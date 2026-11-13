// Tests de `groupMembersRealtimeWatcherProvider`
// (`presentation/providers/group_providers.dart`) — voir sa documentation de
// classe pour le rationale complet. Contrairement au `_NoopSubscription` de
// `group_screen_test.dart` (qui n'invoque jamais `onChanged`), le double de
// `GroupRepository` ci-dessous invoque réellement `onChanged` et permet
// d'observer le cycle de vie du channel Realtime :
// - `onChanged` doit invalider `groupDetailProvider` tant que ce provider est
//   monté, sans jamais lever (garde `ref.mounted`, problème A) ;
// - le channel ne doit être recréé QUE quand la liste de `characterIds`
//   surveillée change réellement, jamais à une simple transition
//   loading -> data de `groupDetailProvider` (ex. un membre dont les PV
//   changent), voir problème B ;
// - `cancel()` doit être appelé à la disposition du `ProviderContainer`.
//
// Bug F07 (`docs/retours-utilisateurs.md`) : `GroupRepository
// .subscribeToMemberUpdates` écoute désormais aussi `INSERT`/`DELETE` sur
// `group_members` (seul `INSERT` est filtré par `group_id` ; `DELETE` est
// écouté sans filtre, REPLICA IDENTITY DEFAULT : l'ancienne ligne ne porte que
// l'`id`, et le client n'actualise que si l'`id` supprimé est celui d'un
// membre connu, `shouldRefreshOnMemberDelete`) en plus de `UPDATE` sur
// `characters` — la construction réelle du filtre Postgres est du ressort
// de `SupabaseGroupRepository` (non testée ici, pas de mock du SDK Realtime
// dans ce dépôt), mais ce fichier vérifie : (1) que `groupId` est bien
// transmis au repository (sans quoi celui-ci ne pourrait pas construire ce
// second filtre) et (2) que l'arrivée d'un nouveau membre — simulée par le
// même `onChanged` générique, puisque le double de `GroupRepository` ne
// distingue pas la source du changement, exactement comme la vraie
// implémentation qui relaie les deux canaux sur le même callback — invalide
// bien `groupDetailProvider` et fait apparaître le nouveau membre sans que
// le MJ ait besoin de quitter/rouvrir l'écran "Groupe".

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/groups/data/group_repository.dart';
import 'package:personnages/features/groups/domain/created_group.dart';
import 'package:personnages/features/groups/domain/group_detail.dart';
import 'package:personnages/features/groups/domain/group_member.dart';
import 'package:personnages/features/groups/domain/group_note_entry.dart';
import 'package:personnages/features/groups/domain/group_preview.dart';
import 'package:personnages/features/groups/domain/group_role.dart';
import 'package:personnages/features/groups/domain/group_summary.dart';
import 'package:personnages/features/groups/domain/group_treasure.dart';
import 'package:personnages/features/groups/domain/group_treasure_item.dart';
import 'package:personnages/features/groups/domain/joined_group.dart';
import 'package:personnages/features/groups/presentation/providers/group_providers.dart';

