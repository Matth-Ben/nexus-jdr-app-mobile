// Tests de widget de l'écran "Liste des personnages".
//
// Comme pour `login_screen_test.dart`, les dépôts de test
// (`_FakeCharacterRepository`/`_FakeAuthRepository`) sont injectés via
// `overrideWithValue`, pour ne jamais toucher à `Supabase.instance.client`.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/features/auth/data/auth_repository.dart';
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
import 'package:personnages/features/characters/domain/level_up_feat_option.dart';
import 'package:personnages/features/characters/domain/level_up_invocation_option.dart';
import 'package:personnages/features/characters/domain/level_up_choice_selection.dart';
import 'package:personnages/features/characters/domain/level_up_level_data.dart';
import 'package:personnages/features/characters/domain/rest_type.dart';
import 'package:personnages/features/characters/domain/reward_item_draft.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/core/router/route_observer_provider.dart';
import 'package:personnages/features/characters/presentation/character_list_screen.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/features/characters/presentation/widgets/character_card.dart';
import 'package:personnages/features/auth/presentation/providers/auth_providers.dart';
import 'package:personnages/features/groups/data/group_repository.dart';
import 'package:personnages/features/groups/domain/created_group.dart';
import 'package:personnages/features/groups/domain/group_detail.dart';
import 'package:personnages/features/groups/domain/group_preview.dart';
import 'package:personnages/features/groups/domain/group_summary.dart';
import 'package:personnages/features/groups/domain/group_treasure.dart';
import 'package:personnages/features/groups/domain/group_treasure_item.dart';
import 'package:personnages/features/groups/domain/joined_group.dart';
import 'package:personnages/features/groups/presentation/providers/group_providers.dart';

class _FakeCharacterRepository implements CharacterRepository {
  int fetchCallCount = 0;
  List<CharacterSummary>? charactersToReturn;
  Object? errorToThrow;
  Completer<List<CharacterSummary>>? completer;

  @override
  Future<List<CharacterSummary>> fetchCharacters() async {
    fetchCallCount++;
    if (completer != null) {
      return completer!.future;
    }
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return charactersToReturn ?? const [];
  }

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> setDead({
    required String characterId,
    required bool isDead,
  }) {
    throw UnimplementedError();
  }

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
    bool isPactSlot = false,
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

/// Double minimal de `GroupRepository` — seul `fetchMyGroups` est exercé par
/// les tests de `_GroupsButton` (`character_list_screen.dart`) ci-dessous,
/// tout le reste lève `UnimplementedError` (jamais appelé depuis cet écran).
class _FakeGroupRepository implements GroupRepository {
  List<GroupSummary>? groupsToReturn;
  Object? errorToThrow;

