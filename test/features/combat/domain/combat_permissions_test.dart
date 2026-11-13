import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/combat/domain/combat_permissions.dart';
import 'package:personnages/features/groups/domain/group_detail.dart';
import 'package:personnages/features/groups/domain/group_member.dart';
import 'package:personnages/features/groups/domain/group_role.dart';

GroupDetail buildGroup({
  required String ownerId,
  required String me,
  required List<GroupMember> members,
}) => GroupDetail(
  id: 'g',
  name: 'Groupe',
  ownerId: ownerId,
  inviteCode: 'ABC',
  currentUserId: me,
  members: members,
);

GroupMember member(
  String userId, {
  String? characterId,
  bool gm = false,
  GroupRole role = GroupRole.membre,
}) => GroupMember(
  userId: userId,
  characterId: characterId,
  role: role,
  name: userId,
  isGameMaster: gm,
);

void main() {
  group('canStartCombat', () {
    test('propriétaire qui joue avec un personnage -> faux', () {
      final g = buildGroup(
        ownerId: 'me',
        me: 'me',
        members: [member('me', characterId: 'c1', role: GroupRole.owner)],
      );
      expect(canStartCombat(g), isFalse);
    });

    test('membre MJ non propriétaire -> faux', () {
      final g = buildGroup(
        ownerId: 'boss',
        me: 'me',
        members: [
          member('boss', characterId: 'c0', role: GroupRole.owner),
          member('me', gm: true),
        ],
      );
      expect(canStartCombat(g), isFalse);
    });

    test('propriétaire MJ -> vrai', () {
      final g = buildGroup(
        ownerId: 'me',
        me: 'me',
        members: [member('me', gm: true, role: GroupRole.owner)],
      );
      expect(canStartCombat(g), isTrue);
    });

    test('propriétaire sans ligne membre -> faux', () {
      final g = buildGroup(ownerId: 'me', me: 'me', members: const []);
      expect(canStartCombat(g), isFalse);
    });
  });

  group('canEndCombat', () {
    test('propriétaire même sans ligne membre -> vrai, sinon faux', () {
      expect(
        canEndCombat(buildGroup(ownerId: 'me', me: 'me', members: const [])),
        isTrue,
      );
      expect(
        canEndCombat(
          buildGroup(ownerId: 'x', me: 'me', members: [member('me', gm: true)]),
        ),
        isFalse,
      );
    });
  });
}
