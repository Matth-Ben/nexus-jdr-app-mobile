// Lecture des conditions (P6) par les trois mappers : fiche du propriétaire
// (ligne `characters`), membre de groupe (vue du MJ) et fiche partagée.
// Lecture tolérante : colonne absente, null, clé inconnue = jamais de crash.

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_sharing/domain/shared_character_mapper.dart';
import 'package:personnages/features/characters/data/character_detail_row_mapper.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/condition_type.dart';
import 'package:personnages/features/groups/data/group_member_row_mapper.dart';
import 'package:personnages/features/groups/domain/group_member.dart';

CharacterDetail _detail(Map<String, dynamic> row) =>
    CharacterDetailRowMapper.toCharacterDetail(
      {'id': 'char-1', 'name': 'Test', ...row},
      raceNames: const {},
      subraceNames: const {},
      classNames: const {},
      backgroundNames: const {},
      alignmentNames: const {},
    );

Map<String, dynamic> _memberRow(Map<String, dynamic> character) => {
  'id': 'row-1',
  'character_id': 'char-1',
  'user_id': 'user-1',
  'role': 'owner',
  'is_game_master': false,
  'characters': {
    'name': 'Test',
    'current_hp': 5,
    'max_hp': 10,
    'temporary_hp': 0,
    'is_dead': false,
    ...character,
  },
};

void main() {
  group('fiche du propriétaire (ligne characters)', () {
    test('lit les clés connues', () {
      final detail = _detail({
        'conditions': ['poisoned', 'prone'],
      });
      expect(detail.conditions, [ConditionType.poisoned, ConditionType.prone]);
    });

    test('clés inconnues conservées à part pour la réécriture', () {
      final detail = _detail({
        'conditions': ['blinded', 'futur_etat'],
      });
      expect(detail.conditions, [ConditionType.blinded]);
      expect(detail.unknownConditionKeys, ['futur_etat']);
      expect(_detail({}).unknownConditionKeys, isEmpty);
    });

    test(
      'colonne absente (ancien cache) ou null : liste vide, pas de crash',
      () {
        expect(_detail({}).conditions, isEmpty);
        expect(_detail({'conditions': null}).conditions, isEmpty);
      },
    );

    test('clé inconnue ignorée, valeur mal typée tolérée', () {
      expect(
        _detail({
          'conditions': ['blinded', 'exhaustion', 7],
        }).conditions,
        [ConditionType.blinded],
      );
      expect(_detail({'conditions': 'blinded'}).conditions, isEmpty);
    });
  });

  group('membre de groupe (vue du MJ)', () {
    GroupMember map(Map<String, dynamic> character) =>
        GroupMemberRowMapper.toGroupMember(
          _memberRow(character),
          raceNames: const {},
          classNames: const {},
        );

    test('porte les conditions du personnage', () {
      expect(
        map({
          'conditions': ['stunned', 'charmed'],
        }).conditions,
        [ConditionType.charmed, ConditionType.stunned],
      );
    });

    test('absentes / inconnues : liste vide, jamais de crash', () {
      expect(map({}).conditions, isEmpty);
      expect(
        map({
          'conditions': ['inconnue'],
        }).conditions,
        isEmpty,
      );
    });

    test('membre sans personnage (MJ volontaire) : aucune condition', () {
      final member = GroupMemberRowMapper.toGroupMember(
        {
          'id': 'row-2',
          'character_id': null,
          'user_id': 'user-2',
          'role': 'member',
          'is_game_master': true,
          'characters': null,
        },
        raceNames: const {},
        classNames: const {},
      );
      expect(member.conditions, isEmpty);
    });
  });

  group('fiche partagée (build_character_sheet_json)', () {
    Map<String, dynamic> json(Map<String, dynamic> character) => {
      'character': {'id': 'char-1', 'name': 'Test', ...character},
      'classes': <Map<String, dynamic>>[],
    };

    test('lit conditions', () {
      expect(
        mapSharedCharacterJson(
          json({
            'conditions': ['invisible', 'deafened'],
          }),
        ).conditions,
        [ConditionType.deafened, ConditionType.invisible],
      );
    });

    test('ancien payload sans conditions / clé inconnue : vide ou filtré', () {
      expect(mapSharedCharacterJson(json({})).conditions, isEmpty);
      expect(
        mapSharedCharacterJson(
          json({
            'conditions': ['grappled', 'zzz'],
          }),
        ).conditions,
        [ConditionType.grappled],
      );
    });
  });
}
