import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/data/racial_innate_spell_row_mapper.dart';

void main() {
  group('collectSpellIds', () {
    test('un spell_id par ligne, en String, sans doublon', () {
      final ids = RacialInnateSpellRowMapper.collectSpellIds([
        {'spell_id': 24, 'character_level': 1},
        {'spell_id': 403, 'character_level': 3},
        {'spell_id': 24, 'character_level': 1},
      ]);
      expect(ids, {'24', '403'});
    });

    test('une ligne sans spell_id est ignorée', () {
      final ids = RacialInnateSpellRowMapper.collectSpellIds([
        {'spell_id': null, 'character_level': 1},
      ]);
      expect(ids, isEmpty);
    });
  });

  group('parse', () {
    const names = {'24': 'Thaumaturgie', '403': 'Représailles infernales'};

    test('résout chaque ligne concernant la race entière (subrace_id nul)', () {
      final grants = RacialInnateSpellRowMapper.parse(
        rows: const [
          {'spell_id': 24, 'subrace_id': null, 'character_level': 1},
          {'spell_id': 403, 'subrace_id': null, 'character_level': 3},
        ],
        subraceId: null,
        names: names,
      );

      expect(grants, hasLength(2));
      expect(grants[0].spellId, 24);
      expect(grants[0].spellName, 'Thaumaturgie');
      expect(grants[0].characterLevel, 1);
      expect(grants[1].spellId, 403);
      expect(grants[1].characterLevel, 3);
    });

    test('trie par characterLevel croissant, indépendamment de l\'ordre '
        'd\'entrée', () {
      final grants = RacialInnateSpellRowMapper.parse(
        rows: const [
          {'spell_id': 450, 'subrace_id': null, 'character_level': 5},
          {'spell_id': 24, 'subrace_id': null, 'character_level': 1},
        ],
        subraceId: null,
        names: const {'450': 'Ténèbres', '24': 'Thaumaturgie'},
      );

      expect(grants.map((g) => g.characterLevel), [1, 5]);
    });

    test('une ligne de sous-race non concernée (subrace_id différent) est '
        'ignorée', () {
      final grants = RacialInnateSpellRowMapper.parse(
        rows: const [
          {'spell_id': 77, 'subrace_id': 25, 'character_level': 1},
        ],
        subraceId: 28,
        names: const {'77': 'Lévitation'},
      );

      expect(grants, isEmpty);
    });

    test(
      'une ligne de sous-race concernée (subrace_id égal) est conservée',
      () {
        final grants = RacialInnateSpellRowMapper.parse(
          rows: const [
            {'spell_id': 77, 'subrace_id': 25, 'character_level': 1},
          ],
          subraceId: 25,
          names: const {'77': 'Lévitation'},
        );

        expect(grants, hasLength(1));
        expect(grants.single.spellId, 77);
      },
    );

    test('une ligne sans subrace_id (race entière) est conservée même pour un '
        'personnage sans sous-race (subraceId nul)', () {
      final grants = RacialInnateSpellRowMapper.parse(
        rows: const [
          {'spell_id': 24, 'subrace_id': null, 'character_level': 1},
        ],
        subraceId: null,
        names: names,
      );

      expect(grants, hasLength(1));
    });

    test(
      'une ligne dont le nom du sort n\'a pas pu être résolu est ignorée',
      () {
        final grants = RacialInnateSpellRowMapper.parse(
          rows: const [
            {'spell_id': 999, 'subrace_id': null, 'character_level': 1},
          ],
          subraceId: null,
          names: const {},
        );

        expect(grants, isEmpty);
      },
    );

    test(
      'une ligne avec spell_id/character_level non numérique est ignorée',
      () {
        final grants = RacialInnateSpellRowMapper.parse(
          rows: const [
            {'spell_id': null, 'subrace_id': null, 'character_level': 1},
            {'spell_id': 24, 'subrace_id': null, 'character_level': null},
          ],
          subraceId: null,
          names: names,
        );

        expect(grants, isEmpty);
      },
    );

    test('liste vide pour des lignes vides', () {
      expect(
        RacialInnateSpellRowMapper.parse(
          rows: const [],
          subraceId: null,
          names: const {},
        ),
        isEmpty,
      );
    });
  });
}
