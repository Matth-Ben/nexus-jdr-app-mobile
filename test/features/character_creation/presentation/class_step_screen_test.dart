// Tests de widget de l'étape 2/9 de l'assistant de création ("Classe").
//
// Même principe que `race_step_screen_test.dart` : dépôt factice injecté via
// `overrideWithValue`, aucun appel réseau réel. Pas de sous-classe ni de
// "classe personnalisée" à tester ici (contrairement à Race) : "Suivant"
// s'active dès qu'une classe est sélectionnée.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/core/widgets/selectable_option_tile.dart';
import 'package:personnages/features/character_creation/data/character_creation_repository.dart';
import 'package:personnages/features/character_creation/domain/background_catalog.dart';
import 'package:personnages/features/character_creation/domain/character_creation_draft.dart';
import 'package:personnages/features/character_creation/domain/character_creation_failure.dart';
import 'package:personnages/features/character_creation/domain/class_catalog.dart';
import 'package:personnages/features/character_creation/domain/class_option.dart';
import 'package:personnages/features/character_creation/domain/language_catalog.dart';
import 'package:personnages/features/character_creation/domain/race_catalog.dart';
import 'package:personnages/features/character_creation/domain/tool_catalog.dart';
import 'package:personnages/features/character_creation/presentation/class_step_screen.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_draft_provider.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_providers.dart';

class _FakeCharacterCreationRepository implements CharacterCreationRepository {
  ClassCatalog? catalogToReturn;
  Object? catalogErrorToThrow;
  Completer<ClassCatalog>? catalogCompleter;

  @override
  Future<RaceCatalog> fetchRaceCatalog() async =>
      const RaceCatalog(races: [], subraces: []);

  @override
  Future<ClassCatalog> fetchClassCatalog() async {
    if (catalogCompleter != null) {
      return catalogCompleter!.future;
    }
    if (catalogErrorToThrow != null) {
      throw catalogErrorToThrow!;
    }
    return catalogToReturn ?? const ClassCatalog(classes: []);
  }

  // Non exercé par ces tests (étape 2 "Classe" uniquement) : implémentation
  // minimale requise pour satisfaire `CharacterCreationRepository`.
  @override
  Future<BackgroundCatalog> fetchBackgroundCatalog() async =>
      const BackgroundCatalog(backgrounds: []);

  @override
  Future<ToolCatalog> fetchToolCatalog() async => const ToolCatalog(tools: []);

  @override
  Future<LanguageCatalog> fetchLanguageCatalog() async =>
      const LanguageCatalog(languages: []);
}

const _magicien = ClassOption(
  id: 1,
  name: 'Magicien',
  description: 'Érudit de la magie arcanique.',
  hitDie: 6,
);

const _guerrier = ClassOption(
  id: 2,
  name: 'Guerrier',
  description: 'Maître du combat.',
  hitDie: 10,
);

