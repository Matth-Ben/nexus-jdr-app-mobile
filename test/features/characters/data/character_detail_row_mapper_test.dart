import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/data/character_detail_row_mapper.dart';

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
    test('résout le nom de classe et les maîtrises de jets de sauvegarde '
        'embarquées (relation classes.saving_throw_proficiencies)', () {
      final row = _row(
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
    });

    test('un id sans nom résolu retombe sur un libellé générique', () {
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
}
