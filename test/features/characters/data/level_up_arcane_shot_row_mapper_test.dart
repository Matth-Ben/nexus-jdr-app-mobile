import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/data/level_up_arcane_shot_row_mapper.dart';

void main() {
  group('LevelUpArcaneShotRowMapper.collectIds', () {
    test('collecte les id en Set<String>', () {
      final rows = [
        {'id': 10, 'min_level': 3},
        {'id': 11, 'min_level': 3},
      ];
      expect(LevelUpArcaneShotRowMapper.collectIds(rows), {'10', '11'});
    });

    test('ignore une ligne sans id exploitable', () {
      final rows = [
        {'id': null, 'min_level': 3},
      ];
      expect(LevelUpArcaneShotRowMapper.collectIds(rows), isEmpty);
    });
  });

  group('LevelUpArcaneShotRowMapper.toOptions', () {
    test('construit les options triées alphabétiquement (français)', () {
      final rows = [
        {'id': 1, 'min_level': 3},
        {'id': 2, 'min_level': 3},
      ];

      final options = LevelUpArcaneShotRowMapper.toOptions(
        rows,
        names: const {'1': 'Tir explosif', '2': 'Décharge foudroyante'},
        descriptions: const {
          '1': 'Description du tir explosif.',
          '2': 'Description de la décharge foudroyante.',
        },
      );

      expect(options.map((o) => o.name), [
        'Décharge foudroyante',
        'Tir explosif',
      ]);
      expect(options[0].id, 2);
      expect(options[1].description, 'Description du tir explosif.');
    });

    test('un id sans nom résolu retombe sur un libellé générique', () {
      final rows = [
        {'id': 42, 'min_level': 3},
      ];

      final options = LevelUpArcaneShotRowMapper.toOptions(
        rows,
        names: const {},
        descriptions: const {},
      );

      expect(options.single.name, 'Tir arcanique #42');
      expect(options.single.description, '');
    });

    test('ignore une ligne sans id exploitable', () {
      final rows = [
        {'id': null, 'min_level': 3},
      ];

      final options = LevelUpArcaneShotRowMapper.toOptions(
        rows,
        names: const {},
        descriptions: const {},
      );

      expect(options, isEmpty);
    });
  });
}
