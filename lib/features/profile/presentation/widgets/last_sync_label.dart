import '../../../../core/sync/relative_sync_time.dart';
import '../../../../l10n/app_localizations.dart';

/// Libellé « Dernière synchronisation : … » du pied de page du Profil.
///
/// [lastSync] `null` : « jamais ». Sinon durée relative (< 1 min « à
/// l'instant », < 60 min « il y a N min », < 24 h « il y a N h ») ou, au-delà,
/// date absolue locale (« 10 nov. 2026 à 14:32 », `intl` dans la langue de
/// l'app) — formules de [relativeSyncWhen], partagées avec le panneau des
/// alertes de synchro. [pendingCount] > 0 ajoute le suffixe « · N en
/// attente ». Pure : ni horloge ni état — [now] est fourni par l'appelant.
String lastSyncLabel(
  AppLocalizations l10n, {
  required DateTime? lastSync,
  required DateTime now,
  required int pendingCount,
}) {
  final String base;
  if (lastSync == null) {
    base = l10n.profileLastSyncNever;
  } else {
    base = l10n.profileLastSync(
      relativeSyncWhen(l10n, instant: lastSync, now: now),
    );
  }
  return pendingCount > 0
      ? '$base${l10n.profileLastSyncPendingSuffix(pendingCount)}'
      : base;
}
