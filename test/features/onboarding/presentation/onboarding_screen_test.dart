// Tests de widget du carousel de bienvenue/onboarding
// (`presentation/onboarding_screen.dart`) :
// - les 5 pages s'affichent dans l'ordre (titre + texte + médaillon/badge),
//   avec le bon gabarit de boutons bas de page par page (page 1 :
//   "Suivant" seul ; pages 2-4 : "Retour"/"Suivant" ; page 5 :
//   "Retour"/"C'est parti !") ;
// - la barre de progression/le texte "n / 5" du bandeau haut avancent avec
//   la navigation (boutons ET swipe) ;
// - "Passer" (n'importe quelle page) et "C'est parti !" (page 5) appellent
//   tous les deux `AuthRepository.markOnboardingSeen` puis sortent de
//   l'écran avec le même patron défensif que `profile_help_screen
//   .dart::_goBack` (`canPop()` → `pop()`, sinon `go('/')`).
//
// Double de test (`_FakeAuthRepository`) injecté via
// `authRepositoryProvider.overrideWithValue`, même mécanisme que
// `login_screen_test.dart` — jamais de vrai `Supabase.instance.client`.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/features/auth/data/auth_repository.dart';
import 'package:personnages/features/onboarding/presentation/onboarding_screen.dart';
import 'package:personnages/features/auth/presentation/providers/auth_providers.dart';

class _FakeAuthRepository implements AuthRepository {
  int markOnboardingSeenCallCount = 0;
  Object? markOnboardingSeenErrorToThrow;

  @override
  Future<void> markOnboardingSeen() async {
    markOnboardingSeenCallCount++;
    final error = markOnboardingSeenErrorToThrow;
    if (error != null) throw error;
  }

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
  Future<void> signOut() async {}

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
  late _FakeAuthRepository fakeRepository;

  setUp(() {
    fakeRepository = _FakeAuthRepository();
  });

