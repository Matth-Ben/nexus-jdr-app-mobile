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
  });
}
