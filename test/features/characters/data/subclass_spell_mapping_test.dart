// Tests du mapping des sorts "toujours préparés" des sous-classes
// (`subclass_spells`) : `CharacterSpellRowMapper`,
// `CharacterDetailRowMapper.collectSubclassProgress`/`parseSubclassSpellGrants`,
// `SpellStatusFormatter` et `CharacterDetail.preparedSpellCount`.

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/data/character_detail_row_mapper.dart';
import 'package:personnages/features/characters/data/character_spell_row_mapper.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/spell_grant_source.dart';
import 'package:personnages/features/characters/domain/spell_status_formatter.dart';

void main() {
  group('CharacterSpellRowMapper.toCharacterSpellEntries (grants)', () {
    final spellRows = [
      {'id': 1, 'level': 1, 'school': 'abjuration'},
      {'id': 2, 'level': 2, 'school': 'évocation'},
      {'id': 3, 'level': 3, 'school': 'évocation'},
    ];

    test('sort accordé sans ligne character_spells : préparé, non persisté, '
        'avec son origine', () {
      final result = CharacterSpellRowMapper.toCharacterSpellEntries(
        spellRows,
        names: const {'1': 'A', '2': 'B', '3': 'C'},
        descriptions: const {},
        statuses: const {},
        grants: const {2: SpellGrantSource.oath},
      );

      final granted = result.singleWhere((s) => s.id == 2);
      expect(granted.status, 'préparé');
      expect(granted.grantSource, SpellGrantSource.oath);
      expect(granted.isAlwaysPrepared, isTrue);
      expect(granted.isPersisted, isFalse);
    });

    test('doublon (choisi ET accordé) : une seule entrée, préparée, '
        'persistée, favori conservé', () {
      final result = CharacterSpellRowMapper.toCharacterSpellEntries(
        spellRows,
        names: const {},
        descriptions: const {},
        statuses: const {1: 'connu', 2: 'connu'},
        favorites: const {2: true},
        grants: const {2: SpellGrantSource.domain},
      );

      expect(result.where((s) => s.id == 2), hasLength(1));
      final granted = result.singleWhere((s) => s.id == 2);
      expect(granted.status, 'préparé');
      expect(granted.isPersisted, isTrue);
      expect(granted.isFavorite, isTrue);
      final ordinary = result.singleWhere((s) => s.id == 1);
      expect(ordinary.grantSource, isNull);
      expect(ordinary.status, 'connu');
      expect(ordinary.isPersisted, isTrue);
    });
  });

  group('CharacterDetailRowMapper subclass helpers', () {
    final row = {
      'character_classes': [
        {'class_id': 1, 'subclass_id': 10, 'level': 5},
        {'class_id': 2, 'subclass_id': null, 'level': 3},
        {'class_id': 3, 'subclass_id': 30, 'level': 2},
      ],
    };

    test('collectSubclassProgress : niveau de la classe concernée, origine '
        'déduite du nom de classe, sous-classe nulle ignorée', () {
      final progress = CharacterDetailRowMapper.collectSubclassProgress(
        row,
        classNames: const {'1': 'Clerc', '2': 'Guerrier', '3': 'Paladin'},
      );

      expect(progress, hasLength(2));
      expect(progress[0].subclassId, 10);
      expect(progress[0].classLevel, 5);
      expect(progress[0].source, SpellGrantSource.domain);
      expect(progress[1].subclassId, 30);
      expect(progress[1].classLevel, 2);
      expect(progress[1].source, SpellGrantSource.oath);
    });

    test('parseSubclassSpellGrants ignore une ligne incomplète', () {
      final grants = CharacterDetailRowMapper.parseSubclassSpellGrants([
        {'subclass_id': 10, 'spell_id': 5, 'class_level': 3},
        {'subclass_id': 10, 'spell_id': null, 'class_level': 3},
      ]);
      expect(grants, hasLength(1));
      expect(grants.single.spellId, 5);
      expect(grants.single.classLevel, 3);
    });
  });

  group('SpellStatusFormatter (sort accordé)', () {
    const granted = CharacterSpellEntry(
      id: 1,
      name: 'Bénédiction',
      level: 1,
      school: '',
      status: 'préparé',
      grantSource: SpellGrantSource.domain,
    );

    test('sous-titre "toujours préparé · Domaine"', () {
      expect(
        SpellStatusFormatter.subtitle(granted),
        'toujours préparé · Domaine',
      );
    });

    test('lançable mais jamais dé-préparable', () {
      expect(SpellStatusFormatter.canCast(granted), isTrue);
      expect(SpellStatusFormatter.canTogglePrepared(granted), isFalse);
    });
  });

  group('CharacterDetail.preparedSpellCount / grantedSpells', () {
    CharacterSpellEntry spell(
      int id, {
      required String status,
      int level = 1,
      SpellGrantSource? grant,
    }) => CharacterSpellEntry(
      id: id,
      name: 'S$id',
      level: level,
      school: '',
      status: status,
      grantSource: grant,
    );

    test(
      'exclut les sorts accordés, les mineurs et les sorts non préparés',
      () {
        final detail = CharacterDetail(
          id: '1',
          name: 'Test',
          classes: const [],
          xp: 0,
          currentHp: 1,
          maxHp: 1,
          temporaryHp: 0,
          abilityScores: const {},
          spells: [
            spell(1, status: 'préparé'),
            spell(2, status: 'préparé'),
            spell(3, status: 'connu'),
            spell(4, status: 'préparé', level: 0),
            spell(5, status: 'préparé', grant: SpellGrantSource.domain),
            spell(6, status: 'préparé', grant: SpellGrantSource.domain),
          ],
        );

        expect(detail.preparedSpellCount, 2);
        expect(detail.grantedSpells.map((s) => s.id), [5, 6]);
      },
    );
  });
}
