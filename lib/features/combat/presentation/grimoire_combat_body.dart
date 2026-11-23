import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/pixel_icon.dart';
import '../../../core/widgets/pixel_icons/combat_pixel_icons.dart';
import '../../../l10n/app_localizations.dart';
import '../../groups/domain/group_detail.dart';
import '../domain/combat_participant.dart';
import '../domain/grimoire_combat_session.dart';
import '../domain/grimoire_combat_view.dart';
import '../domain/grimoire_failure.dart';
import '../domain/grimoire_participant.dart';
import 'combat_announcer.dart';
import 'combat_l10n.dart';
import 'combat_motion.dart';
import 'providers/grimoire_combat_providers.dart';
import 'widgets/combat_header.dart';
import 'widgets/combat_initiative_card.dart';
import 'widgets/initiative_row.dart';
import 'widgets/initiative_roll_block.dart';
import 'widgets/initiative_sheet.dart';

/// Modificateur d'initiative de la fiche d'un personnage (`null` : inconnu).
typedef CombatDexModifier = Future<int?> Function(String characterId);

/// Corps de l'écran Combat pour un combat **mené depuis Grimoire**
/// (`docs/combat-grimoire-ui.md`) : mêmes en-tête, lignes et feuille que le
/// combat natif, paramétrés par le modèle de vue. Ordre en lecture seule pour
/// tous (meneur compris) ; la seule action est d'envoyer sa propre
/// initiative.
///
/// Aucun défilement automatique à la réception d'un message : lignes à clé
/// stable par participant, un seul positionnement initial sur le tour en
/// cours au dévoilement, puis seulement « Voir le tour en cours ».
class GrimoireCombatBody extends ConsumerStatefulWidget {
  const GrimoireCombatBody({
    required this.groupId,
    required this.detail,
    required this.session,
    required this.phoneOnline,
    required this.dexModifier,
    this.sheetAnnouncer = defaultCombatAnnouncer,
    this.rollOpener = defaultInitiativeRollOpener,
    super.key,
  });

  final String groupId;
  final GroupDetail detail;
  final GrimoireCombatSession session;

  /// Téléphone en ligne (priorité de l'état « hors ligne », §7).
  final bool phoneOnline;
  final CombatDexModifier dexModifier;
  final CombatSheetAnnouncer sheetAnnouncer;
  final InitiativeRollOpener rollOpener;

  @override
  ConsumerState<GrimoireCombatBody> createState() => _GrimoireCombatBodyState();
}

class _GrimoireCombatBodyState extends ConsumerState<GrimoireCombatBody> {
  final ScrollController _scroll = ScrollController();
  final GlobalKey _listKey = GlobalKey();
  final Map<String, GlobalKey> _rowKeys = {};

  bool _didInitialScroll = false;
  bool _currentVisible = true;

  /// Lignes retirées par `participant_removed` (ou sorties de la liste) le
  /// temps de se replier (200 ms), à leur ancienne place.
  final Map<String, ({GrimoireParticipant participant, int index})> _leaving =
      {};

