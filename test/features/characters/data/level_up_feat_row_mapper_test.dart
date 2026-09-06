import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/data/level_up_feat_row_mapper.dart';

void main() {
  group('LevelUpFeatRowMapper.collectFeatIds', () {
    test('collecte les id en Set<String>, ignore les lignes sans id', () {
      final rows = [
        {'id': 3, 'prerequisites': <String, dynamic>{}},
        {'id': 5, 'prerequisites': <String, dynamic>{}},
        {'prerequisites': <String, dynamic>{}},
      ];
      expect(LevelUpFeatRowMapper.collectFeatIds(rows), {'3', '5'});
    });
  });

  group('LevelUpFeatRowMapper.prerequisiteTextFor', () {
    test('extrait prerequisites->>text', () {
      final row = {
        'id': 1,
        'prerequisites': {'text': 'Force 13 ou plus'},
      };
      expect(LevelUpFeatRowMapper.prerequisiteTextFor(row), 'Force 13 ou plus');
    });

    test('null si la clé text est absente', () {
      final row = {'id': 1, 'prerequisites': <String, dynamic>{}};
      expect(LevelUpFeatRowMapper.prerequisiteTextFor(row), isNull);
    });

    test('null si le texte est vide', () {
      final row = {
        'id': 1,
        'prerequisites': {'text': ''},
      };
      expect(LevelUpFeatRowMapper.prerequisiteTextFor(row), isNull);
    });

    test('null si prerequisites n\'est pas un objet JSON (défensif)', () {
      final row = {'id': 1, 'prerequisites': 'invalide'};
      expect(LevelUpFeatRowMapper.prerequisiteTextFor(row), isNull);
    });

    test('null si prerequisites est absent', () {
      final row = {'id': 1};
      expect(LevelUpFeatRowMapper.prerequisiteTextFor(row), isNull);
    });
  });

  group('LevelUpFeatRowMapper.toFeatOptions', () {
    test('construit les options avec noms/descriptions résolus, triées '
        'alphabétiquement', () {
      final rows = [
        {'id': 1, 'prerequisites': <String, dynamic>{}},
        {
          'id': 2,
          'prerequisites': {'text': 'Dextérité 13 ou plus'},
        },
      ];

      final options = LevelUpFeatRowMapper.toFeatOptions(
        rows,
        names: {'1': 'Vigilant', '2': 'Archer d\'élite'},
        descriptions: {'1': 'Description Vigilant', '2': 'Description Archer'},
      );

      expect(options, hasLength(2));
      // Triées alphabétiquement : "Archer d'élite" avant "Vigilant".
      expect(options[0].name, "Archer d'élite");
      expect(options[0].id, 2);
      expect(options[0].prerequisiteText, 'Dextérité 13 ou plus');
      expect(options[0].description, 'Description Archer');
      expect(options[1].name, 'Vigilant');
      expect(options[1].prerequisiteText, isNull);
    });

    test('nom de repli "Don #<id>" si absent de names (défensif)', () {
      final rows = [
        {'id': 42, 'prerequisites': <String, dynamic>{}},
      ];

      final options = LevelUpFeatRowMapper.toFeatOptions(
        rows,
        names: const {},
        descriptions: const {},
      );

      expect(options.single.name, 'Don #42');
      expect(options.single.description, '');
    });

    test('ignore les lignes sans id', () {
      final rows = [
        <String, dynamic>{'prerequisites': <String, dynamic>{}},
      ];

      final options = LevelUpFeatRowMapper.toFeatOptions(
        rows,
        names: const {},
        descriptions: const {},
      );

      expect(options, isEmpty);
    });

    test('liste vide en entrée -> liste vide en sortie', () {
      expect(
        LevelUpFeatRowMapper.toFeatOptions(
          const [],
          names: const {},
          descriptions: const {},
        ),
        isEmpty,
      );
    });
  });
}
