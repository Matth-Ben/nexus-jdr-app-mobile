import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/data/level_up_maneuver_row_mapper.dart';

void main() {
  group('LevelUpManeuverRowMapper.collectIds', () {
    test('collecte les id en Set<String>', () {
      final rows = [
        {'id': 10, 'min_level': 3},
        {'id': 11, 'min_level': 3},
      ];
      expect(LevelUpManeuverRowMapper.collectIds(rows), {'10', '11'});
    });

    test('ignore une ligne sans id exploitable', () {
      final rows = [
        {'id': null, 'min_level': 3},
      ];
      expect(LevelUpManeuverRowMapper.collectIds(rows), isEmpty);
    });
  });

  group('LevelUpManeuverRowMapper.toOptions', () {
    test('construit les options triées alphabétiquement (français)', () {
      final rows = [
        {'id': 1, 'min_level': 3},
        {'id': 2, 'min_level': 3},
      ];

      final options = LevelUpManeuverRowMapper.toOptions(
        rows,
        names: const {'1': 'Feinte', '2': 'Attaque déconcertante'},
        descriptions: const {
          '1': 'Description de Feinte.',
          '2': 'Description de Attaque déconcertante.',
        },
      );

      expect(options.map((o) => o.name), ['Attaque déconcertante', 'Feinte']);
      expect(options[0].id, 2);
      expect(options[0].description, 'Description de Attaque déconcertante.');
    });

    test('un id sans nom résolu retombe sur un libellé générique', () {
      final rows = [
        {'id': 42, 'min_level': 3},
      ];

      final options = LevelUpManeuverRowMapper.toOptions(
        rows,
        names: const {},
        descriptions: const {},
      );

      expect(options.single.name, 'Manœuvre #42');
      expect(options.single.description, '');
    });

    test('ignore une ligne sans id exploitable', () {
      final rows = [
        {'id': null, 'min_level': 3},
      ];

      final options = LevelUpManeuverRowMapper.toOptions(
        rows,
        names: const {},
        descriptions: const {},
      );

      expect(options, isEmpty);
    });
  });
}
