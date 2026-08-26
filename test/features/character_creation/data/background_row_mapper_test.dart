import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/data/background_row_mapper.dart';

void main() {
  group('collectIds', () {
    test('normalise les ids int en String et déduplique', () {
      final rows = [
        {'id': 1},
        {'id': 2},
        {'id': 1},
      ];
      expect(BackgroundRowMapper.collectIds(rows), {'1', '2'});
    });

    test('ignore les ids nuls', () {
      expect(BackgroundRowMapper.collectIds([{}]), isEmpty);
    });
  });

  group('parseTranslatedValues', () {
    test('lit les colonnes réelles entity_id/value', () {
      final values = BackgroundRowMapper.parseTranslatedValues([
        {'entity_id': '1', 'value': 'Ermite'},
        {'entity_id': '2', 'value': 'Soldat'},
      ]);
      expect(values, {'1': 'Ermite', '2': 'Soldat'});
    });

    test('ignore une ligne sans entity_id ou sans value exploitable', () {
      final values = BackgroundRowMapper.parseTranslatedValues([
        {'entity_id': '1', 'value': null},
        {'entity_id': null, 'value': 'Orphelin'},
        {'entity_id': '3', 'value': 'Noble'},
      ]);
      expect(values, {'3': 'Noble'});
    });
  });

  group('parseSkillProficiencies', () {
    test('lit la liste de noms de compétences telle quelle', () {
      expect(
        BackgroundRowMapper.parseSkillProficiencies(['Médecine', 'Religion']),
        ['Médecine', 'Religion'],
      );
    });

    test('type inattendu (null, map...) retombe sur une liste vide', () {
      expect(BackgroundRowMapper.parseSkillProficiencies(null), isEmpty);
      expect(BackgroundRowMapper.parseSkillProficiencies({'a': 1}), isEmpty);
    });

    test('ignore les entrées de la liste qui ne sont pas des chaînes', () {
      expect(
        BackgroundRowMapper.parseSkillProficiencies(['Médecine', 42, null]),
        ['Médecine'],
      );
    });

    test('liste explicitement vide -> liste vide (pas de crash sur le join '
        'de skillsSummaryLine)', () {
      expect(BackgroundRowMapper.parseSkillProficiencies(<String>[]), isEmpty);
    });

    test('plus de deux compétences sont toutes conservées, dans l\'ordre', () {
      expect(
        BackgroundRowMapper.parseSkillProficiencies([
          'Discrétion',
          'Escamotage',
          'Perception',
          'Investigation',
        ]),
        ['Discrétion', 'Escamotage', 'Perception', 'Investigation'],
      );
    });
  });

  group('toBackgroundOption', () {
    test('résout le nom, les compétences et l\'aptitude via les maps de '
        'traductions', () {
      final backgroundOption = BackgroundRowMapper.toBackgroundOption(
        {
          'id': 7,
          'skill_proficiencies': ['Médecine', 'Religion'],
        },
        names: {'7': 'Ermite'},
        featureNames: {'7': 'Découverte'},
        featureDescriptions: {
          '7': "un secret qui a changé ta vision du monde.",
        },
      );

      expect(backgroundOption.id, 7);
      expect(backgroundOption.name, 'Ermite');
      expect(backgroundOption.skillProficiencies, ['Médecine', 'Religion']);
      expect(
        backgroundOption.skillsSummaryLine,
        'Compétences : Médecine, Religion',
      );
      expect(backgroundOption.featureName, 'Découverte');
      expect(
        backgroundOption.featureSummaryLine,
        'Aptitude : Découverte — un secret qui a changé ta vision du monde.',
      );
    });

    test('trois compétences ou plus sont toutes reprises dans '
        'skillsSummaryLine', () {
      final backgroundOption = BackgroundRowMapper.toBackgroundOption(
        {
          'id': 11,
          'skill_proficiencies': ['Discrétion', 'Escamotage', 'Investigation'],
        },
        names: {'11': 'Criminel'},
        featureNames: {'11': 'Contact criminel'},
        featureDescriptions: {'11': 'un intermédiaire fiable.'},
      );

      expect(
        backgroundOption.skillsSummaryLine,
        'Compétences : Discrétion, Escamotage, Investigation',
      );
    });

    test('id sans traduction résolue -> libellé générique et aptitude vide '
        'plutôt que crash', () {
      final backgroundOption = BackgroundRowMapper.toBackgroundOption(
        {'id': 99, 'skill_proficiencies': <String>[]},
        names: const {},
        featureNames: const {},
        featureDescriptions: const {},
      );

      expect(backgroundOption.name, 'Historique #99');
      expect(backgroundOption.featureName, isEmpty);
      expect(backgroundOption.featureDescription, isEmpty);
      expect(backgroundOption.skillProficiencies, isEmpty);
    });

    test('skill_proficiencies manquant (null) -> liste vide, résolution des '
        'autres champs indépendante', () {
      final backgroundOption = BackgroundRowMapper.toBackgroundOption(
        {'id': 5, 'skill_proficiencies': null},
        names: {'5': 'Noble'},
        featureNames: {'5': 'Position privilégiée'},
        featureDescriptions: const {},
      );

      expect(backgroundOption.name, 'Noble');
      expect(backgroundOption.skillProficiencies, isEmpty);
      expect(backgroundOption.featureName, 'Position privilégiée');
      expect(backgroundOption.featureDescription, isEmpty);
    });

    test('seul le nom manque à la traduction -> libellé générique, aptitude '
        'et compétences résolues normalement', () {
      final backgroundOption = BackgroundRowMapper.toBackgroundOption(
        {
          'id': 3,
          'skill_proficiencies': ['Arcanes'],
        },
        names: const {},
        featureNames: {'3': 'Recherche magique'},
        featureDescriptions: {'3': 'accès à une bibliothèque savante.'},
      );

      expect(backgroundOption.name, 'Historique #3');
      expect(backgroundOption.featureName, 'Recherche magique');
      expect(
        backgroundOption.featureDescription,
        'accès à une bibliothèque savante.',
      );
      expect(backgroundOption.skillProficiencies, ['Arcanes']);
    });

    test('seule l\'aptitude (nom) manque à la traduction -> nom et '
        'compétences résolus, featureName vide', () {
      final backgroundOption = BackgroundRowMapper.toBackgroundOption(
        {
          'id': 4,
          'skill_proficiencies': ['Survie'],
        },
        names: {'4': 'Exilé'},
        featureNames: const {},
        featureDescriptions: {'4': 'une description orpheline de son titre.'},
      );

      expect(backgroundOption.name, 'Exilé');
      expect(backgroundOption.featureName, isEmpty);
      expect(
        backgroundOption.featureDescription,
        'une description orpheline de son titre.',
      );
      expect(
        backgroundOption.featureSummaryLine,
        'Aptitude :  — une description orpheline de son titre.',
      );
    });

    test('toBackgroundOption relaie tool_or_language_choices vers '
        'parseToolOrLanguageGrantedTools/parseLanguageChoiceCount', () {
      final backgroundOption = BackgroundRowMapper.toBackgroundOption(
        {
          'id': 30,
          'skill_proficiencies': <String>[],
          'tool_or_language_choices': {
            'tools': ['Kit de déguisement'],
            'languages': 2,
          },
        },
        names: const {},
        featureNames: const {},
        featureDescriptions: const {},
      );

      expect(backgroundOption.toolOrLanguageGrantedTools, [
        'Kit de déguisement',
      ]);
      expect(backgroundOption.languageChoiceCount, 2);
    });

    test('tool_or_language_choices absent -> toolOrLanguageGrantedTools vide, '
        'languageChoiceCount null', () {
      final backgroundOption = BackgroundRowMapper.toBackgroundOption(
        {'id': 31, 'skill_proficiencies': <String>[]},
        names: const {},
        featureNames: const {},
        featureDescriptions: const {},
      );

      expect(backgroundOption.toolOrLanguageGrantedTools, isEmpty);
      expect(backgroundOption.languageChoiceCount, isNull);
    });
  });

  group('parseToolOrLanguageGrantedTools', () {
    test('clé "tools" (tableau de chaînes) -> conservée telle quelle', () {
      expect(
        BackgroundRowMapper.parseToolOrLanguageGrantedTools({
          'tools': ['Kit de déguisement', 'un jeu au choix'],
        }),
        ['Kit de déguisement', 'un jeu au choix'],
      );
    });

    test('clé "tools" absente -> liste vide', () {
      expect(
        BackgroundRowMapper.parseToolOrLanguageGrantedTools({'languages': 2}),
        isEmpty,
      );
    });

    test('type inattendu (null, liste au lieu de map) -> liste vide', () {
      expect(
        BackgroundRowMapper.parseToolOrLanguageGrantedTools(null),
        isEmpty,
      );
      expect(
        BackgroundRowMapper.parseToolOrLanguageGrantedTools(['tools']),
        isEmpty,
      );
    });

    test(
      'clé "tools" avec un type inattendu (pas une liste) -> liste vide',
      () {
        expect(
          BackgroundRowMapper.parseToolOrLanguageGrantedTools({
            'tools': 'un instrument de musique au choix',
          }),
          isEmpty,
        );
      },
    );

    test('clé "vehicles" présente à côté de "tools" -> ignorée, "tools" quand '
        'même résolu', () {
      expect(
        BackgroundRowMapper.parseToolOrLanguageGrantedTools({
          'tools': ["Kit d'artisan"],
          'vehicles': ['un véhicule terrestre'],
        }),
        ["Kit d'artisan"],
      );
    });
  });

  group('parseLanguageChoiceCount', () {
    test('clé "languages" (entier) -> conservée telle quelle', () {
      expect(BackgroundRowMapper.parseLanguageChoiceCount({'languages': 2}), 2);
    });

    test('clé "languages" absente -> null (pas de choix octroyé)', () {
      expect(
        BackgroundRowMapper.parseLanguageChoiceCount({
          'tools': ['Kit de déguisement'],
        }),
        isNull,
      );
    });

    test('type inattendu (null, liste au lieu de map) -> null', () {
      expect(BackgroundRowMapper.parseLanguageChoiceCount(null), isNull);
      expect(
        BackgroundRowMapper.parseLanguageChoiceCount(['languages']),
        isNull,
      );
    });

    test('clé "languages" avec un type inattendu (pas un nombre) -> null', () {
      expect(
        BackgroundRowMapper.parseLanguageChoiceCount({'languages': 'deux'}),
        isNull,
      );
    });

    test('clé "vehicles" présente à côté de "languages" -> ignorée, '
        '"languages" quand même résolu (hors périmètre étape 5/9)', () {
      expect(
        BackgroundRowMapper.parseLanguageChoiceCount({
          'languages': 1,
          'vehicles': ['un véhicule aquatique'],
        }),
        1,
      );
    });
  });
}
