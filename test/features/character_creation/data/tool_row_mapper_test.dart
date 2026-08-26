import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/data/tool_row_mapper.dart';

void main() {
  group('collectIds', () {
    test('normalise les ids int en String et déduplique', () {
      final rows = [
        {'id': 1},
        {'id': 2},
        {'id': 1},
      ];
      expect(ToolRowMapper.collectIds(rows), {'1', '2'});
    });

    test('ignore les ids nuls', () {
      expect(ToolRowMapper.collectIds([{}]), isEmpty);
    });
  });

  group('parseTranslatedValues', () {
    test('lit les colonnes réelles entity_id/value', () {
      final values = ToolRowMapper.parseTranslatedValues([
        {'entity_id': '1', 'value': 'Luth'},
        {'entity_id': '2', 'value': "Outils d'herboriste"},
      ]);
      expect(values, {'1': 'Luth', '2': "Outils d'herboriste"});
    });

    test('ignore une ligne sans entity_id ou sans value exploitable', () {
      final values = ToolRowMapper.parseTranslatedValues([
        {'entity_id': '1', 'value': null},
        {'entity_id': null, 'value': 'Orphelin'},
        {'entity_id': '3', 'value': 'Kit de forgeron'},
      ]);
      expect(values, {'3': 'Kit de forgeron'});
    });
  });

  group('toToolOption', () {
    test('résout le nom via la map de traductions', () {
      final tool = ToolRowMapper.toToolOption(
        {'id': 1, 'category': 'instrument'},
        names: {'1': 'Luth'},
      );

      expect(tool.id, 1);
      expect(tool.name, 'Luth');
      expect(tool.category, 'instrument');
    });

    test(
      'id sans traduction résolue -> libellé générique plutôt que crash',
      () {
        final tool = ToolRowMapper.toToolOption({
          'id': 99,
          'category': 'jeu',
        }, names: const {});

        expect(tool.name, 'Outil #99');
        expect(tool.category, 'jeu');
      },
    );

    test('catégorie manquante -> retombe sur "autre"', () {
      final tool = ToolRowMapper.toToolOption(
        {'id': 5},
        names: {'5': 'Kit de déguisement'},
      );

      expect(tool.category, 'autre');
    });
  });
}
