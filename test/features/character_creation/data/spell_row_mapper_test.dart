import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/data/spell_row_mapper.dart';

void main() {
  group('collectSpellIds', () {
    test('normalise les spell_id en int et déduplique', () {
      final rows = [
        {'spell_id': 1},
        {'spell_id': 2},
        {'spell_id': 1},
      ];
      expect(SpellRowMapper.collectSpellIds(rows), {1, 2});
    });

    test('ignore les spell_id absents ou non numériques', () {
      expect(SpellRowMapper.collectSpellIds([{}]), isEmpty);
    });
  });

  group('collectIds', () {
    test('normalise les ids int en String et déduplique', () {
      final rows = [
        {'id': 1},
        {'id': 2},
        {'id': 1},
      ];
      expect(SpellRowMapper.collectIds(rows), {'1', '2'});
    });

    test('ignore les ids nuls', () {
      expect(SpellRowMapper.collectIds([{}]), isEmpty);
    });
  });

  group('parseTranslatedValues', () {
    test('lit les colonnes réelles entity_id/value', () {
      final values = SpellRowMapper.parseTranslatedValues([
        {'entity_id': '1', 'value': 'Trait de feu'},
        {'entity_id': '2', 'value': 'Lumières dansantes'},
      ]);
      expect(values, {'1': 'Trait de feu', '2': 'Lumières dansantes'});
    });

    test('ignore une ligne sans entity_id ou sans value exploitable', () {
      final values = SpellRowMapper.parseTranslatedValues([
        {'entity_id': '1', 'value': null},
        {'entity_id': null, 'value': 'Orphelin'},
        {'entity_id': '3', 'value': 'Réparation'},
      ]);
      expect(values, {'3': 'Réparation'});
    });
  });

  group('toSpellOption', () {
    test('résout le nom via la map de traductions et lit les colonnes de '
        'méta', () {
      final spell = SpellRowMapper.toSpellOption(
        {
          'id': 1,
          'level': 0,
          'school': 'Évocation',
          'casting_time': '1 action',
        },
        names: {'1': 'Trait de feu'},
      );

      expect(spell.id, 1);
      expect(spell.name, 'Trait de feu');
      expect(spell.level, 0);
      expect(spell.school, 'Évocation');
      expect(spell.castingTime, '1 action');
      expect(spell.metaLine, 'Évocation · 1 action');
    });

    test(
      'id sans traduction résolue -> libellé générique plutôt que crash',
      () {
        final spell = SpellRowMapper.toSpellOption({
          'id': 99,
          'level': 1,
          'school': 'Divination',
          'casting_time': '1 action',
        }, names: const {});

        expect(spell.name, 'Sort #99');
      },
    );

    test('level/school/casting_time manquants retombent sur des valeurs '
        'neutres plutôt que de crasher', () {
      final spell = SpellRowMapper.toSpellOption(
        {'id': 5},
        names: const {'5': 'Réparation'},
      );

      expect(spell.level, 0);
      expect(spell.school, '');
      expect(spell.castingTime, '');
    });
  });
}