void main() {
  group('groupMembersRealtimeWatcherProvider', () {
    const groupId = 'group-1';

    late _FakeGroupRepository fakeRepository;
    late ProviderContainer container;

    setUp(() {
      fakeRepository = _FakeGroupRepository();
      container = ProviderContainer(
        overrides: [groupRepositoryProvider.overrideWithValue(fakeRepository)],
      );
      addTearDown(container.dispose);
    });

    test('souscrit une fois le détail résolu, et onChanged invalide '
        'groupDetailProvider tant que ce provider est monté', () async {
      fakeRepository.detailBuilder = () =>
          _detail(memberIds: const ['char-a', 'char-b']);

      container.listen(
        groupMembersRealtimeWatcherProvider(groupId),
        (previous, next) {},
        fireImmediately: true,
      );
      await pumpEventQueue();

      expect(fakeRepository.subscribeCallCount, 1);
      expect(fakeRepository.lastSubscribedCharacterIds, ['char-a', 'char-b']);
      expect(
        fakeRepository.subscribedGroupIds,
        ['group-1'],
        reason:
            'groupId doit être transmis au repository (F07) pour qu\'il '
            'puisse filtrer le canal group_members',
      );
      expect(fakeRepository.fetchGroupDetailCallCount, 1);

      fakeRepository.lastOnChanged!();
      await pumpEventQueue();

      expect(
        fakeRepository.fetchGroupDetailCallCount,
        2,
        reason: 'onChanged doit invalider groupDetailProvider(groupId)',
      );
    });

    test('un évènement de type "nouveau membre" (INSERT group_members, F07) '
        'invalide groupDetailProvider et fait apparaître le membre sans '
        'quitter l\'écran', () async {
      // Au départ, le MJ est seul sur l'écran "Groupe" : un seul membre
      // résolu par groupDetailProvider.
      var memberIds = const ['char-a'];
      fakeRepository.detailBuilder = () => _detail(memberIds: memberIds);

      final states = <GroupDetail>[];
      container.listen(groupDetailProvider(groupId), (previous, next) {
        final value = next.value;
        if (value != null) states.add(value);
      }, fireImmediately: true);

      container.listen(
        groupMembersRealtimeWatcherProvider(groupId),
        (previous, next) {},
        fireImmediately: true,
      );
      await pumpEventQueue();

      expect(states, hasLength(1));
      expect(states.single.members, hasLength(1));

      // Un nouveau membre rejoint le groupe (INSERT sur `group_members`,
      // non déployé en prod au moment de ce correctif — voir la doc de
      // `GroupRepository.subscribeToMemberUpdates`) : côté client, cet
      // évènement arrive sur le même `onChanged` que les mises à jour de
      // PV, puisque les deux canaux relaient vers le même callback.
      memberIds = const ['char-a', 'char-b'];
      fakeRepository.lastOnChanged!();
      await pumpEventQueue();

      expect(
        fakeRepository.fetchGroupDetailCallCount,
        2,
        reason:
            'un évènement group_members doit invalider groupDetailProvider '
            'exactement comme un évènement characters',
      );
      expect(
        states.last.members,
        hasLength(2),
        reason:
            'le MJ déjà sur l\'écran "Groupe" doit voir apparaître le '
            'nouveau membre sans quitter/rouvrir l\'écran (F07)',
      );
    });

    test('un DELETE group_members (F08) dont l\'id est celui d\'un membre '
        'connu invalide groupDetailProvider : le membre disparaît', () async {
      var memberIds = const ['char-a', 'char-b'];
      fakeRepository.detailBuilder = () => _detail(memberIds: memberIds);

      final states = <GroupDetail>[];
      container.listen(groupDetailProvider(groupId), (previous, next) {
        final value = next.value;
        if (value != null) states.add(value);
      }, fireImmediately: true);
      container.listen(
        groupMembersRealtimeWatcherProvider(groupId),
        (previous, next) {},
        fireImmediately: true,
      );
      await pumpEventQueue();
      expect(states.last.members, hasLength(2));

      // Le joueur 'row-1' quitte le groupe : Realtime ne fournit que l'id
      // (REPLICA IDENTITY DEFAULT), jamais group_id.
      memberIds = const ['char-a'];
      fakeRepository.simulateMemberDelete({'id': 'row-1'});
      await pumpEventQueue();

      expect(fakeRepository.fetchGroupDetailCallCount, 2);
      expect(states.last.members, hasLength(1));
    });

    test('un DELETE group_members (F08) dont l\'id est inconnu (autre '
        'groupe) ou absent n\'invalide pas groupDetailProvider', () async {
      fakeRepository.detailBuilder = () =>
          _detail(memberIds: const ['char-a', 'char-b']);

      container.listen(
        groupMembersRealtimeWatcherProvider(groupId),
        (previous, next) {},
        fireImmediately: true,
      );
      await pumpEventQueue();
      expect(fakeRepository.fetchGroupDetailCallCount, 1);

      fakeRepository.simulateMemberDelete({'id': 'row-other-group'});
      fakeRepository.simulateMemberDelete(<String, dynamic>{});
      await pumpEventQueue();

      expect(fakeRepository.fetchGroupDetailCallCount, 1);
    });

    test('onChanged appelé après démontage du provider ne lève pas '
        '(garde ref.mounted, problème A)', () async {
      fakeRepository.detailBuilder = () => _detail(memberIds: const ['char-a']);

      container.listen(
        groupMembersRealtimeWatcherProvider(groupId),
        (previous, next) {},
        fireImmediately: true,
      );
      await pumpEventQueue();
      final onChanged = fakeRepository.lastOnChanged!;

      container.dispose();

      expect(onChanged, returnsNormally);
    });

    test('un refresh de groupDetailProvider qui ne change pas la liste de '
        'characterIds (ex. simple mise à jour de PV) ne recrée pas le '
        'channel (problème B)', () async {
      var hp = 10;
      fakeRepository.detailBuilder = () =>
          _detail(memberIds: const ['char-a', 'char-b'], firstMemberHp: hp);

      container.listen(
        groupMembersRealtimeWatcherProvider(groupId),
        (previous, next) {},
        fireImmediately: true,
      );
      await pumpEventQueue();
      expect(fakeRepository.subscribeCallCount, 1);
      final firstSubscription = fakeRepository.subscriptions.single;

      hp = 25;
      container.invalidate(groupDetailProvider(groupId));
      await pumpEventQueue();

      expect(
        fakeRepository.fetchGroupDetailCallCount,
        2,
        reason: 'le détail a bien été rafraîchi',
      );
      expect(
        fakeRepository.subscribeCallCount,
        1,
        reason:
            'même liste de characterIds -> le channel ne doit pas être '
            'recréé',
      );
      expect(firstSubscription.cancelled, isFalse);
    });

    test('un changement réel de la liste de characterIds (un membre rejoint) '
        'recrée le channel et annule le précédent', () async {
      var memberIds = const ['char-a', 'char-b'];
      fakeRepository.detailBuilder = () => _detail(memberIds: memberIds);

      container.listen(
        groupMembersRealtimeWatcherProvider(groupId),
        (previous, next) {},
        fireImmediately: true,
      );
      await pumpEventQueue();
      expect(fakeRepository.subscribeCallCount, 1);
      final firstSubscription = fakeRepository.subscriptions.single;

      memberIds = const ['char-a', 'char-b', 'char-c'];
      container.invalidate(groupDetailProvider(groupId));
      await pumpEventQueue();

      expect(fakeRepository.subscribeCallCount, 2);
      expect(fakeRepository.lastSubscribedCharacterIds, memberIds);
      expect(
        firstSubscription.cancelled,
        isTrue,
        reason: 'ancien channel annulé avant la recréation',
      );
    });

    test('dispose() du ProviderContainer annule le channel Realtime', () async {
      fakeRepository.detailBuilder = () => _detail(memberIds: const ['char-a']);

      container.listen(
        groupMembersRealtimeWatcherProvider(groupId),
        (previous, next) {},
        fireImmediately: true,
      );
      await pumpEventQueue();
      final subscription = fakeRepository.subscriptions.single;
      expect(subscription.cancelled, isFalse);

      container.dispose();

      expect(subscription.cancelled, isTrue);
    });
  });
}