void main() {
  late _FakeCharacterCreationRepository fakeRepository;
  late ProviderContainer container;
  late GoRouter router;

  setUp(() {
    fakeRepository = _FakeCharacterCreationRepository();
    container = ProviderContainer(
      overrides: [
        characterCreationRepositoryProvider.overrideWithValue(fakeRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  // `initialLocation` reste l'étape "Race" (stub) : `ClassStepScreen` est
  // atteinte via un `push`, comme dans la vraie navigation
  // (`race_step_screen.dart` pousse `/characters/new/step-2`). Nécessaire pour
  // que `context.pop()` du bouton "Retour" ait bien une route précédente sur
  // la pile (contrairement à `RaceStepScreen`, `ClassStepScreen._goBack` n'a
  // pas de repli `context.go('/')` : elle suppose toujours être poussée).
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
          path: '/characters/new/step-2',
          builder: (context, state) => const ClassStepScreen(),
        ),
        GoRoute(
          path: '/characters/new/step-3',
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

  Future<void> pumpClassStep(WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();
    router.push('/characters/new/step-2');
    await tester.pumpAndSettle();
  }

  testWidgets('affiche un indicateur de chargement pendant la récupération', (
    WidgetTester tester,
  ) async {
    fakeRepository.catalogCompleter = Completer<ClassCatalog>();

    await tester.pumpWidget(buildTestWidget());
    router.push('/characters/new/step-2');
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('affiche la liste des classes avec leur résumé', (
    WidgetTester tester,
  ) async {
    fakeRepository.catalogToReturn = const ClassCatalog(
      classes: [_magicien, _guerrier],
    );

    await pumpClassStep(tester);

    expect(find.text('Magicien'), findsOneWidget);
    expect(
      find.text('Érudit de la magie arcanique. · dé de vie d6'),
      findsOneWidget,
    );
    expect(find.text('Guerrier'), findsOneWidget);
    expect(find.text('Maître du combat. · dé de vie d10'), findsOneWidget);
  });

  testWidgets(
    'affiche un état d\'erreur avec un bouton "Réessayer" si le catalogue '
    'échoue à charger',
    (WidgetTester tester) async {
      fakeRepository.catalogErrorToThrow = const CharacterCreationFailure(
        'Impossible de charger les classes disponibles. Réessayez.',
      );

      await pumpClassStep(tester);

      expect(
        find.text(
          'Impossible de charger les classes disponibles. '
          'Réessayez.',
        ),
        findsOneWidget,
      );

      fakeRepository.catalogErrorToThrow = null;
      fakeRepository.catalogToReturn = const ClassCatalog(classes: [_magicien]);

      await tester.tap(find.text('RÉESSAYER'));
      await tester.pumpAndSettle();

      expect(find.text('Magicien'), findsOneWidget);
    },
  );

  testWidgets('le bouton "Suivant" est désactivé tant qu\'aucune classe '
      'n\'est sélectionnée', (WidgetTester tester) async {
    fakeRepository.catalogToReturn = const ClassCatalog(classes: [_magicien]);

    await pumpClassStep(tester);

    await tester.tap(find.text('SUIVANT'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(readDraft(), const CharacterCreationDraft());
    expect(find.text('Étape suivante'), findsNothing);
  });

  testWidgets(
    'sélectionner une classe active "Suivant" et met à jour le brouillon',
    (WidgetTester tester) async {
      fakeRepository.catalogToReturn = const ClassCatalog(
        classes: [_magicien, _guerrier],
      );

      await pumpClassStep(tester);

      await tester.tap(find.text('Guerrier'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      expect(readDraft(), const CharacterCreationDraft(classId: 2));
      expect(find.text('Étape suivante'), findsOneWidget);
    },
  );

  testWidgets('changer de sélection avant de valider envoie la dernière classe '
      'choisie', (WidgetTester tester) async {
    fakeRepository.catalogToReturn = const ClassCatalog(
      classes: [_magicien, _guerrier],
    );

    await pumpClassStep(tester);

    await tester.tap(find.text('Magicien'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guerrier'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('SUIVANT'));
    await tester.pumpAndSettle();

    expect(readDraft(), const CharacterCreationDraft(classId: 2));
  });

  testWidgets('le bouton "Retour" revient à l\'étape Race', (
    WidgetTester tester,
  ) async {
    fakeRepository.catalogToReturn = const ClassCatalog(classes: [_magicien]);

    await pumpClassStep(tester);

    await tester.tap(find.text('RETOUR'));
    await tester.pumpAndSettle();

    expect(find.text('Étape Race'), findsOneWidget);
  });

  testWidgets(
    'le bouton "Retour" utilise la variante "parchemin" du bouton secondaire '
    '(maquette 03_étape_2_classe.png)',
    (WidgetTester tester) async {
      fakeRepository.catalogToReturn = const ClassCatalog(classes: [_magicien]);

      await pumpClassStep(tester);

      final backButton = tester
          .widgetList<SecondaryButton>(find.byType(SecondaryButton))
          .firstWhere((button) => button.label == 'Retour');

      expect(backButton.surface, SecondaryButtonSurface.parchment);
    },
  );

  testWidgets(
    'une classe sans traduction résolue (id absent des tables translations) '
    'affiche un libellé générique et reste sélectionnable',
    (WidgetTester tester) async {
      const untranslated = ClassOption(
        id: 99,
        name: 'Classe #99',
        description: '',
        hitDie: 8,
      );
      fakeRepository.catalogToReturn = const ClassCatalog(
        classes: [_magicien, untranslated],
      );

      await pumpClassStep(tester);

      expect(find.text('Classe #99'), findsOneWidget);
      // Description vide -> `summaryLine` omet le segment description et le
      // séparateur ' · ' orphelin (voir `class_row_mapper_test.dart`).
      expect(find.text('dé de vie d8'), findsOneWidget);

      await tester.tap(find.text('Classe #99'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      expect(readDraft(), const CharacterCreationDraft(classId: 99));
    },
  );

  testWidgets('un catalogue de classes vide n\'affiche aucune ligne et laisse '
      '"Suivant" désactivé, sans crash', (WidgetTester tester) async {
    fakeRepository.catalogToReturn = const ClassCatalog(classes: []);

    await pumpClassStep(tester);

    expect(find.byType(Text), findsWidgets);
    expect(find.text('Magicien'), findsNothing);
    expect(find.text('Guerrier'), findsNothing);

    await tester.tap(find.text('SUIVANT'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(readDraft(), const CharacterCreationDraft());
    expect(find.text('Étape suivante'), findsNothing);
  });

  testWidgets(
    'revenir sur l\'étape avec un brouillon déjà rempli affiche la classe '
    'déjà choisie (retour en arrière depuis une étape suivante, '
    'docs/cahier-des-charges/05-ux-navigation.md)',
    (WidgetTester tester) async {
      fakeRepository.catalogToReturn = const ClassCatalog(
        classes: [_magicien, _guerrier],
      );
      container
          .read(characterCreationDraftControllerProvider.notifier)
          .setClass(classId: 2);

      await pumpClassStep(tester);

      final tiles = tester.widgetList<SelectableOptionTile>(
        find.byType(SelectableOptionTile),
      );
      expect(
        tiles.firstWhere((tile) => tile.title == 'Guerrier').selected,
        true,
      );
      expect(
        tiles.firstWhere((tile) => tile.title == 'Magicien').selected,
        false,
      );

      // "Suivant" doit déjà être actif : pas besoin de re-sélectionner.
      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      expect(readDraft(), const CharacterCreationDraft(classId: 2));
    },
  );
}
