// Tests de widget de l'étape "Édition" de l'assistant de création, TOUTE
// PREMIÈRE étape (AVANT `RaceStepScreen`) — chantier "choix d'édition
// 2014/2024 par personnage". Aucun catalogue réseau à simuler (2 options
// figées en dur), contrairement à `race_step_screen_test.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/widgets/step_progress_bar.dart';
import 'package:personnages/features/character_creation/domain/character_creation_draft.dart';
import 'package:personnages/features/character_creation/presentation/edition_step_screen.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_draft_provider.dart';

void main() {
  late ProviderContainer container;
  late GoRouter router;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  GoRouter buildTestRouter() {
    router = GoRouter(
      initialLocation: '/characters/new/edition',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Liste des personnages')),
          ),
        ),
        GoRoute(
          path: '/characters/new/edition',
          builder: (context, state) => const EditionStepScreen(),
        ),
        GoRoute(
          path: '/characters/new',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Étape Race'))),
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

  testWidgets(
    'affiche les 2 options d\'édition, 2014 présélectionnée par défaut '
    '(même défaut que CharacterCreationDraft.edition)',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('1. Édition'), findsOneWidget);
      expect(find.text('Étape 1 / 10'), findsOneWidget);
      expect(find.text('2014 — Manuel des Joueurs'), findsOneWidget);
      expect(find.text('2024 — Manuel des Joueurs revu'), findsOneWidget);
    },
  );

  testWidgets(
    'le titre d\'étape et la barre de progression sont sur le bandeau bois',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final title = tester.widget<Text>(find.text('1. Édition'));
      expect(title.style?.color, AppColors.textOnWood);
      expect(find.byType(StepProgressBar), findsOneWidget);
    },
  );

  testWidgets('"Suivant" est actionnable dès le premier affichage (2014 déjà '
      'présélectionnée) et écrit edition dans le brouillon avant de naviguer '
      'vers l\'étape Race', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('SUIVANT'));
    await tester.pumpAndSettle();

    expect(readDraft().edition, '2014');
    expect(find.text('Étape Race'), findsOneWidget);
  });

  testWidgets('choisir "2024" puis "Suivant" écrit edition = \'2024\' dans le '
      'brouillon', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('2024 — Manuel des Joueurs revu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SUIVANT'));
    await tester.pumpAndSettle();

    expect(readDraft().edition, '2024');
    expect(find.text('Étape Race'), findsOneWidget);
  });

  testWidgets(
    'revenir sur l\'étape avec un brouillon déjà fixé sur 2024 affiche cette '
    'option présélectionnée (retour en arrière depuis une étape suivante, '
    'docs/cahier-des-charges/05-ux-navigation.md)',
    (WidgetTester tester) async {
      container
          .read(characterCreationDraftControllerProvider.notifier)
          .setEdition('2024');

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      expect(readDraft().edition, '2024');
    },
  );

  testWidgets('le bouton "Retour" navigue vers la liste des personnages', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('RETOUR'));
    await tester.pumpAndSettle();

    expect(find.text('Liste des personnages'), findsOneWidget);
  });
}