GroupDetail _detail({required List<String> memberIds, int firstMemberHp = 10}) {
  return GroupDetail(
    id: 'group-1',
    name: 'Les Lames',
    ownerId: 'owner-1',
    inviteCode: 'ABCD1234',
    currentUserId: 'owner-1',
    members: [
      for (var i = 0; i < memberIds.length; i++)
        GroupMember(
          membershipId: 'row-$i',
          characterId: memberIds[i],
          userId: 'user-$i',
          role: i == 0 ? GroupRole.owner : GroupRole.membre,
          name: 'Personnage $i',
          isGameMaster: false,
          level: 1,
          currentHp: i == 0 ? firstMemberHp : 10,
          maxHp: 20,
          temporaryHp: 0,
          isDead: false,
        ),
    ],
  );
}

class _RecordingSubscription implements GroupRealtimeSubscription {
  bool cancelled = false;

  @override
  Future<void> cancel() async {
    cancelled = true;
  }
}

/// Double de `GroupRepository` qui invoque réellement `onChanged` (voir
/// [_FakeGroupRepository.lastOnChanged]), contrairement au
/// `_NoopSubscription` de `group_screen_test.dart` — seuls
/// [fetchGroupDetail]/[subscribeToMemberUpdates] sont exercés par ces tests.
class _FakeGroupRepository implements GroupRepository {
  @override
  Future<List<String>> fetchGroupIdsForCharacter(String characterId) async =>
      const [];

