// Tests de widget de l'écran "Créer un groupe" (route /groups/new) — voir
// `docs/cahier-des-charges/12-partage-et-groupes.md` section 2.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/widgets/primary_button.dart';
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
import 'package:personnages/features/groups/data/group_repository.dart';
import 'package:personnages/features/groups/domain/created_group.dart';
import 'package:personnages/features/groups/domain/group_detail.dart';
import 'package:personnages/features/groups/domain/group_failure.dart';
import 'package:personnages/features/groups/domain/group_preview.dart';
import 'package:personnages/features/groups/domain/group_summary.dart';
import 'package:personnages/features/groups/domain/group_treasure.dart';
import 'package:personnages/features/groups/domain/group_treasure_item.dart';
import 'package:personnages/features/groups/domain/joined_group.dart';
import 'package:personnages/features/groups/presentation/group_create_screen.dart';
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
  Future<void> addGalleryPhoto({
    required String characterId,
    required Uint8List bytes,
  }) => throw UnimplementedError();

  @override
  Future<void> removeGalleryPhoto({
    required String characterId,
    required String photoId,
    required String url,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> addJournalEntry({
    required String characterId,
    required String body,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> updateJournalEntry({
    required String characterId,
    required String entryId,
    required String body,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> removeJournalEntry({
    required String characterId,
    required String entryId,
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
  Object? createErrorToThrow;
  Completer<CreatedGroup>? createCompleter;
  String? lastCreatedName;
  String? lastCreatedCharacterId;

  @override
  Future<CreatedGroup> createGroup({
    required String name,
    required String characterId,
  }) async {
    lastCreatedName = name;
    lastCreatedCharacterId = characterId;
    if (createCompleter != null) return createCompleter!.future;
    if (createErrorToThrow != null) throw createErrorToThrow!;
    return const CreatedGroup(
      id: 'group-1',
      name: 'Les Lames',
      inviteCode: 'AB3F7K2M',
    );
  }

  @override
  Future<List<GroupSummary>> fetchMyGroups() => throw UnimplementedError();

  @override
  Future<GroupPreview> previewGroupInvite(String code) =>
      throw UnimplementedError();

  @override
  Future<JoinedGroup> joinGroup({
    required String code,
    required String characterId,
  }) => throw UnimplementedError();

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
    initialLocation: '/groups/new',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Liste des personnages'))),
      ),
      GoRoute(
        path: '/groups/new',
        builder: (context, state) => const GroupCreateScreen(),
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

bool _isPrimaryButtonEnabled(WidgetTester tester, String label) {
  final button = tester.widget<PrimaryButton>(
    find.widgetWithText(PrimaryButton, label.toUpperCase()),
  );
  return button.onPressed != null;
}

void main() {
  late _FakeCharacterRepository fakeCharacterRepository;
  late _FakeGroupRepository fakeGroupRepository;

  setUp(() {
    fakeCharacterRepository = _FakeCharacterRepository();
    fakeGroupRepository = _FakeGroupRepository();
  });

  testWidgets('affiche le titre et les personnages du joueur', (tester) async {
    fakeCharacterRepository.charactersToReturn = const [
      CharacterSummary(id: '1', name: 'Sylvi', level: 3, xp: 900),
    ];

    await tester.pumpWidget(
      _buildTestWidget(
        characterRepository: fakeCharacterRepository,
        groupRepository: fakeGroupRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CRÉER UN GROUPE'), findsOneWidget);
    expect(find.text('Sylvi'), findsOneWidget);
  });

  testWidgets('"Créer le groupe" désactivé tant que le nom est vide ou aucun '
      'personnage sélectionné', (tester) async {
    fakeCharacterRepository.charactersToReturn = const [
      CharacterSummary(id: '1', name: 'Sylvi', level: 3, xp: 900),
    ];

    await tester.pumpWidget(
      _buildTestWidget(
        characterRepository: fakeCharacterRepository,
        groupRepository: fakeGroupRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(_isPrimaryButtonEnabled(tester, 'Créer le groupe'), isFalse);

    await tester.enterText(find.byType(TextFormField), 'Les Lames');
    await tester.pump();
    expect(_isPrimaryButtonEnabled(tester, 'Créer le groupe'), isFalse);

    await tester.tap(find.text('Sylvi'), warnIfMissed: false);
    await tester.pump();
    expect(_isPrimaryButtonEnabled(tester, 'Créer le groupe'), isTrue);
  });

  testWidgets(
    'sélection exclusive : sélectionner un 2e personnage désélectionne '
    'le premier',
    (tester) async {
      fakeCharacterRepository.charactersToReturn = const [
        CharacterSummary(id: '1', name: 'Sylvi', level: 3, xp: 900),
        CharacterSummary(id: '2', name: 'Borgan', level: 1, xp: 0),
      ];

      await tester.pumpWidget(
        _buildTestWidget(
          characterRepository: fakeCharacterRepository,
          groupRepository: fakeGroupRepository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'Les Lames');
      await tester.tap(find.text('Sylvi'), warnIfMissed: false);
      await tester.pump();
      await tester.tap(find.text('Borgan'), warnIfMissed: false);
      await tester.pump();

      fakeGroupRepository.createCompleter = Completer<CreatedGroup>();
      await tester.tap(find.text('CRÉER LE GROUPE'));
      await tester.pump();

      expect(fakeGroupRepository.lastCreatedCharacterId, '2');
    },
  );

  testWidgets(
    'soumission : appelle create-group, affiche l\'overlay, puis navigue '
    'vers /groups/:id avec un SnackBar de succès',
    (tester) async {
      fakeCharacterRepository.charactersToReturn = const [
        CharacterSummary(id: '1', name: 'Sylvi', level: 3, xp: 900),
      ];
      fakeGroupRepository.createCompleter = Completer<CreatedGroup>();

      await tester.pumpWidget(
        _buildTestWidget(
          characterRepository: fakeCharacterRepository,
          groupRepository: fakeGroupRepository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'Les Lames');
      await tester.tap(find.text('Sylvi'), warnIfMissed: false);
      await tester.pump();
      await tester.tap(find.text('CRÉER LE GROUPE'));
      await tester.pump();

      expect(fakeGroupRepository.lastCreatedName, 'Les Lames');
      expect(fakeGroupRepository.lastCreatedCharacterId, '1');
      expect(find.text('Création du groupe...'), findsOneWidget);

      fakeGroupRepository.createCompleter!.complete(
        const CreatedGroup(
          id: 'group-1',
          name: 'Les Lames',
          inviteCode: 'AB3F7K2M',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Écran Groupe group-1'), findsOneWidget);
      expect(find.text('Groupe créé !'), findsOneWidget);
    },
  );

  testWidgets(
    'échec réseau : affiche un bandeau d\'erreur, reste sur l\'écran',
    (tester) async {
      fakeCharacterRepository.charactersToReturn = const [
        CharacterSummary(id: '1', name: 'Sylvi', level: 3, xp: 900),
      ];
      fakeGroupRepository.createErrorToThrow = const GroupFailure(
        'Erreur serveur.',
      );

      await tester.pumpWidget(
        _buildTestWidget(
          characterRepository: fakeCharacterRepository,
          groupRepository: fakeGroupRepository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'Les Lames');
      await tester.tap(find.text('Sylvi'), warnIfMissed: false);
      await tester.pump();
      await tester.tap(find.text('CRÉER LE GROUPE'));
      await tester.pumpAndSettle();

      expect(find.text('Erreur serveur.'), findsOneWidget);
      expect(find.text('CRÉER UN GROUPE'), findsOneWidget);
    },
  );

  testWidgets('état vide (aucun personnage) : message dédié', (tester) async {
    fakeCharacterRepository.charactersToReturn = const [];

    await tester.pumpWidget(
      _buildTestWidget(
        characterRepository: fakeCharacterRepository,
        groupRepository: fakeGroupRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining("Tu n'as pas encore de personnage"),
      findsOneWidget,
    );
  });
}
