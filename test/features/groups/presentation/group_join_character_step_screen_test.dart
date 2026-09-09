// Tests de widget de l'étape 3/3 "Choix du personnage" du flux "Rejoindre
// un groupe" — calque `join_character_step_screen_test.dart`.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/features/character_creation/domain/character_creation_draft.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_draft_provider.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_return_route_provider.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/characters/domain/inventory_catalog_item.dart';
import 'package:personnages/features/characters/domain/level_up_apply_result.dart';
import 'package:personnages/features/characters/domain/level_up_feat_option.dart';
import 'package:personnages/features/characters/domain/level_up_invocation_option.dart';
import 'package:personnages/features/characters/domain/level_up_choice_selection.dart';
import 'package:personnages/features/characters/domain/level_up_level_data.dart';
import 'package:personnages/features/characters/domain/rest_type.dart';
import 'package:personnages/features/characters/domain/reward_item_draft.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/features/characters/presentation/widgets/character_card.dart';
import 'package:personnages/features/groups/data/group_repository.dart';
import 'package:personnages/features/groups/domain/created_group.dart';
import 'package:personnages/features/groups/domain/group_detail.dart';
import 'package:personnages/features/groups/domain/group_invite_failure.dart';
import 'package:personnages/features/groups/domain/group_preview.dart';
import 'package:personnages/features/groups/domain/group_summary.dart';
import 'package:personnages/features/groups/domain/group_treasure.dart';
import 'package:personnages/features/groups/domain/group_treasure_item.dart';
import 'package:personnages/features/groups/domain/joined_group.dart';
import 'package:personnages/features/groups/presentation/group_join_character_step_screen.dart';
import 'package:personnages/features/groups/presentation/providers/group_providers.dart';

class _FakeCharacterRepository implements CharacterRepository {
  List<CharacterSummary>? charactersToReturn;
  Object? charactersErrorToThrow;

