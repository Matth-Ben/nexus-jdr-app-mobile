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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/groups/data/group_repository.dart';
import 'package:personnages/features/groups/domain/created_group.dart';
import 'package:personnages/features/groups/domain/group_detail.dart';
import 'package:personnages/features/groups/domain/group_member.dart';
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

    test(
      'souscrit une fois le détail résolu, et onChanged invalide '
      'groupDetailProvider tant que ce provider est monté',
      () async {
        fakeRepository.detailBuilder = () =>
            _detail(memberIds: const ['char-a', 'char-b']);

        container.listen(
          groupMembersRealtimeWatcherProvider(groupId),
          (previous, next) {},
          fireImmediately: true,
        );
        await pumpEventQueue();

        expect(fakeRepository.subscribeCallCount, 1);
        expect(fakeRepository.lastSubscribedCharacterIds, [
          'char-a',
          'char-b',
        ]);
        expect(fakeRepository.fetchGroupDetailCallCount, 1);

        fakeRepository.lastOnChanged!();
        await pumpEventQueue();

        expect(
          fakeRepository.fetchGroupDetailCallCount,
          2,
          reason: 'onChanged doit invalider groupDetailProvider(groupId)',
        );
      },
    );

    test(
      'onChanged appelé après démontage du provider ne lève pas '
      '(garde ref.mounted, problème A)',
      () async {
        fakeRepository.detailBuilder = () =>
            _detail(memberIds: const ['char-a']);

        container.listen(
          groupMembersRealtimeWatcherProvider(groupId),
          (previous, next) {},
          fireImmediately: true,
        );
        await pumpEventQueue();
        final onChanged = fakeRepository.lastOnChanged!;

        container.dispose();

        expect(onChanged, returnsNormally);
      },
    );

    test(
      'un refresh de groupDetailProvider qui ne change pas la liste de '
      'characterIds (ex. simple mise à jour de PV) ne recrée pas le '
      'channel (problème B)',
      () async {
        var hp = 10;
        fakeRepository.detailBuilder = () => _detail(
          memberIds: const ['char-a', 'char-b'],
          firstMemberHp: hp,
        );

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
      },
    );

    test(
      'un changement réel de la liste de characterIds (un membre rejoint) '
      'recrée le channel et annule le précédent',
      () async {
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
      },
    );

    test('dispose() du ProviderContainer annule le channel Realtime', () async {
      fakeRepository.detailBuilder = () =>
          _detail(memberIds: const ['char-a']);

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
          characterId: memberIds[i],
          userId: 'user-$i',
          role: i == 0 ? GroupRole.owner : GroupRole.membre,
          name: 'Personnage $i',
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
  GroupDetail Function()? detailBuilder;
  int fetchGroupDetailCallCount = 0;

  int subscribeCallCount = 0;
  List<String>? lastSubscribedCharacterIds;
  void Function()? lastOnChanged;
  final List<_RecordingSubscription> subscriptions = [];

  @override
  Future<GroupDetail> fetchGroupDetail(String groupId) async {
    fetchGroupDetailCallCount++;
    return detailBuilder!();
  }

  @override
  GroupRealtimeSubscription subscribeToMemberUpdates({
    required List<String> characterIds,
    required void Function() onChanged,
  }) {
    subscribeCallCount++;
    lastSubscribedCharacterIds = characterIds;
    lastOnChanged = onChanged;
    final subscription = _RecordingSubscription();
    subscriptions.add(subscription);
    return subscription;
  }

  @override
  Future<List<GroupSummary>> fetchMyGroups() => throw UnimplementedError();

  @override
  Future<CreatedGroup> createGroup({
    required String name,
    required String characterId,
  }) => throw UnimplementedError();

  @override
  Future<GroupPreview> previewGroupInvite(String code) =>
      throw UnimplementedError();

  @override
  Future<JoinedGroup> joinGroup({
    required String code,
    required String characterId,
  }) => throw UnimplementedError();

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
