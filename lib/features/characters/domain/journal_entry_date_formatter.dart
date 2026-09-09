/// Formate la date d'une entrée de journal (`CharacterJournalEntry
/// .createdAt`) pour l'onglet "Histoire" — voir
/// `presentation/widgets/character_journal_card.dart`.
///
/// Formatage manuel plutôt que `package:intl` (absente de ce dépôt, voir
/// `pubspec.yaml`) : cette app est entièrement en français, sans besoin de
/// localisation multi-langue qui justifierait la dépendance — même rationale
/// que `weight_formatter.dart`/`gold_amount_formatter.dart` (formatage
/// numérique français fait main).
abstract final class JournalEntryDateFormatter {
  static const List<String> _months = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];

  /// Ex. "9 septembre 2026 · 18:32", toujours en heure locale de l'appareil
  /// (`DateTime.toLocal`) — [dateTime] vient de `character_journal_entries
  /// .created_at` (`timestamptz`, donc déjà en UTC côté base).
  static String format(DateTime dateTime) {
    final local = dateTime.toLocal();
    final month = _months[local.month - 1];
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.day} $month ${local.year} · $hour:$minute';
  }
}
