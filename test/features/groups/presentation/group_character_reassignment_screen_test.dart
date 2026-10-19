// Tests de widget de l'écran "CHOISIR UN NOUVEAU PERSONNAGE" (route
// `/groups/:id/reassign-character`) — rattachement d'un nouveau personnage
// par un membre ORPHELIN (voir `GroupMember.isAwaitingCharacter`), voir la
// doc de classe de `GroupCharacterReassignmentScreen`.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/widgets/destructive_button.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/characters/domain/inventory_catalog_item.dart';
import 'package:personnages/features/characters/domain/level_up_apply_result.dart';
import 'package:personnages/features/characters/domain/level_up_choice_selection.dart';
import 'package:personnages/features/characters/domain/level_up_feat_option.dart';
import 'package:personnages/features/characters/domain/level_up_invocation_option.dart';
import 'package:personnages/features/characters/domain/level_up_elemental_discipline_option.dart';
import 'package:personnages/features/characters/domain/level_up_level_data.dart';
import 'package:personnages/features/characters/domain/rest_type.dart';
import 'package:personnages/features/characters/domain/reward_item_draft.dart';
import 'package:personnages/features/characters/domain/weapon_slot.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/features/groups/data/group_repository.dart';
import 'package:personnages/features/groups/domain/created_group.dart';
import 'package:personnages/features/groups/domain/group_character_reassignment_failure.dart';
import 'package:personnages/features/groups/domain/group_detail.dart';
import 'package:personnages/features/groups/domain/group_note.dart';
import 'package:personnages/features/groups/domain/group_preview.dart';
import 'package:personnages/features/groups/domain/group_summary.dart';
import 'package:personnages/features/groups/domain/group_treasure.dart';
import 'package:personnages/features/groups/domain/group_treasure_item.dart';
import 'package:personnages/features/groups/domain/joined_group.dart';
import 'package:personnages/features/groups/presentation/group_character_reassignment_screen.dart';
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
  Future<WriteOutcome> deleteCharacter({required String characterId}) =>
      throw UnimplementedError();

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
  Future<List<LevelUpElementalDisciplineOption>>
  fetchAvailableElementalDisciplines({
    required String characterId,
    required Object classId,
    required int subclassId,
    required int targetLevel,
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
    List<String> elementalDisciplineNames = const [],
    List<int> racialInnateSpellIds = const [],
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> applyRest({
    required String characterId,
    required RestType type,
    required String className,
    Map<String, int> hitDiceSpentByClassId = const {},
    int appliedGain = 0,
    Map<String, int> hitDiceRecoveredByClassId = const {},
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
  Future<WriteOutcome> equipWeaponToSlot({
    required String characterId,
    required String inventoryId,
    required WeaponSlot slot,
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
  Future<WriteOutcome> setInnateSpellUsesSpent({
    required String characterId,
    required int spellId,
    required int usesSpent,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> useClassFeature({
    required String characterId,
    required int classFeatureId,
    required int usesRemaining,
  }) => throw UnimplementedError();
}

class _FakeGroupRepository implements GroupRepository {
  Object? setGroupCharacterError;
  Completer<void>? setGroupCharacterCompleter;
  String? lastSetGroupId;
  String? lastSetCharacterId;
  int setGroupCharacterCallCount = 0;

  bool leaveGroupCalled = false;
  Object? leaveGroupError;

  @override
  Future<void> setGroupCharacter({
    required String groupId,
    required String characterId,
  }) async {
    setGroupCharacterCallCount++;
    lastSetGroupId = groupId;
    lastSetCharacterId = characterId;
    if (setGroupCharacterCompleter != null) {
      return setGroupCharacterCompleter!.future;
    }
    if (setGroupCharacterError != null) throw setGroupCharacterError!;
  }

  @override
  Future<void> leaveGroup(String groupId) async {
    leaveGroupCalled = true;
    if (leaveGroupError != null) throw leaveGroupError!;
  }

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
  Future<void> removeMember({
    required String groupId,
    required String userId,
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

  @override
  Future<GroupNote> fetchGroupNote({
    required String groupId,
    required String characterId,
  }) => throw UnimplementedError();

  @override
  Future<void> saveGroupNote({
    required String groupId,
    required String characterId,
    required String body,
  }) => throw UnimplementedError();
}

GoRouter _buildTestRouter() {
  return GoRouter(
    initialLocation: '/groups/group-1/reassign-character',
    routes: [
      GoRoute(
        path: '/groups',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Écran Groupes'))),
      ),
      GoRoute(
        path: '/groups/:id/reassign-character',
        builder: (context, state) => GroupCharacterReassignmentScreen(
          groupId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/groups/:id',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Text('Écran Groupe ${state.pathParameters['id']}'),
          ),
        ),
      ),
      GoRoute(
        path: '/characters/new',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text("Assistant de création"))),
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

const _sylvi = CharacterSummary(
  id: 'char-sylvi',
  name: 'Sylvi',
  level: 3,
  xp: 900,
);
const _bob = CharacterSummary(id: 'char-bob', name: 'Bob', level: 1, xp: 0);

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

    expect(find.text('CHOISIR UN NOUVEAU PERSONNAGE'), findsOneWidget);
    expect(
      find.textContaining('Ton précédent personnage a été supprimé'),
      findsOneWidget,
    );
  });

  testWidgets(
    '"Confirmer" désactivé tant qu\'aucun personnage n\'est sélectionné, '
    'puis activé après sélection',
    (tester) async {
      fakeCharacterRepository.charactersToReturn = const [_sylvi, _bob];

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      PrimaryButton confirmButton() =>
          tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(confirmButton().onPressed, isNull);

      await tester.tap(find.text('Sylvi'));
      await tester.pumpAndSettle();

      expect(confirmButton().onPressed, isNotNull);
    },
  );

  testWidgets(
    'confirmer appelle setGroupCharacter puis navigue vers l\'écran Groupe',
    (tester) async {
      fakeCharacterRepository.charactersToReturn = const [_sylvi, _bob];

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bob'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONFIRMER'));
      await tester.pumpAndSettle();

      expect(fakeGroupRepository.setGroupCharacterCallCount, 1);
      expect(fakeGroupRepository.lastSetGroupId, 'group-1');
      expect(fakeGroupRepository.lastSetCharacterId, 'char-bob');
      expect(find.text('Écran Groupe group-1'), findsOneWidget);
    },
  );

  testWidgets('overlay de sauvegarde affiché pendant l\'appel réseau', (
    tester,
  ) async {
    fakeCharacterRepository.charactersToReturn = const [_sylvi];
    final completer = Completer<void>();
    fakeGroupRepository.setGroupCharacterCompleter = completer;

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sylvi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONFIRMER'));
    await tester.pump();

    expect(find.text('Mise à jour du groupe...'), findsOneWidget);

    completer.complete();
    await tester.pumpAndSettle();
  });

  group('erreurs de setGroupCharacter', () {
    testWidgets('character_not_owned -> bandeau dédié', (tester) async {
      fakeCharacterRepository.charactersToReturn = const [_sylvi];
      fakeGroupRepository.setGroupCharacterError =
          const GroupCharacterReassignmentFailure(
            GroupCharacterReassignmentFailureKind.characterNotOwned,
          );

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sylvi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONFIRMER'));
      await tester.pumpAndSettle();

      expect(find.textContaining("ne t'appartient pas"), findsOneWidget);
      // Reste sur l'écran, n'a pas navigué.
      expect(find.text('CHOISIR UN NOUVEAU PERSONNAGE'), findsOneWidget);
    });

    testWidgets('already_in_group -> bandeau dédié', (tester) async {
      fakeCharacterRepository.charactersToReturn = const [_sylvi];
      fakeGroupRepository.setGroupCharacterError =
          const GroupCharacterReassignmentFailure(
            GroupCharacterReassignmentFailureKind.alreadyInGroup,
          );

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sylvi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONFIRMER'));
      await tester.pumpAndSettle();

      expect(find.textContaining('déjà membre de ce groupe'), findsOneWidget);
    });

    testWidgets(
      'erreur générique (exception inattendue) -> message générique',
      (tester) async {
        fakeCharacterRepository.charactersToReturn = const [_sylvi];
        fakeGroupRepository.setGroupCharacterError = Exception('boom');

        await tester.pumpWidget(buildWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Sylvi'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONFIRMER'));
        await tester.pumpAndSettle();

        expect(
          find.text('Impossible de mettre à jour le groupe. Réessayez.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('not_member -> bandeau dédié', (tester) async {
      fakeCharacterRepository.charactersToReturn = const [_sylvi];
      fakeGroupRepository.setGroupCharacterError =
          const GroupCharacterReassignmentFailure(
            GroupCharacterReassignmentFailureKind.notMember,
          );

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sylvi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONFIRMER'));
      await tester.pumpAndSettle();

      expect(find.textContaining("Tu n'es plus membre"), findsOneWidget);
    });

    testWidgets('not_eligible -> bandeau dédié', (tester) async {
      fakeCharacterRepository.charactersToReturn = const [_sylvi];
      fakeGroupRepository.setGroupCharacterError =
          const GroupCharacterReassignmentFailure(
            GroupCharacterReassignmentFailureKind.notEligible,
          );

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sylvi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONFIRMER'));
      await tester.pumpAndSettle();

      expect(find.text('Cette action ne te concerne plus.'), findsOneWidget);
    });
  });

  group('état vide (aucun personnage)', () {
    testWidgets(
      'affiche la note dédiée et les deux actions "Créer un personnage"/'
      '"Quitter le groupe"',
      (tester) async {
        fakeCharacterRepository.charactersToReturn = const [];

        await tester.pumpWidget(buildWidget());
        await tester.pumpAndSettle();

        expect(
          find.text("Tu n'as pas encore de personnage à rattacher."),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(SecondaryButton, 'CRÉER UN PERSONNAGE'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(DestructiveButton, 'Quitter le groupe'),
          findsOneWidget,
        );
      },
    );

    testWidgets('"Créer un personnage" pousse l\'assistant de création', (
      tester,
    ) async {
      fakeCharacterRepository.charactersToReturn = const [];

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('CRÉER UN PERSONNAGE'));
      await tester.pumpAndSettle();

      expect(find.text('Assistant de création'), findsOneWidget);
    });

    testWidgets(
      'retour depuis l\'assistant de création rafraîchit charactersProvider '
      '-- le personnage tout juste créé apparaît sans action supplémentaire',
      (tester) async {
        fakeCharacterRepository.charactersToReturn = const [];

        await tester.pumpWidget(buildWidget());
        await tester.pumpAndSettle();

        expect(find.text('Sylvi'), findsNothing);

        await tester.tap(find.text('CRÉER UN PERSONNAGE'));
        await tester.pumpAndSettle();
        expect(find.text('Assistant de création'), findsOneWidget);

        // Simule le retour de l'assistant (pousse via context.push) avec un
        // nouveau personnage deja cree cote depot -- le stub de route n'a
        // pas d'AppBar/back button, on ferme donc directement via le
        // Navigator plutot que tester.pageBack().
        fakeCharacterRepository.charactersToReturn = const [_sylvi];
        Navigator.of(tester.element(find.text('Assistant de création'))).pop();
        await tester.pumpAndSettle();

        expect(find.text('CHOISIR UN NOUVEAU PERSONNAGE'), findsOneWidget);
        expect(find.text('Sylvi'), findsOneWidget);
      },
    );

    testWidgets('"Quitter le groupe" : confirmation puis leaveGroup', (
      tester,
    ) async {
      fakeCharacterRepository.charactersToReturn = const [];

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Quitter le groupe'));
      await tester.pumpAndSettle();

      // Dialogue de confirmation.
      expect(find.text('Quitter ce groupe ?'), findsOneWidget);
      await tester.tap(find.widgetWithText(DestructiveButton, 'Quitter'));
      await tester.pumpAndSettle();

      expect(fakeGroupRepository.leaveGroupCalled, isTrue);
      expect(find.text('Écran Groupes'), findsOneWidget);
    });
  });

  group('état d\'erreur de charactersProvider', () {
    testWidgets('affiche un message avec un bouton Réessayer', (tester) async {
      fakeCharacterRepository.charactersErrorToThrow = const CharacterFailure(
        'Erreur réseau.',
      );

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Erreur réseau.'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
    });
  });
}
