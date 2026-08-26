import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/data/class_row_mapper.dart';
import 'package:personnages/features/character_creation/domain/skill_ability_mapping.dart';

void main() {
  group('collectIds', () {
    test('normalise les ids int en String et déduplique', () {
      final rows = [
        {'id': 1},
        {'id': 2},
        {'id': 1},
      ];
      expect(ClassRowMapper.collectIds(rows), {'1', '2'});
    });

    test('ignore les ids nuls', () {
      expect(ClassRowMapper.collectIds([{}]), isEmpty);
    });
  });

  group('parseTranslatedValues', () {
    test('lit les colonnes réelles entity_id/value', () {
      final values = ClassRowMapper.parseTranslatedValues([
        {'entity_id': '1', 'value': 'Magicien'},
        {'entity_id': '2', 'value': 'Guerrier'},
      ]);
      expect(values, {'1': 'Magicien', '2': 'Guerrier'});
    });

    test('ignore une ligne sans entity_id ou sans value exploitable', () {
      final values = ClassRowMapper.parseTranslatedValues([
        {'entity_id': '1', 'value': null},
        {'entity_id': null, 'value': 'Orphelin'},
        {'entity_id': '3', 'value': 'Roublard'},
      ]);
      expect(values, {'3': 'Roublard'});
    });
  });

  group('toClassOption', () {
    test('résout le nom et la description via les maps de traductions', () {
      final classOption = ClassRowMapper.toClassOption(
        {'id': 1, 'hit_die': 6},
        names: {'1': 'Magicien'},
        descriptions: {
          '1':
              'Érudit de la magie arcanique, dont le pouvoir vient de '
              "l'étude et d'un grimoire.",
        },
      );

      expect(classOption.id, 1);
      expect(classOption.name, 'Magicien');
      expect(
        classOption.summaryLine,
        'Érudit de la magie arcanique, dont le pouvoir vient de '
        "l'étude et d'un grimoire. · dé de vie d6",
      );
    });

    test(
      'id sans traduction résolue -> libellé générique plutôt que crash',
      () {
        final classOption = ClassRowMapper.toClassOption(
          {'id': 99, 'hit_die': 8},
          names: const {},
          descriptions: const {},
        );

        expect(classOption.name, 'Classe #99');
        expect(classOption.description, isEmpty);
        expect(classOption.summaryLine, 'dé de vie d8');
      },
    );

    test('nom résolu mais description manquante -> description vide, nom '
        'conservé (résolution indépendante des deux maps)', () {
      final classOption = ClassRowMapper.toClassOption(
        {'id': 5, 'hit_die': 10},
        names: {'5': 'Guerrier'},
        descriptions: const {},
      );

      expect(classOption.name, 'Guerrier');
      expect(classOption.description, isEmpty);
      expect(classOption.summaryLine, 'dé de vie d10');
    });

    test('description résolue mais nom manquant -> libellé générique mais '
        'description conservée (résolution indépendante des deux maps)', () {
      final classOption = ClassRowMapper.toClassOption(
        {'id': 7, 'hit_die': 8},
        names: const {},
        descriptions: {'7': 'Combattant polyvalent.'},
      );

      expect(classOption.name, 'Classe #7');
      expect(classOption.description, 'Combattant polyvalent.');
      expect(classOption.summaryLine, 'Combattant polyvalent. · dé de vie d8');
    });

    test('toClassOption relaie skill_choices/tool_proficiencies vers '
        'parseSkillChoices/parseToolChoice/parseGrantedToolNames', () {
      final classOption = ClassRowMapper.toClassOption(
        {
          'id': 8,
          'hit_die': 8,
          'skill_choices': {
            'count': 3,
            'choices': ['Arcanes', 'Histoire'],
          },
          'tool_proficiencies': {'count': 1, 'type': 'instrument'},
        },
        names: const {},
        descriptions: const {},
      );

      expect(classOption.skillChoices.count, 3);
      expect(classOption.skillChoices.choices, ['Arcanes', 'Histoire']);
      expect(classOption.toolChoice?.count, 1);
      expect(classOption.toolChoice?.categories, ['instrument']);
      expect(classOption.grantedToolNames, isEmpty);
    });

    test('toClassOption avec tool_proficiencies en liste de noms précis '
        '(Druide/Roublard) -> grantedToolNames peuplé, toolChoice null', () {
      final classOption = ClassRowMapper.toClassOption(
        {
          'id': 9,
          'hit_die': 8,
          'skill_choices': {'count': 2, 'choices': []},
          'tool_proficiencies': ["outils d'herboriste"],
        },
        names: const {},
        descriptions: const {},
      );

      expect(classOption.toolChoice, isNull);
      expect(classOption.grantedToolNames, ["outils d'herboriste"]);
    });
  });

  group('parseSkillChoices', () {
    test('type inattendu (null, liste...) retombe sur count:0, choices:[]', () {
      final fromNull = ClassRowMapper.parseSkillChoices(null);
      expect(fromNull.count, 0);
      expect(fromNull.choices, isEmpty);

      final fromList = ClassRowMapper.parseSkillChoices(['pas', 'une', 'map']);
      expect(fromList.count, 0);
      expect(fromList.choices, isEmpty);
    });

    test('forme {"count", "choices": [...]} -> count et liste tels quels', () {
      final result = ClassRowMapper.parseSkillChoices({
        'count': 2,
        'choices': ['Arcanes', 'Histoire', 'Religion'],
      });
      expect(result.count, 2);
      expect(result.choices, ['Arcanes', 'Histoire', 'Religion']);
    });

    test('forme {"count": 3, "choices": "toutes"} (Barde) -> développée en les '
        '18 compétences complètes', () {
      final result = ClassRowMapper.parseSkillChoices({
        'count': 3,
        'choices': 'toutes',
      });
      expect(result.count, 3);
      expect(result.choices, SkillAbilityMapping.allSkillNames);
      expect(result.choices.length, 18);
    });

    test('count manquant -> 0', () {
      final result = ClassRowMapper.parseSkillChoices({
        'choices': ['Arcanes'],
      });
      expect(result.count, 0);
    });

    test('choices ni liste ni "toutes" -> liste vide', () {
      final result = ClassRowMapper.parseSkillChoices({
        'count': 2,
        'choices': 42,
      });
      expect(result.choices, isEmpty);
    });

    test('choices contenant des entrées non-String -> ignorées', () {
      final result = ClassRowMapper.parseSkillChoices({
        'count': 2,
        'choices': ['Arcanes', 42, null],
      });
      expect(result.choices, ['Arcanes']);
    });
  });

  group('parseToolChoice', () {
    test('tool_proficiencies vide ([]) -> null (ni choix, ni octroi)', () {
      expect(ClassRowMapper.parseToolChoice(<dynamic>[]), isNull);
    });

    test('type inattendu (null) -> null', () {
      expect(ClassRowMapper.parseToolChoice(null), isNull);
    });

    test('map sans count ou sans type -> null', () {
      expect(ClassRowMapper.parseToolChoice({'type': 'instrument'}), isNull);
      expect(ClassRowMapper.parseToolChoice({'count': 1}), isNull);
    });

    test('type "instrument" -> categories: [instrument]', () {
      final result = ClassRowMapper.parseToolChoice({
        'count': 1,
        'type': 'instrument',
      });
      expect(result?.count, 1);
      expect(result?.categories, ['instrument']);
    });

    test('type "jeu" -> categories: [jeu]', () {
      final result = ClassRowMapper.parseToolChoice({
        'count': 1,
        'type': 'jeu',
      });
      expect(result?.categories, ['jeu']);
    });

    test('type "outils_artisan" -> categories: [outils_artisan]', () {
      final result = ClassRowMapper.parseToolChoice({
        'count': 1,
        'type': 'outils_artisan',
      });
      expect(result?.categories, ['outils_artisan']);
    });

    test('type "outils_artisan_ou_instrument" (Moine) -> développé en DEUX '
        'catégories réelles [outils_artisan, instrument]', () {
      final result = ClassRowMapper.parseToolChoice({
        'count': 1,
        'type': 'outils_artisan_ou_instrument',
      });
      expect(result?.categories, ['outils_artisan', 'instrument']);
    });

    test('type jsonb inconnu -> categories vide plutôt que crash', () {
      final result = ClassRowMapper.parseToolChoice({
        'count': 1,
        'type': 'type_inconnu',
      });
      expect(result?.categories, isEmpty);
    });
  });

  group('parseGrantedToolNames', () {
    test('tool_proficiencies vide ([]) -> liste vide', () {
      expect(ClassRowMapper.parseGrantedToolNames(<dynamic>[]), isEmpty);
    });

    test('liste de noms d\'outils précis (Druide, Roublard) -> conservée', () {
      expect(ClassRowMapper.parseGrantedToolNames(["outils d'herboriste"]), [
        "outils d'herboriste",
      ]);
      expect(ClassRowMapper.parseGrantedToolNames(['outils de voleur']), [
        'outils de voleur',
      ]);
    });

    test('forme {"count", "type"} (objet, pas une liste) -> liste vide, jamais '
        'confondue avec un octroi', () {
      expect(
        ClassRowMapper.parseGrantedToolNames({
          'count': 1,
          'type': 'instrument',
        }),
        isEmpty,
      );
    });

    test('type inattendu (null) -> liste vide', () {
      expect(ClassRowMapper.parseGrantedToolNames(null), isEmpty);
    });

    test('entrées non-String de la liste sont ignorées', () {
      expect(
        ClassRowMapper.parseGrantedToolNames(['outils de voleur', 42, null]),
        ['outils de voleur'],
      );
    });
  });
}
