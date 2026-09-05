import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/data/character_detail_row_mapper.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';

Map<String, dynamic> _row({
  Object? raceId = 1,
  Object? subraceId,
  Object? backgroundId = 2,
  Object? alignmentId = 3,
  String? raceCustomText,
  List<Map<String, dynamic>> characterClasses = const [],
  List<Map<String, dynamic>> abilityScores = const [],
}) {
  return {
    'id': 'char-1',
    'name': 'Halltesse',
    'portrait_url': null,
    'xp': 1200,
    'current_hp': 18,
    'max_hp': 24,
    'temporary_hp': 5,
    'race_id': raceId,
    'subrace_id': subraceId,
    'race_custom_text': raceCustomText,
    'background_id': backgroundId,
    'alignment_id': alignmentId,
    'character_classes': characterClasses,
    'character_ability_scores': abilityScores,
  };
}

void main() {
  group('CharacterDetailRowMapper.collectXIds', () {
    test('collecte race/subrace/background/alignment en Set<String>', () {
      final row = _row(
        raceId: 1,
        subraceId: 4,
        backgroundId: 2,
        alignmentId: 3,
      );
      expect(CharacterDetailRowMapper.collectRaceIds(row), {'1'});
      expect(CharacterDetailRowMapper.collectSubraceIds(row), {'4'});
      expect(CharacterDetailRowMapper.collectBackgroundIds(row), {'2'});
      expect(CharacterDetailRowMapper.collectAlignmentIds(row), {'3'});
    });

    test('retourne un Set vide pour un id nul (race personnalisée...)', () {
      final row = _row(raceId: null, subraceId: null);
      expect(CharacterDetailRowMapper.collectRaceIds(row), isEmpty);
      expect(CharacterDetailRowMapper.collectSubraceIds(row), isEmpty);
    });

    test('collecte les class_id de toutes les lignes character_classes', () {
      final row = _row(
        characterClasses: const [
          {'class_id': 5, 'level': 3, 'is_primary': true},
          {'class_id': 7, 'level': 2, 'is_primary': false},
        ],
      );
      expect(CharacterDetailRowMapper.collectClassIds(row), {'5', '7'});
    });
  });

  group('CharacterDetailRowMapper.parseClasses', () {
    test('résout le nom de classe, les maîtrises de jets de sauvegarde, le '
        'dé de vie embarqués (relation classes.saving_throw_proficiencies/'
        'hit_die) et hit_dice_spent', () {
      final row = _row(
        characterClasses: [
          {
            'class_id': 5,
            'level': 3,
            'is_primary': true,
            'hit_dice_spent': 2,
            'classes': {
              'saving_throw_proficiencies': ['str', 'con'],
              'hit_die': 10,
            },
          },
        ],
      );

      final classes = CharacterDetailRowMapper.parseClasses(
        row,
        classNames: const {'5': 'Guerrier'},
      );

      expect(classes, hasLength(1));
      expect(classes.first.className, 'Guerrier');
      expect(classes.first.level, 3);
      expect(classes.first.isPrimary, isTrue);
      expect(classes.first.savingThrowProficiencies, ['str', 'con']);
      expect(classes.first.hitDie, 10);
      expect(classes.first.hitDiceSpent, 2);
    });

    test('un id sans nom résolu retombe sur un libellé générique, un dé de '
        'vie manquant reste null (jamais deviné, voir '
        'CharacterDetailClassRow.hitDie), hit_dice_spent absent retombe '
        'sur 0', () {
      final row = _row(
        characterClasses: const [
          {'class_id': 99, 'level': 1, 'is_primary': true},
        ],
      );
      final classes = CharacterDetailRowMapper.parseClasses(
        row,
        classNames: const {},
      );
      expect(classes.first.className, 'Classe #99');
      expect(classes.first.savingThrowProficiencies, isEmpty);
      expect(classes.first.hitDie, isNull);
      expect(classes.first.hitDiceSpent, 0);
    });

    test('ignore une ligne sans class_id exploitable', () {
      final row = _row(
        characterClasses: const [
          {'class_id': null, 'level': 1, 'is_primary': true},
        ],
      );
      expect(
        CharacterDetailRowMapper.parseClasses(row, classNames: const {}),
        isEmpty,
      );
    });
  });

  group('CharacterDetailRowMapper.parseAbilityScores', () {
    test('construit {ability_id: score}', () {
      final row = _row(
        abilityScores: const [
          {'ability_id': 'str', 'score': 16},
          {'ability_id': 'dex', 'score': 12},
        ],
      );
      expect(CharacterDetailRowMapper.parseAbilityScores(row), {
        'str': 16,
        'dex': 12,
      });
    });

    test('ignore une ligne sans ability_id/score exploitable', () {
      final row = _row(
        abilityScores: const [
          {'ability_id': null, 'score': 16},
          {'ability_id': 'dex', 'score': null},
        ],
      );
      expect(CharacterDetailRowMapper.parseAbilityScores(row), isEmpty);
    });
  });

  group('CharacterDetailRowMapper.toCharacterDetail', () {
    test('construit un CharacterDetail complet avec tous les noms résolus', () {
      final row = _row(
        raceId: 1,
        subraceId: 4,
        backgroundId: 2,
        alignmentId: 3,
        characterClasses: [
          {
            'class_id': 5,
            'level': 3,
            'is_primary': true,
            'classes': {
              'saving_throw_proficiencies': ['str', 'con'],
            },
          },
        ],
        abilityScores: const [
          {'ability_id': 'str', 'score': 16},
        ],
      );

      final detail = CharacterDetailRowMapper.toCharacterDetail(
        row,
        raceNames: const {'1': 'Elfe'},
        subraceNames: const {'4': 'Haut-elfe'},
        classNames: const {'5': 'Guerrier'},
        backgroundNames: const {'2': 'Noble'},
        alignmentNames: const {'3': 'Loyal Bon'},
      );

      expect(detail.id, 'char-1');
      expect(detail.name, 'Halltesse');
      expect(detail.raceName, 'Elfe');
      expect(detail.subraceName, 'Haut-elfe');
      expect(detail.backgroundName, 'Noble');
      expect(detail.alignmentName, 'Loyal Bon');
      expect(detail.xp, 1200);
      expect(detail.currentHp, 18);
      expect(detail.maxHp, 24);
      expect(detail.temporaryHp, 5);
      expect(detail.classes.single.className, 'Guerrier');
      expect(detail.abilityScores, {'str': 16});
      // Colonnes absentes de `_row(...)` -> repli à 0, même règle que
      // xp/current_hp/etc.
      expect(detail.currencyGp, 0);
      expect(detail.currencyPp, 0);
      expect(detail.currencyEp, 0);
      expect(detail.currencySp, 0);
      expect(detail.currencyCp, 0);
    });

    test('résout la monnaie (currency_gp/pp/ep/sp/cp) directement depuis la '
        'ligne, sans dépendre d\'une requête supplémentaire', () {
      final row = _row();
      row['currency_gp'] = 42;
      row['currency_pp'] = 2;
      row['currency_ep'] = 3;
      row['currency_sp'] = 6;
      row['currency_cp'] = 14;

      final detail = CharacterDetailRowMapper.toCharacterDetail(
        row,
        raceNames: const {},
        subraceNames: const {},
        classNames: const {},
        backgroundNames: const {},
        alignmentNames: const {},
      );

      expect(detail.currencyGp, 42);
      expect(detail.currencyPp, 2);
      expect(detail.currencyEp, 3);
      expect(detail.currencySp, 6);
      expect(detail.currencyCp, 14);
    });

    test('inventory est transmis tel quel quand fourni', () {
      final row = _row();
      const inventory = [
        CharacterInventoryItem(
          id: 'inv-1',
          itemId: 1,
          name: 'Dague',
          category: 'arme',
          quantity: 2,
          equipped: false,
          totalWeight: 1,
        ),
      ];

      final detail = CharacterDetailRowMapper.toCharacterDetail(
        row,
        raceNames: const {},
        subraceNames: const {},
        classNames: const {},
        backgroundNames: const {},
        alignmentNames: const {},
        inventory: inventory,
      );

      expect(detail.inventory, inventory);
    });

    test('un id nul (race_id/background_id/alignment_id) reste non résolu', () {
      final row = _row(raceId: null, backgroundId: null, alignmentId: null);
      final detail = CharacterDetailRowMapper.toCharacterDetail(
        row,
        raceNames: const {},
        subraceNames: const {},
        classNames: const {},
        backgroundNames: const {},
        alignmentNames: const {},
      );
      expect(detail.raceName, isNull);
      expect(detail.backgroundName, isNull);
      expect(detail.alignmentName, isNull);
    });

    test('les listes de l\'onglet Compétences sont transmises telles quelles '
        'quand fournies', () {
      final row = _row();
      final detail = CharacterDetailRowMapper.toCharacterDetail(
        row,
        raceNames: const {},
        subraceNames: const {},
        classNames: const {},
        backgroundNames: const {},
        alignmentNames: const {},
        toolProficiencyNames: const ['Outils de forgeron'],
        knownLanguageNames: const ['Nain'],
      );
      expect(detail.toolProficiencyNames, ['Outils de forgeron']);
      expect(detail.knownLanguageNames, ['Nain']);
    });
  });

  group('CharacterDetailRowMapper — onglet Compétences', () {
    test('collectClassIdsRaw collecte les class_id en Set<int>', () {
      final row = _row(
        characterClasses: const [
          {'class_id': 5, 'level': 3, 'is_primary': true},
          {'class_id': 7, 'level': 2, 'is_primary': false},
          {'class_id': 5, 'level': 3, 'is_primary': true},
        ],
      );
      expect(CharacterDetailRowMapper.collectClassIdsRaw(row), {5, 7});
    });

    test('collectClassLevels construit {class_id: level}', () {
      final row = _row(
        characterClasses: const [
          {'class_id': 5, 'level': 3, 'is_primary': true},
          {'class_id': 7, 'level': 2, 'is_primary': false},
        ],
      );
      expect(CharacterDetailRowMapper.collectClassLevels(row), {
        '5': 3,
        '7': 2,
      });
    });

    test('collectToolIds/parseToolProficiencyNames : custom_text prioritaire '
        'sur le nom résolu via translations, tool_id sans traduction résolue '
        'retombe sur un libellé générique', () {
      final rows = [
        {'tool_id': 1, 'custom_text': null},
        {'tool_id': null, 'custom_text': 'Outils de bricolage improvisés'},
        {'tool_id': 99, 'custom_text': null},
      ];

      expect(CharacterDetailRowMapper.collectToolIds(rows), {1, 99});

      final names = CharacterDetailRowMapper.parseToolProficiencyNames(
        rows,
        toolNames: const {'1': 'Outils de forgeron'},
      );
      expect(names, [
        'Outils de forgeron',
        'Outils de bricolage improvisés',
        'Outil #99',
      ]);
    });

    test(
      'collectLanguageIds/parseLanguageNames résolvent les noms de langues',
      () {
        final rows = [
          {'language_id': 1},
          {'language_id': 2},
        ];

        expect(CharacterDetailRowMapper.collectLanguageIds(rows), {1, 2});

        final names = CharacterDetailRowMapper.parseLanguageNames(
          rows,
          languageNames: const {'1': 'Commun', '2': 'Nain'},
        );
        expect(names, ['Commun', 'Nain']);
      },
    );

    test('parseSpellSlots construit un CharacterSpellSlot par ligne', () {
      final row = _row();
      row['character_spell_slots'] = [
        {'slot_level': 1, 'slots_total': 4, 'slots_used': 1},
        {'slot_level': 2, 'slots_total': 3, 'slots_used': 3},
      ];

      final slots = CharacterDetailRowMapper.parseSpellSlots(row);

      expect(slots, hasLength(2));
      expect(slots[0].level, 1);
      expect(slots[0].total, 4);
      expect(slots[0].used, 1);
      expect(slots[1].remaining, 0);
    });

    test('une ligne character_spell_slots sans slot_level est ignorée', () {
      final row = _row();
      row['character_spell_slots'] = [
        {'slot_level': null, 'slots_total': 4, 'slots_used': 1},
      ];

      expect(CharacterDetailRowMapper.parseSpellSlots(row), isEmpty);
    });
  });

  group('CharacterDetailRowMapper — onglet Histoire (9 champs texte)', () {
    test(
      'résout les 9 champs directement depuis la ligne quand renseignés',
      () {
        final row = _row();
        row['appearance_text'] = 'Cheveux argentés.';
        row['traits_text'] = 'Curieuse.';
        row['ideals_text'] = 'Le savoir avant tout.';
        row['bonds_text'] = 'Recherche un grimoire.';
        row['flaws_text'] = 'Trop curieuse.';
        row['backstory_text'] = 'Élevée dans une enclave.';
        row['allies_text'] = "L'Ordre des Archivistes.";
        row['features_text'] = 'Une cicatrice.';
        row['treasure_text'] = 'Un grimoire scellé.';

        final detail = CharacterDetailRowMapper.toCharacterDetail(
          row,
          raceNames: const {},
          subraceNames: const {},
          classNames: const {},
          backgroundNames: const {},
          alignmentNames: const {},
        );

        expect(detail.appearanceText, 'Cheveux argentés.');
        expect(detail.traitsText, 'Curieuse.');
        expect(detail.idealsText, 'Le savoir avant tout.');
        expect(detail.bondsText, 'Recherche un grimoire.');
        expect(detail.flawsText, 'Trop curieuse.');
        expect(detail.backstoryText, 'Élevée dans une enclave.');
        expect(detail.alliesText, "L'Ordre des Archivistes.");
        expect(detail.featuresText, 'Une cicatrice.');
        expect(detail.treasureText, 'Un grimoire scellé.');
      },
    );

    test('les 9 champs replient sur une chaîne vide quand absents/nuls de la '
        'ligne (colonnes `not null default \'\'` en base, jamais nulles en '
        'pratique, mais un repli défensif comme sur xp/current_hp)', () {
      final row = _row();
      row['appearance_text'] = null;

      final detail = CharacterDetailRowMapper.toCharacterDetail(
        row,
        raceNames: const {},
        subraceNames: const {},
        classNames: const {},
        backgroundNames: const {},
        alignmentNames: const {},
      );

      expect(detail.appearanceText, '');
      expect(detail.traitsText, '');
      expect(detail.idealsText, '');
      expect(detail.bondsText, '');
      expect(detail.flawsText, '');
      expect(detail.backstoryText, '');
      expect(detail.alliesText, '');
      expect(detail.featuresText, '');
      expect(detail.treasureText, '');
    });
  });

  group('CharacterDetailRowMapper — carte "Apparence physique" (7 champs)', () {
    test(
      'résout les 7 champs directement depuis la ligne quand renseignés',
      () {
        final row = _row();
        row['sexe'] = 'Femme';
        row['age'] = '124 ans';
        row['height'] = '1m70';
        row['weight'] = '58 kg';
        row['eyes'] = 'Argentés';
        row['skin'] = 'Pâle';
        row['hair'] = 'Argentés, tressés';

        final detail = CharacterDetailRowMapper.toCharacterDetail(
          row,
          raceNames: const {},
          subraceNames: const {},
          classNames: const {},
          backgroundNames: const {},
          alignmentNames: const {},
        );

        expect(detail.sexe, 'Femme');
        expect(detail.age, '124 ans');
        expect(detail.height, '1m70');
        expect(detail.weight, '58 kg');
        expect(detail.eyes, 'Argentés');
        expect(detail.skin, 'Pâle');
        expect(detail.hair, 'Argentés, tressés');
      },
    );

    test('les 7 champs replient sur une chaîne vide quand absents/nuls de la '
        'ligne (colonnes `text` nullables sans défaut en base, à la '
        'différence des colonnes `*_text` de l\'onglet Histoire ci-dessus, '
        'mais même repli défensif côté modèle)', () {
      final row = _row();

      final detail = CharacterDetailRowMapper.toCharacterDetail(
        row,
        raceNames: const {},
        subraceNames: const {},
        classNames: const {},
        backgroundNames: const {},
        alignmentNames: const {},
      );

      expect(detail.sexe, '');
      expect(detail.age, '');
      expect(detail.height, '');
      expect(detail.weight, '');
      expect(detail.eyes, '');
      expect(detail.skin, '');
      expect(detail.hair, '');
    });
  });
}
