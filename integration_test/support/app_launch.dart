import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/main.dart' as app;

/// Lance la vraie app (`lib/main.dart::main`) et attend la fin du bootstrap
/// (`AppBootstrap` — Supabase, PostHog, Firebase sur Android, vérification de
/// version) pour atterrir soit sur [LoginScreen] (pas de session), soit sur
/// l'écran d'accueil authentifié.
///
/// Contrairement à `test/` (doubles factices) et `test_integration/` (tests
/// VM purs contre un vrai Supabase **local**), ces tests pilotent l'app
/// réelle sur un appareil/émulateur réel (`IntegrationTestWidgetsFlutterBinding`),
/// contre le projet Supabase **distant** partagé dev/staging/prod configuré
/// par `--dart-define-from-file=config/dev.json` (voir
/// `integration_test/README.md`) — aucun mock réseau.
///
/// Timeout généreux (90s, par défaut `pumpAndSettle` attend indéfiniment par
/// petits pas de 100ms tant que des frames sont planifiées) : le tout premier
/// lancement réel contre le réseau (Supabase, PostHog, vérification de
/// version, préchargement du catalogue de référence) est nettement plus lent
/// qu'un test de widget avec doubles factices.
Future<void> launchApp(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle(const Duration(seconds: 2));
  // Boucle de pump supplémentaire : certains écrans (splash → vérification
  // de version → login/accueil) enchaînent plusieurs `Future`s réseau
  // successifs, qu'un seul `pumpAndSettle` ne couvre pas toujours de façon
  // fiable dès qu'une animation reste active entre deux étapes.
  for (var attempt = 0; attempt < 45; attempt++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

/// Cherche un [TextFormField] par position dans l'écran de connexion
/// (`lib/features/auth/presentation/login_screen.dart`) — cet écran ne pose
/// aucune `Key` dédiée sur ses champs (vérifié par lecture du fichier), donc
/// le sélecteur le plus stable disponible est le type + l'ordre vertical
/// (jamais une coordonnée d'écran), documenté ici pour n'être changé qu'en un
/// seul endroit si l'écran ajoute/retire un champ.
final Finder emailFieldFinder = find.byType(TextFormField).at(0);
final Finder passwordFieldFinder = find.byType(TextFormField).at(1);
