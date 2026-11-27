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
    isGameMaster: false,
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

  test('memberCharacterIds retombe sur userId pour un MJ sans personnage', () {
    final gameMaster = GroupMember(
      userId: 'user-mj',
      role: GroupRole.membre,
      name: 'MJ',
      isGameMaster: true,
    );
    final detail = GroupDetail(
      id: 'group-1',
      name: 'Les Lames',
      ownerId: 'user-owner',
      inviteCode: 'AB3F7K2M',
      currentUserId: 'user-owner',
      members: [
        _member(characterId: 'char-1', userId: 'user-1', role: GroupRole.owner),
        gameMaster,
      ],
    );

    expect(detail.memberCharacterIds, ['char-1', 'user-mj']);
  });

  test('memberRowIds expose les group_members.id connus, sans les null', () {
    final detail = GroupDetail(
      id: 'group-1',
      name: 'Les Lames',
      ownerId: 'user-owner',
      inviteCode: 'AB3F7K2M',
      currentUserId: 'user-owner',
      members: [
        _member(
          characterId: 'char-1',
          userId: 'user-1',
          role: GroupRole.owner,
        ).copyWith(membershipId: 'row-1'),
        _member(
          characterId: 'char-2',
          userId: 'user-2',
          role: GroupRole.membre,
        ),
      ],
    );

    expect(detail.memberRowIds, {'row-1'});
  });

  // Étape 4 : campagne associée au groupe (`story_title`,
  // `story_summary_public`), décision n° 36.
  group('GroupDetail campagne', () {
    GroupDetail detail({String? storyTitle, String? storySummaryPublic}) =>
        GroupDetail(
          id: 'group-1',
          name: 'Les Lames',
          ownerId: 'user-owner',
          inviteCode: 'AB3F7K2M',
          currentUserId: 'user-owner',
          members: const [],
          storyTitle: storyTitle,
          storySummaryPublic: storySummaryPublic,
        );

    test('avec un titre et un résumé : carte complète', () {
      final d = detail(
        storyTitle: ' La Mine perdue ',
        storySummaryPublic: 'Phandaline.\nUne mine.',
      );
      expect(d.campaignTitle, 'La Mine perdue');
      expect(d.campaignSummary, 'Phandaline.\nUne mine.');
      expect(d.hasCampaignCard, isTrue);
    });

    test('sans titre (colonnes absentes ou NULL) : pas de carte, même avec '
        'un résumé', () {
      expect(detail().storyTitle, isNull);
      expect(detail().hasCampaignCard, isFalse);
      final orphanSummary = detail(storySummaryPublic: 'Un résumé.');
      expect(orphanSummary.campaignSummary, isNull);
      expect(orphanSummary.hasCampaignCard, isFalse);
    });

    test('titre identique au nom avec un résumé : résumé seul', () {
      final d = detail(
        storyTitle: 'les lames',
        storySummaryPublic: 'Un résumé.',
      );
      expect(d.campaignTitle, isNull);
      expect(d.campaignSummary, 'Un résumé.');
      expect(d.hasCampaignCard, isTrue);
    });

    test('titre identique au nom sans résumé : pas de carte', () {
      final d = detail(storyTitle: 'Les Lames');
      expect(d.campaignTitle, isNull);
      expect(d.hasCampaignCard, isFalse);
    });
  });

  // « Devenir MJ » : propriétaire qui joue un personnage dans ce groupe,
  // jamais un autre cas.
  group('GroupDetail.canBecomeGameMaster', () {
    GroupDetail detail({
      required String currentUserId,
      required List<GroupMember> members,
    }) => GroupDetail(
      id: 'group-1',
      name: 'Les Lames',
      ownerId: 'user-owner',
      inviteCode: 'AB3F7K2M',
      currentUserId: currentUserId,
      members: members,
    );

    final ownerPlaying = _member(
      characterId: 'char-owner',
      userId: 'user-owner',
      role: GroupRole.owner,
    );
    const ownerGameMaster = GroupMember(
      userId: 'user-owner',
      role: GroupRole.owner,
      name: 'MJ',
      isGameMaster: true,
    );
    const ownerOrphan = GroupMember(
      userId: 'user-owner',
      role: GroupRole.owner,
      name: 'Orphelin',
      isGameMaster: false,
    );
    final player = _member(
      characterId: 'char-2',
      userId: 'user-2',
      role: GroupRole.membre,
    );

    test('propriétaire qui joue un personnage : vrai', () {
      expect(
        detail(
          currentUserId: 'user-owner',
          members: [ownerPlaying, player],
        ).canBecomeGameMaster,
        isTrue,
      );
    });

    test('propriétaire déjà MJ sans personnage : faux', () {
      expect(
        detail(
          currentUserId: 'user-owner',
          members: [ownerGameMaster, player],
        ).canBecomeGameMaster,
        isFalse,
      );
    });

    test('propriétaire orphelin (personnage supprimé) : faux', () {
      expect(
        detail(
          currentUserId: 'user-owner',
          members: [ownerOrphan],
        ).canBecomeGameMaster,
        isFalse,
      );
    });

    test('propriétaire sans ligne membre (parti) : faux', () {
      expect(
        detail(
          currentUserId: 'user-owner',
          members: [player],
        ).canBecomeGameMaster,
        isFalse,
      );
    });

    test('membre qui joue mais n\'est pas propriétaire : faux', () {
      expect(
        detail(
          currentUserId: 'user-2',
          members: [ownerPlaying, player],
        ).canBecomeGameMaster,
        isFalse,
      );
    });
  });
}
