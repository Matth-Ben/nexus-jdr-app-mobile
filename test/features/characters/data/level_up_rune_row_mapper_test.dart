import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/data/level_up_rune_row_mapper.dart';

void main() {
  group('LevelUpRuneRowMapper.collectIds', () {
    test('collecte les id en Set<String>', () {
      final rows = [
        {'id': 10, 'min_level': 3},
        {'id': 11, 'min_level': 7},
      ];
      expect(LevelUpRuneRowMapper.collectIds(rows), {'10', '11'});
    });

    test('ignore une ligne sans id exploitable', () {
      final rows = [
        {'id': null, 'min_level': 3},
      ];
      expect(LevelUpRuneRowMapper.collectIds(rows), isEmpty);
    });
  });

  group('LevelUpRuneRowMapper.toOptions', () {
    test('construit les options triées alphabétiquement (français)', () {
      final rows = [
        {'id': 1, 'min_level': 3},
        {'id': 2, 'min_level': 7},
      ];

      final options = LevelUpRuneRowMapper.toOptions(
        rows,
        names: const {'1': 'Rune de Cloué', '2': 'Rune de Feu'},
        descriptions: const {
          '1': 'Description de Rune de Cloué.',
          '2': 'Description de Rune de Feu.',
        },
      );

      expect(options.map((o) => o.name), ['Rune de Cloué', 'Rune de Feu']);
      expect(options[0].id, 1);
    });

    test('un id sans nom résolu retombe sur un libellé générique', () {
      final rows = [
        {'id': 42, 'min_level': 3},
      ];

      final options = LevelUpRuneRowMapper.toOptions(
        rows,
        names: const {},
        descriptions: const {},
      );

      expect(options.single.name, 'Rune #42');
      expect(options.single.description, '');
    });

    test('ignore une ligne sans id exploitable', () {
      final rows = [
        {'id': null, 'min_level': 3},
      ];

      final options = LevelUpRuneRowMapper.toOptions(
        rows,
        names: const {},
        descriptions: const {},
      );

      expect(options, isEmpty);
    });
  });
}
