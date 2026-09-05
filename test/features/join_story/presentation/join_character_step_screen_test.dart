// Tests de widget de l'étape 3/4 "Choix du personnage" (et l'overlay de
// l'étape 4/4 "Validation", qui n'a pas de route dédiée — voir la spec
// visuelle de la tâche) du flux "Rejoindre une histoire".
//
// Réutilise `charactersProvider`/`CharacterCard` : le dépôt de test des
// personnages (`_FakeCharacterRepository`) et celui du flux "Rejoindre une
// histoire" (`_FakeStoryInviteRepository`) sont tous deux injectés via
// `overrideWithValue`, même principe que `character_list_screen_test.dart`.

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
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/characters/domain/inventory_catalog_item.dart';
import 'package:personnages/features/characters/domain/level_up_apply_result.dart';
import 'package:personnages/features/characters/domain/level_up_choice_selection.dart';
import 'package:personnages/features/characters/domain/level_up_level_data.dart';
import 'package:personnages/features/characters/domain/rest_type.dart';
import 'package:personnages/features/characters/domain/reward_item_draft.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/features/characters/presentation/widgets/character_card.dart';
import 'package:personnages/features/join_story/data/story_invite_repository.dart';
import 'package:personnages/features/join_story/domain/join_story_result.dart';
import 'package:personnages/features/join_story/domain/story_invite_failure.dart';
import 'package:personnages/features/join_story/domain/story_preview.dart';
import 'package:personnages/features/join_story/presentation/join_character_step_screen.dart';
import 'package:personnages/features/join_story/presentation/providers/join_story_providers.dart';

class _FakeCharacterRepository implements CharacterRepository {
  List<CharacterSummary>? charactersToReturn;
  Object? charactersErrorToThrow;

