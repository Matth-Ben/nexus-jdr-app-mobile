import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../cache/cache_providers.dart';
import '../cache/sync_alert_store.dart';
import '../sync/relative_sync_time.dart';
import '../sync/sync_alerts_panel_providers.dart';
import '../sync/sync_clock_provider.dart';
import '../sync/sync_status_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'secondary_button.dart';
import 'sheet_header_bar.dart';
import 'sync_status_banner.dart';
import 'undo_snack_bar.dart';

/// Part de la hauteur de l'écran que la feuille ne dépasse jamais.
const double syncAlertsSheetMaxHeightFraction = 0.85;

/// Échelle de police au-delà de laquelle les marges de la liste se réduisent.
const double _denseScale = 2.2;

/// Ouvre le panneau des alertes de synchronisation (conflits et modifications
/// abandonnées) : feuille modale basse, liste plate triée de la plus récente à
/// la plus ancienne, avec « Écarter » / « Tout écarter » annulables.
///
/// Appelé depuis le bandeau de synchro (liste et fiche) et depuis le Profil.
/// Lecture et écriture **locales** seulement (drift) : fonctionne hors ligne,
/// n'appelle jamais le réseau, et ne touche jamais aux écritures en attente ni
/// aux données d'un personnage (écarter une alerte = supprimer la ligne
/// d'alerte, rien d'autre).
Future<void> showSyncAlertsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SyncAlertsSheet(),
  );
}

/// Hôte de la feuille : une zone transparente de
/// [syncAlertsSheetMaxHeightFraction] de l'écran, dans laquelle le panneau
/// (fond parchemin) occupe la hauteur de son contenu, collé en bas.
///
/// Elle embarque son propre `ScaffoldMessenger` + `Scaffold` : un SnackBar
/// montré par le `Scaffold` de l'écran en dessous serait caché par la feuille
/// modale (ancrée en bas). Le SnackBar « Annuler » apparaît ainsi en bas de la
/// feuille. La zone transparente au-dessus du panneau ferme la feuille au tap,
/// comme le fond assombri.
class _SyncAlertsSheet extends StatelessWidget {
  const _SyncAlertsSheet();

