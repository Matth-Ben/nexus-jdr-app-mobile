import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../sync/sync_banner_engine.dart';
import '../sync/sync_status_providers.dart';
import 'alert_banner.dart';
import 'info_banner.dart';
import 'sync_alerts_sheet.dart';

/// Bandeau de synchro hors-ligne (T2 du chantier hors-ligne) : **un seul**
/// état visible à la fois, silencieux en usage normal. Réutilise
/// [InfoBanner]/[AlertBanner], aucune nouvelle couleur. L'état vient de
/// `syncBannerProvider` (précédence et temporisations : [SyncBannerEngine]).
///
/// [characterId] renseigné : bandeau de la fiche (compteur de CE personnage,
/// « Hors ligne » affiché même sans modification en attente). `null` : bandeau
/// de la liste (total du compte, hors-ligne seulement si N > 0).
///
/// [visiblePadding] : marges autour du bandeau **uniquement quand il est
/// visible** (le placement diffère entre la fiche et la liste, voir leurs
/// écrans) ; rien n'est réservé quand il est masqué.
///
/// Alertes persistées : un seul bandeau « {N} alerte(s) de synchronisation »
/// qui ouvre le panneau (`showSyncAlertsSheet`), voir [_AlertSummaryBanner].
///
/// Accessibilité : région live seulement pour l'alerte (apparition), le
/// passage hors-ligne (libellé fixe, sans compteur : un changement de N
/// n'est jamais ré-annoncé) et « Synchronisé » ; jamais pour « en cours » ni
/// « en attente ». Icône + texte, jamais la couleur seule.
class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({
    required this.visiblePadding,
    this.characterId,
    super.key,
  });

  final String? characterId;
  final EdgeInsets visiblePadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(syncBannerProvider(characterId: characterId));
    final l10n = AppLocalizations.of(context)!;

    final Widget? banner = switch (state.kind) {
      SyncBannerKind.none => null,
      SyncBannerKind.alert => _AlertSummaryBanner(
        count: state.alertCount,
        onTap: () => unawaited(showSyncAlertsSheet(context)),
      ),
      SyncBannerKind.syncing => InfoBanner(
        icon: Icons.sync,
        message: l10n.syncBannerSyncing,
      ),
      SyncBannerKind.offline => Semantics(
        liveRegion: true,
        container: true,
        label: l10n.syncBannerOfflineSemantics,
        child: ExcludeSemantics(
          child: InfoBanner(
            icon: Icons.cloud_off_outlined,
            message: state.pendingCount > 0
                ? l10n.syncBannerOfflinePending(state.pendingCount)
                : l10n.syncBannerOfflineEmpty,
          ),
        ),
      ),
      SyncBannerKind.pending => InfoBanner(
        icon: Icons.cloud_upload_outlined,
        message: l10n.syncBannerPendingOnline(state.pendingCount),
      ),
      SyncBannerKind.synced => Semantics(
        liveRegion: true,
        container: true,
        child: InfoBanner(icon: Icons.check, message: l10n.syncBannerSynced),
      ),
    };

    // Reduce motion : changement immédiat (même motif que `dice_roll_sheet`).
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);

    // Clé par nature d'état, jamais par compteur : un changement de N met le
    // texte à jour sur place, sans fondu (ni nouvelle annonce).
    final Widget content = banner == null
        ? const SizedBox(key: ValueKey('none'), width: double.infinity)
        : Padding(
            key: ValueKey(state.kind),
            padding: visiblePadding,
            child: banner,
          );
    // Reduce motion : changement immédiat, sans `AnimatedSize` (même motif que
    // `dice_roll_sheet`).
    if (reduceMotion) return content;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: content,
      ),
    );
  }
}

/// Bandeau « {N} alerte(s) de synchronisation · Voir les alertes » : entier
/// tappable, ouvre le panneau des alertes. Pas de bouton de fermeture : on
/// écarte les alertes depuis le panneau.
///
/// Sémantique : un seul nœud bouton « {N} alertes de synchronisation. Ouvrir
/// la liste. » (texte visible exclu). La région live n'est active qu'à
/// l'**apparition** du bandeau (premier rendu de cet état) : le widget la
/// retire dès l'image suivante, un changement de N ensuite met le libellé à
/// jour sans nouvelle annonce.
class _AlertSummaryBanner extends StatefulWidget {
  const _AlertSummaryBanner({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  State<_AlertSummaryBanner> createState() => _AlertSummaryBannerState();
}

class _AlertSummaryBannerState extends State<_AlertSummaryBanner> {
  bool _live = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _live = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      container: true,
      button: true,
      liveRegion: _live,
      label: l10n.syncAlertsBannerSemantics(widget.count),
      onTap: widget.onTap,
      excludeSemantics: true,
      child: AlertBanner(
        message: l10n.syncAlertsBannerCount(widget.count),
        actionLabel: l10n.syncAlertsBannerAction,
        onTap: widget.onTap,
      ),
    );
  }
}
