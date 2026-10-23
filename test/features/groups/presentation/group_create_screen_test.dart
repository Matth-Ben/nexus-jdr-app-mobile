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
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/characters/domain/inventory_catalog_item.dart';
import 'package:personnages/features/characters/domain/level_up_apply_result.dart';
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
import 'package:personnages/features/characters/domain/level_up_choice_selection.dart';
import 'package:personnages/features/characters/domain/level_up_level_data.dart';
import 'package:personnages/features/characters/domain/rest_type.dart';
import 'package:personnages/features/characters/domain/reward_item_draft.dart';
import 'package:personnages/features/characters/domain/weapon_slot.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/features/groups/data/group_repository.dart';
import 'package:personnages/features/groups/domain/created_group.dart';
import 'package:personnages/features/groups/domain/group_detail.dart';
import 'package:personnages/features/groups/domain/group_failure.dart';
import 'package:personnages/features/groups/domain/group_note.dart';
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
  Object? createErrorToThrow;
  Completer<CreatedGroup>? createCompleter;
  String? lastCreatedName;
  String? lastCreatedCharacterId;

  @override
  Future<CreatedGroup> createGroup({
    required String name,
    String? characterId,
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

/// Ouvre la sheet "Choisir un personnage" — un tap sur la tuile de
/// sélection (identifiée par son chevron, seul dans l'arbre sur cet écran
/// tant que la sheet n'est pas ouverte, quel que soit le libellé affiché sur
/// la tuile à cet instant : placeholder ou nom du personnage déjà choisi).
Future<void> _openCharacterPicker(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.chevron_right));
  await tester.pumpAndSettle();
}

/// Ouvre la sheet puis sélectionne [characterName] dedans — la sheet se
/// referme automatiquement après la sélection (voir
/// `group_create_screen.dart::_openCharacterPicker`).
Future<void> _selectCharacterViaSheet(
  WidgetTester tester,
  String characterName,
) async {
  await _openCharacterPicker(tester);
  await tester.tap(find.text(characterName), warnIfMissed: false);
  await tester.pumpAndSettle();
}

void main() {
  late _FakeCharacterRepository fakeCharacterRepository;
  late _FakeGroupRepository fakeGroupRepository;

  setUp(() {
    fakeCharacterRepository = _FakeCharacterRepository();
    fakeGroupRepository = _FakeGroupRepository();
  });

  testWidgets(
    'affiche le titre, le texte d\'intro et le sélecteur de personnage',
    (tester) async {
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
      expect(
        find.textContaining('Un groupe permet de suivre les PV'),
        findsOneWidget,
      );
      expect(find.text('Nom du groupe'), findsOneWidget);
      expect(find.text('Qui te représente dans ce groupe ?'), findsOneWidget);
      expect(find.textContaining('représentera ta présence'), findsOneWidget);
      // Aucune sélection : la tuile affiche le placeholder, "Sylvi"
      // n'apparaît nulle part avant l'ouverture de la sheet.
      expect(find.text('Choisir un personnage ou un rôle'), findsOneWidget);
      expect(find.text('Sylvi'), findsNothing);
      expect(
        find.textContaining("Un code d'invitation sera généré"),
        findsOneWidget,
      );

      await _openCharacterPicker(tester);
      expect(find.text('Sylvi'), findsOneWidget);
    },
  );

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

    await _selectCharacterViaSheet(tester, 'Sylvi');
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
      await _selectCharacterViaSheet(tester, 'Sylvi');
      // La tuile affiche désormais "Sylvi" : rouvrir la sheet à travers
      // elle puis choisir "Borgan" à la place.
      expect(find.text('Sylvi'), findsOneWidget);
      await _selectCharacterViaSheet(tester, 'Borgan');

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
      await _selectCharacterViaSheet(tester, 'Sylvi');
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
      await _selectCharacterViaSheet(tester, 'Sylvi');
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

    // Correctif de bug (MJ sans personnage, 12-13/10/2026) : la tuile et la
    // note sur le code d'invitation restent affichées même sans aucun
    // personnage — seul un joueur qui veut choisir un VRAI personnage est
    // concerné par l'absence de la liste ; un joueur qui veut rejoindre en
    // MJ ne doit jamais être bloqué.
    expect(find.text('Choisir un personnage ou un rôle'), findsOneWidget);
    expect(
      find.textContaining("Un code d'invitation sera généré"),
      findsOneWidget,
    );
    // Le message dédié "aucun personnage" n'apparaît plus que dans la sheet,
    // sous la ligne MJ.
    expect(
      find.textContaining("Tu n'as pas encore de personnage"),
      findsNothing,
    );

    await _openCharacterPicker(tester);

    expect(find.text('CHOISIR TON RÔLE'), findsOneWidget);
    expect(find.text('MJ — sans personnage'), findsOneWidget);
    expect(
      find.textContaining(
        "Tu n'as pas encore de personnage à inscrire dans ce groupe.",
      ),
      findsOneWidget,
    );
  });

  group('MJ sans personnage (décision du 12-13/10/2026)', () {
    testWidgets(
      'sélectionner MJ met à jour la tuile et active "Créer le groupe", '
      'indépendamment de charactersProvider',
      (tester) async {
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

        await tester.enterText(find.byType(TextFormField), 'Les Lames');
        await _openCharacterPicker(tester);
        await tester.tap(find.text('MJ — sans personnage'));
        await tester.pumpAndSettle();

        expect(find.text('MJ — sans personnage'), findsOneWidget);
        expect(_isPrimaryButtonEnabled(tester, 'Créer le groupe'), isTrue);

        await tester.tap(find.text('CRÉER LE GROUPE'));
        await tester.pump();

        expect(fakeGroupRepository.lastCreatedName, 'Les Lames');
        expect(fakeGroupRepository.lastCreatedCharacterId, isNull);
      },
    );

    testWidgets(
      'sélection exclusive : choisir un personnage après MJ désélectionne MJ',
      (tester) async {
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

        await _openCharacterPicker(tester);
        await tester.tap(find.text('MJ — sans personnage'));
        await tester.pumpAndSettle();
        expect(find.text('MJ — sans personnage'), findsOneWidget);

        await _selectCharacterViaSheet(tester, 'Sylvi');

        expect(find.text('Sylvi'), findsOneWidget);
        expect(find.text('MJ — sans personnage'), findsNothing);
      },
    );

    testWidgets(
      'la ligne MJ reste visible/sélectionnable même si charactersProvider '
      'échoue — le bouton primaire ne dépend jamais de cet état quand MJ '
      'est choisi',
      (tester) async {
        fakeCharacterRepository.charactersErrorToThrow = const CharacterFailure(
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
        await _openCharacterPicker(tester);

        expect(find.text('MJ — sans personnage'), findsOneWidget);
        await tester.tap(find.text('MJ — sans personnage'));
        await tester.pumpAndSettle();

        expect(_isPrimaryButtonEnabled(tester, 'Créer le groupe'), isTrue);
      },
    );
  });
}