  @override
  Future<List<CharacterSummary>> fetchCharacters() async {
    if (charactersErrorToThrow != null) throw charactersErrorToThrow!;
    return charactersToReturn ?? const [];
  }

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> updateHp({
    required String characterId,
    required int currentHp,
    required int temporaryHp,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<String> uploadPortrait({
    required String characterId,
    required Uint8List bytes,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> removePortrait({
    required String characterId,
    required String portraitUrl,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> addXp({
    required String characterId,
    required int newXp,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<LevelUpLevelData> fetchLevelUpLevelData({
    required Object classId,
    required int targetLevel,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<LevelUpApplyResult> applyLevelUp({
    required String characterId,
    required String className,
    required int hpRolled,
    required String hpMethod,
    required int hpGain,
    LevelUpChoiceSelection? choice,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> applyRest({
    required String characterId,
    required RestType type,
    required String className,
    int diceSpent = 0,
    int appliedGain = 0,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> leaveStory({required String characterCampaignId}) {
    throw UnimplementedError();
  }

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
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> setInventoryItemEquipped({
    required String characterId,
    required String inventoryId,
    required bool equipped,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> removeInventoryItem({
    required String characterId,
    required String inventoryId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> adjustCurrency({
    required String characterId,
    required CurrencyKind currency,
    required int newAmount,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> addInventoryItem({
    required String characterId,
    required int itemId,
    required int quantity,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> addCustomInventoryItem({
    required String characterId,
    required String customName,
    required int quantity,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> addReward({
    required String characterId,
    required Map<CurrencyKind, int> newCurrencyTotals,
    required List<RewardItemDraft> items,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<InventoryCatalogItem>> fetchInventoryCatalog() {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> castSpell({
    required String characterId,
    required int slotLevel,
    required int slotsUsed,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> useClassFeature({
    required String characterId,
    required int classFeatureId,
    required int usesRemaining,
  }) {
    throw UnimplementedError();
  }
}

class _FakeStoryInviteRepository implements StoryInviteRepository {
  Object? joinErrorToThrow;
  Completer<JoinStoryResult>? joinCompleter;
  String? lastJoinedCode;
  String? lastJoinedCharacterId;
  int joinCallCount = 0;

  @override
  Future<StoryPreview> previewInvite(String code) {
    throw UnimplementedError();
  }

  @override
  Future<JoinStoryResult> joinStory({
    required String code,
    required String characterId,
  }) async {
    joinCallCount++;
    lastJoinedCode = code;
    lastJoinedCharacterId = characterId;
    if (joinCompleter != null) return joinCompleter!.future;
    if (joinErrorToThrow != null) throw joinErrorToThrow!;
    return JoinStoryResult(
      characterCampaignId: 'cc-1',
      joinedAt: '2026-08-30T00:00:00Z',
      characterId: characterId,
      storyId: 'story-1',
      storyTitle: 'Histoire test',
    );
  }
}

GoRouter _buildTestRouter() {
  return GoRouter(
    initialLocation: '/join/step-3?code=AB3F7K',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Liste des personnages'))),
      ),
      GoRoute(
        path: '/join/step-2',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Étape 2'))),
      ),
      GoRoute(
        path: '/join/step-3',
        builder: (context, state) =>
            JoinCharacterStepScreen(code: state.uri.queryParameters['code']!),
      ),
      GoRoute(
        path: '/characters/new',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Assistant de création'))),
      ),
      GoRoute(
        path: '/characters/:id',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Text('Fiche personnage ${state.pathParameters['id']}'),
          ),
        ),
      ),
    ],
  );
}

Widget _buildTestWidget({
  required _FakeCharacterRepository characterRepository,
  required _FakeStoryInviteRepository storyInviteRepository,
}) {
  return ProviderScope(
    overrides: [
      characterRepositoryProvider.overrideWithValue(characterRepository),
      storyInviteRepositoryProvider.overrideWithValue(storyInviteRepository),
    ],
    child: MaterialApp.router(routerConfig: _buildTestRouter()),
  );
}

void main() {
  late _FakeCharacterRepository fakeCharacterRepository;
  late _FakeStoryInviteRepository fakeStoryInviteRepository;

  setUp(() {
    fakeCharacterRepository = _FakeCharacterRepository();
    fakeStoryInviteRepository = _FakeStoryInviteRepository();
  });

  testWidgets('affiche les personnages du joueur connecté', (tester) async {
    fakeCharacterRepository.charactersToReturn = const [
      CharacterSummary(
        id: '1',
        name: 'Halltesse Ambrelune',
        level: 5,
        xp: 7000,
      ),
    ];

    await tester.pumpWidget(
      _buildTestWidget(
        characterRepository: fakeCharacterRepository,
        storyInviteRepository: fakeStoryInviteRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Halltesse Ambrelune'), findsOneWidget);
    expect(find.text('Étape 3 / 4'), findsOneWidget);
  });

  testWidgets('état vide : message dédié, le bouton "+ Créer" reste affiché', (
    tester,
  ) async {
    fakeCharacterRepository.charactersToReturn = const [];

    await tester.pumpWidget(
      _buildTestWidget(
        characterRepository: fakeCharacterRepository,
        storyInviteRepository: fakeStoryInviteRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Tu n\'as pas encore de personnage à rattacher.'),
      findsOneWidget,
    );
    expect(find.text('+ CRÉER UN NOUVEAU PERSONNAGE'), findsOneWidget);
  });

  testWidgets('état d\'erreur avec bouton "Réessayer"', (tester) async {
    fakeCharacterRepository.charactersErrorToThrow = const CharacterFailure(
      'Impossible de charger vos personnages. Réessayez.',
    );

    await tester.pumpWidget(
      _buildTestWidget(
        characterRepository: fakeCharacterRepository,
        storyInviteRepository: fakeStoryInviteRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Impossible de charger vos personnages. Réessayez.'),
      findsOneWidget,
    );
    expect(find.text('RÉESSAYER'), findsOneWidget);
  });

  testWidgets(
    'tap sur une carte personnage rattache directement (pas de second tap '
    'de confirmation), affiche l\'overlay pendant l\'appel, puis navigue '
    'vers la fiche avec un SnackBar de succès',
    (tester) async {
      fakeCharacterRepository.charactersToReturn = const [
        CharacterSummary(id: '42', name: 'Borgan', level: 1, xp: 0),
      ];
      fakeStoryInviteRepository.joinCompleter = Completer<JoinStoryResult>();

      await tester.pumpWidget(
        _buildTestWidget(
          characterRepository: fakeCharacterRepository,
          storyInviteRepository: fakeStoryInviteRepository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CharacterCard));
      await tester.pump();

      expect(fakeStoryInviteRepository.joinCallCount, 1);
      expect(fakeStoryInviteRepository.lastJoinedCode, 'AB3F7K');
      expect(fakeStoryInviteRepository.lastJoinedCharacterId, '42');
      expect(find.text('Rattachement à l\'histoire...'), findsOneWidget);

      fakeStoryInviteRepository.joinCompleter!.complete(
        const JoinStoryResult(
          characterCampaignId: 'cc-1',
          joinedAt: '2026-08-30T00:00:00Z',
          characterId: '42',
          storyId: 'story-1',
          storyTitle: 'Histoire test',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fiche personnage 42'), findsOneWidget);
      expect(find.text('Histoire rejointe !'), findsOneWidget);
    },
  );

  testWidgets(
    'échec "already_joined" : referme l\'overlay, reste sur l\'étape, '
    'affiche le bandeau dédié',
    (tester) async {
      fakeCharacterRepository.charactersToReturn = const [
        CharacterSummary(id: '42', name: 'Borgan', level: 1, xp: 0),
      ];
      fakeStoryInviteRepository.joinErrorToThrow = const StoryInviteFailure(
        StoryInviteFailureKind.alreadyJoined,
      );

      await tester.pumpWidget(
        _buildTestWidget(
          characterRepository: fakeCharacterRepository,
          storyInviteRepository: fakeStoryInviteRepository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CharacterCard));
      await tester.pumpAndSettle();

      expect(
        find.text('Ce personnage est déjà rattaché à cette histoire.'),
        findsOneWidget,
      );
      expect(find.text('Rattachement à l\'histoire...'), findsNothing);
      expect(find.text('Étape 3 / 4'), findsOneWidget);
    },
  );

  testWidgets('échec générique : affiche le message générique', (tester) async {
    fakeCharacterRepository.charactersToReturn = const [
      CharacterSummary(id: '42', name: 'Borgan', level: 1, xp: 0),
    ];
    fakeStoryInviteRepository.joinErrorToThrow = StateError('boom');

    await tester.pumpWidget(
      _buildTestWidget(
        characterRepository: fakeCharacterRepository,
        storyInviteRepository: fakeStoryInviteRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CharacterCard));
    await tester.pumpAndSettle();

    expect(
      find.text('Impossible de rejoindre cette histoire. Réessayez.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'échec "invalid_code" (course improbable : code invalidé entre les '
    'étapes 2/4 et 4/4) : referme l\'overlay, reste sur l\'étape, affiche '
    'le bandeau dédié',
    (tester) async {
      fakeCharacterRepository.charactersToReturn = const [
        CharacterSummary(id: '42', name: 'Borgan', level: 1, xp: 0),
      ];
      fakeStoryInviteRepository.joinErrorToThrow = const StoryInviteFailure(
        StoryInviteFailureKind.invalidCode,
      );

      await tester.pumpWidget(
        _buildTestWidget(
          characterRepository: fakeCharacterRepository,
          storyInviteRepository: fakeStoryInviteRepository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CharacterCard));
      await tester.pumpAndSettle();

      expect(
        find.text('Ce code d\'invitation n\'est pas valide.'),
        findsOneWidget,
      );
      expect(find.text('Rattachement à l\'histoire...'), findsNothing);
      expect(find.text('Étape 3 / 4'), findsOneWidget);
    },
  );

  testWidgets(
    'échec "invite_disabled" (course improbable : invitation désactivée '
    'entre les étapes 2/4 et 4/4) : affiche le bandeau dédié',
    (tester) async {
      fakeCharacterRepository.charactersToReturn = const [
        CharacterSummary(id: '42', name: 'Borgan', level: 1, xp: 0),
      ];
      fakeStoryInviteRepository.joinErrorToThrow = const StoryInviteFailure(
        StoryInviteFailureKind.inviteDisabled,
      );

      await tester.pumpWidget(
        _buildTestWidget(
          characterRepository: fakeCharacterRepository,
          storyInviteRepository: fakeStoryInviteRepository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CharacterCard));
      await tester.pumpAndSettle();

      expect(find.text('Cette invitation a été désactivée.'), findsOneWidget);
    },
  );

  testWidgets(
    'échec "character_not_owned" (ne devrait jamais arriver en pratique — '
    'voir StoryInviteFailureKind.characterNotOwned) : traité comme '
    'générique, pas de libellé dédié',
    (tester) async {
      fakeCharacterRepository.charactersToReturn = const [
        CharacterSummary(id: '42', name: 'Borgan', level: 1, xp: 0),
      ];
      fakeStoryInviteRepository.joinErrorToThrow = const StoryInviteFailure(
        StoryInviteFailureKind.characterNotOwned,
      );

      await tester.pumpWidget(
        _buildTestWidget(
          characterRepository: fakeCharacterRepository,
          storyInviteRepository: fakeStoryInviteRepository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CharacterCard));
      await tester.pumpAndSettle();

      expect(
        find.text('Impossible de rejoindre cette histoire. Réessayez.'),
        findsOneWidget,
      );
    },
  );

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
          storyInviteRepositoryProvider.overrideWithValue(
            fakeStoryInviteRepository,
          ),
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
        '/join/step-3?code=AB3F7K',
      );
    },
  );
}
