import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/data/character_spell_row_mapper.dart';

void main() {
  group('CharacterSpellRowMapper.collectSpellIds', () {
    test('collecte les spell_id en Set<int>, dédupliqués', () {
      final rows = [
        {'spell_id': 1, 'status': 'connu'},
        {'spell_id': 2, 'status': 'connu'},
        {'spell_id': 1, 'status': 'connu'},
      ];
      expect(CharacterSpellRowMapper.collectSpellIds(rows), {1, 2});
    });

    test('ignore une ligne sans spell_id exploitable', () {
      final rows = [
        {'spell_id': null, 'status': 'connu'},
      ];
      expect(CharacterSpellRowMapper.collectSpellIds(rows), isEmpty);
    });
  });

  group('CharacterSpellRowMapper.parseStatuses', () {
    test('construit {spell_id: status}', () {
      final rows = [
        {'spell_id': 1, 'status': 'préparé'},
        {'spell_id': 2, 'status': 'inné'},
      ];
      expect(CharacterSpellRowMapper.parseStatuses(rows), {
        1: 'préparé',
        2: 'inné',
      });
    });
  });

  group('CharacterSpellRowMapper.toCharacterSpellEntries', () {
    test('résout le nom, le niveau, l\'école et le statut', () {
      final spellRows = [
        {'id': 1, 'level': 3, 'school': 'Évocation'},
      ];

      final result = CharacterSpellRowMapper.toCharacterSpellEntries(
        spellRows,
        names: const {'1': 'Boule de feu'},
        statuses: const {1: 'connu'},
      );

      expect(result, hasLength(1));
      expect(result.single.name, 'Boule de feu');
      expect(result.single.level, 3);
      expect(result.single.school, 'Évocation');
      expect(result.single.status, 'connu');
    });

    test('un id sans nom résolu retombe sur un libellé générique', () {
      final spellRows = [
        {'id': 42, 'level': 0, 'school': null},
      ];

      final result = CharacterSpellRowMapper.toCharacterSpellEntries(
        spellRows,
        names: const {},
        statuses: const {},
      );

      expect(result.single.name, 'Sort #42');
      expect(result.single.school, '');
      // Aucun statut résolu : retombe sur 'connu'.
      expect(result.single.status, 'connu');
    });
  });
}
