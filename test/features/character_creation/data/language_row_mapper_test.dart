import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/data/language_row_mapper.dart';

void main() {
  group('collectIds', () {
    test('normalise les ids int en String et déduplique', () {
      final rows = [
        {'id': 1},
        {'id': 2},
        {'id': 1},
      ];
      expect(LanguageRowMapper.collectIds(rows), {'1', '2'});
    });

    test('ignore les ids nuls', () {
      expect(LanguageRowMapper.collectIds([{}]), isEmpty);
    });
  });

  group('parseTranslatedValues', () {
    test('lit les colonnes réelles entity_id/value', () {
      final values = LanguageRowMapper.parseTranslatedValues([
        {'entity_id': '1', 'value': 'Commun'},
        {'entity_id': '2', 'value': 'Nain'},
      ]);
      expect(values, {'1': 'Commun', '2': 'Nain'});
    });

    test('ignore une ligne sans entity_id ou sans value exploitable', () {
      final values = LanguageRowMapper.parseTranslatedValues([
        {'entity_id': '1', 'value': null},
        {'entity_id': null, 'value': 'Orphelin'},
        {'entity_id': '3', 'value': 'Elfique'},
      ]);
      expect(values, {'3': 'Elfique'});
    });
  });

  group('toLanguageOption', () {
    test('résout le nom via la map de traductions', () {
      final language = LanguageRowMapper.toLanguageOption(
        {'id': 1, 'type': 'standard'},
        names: {'1': 'Commun'},
      );

      expect(language.id, 1);
      expect(language.name, 'Commun');
      expect(language.type, 'standard');
    });

    test(
      'id sans traduction résolue -> libellé générique plutôt que crash',
      () {
        final language = LanguageRowMapper.toLanguageOption({
          'id': 99,
          'type': 'exotique',
        }, names: const {});

        expect(language.name, 'Langue #99');
        expect(language.type, 'exotique');
      },
    );

    test('type manquant -> retombe sur "standard"', () {
      final language = LanguageRowMapper.toLanguageOption(
        {'id': 5},
        names: {'5': 'Gnome'},
      );

      expect(language.type, 'standard');
    });
  });
}
