import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app_launch.dart';

/// Tape sur [text] après l'avoir fait défiler dans le viewport
/// (`tester.ensureVisible`) : la carte de connexion vit dans un
/// `SingleChildScrollView` qui se redimensionne quand le clavier natif
/// apparaît après une saisie de texte — un `tester.tap` direct sur un lien
/// (ex. "Créer un compte"/"Se connecter") rate alors sa cible réelle sur
/// un vrai appareil (contrairement à un test de widget avec clavier
/// simulé), jamais par coordonnées d'écran malgré tout : seul le defilement
/// standard du `Scrollable` ancêtre est utilisé.
Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

/// Tests d'intégration (vraie app, vrai émulateur, vrai Supabase distant —
/// voir `integration_test/README.md`) de l'écran de connexion
/// (`lib/features/auth/presentation/login_screen.dart`), **sans** compte de
/// test confirmé requis : contrairement aux scénarios authentifiés de ce
/// dossier, tout ce qui est vérifié ici reste accessible sans session
/// (validation de formulaire, bascule connexion/inscription, et un vrai
/// `signUp` jetable — jamais confirmé, donc jamais connecté, ce qui est
/// justement l'état final vérifié).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Installe un faux canal de saisie (pas de vrai clavier natif à
    // l'écran) : sur un vrai appareil, `enterText` sans ceci ouvre le
    // clavier IME réel, qui redimensionne la `SingleChildScrollView` de
    // l'écran de connexion de façon parfois flaky vis-à-vis de
    // `tester.ensureVisible`/`tap` juste après — jamais une histoire de
    // coordonnées d'écran, seulement d'éviter cette UI native
    // superflue pour ce que ce test vérifie.
    TestWidgetsFlutterBinding.ensureInitialized().testTextInput.register();
  });

  testWidgets(
    "écran de connexion : état vide, erreurs de validation, bascule "
    'connexion/inscription',
    (tester) async {
      await launchApp(tester);

      // --- État nominal : écran de connexion affiché (pas de session) ---
      expect(find.text('NEXUS JDR'), findsOneWidget);
      expect(find.text('ENTRER DANS LA TAVERNE'), findsOneWidget);
      expect(emailFieldFinder, findsOneWidget);
      expect(passwordFieldFinder, findsOneWidget);

      // --- État "erreur" : soumission du formulaire vide ---
      await _tapText(tester, 'ENTRER');
      await tester.pumpAndSettle();
      // `AuthValidators.email`/`.password` (lib/features/auth/domain/
      // auth_validators.dart) refusent un champ vide, sans jamais contacter
      // Supabase (voir le doc-comment de `_LoginScreenState._submit`).
      expect(find.text('Saisissez votre adresse e-mail.'), findsOneWidget);
      expect(find.text('Saisissez votre mot de passe.'), findsOneWidget);

      // --- Adresse mal formée / mot de passe trop court ---
      await tester.enterText(emailFieldFinder, 'pas-un-email');
      await tester.enterText(passwordFieldFinder, 'x');
      await tester.pump();
      await _tapText(tester, 'ENTRER');
      await tester.pumpAndSettle();
      expect(find.text('Adresse e-mail invalide.'), findsOneWidget);
      expect(
        find.text('Le mot de passe doit contenir au moins 6 caractères.'),
        findsOneWidget,
      );
      // Le formulaire ne doit toujours pas avoir déclenché de redirection :
      // on doit être encore sur l'écran de connexion.
      expect(find.text('ENTRER DANS LA TAVERNE'), findsOneWidget);

      // --- Bascule vers le mode inscription ---
      await _tapText(tester, 'Créer un compte');
      await tester.pumpAndSettle();
      expect(find.text('CRÉER UN COMPTE'), findsOneWidget);
      expect(find.text('Confirmer le mot de passe'), findsOneWidget);
      expect(find.text('Pseudo'), findsOneWidget);

      // --- Retour au mode connexion ---
      await _tapText(tester, 'Se connecter');
      await tester.pumpAndSettle();
      expect(find.text('ENTRER DANS LA TAVERNE'), findsOneWidget);
    },
  );

  testWidgets(
    "inscription : un signUp jetable aboutit à l'état "
    '"vérifiez vos e-mails" (confirmation par e-mail activée sur le projet '
    'Supabase distant, voir AuthRepository.signUp)',
    (tester) async {
      await launchApp(tester);

      await _tapText(tester, 'Créer un compte');
      await tester.pumpAndSettle();

      final email =
          'qa-integration-${DateTime.now().microsecondsSinceEpoch}'
          '@nexus-jdr.test';
      await tester.enterText(find.byType(TextFormField).at(0), email);
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Integration1234!Test',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'Integration1234!Test',
      );
      await tester.pump();

      await _tapText(tester, 'CRÉER LE COMPTE');
      await tester.pumpAndSettle(const Duration(seconds: 1));
      for (var attempt = 0; attempt < 20; attempt++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('VÉRIFIEZ VOS E-MAILS'), findsOneWidget);
      expect(find.textContaining(email), findsOneWidget);

      // Retour à la connexion, pour laisser l'écran dans un état propre.
      await _tapText(tester, 'RETOUR À LA CONNEXION');
      await tester.pumpAndSettle();
      expect(find.text('ENTRER DANS LA TAVERNE'), findsOneWidget);
    },
    // Crée un vrai utilisateur non confirmé sur le projet Supabase distant
    // partagé dev/staging/prod à chaque exécution (e-mail jetable
    // `@nexus-jdr.test`, jamais confirmé donc jamais connecté) — voir
    // `integration_test/README.md`, section "Données de test laissées en
    // base".
  );
}