  @override
  void didUpdateWidget(GrimoireCombatBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = oldWidget.session.view;
    final after = widget.session.view;
    if (after.status == GrimoireCombatStatus.preparing) {
      _didInitialScroll = false;
    }
    if (before.combatId != after.combatId ||
        after.status != GrimoireCombatStatus.active ||
        combatReduceMotion(context)) {
      _leaving.clear();
      return;
    }
    final ids = {for (final participant in after.participants) participant.id};
    for (var i = 0; i < before.participants.length; i++) {
      final participant = before.participants[i];
      if (!ids.contains(participant.id)) {
        _leaving[participant.id] = (participant: participant, index: i);
      }
    }
    _leaving.removeWhere((id, _) => ids.contains(id));
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  GrimoireIdentity get _me => (
    userId: widget.detail.currentUserId,
    characterId: widget.detail.currentMember?.characterId,
  );

  GlobalKey _rowKey(String id) => _rowKeys.putIfAbsent(id, GlobalKey.new);

  // ----------------------------------------------------------- défilement

  void _afterLayout(GrimoireCombatView view) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final current = view.currentParticipant;
      if (!_didInitialScroll) {
        // La liste n'existait pas avant le dévoilement : un seul
        // positionnement initial, aucune position à préserver.
        _didInitialScroll = true;
        if (current != null) _scrollToCurrent(current.id, animate: false);
      }
      _measureCurrentVisibility(current?.id);
    });
  }

  void _scrollToCurrent(String id, {required bool animate}) {
    final rowContext = _rowKeys[id]?.currentContext;
    if (rowContext == null) return;
    final reduce = combatReduceMotion(context);
    unawaited(
      Scrollable.ensureVisible(
        rowContext,
        alignment: 0.1,
        duration: animate && !reduce
            ? const Duration(milliseconds: 250)
            : Duration.zero,
      ),
    );
  }

  void _measureCurrentVisibility(String? currentId) {
    var visible = true;
    final rowBox = currentId == null
        ? null
        : _rowKeys[currentId]?.currentContext?.findRenderObject();
    final listBox = _listKey.currentContext?.findRenderObject();
    if (rowBox is RenderBox &&
        rowBox.attached &&
        listBox is RenderBox &&
        listBox.attached) {
      final rowRect = rowBox.localToGlobal(Offset.zero) & rowBox.size;
      final listRect = listBox.localToGlobal(Offset.zero) & listBox.size;
      visible = rowRect.overlaps(listRect);
    }
    if (visible != _currentVisible && mounted) {
      setState(() => _currentVisible = visible);
    }
  }

  // ------------------------------------------------------------ initiative

  /// Feuille d'initiative réutilisée telle quelle (« Envoyer au MJ », aide
  /// « seul le MJ peut la modifier »), puis envoi au meneur.
  Future<void> _sendInitiative() async {
    final member = widget.detail.currentMember;
    final characterId = member?.characterId;
    if (member == null || characterId == null) return;
    final l10n = AppLocalizations.of(context)!;
    final modifier = await widget.dexModifier(characterId);
    if (!mounted) return;
    final value = await showInitiativeSheet(
      context,
      participantName: member.name,
      rollModifier: modifier,
      showDexHelp: modifier != null,
      announcer: widget.sheetAnnouncer,
      rollOpener: widget.rollOpener,
      primaryLabel: l10n.combatSendToGm,
      helpText: l10n.combatSendHint,
    );
    if (value == null || !mounted) return;
    await ref
        .read(grimoireCombatProvider(widget.groupId).notifier)
        .sendInitiative(value);
  }

  /// Raison visible d'un envoi indisponible : hors ligne (ou canal coupé),
  /// puis MJ hors ligne.
  String? _unavailableReason(
    AppLocalizations l10n,
    GrimoireDisplayLiveness liveness,
  ) => switch (liveness) {
    GrimoireDisplayLiveness.offline => l10n.combatStartUnavailableOffline,
    GrimoireDisplayLiveness.gmOffline => l10n.combatUnavailableGmOffline,
    _ => null,
  };

  String? _failureMessage(AppLocalizations l10n, GrimoireFailure? failure) {
    if (failure == null) return null;
    final seconds = failure.retryAfterSeconds;
    return switch (failure.kind) {
      GrimoireFailureKind.rateLimited when seconds != null =>
        l10n.combatSendRateLimited(seconds),
      GrimoireFailureKind.noCharacter => l10n.combatFailureNoCharacter,
      GrimoireFailureKind.groupNotFound => l10n.combatNotMemberAnymore,
      GrimoireFailureKind.offline => l10n.combatStartUnavailableOffline,
      _ => l10n.combatSendFailed,
    };
  }

  Widget? _initiativeCard(
    AppLocalizations l10n,
    GrimoireCombatView view,
    GrimoireDisplayLiveness liveness,
  ) {
    if (!view.showsInitiativeCard) return null;
    final initiative = view.initiative;
    final state = switch (initiative.status) {
      GrimoireInitiativeStatus.idle => null,
      GrimoireInitiativeStatus.requested => CombatInitiativeCardState.requested,
      GrimoireInitiativeStatus.sending => CombatInitiativeCardState.sending,
      GrimoireInitiativeStatus.sent => CombatInitiativeCardState.sent,
      GrimoireInitiativeStatus.received => CombatInitiativeCardState.received,
      GrimoireInitiativeStatus.notReceived =>
        CombatInitiativeCardState.notReceived,
      GrimoireInitiativeStatus.requestedAgain =>
        CombatInitiativeCardState.requestedAgain,
      GrimoireInitiativeStatus.failed => CombatInitiativeCardState.failed,
    };
    if (state == null) return null;
    final received = initiative.status == GrimoireInitiativeStatus.received;
    return CombatInitiativeCard(
      state: state,
      characterName: widget.detail.currentMember?.name ?? '',
      value: received
          ? initiative.sentValue ?? view.mine(_me)?.initiative
          : initiative.sentValue,
      preparing: view.status == GrimoireCombatStatus.preparing,
      unavailableReason: _unavailableReason(l10n, liveness),
      failureMessage: _failureMessage(l10n, initiative.failure),
      onSend: _sendInitiative,
    );
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final session = widget.session;
    final view = session.view;
    final liveness = session.displayLiveness(phoneOnline: widget.phoneOnline);
    final preparing = view.status == GrimoireCombatStatus.preparing;
    final card = _initiativeCard(l10n, view, liveness);
    final reduce = combatReduceMotion(context);

    final Widget content = preparing
        ? _preparing(l10n, view, card)
        : _ordered(l10n, view, liveness, card);
    return Column(
      children: [
        _banners(l10n, session, liveness, reduce),
        Expanded(
          child: reduce
              ? content
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: KeyedSubtree(key: ValueKey(preparing), child: content),
                ),
        ),
      ],
    );
  }

  /// Bandeaux au-dessus de l'en-tête, par priorité : hors ligne, puis MJ hors
  /// ligne ; meneur ; joueur retiré. Apparition et retrait `AnimatedSize`.
  Widget _banners(
    AppLocalizations l10n,
    GrimoireCombatSession session,
    GrimoireDisplayLiveness liveness,
    bool reduce,
  ) {
    final view = session.view;
    final last = view.lastSentAt ?? view.lastReceivedAt ?? DateTime.now();
    final time = combatClockLabel(l10n, last);
    final banners = [
      if (liveness == GrimoireDisplayLiveness.offline)
        InfoBanner(
          key: const Key('combatGrimoireOffline'),
          icon: Icons.cloud_off_outlined,
          message: l10n.combatOfflineBanner(time),
        )
      else if (liveness == GrimoireDisplayLiveness.gmOffline)
        InfoBanner(
          key: const Key('combatGrimoireGmOffline'),
          icon: Icons.hourglass_empty,
          message: l10n.combatGmOfflineBanner(time),
        ),
      if (session.isLeader)
        InfoBanner(
          key: const Key('combatGrimoireLeader'),
          icon: Icons.desktop_windows_outlined,
          message: l10n.combatGrimoireLeaderInfo,
        ),
      if (view.removedFromCombat)
        InfoBanner(
          key: const Key('combatGrimoireRemoved'),
          icon: Icons.block_outlined,
          message: l10n.combatRemovedByGm,
        ),
    ];
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final banner in banners)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            child: banner,
          ),
      ],
    );
    if (reduce) return column;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.topCenter,
      child: SizedBox(width: double.infinity, child: column),
    );
  }

  Widget _header(Widget header) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.sm,
      AppSpacing.lg,
      AppSpacing.sm,
    ),
    child: header,
  );

  /// Préparation : annonce sans contenu (ni round, ni progression, ni
  /// initiative des autres), carte d'initiative puis bloc d'attente dans un
  /// corps défilant au texte agrandissable sans plafond.
  Widget _preparing(
    AppLocalizations l10n,
    GrimoireCombatView view,
    Widget? card,
  ) {
    return Column(
      children: [
        _header(
          CombatHeader(
            mode: CombatHeaderMode.preparing,
            round: view.round,
            initiativeEntered: 0,
            initiativeTotal: 0,
            sourceLabel: l10n.combatGrimoireSource,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            key: const Key('combatGrimoirePreparing'),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _animatedCard(card),
                if (card != null) const SizedBox(height: AppSpacing.lg),
                const SizedBox(height: AppSpacing.md),
                const PixelIcon(
                  matrix: kCombatSwordsMatrix,
                  size: 32,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.combatEmptyPlayer,
                  textAlign: TextAlign.center,
                  style: AppTypography.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _animatedCard(Widget? card) {
    final child = card ?? const SizedBox(width: double.infinity);
    if (combatReduceMotion(context)) return child;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.topCenter,
      child: child,
    );
  }

  /// Ordre dévoilé, en lecture seule : le tableau `participants` tel quel,
  /// jamais retrié ; aucun menu ni réordonnancement.
  Widget _ordered(
    AppLocalizations l10n,
    GrimoireCombatView view,
    GrimoireDisplayLiveness liveness,
    Widget? card,
  ) {
    final me = _me;
    final current = view.currentParticipant;
    final progress = view.initiativeProgress;
    final initiative = view.initiative;
    final corrected = view.correctedFrom(me);
    final dead = grimoireDeadCharacterIds(widget.detail.members);
    final unavailable = _unavailableReason(l10n, liveness);
    final combatId = view.combatId ?? '';
    _afterLayout(view);

    Widget rowFor(GrimoireParticipant participant, int index, {Key? key}) {
      final mine = GrimoireCombatView.isMine(participant, me);
      final sentLabel =
          mine &&
          (initiative.status == GrimoireInitiativeStatus.sending ||
              initiative.status == GrimoireInitiativeStatus.sent ||
              initiative.status == GrimoireInitiativeStatus.received);
      return InitiativeRow(
        key: key ?? _rowKey(participant.id),
        participant: participant.toCombatParticipant(
          combatId: combatId,
          groupId: widget.groupId,
          sortOrder: index,
        ),
        rank: participant.initiative == null ? null : index + 1,
        isCurrent: current?.id == participant.id,
        isYou: mine,
        isDead: isGrimoireParticipantDead(participant, dead),
        pendingLabel: sentLabel ? l10n.combatInitiativeSentLabel : null,
        note: mine && corrected != null
            ? l10n.combatInitiativeCorrected(corrected)
            : null,
        onFill: mine && initiative.canSend ? _sendInitiative : null,
        actionsEnabled: unavailable == null,
        disabledHint: unavailable,
      );
    }

    final viewportHeight = MediaQuery.sizeOf(context).height;
    return Column(
      children: [
        _header(
          CombatHeader(
            mode: view.yourTurn
                ? CombatHeaderMode.yourTurn
                : CombatHeaderMode.standard,
            round: view.round,
            turnName: current?.name,
            initiativeEntered: progress.entered,
            initiativeTotal: progress.total,
            sourceLabel: l10n.combatGrimoireSource,
            showJumpToTurn: !_currentVisible && current != null,
            onJumpToTurn: current == null
                ? null
                : () => _scrollToCurrent(current.id, animate: true),
          ),
        ),
        // Zone fixe de la carte d'initiative (place de « Renseigner mon
        // initiative ») : textes plafonnés ×2,0, 30 % du viewport au plus.
        _animatedCard(
          card == null
              ? null
              : Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: MediaQuery.withClampedTextScaling(
                    maxScaleFactor: AppTypography.maxTextScaleFactor,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: viewportHeight * 0.3,
                      ),
                      child: SingleChildScrollView(child: card),
                    ),
                  ),
                ),
        ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification ||
                  notification is ScrollEndNotification) {
                final id = current?.id;
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _measureCurrentVisibility(id),
                );
              }
              return false;
            },
            child: ListView(
              key: _listKey,
              controller: _scroll,
              // Toutes les lignes restent construites : le défilement vers le
              // tour en cours ne dépend jamais d'une ligne hors fenêtre.
              scrollCacheExtent: const ScrollCacheExtent.pixels(100000),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              children: [
                for (final entry in _entries(view))
                  if (entry.leaving)
                    _CollapsingRow(
                      key: ValueKey('combatLeaving-${entry.participant.id}'),
                      onDone: () {
                        if (mounted) {
                          setState(() => _leaving.remove(entry.participant.id));
                        }
                      },
                      child: rowFor(
                        entry.participant,
                        entry.index,
                        key: ValueKey(
                          'combatLeavingRow-${entry.participant.id}',
                        ),
                      ),
                    )
                  else ...[
                    rowFor(entry.participant, entry.index),
                    const SizedBox(height: AppSpacing.sm),
                  ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Lignes affichées : l'ordre du MJ tel quel, plus les lignes qui se
  /// replient à leur ancienne place (aucune section « Retirés »).
  List<({GrimoireParticipant participant, int index, bool leaving})> _entries(
    GrimoireCombatView view,
  ) {
    final entries = [
      for (var i = 0; i < view.participants.length; i++)
        (participant: view.participants[i], index: i, leaving: false),
    ];
    final leaving = _leaving.values.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    for (final gone in leaving) {
      entries.insert(gone.index.clamp(0, entries.length), (
        participant: gone.participant,
        index: gone.index,
        leaving: true,
      ));
    }
    return entries;
  }
}

/// Ligne qui se replie (taille et opacité, 200 ms) puis disparaît.
class _CollapsingRow extends StatefulWidget {
  const _CollapsingRow({required this.child, required this.onDone, super.key});

  final Widget child;
  final VoidCallback onDone;

  @override
  State<_CollapsingRow> createState() => _CollapsingRowState();
}

class _CollapsingRowState extends State<_CollapsingRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
    value: 1,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_controller.reverse().whenComplete(widget.onDone));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizeTransition(
        sizeFactor: _controller,
        alignment: AlignmentDirectional.topCenter,
        child: FadeTransition(
          opacity: _controller,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Ligne publique de Grimoire présentée par [InitiativeRow] (même gabarit
/// que le combat natif) ; [sortOrder] = rang dans l'ordre du MJ.
extension GrimoireParticipantRow on GrimoireParticipant {
  CombatParticipant toCombatParticipant({
    required String combatId,
    required String groupId,
    required int sortOrder,
  }) => CombatParticipant(
    id: id,
    combatId: combatId,
    groupId: groupId,
    characterId: characterId,
    userId: userId,
    name: name,
    kind: kind,
    initiative: initiative,
    sortOrder: sortOrder,
    status: status,
  );
}