  @override
  Widget build(BuildContext context) {
    final height =
        MediaQuery.sizeOf(context).height * syncAlertsSheetMaxHeightFraction;
    return SizedBox(
      height: height,
      child: ScaffoldMessenger(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                  child: const SizedBox.expand(),
                ),
              ),
              const Align(
                alignment: Alignment.bottomCenter,
                child: _SyncAlertsPanel(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncAlertsPanel extends ConsumerStatefulWidget {
  const _SyncAlertsPanel();

  @override
  ConsumerState<_SyncAlertsPanel> createState() => _SyncAlertsPanelState();
}

class _SyncAlertsPanelState extends ConsumerState<_SyncAlertsPanel> {
  /// Reçoit le focus après un « Écarter » (la carte écartée disparaît) : le
  /// texte d'introduction, en tête de la liste.
  final FocusNode _introFocus = FocusNode(debugLabel: 'syncAlertsIntro');

  @override
  void dispose() {
    _introFocus.dispose();
    super.dispose();
  }

  String _ownerId(SyncAlert alert) =>
      ref.read(syncOwnerIdProvider) ?? alert.ownerId;

  Future<void> _dismiss(SyncAlert alert) async {
    final l10n = AppLocalizations.of(context)!;
    final store = ref.read(syncAlertStoreProvider);
    try {
      await store.dismiss(ownerId: _ownerId(alert), id: alert.id);
    } catch (_) {
      // Écriture locale échouée : l'alerte reste affichée, rien à annuler.
      return;
    }
    if (!mounted) return;
    _introFocus.requestFocus();
    showUndoSnackBar(
      context,
      message: l10n.syncAlertsDismissedSnack,
      undoLabel: l10n.spellSlotUsedSnackBarUndoLabel,
      announcement: l10n.syncAlertsDismissedAnnouncement,
      onUndo: () => unawaited(store.restore(alert)),
    );
  }

  Future<void> _dismissAll(List<SyncAlert> alerts) async {
    if (alerts.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final store = ref.read(syncAlertStoreProvider);
    final List<SyncAlert> removed;
    try {
      removed = await store.dismissAll(ownerId: _ownerId(alerts.first));
    } catch (_) {
      return;
    }
    if (!mounted || removed.isEmpty) return;
    _introFocus.requestFocus();
    showUndoSnackBar(
      context,
      message: l10n.syncAlertsDismissedAllSnack(removed.length),
      undoLabel: l10n.spellSlotUsedSnackBarUndoLabel,
      announcement: l10n.syncAlertsDismissedAllAnnouncement(removed.length),
      onUndo: () => unawaited(_restoreAll(store, removed)),
    );
  }

  Future<void> _restoreAll(
    SyncAlertStore store,
    List<SyncAlert> removed,
  ) async {
    for (final alert in removed) {
      await store.restore(alert);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final alertsAsync = ref.watch(sortedSyncAlertsProvider);
    final known = ref.watch(knownCharacterIdsProvider);
    final now = ref.watch(syncClockProvider)();
    // Très grande police sur écran étroit (320 dp à x3,0) : marges réduites
    // pour que « emplacements » (12 lettres à 39 px) tienne sur une ligne.
    final dense = MediaQuery.textScalerOf(context).scale(13) / 13 > _denseScale;

    final Widget body;
    final alerts = alertsAsync.value;
    if (alertsAsync.hasError && alerts == null) {
      body = _LoadError(message: l10n.syncAlertsLoadError);
    } else if (alerts == null) {
      // Lecture locale en cours (quelques ms) : rien plutôt qu'un état vide
      // qui clignoterait.
      body = const SizedBox(height: AppSpacing.lg * 2);
    } else if (alerts.isEmpty) {
      body = _EmptyState(
        title: l10n.syncAlertsEmptyTitle,
        body: l10n.syncAlertsEmptyBody,
      );
    } else {
      body = ListView(
        shrinkWrap: true,
        padding: EdgeInsets.fromLTRB(
          dense ? AppSpacing.xs : AppSpacing.md,
          AppSpacing.md,
          dense ? AppSpacing.xs : AppSpacing.md,
          AppSpacing.lg,
        ),
        children: [
          Focus(
            focusNode: _introFocus,
            child: Text(
              l10n.syncAlertsSheetIntro,
              style: AppTypography.body(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (alerts.length >= 2) ...[
            SecondaryButton(
              label: l10n.syncAlertsDismissAll,
              surface: SecondaryButtonSurface.parchment,
              onPressed: () => unawaited(_dismissAll(alerts)),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          for (final alert in alerts) ...[
            _AlertCard(
              key: ValueKey('syncAlertCard-${alert.id}'),
              alert: alert,
              now: now,
              dense: dense,
              orphan: known != null && !known.contains(alert.characterId),
              onDismiss: () => unawaited(_dismiss(alert)),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.parchmentBg),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeaderBar(title: l10n.syncAlertsSheetTitle),
            Flexible(child: body),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.now,
    required this.orphan,
    required this.onDismiss,
    required this.dense,
    super.key,
  });

  final SyncAlert alert;
  final DateTime now;
  final bool orphan;
  final bool dense;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isConflict = alert.kind == SyncAlertKind.conflict;
    final kindLabel = isConflict
        ? l10n.syncAlertsKindConflict
        : l10n.syncAlertsKindAbandon;
    final when = relativeSyncWhen(l10n, instant: alert.createdAt, now: now);
    final dateLabel = isConflict ? l10n.syncAlertsSince(when) : when;
    final message = syncAlertMessage(l10n, alert, truncateName: false);
    final name = alert.characterName.isEmpty
        ? l10n.syncAlertUnknownCharacter
        : alert.characterName;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          dense ? AppSpacing.xs : AppSpacing.sm,
          AppSpacing.sm,
          dense ? AppSpacing.xs : AppSpacing.sm,
          AppSpacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Nœud sémantique de la carte : type + date + message complet
            // (+ mention d'orpheline), d'un seul tenant.
            Semantics(
              container: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isConflict
                                ? Icons.sync_problem
                                : Icons.cancel_outlined,
                            size: 18,
                            color: AppColors.accentBrick,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              kindLabel,
                              style: AppTypography.body(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        dateLabel,
                        style: AppTypography.body(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    message,
                    style: AppTypography.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (orphan) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(
                            Icons.info_outline,
                            size: 14,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            l10n.syncAlertsOrphan,
                            style: AppTypography.body(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Semantics(
                container: true,
                button: true,
                label: l10n.syncAlertsDismissSemantics(name),
                excludeSemantics: true,
                onTap: onDismiss,
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: InkWell(
                    onTap: onDismiss,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      child: Center(
                        widthFactor: 1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          child: Text(
                            l10n.syncAlertsDismiss,
                            style: AppTypography.body(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ).copyWith(decoration: TextDecoration.underline),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Semantics(
        liveRegion: true,
        container: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ExcludeSemantics(
              child: Icon(
                Icons.check_circle_outline,
                size: 32,
                color: AppColors.accentTeal,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.body(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              body,
              textAlign: TextAlign.center,
              style: AppTypography.body(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Semantics(
        liveRegion: true,
        container: true,
        child: Row(
          children: [
            const ExcludeSemantics(
              child: Icon(
                Icons.warning_amber_rounded,
                size: 20,
                color: AppColors.accentBrick,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTypography.body(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentBrick,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
