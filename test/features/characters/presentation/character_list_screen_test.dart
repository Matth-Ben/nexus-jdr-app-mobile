// Tests de widget de l'écran "Liste des personnages".
//
// Comme pour `login_screen_test.dart`, les dépôts de test
// (`_FakeCharacterRepository`/`_FakeAuthRepository`) sont injectés via
// `overrideWithValue`, pour ne jamais toucher à `Supabase.instance.client`.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/features/auth/data/auth_repository.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
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

  Widget buildTestWidget() {
    final router = GoRouter(
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

    return ProviderScope(
      overrides: [
        characterRepositoryProvider.overrideWithValue(fakeCharacterRepository),
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
      ],
      child: MaterialApp.router(routerConfig: router),
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

  testWidgets(
    'le bouton "Importer XML" affiche un message d\'information sans rien '
    'importer',
    (WidgetTester tester) async {
      fakeCharacterRepository.charactersToReturn = const [];

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('IMPORTER XML'));
      await tester.pumpAndSettle();

      expect(
        find.text('Import XML disponible dans une prochaine version.'),
        findsOneWidget,
      );
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