  GroupDetail Function()? detailBuilder;
  int fetchGroupDetailCallCount = 0;

  int subscribeCallCount = 0;
  List<String>? lastSubscribedCharacterIds;
  void Function()? lastOnChanged;
  bool Function(String)? lastIsKnownMembershipId;
  final List<_RecordingSubscription> subscriptions = [];

  @override
  Future<GroupDetail> fetchGroupDetail(String groupId) async {
    fetchGroupDetailCallCount++;
    return detailBuilder!();
  }

  List<String> subscribedGroupIds = [];

  @override
  GroupRealtimeSubscription subscribeToMemberUpdates({
    required String groupId,
    required List<String> characterIds,
    required bool Function(String membershipId) isKnownMembershipId,
    required void Function() onChanged,
  }) {
    subscribeCallCount++;
    lastSubscribedCharacterIds = characterIds;
    subscribedGroupIds.add(groupId);
    lastOnChanged = onChanged;
    lastIsKnownMembershipId = isKnownMembershipId;
    final subscription = _RecordingSubscription();
    subscriptions.add(subscription);
    return subscription;
  }

  /// Reproduit le callback `DELETE` de `SupabaseGroupRepository` (même
  /// fonction de décision), le SDK Realtime n'étant pas mockable (D176).
  void simulateMemberDelete(Map<String, dynamic> oldRecord) {
    if (shouldRefreshOnMemberDelete(oldRecord, lastIsKnownMembershipId!)) {
      lastOnChanged!();
    }
  }

  @override
  Future<List<GroupNoteEntry>> fetchGroupNoteEntries(String groupId) =>
      throw UnimplementedError();

  @override
  Future<void> addGroupNoteEntry({
    required String groupId,
    String? title,
    required String body,
  }) => throw UnimplementedError();

  @override
  Future<void> updateGroupNoteEntry({
    required String entryId,
    String? title,
    required String body,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteGroupNoteEntry(String entryId) =>
      throw UnimplementedError();

  @override
  Future<List<GroupSummary>> fetchMyGroups() => throw UnimplementedError();

  @override
  Future<CreatedGroup> createGroup({
    required String name,
    String? characterId,
  }) => throw UnimplementedError();

  @override
  Future<GroupPreview> previewGroupInvite(String code) =>
      throw UnimplementedError();

  @override
  Future<JoinedGroup> joinGroup({required String code, String? characterId}) =>
      throw UnimplementedError();

  @override
  Future<void> renameGroup({required String groupId, required String name}) =>
      throw UnimplementedError();

  @override
  Future<String> regenerateInviteCode(String groupId) =>
      throw UnimplementedError();

  @override
  Future<void> dissolveGroup(String groupId) => throw UnimplementedError();

  @override
  Future<void> leaveGroup(String groupId) => throw UnimplementedError();

  @override
  Future<void> removeMember({
    required String groupId,
    required String userId,
  }) => throw UnimplementedError();

  @override
  Future<void> setGroupCharacter({
    required String groupId,
    required String characterId,
  }) => throw UnimplementedError();

  @override
  Future<GroupTreasure> fetchGroupTreasure(String groupId) =>
      throw UnimplementedError();

  @override
  Future<void> addToTreasure({
    required String groupId,
    required Map<CurrencyKind, int> newCurrencyTotals,
    required List<GroupTreasureItem> newItems,
  }) => throw UnimplementedError();

  @override
  Future<bool> claimTreasureCurrency({
    required String groupId,
    required String characterId,
    required CurrencyKind currency,
    required int amount,
  }) => throw UnimplementedError();

  @override
  Future<void> claimTreasureItem({
    required String groupId,
    required String characterId,
    required GroupTreasureItem item,
    required int quantity,
  }) => throw UnimplementedError();
}
