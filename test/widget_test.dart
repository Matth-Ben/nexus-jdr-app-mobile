// Test de fumée pour le point d'entrée de l'app.
//
// Note : on pompe directement `NexusJdrApp` (pas `main()`), pour ne pas
// dépendre de `Supabase.initialize` (accès réseau/plugins natifs) dans un
// test de widget. Le routeur applicatif lit `Supabase.instance.client` dès
// sa construction (redirection connecté/non connecté) : on le surcharge donc
// ici via `appRouterProvider.overrideWithValue` avec un routeur de test
// minimal (un simple `Scaffold` de test, sans dépendre d'un écran réel de
// l'app), plutôt que d'initialiser Supabase pour de vrai.
//
// `characterWriteSyncCoordinatorProvider`/`characterCreationCatalogPreloaderProvider`
// (`NexusJdrApp.build`) sont surchargés pour la même raison : leur provider
// "réel" déclenche `start()` dès sa construction (tentative de synchro/
// préchargement immédiate, voir leur doc de classe), qui lit à son tour
// `supabaseClientProvider` -> `Supabase.instance.client`, non initialisé
// ici. Les overrides ci-dessous construisent chaque coordinateur/préchargeur
// sans jamais appeler `start()`, pour ne jamais déclencher cette lecture.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/router/app_router.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_catalog_preloader.dart';
import 'package:personnages/features/characters/presentation/providers/character_write_sync_coordinator.dart';
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
        overrides: [
          appRouterProvider.overrideWithValue(testRouter),
          characterWriteSyncCoordinatorProvider.overrideWith(
            (ref) => CharacterWriteSyncCoordinator(ref),
          ),
          characterCreationCatalogPreloaderProvider.overrideWith(
            (ref) => CharacterCreationCatalogPreloader(ref),
          ),
        ],
        child: const NexusJdrApp(),
      ),
    );

    expect(find.text('Route de test'), findsOneWidget);
  });
}
