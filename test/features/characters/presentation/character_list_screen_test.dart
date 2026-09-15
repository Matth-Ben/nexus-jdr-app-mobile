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
import 'package:package_info_plus/package_info_plus.dart';
import 'package:personnages/features/app_update/data/app_version_repository.dart';
import 'package:personnages/features/app_update/presentation/providers/app_version_providers.dart';
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
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/widgets/dashed_border_painter.dart';
import 'package:personnages/features/characters/presentation/character_list_screen.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/features/characters/presentation/widgets/character_card.dart';
import 'package:personnages/features/auth/presentation/providers/auth_providers.dart';

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
  Future<WriteOutcome> setInventoryItemAttuned({
    required String characterId,
    required String inventoryId,
    required bool attuned,
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
  Future<bool> signUp({
    required String email,
    required String password,
  }) async => false;

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

/// Double d'`AppVersionRepository` (`features/app_update/`) — voir la
/// documentation de classe de `UpdateSuggestedBanner` dans
/// `character_list_screen.dart::build` : la bannière "Mise à jour suggérée"
/// est insérée inconditionnellement, ce fichier ne teste donc que sa
/// présence/absence selon le statut résolu, jamais son contenu détaillé
/// (voir `test/features/app_update/presentation/widgets/update_suggested_banner_test.dart`
/// pour ça).
class _FakeAppVersionRepository implements AppVersionRepository {
  _FakeAppVersionRepository(this._row);

  final AppVersionRow _row;

  @override
  Future<AppVersionRow> fetchCurrentPlatformVersion() async => _row;
}

void main() {
  // `packageInfoProvider` (lu par `appVersionCheckProvider`, dépendance de
  // `UpdateSuggestedBanner`) : mockée une fois pour tout le fichier, même
  // convention que `profile_screen_test.dart`.
  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'Nexus JDR — Personnages',
      packageName: 'com.nexusjdr.personnages',
      version: '0.1.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  late _FakeCharacterRepository fakeCharacterRepository;
  late _FakeAuthRepository fakeAuthRepository;
  // Statut "à jour" par défaut (`installedVersion` == `latestVersion`, voir
  // `setUpAll` ci-dessus) : la bannière "Mise à jour suggérée" reste
  // invisible pour tous les tests de ce fichier qui ne la concernent pas
  // explicitement — important en particulier pour ne pas faire doublon avec
  // l'icône `Icons.close` déjà utilisée par le champ de recherche (voir le
  // groupe "recherche/filtre" plus bas).
  late _FakeAppVersionRepository fakeAppVersionRepository;

  setUp(() {
    fakeCharacterRepository = _FakeCharacterRepository();
    fakeAuthRepository = _FakeAuthRepository();
    fakeAppVersionRepository = _FakeAppVersionRepository(
      const AppVersionRow(
        minimumSupportedVersion: '0.1.0',
        latestVersion: '0.1.0',
      ),
    );
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
          // Cible du bouton "groupes" de l'en-tête
          // (`character_list_screen.dart::_GroupsButton`) — navigue
          // TOUJOURS ici, quel que soit le nombre de groupes du joueur.
          // Écran "Groupes" réel non utilisé ici (voir les tests dédiés
          // `test/features/groups/presentation/group_list_screen_test.dart`) :
          // ce fichier ne teste que la navigation déclenchée par
          // `CharacterListScreen`, pas le contenu de l'écran de destination.
          path: '/groups',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Écran Groupes'))),
        ),
      ],
    );
  }

  Widget buildTestWidget({
    RouteObserver<PageRoute<dynamic>>? routeObserver,
    AppVersionRepository? appVersionRepository,
  }) {
    final observer = routeObserver ?? RouteObserver<PageRoute<dynamic>>();
    return ProviderScope(
      overrides: [
        characterRepositoryProvider.overrideWithValue(fakeCharacterRepository),
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        routeObserverProvider.overrideWithValue(observer),
        appVersionRepositoryProvider.overrideWithValue(
          appVersionRepository ?? fakeAppVersionRepository,
        ),
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

  testWidgets('état vide "aucun personnage" : médaillon en bordure pointillée '
      'circulaire, icône explore_outlined en accentTeal (recettage direction '
      'artistique du 13/09)', (WidgetTester tester) async {
    fakeCharacterRepository.charactersToReturn = const [];

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint &&
            widget.painter is DashedBorderPainter &&
            (widget.painter! as DashedBorderPainter).shape == BoxShape.circle &&
            (widget.painter! as DashedBorderPainter).color ==
                AppColors.textOnWoodMuted,
      ),
      findsOneWidget,
    );
    final icon = tester.widget<Icon>(find.byIcon(Icons.explore_outlined));
    expect(icon.color, AppColors.accentTeal);
    expect(find.byIcon(Icons.shield_moon_outlined), findsNothing);
  });

  group(
    'échec du chargement initial : écran "Connexion impossible" '
    '(recettage direction artistique du 13/09/2026, remplace l\'ancien '
    '`_ErrorState` générique — voir `widgets/connection_error_state.dart`)',
    () {
      testWidgets(
        'affiche le bandeau "CONNEXION", le titre, le texte explicatif et '
        'l\'icône wifi barrée, quelle que soit l\'erreur levée par le dépôt',
        (WidgetTester tester) async {
          fakeCharacterRepository.errorToThrow = const CharacterFailure(
            'Session expirée, reconnecte-toi.',
          );

          await tester.pumpWidget(buildTestWidget());
          await tester.pumpAndSettle();

          expect(find.text('CONNEXION'), findsOneWidget);
          expect(find.text('Connexion impossible'), findsOneWidget);
          expect(
            find.textContaining(
              'les modifications se synchroniseront automatiquement',
            ),
            findsOneWidget,
          );
          expect(find.byIcon(Icons.wifi_off), findsOneWidget);
          // Copie statique de la maquette, jamais le message de la
          // `CharacterFailure` sous-jacente (spec de la tâche).
          expect(find.text('Session expirée, reconnecte-toi.'), findsNothing);
        },
      );

      testWidgets(
        'même écran statique quand le dépôt lève une exception qui n\'est '
        'pas une CharacterFailure',
        (WidgetTester tester) async {
          fakeCharacterRepository.errorToThrow = StateError('boom réseau');

          await tester.pumpWidget(buildTestWidget());
          await tester.pumpAndSettle();

          expect(find.text('Connexion impossible'), findsOneWidget);
        },
      );

      testWidgets('le bouton "RÉESSAYER" relance la requête', (
        WidgetTester tester,
      ) async {
        fakeCharacterRepository.errorToThrow = const CharacterFailure(
          'Impossible de charger vos personnages. Réessayez.',
        );

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();
        expect(fakeCharacterRepository.fetchCallCount, 1);

        await tester.tap(find.text('RÉESSAYER'));
        await tester.pumpAndSettle();

        expect(fakeCharacterRepository.fetchCallCount, 2);
      });

      testWidgets('un nouvel échec après "RÉESSAYER" réaffiche le même écran '
          '"Connexion impossible" (pas de crash, pas de retour à la liste)', (
        WidgetTester tester,
      ) async {
        fakeCharacterRepository.errorToThrow = const CharacterFailure(
          'Impossible de charger vos personnages. Réessayez.',
        );

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('RÉESSAYER'));
        await tester.pumpAndSettle();

        expect(find.text('Connexion impossible'), findsOneWidget);
        expect(fakeCharacterRepository.fetchCallCount, 2);
      });

      testWidgets('affiche le lien "Continuer hors ligne", visuellement neutre '
          '(aucun fallback cache réel tant que la Phase 4 n\'est pas livrée '
          '— voir `widgets/connection_error_state.dart`)', (
        WidgetTester tester,
      ) async {
        fakeCharacterRepository.errorToThrow = const CharacterFailure(
          'Impossible de charger vos personnages. Réessayez.',
        );

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Continuer hors ligne'), findsOneWidget);
        expect(
          find.ancestor(
            of: find.text('Continuer hors ligne'),
            matching: find.byType(Tooltip),
          ),
          findsOneWidget,
        );
      });

      testWidgets('aucune flèche retour dans le bandeau "CONNEXION" : '
          '`CharacterListScreen` est l\'écran d\'accueil (route `/`), rien de '
          'cohérent vers quoi revenir (écart assumé par rapport à la maquette, '
          'voir la documentation de classe de `ConnectionErrorState`)', (
        WidgetTester tester,
      ) async {
        fakeCharacterRepository.errorToThrow = const CharacterFailure(
          'Impossible de charger vos personnages. Réessayez.',
        );

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
      });
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
    'le bouton "Rejoindre une histoire" est masqué (fonctionnalité mise de '
    'côté le temps du reste du recettage direction-artistique — voir le '
    'commentaire de `character_list_screen.dart::build`)',
    (WidgetTester tester) async {
      fakeCharacterRepository.charactersToReturn = const [];

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('REJOINDRE UNE HISTOIRE'), findsNothing);
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
          appVersionRepositoryProvider.overrideWithValue(
            fakeAppVersionRepository,
          ),
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
      'navigue toujours vers l\'écran "Groupes" (/groups), quel que soit '
      'le nombre de groupes du joueur (voir les tests dédiés de '
      'group_list_screen_test.dart pour le contenu de cet écran)',
      (WidgetTester tester) async {
        fakeCharacterRepository.charactersToReturn = const [];

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.groups_outlined));
        await tester.pumpAndSettle();

        expect(find.text('Écran Groupes'), findsOneWidget);
      },
    );
  });

  testWidgets(
    'en-tête : le bouton "groupes" est affiché à gauche du bouton "profil" '
    '(conforme à la maquette "Liste des personnages" de '
    '`09-maquettes-captures.md`, recettage direction artistique du 13/09)',
    (WidgetTester tester) async {
      fakeCharacterRepository.charactersToReturn = const [];

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final groupsX = tester.getTopLeft(find.byIcon(Icons.groups_outlined)).dx;
      final profileX = tester
          .getTopLeft(find.byIcon(Icons.person_outline).last)
          .dx;

      expect(
        groupsX,
        lessThan(profileX),
        reason:
            'le bouton "groupes" doit précéder le bouton "profil" '
            'horizontalement dans l\'en-tête',
      );
    },
  );

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
      'état "aucun résultat" : médaillon en bordure pointillée circulaire '
      '(recettage direction artistique du 13/09)',
      (WidgetTester tester) async {
        fakeCharacterRepository.charactersToReturn = characters;

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Rechercher un personnage'),
          'Zar',
        );
        await tester.pumpAndSettle();

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is CustomPaint &&
                widget.painter is DashedBorderPainter &&
                (widget.painter! as DashedBorderPainter).shape ==
                    BoxShape.circle &&
                (widget.painter! as DashedBorderPainter).color ==
                    AppColors.textOnWoodMuted,
          ),
          findsOneWidget,
        );
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

    testWidgets('recherche ET filtre de classe combinés (intersection)', (
      WidgetTester tester,
    ) async {
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
    });
  });

  group('bannière "Mise à jour suggérée" (`UpdateSuggestedBanner`, recettage '
      'direction-artistique du 13/09/2026) — insérée entre l\'en-tête et la '
      'barre de recherche, contenu détaillé testé séparément dans '
      'update_suggested_banner_test.dart', () {
    testWidgets('invisible par défaut (statut "à jour", voir le double '
        '`_FakeAppVersionRepository` par défaut de `setUp`)', (tester) async {
      fakeCharacterRepository.charactersToReturn = const [];

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Nouvelle version disponible'), findsNothing);
    });

    testWidgets('visible entre l\'en-tête ("TES AVENTURIERS") et la barre de '
        'recherche quand une mise à jour est suggérée', (tester) async {
      fakeCharacterRepository.charactersToReturn = const [];

      await tester.pumpWidget(
        buildTestWidget(
          appVersionRepository: _FakeAppVersionRepository(
            const AppVersionRow(
              minimumSupportedVersion: '0.1.0',
              latestVersion: '0.5.0',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nouvelle version disponible'), findsOneWidget);

      final headerY = tester.getBottomLeft(find.text('TES AVENTURIERS')).dy;
      final bannerY = tester
          .getTopLeft(find.text('Nouvelle version disponible'))
          .dy;
      final searchY = tester
          .getTopLeft(
            find.widgetWithText(TextField, 'Rechercher un personnage'),
          )
          .dy;

      expect(
        headerY,
        lessThan(bannerY),
        reason: 'la bannière doit être sous l\'en-tête',
      );
      expect(
        bannerY,
        lessThan(searchY),
        reason:
            'la bannière doit être au-dessus de la barre de '
            'recherche',
      );
    });

    testWidgets(
      'invisible quand une mise à jour est obligatoire (c\'est l\'écran '
      'bloquant `ForceUpdateScreen` qui prend le relais avant même '
      'd\'atteindre cet écran, jamais la bannière)',
      (tester) async {
        fakeCharacterRepository.charactersToReturn = const [];

        await tester.pumpWidget(
          buildTestWidget(
            appVersionRepository: _FakeAppVersionRepository(
              const AppVersionRow(
                minimumSupportedVersion: '0.5.0',
                latestVersion: '0.6.0',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Nouvelle version disponible'), findsNothing);
      },
    );
  });
}
