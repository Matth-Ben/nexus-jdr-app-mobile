// Tests de widget de l'écran unique "REJOINDRE UN GROUPE" (route
// `/groups/join`) — recettage direction-artistique du 13/09/2026, voir la
// doc de classe de `GroupJoinScreen`. Remplace les 3 anciens fichiers de test
// à étapes (`group_join_code_step_screen_test.dart`,
// `group_join_confirmation_step_screen_test.dart`,
// `group_join_character_step_screen_test.dart`, retirés par cette tâche).

import 'dart:async';
import 'dart:typed_data';

import 'package:personnages/features/combat/presentation/providers/character_combat_provider.dart';
import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../support/fake_current_user.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/characters/domain/custom_item_enrichment.dart';
import 'package:personnages/features/characters/domain/inventory_catalog_item.dart';
import 'package:personnages/features/characters/domain/level_up_apply_result.dart';
import 'package:personnages/features/characters/domain/level_up_choice_selection.dart';
import 'package:personnages/features/characters/domain/level_up_feat_option.dart';
import 'package:personnages/features/characters/domain/level_up_invocation_option.dart';
import 'package:personnages/features/characters/domain/level_up_elemental_discipline_option.dart';
import 'package:personnages/features/characters/domain/level_up_maneuver_option.dart';
import 'package:personnages/features/characters/domain/level_up_arcane_shot_option.dart';
import 'package:personnages/features/characters/domain/level_up_infusion_option.dart';
import 'package:personnages/features/characters/domain/level_up_infusion_swap.dart';
import 'package:personnages/features/characters/domain/level_up_metamagic_option.dart';
import 'package:personnages/features/characters/domain/level_up_metamagic_swap.dart';
import 'package:personnages/features/characters/domain/level_up_draconic_ancestry_option.dart';
import 'package:personnages/features/characters/domain/level_up_rune_option.dart';
import 'package:personnages/features/characters/domain/level_up_level_data.dart';
import 'package:personnages/features/characters/domain/rest_type.dart';
import 'package:personnages/features/characters/domain/reward_item_draft.dart';
import 'package:personnages/features/characters/domain/weapon_slot.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/features/groups/data/group_repository.dart';
import 'package:personnages/features/groups/domain/created_group.dart';
import 'package:personnages/features/groups/domain/group_detail.dart';
import 'package:personnages/features/groups/domain/group_invite_failure.dart';
import 'package:personnages/features/groups/domain/group_note_entry.dart';
import 'package:personnages/features/groups/domain/group_preview.dart';
import 'package:personnages/features/groups/domain/group_summary.dart';
import 'package:personnages/features/groups/domain/group_treasure.dart';
import 'package:personnages/features/groups/domain/group_treasure_item.dart';
import 'package:personnages/features/groups/domain/joined_group.dart';
import 'package:personnages/features/groups/presentation/group_join_screen.dart';
import 'package:personnages/features/groups/presentation/providers/group_providers.dart';
import 'package:personnages/l10n/app_localizations.dart';

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
  Future<WriteOutcome> setArmorClassBonus({
    required String characterId,
    required int bonus,
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
  Future<List<LevelUpManeuverOption>> fetchAvailableManeuvers({
    required String characterId,
    required Object classId,
    required int subclassId,
    required int targetLevel,
  }) async => throw UnimplementedError();

  @override
  Future<List<LevelUpArcaneShotOption>> fetchAvailableArcaneShots({
    required String characterId,
    required Object classId,
    required int subclassId,
    required int targetLevel,
  }) async => throw UnimplementedError();

  @override
  Future<List<LevelUpRuneOption>> fetchAvailableRunes({
    required String characterId,
    required Object classId,
    required int subclassId,
    required int targetLevel,
  }) async => throw UnimplementedError();

  @override
  Future<List<LevelUpInfusionOption>> fetchAvailableInfusions({
    required String characterId,
    required Object classId,
    required int targetLevel,
  }) async => throw UnimplementedError();

  @override
  Future<List<String>> fetchKnownInfusionNames({
    required String characterId,
  }) async => throw UnimplementedError();

  @override
  Future<List<LevelUpMetamagicOption>> fetchAvailableMetamagicOptions({
    required String characterId,
    required Object classId,
    required int targetLevel,
  }) async => throw UnimplementedError();

  @override
  Future<List<String>> fetchKnownMetamagicNames({
    required String characterId,
    required Object classId,
  }) async => throw UnimplementedError();

  @override
  Future<List<LevelUpDraconicAncestryOption>>
  fetchAvailableDraconicAncestryOptions({required Object subclassId}) async =>
      throw UnimplementedError();

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
    List<String> maneuverNames = const [],
    List<String> arcaneShotNames = const [],
    List<String> runeNames = const [],
    List<String> infusionNames = const [],
    LevelUpInfusionSwap? infusionSwap,
    List<String> metamagicNames = const [],
    LevelUpMetamagicSwap? metamagicSwap,
    List<int> expertiseSkillIds = const [],
    bool expertiseThievesToolsSubstitution = false,
    String? draconicAncestryDamageType,
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
    String? description,
    String? damageDice,
    String? damageType,
    List<String> properties = const [],
    CustomItemEnrichment? enrichment,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> updateCustomInventoryItem({
    required String characterId,
    required String inventoryId,
    required String customName,
    required CustomItemEnrichment enrichment,
    String? description,
    String? damageDice,
    String? damageType,
    List<String> properties = const [],
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
  int idsCalls = 0;

  @override
  Future<List<String>> fetchGroupIdsForCharacter(String characterId) async {
    idsCalls++;
    return const [];
  }

  GroupPreview? previewToReturn;
  Object? previewErrorToThrow;
  Completer<GroupPreview>? previewCompleter;
  int previewCallCount = 0;
  final List<String> previewedCodes = [];

  Object? joinErrorToThrow;
  Completer<JoinedGroup>? joinCompleter;
  String? lastJoinedCode;
  String? lastJoinedCharacterId;
  int joinCallCount = 0;

  @override
  Future<GroupPreview> previewGroupInvite(String code) async {
    previewCallCount++;
    previewedCodes.add(code);
    if (previewCompleter != null) return previewCompleter!.future;
    if (previewErrorToThrow != null) throw previewErrorToThrow!;
    return previewToReturn ??
        const GroupPreview(name: 'Groupe test', memberCount: 1);
  }

  @override
  Future<JoinedGroup> joinGroup({
    required String code,
    String? characterId,
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
    String? characterId,
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
  Future<void> becomeGroupGameMaster(String groupId) =>
      throw UnimplementedError();

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
  Future<void> addTreasureItems({
    required String groupId,
    required List<GroupTreasureItem> items,
  }) => throw UnimplementedError();

  @override
  Future<void> updateTreasureItem({
    required String groupId,
    required GroupTreasureItem expected,
    required GroupTreasureItem updated,
  }) => throw UnimplementedError();

  @override
  Future<void> removeTreasureItem({
    required String groupId,
    required GroupTreasureItem expected,
  }) => throw UnimplementedError();

  @override
  Future<void> setTreasureCurrency({
    required String groupId,
    required Map<CurrencyKind, int> expected,
    required Map<CurrencyKind, int> newTotals,
  }) => throw UnimplementedError();

  @override
  Future<CharacterInventoryItem> fetchTreasureItemDetails(
    GroupTreasureItem item,
  ) => throw UnimplementedError();

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
    required String groupId,
    required List<String> characterIds,
    required bool Function(String membershipId) isKnownMembershipId,
    required void Function() onChanged,
  }) => throw UnimplementedError();

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
}

GoRouter _buildTestRouter({String initialLocation = '/groups/join'}) {
  return GoRouter(
    initialLocation: initialLocation,
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
  Locale locale = const Locale('fr'),
  String initialLocation = '/groups/join',
}) {
  return ProviderScope(
    overrides: [
      characterRepositoryProvider.overrideWithValue(characterRepository),
      groupRepositoryProvider.overrideWithValue(groupRepository),
      currentUserFromTestOverride,
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      routerConfig: _buildTestRouter(initialLocation: initialLocation),
    ),
  );
}

bool _isPrimaryButtonEnabled(WidgetTester tester) {
  final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
  return button.onPressed != null;
}

Finder _previewCard() => find.byKey(const ValueKey('groupInvitePreviewCard'));

/// « Rejoindre » est ignoré pendant [kDoubleTapTimeout] après l'apparition
/// de la carte (garde anti double toucher) : attend ce délai, puis touche.
Future<void> _tapJoin(WidgetTester tester) async {
  await tester.pump(kDoubleTapTimeout);
  await tester.tap(find.text('REJOINDRE'));
}

Finder _previewLoading() =>
    find.byKey(const ValueKey('groupInvitePreviewLoading'));

bool _isPrimaryButtonLoading(WidgetTester tester) =>
    tester.widget<PrimaryButton>(find.byType(PrimaryButton)).isLoading;

/// Décision n° 34 : « Rejoindre » ne rattache qu'à un groupe dont l'aperçu
/// est affiché. Un code de 6 caractères n'est pas prévisualisé d'office :
/// « Voir le groupe » affiche l'aperçu, puis « Rejoindre » confirme.
Future<void> _showPreview(WidgetTester tester) async {
  await tester.tap(find.text('VOIR LE GROUPE'));
  await tester.pumpAndSettle();
  expect(_previewCard(), findsOneWidget);
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

  testWidgets('rejoindre un groupe invalide le cache des groupes d\'un '
      'personnage (le bandeau de combat apparaît sans attendre)', (
    tester,
  ) async {
    fakeCharacterRepository.charactersToReturn = const [
      CharacterSummary(id: '42', name: 'Borgan', level: 1, xp: 0),
    ];
    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    container.listen(characterGroupIdsProvider('42'), (_, _) {});
    await tester.pumpAndSettle();
    expect(fakeGroupRepository.idsCalls, 1);

    await tester.tap(find.text('Borgan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('MJ — sans personnage'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ab3f7k');
    await tester.pump();
    await _showPreview(tester);
    await _tapJoin(tester);
    await tester.pumpAndSettle();

    expect(find.text('Écran Groupe group-1'), findsOneWidget);
    expect(fakeGroupRepository.idsCalls, 2);
  });

  testWidgets('affiche le titre et le texte d\'intro', (tester) async {
    fakeCharacterRepository.charactersToReturn = const [];

    await tester.pumpWidget(buildWidget());
    await tester.pumpAndSettle();

    expect(find.text('REJOINDRE UN GROUPE'), findsOneWidget);
    expect(find.textContaining("Demande le code d'invitation"), findsOneWidget);
  });

  testWidgets(
    'affiche le sous-texte signalant l\'option "MJ — sans personnage" '
    '(correctif F01)',
    (tester) async {
      fakeCharacterRepository.charactersToReturn = const [];

      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('Qui te représente dans ce groupe ?'), findsOneWidget);
      expect(
        find.text(
          'Choisis ton personnage, ou sélectionne '
          '« MJ — sans personnage » si tu animes la partie sans fiche.',
        ),
        findsOneWidget,
      );
    },
  );

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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
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

  testWidgets('tap sur la tuile personnage ouvre "CHOISIR TON RÔLE", la '
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

    expect(find.text('CHOISIR TON RÔLE'), findsOneWidget);
    expect(find.text('Borgan'), findsOneWidget);

    await tester.tap(find.text('Borgan'));
    await tester.pumpAndSettle();

    expect(find.text('CHOISIR TON RÔLE'), findsNothing);
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
      await tester.tap(find.text('VOIR LE GROUPE'));
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
      await tester.tap(find.text('VOIR LE GROUPE'));
      await tester.pumpAndSettle();

      expect(
        find.text('Impossible de rejoindre ce groupe. Réessaie.'),
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
      await _showPreview(tester);
      await _tapJoin(tester);
      await tester.pump();

      expect(find.text('Rattachement au groupe…'), findsOneWidget);

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
      await _showPreview(tester);
      await _tapJoin(tester);
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

  group('MJ sans personnage (décision du 12-13/10/2026)', () {
    testWidgets(
      'sélectionner MJ met à jour la tuile et active "Rejoindre" dès que le '
      'code est valide',
      (tester) async {
        fakeCharacterRepository.charactersToReturn = const [
          CharacterSummary(id: '1', name: 'Halltesse', level: 5, xp: 7000),
        ];

        await tester.pumpWidget(buildWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Halltesse'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('MJ — sans personnage'));
        await tester.pumpAndSettle();

        expect(find.text('MJ — sans personnage'), findsOneWidget);
        expect(
          find.text('Suit le groupe sans fiche de personnage.'),
          findsOneWidget,
        );
        expect(_isPrimaryButtonEnabled(tester), isFalse);

        await tester.enterText(find.byType(TextField), 'ab3f7k');
        await tester.pump();

        expect(_isPrimaryButtonEnabled(tester), isTrue);
      },
    );

    testWidgets(
      'sélection exclusive : choisir un personnage après MJ désélectionne MJ',
      (tester) async {
        fakeCharacterRepository.charactersToReturn = const [
          CharacterSummary(id: '1', name: 'Halltesse', level: 5, xp: 7000),
        ];

        await tester.pumpWidget(buildWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Halltesse'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('MJ — sans personnage'));
        await tester.pumpAndSettle();
        expect(find.text('MJ — sans personnage'), findsOneWidget);

        await tester.tap(find.text('MJ — sans personnage'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Halltesse'));
        await tester.pumpAndSettle();

        expect(find.text('Halltesse'), findsOneWidget);
        expect(find.text('MJ — sans personnage'), findsNothing);
      },
    );

    testWidgets(
      'la ligne MJ reste visible/sélectionnable même si charactersProvider '
      'échoue — "Rejoindre" ne dépend jamais de cet état quand MJ est choisi',
      (tester) async {
        fakeCharacterRepository.charactersErrorToThrow = const CharacterFailure(
          'Erreur serveur.',
        );

        await tester.pumpWidget(buildWidget());
        await tester.pumpAndSettle();

        expect(find.text('Choisir un personnage ou un rôle'), findsOneWidget);

        await tester.tap(find.text('Choisir un personnage ou un rôle'));
        await tester.pumpAndSettle();

        expect(find.text('MJ — sans personnage'), findsOneWidget);
        await tester.tap(find.text('MJ — sans personnage'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'ab3f7k');
        await tester.pump();

        expect(_isPrimaryButtonEnabled(tester), isTrue);
      },
    );

    testWidgets(
      'rejoindre en MJ : joinGroup est appelé avec characterId null',
      (tester) async {
        fakeCharacterRepository.charactersToReturn = const [
          CharacterSummary(id: '42', name: 'Borgan', level: 1, xp: 0),
        ];

        await tester.pumpWidget(buildWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Borgan'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('MJ — sans personnage'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'ab3f7k');
        await tester.pump();
        await _showPreview(tester);
        await _tapJoin(tester);
        await tester.pumpAndSettle();

        expect(fakeGroupRepository.lastJoinedCharacterId, isNull);
        expect(find.text('Écran Groupe group-1'), findsOneWidget);
      },
    );

    testWidgets(
      'échec "mj_already_assigned" au rattachement : bandeau encadré dédié',
      (tester) async {
        fakeCharacterRepository.charactersToReturn = const [];
        fakeGroupRepository.joinErrorToThrow = const GroupInviteFailure(
          GroupInviteFailureKind.mjAlreadyAssigned,
        );

        await tester.pumpWidget(buildWidget());
        await tester.pumpAndSettle();

        await tester.tap(
          find.text("Tu n'as pas encore de personnage à rattacher."),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('MJ — sans personnage'));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'ab3f7k');
        await tester.pump();
        await _showPreview(tester);
        await _tapJoin(tester);
        await tester.pumpAndSettle();

        expect(
          find.text('Ce groupe a déjà un MJ sans personnage.'),
          findsOneWidget,
        );
      },
    );
  });

  // Étape 4 : aperçu du groupe avant de le rejoindre (décisions n° 33, 34
  // et 36 du 19/11/2026).
  group('aperçu avant de rejoindre', () {
    const fullCode = 'ab3f7k2m';
    const campaignPreview = GroupPreview(
      name: 'Les Lames',
      memberCount: 3,
      storyTitle: 'La Mine perdue',
    );

    Future<void> enterFullCode(WidgetTester tester) async {
      await tester.enterText(find.byType(TextField), fullCode);
      await tester.pumpAndSettle();
    }

    setUp(() {
      fakeCharacterRepository.charactersToReturn = const [
        CharacterSummary(id: '42', name: 'Borgan', level: 1, xp: 0),
      ];
    });

    testWidgets('code complet : la carte s\'affiche d\'office sous le champ '
        '(nom, membres, campagne), sans rejoindre', (tester) async {
      fakeGroupRepository.previewToReturn = campaignPreview;
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      expect(_previewCard(), findsNothing);

      await enterFullCode(tester);

      expect(_previewCard(), findsOneWidget);
      expect(fakeGroupRepository.previewedCodes, ['AB3F7K2M']);
      expect(fakeGroupRepository.joinCallCount, 0);
      final card = find.descendant(
        of: _previewCard(),
        matching: find.text('Les Lames'),
      );
      expect(card, findsOneWidget);
      expect(find.text('3 membres'), findsOneWidget);
      expect(
        find.text('Campagne\u00a0: La Mine perdue', findRichText: true),
        findsOneWidget,
      );
      // Sous le champ du code, avant le choix du rôle.
      expect(
        tester.getTopLeft(_previewCard()).dy,
        greaterThan(tester.getBottomLeft(find.byType(TextField)).dy),
      );
      expect(
        tester.getTopLeft(_previewCard()).dy,
        lessThan(
          tester.getTopLeft(find.text('Qui te représente dans ce groupe ?')).dy,
        ),
      );
      // Annoncé par le lecteur d'écran à son apparition.
      expect(
        find.ancestor(
          of: _previewCard(),
          matching: find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.liveRegion == true,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('sans campagne : nom et « 1 membre », aucune ligne '
        '« Campagne »', (tester) async {
      fakeGroupRepository.previewToReturn = const GroupPreview(
        name: 'Les Lames',
        memberCount: 1,
      );
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await enterFullCode(tester);

      expect(_previewCard(), findsOneWidget);
      expect(find.text('1 membre'), findsOneWidget);
      expect(find.textContaining('Campagne', findRichText: true), findsNothing);
    });

    testWidgets('titre identique au nom du groupe (casse, blancs) : aucune '
        'ligne « Campagne »', (tester) async {
      fakeGroupRepository.previewToReturn = const GroupPreview(
        name: 'Les Lames',
        memberCount: 2,
        storyTitle: '  LES LAMES ',
      );
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await enterFullCode(tester);

      expect(_previewCard(), findsOneWidget);
      expect(find.text('2 membres'), findsOneWidget);
      expect(find.textContaining('Campagne', findRichText: true), findsNothing);
    });

    testWidgets('en anglais : « 3 members », « Campaign: », titre non '
        'traduit', (tester) async {
      fakeGroupRepository.previewToReturn = campaignPreview;
      await tester.pumpWidget(
        _buildTestWidget(
          characterRepository: fakeCharacterRepository,
          groupRepository: fakeGroupRepository,
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      await enterFullCode(tester);

      expect(find.text('3 members'), findsOneWidget);
      expect(
        find.text('Campaign: La Mine perdue', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('carte affichée puis « Rejoindre » : rattachement direct, '
        'sans second aperçu', (tester) async {
      fakeGroupRepository.previewToReturn = campaignPreview;
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await enterFullCode(tester);

      await _tapJoin(tester);
      await tester.pumpAndSettle();

      expect(fakeGroupRepository.previewCallCount, 1);
      expect(fakeGroupRepository.joinCallCount, 1);
      expect(fakeGroupRepository.lastJoinedCode, 'AB3F7K2M');
      expect(fakeGroupRepository.lastJoinedCharacterId, '42');
      expect(find.text('Écran Groupe group-1'), findsOneWidget);
    });

    testWidgets('lien d\'invitation (code complet pré-rempli) : la carte '
        's\'affiche dès l\'ouverture', (tester) async {
      fakeGroupRepository.previewToReturn = campaignPreview;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            characterRepositoryProvider.overrideWithValue(
              fakeCharacterRepository,
            ),
            groupRepositoryProvider.overrideWithValue(fakeGroupRepository),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('fr'),
            home: Scaffold(body: GroupJoinScreen(initialCode: 'AB3F7K2M')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_previewCard(), findsOneWidget);
      expect(fakeGroupRepository.previewedCodes, ['AB3F7K2M']);
      expect(fakeGroupRepository.joinCallCount, 0);
    });

    testWidgets('modifier le code retire la carte de l\'ancien code', (
      tester,
    ) async {
      fakeGroupRepository.previewToReturn = campaignPreview;
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await enterFullCode(tester);
      expect(_previewCard(), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'ab3f7k2');
      await tester.pumpAndSettle();

      expect(_previewCard(), findsNothing);
    });

    testWidgets('code de 6 caractères : « Voir le groupe » affiche la carte '
        'sans rejoindre, « Rejoindre » rejoint', (tester) async {
      fakeGroupRepository.previewToReturn = campaignPreview;
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'ab3f7k');
      await tester.pumpAndSettle();
      expect(_previewCard(), findsNothing);
      expect(fakeGroupRepository.previewCallCount, 0);

      await tester.tap(find.text('VOIR LE GROUPE'));
      await tester.pumpAndSettle();
      expect(_previewCard(), findsOneWidget);
      expect(fakeGroupRepository.joinCallCount, 0);

      await _tapJoin(tester);
      await tester.pumpAndSettle();
      expect(fakeGroupRepository.previewCallCount, 1);
      expect(fakeGroupRepository.joinCallCount, 1);
      expect(find.text('Écran Groupe group-1'), findsOneWidget);
    });

    testWidgets('aperçu automatique en cours : « Voir le groupe » inactif, '
        'un toucher ne fait rien ; la carte arrive sans voile', (tester) async {
      fakeGroupRepository.previewCompleter = Completer<GroupPreview>();
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), fullCode);
      await tester.pump();

      expect(_isPrimaryButtonEnabled(tester), isFalse);
      await tester.tap(find.text('VOIR LE GROUPE'), warnIfMissed: false);
      await tester.pump();
      expect(find.text('Rattachement au groupe…'), findsNothing);
      expect(_previewLoading(), findsOneWidget);

      fakeGroupRepository.previewCompleter!.complete(campaignPreview);
      await tester.pumpAndSettle();

      expect(_previewCard(), findsOneWidget);
      expect(_previewLoading(), findsNothing);
      expect(find.text('REJOINDRE'), findsOneWidget);
      // Garde anti double toucher : inactif, puis actif après 300 ms.
      expect(_isPrimaryButtonEnabled(tester), isFalse);
      await tester.pump(kDoubleTapTimeout);
      expect(_isPrimaryButtonEnabled(tester), isTrue);
      expect(fakeGroupRepository.previewCallCount, 1);
      expect(fakeGroupRepository.joinCallCount, 0);
    });

    // Relecture de code de la PR #304, point bloquant : arrivée par un lien
    // (personnage choisi d'office), appui sur « Voir le groupe » pendant
    // l'aperçu automatique, réponse reçue pendant l'appui, doigt levé sur
    // « Rejoindre » : jamais de rattachement sans confirmation.
    testWidgets('appui commencé pendant l\'aperçu automatique, réponse reçue '
        'avant de lever le doigt : aucun rattachement', (tester) async {
      fakeGroupRepository.previewCompleter = Completer<GroupPreview>();
      await tester.pumpWidget(
        _buildTestWidget(
          characterRepository: fakeCharacterRepository,
          groupRepository: fakeGroupRepository,
          initialLocation: '/groups/join?code=AB3F7K2M',
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(_previewLoading(), findsOneWidget);
      expect(find.text('Borgan'), findsOneWidget);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('VOIR LE GROUPE')),
      );
      fakeGroupRepository.previewCompleter!.complete(campaignPreview);
      await tester.pump();
      await tester.pump();
      expect(find.text('REJOINDRE'), findsOneWidget);

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 500));

      expect(fakeGroupRepository.joinCallCount, 0);
      expect(find.text('Rattachement au groupe…'), findsNothing);
      expect(_previewCard(), findsOneWidget);
    });

    testWidgets('appui commencé sur « Rejoindre » pour le groupe A, carte du '
        'groupe B affichée avant de lever le doigt : aucun rattachement', (
      tester,
    ) async {
      fakeGroupRepository.previewToReturn = campaignPreview;
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await enterFullCode(tester);
      await tester.pump(kDoubleTapTimeout);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('REJOINDRE')),
      );
      fakeGroupRepository.previewToReturn = const GroupPreview(
        name: 'Groupe B',
        memberCount: 2,
      );
      await tester.enterText(find.byType(TextField), 'zz9988xx');
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.descendant(of: _previewCard(), matching: find.text('Groupe B')),
        findsOneWidget,
      );

      await gesture.up();
      await tester.pump();

      expect(fakeGroupRepository.joinCallCount, 0);
    });

    testWidgets('double toucher : « Rejoindre » ignoré 300 ms après '
        'l\'apparition de la carte, accepté ensuite', (tester) async {
      fakeGroupRepository.previewToReturn = campaignPreview;
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'ab3f7k');
      await tester.pump();

      await tester.tap(find.text('VOIR LE GROUPE'));
      await tester.pump();
      await tester.pump();
      expect(_previewCard(), findsOneWidget);

      // Garde armée à l'affichage : bouton inactif, toucher sans effet.
      expect(_isPrimaryButtonEnabled(tester), isFalse);
      await tester.pump(const Duration(milliseconds: 100));
      expect(_isPrimaryButtonEnabled(tester), isFalse);
      await tester.tap(find.text('REJOINDRE'));
      await tester.pump();
      expect(fakeGroupRepository.joinCallCount, 0);
      expect(find.text('Rattachement au groupe…'), findsNothing);

      // L'expiration reconstruit l'écran : le bouton redevient actif seul.
      await tester.pump(const Duration(milliseconds: 150));
      expect(_isPrimaryButtonEnabled(tester), isFalse);
      await tester.pump(const Duration(milliseconds: 160));
      expect(_isPrimaryButtonEnabled(tester), isTrue);
      await tester.tap(find.text('REJOINDRE'));
      await tester.pumpAndSettle();
      expect(fakeGroupRepository.joinCallCount, 1);
      expect(find.text('Écran Groupe group-1'), findsOneWidget);
    });

    testWidgets('double toucher : la garde vaut aussi pour la carte de '
        'l\'aperçu automatique', (tester) async {
      fakeGroupRepository.previewToReturn = campaignPreview;
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), fullCode);
      await tester.pump();
      await tester.pump();
      expect(_previewCard(), findsOneWidget);
      expect(_isPrimaryButtonEnabled(tester), isFalse);

      await tester.tap(find.text('REJOINDRE'));
      await tester.pump();
      expect(fakeGroupRepository.joinCallCount, 0);

      await _tapJoin(tester);
      await tester.pumpAndSettle();
      expect(fakeGroupRepository.joinCallCount, 1);
    });

    testWidgets('code invalide sans toucher : l\'erreur est annoncée par le '
        'lecteur d\'écran (liveRegion)', (tester) async {
      fakeGroupRepository.previewErrorToThrow = const GroupInviteFailure(
        GroupInviteFailureKind.invalidCode,
      );
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await enterFullCode(tester);

      final hint = find.text("Ce code d'invitation n'est pas valide.");
      expect(hint, findsOneWidget);
      expect(
        find.ancestor(
          of: hint,
          matching: find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.properties.liveRegion == true &&
                w.container,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('code régénéré : pendant la relecture de l\'aperçu, ni carte '
        'de l\'ancien groupe ni « Rejoindre », « Recherche du groupe… »', (
      tester,
    ) async {
      fakeGroupRepository.previewToReturn = campaignPreview;
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await enterFullCode(tester);
      expect(_previewCard(), findsOneWidget);

      final reread = Completer<GroupPreview>();
      fakeGroupRepository
        ..joinErrorToThrow = const GroupInviteFailure(
          GroupInviteFailureKind.invalidCode,
        )
        ..previewCompleter = reread;
      await _tapJoin(tester);
      await tester.pump();
      await tester.pump();

      expect(fakeGroupRepository.joinCallCount, 1);
      expect(fakeGroupRepository.previewCallCount, 2, reason: 'relecture');
      expect(_previewCard(), findsNothing);
      expect(find.text('REJOINDRE'), findsNothing);
      expect(_previewLoading(), findsOneWidget);
      expect(_isPrimaryButtonEnabled(tester), isFalse);
      expect(
        find.text("Ce code d'invitation n'est pas valide."),
        findsOneWidget,
      );

      reread.completeError(
        const GroupInviteFailure(GroupInviteFailureKind.invalidCode),
      );
      await tester.pumpAndSettle();
      expect(_previewLoading(), findsNothing);
      expect(_previewCard(), findsNothing);
      expect(find.text('VOIR LE GROUPE'), findsOneWidget);
    });

    testWidgets('code régénéré entre l\'aperçu et le rattachement : la carte '
        'de l\'ancien groupe disparaît, retour à « Voir le groupe »', (
      tester,
    ) async {
      fakeGroupRepository.previewToReturn = campaignPreview;
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await enterFullCode(tester);
      expect(_previewCard(), findsOneWidget);

      fakeGroupRepository
        ..joinErrorToThrow = const GroupInviteFailure(
          GroupInviteFailureKind.invalidCode,
        )
        ..previewErrorToThrow = const GroupInviteFailure(
          GroupInviteFailureKind.invalidCode,
        );
      await _tapJoin(tester);
      await tester.pumpAndSettle();

      expect(fakeGroupRepository.joinCallCount, 1);
      expect(fakeGroupRepository.previewCallCount, 2, reason: 'relu');
      expect(_previewCard(), findsNothing);
      expect(find.text('REJOINDRE'), findsNothing);
      expect(find.text('VOIR LE GROUPE'), findsOneWidget);
      expect(
        find.text("Ce code d'invitation n'est pas valide."),
        findsOneWidget,
      );
    });

    testWidgets('code de 6 caractères : « Voir le groupe » verrouille le '
        'champ et le rôle sans voile, puis « Rejoindre » montre le voile', (
      tester,
    ) async {
      fakeGroupRepository.previewCompleter = Completer<GroupPreview>();
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'ab3f7k');
      await tester.pump();

      await tester.tap(find.text('VOIR LE GROUPE'));
      await tester.pump();
      expect(find.text('Rattachement au groupe…'), findsNothing);
      expect(_isPrimaryButtonLoading(tester), isTrue);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      expect(_previewLoading(), findsOneWidget);

      fakeGroupRepository.previewCompleter!.complete(campaignPreview);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);

      fakeGroupRepository.joinCompleter = Completer<JoinedGroup>();
      await _tapJoin(tester);
      await tester.pump();
      expect(find.text('Rattachement au groupe…'), findsOneWidget);

      fakeGroupRepository.joinCompleter!.complete(
        const JoinedGroup(groupId: 'group-1', name: 'Les Lames'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Écran Groupe group-1'), findsOneWidget);
    });

    testWidgets('aperçu automatique en cours : « Recherche du groupe… » dans '
        'l\'encadré, annoncé, sans verrouiller l\'écran', (tester) async {
      fakeGroupRepository.previewCompleter = Completer<GroupPreview>();
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), fullCode);
      await tester.pump();

      expect(_previewLoading(), findsOneWidget);
      expect(
        find.descendant(
          of: _previewLoading(),
          matching: find.text('Recherche du groupe…'),
        ),
        findsOneWidget,
      );
      final spinner = find.descendant(
        of: _previewLoading(),
        matching: find.byType(CircularProgressIndicator),
      );
      expect(tester.getSize(spinner), const Size(16, 16));
      expect(tester.widget<CircularProgressIndicator>(spinner).strokeWidth, 2);
      expect(
        find.ancestor(
          of: _previewLoading(),
          matching: find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.liveRegion == true,
          ),
        ),
        findsOneWidget,
      );
      // Sous le champ, comme la carte.
      expect(
        tester.getTopLeft(_previewLoading()).dy,
        greaterThan(tester.getBottomLeft(find.byType(TextField)).dy),
      );
      expect(_isPrimaryButtonLoading(tester), isFalse);
      expect(_isPrimaryButtonEnabled(tester), isFalse);
      expect(find.text('VOIR LE GROUPE'), findsOneWidget);

      fakeGroupRepository.previewCompleter!.complete(campaignPreview);
      await tester.pumpAndSettle();
      expect(_previewLoading(), findsNothing);
      expect(_previewCard(), findsOneWidget);
    });

    testWidgets('en anglais : « Looking for the group… »', (tester) async {
      fakeGroupRepository.previewCompleter = Completer<GroupPreview>();
      await tester.pumpWidget(
        _buildTestWidget(
          characterRepository: fakeCharacterRepository,
          groupRepository: fakeGroupRepository,
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), fullCode);
      await tester.pump();

      expect(find.text('Looking for the group…'), findsOneWidget);
      fakeGroupRepository.previewCompleter!.complete(campaignPreview);
      await tester.pumpAndSettle();
    });

    testWidgets('code complet invalide : l\'erreur s\'affiche aussitôt sous '
        'le champ, sans toucher', (tester) async {
      fakeGroupRepository.previewErrorToThrow = const GroupInviteFailure(
        GroupInviteFailureKind.invalidCode,
      );
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await enterFullCode(tester);

      expect(_previewCard(), findsNothing);
      expect(_previewLoading(), findsNothing);
      expect(
        find.text("Ce code d'invitation n'est pas valide."),
        findsOneWidget,
      );
      expect(fakeGroupRepository.previewCallCount, 1);

      // Le bouton relance la validation : même erreur, une seule fois.
      await tester.tap(find.text('VOIR LE GROUPE'));
      await tester.pumpAndSettle();

      expect(
        find.text("Ce code d'invitation n'est pas valide."),
        findsOneWidget,
      );
      expect(fakeGroupRepository.previewCallCount, 2, reason: 'relancé');
      expect(fakeGroupRepository.joinCallCount, 0);
    });

    testWidgets('aperçu automatique en échec réseau : rien sous le champ ni '
        'en bandeau avant le toucher', (tester) async {
      fakeGroupRepository.previewErrorToThrow = const GroupInviteFailure(
        GroupInviteFailureKind.generic,
      );
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await enterFullCode(tester);

      expect(_previewCard(), findsNothing);
      expect(_previewLoading(), findsNothing);
      expect(find.text("Ce code d'invitation n'est pas valide."), findsNothing);
      expect(
        find.text('Impossible de rejoindre ce groupe. Réessaie.'),
        findsNothing,
      );
    });

    testWidgets('aperçu automatique en échec réseau : « Voir le groupe » '
        'le relance et montre la carte, le joueur confirme ensuite', (
      tester,
    ) async {
      fakeGroupRepository.previewErrorToThrow = const GroupInviteFailure(
        GroupInviteFailureKind.generic,
      );
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await enterFullCode(tester);
      expect(_previewCard(), findsNothing);

      fakeGroupRepository
        ..previewErrorToThrow = null
        ..previewToReturn = campaignPreview;
      await tester.tap(find.text('VOIR LE GROUPE'));
      await tester.pumpAndSettle();

      expect(_previewCard(), findsOneWidget);
      expect(fakeGroupRepository.joinCallCount, 0);

      await _tapJoin(tester);
      await tester.pumpAndSettle();
      expect(fakeGroupRepository.joinCallCount, 1);
      expect(find.text('Écran Groupe group-1'), findsOneWidget);
    });

    testWidgets('échec générique persistant : même bandeau qu\'avant', (
      tester,
    ) async {
      fakeGroupRepository.previewErrorToThrow = const GroupInviteFailure(
        GroupInviteFailureKind.generic,
      );
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await enterFullCode(tester);

      await tester.tap(find.text('VOIR LE GROUPE'));
      await tester.pumpAndSettle();

      expect(
        find.text('Impossible de rejoindre ce groupe. Réessaie.'),
        findsOneWidget,
      );
      expect(_previewCard(), findsNothing);
      expect(fakeGroupRepository.joinCallCount, 0);
    });

    testWidgets('l\'erreur de code disparaît quand le code change', (
      tester,
    ) async {
      fakeGroupRepository.previewErrorToThrow = const GroupInviteFailure(
        GroupInviteFailureKind.invalidCode,
      );
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'ab3f7k');
      await tester.pump();
      await tester.tap(find.text('VOIR LE GROUPE'));
      await tester.pumpAndSettle();
      expect(
        find.text("Ce code d'invitation n'est pas valide."),
        findsOneWidget,
      );

      fakeGroupRepository
        ..previewErrorToThrow = null
        ..previewToReturn = campaignPreview;
      await enterFullCode(tester);

      expect(find.text("Ce code d'invitation n'est pas valide."), findsNothing);
      expect(_previewCard(), findsOneWidget);
    });

    testWidgets('échec au rattachement après l\'aperçu : erreurs inchangées, '
        'la carte reste', (tester) async {
      fakeGroupRepository
        ..previewToReturn = campaignPreview
        ..joinErrorToThrow = const GroupInviteFailure(
          GroupInviteFailureKind.alreadyInGroup,
        );
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await enterFullCode(tester);

      await _tapJoin(tester);
      await tester.pumpAndSettle();

      expect(
        find.text('Ce personnage est déjà membre de ce groupe.'),
        findsOneWidget,
      );
      expect(_previewCard(), findsOneWidget);
    });

    testWidgets('le bandeau d\'échec disparaît quand le code change (pas de '
        '« déjà membre » à côté de l\'aperçu d\'un autre groupe)', (
      tester,
    ) async {
      fakeGroupRepository
        ..previewToReturn = campaignPreview
        ..joinErrorToThrow = const GroupInviteFailure(
          GroupInviteFailureKind.alreadyInGroup,
        );
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await enterFullCode(tester);
      await _tapJoin(tester);
      await tester.pumpAndSettle();
      expect(
        find.text('Ce personnage est déjà membre de ce groupe.'),
        findsOneWidget,
      );

      fakeGroupRepository.previewToReturn = const GroupPreview(
        name: 'Autre groupe',
        memberCount: 2,
      );
      await tester.enterText(find.byType(TextField), 'zz9988xx');
      await tester.pumpAndSettle();

      expect(
        find.text('Ce personnage est déjà membre de ce groupe.'),
        findsNothing,
      );
      expect(find.text('Autre groupe'), findsOneWidget);
    });

    testWidgets('pluriel : « 0 membre » en français (0 relève du singulier)', (
      tester,
    ) async {
      fakeGroupRepository.previewToReturn = const GroupPreview(
        name: 'Groupe vide',
        memberCount: 0,
      );
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await enterFullCode(tester);

      expect(find.text('0 membre'), findsOneWidget);
      expect(find.text('1 membre'), findsNothing);
    });

    testWidgets('pluriel : « 1 member » en anglais', (tester) async {
      fakeGroupRepository.previewToReturn = const GroupPreview(
        name: 'Les Lames',
        memberCount: 1,
      );
      await tester.pumpWidget(
        _buildTestWidget(
          characterRepository: fakeCharacterRepository,
          groupRepository: fakeGroupRepository,
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      await enterFullCode(tester);

      expect(find.text('1 member'), findsOneWidget);
    });

    testWidgets('carte du groupe A affichée, puis code complet du groupe B '
        'dont l\'aperçu est en attente : le bouton ne rejoint ni A ni B', (
      tester,
    ) async {
      fakeGroupRepository.previewToReturn = campaignPreview;
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await enterFullCode(tester);
      expect(
        find.descendant(of: _previewCard(), matching: find.text('Les Lames')),
        findsOneWidget,
      );
      expect(find.text('REJOINDRE'), findsOneWidget);

      final groupB = Completer<GroupPreview>();
      fakeGroupRepository.previewCompleter = groupB;
      await tester.enterText(find.byType(TextField), 'zz9988xx');
      await tester.pump();

      expect(_previewCard(), findsNothing, reason: 'jamais la carte de A');
      expect(_previewLoading(), findsOneWidget);
      expect(find.text('VOIR LE GROUPE'), findsOneWidget);

      await tester.tap(find.text('VOIR LE GROUPE'));
      await tester.pump();
      expect(fakeGroupRepository.joinCallCount, 0);
      expect(find.text('Rattachement au groupe…'), findsNothing);

      groupB.complete(const GroupPreview(name: 'Groupe B', memberCount: 2));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: _previewCard(), matching: find.text('Groupe B')),
        findsOneWidget,
      );
      expect(fakeGroupRepository.joinCallCount, 0);
      expect(fakeGroupRepository.previewedCodes, ['AB3F7K2M', 'ZZ9988XX']);

      await _tapJoin(tester);
      await tester.pumpAndSettle();
      expect(fakeGroupRepository.joinCallCount, 1);
      expect(fakeGroupRepository.lastJoinedCode, 'ZZ9988XX');
    });

    testWidgets('libellé du bouton : « Voir le groupe » tant que la carte '
        'n\'est pas affichée, « Rejoindre » ensuite', (tester) async {
      fakeGroupRepository.previewToReturn = campaignPreview;
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('VOIR LE GROUPE'), findsOneWidget);
      expect(find.text('REJOINDRE'), findsNothing);

      await enterFullCode(tester);
      expect(find.text('REJOINDRE'), findsOneWidget);
      expect(find.text('VOIR LE GROUPE'), findsNothing);

      await tester.enterText(find.byType(TextField), 'ab3f7k2');
      await tester.pumpAndSettle();
      expect(find.text('VOIR LE GROUPE'), findsOneWidget);
    });

    testWidgets('libellé du bouton en anglais : « See the group » puis '
        '« Join »', (tester) async {
      fakeGroupRepository.previewToReturn = campaignPreview;
      await tester.pumpWidget(
        _buildTestWidget(
          characterRepository: fakeCharacterRepository,
          groupRepository: fakeGroupRepository,
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SEE THE GROUP'), findsOneWidget);
      await enterFullCode(tester);
      expect(find.text('JOIN'), findsOneWidget);
    });

    testWidgets('titre de la campagne en variante compacte (14 w700), sous le '
        'nom du groupe (16 w800)', (tester) async {
      fakeGroupRepository.previewToReturn = campaignPreview;
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();
      await enterFullCode(tester);

      final rich = tester.widget<RichText>(
        find.descendant(
          of: _previewCard(),
          matching: find.byWidgetPredicate(
            (w) =>
                w is RichText &&
                w.text.toPlainText().contains('La Mine perdue'),
          ),
        ),
      );
      final leaves = <TextSpan>[];
      rich.text.visitChildren((span) {
        if (span is TextSpan && span.text != null) leaves.add(span);
        return true;
      });
      final title = leaves.singleWhere((span) => span.text == 'La Mine perdue');
      expect(title.style!.fontSize, 14);
      expect(title.style!.fontWeight, FontWeight.w700);
      final name = tester.widget<Text>(
        find.descendant(of: _previewCard(), matching: find.text('Les Lames')),
      );
      expect(name.style!.fontSize, 16);
      expect(name.style!.fontWeight, FontWeight.w800);
    });
  });

  // D233 : plus aucun texte en dur sur cet écran ; chaque texte affiché est
  // celui de sa clé `.arb`, en français (tutoiement) comme en anglais.
  group('textes localisés (D233)', () {
    test('messages d\'erreur au tutoiement en français', () {
      final fr = lookupAppLocalizations(const Locale('fr'));
      expect(
        fr.groupJoinGenericError,
        'Impossible de rejoindre ce groupe. Réessaie.',
      );
      expect(
        fr.groupJoinInvalidCodeError,
        "Ce code d'invitation n'est pas valide.",
      );
      expect(
        fr.groupJoinAlreadyInGroupError,
        'Ce personnage est déjà membre de ce groupe.',
      );
      expect(
        fr.groupJoinGameMasterAlreadyAssignedError,
        'Ce groupe a déjà un MJ sans personnage.',
      );
      // Tous les textes de l'écran : jamais de vouvoiement.
      for (final text in [
        fr.groupJoinTitle,
        fr.groupJoinIntro,
        fr.groupJoinCodeLabel,
        fr.groupJoinRoleLabel,
        fr.groupJoinRoleHelp,
        fr.groupJoinRolePickerTitle,
        fr.groupJoinGameMasterRoleTitle,
        fr.groupJoinGameMasterRoleSubtitle,
        fr.groupJoinNoCharacter,
        fr.groupJoinChooseRolePlaceholder,
        fr.groupJoinCharactersRetryButton,
        fr.groupJoinSuccess,
        fr.groupJoinInProgress,
        fr.groupJoinGenericError,
        fr.groupJoinInvalidCodeError,
        fr.groupJoinAlreadyInGroupError,
        fr.groupJoinGameMasterAlreadyAssignedError,
      ]) {
        expect(
          text,
          isNot(matches(RegExp(r'\b(Réessayez|vous|votre|vos)\b'))),
          reason: text,
        );
      }
    });

    for (final locale in const [Locale('fr'), Locale('en')]) {
      final l10n = lookupAppLocalizations(locale);
      final lang = locale.languageCode;

      Widget buildIn() => _buildTestWidget(
        characterRepository: fakeCharacterRepository,
        groupRepository: fakeGroupRepository,
        locale: locale,
      );

      /// Touche le bouton principal (« Voir le groupe » ou « Rejoindre »),
      /// quelle que soit la langue, après la garde anti double toucher.
      Future<void> tapPrimary(WidgetTester tester) async {
        await tester.pump(kDoubleTapTimeout);
        await tester.tap(find.byType(PrimaryButton));
      }

      testWidgets('[$lang] textes fixes de l\'écran et de la feuille de rôle', (
        tester,
      ) async {
        fakeCharacterRepository.charactersToReturn = const [];
        await tester.pumpWidget(buildIn());
        await tester.pumpAndSettle();

        expect(find.text(l10n.groupJoinTitle), findsOneWidget);
        expect(find.text(l10n.groupJoinIntro), findsOneWidget);
        expect(find.text(l10n.groupJoinCodeLabel), findsOneWidget);
        expect(find.text(l10n.groupJoinRoleLabel), findsOneWidget);
        expect(find.text(l10n.groupJoinRoleHelp), findsOneWidget);
        expect(find.text(l10n.groupJoinNoCharacter), findsOneWidget);

        await tester.tap(find.text(l10n.groupJoinNoCharacter));
        await tester.pumpAndSettle();
        expect(find.text(l10n.groupJoinRolePickerTitle), findsOneWidget);
        expect(find.text(l10n.groupJoinGameMasterRoleTitle), findsOneWidget);
        expect(find.text(l10n.groupJoinGameMasterRoleSubtitle), findsOneWidget);
        // Tuile du rôle et note sous la ligne MJ.
        expect(find.text(l10n.groupJoinNoCharacter), findsNWidgets(2));

        await tester.tap(find.text(l10n.groupJoinGameMasterRoleTitle));
        await tester.pumpAndSettle();
        expect(find.text(l10n.groupJoinRolePickerTitle), findsNothing);
        expect(find.text(l10n.groupJoinGameMasterRoleTitle), findsOneWidget);
        expect(find.text(l10n.groupJoinGameMasterRoleSubtitle), findsOneWidget);
      });

      testWidgets('[$lang] résumé du personnage : niveau localisé', (
        tester,
      ) async {
        fakeCharacterRepository.charactersToReturn = const [
          CharacterSummary(
            id: '1',
            name: 'Halltesse',
            level: 5,
            xp: 7000,
            className: 'Magicien',
          ),
        ];
        await tester.pumpWidget(buildIn());
        await tester.pumpAndSettle();

        expect(
          find.text('Magicien · ${l10n.characterLevelAbbreviation(5)}'),
          findsOneWidget,
        );
      });

      testWidgets('[$lang] personnages en échec : choix du rôle et bouton '
          'de relance', (tester) async {
        fakeCharacterRepository.charactersErrorToThrow = Exception('réseau');
        await tester.pumpWidget(buildIn());
        await tester.pumpAndSettle();

        expect(find.text(l10n.groupJoinChooseRolePlaceholder), findsOneWidget);
        await tester.tap(find.text(l10n.groupJoinChooseRolePlaceholder));
        await tester.pumpAndSettle();
        expect(find.text(l10n.characterLoadFailedErrorMessage), findsOneWidget);
        expect(find.text(l10n.groupJoinCharactersRetryButton), findsOneWidget);
      });

      testWidgets('[$lang] aperçu : code invalide sous le champ, échec '
          'générique en bandeau', (tester) async {
        fakeCharacterRepository.charactersToReturn = const [
          CharacterSummary(id: '42', name: 'Borgan', level: 1, xp: 0),
        ];
        fakeGroupRepository.previewErrorToThrow = const GroupInviteFailure(
          GroupInviteFailureKind.invalidCode,
        );
        await tester.pumpWidget(buildIn());
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'ab3f7k');
        await tester.pump();
        await tapPrimary(tester);
        await tester.pumpAndSettle();
        expect(find.text(l10n.groupJoinInvalidCodeError), findsOneWidget);

        fakeGroupRepository.previewErrorToThrow = const GroupInviteFailure(
          GroupInviteFailureKind.generic,
        );
        await tester.enterText(find.byType(TextField), 'cd9912');
        await tester.pump();
        await tapPrimary(tester);
        await tester.pumpAndSettle();
        expect(find.text(l10n.groupJoinGenericError), findsOneWidget);
        expect(find.text(l10n.groupJoinInvalidCodeError), findsNothing);

        // Aperçu automatique d'un code complet invalide : même texte.
        fakeGroupRepository.previewErrorToThrow = const GroupInviteFailure(
          GroupInviteFailureKind.invalidCode,
        );
        await tester.enterText(find.byType(TextField), 'ab3f7k2m');
        await tester.pumpAndSettle();
        expect(find.text(l10n.groupJoinInvalidCodeError), findsOneWidget);
      });

      final joinFailures = <Object, String>{
        const GroupInviteFailure(GroupInviteFailureKind.alreadyInGroup):
            l10n.groupJoinAlreadyInGroupError,
        const GroupInviteFailure(GroupInviteFailureKind.mjAlreadyAssigned):
            l10n.groupJoinGameMasterAlreadyAssignedError,
        const GroupInviteFailure(GroupInviteFailureKind.generic):
            l10n.groupJoinGenericError,
        const GroupInviteFailure(GroupInviteFailureKind.invalidCode):
            l10n.groupJoinInvalidCodeError,
        Exception('réseau'): l10n.groupJoinGenericError,
      };
      for (final entry in joinFailures.entries) {
        testWidgets('[$lang] rattachement en échec (${entry.key}) : '
            '« ${entry.value} »', (tester) async {
          fakeCharacterRepository.charactersToReturn = const [
            CharacterSummary(id: '42', name: 'Borgan', level: 1, xp: 0),
          ];
          fakeGroupRepository.joinErrorToThrow = entry.key;
          await tester.pumpWidget(buildIn());
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField), 'ab3f7k');
          await tester.pump();
          await tapPrimary(tester);
          await tester.pumpAndSettle();
          expect(_previewCard(), findsOneWidget);
          await tapPrimary(tester);
          await tester.pumpAndSettle();

          expect(find.text(entry.value), findsOneWidget);
        });
      }

      testWidgets('[$lang] rattachement : voile puis message de réussite', (
        tester,
      ) async {
        fakeCharacterRepository.charactersToReturn = const [
          CharacterSummary(id: '42', name: 'Borgan', level: 1, xp: 0),
        ];
        fakeGroupRepository.joinCompleter = Completer<JoinedGroup>();
        await tester.pumpWidget(buildIn());
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'ab3f7k');
        await tester.pump();
        await tapPrimary(tester);
        await tester.pumpAndSettle();
        await tapPrimary(tester);
        await tester.pump();

        expect(find.text(l10n.groupJoinInProgress), findsOneWidget);

        fakeGroupRepository.joinCompleter!.complete(
          const JoinedGroup(groupId: 'group-1', name: 'Les Lames'),
        );
        await tester.pumpAndSettle();
        expect(find.text(l10n.groupJoinSuccess), findsOneWidget);
      });
    }
  });
}
