import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';

/// Libellé « Dernière synchronisation : … » du pied de page du Profil.
///
/// [lastSync] `null` : « jamais ». Sinon durée relative (< 1 min « à
/// l'instant », < 60 min « il y a N min », < 24 h « il y a N h ») ou, au-delà,
/// date absolue locale (« 10 nov. 2026 à 14:32 », `intl` dans la langue de
/// l'app). [pendingCount] > 0 ajoute le suffixe « · N en attente ». Pure : ni
/// horloge ni état — [now] est fourni par l'appelant.
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
    final elapsed = now.difference(lastSync);
    final String when;
    if (elapsed < const Duration(minutes: 1)) {
      // Inclut un écart négatif (horloge de l'appareil réglée en arrière).
      when = l10n.profileLastSyncJustNow;
    } else if (elapsed < const Duration(hours: 1)) {
      when = l10n.profileLastSyncMinutes(elapsed.inMinutes);
    } else if (elapsed < const Duration(hours: 24)) {
      when = l10n.profileLastSyncHours(elapsed.inHours);
    } else {
      final local = lastSync.toLocal();
      when = l10n.profileLastSyncAbsolute(
        DateFormat.yMMMd(l10n.localeName).format(local),
        DateFormat.Hm(l10n.localeName).format(local),
      );
    }
    base = l10n.profileLastSync(when);
  }
  return pendingCount > 0
      ? '$base${l10n.profileLastSyncPendingSuffix(pendingCount)}'
      : base;
}