  @override
  Future<List<CharacterSummary>> fetchCharacters() async {
    if (charactersErrorToThrow != null) throw charactersErrorToThrow!;
    return charactersToReturn ?? const [];
  }

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) =>
      throw UnimplementedError();

  @override
  Future<WriteOutcome> setDead({
    required String characterId,
    required bool isDead,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> setArchived({
    required String characterId,
    required bool isArchived,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> setInspiration({
    required String characterId,
    required bool inspiration,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> setSpellFavorite({
    required String characterId,
    required int spellId,
    required bool isFavorite,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> setSpellPrepared({
    required String characterId,
    required int spellId,
    required bool prepared,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> updateHp({
    required String characterId,
    required int currentHp,
    required int temporaryHp,
  }) => throw UnimplementedError();

  @override
  Future<String> uploadPortrait({
    required String characterId,
    required Uint8List bytes,
  }) => throw UnimplementedError();

  @override
  Future<void> removePortrait({
    required String characterId,
    required String portraitUrl,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> addXp({
    required String characterId,
    required int newXp,
  }) => throw UnimplementedError();

  @override
  Future<LevelUpLevelData> fetchLevelUpLevelData({
    required Object classId,
    required int targetLevel,
  }) => throw UnimplementedError();

  @override
  Future<List<LevelUpFeatOption>> fetchAvailableFeats({
    required String characterId,
  }) async => throw UnimplementedError();

  @override
  Future<List<LevelUpInvocationOption>> fetchAvailableInvocations({
    required String characterId,
  }) async => throw UnimplementedError();

  @override
  Future<LevelUpApplyResult> applyLevelUp({
    required String characterId,
    required Object classId,
    required String className,
    required bool isMulticlassing,
    required int hpRolled,
    required String hpMethod,
    required int hpGain,
    LevelUpChoiceSelection? choice,
    List<int> initialSpellIds = const [],
    List<int> invocationIds = const [],
  }) => throw UnimplementedError();

  @override
  Future<void> applyRest({
    required String characterId,
    required RestType type,
    required String className,
    int diceSpent = 0,
    int appliedGain = 0,
  }) => throw UnimplementedError();

  @override
  Future<void> leaveStory({required String characterCampaignId}) =>
      throw UnimplementedError();

  @override
  Future<WriteOutcome> updateStoryFields({
    required String characterId,
    String? appearanceText,
    String? traitsText,
    String? idealsText,
    String? bondsText,
    String? flawsText,
    String? backstoryText,
    String? alliesText,
    String? featuresText,
    String? treasureText,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> useInventoryItem({
    required String characterId,
    required String inventoryId,
    required int newQuantity,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> setInventoryItemEquipped({
    required String characterId,
    required String inventoryId,
    required bool equipped,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> setInventoryItemAttuned({
    required String characterId,
    required String inventoryId,
    required bool attuned,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> removeInventoryItem({
    required String characterId,
    required String inventoryId,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> adjustCurrency({
    required String characterId,
    required CurrencyKind currency,
    required int newAmount,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> addInventoryItem({
    required String characterId,
    required int itemId,
    required int quantity,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> addCustomInventoryItem({
    required String characterId,
    required String customName,
    required int quantity,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> addReward({
    required String characterId,
    required Map<CurrencyKind, int> newCurrencyTotals,
    required List<RewardItemDraft> items,
  }) => throw UnimplementedError();

  @override
  Future<List<InventoryCatalogItem>> fetchInventoryCatalog() =>
      throw UnimplementedError();

  @override
  Future<WriteOutcome> castSpell({
    required String characterId,
    required int slotLevel,
    required int slotsUsed,
    bool isPactSlot = false,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> useClassFeature({
    required String characterId,
    required int classFeatureId,
    required int usesRemaining,
  }) => throw UnimplementedError();
}

class _FakeGroupRepository implements GroupRepository {
  Object? joinErrorToThrow;
  Completer<JoinedGroup>? joinCompleter;
  String? lastJoinedCode;
  String? lastJoinedCharacterId;
  int joinCallCount = 0;

  @override
  Future<JoinedGroup> joinGroup({
    required String code,
    required String characterId,
  }) async {
    joinCallCount++;
    lastJoinedCode = code;
    lastJoinedCharacterId = characterId;
    if (joinCompleter != null) return joinCompleter!.future;
    if (joinErrorToThrow != null) throw joinErrorToThrow!;
    return const JoinedGroup(groupId: 'group-1', name: 'Les Lames');
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
  Future<GroupDetail> fetchGroupDetail(String groupId) =>
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

  @override
  GroupRealtimeSubscription subscribeToMemberUpdates({
    required List<String> characterIds,
    required void Function() onChanged,
  }) => throw UnimplementedError();
}

GoRouter _buildTestRouter() {
  return GoRouter(
    initialLocation: '/groups/join/step-3?code=AB3F7K2M',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Liste des personnages'))),
      ),
      GoRoute(
        path: '/groups/join/step-2',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Étape 2'))),
      ),
      GoRoute(
        path: '/groups/join/step-3',
        builder: (context, state) => GroupJoinCharacterStepScreen(
          code: state.uri.queryParameters['code']!,
        ),
      ),
      GoRoute(
        path: '/characters/new',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Assistant de création'))),
      ),
      GoRoute(
        path: '/groups/:id',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Text('Écran Groupe ${state.pathParameters['id']}'),
          ),
        ),
      ),
    ],
  );
}

Widget _buildTestWidget({
  required _FakeCharacterRepository characterRepository,
  required _FakeGroupRepository groupRepository,
}) {
  return ProviderScope(
    overrides: [
      characterRepositoryProvider.overrideWithValue(characterRepository),
      groupRepositoryProvider.overrideWithValue(groupRepository),
    ],
    child: MaterialApp.router(routerConfig: _buildTestRouter()),
  );
}

void main() {
  late _FakeCharacterRepository fakeCharacterRepository;
  late _FakeGroupRepository fakeGroupRepository;

  setUp(() {
    fakeCharacterRepository = _FakeCharacterRepository();
    fakeGroupRepository = _FakeGroupRepository();
  });

  testWidgets('affiche les personnages du joueur connecté', (tester) async {
    fakeCharacterRepository.charactersToReturn = const [
      CharacterSummary(id: '1', name: 'Halltesse', level: 5, xp: 7000),
    ];

    await tester.pumpWidget(
      _buildTestWidget(
        characterRepository: fakeCharacterRepository,
        groupRepository: fakeGroupRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Halltesse'), findsOneWidget);
    expect(find.text('Étape 3 / 3'), findsOneWidget);
  });

  testWidgets('état vide : message dédié, le bouton "+ Créer" reste affiché', (
    tester,
  ) async {
    fakeCharacterRepository.charactersToReturn = const [];

    await tester.pumpWidget(
      _buildTestWidget(
        characterRepository: fakeCharacterRepository,
        groupRepository: fakeGroupRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text("Tu n'as pas encore de personnage à rattacher."),
      findsOneWidget,
    );
    expect(find.text('+ CRÉER UN NOUVEAU PERSONNAGE'), findsOneWidget);
  });

  testWidgets(
    'tap sur une carte personnage rattache directement, affiche l\'overlay '
    'pendant l\'appel, puis navigue vers l\'écran "Groupe" avec un SnackBar '
    'de succès',
    (tester) async {
      fakeCharacterRepository.charactersToReturn = const [
        CharacterSummary(id: '42', name: 'Borgan', level: 1, xp: 0),
      ];
      fakeGroupRepository.joinCompleter = Completer<JoinedGroup>();

      await tester.pumpWidget(
        _buildTestWidget(
          characterRepository: fakeCharacterRepository,
          groupRepository: fakeGroupRepository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CharacterCard));
      await tester.pump();

      expect(fakeGroupRepository.joinCallCount, 1);
      expect(fakeGroupRepository.lastJoinedCode, 'AB3F7K2M');
      expect(fakeGroupRepository.lastJoinedCharacterId, '42');
      expect(find.text('Rattachement au groupe...'), findsOneWidget);

      fakeGroupRepository.joinCompleter!.complete(
        const JoinedGroup(groupId: 'group-1', name: 'Les Lames'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Écran Groupe group-1'), findsOneWidget);
      expect(find.text('Groupe rejoint !'), findsOneWidget);
    },
  );

  testWidgets(
    'échec "already_in_group" : referme l\'overlay, reste sur l\'étape, '
    'affiche le bandeau dédié',
    (tester) async {
      fakeCharacterRepository.charactersToReturn = const [
        CharacterSummary(id: '42', name: 'Borgan', level: 1, xp: 0),
      ];
      fakeGroupRepository.joinErrorToThrow = const GroupInviteFailure(
        GroupInviteFailureKind.alreadyInGroup,
      );

      await tester.pumpWidget(
        _buildTestWidget(
          characterRepository: fakeCharacterRepository,
          groupRepository: fakeGroupRepository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CharacterCard));
      await tester.pumpAndSettle();

      expect(
        find.text('Ce personnage est déjà membre de ce groupe.'),
        findsOneWidget,
      );
      expect(find.text('Rattachement au groupe...'), findsNothing);
      expect(find.text('Étape 3 / 3'), findsOneWidget);
    },
  );

  testWidgets('échec "invalid_code" : affiche le bandeau dédié', (
    tester,
  ) async {
    fakeCharacterRepository.charactersToReturn = const [
      CharacterSummary(id: '42', name: 'Borgan', level: 1, xp: 0),
    ];
    fakeGroupRepository.joinErrorToThrow = const GroupInviteFailure(
      GroupInviteFailureKind.invalidCode,
    );

    await tester.pumpWidget(
      _buildTestWidget(
        characterRepository: fakeCharacterRepository,
        groupRepository: fakeGroupRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CharacterCard));
    await tester.pumpAndSettle();

    expect(find.text("Ce code d'invitation n'est pas valide."), findsOneWidget);
  });

  testWidgets('échec générique : affiche le message générique', (tester) async {
    fakeCharacterRepository.charactersToReturn = const [
      CharacterSummary(id: '42', name: 'Borgan', level: 1, xp: 0),
    ];
    fakeGroupRepository.joinErrorToThrow = StateError('boom');

    await tester.pumpWidget(
      _buildTestWidget(
        characterRepository: fakeCharacterRepository,
        groupRepository: fakeGroupRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CharacterCard));
    await tester.pumpAndSettle();

    expect(
      find.text('Impossible de rejoindre ce groupe. Réessayez.'),
      findsOneWidget,
    );
  });

  testWidgets(
    '"+ Créer un nouveau personnage" réinitialise le brouillon, pose la '
    'route de retour vers cette étape et lance l\'assistant de création',
    (tester) async {
      fakeCharacterRepository.charactersToReturn = const [];

      final container = ProviderContainer(
        overrides: [
          characterRepositoryProvider.overrideWithValue(
            fakeCharacterRepository,
          ),
          groupRepositoryProvider.overrideWithValue(fakeGroupRepository),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(characterCreationDraftControllerProvider.notifier)
          .setRace(raceId: 7, subraceId: 3);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: _buildTestRouter()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('+ CRÉER UN NOUVEAU PERSONNAGE'));
      await tester.pumpAndSettle();

      expect(find.text('Assistant de création'), findsOneWidget);
      expect(
        container.read(characterCreationDraftControllerProvider),
        const CharacterCreationDraft(),
      );
      expect(
        container.read(characterCreationReturnRouteControllerProvider),
        '/groups/join/step-3?code=AB3F7K2M',
      );
    },
  );
}
