import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/connectivity_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/error_retry_state.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/pixel_icon.dart';
import '../../../core/widgets/pixel_icons/combat_pixel_icons.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../core/widgets/wood_back_header.dart';
import '../../../l10n/app_localizations.dart';
import '../../characters/presentation/providers/character_detail_provider.dart';
import '../../groups/domain/group_detail.dart';
import '../../groups/presentation/providers/group_providers.dart';
import '../../groups/presentation/widgets/group_confirmation_dialog.dart';
import '../domain/combat_announcement.dart';
import '../domain/combat_failure.dart';
import '../domain/combat_participant.dart';
import '../domain/combat_permissions.dart';
import '../domain/combat_player_input.dart';
import '../domain/combat_reorder.dart';
import '../domain/combat_snapshot.dart';
import '../domain/combat_view_state.dart';
import '../domain/grimoire_combat_reducer.dart';
import '../domain/grimoire_combat_session.dart';
import '../domain/grimoire_combat_view.dart';
import 'combat_announcer.dart';
import 'combat_l10n.dart';
import 'combat_motion.dart';
import 'grimoire_combat_body.dart';
import 'providers/combat_providers.dart';
import 'providers/combat_read_only_provider.dart';
import 'providers/grimoire_banner_provider.dart';
import 'providers/grimoire_combat_providers.dart';
import 'widgets/add_monster_sheet.dart';
import 'widgets/combat_action_menu.dart';
import 'widgets/combat_header.dart';
import 'widgets/initiative_roll_block.dart';
import 'widgets/initiative_row.dart';
import 'widgets/initiative_sheet.dart';

/// Écran Combat du groupe, route `/groups/:id/combat` — spec visuelle
/// `docs/combat-groupe-ui.md`. Lecture pour tous les membres ; contrôles du
/// MJ (lancer/terminer, monstres, initiatives, retrait, égalités) pour le
/// propriétaire. Aucune écriture hors ligne (lecture seule du dernier état).
///
/// Aucun défilement automatique à la réception d'un évènement temps réel :
/// un seul [ScrollController], des lignes à clé stable par participant, un
/// seul défilement initial vers le tour actif, puis seulement sur appui du
/// bouton « Voir le tour en cours ».
///
/// Même route et mêmes widgets pour un combat **mené depuis Grimoire**
/// (`docs/combat-grimoire-ui.md`) : tant qu'il est vivant, il est affiché en
/// priorité (décision 61) par [GrimoireCombatBody] ; sinon le combat natif.
/// Sans combat : « Connexion au combat… » (5 s au plus) puis « Aucun combat
/// en cours », en continuant d'écouter.
class CombatScreen extends ConsumerStatefulWidget {
  const CombatScreen({
    required this.groupId,
    this.announcer,
    this.assertiveAnnouncer,
    this.rollOpener = defaultInitiativeRollOpener,
    super.key,
  });

  final String groupId;

  /// Annonceur sémantique (surchargeable en test).
  final CombatSheetAnnouncer? announcer;

  /// Annonceur **assertif** (« C'est ton tour. » d'un combat Grimoire),
  /// surchargeable en test.
  final CombatSheetAnnouncer? assertiveAnnouncer;

  /// Lanceur de d20 de la feuille d'initiative (surchargeable en test).
  final InitiativeRollOpener rollOpener;

