import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/data/patron_extended_spell_row_mapper.dart';

void main() {
  test('groupe par sous-classe avec nom, niveau de sort et class_level', () {
    final result = PatronExtendedSpellRowMapper.parse(
      grantRows: [
        {'subclass_id': 40, 'spell_id': 1, 'class_level': 1},
        {'subclass_id': 40, 'spell_id': 2, 'class_level': 3},
        {'subclass_id': 41, 'spell_id': 1, 'class_level': 1},
      ],
      spellRows: [
        {
          'id': 1,
          'level': 1,
          'school': 'Evocation',
          'casting_time': '1 action',
        },
        {
          'id': 2,
          'level': 2,
          'school': 'Evocation',
          'casting_time': '1 action',
        },
      ],
      names: {'1': 'Mains brulantes', '2': 'Fracasser'},
    );
    expect(result.keys, {40, 41});
    expect(result[40]!.map((e) => e.spell.name), [
      'Mains brulantes',
      'Fracasser',
    ]);
    expect(result[40]!.map((e) => e.classLevel), [1, 3]);
    expect(result[40]![1].spell.level, 2);
    expect(result[41]!.single.spell.id, 1);
  });

  test('ignore les lignes incompletes ou dont le sort est inconnu', () {
    final result = PatronExtendedSpellRowMapper.parse(
      grantRows: [
        {'subclass_id': null, 'spell_id': 1, 'class_level': 1},
        {'subclass_id': 40, 'spell_id': 1},
        {'subclass_id': 40, 'spell_id': 99, 'class_level': 1},
      ],
      spellRows: [
        {'id': 1, 'level': 1, 'school': 'X', 'casting_time': '1 action'},
      ],
      names: const {},
    );
    expect(result, isEmpty);
  });

  test('collectSpellIds deduplique', () {
    expect(
      PatronExtendedSpellRowMapper.collectSpellIds([
        {'spell_id': 1},
        {'spell_id': 1},
        {'spell_id': 2},
        {'spell_id': null},
      ]),
      {1, 2},
    );
  });
}
