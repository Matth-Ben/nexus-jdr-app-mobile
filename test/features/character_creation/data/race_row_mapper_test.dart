import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/data/race_row_mapper.dart';
import 'package:personnages/features/character_creation/domain/class_skill_choices.dart';
import 'package:personnages/features/character_creation/domain/race_trait.dart';
import 'package:personnages/features/character_creation/domain/tool_catalog.dart';
import 'package:personnages/features/character_creation/domain/tool_option.dart';

const _toolsCatalog = ToolCatalog(
  tools: [
    ToolOption(id: 1, name: 'Outils de forgeron', category: 'outils_artisan'),
    ToolOption(id: 2, name: 'Outils de brasseur', category: 'outils_artisan'),
    ToolOption(id: 3, name: 'Outils de maçon', category: 'outils_artisan'),
    ToolOption(id: 4, name: 'Luth', category: 'instrument'),
    ToolOption(id: 5, name: 'Flûte', category: 'instrument'),
    ToolOption(id: 6, name: 'Dés à jouer', category: 'jeu'),
  ],
);

void main() {
  group('collectIds', () {
    test('normalise les ids int en String et déduplique', () {
      final rows = [
        {'id': 1},
        {'id': 2},
        {'id': 1},
      ];
      expect(RaceRowMapper.collectIds(rows), {'1', '2'});
    });

    test('ignore les ids nuls', () {
      expect(RaceRowMapper.collectIds([{}]), isEmpty);
    });
  });

  group('parseTranslatedNames', () {
    test('lit les colonnes réelles entity_id/value', () {
      final names = RaceRowMapper.parseTranslatedNames([
        {'entity_id': '1', 'value': 'Elfe'},
        {'entity_id': '2', 'value': 'Nain'},
      ]);
      expect(names, {'1': 'Elfe', '2': 'Nain'});
    });

    test('ignore une ligne sans entity_id ou sans value exploitable', () {
      final names = RaceRowMapper.parseTranslatedNames([
        {'entity_id': '1', 'value': null},
        {'entity_id': null, 'value': 'Orphelin'},
        {'entity_id': '3', 'value': 'Halfelin'},
      ]);
      expect(names, {'3': 'Halfelin'});
    });
  });

  group('parseAbilityBonuses', () {
    test('convertit un jsonb Map en Map<String, dynamic>', () {
      expect(RaceRowMapper.parseAbilityBonuses({'dex': 2}), {'dex': 2});
    });

    test('conserve la clé spéciale choice_others telle quelle', () {
      final parsed = RaceRowMapper.parseAbilityBonuses({
        'cha': 2,
        'choice_others': {'amount': 1, 'count': 2},
      });
      expect(parsed['cha'], 2);
      expect(parsed['choice_others'], {'amount': 1, 'count': 2});
    });

    test('null ou type inattendu -> map vide', () {
      expect(RaceRowMapper.parseAbilityBonuses(null), isEmpty);
      expect(RaceRowMapper.parseAbilityBonuses('pas une map'), isEmpty);
    });
  });

  group('parseTraits', () {
    test('parse une liste de {name, description}', () {
      final traits = RaceRowMapper.parseTraits([
        {'name': 'Vision dans le noir', 'description': '...'},
        {'name': 'Transe', 'description': '...'},
      ]);
      expect(traits, [
        const RaceTrait(name: 'Vision dans le noir', description: '...'),
        const RaceTrait(name: 'Transe', description: '...'),
      ]);
    });

    test('ignore une entrée sans name exploitable', () {
      final traits = RaceRowMapper.parseTraits([
        {'description': 'sans nom'},
        {'name': 'Robustesse', 'description': '...'},
      ]);
      expect(traits, [const RaceTrait(name: 'Robustesse', description: '...')]);
    });

    test('null ou type inattendu -> liste vide', () {
      expect(RaceRowMapper.parseTraits(null), isEmpty);
      expect(RaceRowMapper.parseTraits('pas une liste'), isEmpty);
    });

    test('description manquante -> chaîne vide plutôt que crash', () {
      final traits = RaceRowMapper.parseTraits([
        {'name': 'Chanceux'},
      ]);
      expect(traits.single.description, isEmpty);
    });
  });

  group('toRaceOption', () {
    test('résout le nom via la map de traductions', () {
      final race = RaceRowMapper.toRaceOption(
        {
          'id': 2,
          'ability_bonuses': {'dex': 2},
          'traits': [
            {'name': 'Vision dans le noir', 'description': '...'},
          ],
        },
        names: {'2': 'Elfe'},
      );

      expect(race.id, 2);
      expect(race.name, 'Elfe');
      expect(race.summaryLine, '+2 Dex · Vision dans le noir');
    });

    test(
      'id sans traduction résolue -> libellé générique plutôt que crash',
      () {
        final race = RaceRowMapper.toRaceOption({
          'id': 99,
          'ability_bonuses': {},
          'traits': [],
        }, names: const {});

        expect(race.name, 'Race #99');
      },
    );

    test(
      'is_incomplete absent de la ligne -> false (cache offline ancien)',
      () {
        final race = RaceRowMapper.toRaceOption(
          {'id': 2, 'ability_bonuses': {}, 'traits': []},
          names: const {'2': 'Elfe'},
        );

        expect(race.isIncomplete, isFalse);
      },
    );

    test('is_incomplete true -> reporté tel quel sur RaceOption', () {
      final race = RaceRowMapper.toRaceOption(
        {'id': 2, 'ability_bonuses': {}, 'traits': [], 'is_incomplete': true},
        names: const {'2': 'Race maison'},
      );

      expect(race.isIncomplete, isTrue);
    });

    test('source absent de la ligne -> chaîne vide plutôt que crash', () {
      final race = RaceRowMapper.toRaceOption(
        {'id': 2, 'ability_bonuses': {}, 'traits': []},
        names: const {'2': 'Elfe'},
      );

      expect(race.source, isEmpty);
      expect(
        race.isCoreSource,
        isFalse,
        reason:
            'une source absente/inconnue est classée en extension par '
            'défaut plutôt que de base (fallback conservateur)',
      );
    });

    test('source reportée telle quelle sur RaceOption', () {
      final race = RaceRowMapper.toRaceOption(
        {
          'id': 2,
          'ability_bonuses': {},
          'traits': [],
          'source': 'Manuel des Joueurs (2024)',
        },
        names: const {'2': 'Elfe'},
      );

      expect(race.source, 'Manuel des Joueurs (2024)');
      expect(race.isCoreSource, isTrue);
    });

    test('une source d\'extension (ne commence pas par "Manuel des Joueurs") '
        '-> isCoreSource false', () {
      final race = RaceRowMapper.toRaceOption(
        {
          'id': 2,
          'ability_bonuses': {},
          'traits': [],
          'source': 'Monstres du Multivers',
        },
        names: const {'2': 'Aasimar'},
      );

      expect(race.isCoreSource, isFalse);
    });
  });

  group('parseSkillChoice', () {
    test('null/type inattendu -> null (pas de choix)', () {
      expect(RaceRowMapper.parseSkillChoice(null), isNull);
      expect(RaceRowMapper.parseSkillChoice('pas une map'), isNull);
    });

    test('count absent -> null', () {
      expect(RaceRowMapper.parseSkillChoice({'choices': <String>[]}), isNull);
    });

    test('Centaure : {count:1, choices:[liste restreinte]}', () {
      final choice = RaceRowMapper.parseSkillChoice({
        'count': 1,
        'choices': ['Dressage', 'Médecine', 'Nature', 'Survie'],
      });

      expect(
        choice,
        const ClassSkillChoices(
          count: 1,
          choices: ['Dressage', 'Médecine', 'Nature', 'Survie'],
        ),
      );
    });

    test('Changelin : {count:2, choices:[5 compétences]}', () {
      final choice = RaceRowMapper.parseSkillChoice({
        'count': 2,
        'choices': [
          'Intimidation',
          'Perspicacité',
          'Persuasion',
          'Représentation',
          'Tromperie',
        ],
      });

      expect(choice!.count, 2);
      expect(choice.choices, hasLength(5));
    });

    test('Demi-elfe/Forgelier/Kenku : {count:N, choices:null} -> choix libre, '
        'développé en les 18 compétences', () {
      final choice = RaceRowMapper.parseSkillChoice({
        'count': 2,
        'choices': null,
      });

      expect(choice!.count, 2);
      expect(choice.choices, hasLength(18));
      expect(choice.choices, contains('Arcanes'));
    });
  });

  group('parseToolChoice', () {
    test('null/type inattendu -> null (pas de choix)', () {
      expect(
        RaceRowMapper.parseToolChoice(null, toolCatalog: _toolsCatalog),
        isNull,
      );
    });

    test('count absent -> null', () {
      expect(
        RaceRowMapper.parseToolChoice({
          'choices': <String>[],
        }, toolCatalog: _toolsCatalog),
        isNull,
      );
    });

    test(
      'Nain : {count:1, choices:[liste nommée]} -> reportée telle quelle',
      () {
        final choice = RaceRowMapper.parseToolChoice({
          'count': 1,
          'choices': [
            'Outils de forgeron',
            'Outils de brasseur',
            'Outils de maçon',
          ],
        }, toolCatalog: _toolsCatalog);

        expect(choice!.count, 1);
        expect(choice.choices, [
          'Outils de forgeron',
          'Outils de brasseur',
          'Outils de maçon',
        ]);
      },
    );

    test('Satyre : {count:1, categories:["instrument"]} -> développée contre '
        'le catalogue d\'outils, les autres catégories exclues', () {
      final choice = RaceRowMapper.parseToolChoice({
        'count': 1,
        'categories': ['instrument'],
      }, toolCatalog: _toolsCatalog);

      expect(choice!.count, 1);
      expect(choice.choices, ['Luth', 'Flûte']);
    });

    test('Forgelier : ni choices ni categories -> choix libre, tout le '
        'catalogue d\'outils', () {
      final choice = RaceRowMapper.parseToolChoice({
        'count': 1,
      }, toolCatalog: _toolsCatalog);

      expect(choice!.count, 1);
      expect(choice.choices, hasLength(_toolsCatalog.tools.length));
    });

    test('ToolCatalog vide (ancien cache offline) -> liste de candidats vide '
        'plutôt que de crasher', () {
      final choice = RaceRowMapper.parseToolChoice({
        'count': 1,
        'categories': ['instrument'],
      }, toolCatalog: const ToolCatalog(tools: []));

      expect(choice!.choices, isEmpty);
    });
  });

  group('parseSkillProficiencies', () {
    test('Satyre : ["Persuasion", "Représentation"] reportée telle quelle', () {
      expect(
        RaceRowMapper.parseSkillProficiencies(['Persuasion', 'Représentation']),
        ['Persuasion', 'Représentation'],
      );
    });

    test(
      'null/type inattendu -> liste vide (la grande majorité des races)',
      () {
        expect(RaceRowMapper.parseSkillProficiencies(null), isEmpty);
        expect(RaceRowMapper.parseSkillProficiencies('pas une liste'), isEmpty);
      },
    );
  });

  group('toRaceOption — résolution des 3 nouvelles colonnes', () {
    test('race sans aucune des 3 colonnes -> skillChoice/toolChoice null, '
        'skillProficiencies vide', () {
      final race = RaceRowMapper.toRaceOption(
        {'id': 1, 'ability_bonuses': {}, 'traits': []},
        names: const {'1': 'Humain'},
      );

      expect(race.skillChoice, isNull);
      expect(race.toolChoice, isNull);
      expect(race.skillProficiencies, isEmpty);
    });

    test('Changeforme : skill_choice résolu avec le toolCatalog par défaut '
        '(outil non applicable ici)', () {
      final race = RaceRowMapper.toRaceOption(
        {
          'id': 48,
          'ability_bonuses': {},
          'traits': [],
          'skill_choice': {
            'count': 1,
            'choices': ['Acrobaties', 'Athlétisme', 'Intimidation', 'Survie'],
          },
        },
        names: const {'48': 'Changeforme'},
      );

      expect(race.skillChoice!.count, 1);
      expect(race.skillChoice!.choices, hasLength(4));
    });

    test('Nain : tool_choice résolu contre le toolCatalog fourni', () {
      final race = RaceRowMapper.toRaceOption(
        {
          'id': 3,
          'ability_bonuses': {},
          'traits': [],
          'tool_choice': {
            'count': 1,
            'choices': ['Outils de forgeron', 'Outils de brasseur'],
          },
        },
        names: const {'3': 'Nain'},
        toolCatalog: _toolsCatalog,
      );

      expect(race.toolChoice!.count, 1);
      expect(race.toolChoice!.choices, [
        'Outils de forgeron',
        'Outils de brasseur',
      ]);
    });

    test('Satyre : skill_proficiencies + tool_choice par catégorie', () {
      final race = RaceRowMapper.toRaceOption(
        {
          'id': 42,
          'ability_bonuses': {},
          'traits': [],
          'skill_proficiencies': ['Persuasion', 'Représentation'],
          'tool_choice': {
            'count': 1,
            'categories': ['instrument'],
          },
        },
        names: const {'42': 'Satyre'},
        toolCatalog: _toolsCatalog,
      );

      expect(race.skillProficiencies, ['Persuasion', 'Représentation']);
      expect(race.toolChoice!.choices, ['Luth', 'Flûte']);
      expect(
        race.skillChoice,
        isNull,
        reason: 'le Satyre a un octroi automatique, pas un choix',
      );
    });
  });

  group('toRaceOption — natural_weapon_item_id', () {
    test('Tabaxi : natural_weapon_item_id résolu en int', () {
      final race = RaceRowMapper.toRaceOption(
        {
          'id': 50,
          'ability_bonuses': {},
          'traits': [],
          'natural_weapon_item_id': 120,
        },
        names: const {'50': 'Tabaxi'},
      );

      expect(race.naturalWeaponItemId, 120);
    });

    test('natural_weapon_item_id absent -> null (la grande majorité des '
        'races)', () {
      final race = RaceRowMapper.toRaceOption(
        {'id': 1, 'ability_bonuses': {}, 'traits': []},
        names: const {'1': 'Humain'},
      );

      expect(race.naturalWeaponItemId, isNull);
    });
  });

  group('toSubraceOption', () {
    test('résout le nom via la map de traductions et porte le raceId', () {
      final subrace = RaceRowMapper.toSubraceOption(
        {
          'id': 5,
          'race_id': 2,
          'ability_bonuses': {'int': 1},
          'traits': <Map<String, dynamic>>[],
        },
        names: {'5': 'Haut-elfe'},
      );

      expect(subrace.id, 5);
      expect(subrace.raceId, 2);
      expect(subrace.name, 'Haut-elfe');
    });

    test(
      'id sans traduction résolue -> libellé générique plutôt que crash',
      () {
        final subrace = RaceRowMapper.toSubraceOption({
          'id': 42,
          'race_id': 2,
          'ability_bonuses': {},
          'traits': [],
        }, names: const {});

        expect(subrace.name, 'Sous-race #42');
      },
    );
  });
}