  @override
  ConsumerState<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends ConsumerState<CombatScreen> {
  final ScrollController _scroll = ScrollController();
  final GlobalKey _listKey = GlobalKey();
  final Map<String, GlobalKey> _rowKeys = {};

  bool _didInitialScroll = false;
  bool _reorderMode = false;
  bool _removedExpanded = false;
  bool _currentVisible = true;

  DateTime? _lastAnnouncedAt;
  String? _pendingAnnouncement;
  Timer? _announcementTimer;

  /// Fenêtre « Connexion au combat… » (abonnement + `state_request`) avant
  /// « Aucun combat en cours ».
  Timer? _connectingTimer;
  bool _connectingOver = false;

  @override
  void initState() {
    super.initState();
    _connectingTimer = Timer(kGrimoireConnectingWindow, () {
      _connectingTimer = null;
      if (mounted) setState(() => _connectingOver = true);
    });
  }

  @override
  void dispose() {
    _announcementTimer?.cancel();
    _connectingTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  GlobalKey _rowKey(String id) => _rowKeys.putIfAbsent(id, GlobalKey.new);

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/groups/${widget.groupId}');
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // --------------------------------------------------------- annonces

  void _onStateChange(CombatViewState? previous, CombatViewState next) {
    if (previous == null) return;
    final userId = ref
        .read(groupDetailProvider(widget.groupId))
        .value
        ?.currentUserId;
    final announcement = combatAnnouncementFor(
      previous: previous,
      next: next,
      currentUserId: userId,
    );
    if (announcement == null || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    _announce(switch (announcement.kind) {
      CombatAnnouncementKind.ended => l10n.combatAnnounceEnded,
      CombatAnnouncementKind.yourTurn => l10n.combatAnnounceYourTurn,
      CombatAnnouncementKind.turn => l10n.combatAnnounceTurn(
        announcement.round ?? 0,
        announcement.name ?? '',
      ),
    });
  }

  /// Évènements **reçus** du combat Grimoire (jamais au chargement ni sur un
  /// `state` de reprise) : annonces polies fusionnées ; « C'est ton tour. »
  /// assertive, avec un seul retour haptique.
  void _onGrimoireEvents(int? previous, int next) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final session = ref.read(grimoireCombatProvider(widget.groupId));
    final group =
        ref.read(groupDetailProvider(widget.groupId)).value?.name ?? '';
    for (final event in session.events) {
      final String? text = switch (event.kind) {
        GrimoireCombatEventKind.combatStarted => l10n.combatAnnounceStart(
          group,
        ),
        GrimoireCombatEventKind.initiativeRequested =>
          l10n.combatAnnounceInitiativeRequested,
        GrimoireCombatEventKind.initiativeSent =>
          l10n.combatAnnounceInitiativeSent(event.value ?? 0),
        GrimoireCombatEventKind.initiativeReceived =>
          l10n.combatAnnounceInitiativeReceived,
        GrimoireCombatEventKind.initiativeCorrected =>
          l10n.combatAnnounceInitiativeCorrected(event.value ?? 0),
        GrimoireCombatEventKind.orderRevealed =>
          l10n.combatAnnounceOrderRevealed,
        GrimoireCombatEventKind.turn => l10n.combatAnnounceTurn(
          event.round ?? 0,
          event.name ?? '',
        ),
        GrimoireCombatEventKind.gmOffline => l10n.combatAnnounceGmOffline,
        GrimoireCombatEventKind.gmBack => l10n.combatAnnounceGmBack,
        GrimoireCombatEventKind.ended => l10n.combatAnnounceEnded,
        GrimoireCombatEventKind.yourTurn ||
        GrimoireCombatEventKind.expired => null,
      };
      if (event.kind == GrimoireCombatEventKind.yourTurn) {
        unawaited(HapticFeedback.mediumImpact());
        final assertive =
            widget.assertiveAnnouncer ?? defaultCombatAssertiveAnnouncer;
        assertive(context, l10n.combatAnnounceYourTurn);
      } else if (text != null) {
        _announce(text);
      }
    }
  }

  /// Annonce polie ; les changements rapprochés sont fusionnés (au plus une
  /// annonce par seconde, la plus récente l'emporte).
  void _announce(String text) {
    const gap = Duration(seconds: 1);
    final now = DateTime.now();
    final last = _lastAnnouncedAt;
    if (last == null || now.difference(last) >= gap) {
      _lastAnnouncedAt = now;
      _send(text);
      return;
    }
    _pendingAnnouncement = text;
    _announcementTimer ??= Timer(gap - now.difference(last), () {
      _announcementTimer = null;
      final pending = _pendingAnnouncement;
      _pendingAnnouncement = null;
      if (pending != null && mounted) {
        _lastAnnouncedAt = DateTime.now();
        _send(pending);
      }
    });
  }

  void _send(String text) {
    final announcer = widget.announcer;
    if (announcer != null) {
      announcer(context, text);
    } else {
      defaultCombatAnnouncer(context, text);
    }
  }

  // ----------------------------------------------------------- défilement

  void _afterLayout(CombatSnapshot snapshot) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final current = snapshot.currentParticipant;
      if (!_didInitialScroll) {
        // Un seul défilement initial, même sans tour actif : un tour reçu
        // plus tard ne fait jamais défiler la liste.
        _didInitialScroll = true;
        if (current != null) {
          _scrollToCurrent(current.id, animate: false);
        }
      }
      _measureCurrentVisibility(current?.id);
    });
  }

  void _scrollToCurrent(String id, {required bool animate}) {
    final context = _rowKeys[id]?.currentContext;
    if (context == null) return;
    final reduce = combatReduceMotion(this.context);
    unawaited(
      Scrollable.ensureVisible(
        context,
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

  // -------------------------------------------------------------- actions

  CombatNotifier get _notifier =>
      ref.read(combatProvider(widget.groupId).notifier);

  /// Exécute une écriture et affiche l'échec localisé en snackbar. [mine] :
  /// écriture du joueur sur sa propre ligne — un `participant_removed` se lit
  /// alors « Le MJ t'a retiré de ce combat » plutôt que « Ce participant... ».
  Future<bool> _run(Future<void> Function() action, {bool mine = false}) async {
    try {
      await action();
      return true;
    } on CombatFailure catch (failure) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _snack(
          mine && failure.kind == CombatFailureKind.participantRemoved
              ? l10n.combatPlayerRemoved
              : failure.localized(l10n),
        );
      }
    } on Object {
      if (mounted) {
        _snack(AppLocalizations.of(context)!.combatFailureGeneric);
      }
    }
    return false;
  }

  Future<void> _editInitiative(CombatParticipant participant) async {
    // Le MJ ne connaît pas le modificateur de Dextérité d'un joueur ni d'un
    // monstre : d20 + 0, sans aide.
    final value = await showInitiativeSheet(
      context,
      participantName: participant.name,
      initial: participant.initiative,
      rollModifier: 0,
      announcer: widget.announcer ?? defaultCombatAnnouncer,
      rollOpener: widget.rollOpener,
    );
    if (value == null || !mounted) return;
    await _run(() => _notifier.setParticipantInitiative(participant.id, value));
  }

  /// Modificateur d'initiative du personnage du joueur, lu sur sa fiche
  /// (`CharacterDetail.initiative`, jamais recalculé ici). `null` si la fiche
  /// n'est pas disponible : pas de lanceur plutôt qu'un modificateur faux.
  Future<int?> _dexModifier(String characterId) async {
    final provider = characterDetailProvider(characterId);
    final cached = ref.read(provider).value;
    if (cached != null) return cached.initiative;
    try {
      final detail = await ref
          .read(provider.future)
          .timeout(const Duration(seconds: 3));
      return detail.initiative;
    } on Object {
      return null;
    }
  }

  /// Le joueur saisit **sa** propre initiative (`set_my_initiative`), pour sa
  /// ligne ou, si elle n'existe pas encore, pour la ligne que le serveur créera.
  Future<void> _editMine(
    GroupDetail detail,
    PlayerInitiativeStatus status,
  ) async {
    final member = detail.currentMember;
    final characterId = member?.characterId;
    if (member == null || characterId == null) return;
    final modifier = await _dexModifier(characterId);
    if (!mounted) return;
    final value = await showInitiativeSheet(
      context,
      participantName: status.row?.name ?? member.name,
      initial: status.row?.initiative,
      rollModifier: modifier,
      showDexHelp: modifier != null,
      announcer: widget.announcer ?? defaultCombatAnnouncer,
      rollOpener: widget.rollOpener,
    );
    if (value == null || !mounted) return;
    await _run(() => _notifier.setMyInitiative(value), mine: true);
  }

  Future<void> _confirmRemove(CombatParticipant participant) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showGroupConfirmationDialog(
      context,
      title: l10n.combatRemoveConfirmTitle(participant.name),
      message: l10n.combatRemoveConfirmBody,
      confirmLabel: l10n.combatRemoveConfirmAction,
      cancelLabel: l10n.combatCancel,
      focusCancelInitially: true,
    );
    if (confirmed != true || !mounted) return;
    await _run(() => _notifier.removeParticipant(participant.id));
  }

  Future<void> _confirmEnd(int round) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showGroupConfirmationDialog(
      context,
      title: l10n.combatEndConfirmTitle,
      message: l10n.combatEndConfirmBody(round),
      confirmLabel: l10n.combatEnd,
      cancelLabel: l10n.combatCancel,
      focusCancelInitially: true,
    );
    if (confirmed != true || !mounted) return;
    await _run(() => _notifier.endCombat());
  }

  Future<void> _addMonster() {
    final l10n = AppLocalizations.of(context)!;
    return showAddMonsterSheet(
      context,
      announcer: widget.announcer ?? defaultCombatAnnouncer,
      existingNames: () => [
        for (final participant
            in ref
                    .read(combatProvider(widget.groupId))
                    .snapshot
                    ?.participants ??
                const <CombatParticipant>[])
          participant.name,
      ],
      onSubmit: ({required name, required initiative, required count}) async {
        try {
          await _notifier.addNpcParticipants(
            baseName: name,
            initiative: initiative,
            count: count,
          );
          return null;
        } on CombatFailure catch (failure) {
          return failure.localized(l10n);
        } on Object {
          return l10n.combatFailureGeneric;
        }
      },
    );
  }

  Future<void> _reorder(
    CombatParticipant participant,
    CombatParticipant neighbor,
  ) => _run(
    () => _notifier.reorderParticipant(
      participantId: participant.id,
      newSortOrder: swapSortOrderWith(neighbor),
    ),
  );

  void _openHeaderMenu({
    required CombatSnapshot snapshot,
    required bool canPilot,
    required bool canEnd,
  }) {
    final l10n = AppLocalizations.of(context)!;
    showCombatActionMenu(
      context,
      title: l10n.combatScreenTitle,
      entries: [
        if (canPilot && hasInitiativeTies(snapshot))
          CombatMenuEntry(
            icon: Icons.swap_vert,
            label: l10n.combatReorderMode,
            onTap: () => setState(() => _reorderMode = true),
          ),
        if (canEnd)
          CombatMenuEntry(
            label: l10n.combatEnd,
            destructive: true,
            onTap: () => _confirmEnd(snapshot.combat.round),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final groupId = widget.groupId;
    ref.watch(combatRealtimeWatcherProvider(groupId));
    ref.watch(grimoireCombatWatcherProvider(groupId));
    ref.listen<CombatViewState>(combatProvider(groupId), _onStateChange);
    ref
      ..listen<int>(
        grimoireCombatProvider(groupId)
            .select((session) => session.eventSerial),
        _onGrimoireEvents,
      )
      // Exclusion : une annonce polie du titre de l'état final.
      ..listen<bool>(
        grimoireCombatProvider(groupId).select((session) => session.isExcluded),
        (previous, excluded) {
          if (excluded && previous != true && mounted) {
            _announce(AppLocalizations.of(context)!.combatNotMemberAnymore);
          }
        },
      );
    final state = ref.watch(combatProvider(groupId));
    final detailAsync = ref.watch(groupDetailProvider(groupId));
    final detail = detailAsync.value;
    syncGrimoireIdentity(
      context,
      ref,
      groupId,
      detail == null
          ? null
          : (
              userId: detail.currentUserId,
              characterId: detail.currentMember?.characterId,
            ),
    );

    return Scaffold(
      backgroundColor: AppColors.parchmentBg,
      body: Column(
        children: [
          WoodBackHeader(title: l10n.combatScreenTitle, onBack: _goBack),
          Expanded(child: _body(context, l10n, state, detailAsync)),
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    CombatViewState state,
    AsyncValue<GroupDetail> detailAsync,
  ) {
    final detail = detailAsync.value;
    final grimoire = ref.watch(grimoireCombatProvider(widget.groupId));
    if (grimoire.isExcluded) return _fade('excluded', _excluded(l10n));
    final view = grimoire.view;
    // Décision 61 : un combat Grimoire vivant passe avant le combat natif.
    if (view.isAlive && detail != null) {
      return _fade(
        'grimoire',
        GrimoireCombatBody(
          groupId: widget.groupId,
          detail: detail,
          session: grimoire,
          phoneOnline: ref.watch(connectivityStatusProvider).value != false,
          dexModifier: _dexModifier,
          sheetAnnouncer: widget.announcer ?? defaultCombatAnnouncer,
          rollOpener: widget.rollOpener,
        ),
      );
    }
    // Fin ou expiration d'un combat Grimoire : seulement sans combat natif,
    // ou si le dernier message de Grimoire est plus récent que la fin native
    // (un combat natif lancé puis terminé après coup n'est jamais masqué).
    if (detail != null && _grimoireEndPrevails(state, view)) {
      if (view.status == GrimoireCombatStatus.ended) {
        return _fade('grimoireEnded', _grimoireEnded(l10n, view));
      }
      if (view.isExpired) {
        return _fade('grimoireInterrupted', _interrupted(l10n, view));
      }
    }
    if (state.phase == CombatPhase.error) {
      return ErrorRetryState(
        message: l10n.combatLoadError,
        onRetry: () => unawaited(_notifier.refresh()),
      );
    }
    if (detail == null) {
      if (detailAsync.hasError) {
        return ErrorRetryState(
          message: l10n.combatLoadError,
          onRetry: () => ref.invalidate(groupDetailProvider(widget.groupId)),
        );
      }
      return _loading(l10n);
    }
    switch (state.phase) {
      case CombatPhase.loading:
        return _fade('connecting', _loading(l10n));
      case CombatPhase.error:
        return const SizedBox.shrink();
      case CombatPhase.none:
        // Remplace « Aucun combat actif. » : le combat (natif ou Grimoire)
        // s'affichera ici dès qu'il reprend.
        if (!_connectingOver &&
            grimoire.link != GrimoireLinkStatus.lost &&
            grimoire.link != GrimoireLinkStatus.unavailable) {
          return _fade('connecting', _loading(l10n));
        }
        return _fade(
          'none',
          _emptyScreen(
            key: const Key('combatNone'),
            title: l10n.combatNoneTitle,
            body: l10n.combatNoneBody,
          ),
        );
      case CombatPhase.ended:
        return _endedSummary(l10n, state.snapshot);
      case CombatPhase.active:
        final snapshot = state.snapshot;
        if (snapshot == null) return _loading(l10n);
        return _activeBody(context, l10n, state, snapshot, detail);
    }
  }

  /// La fin (ou l'expiration) du combat Grimoire l'emporte-t-elle sur le
  /// combat natif ? Oui sans combat natif ; face à un combat natif terminé,
  /// seulement si le dernier message de Grimoire a été reçu après la fin
  /// native (même horloge, celle de Nexus) ; jamais face à un combat natif
  /// actif, en chargement ou en erreur.
  bool _grimoireEndPrevails(CombatViewState state, GrimoireCombatView view) {
    switch (state.phase) {
      case CombatPhase.none:
        return true;
      case CombatPhase.ended:
        final nativeEnd = state.snapshot?.combat.endedAt ?? state.lastKnownAt;
        final lastGrimoire = view.lastReceivedAt;
        return nativeEnd != null &&
            lastGrimoire != null &&
            lastGrimoire.isAfter(nativeEnd);
      case CombatPhase.loading:
      case CombatPhase.active:
      case CombatPhase.error:
        return false;
    }
  }

  /// Fondu de 200 ms entre les états propres au combat Grimoire et les états
  /// sans combat (immédiat en reduce motion). Les états du combat natif ne
  /// passent pas par ici.
  Widget _fade(String kind, Widget child) {
    if (combatReduceMotion(context)) return child;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: KeyedSubtree(key: ValueKey('combatState-$kind'), child: child),
    );
  }

  /// Chargement existant, avec le libellé visible « Connexion au combat… ».
  Widget _loading(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: l10n.combatLoading,
            child: const CircularProgressIndicator(color: AppColors.woodMedium),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              l10n.combatConnecting,
              textAlign: TextAlign.center,
              style: AppTypography.body(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// « Aucun combat en cours » / « Pas de nouvelles du MJ » : icône pixel 32,
  /// titre 16/800, texte 13 `textSecondary`, « Retour au groupe ».
  Widget _emptyScreen({
    required Key key,
    required String title,
    String? body,
    Widget icon = const PixelIcon(
      matrix: kCombatSwordsMatrix,
      size: 32,
      color: AppColors.textSecondary,
    ),
    String? buttonLabel,
    VoidCallback? onButton,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.lg),
          icon,
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.body(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (body != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              body,
              textAlign: TextAlign.center,
              style: AppTypography.body(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(
            label: buttonLabel ?? l10n.combatBackToGroup,
            surface: SecondaryButtonSurface.parchment,
            onPressed: onButton ?? _goBack,
          ),
        ],
      ),
    );
  }

  /// Le joueur ne fait plus partie du groupe (`group_not_found`, décision
  /// 50) : état final neutre, retour à l'accueil (le groupe n'est plus
  /// accessible).
  Widget _excluded(AppLocalizations l10n) {
    return _emptyScreen(
      key: const Key('combatExcluded'),
      title: l10n.combatNotMemberAnymore,
      icon: const Icon(
        Icons.group_off_outlined,
        size: 32,
        color: AppColors.textSecondary,
      ),
      buttonLabel: l10n.combatBackHome,
      onButton: () => context.go('/'),
    );
  }

  /// 10 min sans message de Grimoire : on ne sait pas si le combat est
  /// terminé, donc pas de résumé de fin.
  Widget _interrupted(AppLocalizations l10n, GrimoireCombatView view) {
    final last = view.lastSentAt ?? view.lastReceivedAt ?? DateTime.now();
    return _emptyScreen(
      key: const Key('combatInterrupted'),
      title: l10n.combatInterruptedTitle,
      body: l10n.combatInterruptedBody(combatClockLabel(l10n, last)),
    );
  }

  /// Fin d'un combat Grimoire : résumé existant ; sans participant public
  /// (fin avant le dévoilement), « Combat terminé » et son explication.
  Widget _grimoireEnded(AppLocalizations l10n, GrimoireCombatView view) {
    final count = view.endedParticipantCount ?? 0;
    return _summary(
      l10n,
      title: count == 0
          ? l10n.combatEndedTitle
          : l10n.combatEndedSummary(view.endedRounds ?? 1, count),
      body: count == 0 ? l10n.combatEndedBeforeOrder : null,
    );
  }

  Widget _endedSummary(AppLocalizations l10n, CombatSnapshot? snapshot) {
    final rounds = snapshot?.combat.round ?? 1;
    final count = snapshot?.summaryParticipantCount ?? 0;
    return _summary(l10n, title: l10n.combatEndedSummary(rounds, count));
  }

  Widget _summary(
    AppLocalizations l10n, {
    required String title,
    String? body,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            key: const Key('combatEndedSummary'),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.parchmentCard,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.woodLight,
                width: AppBorders.card,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: AppTypography.body(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (body != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    body,
                    style: AppTypography.body(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(
            label: l10n.combatBackToGroup,
            surface: SecondaryButtonSurface.parchment,
            onPressed: _goBack,
          ),
        ],
      ),
    );
  }

  Widget _activeBody(
    BuildContext context,
    AppLocalizations l10n,
    CombatViewState state,
    CombatSnapshot snapshot,
    GroupDetail detail,
  ) {
    final groupId = widget.groupId;
    final readOnly = ref.watch(combatReadOnlyProvider(groupId));
    final isOwner = detail.isOwner;
    final masterAbsent = isCombatMasterAbsent(detail);
    final canPilot = canPilotCombat(detail, readOnly: readOnly);
    final canEnd = canEndCombat(detail) && !readOnly;
    final me = detail.currentUserId;
    // Seul ordre d'affichage : `sortedForDisplay` (via le snapshot).
    final displayed = snapshot.displayParticipants;
    final removed = snapshot.removedVisibleTo(isOwner: isOwner);
    final current = snapshot.currentParticipant;
    final progress = snapshot.initiativeProgress;
    final reorderActive =
        _reorderMode && canPilot && hasInitiativeTies(snapshot);
    final mine = playerInitiativeStatus(snapshot, detail);
    final iWasRemoved = wasRemovedFromCombat(mine);
    // Le joueur ne peut écrire que si le MJ est là, qu'il n'est pas retiré et
    // que l'état est à jour (jamais d'écriture hors ligne).
    final playerCanWrite =
        !readOnly && mine.access == PlayerInitiativeAccess.allowed;
    final disabledHint = readOnly
        ? l10n.combatStartUnavailableOffline
        : l10n.combatFailureGmAbsent;

    _afterLayout(snapshot);

    Widget rowFor(CombatParticipant participant, int index) {
      final up = reorderActive
          ? reorderNeighbor(displayed, index, up: true)
          : null;
      final down = reorderActive
          ? reorderNeighbor(displayed, index, up: false)
          : null;
      final manageable = isOwner && !participant.isRemoved;
      // Un joueur n'agit que sur SA ligne (jamais celle d'un autre).
      final ownRow = !isOwner && isOwnEditableRow(mine, participant);
      final VoidCallback? edit = manageable
          ? () => _editInitiative(participant)
          : ownRow
          ? () => _editMine(detail, mine)
          : null;
      return InitiativeRow(
        key: _rowKey(participant.id),
        participant: participant,
        rank: participant.initiative == null ? null : index + 1,
        isCurrent: current?.id == participant.id,
        isYou: participant.userId != null && participant.userId == me,
        actionsEnabled: manageable ? canPilot : playerCanWrite,
        disabledHint: disabledHint,
        onEditInitiative: edit,
        editLabel: ownRow ? l10n.combatMenuEditMine : null,
        onFill: edit,
        onRemove: manageable ? () => _confirmRemove(participant) : null,
        reorderMode: reorderActive,
        onMoveUp: up == null ? null : () => _reorder(participant, up),
        onMoveDown: down == null ? null : () => _reorder(participant, down),
      );
    }

    final children = <Widget>[
      for (var i = 0; i < displayed.length; i++) ...[
        rowFor(displayed[i], i),
        const SizedBox(height: AppSpacing.sm),
      ],
      if (displayed.isEmpty) _emptyState(l10n, isOwner),
      if (removed.isNotEmpty) ...[
        _removedHeader(l10n, removed.length),
        if (_removedExpanded)
          for (final participant in removed) ...[
            rowFor(participant, -1),
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    ];

    return Column(
      children: [
        if (readOnly)
          _banner(
            InfoBanner(
              icon: Icons.cloud_off_outlined,
              message: l10n.combatOfflineBanner(
                combatClockLabel(l10n, state.lastKnownAt ?? DateTime.now()),
              ),
            ),
          ),
        if (masterAbsent)
          _banner(
            InfoBanner(
              icon: Icons.hourglass_empty,
              message: l10n.combatAwaitingMasterBody,
            ),
          ),
        if (iWasRemoved)
          _banner(
            InfoBanner(
              icon: Icons.block_outlined,
              message: l10n.combatPlayerRemoved,
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: CombatHeader(
            round: snapshot.combat.round,
            turnName: current?.name,
            initiativeEntered: progress.entered,
            initiativeTotal: progress.total,
            showKebab: isOwner,
            kebabEnabled: !readOnly && (canPilot || canEnd),
            onKebab: () => _openHeaderMenu(
              snapshot: snapshot,
              canPilot: canPilot,
              canEnd: canEnd,
            ),
            reorderMode: reorderActive,
            onReorderDone: () => setState(() => _reorderMode = false),
            showJumpToTurn: !_currentVisible && current != null,
            onJumpToTurn: current == null
                ? null
                : () => _scrollToCurrent(current.id, animate: true),
          ),
        ),
        if (shouldOfferFirstInitiative(mine))
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Tooltip(
              message: playerCanWrite ? '' : disabledHint,
              child: SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  key: const Key('combatFillMine'),
                  label: l10n.combatFillMine,
                  onPressed: playerCanWrite
                      ? () => _editMine(detail, mine)
                      : null,
                ),
              ),
            ),
          ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification ||
                  notification is ScrollEndNotification) {
                // Après la mise en page : la position du défilement n'est
                // appliquée aux lignes qu'au prochain frame.
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
              // tour actif ne dépend jamais d'une ligne hors fenêtre.
              scrollCacheExtent: const ScrollCacheExtent.pixels(100000),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              children: children,
            ),
          ),
        ),
        if (isOwner)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Tooltip(
                message: canPilot ? '' : disabledHint,
                child: SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: l10n.combatAddMonster,
                    onPressed: canPilot ? _addMonster : null,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _banner(Widget child) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.sm,
      AppSpacing.lg,
      0,
    ),
    child: child,
  );

  Widget _emptyState(AppLocalizations l10n, bool isOwner) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          if (isOwner) ...[
            const PixelIcon(
              matrix: kCombatSwordsMatrix,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.combatEmptyMasterTitle,
              textAlign: TextAlign.center,
              style: AppTypography.body(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.combatEmptyMasterBody,
              textAlign: TextAlign.center,
              style: AppTypography.body(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ] else
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
    );
  }

  Widget _removedHeader(AppLocalizations l10n, int count) {
    return Semantics(
      button: true,
      expanded: _removedExpanded,
      child: InkWell(
        key: const Key('combatRemovedToggle'),
        onTap: () => setState(() => _removedExpanded = !_removedExpanded),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.combatRemovedSection(count),
                  style: AppTypography.body(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Icon(
                _removedExpanded ? Icons.expand_less : Icons.expand_more,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
