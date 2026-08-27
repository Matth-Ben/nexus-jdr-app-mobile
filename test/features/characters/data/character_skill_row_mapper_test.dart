import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/data/character_skill_row_mapper.dart';

void main() {
  group('CharacterSkillRowMapper.collectIds', () {
    test('collecte les id en Set<String>', () {
      final rows = [
        {'id': 1, 'ability_id': 'dex'},
        {'id': 2, 'ability_id': 'int'},
      ];
      expect(CharacterSkillRowMapper.collectIds(rows), {'1', '2'});
    });
  });

  group('CharacterSkillRowMapper.parseProficiencies', () {
    test('construit {skill_id: proficiency}', () {
      final rows = [
        {'skill_id': 1, 'proficiency': 'competente'},
        {'skill_id': 3, 'proficiency': 'expertise'},
      ];
      expect(CharacterSkillRowMapper.parseProficiencies(rows), {
        1: 'competente',
        3: 'expertise',
      });
    });

    test('ignore une ligne sans skill_id/proficiency exploitable', () {
      final rows = [
        {'skill_id': null, 'proficiency': 'competente'},
        {'skill_id': 2, 'proficiency': null},
      ];
      expect(CharacterSkillRowMapper.parseProficiencies(rows), isEmpty);
    });
  });

  group('CharacterSkillRowMapper.toCharacterSkillRows', () {
    test('résout le nom et la maîtrise de chaque compétence', () {
      final skillRows = [
        {'id': 1, 'ability_id': 'dex'},
        {'id': 2, 'ability_id': 'int'},
      ];

      final result = CharacterSkillRowMapper.toCharacterSkillRows(
        skillRows,
        names: const {'1': 'Acrobaties', '2': 'Arcanes'},
        proficiencies: const {1: 'competente'},
      );

      expect(result, hasLength(2));
      expect(result[0].id, 1);
      expect(result[0].name, 'Acrobaties');
      expect(result[0].abilityId, 'dex');
      expect(result[0].proficiency, 'competente');
      expect(result[1].name, 'Arcanes');
      // Aucune ligne character_skill_proficiencies pour cette compétence :
      // retombe sur 'aucune'.
      expect(result[1].proficiency, 'aucune');
    });

    test('un id sans nom résolu retombe sur un libellé générique', () {
      final skillRows = [
        {'id': 99, 'ability_id': 'wis'},
      ];

      final result = CharacterSkillRowMapper.toCharacterSkillRows(
        skillRows,
        names: const {},
        proficiencies: const {},
      );

      expect(result.single.name, 'Compétence #99');
    });
  });
}
