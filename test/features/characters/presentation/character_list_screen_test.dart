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
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/characters/domain/level_up_apply_result.dart';
import 'package:personnages/features/characters/domain/level_up_choice_selection.dart';
import 'package:personnages/features/characters/domain/level_up_level_data.dart';
import 'package:personnages/features/characters/domain/rest_type.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
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
  }) {
    throw UnimplementedError();
  }
}

class _FakeAuthRepository implements AuthRepository {
  int signOutCallCount = 0;

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
}

void main() {
  late _FakeCharacterRepository fakeCharacterRepository;
  late _FakeAuthRepository fakeAuthRepository;

  setUp(() {
    fakeCharacterRepository = _FakeCharacterRepository();
    fakeAuthRepository = _FakeAuthRepository();
  });

  GoRouter buildTestRouter() {
    return GoRouter(
      initialLocation: '/',
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
          builder: (context, state) => Scaffold(
            body: Center(
              child: Text('Fiche personnage ${state.pathParameters['id']}'),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        characterRepositoryProvider.overrideWithValue(fakeCharacterRepository),
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
      ],
      child: MaterialApp.router(routerConfig: buildTestRouter()),
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
    'avant de naviguer, pour ne jamais reprendre un brouillon abandonné',
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

  testWidgets(
    'le menu profil propose de se déconnecter et appelle le dépôt auth',
    (WidgetTester tester) async {
      fakeCharacterRepository.charactersToReturn = const [];

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      expect(find.text('Se déconnecter'), findsOneWidget);

      await tester.tap(find.text('Se déconnecter'));
      await tester.pumpAndSettle();

      expect(fakeAuthRepository.signOutCallCount, 1);
    },
  );
}