  /// Pousse `OnboardingScreen` par-dessus une route `/` factice, pour que
  /// `context.canPop()` vaille `true` (même rationale que
  /// `profile_help_screen_test.dart::_pumpScreen`) — couvre le cas "ouvert
  /// volontairement depuis le profil" de la doc de classe de
  /// `OnboardingScreen`.
  Future<void> pumpPushedScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/',
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => Scaffold(
                  body: Center(
                    child: TextButton(
                      onPressed: () => context.push('/onboarding'),
                      child: const Text('Ouvrir'),
                    ),
                  ),
                ),
              ),
              GoRoute(
                path: '/onboarding',
                builder: (context, state) => const OnboardingScreen(),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
  }

  /// Pousse `OnboardingScreen` comme route initiale (donc jamais
  /// "poppable") — couvre le cas "forcé par le routeur à la première
  /// connexion" de la doc de classe de `OnboardingScreen`.
  Future<void> pumpInitialScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/onboarding',
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) =>
                    const Scaffold(body: Center(child: Text('Liste'))),
              ),
              GoRoute(
                path: '/onboarding',
                builder: (context, state) => const OnboardingScreen(),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('page 1/5 (BIENVENUE, AVENTURIER)', () {
    testWidgets('affiche le titre/texte de la page 1 et "1 / 5"', (
      tester,
    ) async {
      await pumpPushedScreen(tester);

      expect(find.text('BIENVENUE, AVENTURIER'), findsOneWidget);
      expect(find.textContaining("Nexus JDR t'accompagne"), findsOneWidget);
      expect(find.text('1 / 5'), findsOneWidget);
    });

    testWidgets('bouton "Suivant" seul, pas de "Retour"', (tester) async {
      await pumpPushedScreen(tester);

      expect(find.text('SUIVANT'), findsOneWidget);
      expect(find.text('RETOUR'), findsNothing);
    });

    testWidgets('taper "Suivant" avance à la page 2/5', (tester) async {
      await pumpPushedScreen(tester);

      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      expect(find.text('TES PERSONNAGES'), findsOneWidget);
      expect(find.text('2 / 5'), findsOneWidget);
    });
  });

  group('pages 2-4/5 : "Retour"/"Suivant"', () {
    testWidgets('page 3/5 affiche "Retour" ET "Suivant"', (tester) async {
      await pumpPushedScreen(tester);
      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      expect(find.text('LA FICHE DE TON PERSONNAGE'), findsOneWidget);
      expect(find.text('3 / 5'), findsOneWidget);
      expect(find.text('RETOUR'), findsOneWidget);
      expect(find.text('SUIVANT'), findsOneWidget);
    });

    testWidgets('taper "Retour" depuis la page 3/5 revient à la page 2/5', (
      tester,
    ) async {
      await pumpPushedScreen(tester);
      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('RETOUR'));
      await tester.pumpAndSettle();

      expect(find.text('TES PERSONNAGES'), findsOneWidget);
      expect(find.text('2 / 5'), findsOneWidget);
    });

    testWidgets(
      'le swipe (drag) avance aussi d\'une page, même StepProgressBar/'
      'texte qu\'un tap sur "Suivant"',
      (tester) async {
        await pumpPushedScreen(tester);

        await tester.drag(
          find.text('BIENVENUE, AVENTURIER'),
          const Offset(-400, 0),
        );
        await tester.pumpAndSettle();

        expect(find.text('TES PERSONNAGES'), findsOneWidget);
        expect(find.text('2 / 5'), findsOneWidget);
      },
    );

    testWidgets(
      'le swipe (drag) vers la droite revient a la page precedente, meme '
      'StepProgressBar/texte qu\'un tap sur "Retour"',
      (tester) async {
        await pumpPushedScreen(tester);
        await tester.tap(find.text('SUIVANT'));
        await tester.pumpAndSettle();

        await tester.drag(find.text('TES PERSONNAGES'), const Offset(600, 0));
        await tester.pumpAndSettle();

        expect(find.text('BIENVENUE, AVENTURIER'), findsOneWidget);
        expect(find.text('1 / 5'), findsOneWidget);
        expect(find.text('RETOUR'), findsNothing);
      },
    );

    testWidgets(
      'navigation mixte swipe puis bouton "Suivant" : PageController et '
      'etat interne (StepProgressBar/texte/boutons) restent synchronises, '
      'pas de desynchronisation entre les deux methodes',
      (tester) async {
        await pumpPushedScreen(tester);

        await tester.drag(
          find.text('BIENVENUE, AVENTURIER'),
          const Offset(-400, 0),
        );
        await tester.pumpAndSettle();
        expect(find.text('2 / 5'), findsOneWidget);

        await tester.tap(find.text('SUIVANT'));
        await tester.pumpAndSettle();

        expect(find.text('LA FICHE DE TON PERSONNAGE'), findsOneWidget);
        expect(find.text('3 / 5'), findsOneWidget);
        expect(find.text('RETOUR'), findsOneWidget);
        expect(find.text('SUIVANT'), findsOneWidget);
      },
    );

    testWidgets(
      'navigation mixte bouton "Suivant" puis swipe vers la droite : meme '
      'synchronisation, dans l\'ordre inverse',
      (tester) async {
        await pumpPushedScreen(tester);

        await tester.tap(find.text('SUIVANT'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('SUIVANT'));
        await tester.pumpAndSettle();
        expect(find.text('3 / 5'), findsOneWidget);

        await tester.drag(
          find.text('LA FICHE DE TON PERSONNAGE'),
          const Offset(600, 0),
        );
        await tester.pumpAndSettle();

        expect(find.text('TES PERSONNAGES'), findsOneWidget);
        expect(find.text('2 / 5'), findsOneWidget);
      },
    );
  });

  group('page 5/5 (C\'EST PARTI !)', () {
    Future<void> goToLastPage(WidgetTester tester) async {
      await pumpPushedScreen(tester);
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('SUIVANT'));
        await tester.pumpAndSettle();
      }
    }

    testWidgets('affiche "Retour" ET "C\'est parti !" (pas "Suivant")', (
      tester,
    ) async {
      await goToLastPage(tester);

      expect(find.text("C'EST PARTI !"), findsAtLeastNWidgets(1));
      expect(find.text('5 / 5'), findsOneWidget);
      expect(find.text('RETOUR'), findsOneWidget);
      expect(find.text('SUIVANT'), findsNothing);
    });

    testWidgets(
      'taper "C\'est parti !" appelle `markOnboardingSeen` puis sort de '
      'l\'écran (pop, car poussé depuis une route poppable)',
      (tester) async {
        await goToLastPage(tester);

        await tester.tap(find.text("C'EST PARTI !").last);
        await tester.pumpAndSettle();

        expect(fakeRepository.markOnboardingSeenCallCount, 1);
        expect(find.text('Ouvrir'), findsOneWidget);
        expect(find.byType(OnboardingScreen), findsNothing);
      },
    );
  });

  group('"Passer" (bandeau haut, visible sur les 5 pages)', () {
    testWidgets('visible dès la page 1/5', (tester) async {
      await pumpPushedScreen(tester);

      expect(find.text('Passer'), findsOneWidget);
    });

    testWidgets(
      'taper "Passer" sur la page 1/5 appelle `markOnboardingSeen` puis '
      'sort de l\'écran (pop)',
      (tester) async {
        await pumpPushedScreen(tester);

        await tester.tap(find.text('Passer'));
        await tester.pumpAndSettle();

        expect(fakeRepository.markOnboardingSeenCallCount, 1);
        expect(find.text('Ouvrir'), findsOneWidget);
      },
    );

    testWidgets(
      'écran atteint comme route initiale (non poppable, "forcé par le '
      'routeur") : "Passer" navigue vers "/" plutôt que de pop',
      (tester) async {
        await pumpInitialScreen(tester);

        await tester.tap(find.text('Passer'));
        await tester.pumpAndSettle();

        expect(fakeRepository.markOnboardingSeenCallCount, 1);
        expect(find.text('Liste'), findsOneWidget);
        expect(find.byType(OnboardingScreen), findsNothing);
      },
    );

    testWidgets(
      'échec réseau de `markOnboardingSeen` (best-effort) : ne bloque '
      'jamais la sortie de l\'écran',
      (tester) async {
        fakeRepository.markOnboardingSeenErrorToThrow = Exception(
          'Pas de réseau (double de test).',
        );
        await pumpPushedScreen(tester);

        await tester.tap(find.text('Passer'));
        await tester.pumpAndSettle();

        expect(fakeRepository.markOnboardingSeenCallCount, 1);
        expect(find.text('Ouvrir'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
