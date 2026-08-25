// Test de fumée pour le point d'entrée de l'app.
//
// Note : on pompe directement `NexusJdrApp` (pas `main()`), pour ne pas
// dépendre de `Supabase.initialize` (accès réseau/plugins natifs) dans un
// test de widget. Le routeur applicatif lit `Supabase.instance.client` dès
// sa construction (redirection connecté/non connecté) : on le surcharge donc
// ici via `appRouterProvider.overrideWithValue` avec un routeur de test
// minimal (un simple `Scaffold` de test, sans dépendre d'un écran réel de
// l'app), plutôt que d'initialiser Supabase pour de vrai.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/router/app_router.dart';
import 'package:personnages/main.dart';

void main() {
  testWidgets('affiche la route fournie par le routeur au démarrage', (
    WidgetTester tester,
  ) async {
    final testRouter = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Route de test'))),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appRouterProvider.overrideWithValue(testRouter)],
        child: const NexusJdrApp(),
      ),
    );

    expect(find.text('Route de test'), findsOneWidget);
  });
}
