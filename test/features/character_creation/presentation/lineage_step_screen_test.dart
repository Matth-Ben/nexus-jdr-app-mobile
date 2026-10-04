// Tests de widget de l'étape "Lignée" de l'assistant de création, second
// écran de l'étape 1/9 "Race" — atteinte uniquement depuis `RaceStepScreen`
// pour une race qui a des lignées 2024 sans sous-race (Drakéide, Tieffelin,
// Goliath). Même principe que `subrace_step_screen_test.dart` : dépôt
// factice injecté via `overrideWithValue`, aucun appel réseau réel.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/core/widgets/selectable_option_tile.dart';
import 'package:personnages/features/character_creation/data/lineage_choice_repository.dart';
import 'package:personnages/features/character_creation/domain/character_creation_draft.dart';
import 'package:personnages/features/character_creation/domain/lineage_choice_catalog.dart';
import 'package:personnages/features/character_creation/domain/lineage_option.dart';
import 'package:personnages/features/character_creation/presentation/lineage_step_screen.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_draft_provider.dart';
import 'package:personnages/features/character_creation/presentation/providers/lineage_choice_providers.dart';

class _FakeLineageChoiceRepository implements LineageChoiceRepository {
  LineageChoiceCatalog catalog = const LineageChoiceCatalog(
    optionsByRaceId: {},
  );
  Object? errorToThrow;
  Completer<LineageChoiceCatalog>? completer;

  @override
  Future<LineageChoiceCatalog> fetchLineageChoices() async {
    if (completer != null) return completer!.future;
    if (errorToThrow != null) throw errorToThrow!;
    return catalog;
  }
}

const _tieffelinCatalog = LineageChoiceCatalog(
  optionsByRaceId: {
    9: [
      LineageOption(id: 31, name: 'Abyssal', subtitle: 'Sorts innés abyssaux'),
      LineageOption(
        id: 32,
        name: 'Chtonien',
        subtitle: 'Sorts innés chtoniens',
      ),
      LineageOption(
        id: 33,
        name: 'Infernal',
        subtitle: 'Sorts innés infernaux',
      ),
    ],
  },
);