  @override
  Future<List<GroupSummary>> fetchMyGroups() async {
    if (errorToThrow != null) throw errorToThrow!;
    return groupsToReturn ?? const [];
  }

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

class _FakeAuthRepository implements AuthRepository {
  int signOutCallCount = 0;

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signUp({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {
    signOutCallCount++;
  }

  @override
  Future<void> resetPasswordForEmail({required String email}) async {}

  @override
  Future<void> updateDisplayName({required String? displayName}) async {}

  @override
  Future<void> updatePassword({required String newPassword}) async {}

  @override
  Future<void> updateEmail({required String newEmail}) async {}

  @override
  Future<String> updateAvatar({required Uint8List bytes}) async => '';

  @override
  Future<void> removeAvatar() async {}
}

void main() {
  late _FakeCharacterRepository fakeCharacterRepository;
  late _FakeAuthRepository fakeAuthRepository;
  late _FakeGroupRepository fakeGroupRepository;

  setUp(() {
    fakeCharacterRepository = _FakeCharacterRepository();
    fakeAuthRepository = _FakeAuthRepository();
    fakeGroupRepository = _FakeGroupRepository();
  });

  GoRouter buildTestRouter({List<NavigatorObserver> observers = const []}) {
    return GoRouter(
      initialLocation: '/',
      observers: observers,
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const CharacterListScreen(),
        ),
        GoRoute(
          path: '/characters/new',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Assistant de création')),
          ),
        ),
        GoRoute(
          path: '/characters/:id',
          // Un bouton "Retour" explicite (plutôt que de compter sur la
          // flèche `AppBar` par défaut, absente ici) : simule le pop vers
          // `CharacterListScreen` déclenché en vrai depuis
          // `character_detail_screen.dart` — voir les tests
          // "RouteAware.didPopNext" plus bas, qui vérifient que ce pop
          // relance `charactersProvider`.
          builder: (context, state) => Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Fiche personnage ${state.pathParameters['id']}'),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Retour'),
                  ),
                ],
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/join',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Rejoindre une histoire — étape 1')),
          ),
        ),
        GoRoute(
          // Cible du bouton profil rond de l'en-tête
          // (`character_list_screen.dart::_ProfileButton`) — voir le test
          // "le bouton profil navigue vers l'écran Profil" plus bas.
          // `ProfileScreen` réel non utilisé ici : ce fichier ne teste que
          // la navigation déclenchée par `CharacterListScreen`, pas le
          // contenu de l'écran de destination (voir
          // `test/features/profile/presentation/profile_screen_test.dart`).
          path: '/profile',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Écran Profil'))),
        ),
        GoRoute(
          // Cible de "Créer un groupe" (sheet "GROUPE", 0 groupe). Déclarée
          // AVANT `/groups/:id` ci-dessous : `go_router` fait correspondre
          // les routes dans l'ordre de déclaration, un `/groups/:id` déclaré
          // en premier absorberait `/groups/new` (id = "new") avant que ce
          // literal n'ait sa chance — même ordre que `core/router/
          // app_router.dart`.
          path: '/groups/new',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Créer un groupe'))),
        ),
        GoRoute(
          // Cible de "Rejoindre un groupe" (sheet "GROUPE", 0 groupe).
          path: '/groups/join',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Rejoindre un groupe'))),
        ),
        GoRoute(
          // Cible du bouton "groupes" de l'en-tête
          // (`character_list_screen.dart::_GroupsButton`) quand le joueur
          // est déjà membre d'exactement un groupe (navigation directe) ou
          // choisit un groupe dans la sheet listant plusieurs groupes —
          // écran "Groupe" réel non utilisé ici (voir les tests
          // dédiés de `features/groups/`).
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

  Widget buildTestWidget({RouteObserver<PageRoute<dynamic>>? routeObserver}) {
    final observer = routeObserver ?? RouteObserver<PageRoute<dynamic>>();
    return ProviderScope(
      overrides: [
        characterRepositoryProvider.overrideWithValue(fakeCharacterRepository),
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        groupRepositoryProvider.overrideWithValue(fakeGroupRepository),
        routeObserverProvider.overrideWithValue(observer),
      ],
      child: MaterialApp.router(
        routerConfig: buildTestRouter(observers: [observer]),
      ),
    );
  }

  testWidgets('affiche un indicateur de chargement pendant la récupération', (
    WidgetTester tester,
  ) async {
    fakeCharacterRepository.completer = Completer<List<CharacterSummary>>();

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('affiche les personnages retournés par le dépôt', (
    WidgetTester tester,
  ) async {
    fakeCharacterRepository.charactersToReturn = const [
      CharacterSummary(
        id: '1',
        name: 'Halltesse Ambrelune',
        raceName: 'Elfe',
        className: 'Magicienne',
        level: 5,
        xp: 7000,
      ),
      CharacterSummary(
        id: '2',
        name: 'Borgan Pierrefort',
        raceName: 'Nain',
        className: 'Guerrier',
        level: 3,
        xp: 1200,
      ),
    ];

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Halltesse Ambrelune'), findsOneWidget);
    expect(find.text('Elfe · Magicienne · Niv. 5'), findsOneWidget);
    expect(find.text('Borgan Pierrefort'), findsOneWidget);
    expect(find.text('Nain · Guerrier · Niv. 3'), findsOneWidget);
    expect(find.text('XP'), findsNWidgets(2));
  });

  testWidgets(
    'un personnage sans race/classe résolues affiche seulement le niveau',
    (WidgetTester tester) async {
      fakeCharacterRepository.charactersToReturn = const [
        CharacterSummary(id: '1', name: 'Sylvi Aubefeuille', level: 1, xp: 0),
      ];

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Sylvi Aubefeuille'), findsOneWidget);
      expect(find.text('Niv. 1'), findsOneWidget);
    },
  );

  testWidgets(
    'un personnage avec seulement une classe résolue (race personnalisée '
    'non résolue) affiche "Classe · Niv. X" sans le segment race',
    (WidgetTester tester) async {
      fakeCharacterRepository.charactersToReturn = const [
        CharacterSummary(
          id: '1',
          name: 'Kaeloth',
          className: 'Barde',
          level: 2,
          xp: 500,
        ),
      ];

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Barde · Niv. 2'), findsOneWidget);
    },
  );

  testWidgets(
    'un personnage avec seulement une race résolue (personnage sans classe '
    'enregistrée) affiche "Race · Niv. X" sans le segment classe',
    (WidgetTester tester) async {
      fakeCharacterRepository.charactersToReturn = const [
        CharacterSummary(
          id: '1',
          name: 'Orim',
          raceName: 'Demi-orque',
          // Niveau 1 : repli documenté du dépôt pour un personnage sans
          // ligne `character_classes` (voir `character_repository.dart`).
          level: 1,
          xp: 0,
        ),
      ];

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Demi-orque · Niv. 1'), findsOneWidget);
    },
  );

  testWidgets(
    'un personnage sans portrait affiche l\'icône de substitution générique '
    'dans la liste (docs/cahier-des-charges/04-fonctionnalites-app-mobile.md '
    'section 2)',
    (WidgetTester tester) async {
      fakeCharacterRepository.charactersToReturn = const [
        CharacterSummary(id: '1', name: 'Sylvi Aubefeuille', level: 1, xp: 0),
      ];

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // `Icons.person_outline` est aussi utilisé par le bouton profil de
      // l'en-tête : on restreint la recherche aux icônes à l'intérieur d'une
      // carte personnage pour ne cibler que le portrait de substitution.
      expect(
        find.descendant(
          of: find.byType(CharacterCard),
          matching: find.byIcon(Icons.person_outline),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'un personnage avec un portrait défini construit une image réseau '
    'configurée sur son URL (`characters.portrait_url`)',
    (WidgetTester tester) async {
      const portraitUrl = 'https://example.com/halltesse.jpg';
      fakeCharacterRepository.charactersToReturn = const [
        CharacterSummary(
          id: '1',
          name: 'Halltesse Ambrelune',
          portraitUrl: portraitUrl,
          raceName: 'Elfe',
          className: 'Magicienne',
          level: 5,
          xp: 7000,
        ),
      ];

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // `flutter test` ne fait aucune requête réseau réelle (voir
      // `test/core/widgets/portrait_frame_test.dart` pour le détail) : on
      // vérifie donc la configuration de l'image demandée, pas le rendu
      // pixel final, qui dépend d'un vrai téléchargement hors périmètre de
      // ce test.
      final image = tester.widget<Image>(
        find.descendant(
          of: find.byType(CharacterCard),
          matching: find.byType(Image),
        ),
      );
      expect((image.image as NetworkImage).url, portraitUrl);
    },
  );

  testWidgets('affiche un état vide quand le joueur n\'a aucun personnage', (
    WidgetTester tester,
  ) async {
    fakeCharacterRepository.charactersToReturn = const [];

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.textContaining('AUCUN AVENTURIER'), findsOneWidget);
  });

  testWidgets(
    'affiche un état d\'erreur avec un bouton "Réessayer" qui relance la '
    'requête',
    (WidgetTester tester) async {
      fakeCharacterRepository.errorToThrow = const CharacterFailure(
        'Impossible de charger vos personnages. Réessayez.',
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('Impossible de charger vos personnages. Réessayez.'),
        findsOneWidget,
      );
      expect(fakeCharacterRepository.fetchCallCount, 1);

      await tester.tap(find.text('RÉESSAYER'));
      await tester.pumpAndSettle();

      expect(fakeCharacterRepository.fetchCallCount, 2);
    },
  );

  testWidgets(
    'affiche un message d\'erreur générique (et le bouton "Réessayer") '
    'quand le dépôt lève une exception qui n\'est pas une CharacterFailure',
    (WidgetTester tester) async {
      fakeCharacterRepository.errorToThrow = StateError('boom réseau');

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('Impossible de charger vos personnages. Réessayez.'),
        findsOneWidget,
      );

      await tester.tap(find.text('RÉESSAYER'));
      await tester.pumpAndSettle();

      expect(fakeCharacterRepository.fetchCallCount, 2);
    },
  );

  testWidgets('le bouton "Importer XML" ouvre le sélecteur de fichier natif et '
      'affiche un message d\'erreur si aucun plugin n\'est disponible '
      '(environnement de test)', (WidgetTester tester) async {
    // `file_picker` n'a pas d'implémentation de plateforme enregistrée
    // sous `flutter test` (pas de mock de canal ici) : `pickFiles()` lève
    // une `MissingPluginException`, capturée par
    // `CharacterListScreen._startXmlImport` — ce test vérifie donc le
    // chemin d'erreur réel de cet environnement plutôt que le chemin
    // "sélection réussie" (nécessiterait de mocker le `MethodChannel` du
    // plugin, hors périmètre de ce test ciblé sur `CharacterListScreen`
    // elle-même ; voir `test/features/xml_import/` pour les tests de
    // l'écran de vérification qui suit une sélection réussie).
    fakeCharacterRepository.charactersToReturn = const [];

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('IMPORTER XML'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Impossible de lire ce fichier'),
      findsOneWidget,
    );
  });

  testWidgets(
    'le bouton "Rejoindre une histoire" navigue vers le flux "Rejoindre une '
    'histoire"',
    (WidgetTester tester) async {
      fakeCharacterRepository.charactersToReturn = const [];

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('REJOINDRE UNE HISTOIRE'));
      await tester.pumpAndSettle();

      expect(find.text('Rejoindre une histoire — étape 1'), findsOneWidget);
    },
  );

  testWidgets('le bouton "+ Créer" navigue vers l\'assistant de création', (
    WidgetTester tester,
  ) async {
    fakeCharacterRepository.charactersToReturn = const [];

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('+ CRÉER'));
    await tester.pumpAndSettle();

    expect(find.text('Assistant de création'), findsOneWidget);
  });

  testWidgets(
    'le bouton "+ Créer" réinitialise le brouillon de création en mémoire '
    'et efface toute route de retour laissée par une session "Rejoindre '
    'une histoire" abandonnée, avant de naviguer',
    (WidgetTester tester) async {
      fakeCharacterRepository.charactersToReturn = const [];

      final container = ProviderContainer(
        overrides: [
          characterRepositoryProvider.overrideWithValue(
            fakeCharacterRepository,
          ),
          authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        ],
      );
      addTearDown(container.dispose);
      // Simule un brouillon abandonné d'une session précédente.
      container
          .read(characterCreationDraftControllerProvider.notifier)
          .setRace(raceId: 7, subraceId: 3);
      // Simule une route de retour laissée par une session "Rejoindre une
      // histoire" abandonnée avant l'étape 9 (voir la documentation de
      // classe de `CharacterCreationReturnRouteController`) — une création
      // lancée normalement depuis cet écran ne doit jamais la reprendre.
      container
          .read(characterCreationReturnRouteControllerProvider.notifier)
          .set('/join/step-3?code=AB3F7K');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: buildTestRouter()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('+ CRÉER'));
      await tester.pumpAndSettle();

      expect(
        container.read(characterCreationDraftControllerProvider),
        const CharacterCreationDraft(),
      );
      expect(
        container.read(characterCreationReturnRouteControllerProvider),
        isNull,
      );
    },
  );

  testWidgets(
    'taper une carte personnage navigue vers sa fiche (/characters/:id)',
    (WidgetTester tester) async {
      fakeCharacterRepository.charactersToReturn = const [
        CharacterSummary(
          id: '42',
          name: 'Halltesse Ambrelune',
          level: 5,
          xp: 7000,
        ),
      ];

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CharacterCard));
      await tester.pumpAndSettle();

      expect(find.text('Fiche personnage 42'), findsOneWidget);
    },
  );

  group('RouteAware.didPopNext (rafraîchissement au retour d\'un écran poussé '
      'par-dessus la liste, ex. fiche personnage/montée de niveau)', () {
    testWidgets(
      'revenir de la fiche personnage (pop) relance charactersProvider, '
      'même sans aucune interaction explicite de rafraîchissement',
      (WidgetTester tester) async {
        fakeCharacterRepository.charactersToReturn = const [
          CharacterSummary(
            id: '42',
            name: 'Halltesse Ambrelune',
            level: 5,
            xp: 7000,
          ),
        ];
        final observer = RouteObserver<PageRoute<dynamic>>();

        await tester.pumpWidget(buildTestWidget(routeObserver: observer));
        await tester.pumpAndSettle();
        expect(fakeCharacterRepository.fetchCallCount, 1);

        await tester.tap(find.byType(CharacterCard));
        await tester.pumpAndSettle();
        expect(find.text('Fiche personnage 42'), findsOneWidget);

        // Simule un level-up (ou toute autre écriture) appliqué depuis la
        // fiche : la prochaine requête réseau renverrait un niveau à jour,
        // exactement comme le ferait Supabase après une écriture réussie.
        fakeCharacterRepository.charactersToReturn = const [
          CharacterSummary(
            id: '42',
            name: 'Halltesse Ambrelune',
            level: 6,
            xp: 14000,
          ),
        ];

        await tester.tap(find.text('Retour'));
        await tester.pumpAndSettle();

        expect(find.text('Elfe · Magicienne · Niv. 6'), findsNothing);
        expect(find.text('Niv. 6'), findsOneWidget);
        expect(
          fakeCharacterRepository.fetchCallCount,
          2,
          reason:
              'le retour de la fiche (pop) doit déclencher un nouveau '
              'fetch, sans quoi la carte resterait sur le niveau '
              'obsolète (Niv. 5)',
        );
      },
    );

    testWidgets('un pop en cascade depuis un écran poussé par-dessus la fiche '
        '(ex. "Montée de niveau") relance aussi charactersProvider une '
        'fois revenu sur la liste', (WidgetTester tester) async {
      fakeCharacterRepository.charactersToReturn = const [
        CharacterSummary(
          id: '42',
          name: 'Borgan Pierrefort',
          level: 3,
          xp: 900,
        ),
      ];
      final observer = RouteObserver<PageRoute<dynamic>>();

      await tester.pumpWidget(buildTestWidget(routeObserver: observer));
      await tester.pumpAndSettle();
      expect(fakeCharacterRepository.fetchCallCount, 1);

      await tester.tap(find.byType(CharacterCard));
      await tester.pumpAndSettle();
      expect(find.text('Fiche personnage 42'), findsOneWidget);

      fakeCharacterRepository.charactersToReturn = const [
        CharacterSummary(
          id: '42',
          name: 'Borgan Pierrefort',
          level: 4,
          xp: 2700,
        ),
      ];

      // Pop direct de la fiche vers la liste (le flux réel "Montée de
      // niveau" empile une route supplémentaire par-dessus la fiche puis
      // dépile jusqu'à la liste ; `didPopNext` se déclenche de la même
      // façon dans les deux cas — seul compte le fait que cet écran
      // redevienne visible après un pop, peu importe la profondeur de la
      // pile dépilée, voir la documentation de classe de
      // `CharacterListScreen`).
      await tester.tap(find.text('Retour'));
      await tester.pumpAndSettle();

      expect(find.text('Niv. 4'), findsOneWidget);
      expect(fakeCharacterRepository.fetchCallCount, 2);
    });

    testWidgets(
      'un simple retour depuis la fiche personnage SANS aucune écriture '
      'ne casse rien : refetch inoffensif (redondant mais sans effet '
      "visible), pas de crash au démontage de l'écran",
      (WidgetTester tester) async {
        const unchanged = [
          CharacterSummary(
            id: '42',
            name: 'Halltesse Ambrelune',
            level: 5,
            xp: 7000,
          ),
        ];
        fakeCharacterRepository.charactersToReturn = unchanged;
        final observer = RouteObserver<PageRoute<dynamic>>();

        await tester.pumpWidget(buildTestWidget(routeObserver: observer));
        await tester.pumpAndSettle();
        expect(fakeCharacterRepository.fetchCallCount, 1);

        await tester.tap(find.byType(CharacterCard));
        await tester.pumpAndSettle();
        expect(find.text('Fiche personnage 42'), findsOneWidget);

        // Aucune écriture simulée ici (`charactersToReturn` inchangé) :
        // simple consultation de la fiche puis retour immédiat.
        await tester.tap(find.text('Retour'));
        await tester.pumpAndSettle();

        // Refetch quand même déclenché (comportement voulu, documenté sur
        // `CharacterListScreen` : pas d'optimisation pour éviter un
        // refetch inutile), mais sans régression visible : la carte
        // affiche toujours les mêmes données, aucune exception levée
        // pendant le pop (ce test échouerait sinon, `tester.pumpAndSettle`
        // remonte toute exception non interceptée).
        expect(find.text('Halltesse Ambrelune'), findsOneWidget);
        expect(find.text('Niv. 5'), findsOneWidget);
        expect(fakeCharacterRepository.fetchCallCount, 2);
      },
    );

    testWidgets(
      'ne relance pas charactersProvider au premier affichage (pas de '
      'pop encore survenu)',
      (WidgetTester tester) async {
        fakeCharacterRepository.charactersToReturn = const [];

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(fakeCharacterRepository.fetchCallCount, 1);
      },
    );
  });

  testWidgets(
    'le bouton profil rond navigue vers l\'écran "Profil" (route /profile) '
    '— remplace l\'ancien menu minimal "Se déconnecter" (déplacé sur cet '
    'écran, voir `test/features/profile/presentation/profile_screen_test.dart`)',
    (WidgetTester tester) async {
      fakeCharacterRepository.charactersToReturn = const [];

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      expect(find.text('Écran Profil'), findsOneWidget);
    },
  );

  group('bouton "groupes" (_GroupsButton)', () {
    testWidgets(
      '0 groupe : ouvre la sheet "GROUPE" avec les 2 actions Créer/Rejoindre',
      (WidgetTester tester) async {
        fakeCharacterRepository.charactersToReturn = const [];
        fakeGroupRepository.groupsToReturn = const [];

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.groups_outlined));
        await tester.pumpAndSettle();

        expect(find.text('GROUPE'), findsOneWidget);
        expect(find.text('CRÉER UN GROUPE'), findsOneWidget);
        expect(find.text('REJOINDRE UN GROUPE'), findsOneWidget);
      },
    );

    testWidgets('0 groupe : "Créer un groupe" navigue vers /groups/new', (
      WidgetTester tester,
    ) async {
      fakeCharacterRepository.charactersToReturn = const [];
      fakeGroupRepository.groupsToReturn = const [];

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.groups_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CRÉER UN GROUPE'));
      await tester.pumpAndSettle();

      expect(find.text('Créer un groupe'), findsOneWidget);
    });

    testWidgets('0 groupe : "Rejoindre un groupe" navigue vers /groups/join', (
      WidgetTester tester,
    ) async {
      fakeCharacterRepository.charactersToReturn = const [];
      fakeGroupRepository.groupsToReturn = const [];

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.groups_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('REJOINDRE UN GROUPE'));
      await tester.pumpAndSettle();

      expect(find.text('Rejoindre un groupe'), findsOneWidget);
    });

    testWidgets(
      '1 groupe : navigue directement vers l\'écran "Groupe" de ce groupe, '
      'sans sheet intermédiaire',
      (WidgetTester tester) async {
        fakeCharacterRepository.charactersToReturn = const [];
        fakeGroupRepository.groupsToReturn = const [
          GroupSummary(id: 'group-1', name: 'Les Lames', memberCount: 2),
        ];

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.groups_outlined));
        await tester.pumpAndSettle();

        expect(find.text('Écran Groupe group-1'), findsOneWidget);
        expect(find.text('GROUPE'), findsNothing);
      },
    );

    testWidgets(
      '2+ groupes : ouvre une sheet listant les groupes (nom + membres), '
      'taper une ligne navigue vers son écran "Groupe"',
      (WidgetTester tester) async {
        fakeCharacterRepository.charactersToReturn = const [];
        fakeGroupRepository.groupsToReturn = const [
          GroupSummary(id: 'group-1', name: 'Les Lames', memberCount: 2),
          GroupSummary(id: 'group-2', name: 'Les Ombres', memberCount: 4),
        ];

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.groups_outlined));
        await tester.pumpAndSettle();

        expect(find.text('Les Lames'), findsOneWidget);
        expect(find.text('2 membres'), findsOneWidget);
        expect(find.text('Les Ombres'), findsOneWidget);
        expect(find.text('4 membres'), findsOneWidget);

        await tester.tap(find.text('Les Ombres'));
        await tester.pumpAndSettle();

        expect(find.text('Écran Groupe group-2'), findsOneWidget);
      },
    );

    testWidgets(
      'échec réseau : affiche un SnackBar générique, sans navigation',
      (WidgetTester tester) async {
        fakeCharacterRepository.charactersToReturn = const [];
        fakeGroupRepository.errorToThrow = Exception('boom');

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.groups_outlined));
        await tester.pumpAndSettle();

        expect(
          find.text('Impossible de charger vos groupes. Réessayez.'),
          findsOneWidget,
        );
      },
    );
  });

  group('recherche/filtre (docs/cahier-des-charges/'
      '11-fonctionnalites-a-ajouter.md section 2)', () {
    const characters = [
      CharacterSummary(
        id: '1',
        name: 'Halltesse Ambrelune',
        className: 'Magicien',
        level: 5,
        xp: 7000,
      ),
      CharacterSummary(
        id: '2',
        name: 'Borgan Pierrefort',
        className: 'Guerrier',
        level: 3,
        xp: 1200,
      ),
      CharacterSummary(
        id: '3',
        name: 'Sylvi Aubefeuille',
        className: 'Roublard',
        level: 1,
        xp: 0,
      ),
    ];

    testWidgets(
      'taper dans le champ de recherche ne garde que les personnages dont '
      'le nom correspond',
      (WidgetTester tester) async {
        fakeCharacterRepository.charactersToReturn = characters;

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Rechercher un personnage'),
          'borgan',
        );
        await tester.pumpAndSettle();

        expect(find.text('Halltesse Ambrelune'), findsNothing);
        expect(find.text('Borgan Pierrefort'), findsOneWidget);
        expect(find.text('Sylvi Aubefeuille'), findsNothing);
      },
    );

    testWidgets(
      'aucun résultat pour la recherche : affiche l\'état dédié avec la '
      'requête, "Réinitialiser" restaure la liste complète',
      (WidgetTester tester) async {
        fakeCharacterRepository.charactersToReturn = characters;

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Rechercher un personnage'),
          'Zar',
        );
        await tester.pumpAndSettle();

        expect(find.text('AUCUN RÉSULTAT POUR « ZAR »'), findsOneWidget);
        expect(find.text('Halltesse Ambrelune'), findsNothing);

        await tester.tap(find.text('RÉINITIALISER'));
        await tester.pumpAndSettle();

        expect(find.text('Halltesse Ambrelune'), findsOneWidget);
        expect(find.text('Borgan Pierrefort'), findsOneWidget);
        expect(find.text('Sylvi Aubefeuille'), findsOneWidget);
      },
    );

    testWidgets(
      'icône "×" du champ efface la recherche et restaure la liste complète',
      (WidgetTester tester) async {
        fakeCharacterRepository.charactersToReturn = characters;

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Rechercher un personnage'),
          'borgan',
        );
        await tester.pumpAndSettle();
        expect(find.text('Halltesse Ambrelune'), findsNothing);

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(find.text('Halltesse Ambrelune'), findsOneWidget);
        expect(find.text('Borgan Pierrefort'), findsOneWidget);
      },
    );

    testWidgets(
      'icône filtre : ouvre la sheet "FILTRER PAR CLASSE", cocher une '
      'classe puis "Appliquer" ne garde que les personnages de cette classe',
      (WidgetTester tester) async {
        fakeCharacterRepository.charactersToReturn = characters;

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.filter_list));
        await tester.pumpAndSettle();

        expect(find.text('FILTRER PAR CLASSE'), findsOneWidget);
        expect(find.text('Magicien'), findsOneWidget);
        expect(find.text('Guerrier'), findsOneWidget);
        expect(find.text('Roublard'), findsOneWidget);

        await tester.tap(find.text('Guerrier'));
        await tester.tap(find.text('APPLIQUER'));
        await tester.pumpAndSettle();

        expect(find.text('Halltesse Ambrelune'), findsNothing);
        expect(find.text('Borgan Pierrefort'), findsOneWidget);
        expect(find.text('Sylvi Aubefeuille'), findsNothing);
      },
    );

    testWidgets(
      'sheet de filtre : "Réinitialiser" vide la sélection avant même de '
      'fermer la sheet',
      (WidgetTester tester) async {
        fakeCharacterRepository.charactersToReturn = characters;

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.filter_list));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Guerrier'));
        await tester.tap(find.text('APPLIQUER'));
        await tester.pumpAndSettle();
        expect(find.text('Halltesse Ambrelune'), findsNothing);

        await tester.tap(find.byIcon(Icons.filter_list));
        await tester.pumpAndSettle();
        await tester.tap(find.text('RÉINITIALISER'));
        await tester.tap(find.text('APPLIQUER'));
        await tester.pumpAndSettle();

        expect(find.text('Halltesse Ambrelune'), findsOneWidget);
        expect(find.text('Borgan Pierrefort'), findsOneWidget);
        expect(find.text('Sylvi Aubefeuille'), findsOneWidget);
      },
    );

    testWidgets(
      'recherche ET filtre de classe combinés (intersection)',
      (WidgetTester tester) async {
        fakeCharacterRepository.charactersToReturn = characters;

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.filter_list));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Roublard'));
        await tester.tap(find.text('APPLIQUER'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Rechercher un personnage'),
          'Sylvi',
        );
        await tester.pumpAndSettle();
        expect(find.text('Sylvi Aubefeuille'), findsOneWidget);

        await tester.enterText(
          find.widgetWithText(TextField, 'Rechercher un personnage'),
          'Borgan',
        );
        await tester.pumpAndSettle();
        expect(find.text('Borgan Pierrefort'), findsNothing);
        expect(find.textContaining('AUCUN RÉSULTAT'), findsOneWidget);
      },
    );
  });
}
