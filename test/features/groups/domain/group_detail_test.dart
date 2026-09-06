import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/groups/domain/group_detail.dart';
import 'package:personnages/features/groups/domain/group_member.dart';
import 'package:personnages/features/groups/domain/group_role.dart';

GroupMember _member({
  required String characterId,
  required String userId,
  required GroupRole role,
}) {
  return GroupMember(
    characterId: characterId,
    userId: userId,
    role: role,
    name: 'Perso $characterId',
    level: 1,
    currentHp: 10,
    maxHp: 10,
    temporaryHp: 0,
    isDead: false,
  );
}

void main() {
  group('GroupDetail.isOwner', () {
    test('vrai quand ownerId == currentUserId', () {
      final detail = GroupDetail(
        id: 'group-1',
        name: 'Les Lames',
        ownerId: 'user-owner',
        inviteCode: 'AB3F7K2M',
        currentUserId: 'user-owner',
        members: const [],
      );
      expect(detail.isOwner, isTrue);
    });

    test('faux sinon', () {
      final detail = GroupDetail(
        id: 'group-1',
        name: 'Les Lames',
        ownerId: 'user-owner',
        inviteCode: 'AB3F7K2M',
        currentUserId: 'user-membre',
        members: const [],
      );
      expect(detail.isOwner, isFalse);
    });
  });

  group('GroupDetail.currentMember / currentUserRole', () {
    test('résout le membre correspondant à currentUserId', () {
      final owner = _member(
        characterId: 'char-owner',
        userId: 'user-owner',
        role: GroupRole.owner,
      );
      final membre = _member(
        characterId: 'char-membre',
        userId: 'user-membre',
        role: GroupRole.membre,
      );
      final detail = GroupDetail(
        id: 'group-1',
        name: 'Les Lames',
        ownerId: 'user-owner',
        inviteCode: 'AB3F7K2M',
        currentUserId: 'user-membre',
        members: [owner, membre],
      );

      expect(detail.currentMember, membre);
      expect(detail.currentUserRole, GroupRole.membre);
    });

    test('null si le joueur connecté ne fait plus partie des membres', () {
      final owner = _member(
        characterId: 'char-owner',
        userId: 'user-owner',
        role: GroupRole.owner,
      );
      final detail = GroupDetail(
        id: 'group-1',
        name: 'Les Lames',
        ownerId: 'user-owner',
        inviteCode: 'AB3F7K2M',
        currentUserId: 'user-inconnu',
        members: [owner],
      );

      expect(detail.currentMember, isNull);
      expect(detail.currentUserRole, GroupRole.membre);
    });
  });

  test('memberCharacterIds retourne les characterId de tous les membres', () {
    final detail = GroupDetail(
      id: 'group-1',
      name: 'Les Lames',
      ownerId: 'user-owner',
      inviteCode: 'AB3F7K2M',
      currentUserId: 'user-owner',
      members: [
        _member(characterId: 'char-1', userId: 'user-1', role: GroupRole.owner),
        _member(
          characterId: 'char-2',
          userId: 'user-2',
          role: GroupRole.membre,
        ),
      ],
    );

    expect(detail.memberCharacterIds, ['char-1', 'char-2']);
  });
}
