import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/data/level_up_metamagic_row_mapper.dart';

void main() {
  group('LevelUpMetamagicRowMapper.collectIds', () {
    test('collecte les id en Set<String>', () {
      final rows = [
        {'id': 10, 'min_level': 3},
        {'id': 11, 'min_level': 3},
      ];
      expect(LevelUpMetamagicRowMapper.collectIds(rows), {'10', '11'});
    });

    test('ignore une ligne sans id exploitable', () {
      final rows = [
        {'id': null, 'min_level': 3},
      ];
      expect(LevelUpMetamagicRowMapper.collectIds(rows), isEmpty);
    });
  });

  group('LevelUpMetamagicRowMapper.costTextFor', () {
    test('extrait prerequisites->>cost', () {
      final row = {
        'prerequisites': {'cost': '1 point de sorcellerie'},
      };
      expect(
        LevelUpMetamagicRowMapper.costTextFor(row),
        '1 point de sorcellerie',
      );
    });

    test('null si prerequisites absent ou vide', () {
      expect(LevelUpMetamagicRowMapper.costTextFor({}), isNull);
      expect(
        LevelUpMetamagicRowMapper.costTextFor({
          'prerequisites': <String, dynamic>{},
        }),
        isNull,
      );
      expect(
        LevelUpMetamagicRowMapper.costTextFor({
          'prerequisites': {'cost': ''},
        }),
        isNull,
      );
    });
  });

  group('LevelUpMetamagicRowMapper.toOptions', () {
    test('construit les options triées, avec coût', () {
      final rows = [
        {
          'id': 1,
          'min_level': 3,
          'prerequisites': {'cost': '2 points de sorcellerie'},
        },
        {
          'id': 2,
          'min_level': 3,
          'prerequisites': {'cost': '1 point de sorcellerie'},
        },
      ];

      final options = LevelUpMetamagicRowMapper.toOptions(
        rows,
        names: const {'1': 'Sort rapide', '2': 'Sort discret'},
        descriptions: const {
          '1': 'Description de Sort rapide.',
          '2': 'Description de Sort discret.',
        },
      );

      expect(options.map((o) => o.name), ['Sort discret', 'Sort rapide']);
      expect(options[0].costText, '1 point de sorcellerie');
      expect(options[1].costText, '2 points de sorcellerie');
    });

    test('un id sans nom résolu retombe sur un libellé générique', () {
      final rows = [
        {'id': 42, 'min_level': 3},
      ];

      final options = LevelUpMetamagicRowMapper.toOptions(
        rows,
        names: const {},
        descriptions: const {},
      );

      expect(options.single.name, 'Métamagie #42');
      expect(options.single.description, '');
      expect(options.single.costText, isNull);
    });

    test('ignore une ligne sans id exploitable', () {
      final rows = [
        {'id': null, 'min_level': 3},
      ];

      final options = LevelUpMetamagicRowMapper.toOptions(
        rows,
        names: const {},
        descriptions: const {},
      );

      expect(options, isEmpty);
    });
  });
}
