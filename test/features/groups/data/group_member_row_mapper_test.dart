import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/groups/data/group_member_row_mapper.dart';
import 'package:personnages/features/groups/domain/group_role.dart';

Map<String, dynamic> _row({
  String? characterId = 'char-1',
  String userId = 'user-1',
  String? role = 'owner',
  Map<String, dynamic>? character,
}) {
  return {
    'character_id': characterId,
    'user_id': userId,
    'role': role,
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
        currentUserId: 'user-1',
      );

      expect(member.characterId, 'char-1');
      expect(member.isGameMaster, isFalse);
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
        currentUserId: 'user-1',
      );

      expect(member.className, 'Barde');
      expect(member.role, GroupRole.membre);
    });

    test('champs manquants -> défauts sûrs (jamais de null non attendu)', () {
      final member = GroupMemberRowMapper.toGroupMember(
        _row(character: {}),
        raceNames: const {},
        classNames: const {},
        currentUserId: 'user-1',
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
        currentUserId: 'user-1',
      );
      expect(member.isDead, isTrue);
    });
  });

  group('GroupMemberRowMapper.toGroupMember — MJ sans personnage', () {
    test('character_id null -> GroupMember.isGameMaster, champs personnage '
        'tous null', () {
      final member = GroupMemberRowMapper.toGroupMember(
        _row(characterId: null, character: null),
        raceNames: const {},
        classNames: const {},
        currentUserId: 'user-2',
      );

      expect(member.characterId, isNull);
      expect(member.isGameMaster, isTrue);
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

    test('ligne MJ du joueur connecté -> nom de compte réel', () {
      final member = GroupMemberRowMapper.toGroupMember(
        _row(characterId: null, userId: 'user-me', character: null),
        raceNames: const {},
        classNames: const {},
        currentUserId: 'user-me',
        currentUserDisplayName: 'Brunhilde la MJ',
      );

      expect(member.name, 'Brunhilde la MJ');
    });

    test('ligne MJ du joueur connecté sans nom de compte renseigné -> '
        'repli "MJ"', () {
      final member = GroupMemberRowMapper.toGroupMember(
        _row(characterId: null, userId: 'user-me', character: null),
        raceNames: const {},
        classNames: const {},
        currentUserId: 'user-me',
        currentUserDisplayName: '   ',
      );

      expect(member.name, 'MJ');
    });

    test('ligne MJ d\'un AUTRE membre -> toujours "MJ" (pas de nom de '
        'compte exposé pour un autre utilisateur)', () {
      final member = GroupMemberRowMapper.toGroupMember(
        _row(characterId: null, userId: 'user-other', character: null),
        raceNames: const {},
        classNames: const {},
        currentUserId: 'user-me',
        currentUserDisplayName: 'Mon propre nom',
      );

      expect(member.name, 'MJ');
    });
  });
}
