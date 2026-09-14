// Tests de widget de l'écran unique "REJOINDRE UN GROUPE" (route
// `/groups/join`) — recettage direction-artistique du 13/09/2026, voir la
// doc de classe de `GroupJoinScreen`. Remplace les 3 anciens fichiers de test
// à étapes (`group_join_code_step_screen_test.dart`,
// `group_join_confirmation_step_screen_test.dart`,
// `group_join_character_step_screen_test.dart`, retirés par cette tâche).

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
import 'package:personnages/features/characters/domain/level_up_choice_selection.dart';
import 'package:personnages/features/characters/domain/level_up_feat_option.dart';
import 'package:personnages/features/characters/domain/level_up_invocation_option.dart';
import 'package:personnages/features/characters/domain/level_up_level_data.dart';
import 'package:personnages/features/characters/domain/rest_type.dart';
import 'package:personnages/features/characters/domain/reward_item_draft.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/features/groups/data/group_repository.dart';
import 'package:personnages/features/groups/domain/created_group.dart';
import 'package:personnages/features/groups/domain/group_detail.dart';
import 'package:personnages/features/groups/domain/group_invite_failure.dart';
import 'package:personnages/features/groups/domain/group_preview.dart';
import 'package:personnages/features/groups/domain/group_summary.dart';
import 'package:personnages/features/groups/domain/group_treasure.dart';
import 'package:personnages/features/groups/domain/group_treasure_item.dart';
import 'package:personnages/features/groups/domain/joined_group.dart';
import 'package:personnages/features/groups/presentation/group_join_screen.dart';
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
  GroupPreview? previewToReturn;
  Object? previewErrorToThrow;
  int previewCallCount = 0;

  Object? joinErrorToThrow;
  Completer<JoinedGroup>? joinCompleter;
  String? lastJoinedCode;
  String? lastJoinedCharacterId;
  int joinCallCount = 0;

  @override
  Future<GroupPreview> previewGroupInvite(String code) async {
    previewCallCount++;
    if (previewErrorToThrow != null) throw previewErrorToThrow!;
    return previewToReturn ??
        const GroupPreview(name: 'Groupe test', memberCount: 1);
  }

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
    initialLocation: '/groups/join',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Liste des personnages'))),
      ),
      GoRoute(
        path: '/groups/join',
        builder: (context, state) =>
            GroupJoinScreen(initialCode: state.uri.queryParameters['code']),
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

bool _isPrimaryButtonEnabled(WidgetTester tester) {
  final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
  return button.onPressed != null;
}

void main() {
  late _FakeCharacterRepository fakeCharacterRepository;
  late _FakeGroupRepository fakeGroupRepository;

  setUp(() {
    fakeCharacterRepository = _FakeCharacterRepository();
    fakeGroupRepository = _FakeGroupRepository();
  });

  Widget buildWidget() => _buildTestWidget(
    characterRepository: fakeCharacterRepository,
    groupRepository: fakeGroupRepository,
  );

  testWidgets('affiche le titre et le texte d\'intro', (tester) async {
    fakeCharacterRepository.charactersToReturn = const [];

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('REJOINDRE UN GROUPE'), findsOneWidget);
    expect(find.textContaining("Demande le code d'invitation"), findsOneWidget);
  });

  testWidgets(
    '"Rejoindre" désactivé tant que le code fait moins de 6 caractères ou '
    "qu'aucun personnage n'est sélectionné",
    (tester) async {
      fakeCharacterRepository.charactersToReturn = const [];

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(_isPrimaryButtonEnabled(tester), isFalse);

      await tester.enterText(find.byType(TextField), 'AB3F');
      await tester.pump();

      expect(
        _isPrimaryButtonEnabled(tester),
        isFalse,
        reason: 'code trop court ET aucun personnage disponible',
      );
    },
  );

  testWidgets('"Rejoindre" devient actif à partir de 6 caractères une fois un '
      'personnage sélectionné (auto-sélection du premier personnage)', (
    tester,
  ) async {
    fakeCharacterRepository.charactersToReturn = const [
      CharacterSummary(id: '1', name: 'Halltesse', level: 5, xp: 7000),
    ];

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('Halltesse'), findsOneWidget);
    expect(_isPrimaryButtonEnabled(tester), isFalse);

    await tester.enterText(find.byType(TextField), 'ab3f7k');
    await tester.pump();

    expect(_isPrimaryButtonEnabled(tester), isTrue);
  });

  testWidgets('le champ code se formate en majuscules avec un tiret', (
    tester,
  ) async {
    fakeCharacterRepository.charactersToReturn = const [];

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    // Volontairement différent du hint "AB3F - 7K2M" du champ (voir
    // `_CodeField`) : sinon le `Text` du hint (toujours monté, même masqué
    // une fois le champ rempli) crée un second match pour `find.text`.
    await tester.enterText(find.byType(TextField), 'cd9912xy');
    await tester.pump();

    expect(find.text('CD99 - 12XY'), findsOneWidget);
  });

  testWidgets('le champ code est pré-rempli et formaté via initialCode', (
    tester,
  ) async {
    fakeCharacterRepository.charactersToReturn = const [];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          characterRepositoryProvider.overrideWithValue(
            fakeCharacterRepository,
          ),
          groupRepositoryProvider.overrideWithValue(fakeGroupRepository),
        ],
        child: const MaterialApp(
          home: Scaffold(body: GroupJoinScreen(initialCode: 'ZZ9988XX')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ZZ99 - 88XX'), findsOneWidget);
  });

  testWidgets('état vide : message dédié dans la tuile personnage', (
    tester,
  ) async {
    fakeCharacterRepository.charactersToReturn = const [];

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(
      find.text("Tu n'as pas encore de personnage à rattacher."),
      findsOneWidget,
    );
  });

  testWidgets('tap sur la tuile personnage ouvre "CHOISIR UN PERSONNAGE", la '
      'sélection met à jour la tuile', (tester) async {
    fakeCharacterRepository.charactersToReturn = const [
      CharacterSummary(id: '1', name: 'Halltesse', level: 5, xp: 7000),
      CharacterSummary(id: '2', name: 'Borgan', level: 3, xp: 900),
    ];

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    // Halltesse est auto-sélectionnée (premier personnage de la liste).
    expect(find.text('Halltesse'), findsOneWidget);

    await tester.tap(find.text('Halltesse'));
    await tester.pumpAndSettle();

    expect(find.text('CHOISIR UN PERSONNAGE'), findsOneWidget);
    expect(find.text('Borgan'), findsOneWidget);

    await tester.tap(find.text('Borgan'));
    await tester.pumpAndSettle();

    expect(find.text('CHOISIR UN PERSONNAGE'), findsNothing);
    expect(find.text('Borgan'), findsOneWidget);
  });

  testWidgets(
    'code invalide (aperçu) : texte d\'aide discret sous le champ, jamais '
    'de bandeau encadré',
    (tester) async {
      fakeCharacterRepository.charactersToReturn = const [
        CharacterSummary(id: '1', name: 'Halltesse', level: 5, xp: 7000),
      ];
      fakeGroupRepository.previewErrorToThrow = const GroupInviteFailure(
        GroupInviteFailureKind.invalidCode,
      );

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'ab3f7k');
      await tester.pump();
      await tester.tap(find.text('REJOINDRE'));
      await tester.pumpAndSettle();

      expect(
        find.text("Ce code d'invitation n'est pas valide."),
        findsOneWidget,
      );
      expect(fakeGroupRepository.joinCallCount, 0);
    },
  );

  testWidgets(
    'erreur générique à l\'aperçu : bandeau encadré en tête d\'écran',
    (tester) async {
      fakeCharacterRepository.charactersToReturn = const [
        CharacterSummary(id: '1', name: 'Halltesse', level: 5, xp: 7000),
      ];
      fakeGroupRepository.previewErrorToThrow = const GroupInviteFailure(
        GroupInviteFailureKind.generic,
      );

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'ab3f7k');
      await tester.pump();
      await tester.tap(find.text('REJOINDRE'));
      await tester.pumpAndSettle();

      expect(
        find.text('Impossible de rejoindre ce groupe. Réessayez.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'succès : aperçu puis rattachement, navigation vers l\'écran "Groupe" '
    'avec un SnackBar',
    (tester) async {
      fakeCharacterRepository.charactersToReturn = const [
        CharacterSummary(id: '42', name: 'Borgan', level: 1, xp: 0),
      ];
      fakeGroupRepository.joinCompleter = Completer<JoinedGroup>();

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'ab3f7k');
      await tester.pump();
      await tester.tap(find.text('REJOINDRE'));
      await tester.pump();

      expect(find.text('Rattachement au groupe...'), findsOneWidget);

      fakeGroupRepository.joinCompleter!.complete(
        const JoinedGroup(groupId: 'group-1', name: 'Les Lames'),
      );
      await tester.pumpAndSettle();

      expect(fakeGroupRepository.lastJoinedCode, 'AB3F7K');
      expect(fakeGroupRepository.lastJoinedCharacterId, '42');
      expect(find.text('Écran Groupe group-1'), findsOneWidget);
      expect(find.text('Groupe rejoint !'), findsOneWidget);
    },
  );

  testWidgets(
    'échec "already_in_group" au rattachement : bandeau encadré dédié',
    (tester) async {
      fakeCharacterRepository.charactersToReturn = const [
        CharacterSummary(id: '42', name: 'Borgan', level: 1, xp: 0),
      ];
      fakeGroupRepository.joinErrorToThrow = const GroupInviteFailure(
        GroupInviteFailureKind.alreadyInGroup,
      );

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'ab3f7k');
      await tester.pump();
      await tester.tap(find.text('REJOINDRE'));
      await tester.pumpAndSettle();

      expect(
        find.text('Ce personnage est déjà membre de ce groupe.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'le retour arrière ramène à la liste des personnages quand il n\'y a '
    'rien à dépiler',
    (tester) async {
      fakeCharacterRepository.charactersToReturn = const [];

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();

      expect(find.text('Liste des personnages'), findsOneWidget);
    },
  );
}
