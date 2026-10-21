import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/data/level_up_draconic_ancestry_row_mapper.dart';

void main() {
  group('LevelUpDraconicAncestryRowMapper.collectIds', () {
    test('collecte les id en Set<String>', () {
      final rows = [
        {'id': 10, 'min_level': 1},
        {'id': 11, 'min_level': 1},
      ];
      expect(LevelUpDraconicAncestryRowMapper.collectIds(rows), {'10', '11'});
    });

    test('ignore une ligne sans id exploitable', () {
      final rows = [
        {'id': null, 'min_level': 1},
      ];
      expect(LevelUpDraconicAncestryRowMapper.collectIds(rows), isEmpty);
    });
  });

  group('LevelUpDraconicAncestryRowMapper.damageTypeFor', () {
    test('extrait prerequisites->>damage_type', () {
      final row = {
        'prerequisites': {'damage_type': 'feu'},
      };
      expect(LevelUpDraconicAncestryRowMapper.damageTypeFor(row), 'feu');
    });

    test('null si prerequisites absent ou vide', () {
      expect(LevelUpDraconicAncestryRowMapper.damageTypeFor({}), isNull);
      expect(
        LevelUpDraconicAncestryRowMapper.damageTypeFor({
          'prerequisites': <String, dynamic>{},
        }),
        isNull,
      );
      expect(
        LevelUpDraconicAncestryRowMapper.damageTypeFor({
          'prerequisites': {'damage_type': ''},
        }),
        isNull,
      );
    });
  });

  group('LevelUpDraconicAncestryRowMapper.toOptions', () {
    test('construit les options triées, avec type de dégâts', () {
      final rows = [
        {
          'id': 1,
          'min_level': 1,
          'prerequisites': {'damage_type': 'feu'},
        },
        {
          'id': 2,
          'min_level': 1,
          'prerequisites': {'damage_type': 'froid'},
        },
      ];

      final options = LevelUpDraconicAncestryRowMapper.toOptions(
        rows,
        names: const {'1': 'Dragon rouge', '2': 'Dragon blanc'},
        descriptions: const {
          '1': 'Description de Dragon rouge.',
          '2': 'Description de Dragon blanc.',
        },
      );

      expect(options.map((o) => o.name), ['Dragon blanc', 'Dragon rouge']);
      expect(options[0].damageType, 'froid');
      expect(options[1].damageType, 'feu');
    });

    test(
      'ignore une ligne sans damage_type résolu (contenu pas encore peuplé)',
      () {
        final rows = [
          {'id': 1, 'min_level': 1},
        ];

        final options = LevelUpDraconicAncestryRowMapper.toOptions(
          rows,
          names: const {'1': 'Dragon rouge'},
          descriptions: const {},
        );

        expect(options, isEmpty);
      },
    );

    test('un id sans nom résolu retombe sur un libellé générique', () {
      final rows = [
        {
          'id': 42,
          'min_level': 1,
          'prerequisites': {'damage_type': 'poison'},
        },
      ];

      final options = LevelUpDraconicAncestryRowMapper.toOptions(
        rows,
        names: const {},
        descriptions: const {},
      );

      expect(options.single.name, 'Ascendance #42');
      expect(options.single.description, '');
      expect(options.single.damageType, 'poison');
    });

    test('ignore une ligne sans id exploitable', () {
      final rows = [
        {
          'id': null,
          'min_level': 1,
          'prerequisites': {'damage_type': 'feu'},
        },
      ];

      final options = LevelUpDraconicAncestryRowMapper.toOptions(
        rows,
        names: const {},
        descriptions: const {},
      );

      expect(options, isEmpty);
    });
  });
}
