import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/data/skill_row_mapper.dart';

void main() {
  group('collectIds', () {
    test('normalise les ids int en String et déduplique', () {
      final rows = [
        {'id': 1},
        {'id': 2},
        {'id': 1},
      ];
      expect(SkillRowMapper.collectIds(rows), {'1', '2'});
    });

    test('ignore les ids nuls', () {
      expect(SkillRowMapper.collectIds([{}]), isEmpty);
    });
  });

  group('parseTranslatedValues', () {
    test('lit les colonnes réelles entity_id/value', () {
      final values = SkillRowMapper.parseTranslatedValues([
        {'entity_id': '1', 'value': 'Acrobaties'},
        {'entity_id': '2', 'value': 'Arcanes'},
      ]);
      expect(values, {'1': 'Acrobaties', '2': 'Arcanes'});
    });

    test('ignore une ligne sans entity_id ou sans value exploitable', () {
      final values = SkillRowMapper.parseTranslatedValues([
        {'entity_id': '1', 'value': null},
        {'entity_id': null, 'value': 'Orphelin'},
        {'entity_id': '3', 'value': 'Athlétisme'},
      ]);
      expect(values, {'3': 'Athlétisme'});
    });
  });

  group('toSkillOption', () {
    test('résout le nom via la map de traductions et lit ability_id', () {
      final skill = SkillRowMapper.toSkillOption(
        {'id': 1, 'ability_id': 'dex'},
        names: {'1': 'Acrobaties'},
      );

      expect(skill.id, 1);
      expect(skill.name, 'Acrobaties');
      expect(skill.abilityId, 'dex');
    });

    test(
      'id sans traduction résolue -> libellé générique plutôt que crash',
      () {
        final skill = SkillRowMapper.toSkillOption({
          'id': 99,
          'ability_id': 'int',
        }, names: const {});

        expect(skill.name, 'Compétence #99');
      },
    );

    test('ability_id manquant -> retombe sur une chaîne vide', () {
      final skill = SkillRowMapper.toSkillOption(
        {'id': 5},
        names: {'5': 'Discrétion'},
      );

      expect(skill.abilityId, '');
    });
  });
}
