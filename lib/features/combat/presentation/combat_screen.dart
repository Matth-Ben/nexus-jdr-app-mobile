import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../groups/domain/group_detail.dart';
import '../../groups/presentation/providers/group_providers.dart';
import '../../groups/presentation/widgets/group_confirmation_dialog.dart';
import '../domain/combat_announcement.dart';
import '../domain/combat_enums.dart';
import '../domain/combat_failure.dart';
import '../domain/combat_participant.dart';
import '../domain/combat_permissions.dart';
import '../domain/combat_reorder.dart';
import '../domain/combat_snapshot.dart';
import '../domain/combat_view_state.dart';
import 'combat_l10n.dart';
import 'combat_motion.dart';
import 'providers/combat_providers.dart';
import 'providers/combat_read_only_provider.dart';
import 'widgets/add_monster_sheet.dart';
import 'widgets/combat_action_menu.dart';
import 'widgets/combat_header.dart';
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
class CombatScreen extends ConsumerStatefulWidget {
  const CombatScreen({required this.groupId, this.announcer, super.key});

  final String groupId;

  /// Annonceur sémantique (surchargeable en test).
  final CombatSheetAnnouncer? announcer;

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

  @override
  void dispose() {
    _announcementTimer?.cancel();
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

  Future<bool> _run(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } on CombatFailure catch (failure) {
      if (mounted) _snack(failure.localized(AppLocalizations.of(context)!));
    } on Object {
      if (mounted) {
        _snack(AppLocalizations.of(context)!.combatFailureGeneric);
      }
    }
    return false;
  }

  Future<void> _editInitiative(CombatParticipant participant) async {
    final value = await showInitiativeSheet(
      context,
      participantName: participant.name,
      initial: participant.initiative,
    );
    if (value == null || !mounted) return;
    await _run(() => _notifier.setParticipantInitiative(participant.id, value));
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
      newSortOrder: neighbor.sortOrder,
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
    ref.listen<CombatViewState>(combatProvider(groupId), _onStateChange);
    final state = ref.watch(combatProvider(groupId));
    final detailAsync = ref.watch(groupDetailProvider(groupId));

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
        return _loading(l10n);
      case CombatPhase.error:
        return const SizedBox.shrink();
      case CombatPhase.none:
        return _message(l10n, l10n.combatFailureNoActive);
      case CombatPhase.ended:
        return _endedSummary(l10n, state.snapshot);
      case CombatPhase.active:
        final snapshot = state.snapshot;
        if (snapshot == null) return _loading(l10n);
        return _activeBody(context, l10n, state, snapshot, detail);
    }
  }

  Widget _loading(AppLocalizations l10n) {
    return Center(
      child: Semantics(
        label: l10n.combatLoading,
        child: const CircularProgressIndicator(color: AppColors.woodMedium),
      ),
    );
  }

  Widget _message(AppLocalizations l10n, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: AppTypography.body(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(
              label: l10n.combatBackToGroup,
              surface: SecondaryButtonSurface.parchment,
              onPressed: _goBack,
            ),
          ],
        ),
      ),
    );
  }

  Widget _endedSummary(AppLocalizations l10n, CombatSnapshot? snapshot) {
    final rounds = snapshot?.combat.round ?? 1;
    final count = snapshot?.participants.where((p) => !p.isRemoved).length ?? 0;
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
            child: Semantics(
              header: true,
              child: Text(
                l10n.combatEndedSummary(rounds, count),
                style: AppTypography.body(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
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
    final canPilot = isOwner && !masterAbsent && !readOnly;
    final canEnd = canEndCombat(detail) && !readOnly;
    final me = detail.currentUserId;
    // Seul ordre d'affichage : `sortedForDisplay` (via le snapshot).
    final displayed = snapshot.displayParticipants;
    final removed = isOwner
        ? snapshot.removedParticipants
        : const <CombatParticipant>[];
    final current = snapshot.currentParticipant;
    final progress = snapshot.initiativeProgress;
    final reorderActive =
        _reorderMode && canPilot && hasInitiativeTies(snapshot);
    final iWasRemoved = snapshot.removedParticipants.any(
      (p) => p.userId == me && p.kind == ParticipantKind.pc,
    );
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
      return InitiativeRow(
        key: _rowKey(participant.id),
        participant: participant,
        rank: participant.initiative == null ? null : index + 1,
        isCurrent: current?.id == participant.id,
        isYou: participant.userId != null && participant.userId == me,
        actionsEnabled: canPilot,
        disabledHint: disabledHint,
        onEditInitiative: manageable
            ? () => _editInitiative(participant)
            : null,
        onFill: manageable ? () => _editInitiative(participant) : null,
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
