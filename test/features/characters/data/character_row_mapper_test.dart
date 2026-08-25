import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/data/character_row_mapper.dart';

void main() {
  group('classRowsOf', () {
    test('renvoie une liste vide si character_classes est absent', () {
      expect(CharacterRowMapper.classRowsOf({'id': 'c1'}), isEmpty);
    });

    test('renvoie les lignes character_classes imbriquées', () {
      final rows = CharacterRowMapper.classRowsOf({
        'character_classes': [
          {'class_id': 3, 'level': 5, 'is_primary': true},
        ],
      });
      expect(rows, [
        {'class_id': 3, 'level': 5, 'is_primary': true},
      ]);
    });
  });

  group('collectRaceIds / collectClassIds', () {
    test('normalise les identifiants int en String et déduplique', () {
      final rows = [
        {
          'race_id': 2,
          'character_classes': [
            {'class_id': 5, 'level': 3, 'is_primary': true},
          ],
        },
        {
          'race_id': 2,
          'character_classes': [
            {'class_id': 5, 'level': 1, 'is_primary': false},
            {'class_id': 7, 'level': 2, 'is_primary': false},
          ],
        },
      ];

      expect(CharacterRowMapper.collectRaceIds(rows), {'2'});
      expect(CharacterRowMapper.collectClassIds(rows), {'5', '7'});
    });

    test('ignore les ids nuls', () {
      final rows = [
        {'race_id': null, 'character_classes': <Map<String, dynamic>>[]},
      ];
      expect(CharacterRowMapper.collectRaceIds(rows), isEmpty);
      expect(CharacterRowMapper.collectClassIds(rows), isEmpty);
    });
  });

  group('parseTranslatedNames', () {
    test("lit les colonnes réelles entity_id/value (pas 'name')", () {
      final names = CharacterRowMapper.parseTranslatedNames([
        {'entity_id': '1', 'value': 'Humain'},
        {'entity_id': '2', 'value': 'Elfe'},
      ]);

      expect(names, {'1': 'Humain', '2': 'Elfe'});
    });

    test('ignore une ligne sans entity_id ou sans value exploitable', () {
      final names = CharacterRowMapper.parseTranslatedNames([
        {'entity_id': '1', 'value': null},
        {'entity_id': null, 'value': 'Orphelin'},
        {'entity_id': '3', 'value': 'Nain'},
      ]);

      expect(names, {'3': 'Nain'});
    });
  });

  group('toSummary', () {
    test('résout le nom de race/classe même si les ids arrivent en int côté '
        'characters et en String côté translations (mismatch de type '
        'reproduit à l\'identique du bug réel Supabase)', () {
      final summary = CharacterRowMapper.toSummary(
        {
          'id': 'char-1',
          'name': 'Halltesse',
          'portrait_url': null,
          'xp': 300,
          'race_id': 2, // int, comme renvoyé par PostgREST
          'character_classes': [
            {'class_id': 5, 'level': 3, 'is_primary': true},
          ],
        },
        raceNames: {'2': 'Elfe'}, // clé String, comme renvoyé par translations
        classNames: {'5': 'Magicienne'},
      );

      expect(summary.raceName, 'Elfe');
      expect(summary.className, 'Magicienne');
      expect(summary.level, 3);
    });

    test('personnage multiclassé : niveau total et classe principale', () {
      final summary = CharacterRowMapper.toSummary(
        {
          'id': 'char-2',
          'name': 'Borgan',
          'portrait_url': null,
          'xp': 0,
          'race_id': null,
          'character_classes': [
            {'class_id': 1, 'level': 2, 'is_primary': false},
            {'class_id': 2, 'level': 3, 'is_primary': true},
          ],
        },
        raceNames: const {},
        classNames: {'1': 'Guerrier', '2': 'Roublard'},
      );

      expect(summary.level, 5);
      expect(summary.className, 'Roublard');
      expect(summary.raceName, isNull);
    });

    test(
      'personnage sans character_classes retombe sur le niveau 1 sans crash',
      () {
        final summary = CharacterRowMapper.toSummary(
          {
            'id': 'char-3',
            'name': 'Sylvi',
            'portrait_url': null,
            'xp': 0,
            'race_id': null,
            'character_classes': <Map<String, dynamic>>[],
          },
          raceNames: const {},
          classNames: const {},
        );

        expect(summary.level, 1);
        expect(summary.className, isNull);
      },
    );

    test(
      'nom introuvable dans la map de traductions -> null plutôt que crash',
      () {
        final summary = CharacterRowMapper.toSummary(
          {
            'id': 'char-4',
            'name': 'Inconnu',
            'portrait_url': null,
            'xp': 0,
            'race_id': 99,
            'character_classes': <Map<String, dynamic>>[],
          },
          raceNames: const {}, // '99' absent
          classNames: const {},
        );

        expect(summary.raceName, isNull);
      },
    );
  });
}
