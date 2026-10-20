import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/data/level_up_infusion_row_mapper.dart';

void main() {
  group('LevelUpInfusionRowMapper.collectIds', () {
    test('collecte les id en Set<String>', () {
      final rows = [
        {'id': 10, 'min_level': 2},
        {'id': 11, 'min_level': 6},
      ];
      expect(LevelUpInfusionRowMapper.collectIds(rows), {'10', '11'});
    });

    test('ignore une ligne sans id exploitable', () {
      final rows = [
        {'id': null, 'min_level': 2},
      ];
      expect(LevelUpInfusionRowMapper.collectIds(rows), isEmpty);
    });
  });

  group('LevelUpInfusionRowMapper.prerequisiteTextFor', () {
    test('extrait prerequisites->>text', () {
      final row = {
        'prerequisites': {'text': 'Armure'},
      };
      expect(LevelUpInfusionRowMapper.prerequisiteTextFor(row), 'Armure');
    });

    test('null si prerequisites absent ou vide', () {
      expect(LevelUpInfusionRowMapper.prerequisiteTextFor({}), isNull);
      expect(
        LevelUpInfusionRowMapper.prerequisiteTextFor({
          'prerequisites': <String, dynamic>{},
        }),
        isNull,
      );
      expect(
        LevelUpInfusionRowMapper.prerequisiteTextFor({
          'prerequisites': {'text': ''},
        }),
        isNull,
      );
    });
  });

  group('LevelUpInfusionRowMapper.toOptions', () {
    test('construit les options triées, avec prérequis textuel', () {
      final rows = [
        {
          'id': 1,
          'min_level': 2,
          'prerequisites': {'text': 'Armure'},
        },
        {
          'id': 2,
          'min_level': 2,
          'prerequisites': {'text': 'Arme'},
        },
      ];

      final options = LevelUpInfusionRowMapper.toOptions(
        rows,
        names: const {'1': 'Armure renforcée', '2': 'Lame enchantée'},
        descriptions: const {
          '1': 'Description de Armure renforcée.',
          '2': 'Description de Lame enchantée.',
        },
      );

      expect(options.map((o) => o.name), [
        'Armure renforcée',
        'Lame enchantée',
      ]);
      expect(options[0].prerequisiteText, 'Armure');
      expect(options[1].prerequisiteText, 'Arme');
    });

    test('un id sans nom résolu retombe sur un libellé générique', () {
      final rows = [
        {'id': 42, 'min_level': 2},
      ];

      final options = LevelUpInfusionRowMapper.toOptions(
        rows,
        names: const {},
        descriptions: const {},
      );

      expect(options.single.name, 'Infusion #42');
      expect(options.single.description, '');
      expect(options.single.prerequisiteText, isNull);
    });

    test('ignore une ligne sans id exploitable', () {
      final rows = [
        {'id': null, 'min_level': 2},
      ];

      final options = LevelUpInfusionRowMapper.toOptions(
        rows,
        names: const {},
        descriptions: const {},
      );

      expect(options, isEmpty);
    });
  });
}
