// Tests de widget du flux d'abandon de la création en cours
// (`presentation/widgets/abandon_creation_flow.dart`) — voir
// `docs/cahier-des-charges/11-fonctionnalites-a-ajouter.md`, section
// "Création de personnage (assistant pas-à-pas)" : "Annulation / abandon
// d'une création en cours (suppression du brouillon)".
//
// `ProviderContainer` (pas de dépôt réseau à doubler ici) + un routeur
// minimal reproduisant `/` (liste des personnages) et une route de retour de
// sous-flux fictive — même patron que `race_step_screen_test.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/features/character_creation/domain/character_creation_draft.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_draft_provider.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_return_route_provider.dart';
import 'package:personnages/features/character_creation/presentation/widgets/abandon_creation_flow.dart';

Future<ProviderContainer> _pumpAbandonButton(WidgetTester tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  final router = GoRouter(
    initialLocation: '/characters/new',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Liste des personnages'))),
      ),
      GoRoute(
        path: '/join/step-3',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Choix du personnage (rejoindre)')),
        ),
      ),
      GoRoute(
        path: '/characters/new',
        builder: (context, state) => Consumer(
          builder: (context, ref, _) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => abandonCharacterCreation(context, ref),
                child: const Text('Abandonner'),
              ),
            ),
          ),
        ),
      ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  return container;
}

void main() {
  testWidgets('ouvre une confirmation ; "Continuer" ne réinitialise rien '
      'et ne navigue pas', (tester) async {
    final container = await _pumpAbandonButton(tester);
    container
        .read(characterCreationDraftControllerProvider.notifier)
        .setRace(raceId: 1, subraceId: null, raceCustomText: null);

    await tester.tap(find.text('Abandonner'));
    await tester.pumpAndSettle();

    expect(find.text('Abandonner la création ?'), findsOneWidget);
    expect(
      find.text(
        'Les choix déjà faits dans ce brouillon seront perdus. Cette '
        'action est définitive.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('CONTINUER'));
    await tester.pumpAndSettle();

    expect(
      container.read(characterCreationDraftControllerProvider).raceId,
      1,
      reason: 'annuler la confirmation ne doit pas toucher au brouillon',
    );
    expect(find.text('Liste des personnages'), findsNothing);
  });

  testWidgets(
    '"Abandonner" confirmé réinitialise le brouillon et navigue vers "/" '
    "quand aucun sous-flux n'a posé de route de retour",
    (tester) async {
      final container = await _pumpAbandonButton(tester);
      container
          .read(characterCreationDraftControllerProvider.notifier)
          .setRace(raceId: 1, subraceId: null, raceCustomText: null);

      await tester.tap(find.text('Abandonner'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abandonner').last);
      await tester.pumpAndSettle();

      expect(
        container.read(characterCreationDraftControllerProvider),
        const CharacterCreationDraft(),
      );
      expect(find.text('Liste des personnages'), findsOneWidget);
    },
  );

  testWidgets(
    '"Abandonner" confirmé, avec une route de retour posée par un sous-flux '
    '("Rejoindre une histoire") : navigue vers cette route plutôt que "/", '
    'et la consomme (remise à null)',
    (tester) async {
      final container = await _pumpAbandonButton(tester);
      container
          .read(characterCreationReturnRouteControllerProvider.notifier)
          .set('/join/step-3');

      await tester.tap(find.text('Abandonner'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abandonner').last);
      await tester.pumpAndSettle();

      expect(find.text('Choix du personnage (rejoindre)'), findsOneWidget);
      expect(find.text('Liste des personnages'), findsNothing);
      expect(
        container.read(characterCreationReturnRouteControllerProvider),
        isNull,
        reason: 'la route de retour ne doit servir qu\'une seule fois',
      );
    },
  );
}