void main() {
  late _FakeLineageChoiceRepository fakeRepository;
  late ProviderContainer container;
  late GoRouter router;

  setUp(() {
    fakeRepository = _FakeLineageChoiceRepository();
    fakeRepository.catalog = _tieffelinCatalog;
    container = ProviderContainer(
      overrides: [
        lineageChoiceRepositoryProvider.overrideWithValue(fakeRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  // `initialLocation` reste l'étape "Race" (stub) : `LineageStepScreen` est
  // atteinte via un `push`, comme dans la vraie navigation
  // (`race_step_screen.dart` pousse `/characters/new/lineage`).
  GoRouter buildTestRouter() {
    router = GoRouter(
      initialLocation: '/characters/new',
      routes: [
        GoRoute(
          path: '/characters/new',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Étape Race'))),
        ),
        GoRoute(
          path: '/characters/new/lineage',
          builder: (context, state) => const LineageStepScreen(),
        ),
        GoRoute(
          path: '/characters/new/step-2',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Étape suivante'))),
        ),
      ],
    );
    return router;
  }

  Widget buildTestWidget() {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: buildTestRouter()),
    );
  }

  CharacterCreationDraft readDraft() =>
      container.read(characterCreationDraftControllerProvider);

  Future<void> pumpLineageStep(WidgetTester tester, {int raceId = 9}) async {
    container
        .read(characterCreationDraftControllerProvider.notifier)
        .setRace(raceId: raceId, subraceId: null);
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();
    router.push('/characters/new/lineage');
    await tester.pumpAndSettle();
  }

  testWidgets(
    'charge les 3 lignées fiélonnes du Tieffelin, titre "1. Lignée"',
    (WidgetTester tester) async {
      await pumpLineageStep(tester);

      expect(find.text('1. Lignée'), findsOneWidget);
      expect(find.text('Abyssal'), findsOneWidget);
      expect(find.text('Chtonien'), findsOneWidget);
      expect(find.text('Infernal'), findsOneWidget);
    },
  );

  testWidgets(
    'bandeau "1. Ascendance" pour le Goliath (race sans sous-titre)',
    (WidgetTester tester) async {
      fakeRepository.catalog = const LineageChoiceCatalog(
        optionsByRaceId: {
          24: [LineageOption(id: 25, name: 'Géant des nuages')],
        },
      );

      await pumpLineageStep(tester, raceId: 24);

      expect(find.text('1. Ascendance'), findsOneWidget);
      expect(find.text('Géant des nuages'), findsOneWidget);
    },
  );

  testWidgets('"Suivant" est désactivé tant qu\'aucune lignée n\'est choisie', (
    WidgetTester tester,
  ) async {
    await pumpLineageStep(tester);

    await tester.tap(find.text('SUIVANT'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(readDraft(), const CharacterCreationDraft(raceId: 9));
    expect(find.text('Étape suivante'), findsNothing);
  });

  testWidgets(
    'sélectionner une lignée puis "Suivant" écrit le brouillon et navigue '
    "vers l'étape 2/9",
    (WidgetTester tester) async {
      await pumpLineageStep(tester);

      await tester.tap(find.text('Chtonien'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      expect(
        readDraft(),
        const CharacterCreationDraft(raceId: 9, lineageId: 32),
      );
      expect(find.text('Étape suivante'), findsOneWidget);
    },
  );

  testWidgets('sélection exclusive : choisir une autre lignée désélectionne la '
      'précédente', (WidgetTester tester) async {
    await pumpLineageStep(tester);

    await tester.tap(find.text('Abyssal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chtonien'));
    await tester.pumpAndSettle();

    final tiles = tester.widgetList<SelectableOptionTile>(
      find.byType(SelectableOptionTile),
    );
    expect(tiles.firstWhere((tile) => tile.title == 'Chtonien').selected, true);
    expect(tiles.firstWhere((tile) => tile.title == 'Abyssal').selected, false);
  });

  testWidgets('le bouton "Retour" revient à l\'étape Race', (
    WidgetTester tester,
  ) async {
    await pumpLineageStep(tester);

    await tester.tap(find.text('RETOUR'));
    await tester.pumpAndSettle();

    expect(find.text('Étape Race'), findsOneWidget);
  });

  testWidgets(
    'réhydrate un brouillon déjà rempli (retour en arrière depuis une étape '
    'suivante)',
    (WidgetTester tester) async {
      container
          .read(characterCreationDraftControllerProvider.notifier)
          .setRace(raceId: 9, subraceId: null);
      container
          .read(characterCreationDraftControllerProvider.notifier)
          .setLineage(33);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      router.push('/characters/new/lineage');
      await tester.pumpAndSettle();

      final tiles = tester.widgetList<SelectableOptionTile>(
        find.byType(SelectableOptionTile),
      );
      expect(
        tiles.firstWhere((tile) => tile.title == 'Infernal').selected,
        true,
      );

      final nextButton = tester.widget<PrimaryButton>(
        find.byType(PrimaryButton),
      );
      expect(nextButton.onPressed, isNotNull);
    },
  );

  testWidgets(
    'aucun raceId dans le brouillon (cas défensif, ex. deep-link direct) '
    'redirige vers l\'étape 1 "Race"',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      router.push('/characters/new/lineage');
      await tester.pumpAndSettle();

      expect(find.text('Étape Race'), findsOneWidget);
    },
  );

  testWidgets(
    'erreur de chargement : bouton "Réessayer" invalide le provider',
    (WidgetTester tester) async {
      fakeRepository.errorToThrow = Exception('boom');

      await pumpLineageStep(tester);

      expect(find.text('RÉESSAYER'), findsOneWidget);
    },
  );
}
