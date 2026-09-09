import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/journal_entry_date_formatter.dart';

void main() {
  group('JournalEntryDateFormatter.format', () {
    test('formate jour/mois en toutes lettres/année · heure:minute', () {
      final dateTime = DateTime(2026, 9, 9, 18, 32);
      expect(
        JournalEntryDateFormatter.format(dateTime),
        '9 septembre 2026 · 18:32',
      );
    });

    test('heures/minutes toujours sur 2 chiffres', () {
      final dateTime = DateTime(2026, 1, 1, 5, 4);
      expect(
        JournalEntryDateFormatter.format(dateTime),
        '1 janvier 2026 · 05:04',
      );
    });

    test('les 12 mois sont correctement libellés', () {
      const expected = [
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
      for (var month = 1; month <= 12; month++) {
        final formatted = JournalEntryDateFormatter.format(
          DateTime(2026, month, 15, 0, 0),
        );
        expect(formatted, contains(expected[month - 1]));
      }
    });
  });
}
