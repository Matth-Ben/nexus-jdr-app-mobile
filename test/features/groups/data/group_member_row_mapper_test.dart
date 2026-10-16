import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/groups/data/group_member_row_mapper.dart';
import 'package:personnages/features/groups/domain/group_role.dart';

Map<String, dynamic> _row({
  String? characterId = 'char-1',
  String userId = 'user-1',
  String? role = 'owner',
  bool isGameMaster = false,
  String? displayName,
  Map<String, dynamic>? character,
}) {
  return {
    'character_id': characterId,
    'user_id': userId,
    'role': role,
    'is_game_master': isGameMaster,
    'display_name': displayName,
    'characters': character,
  };
}

void main() {
  group('GroupMemberRowMapper.collectRaceIds / collectClassIds', () {
    test('collecte les identifiants uniques présents', () {
      final rows = [
        _row(
          character: {
            'race_id': 'race-1',
            'character_classes': [
              {'class_id': 'class-1', 'level': 3, 'is_primary': true},
            ],
          },
        ),
        _row(
          characterId: 'char-2',
          character: {
            'race_id': 'race-1',
            'character_classes': [
              {'class_id': 'class-2', 'level': 1, 'is_primary': true},
            ],
          },
        ),
      ];

      expect(GroupMemberRowMapper.collectRaceIds(rows), {'race-1'});
      expect(GroupMemberRowMapper.collectClassIds(rows), {
        'class-1',
        'class-2',
      });
    });

    test('ignore les personnages sans race_id/character_classes', () {
      final rows = [_row(character: {})];
      expect(GroupMemberRowMapper.collectRaceIds(rows), isEmpty);
      expect(GroupMemberRowMapper.collectClassIds(rows), isEmpty);
    });
  });

  group('GroupMemberRowMapper.toGroupMember', () {
    test('mappe une ligne complète, classe primaire résolue', () {
      final row = _row(
        role: 'owner',
        character: {
          'name': 'Sylvi',
          'portrait_url': 'https://example.com/p.png',
          'current_hp': 8,
          'max_hp': 20,
          'temporary_hp': 2,
          'is_dead': false,
          'race_id': 'race-1',
          'character_classes': [
            {'class_id': 'class-1', 'level': 2, 'is_primary': false},
            {'class_id': 'class-2', 'level': 3, 'is_primary': true},
          ],
        },
      );

      final member = GroupMemberRowMapper.toGroupMember(
        row,
        raceNames: const {'race-1': 'Elfe'},
        classNames: const {'class-1': 'Guerrier', 'class-2': 'Rôdeur'},
      );

      expect(member.characterId, 'char-1');
      expect(member.isGameMaster, isFalse);
      expect(member.isAwaitingCharacter, isFalse);
      expect(member.userId, 'user-1');
      expect(member.role, GroupRole.owner);
      expect(member.name, 'Sylvi');
      expect(member.portraitUrl, 'https://example.com/p.png');
      expect(member.raceName, 'Elfe');
      expect(member.className, 'Rôdeur');
      expect(member.level, 5);
      expect(member.currentHp, 8);
      expect(member.maxHp, 20);
      expect(member.temporaryHp, 2);
      expect(member.isDead, isFalse);
    });

    test('utilise la première classe si aucune n\'est marquée primaire', () {
      final row = _row(
        role: 'membre',
        character: {
          'name': 'Bob',
          'current_hp': 1,
          'max_hp': 1,
          'temporary_hp': 0,
          'race_id': 'race-1',
          'character_classes': [
            {'class_id': 'class-1', 'level': 1, 'is_primary': false},
          ],
        },
      );

      final member = GroupMemberRowMapper.toGroupMember(
        row,
        raceNames: const {'race-1': 'Humain'},
        classNames: const {'class-1': 'Barde'},
      );

      expect(member.className, 'Barde');
      expect(member.role, GroupRole.membre);
    });

    test('champs manquants -> défauts sûrs (jamais de null non attendu)', () {
      final member = GroupMemberRowMapper.toGroupMember(
        _row(character: {}),
        raceNames: const {},
        classNames: const {},
      );

      expect(member.name, '');
      expect(member.portraitUrl, isNull);
      expect(member.raceName, isNull);
      expect(member.className, isNull);
      expect(member.level, 0);
      expect(member.currentHp, 0);
      expect(member.maxHp, 0);
      expect(member.temporaryHp, 0);
      expect(member.isDead, isFalse);
    });

    test('is_dead vrai correctement propagé', () {
      final member = GroupMemberRowMapper.toGroupMember(
        _row(character: {'is_dead': true}),
        raceNames: const {},
        classNames: const {},
      );
      expect(member.isDead, isTrue);
    });
  });

  group('GroupMemberRowMapper.toGroupMember — MJ volontaire', () {
    test('character_id null + is_game_master true -> GroupMember.isGameMaster, '
        'champs personnage tous null', () {
      final member = GroupMemberRowMapper.toGroupMember(
        _row(characterId: null, isGameMaster: true, character: null),
        raceNames: const {},
        classNames: const {},
      );

      expect(member.characterId, isNull);
      expect(member.isGameMaster, isTrue);
      expect(member.isAwaitingCharacter, isFalse);
      expect(member.userId, 'user-1');
      expect(member.portraitUrl, isNull);
      expect(member.raceName, isNull);
      expect(member.className, isNull);
      expect(member.level, isNull);
      expect(member.currentHp, isNull);
      expect(member.maxHp, isNull);
      expect(member.temporaryHp, isNull);
      expect(member.isDead, isNull);
    });

    test('nom résolu via group_members_display_name -> utilisé tel quel', () {
      final member = GroupMemberRowMapper.toGroupMember(
        _row(
          characterId: null,
          isGameMaster: true,
          displayName: 'Brunhilde la MJ',
          character: null,
        ),
        raceNames: const {},
        classNames: const {},
      );

      expect(member.name, 'Brunhilde la MJ');
      expect(member.accountDisplayName, 'Brunhilde la MJ');
    });

    test('nom résolu vide/blanc -> repli "MJ"', () {
      final member = GroupMemberRowMapper.toGroupMember(
        _row(
          characterId: null,
          isGameMaster: true,
          displayName: '   ',
          character: null,
        ),
        raceNames: const {},
        classNames: const {},
      );

      expect(member.name, 'MJ');
      expect(member.accountDisplayName, isNull);
    });

    test('nom absent -> repli "MJ"', () {
      final member = GroupMemberRowMapper.toGroupMember(
        _row(characterId: null, isGameMaster: true, character: null),
        raceNames: const {},
        classNames: const {},
      );

      expect(member.name, 'MJ');
    });
  });

  group('GroupMemberRowMapper.toGroupMember — orphelin', () {
    test('character_id null + is_game_master false -> isAwaitingCharacter, '
        'jamais isGameMaster', () {
      final member = GroupMemberRowMapper.toGroupMember(
        _row(characterId: null, character: null),
        raceNames: const {},
        classNames: const {},
      );

      expect(member.characterId, isNull);
      expect(member.isGameMaster, isFalse);
      expect(member.isAwaitingCharacter, isTrue);
    });

    test('nom résolu via group_members_display_name -> utilisé tel quel', () {
      final member = GroupMemberRowMapper.toGroupMember(
        _row(
          characterId: null,
          displayName: 'Eldrin le rescapé',
          character: null,
        ),
        raceNames: const {},
        classNames: const {},
      );

      expect(member.name, 'Eldrin le rescapé');
    });

    test('nom absent -> repli "En attente d\'un personnage", JAMAIS "MJ"', () {
      final member = GroupMemberRowMapper.toGroupMember(
        _row(characterId: null, character: null),
        raceNames: const {},
        classNames: const {},
      );

      expect(member.name, "En attente d'un personnage");
    });

    test('nom résolu vide/blanc -> même repli, jamais "MJ"', () {
      final member = GroupMemberRowMapper.toGroupMember(
        _row(characterId: null, displayName: '   ', character: null),
        raceNames: const {},
        classNames: const {},
      );

      expect(member.name, "En attente d'un personnage");
    });
  });
}
