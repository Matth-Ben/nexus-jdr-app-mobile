// Câblage réel de `main.dart` (`NexusJdrApp`) : la clé globale des
// `SnackBar` (`scaffoldMessengerKeyProvider`) désigne le
// `SnackBarAwareScaffoldMessenger` posé par `MaterialApp.router(builder:)`,
// le même que `ScaffoldMessenger.of(page)` ; une `SnackBar` montrée par la clé
// (SnackBar générique au premier plan, « Ce groupe n'est plus accessible »)
// s'affiche bien dans la page. Surcharges : même patron que `widget_test.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/notifications/notification_providers.dart';
import 'package:personnages/core/notifications/push_token_registrar.dart';
import 'package:personnages/core/router/app_router.dart';
import 'package:personnages/core/widgets/snack_bar_aware_scaffold_messenger.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_catalog_preloader.dart';
import 'package:personnages/features/characters/presentation/providers/character_write_sync_coordinator.dart';
import 'package:personnages/main.dart';

import 'support/app_shell_overrides.dart';

void main() {
  testWidgets('clé globale = messager des pages, SnackBar affichée dans la '
      'page', (tester) async {
    final router = GoRouter(
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
          appRouterProvider.overrideWithValue(router),
          characterWriteSyncCoordinatorProvider.overrideWith(
            (ref) => CharacterWriteSyncCoordinator(ref),
          ),
          characterCreationCatalogPreloaderProvider.overrideWith(
            (ref) => CharacterCreationCatalogPreloader(ref),
          ),
          pushTokenRegistrarProvider.overrideWith(
            (ref) => PushTokenRegistrar(ref),
          ),
          ...appShellTestOverrides(),
        ],
        child: const NexusJdrApp(),
      ),
    );
    await tester.pumpAndSettle();

    final page = tester.element(find.text('Route de test'));
    final key = ProviderScope.containerOf(page)
        .read(scaffoldMessengerKeyProvider);
    final messenger = key.currentState;
    expect(messenger, isA<SnackBarAwareScaffoldMessengerState>());
    expect(identical(ScaffoldMessenger.of(page), messenger), isTrue);

    messenger!.showSnackBar(
      const SnackBar(content: Text("Ce groupe n'est plus accessible.")),
    );
    await tester.pumpAndSettle();
    expect(find.text("Ce groupe n'est plus accessible."), findsOneWidget);
    expect(
      (messenger as SnackBarAwareScaffoldMessengerState).currentSnackBar.value,
      isNotNull,
    );
  });
}
