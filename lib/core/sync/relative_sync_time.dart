import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';

/// Date relative d'un événement de synchro : < 1 min « à l'instant », < 60 min
/// « il y a N min », < 24 h « il y a N h », au-delà date absolue locale
/// (« 10 nov. 2026 à 14:32 », `intl` dans la langue de l'app).
///
/// Formules partagées par le libellé « Dernière synchronisation » du Profil
/// (`lastSyncLabel`) et les cartes du panneau des alertes. Pure : ni horloge ni
/// état — [now] est fourni par l'appelant.
String relativeSyncWhen(
  AppLocalizations l10n, {
  required DateTime instant,
  required DateTime now,
}) {
  final elapsed = now.difference(instant);
  if (elapsed < const Duration(minutes: 1)) {
    // Inclut un écart négatif (horloge de l'appareil réglée en arrière).
    return l10n.profileLastSyncJustNow;
  }
  if (elapsed < const Duration(hours: 1)) {
    return l10n.profileLastSyncMinutes(elapsed.inMinutes);
  }
  if (elapsed < const Duration(hours: 24)) {
    return l10n.profileLastSyncHours(elapsed.inHours);
  }
  final local = instant.toLocal();
  return l10n.profileLastSyncAbsolute(
    DateFormat.yMMMd(l10n.localeName).format(local),
    DateFormat.Hm(l10n.localeName).format(local),
  );
}
