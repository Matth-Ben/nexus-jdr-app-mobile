// Tests de widget de l'étape 1/9 de l'assistant de création ("Race").
//
// Le dépôt de test (`_FakeCharacterCreationRepository`) est injecté via
// `overrideWithValue`, pour ne jamais toucher à `Supabase.instance.client` —
// même principe que `character_list_screen_test.dart`. Cette étape ne fait
// plus aucun appel réseau à la validation ("Suivant") : elle se contente de
// mettre à jour le brouillon en mémoire
// (`character_creation_draft_provider.dart`), vérifié ici via un
// `ProviderContainer` plutôt qu'un double de dépôt.

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
import 'package:personnages/features/character_creation/domain/race_catalog.dart';
import 'package:personnages/features/character_creation/domain/race_option.dart';
import 'package:personnages/features/character_creation/domain/race_trait.dart';
import 'package:personnages/features/character_creation/domain/subrace_option.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_draft_provider.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_providers.dart';
import 'package:personnages/features/character_creation/presentation/race_step_screen.dart';

class _FakeCharacterCreationRepository implements CharacterCreationRepository {
  RaceCatalog? catalogToReturn;
  Object? catalogErrorToThrow;
  Completer<RaceCatalog>? catalogCompleter;

  @override
  Future<RaceCatalog> fetchRaceCatalog() async {
    if (catalogCompleter != null) {
      return catalogCompleter!.future;
    }
    if (catalogErrorToThrow != null) {
      throw catalogErrorToThrow!;
    }
    return catalogToReturn ?? const RaceCatalog(races: [], subraces: []);
  }

  // Non exercé par ces tests (étape 1 "Race" uniquement) : implémentation
  // minimale requise pour satisfaire `CharacterCreationRepository`.
  @override
  Future<ClassCatalog> fetchClassCatalog() async =>
      const ClassCatalog(classes: []);

  // Non exercé par ces tests (étape 1 "Race" uniquement) : implémentation
  // minimale requise pour satisfaire `CharacterCreationRepository`.
  @override
  Future<BackgroundCatalog> fetchBackgroundCatalog() async =>
      const BackgroundCatalog(backgrounds: []);
}

const _elfe = RaceOption(
  id: 1,
  name: 'Elfe',
  abilityBonuses: {'dex': 2},
  traits: [
    RaceTrait(name: 'Vision dans le noir', description: '...'),
    RaceTrait(name: 'Transe', description: '...'),
  ],
);

const _humain = RaceOption(
  id: 2,
  name: 'Humain',
  abilityBonuses: {'str': 1, 'dex': 1, 'con': 1, 'int': 1, 'wis': 1, 'cha': 1},
  traits: [],
);

const _nain = RaceOption(
  id: 3,
  name: 'Nain',
  abilityBonuses: {'con': 2},
  traits: [RaceTrait(name: 'Robustesse naine', description: '...')],
);

const _hautElfe = SubraceOption(
  id: 10,
  raceId: 1,
  name: 'Haut-elfe',
  abilityBonuses: {'int': 1},
  traits: [RaceTrait(name: 'Cantrip elfique', description: '...')],
);

const _nainDesCollines = SubraceOption(
  id: 20,
  raceId: 3,
  name: 'Nain des collines',
  abilityBonuses: {'wis': 1},
  traits: [RaceTrait(name: 'Ténacité naine', description: '...')],
);

void main() {
  late _FakeCharacterCreationRepository fakeRepository;
  late ProviderContainer container;

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

  GoRouter buildTestRouter() {
    return GoRouter(
      initialLocation: '/characters/new',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Liste des personnages')),
          ),
        ),
        GoRoute(
          path: '/characters/new',
          builder: (context, state) => const RaceStepScreen(),
        ),
        GoRoute(
          path: '/characters/new/step-2',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Étape suivante'))),
        ),
      ],
    );
  }

  Widget buildTestWidget() {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: buildTestRouter()),
    );
  }

  CharacterCreationDraft readDraft() =>
      container.read(characterCreationDraftControllerProvider);

  testWidgets('affiche un indicateur de chargement pendant la récupération', (
    WidgetTester tester,
  ) async {
    fakeRepository.catalogCompleter = Completer<RaceCatalog>();

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('affiche la liste des races avec leur résumé', (
    WidgetTester tester,
  ) async {
    fakeRepository.catalogToReturn = const RaceCatalog(
      races: [_elfe, _humain],
      subraces: [],
    );

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Elfe'), findsOneWidget);
    expect(find.text('+2 Dex · Vision dans le noir · Transe'), findsOneWidget);
    expect(find.text('Humain'), findsOneWidget);
    expect(find.text('+1 à toutes les caractéristiques'), findsOneWidget);
  });

  testWidgets(
    'affiche un état d\'erreur avec un bouton "Réessayer" si le catalogue '
    'échoue à charger',
    (WidgetTester tester) async {
      fakeRepository.catalogErrorToThrow = const CharacterCreationFailure(
        'Impossible de charger les races disponibles. Réessayez.',
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('Impossible de charger les races disponibles. Réessayez.'),
        findsOneWidget,
      );

      fakeRepository.catalogErrorToThrow = null;
      fakeRepository.catalogToReturn = const RaceCatalog(
        races: [_elfe],
        subraces: [],
      );

      await tester.tap(find.text('RÉESSAYER'));
      await tester.pumpAndSettle();

      expect(find.text('Elfe'), findsOneWidget);
    },
  );

  testWidgets('le bouton "Suivant" est désactivé tant qu\'aucune race n\'est '
      'sélectionnée', (WidgetTester tester) async {
    fakeRepository.catalogToReturn = const RaceCatalog(
      races: [_humain],
      subraces: [],
    );

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Le bouton "Suivant" est un `PrimaryButton` custom désactivé
    // (`onPressed: null`) plutôt qu'un `ElevatedButton` Material standard :
    // on vérifie l'effet (aucune mise à jour du brouillon, pas de
    // navigation) plutôt que l'état interne du widget.
    await tester.tap(find.text('SUIVANT'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(readDraft(), const CharacterCreationDraft());
    expect(find.text('Étape suivante'), findsNothing);
  });

  testWidgets(
    'sélectionner une race sans sous-race active immédiatement "Suivant"',
    (WidgetTester tester) async {
      fakeRepository.catalogToReturn = const RaceCatalog(
        races: [_humain],
        subraces: [],
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Humain'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      expect(
        readDraft(),
        const CharacterCreationDraft(raceId: 2, subraceId: null),
      );
      expect(find.text('Étape suivante'), findsOneWidget);
    },
  );

  testWidgets(
    'sélectionner une race avec sous-races affiche la liste de sous-races '
    'et bloque "Suivant" tant qu\'aucune n\'est choisie',
    (WidgetTester tester) async {
      fakeRepository.catalogToReturn = const RaceCatalog(
        races: [_elfe],
        subraces: [_hautElfe],
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Haut-elfe'), findsNothing);

      await tester.tap(find.text('Elfe'));
      await tester.pumpAndSettle();

      expect(find.text('Choisis une sous-race.'), findsOneWidget);
      expect(find.text('Haut-elfe'), findsOneWidget);

      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();
      expect(readDraft(), const CharacterCreationDraft());

      await tester.tap(find.text('Haut-elfe'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      expect(
        readDraft(),
        const CharacterCreationDraft(raceId: 1, subraceId: 10),
      );
    },
  );

  testWidgets(
    'changer de race après avoir choisi une sous-race désélectionne cette '
    'sous-race si la nouvelle race n\'en a pas, et active "Suivant" '
    'immédiatement',
    (WidgetTester tester) async {
      fakeRepository.catalogToReturn = const RaceCatalog(
        races: [_elfe, _humain],
        subraces: [_hautElfe],
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Elfe'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Haut-elfe'));
      await tester.pumpAndSettle();

      // Changement vers une race sans sous-race : la sous-race précédemment
      // choisie ne doit plus être ni affichée, ni envoyée dans le brouillon.
      await tester.tap(find.text('Humain'));
      await tester.pumpAndSettle();

      expect(find.text('Haut-elfe'), findsNothing);
      expect(find.text('Choisis une sous-race.'), findsNothing);

      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      expect(
        readDraft(),
        const CharacterCreationDraft(raceId: 2, subraceId: null),
      );
    },
  );

  testWidgets('changer de race entre deux races ayant chacune des sous-races '
      'réinitialise le choix de sous-race plutôt que de conserver l\'ancien '
      'identifiant', (WidgetTester tester) async {
    fakeRepository.catalogToReturn = const RaceCatalog(
      races: [_elfe, _nain],
      subraces: [_hautElfe, _nainDesCollines],
    );

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Elfe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Haut-elfe'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nain'));
    await tester.pumpAndSettle();

    // La sous-race de l'ancienne race ne doit plus apparaître, celle de la
    // nouvelle race doit être proposée mais pas encore sélectionnée.
    expect(find.text('Haut-elfe'), findsNothing);
    expect(find.text('Nain des collines'), findsOneWidget);

    await tester.tap(find.text('SUIVANT'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(
      readDraft(),
      const CharacterCreationDraft(),
      reason:
          'la nouvelle race exige une sous-race, "Suivant" doit rester '
          'bloqué tant qu\'aucune n\'est choisie pour CETTE race',
    );

    await tester.tap(find.text('Nain des collines'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SUIVANT'));
    await tester.pumpAndSettle();

    expect(readDraft(), const CharacterCreationDraft(raceId: 3, subraceId: 20));
  });

  testWidgets(
    'sélectionner "Race personnalisée" affiche un champ texte requis pour '
    'activer "Suivant"',
    (WidgetTester tester) async {
      fakeRepository.catalogToReturn = const RaceCatalog(
        races: [_elfe],
        subraces: [],
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.text('Race personnalisée'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);

      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();
      expect(readDraft(), const CharacterCreationDraft());

      await tester.enterText(find.byType(TextField), 'Golem vivant');
      await tester.pumpAndSettle();

      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      expect(
        readDraft(),
        const CharacterCreationDraft(raceCustomText: 'Golem vivant'),
      );
    },
  );

  testWidgets(
    'un champ de race personnalisée ne contenant que des espaces laisse '
    '"Suivant" désactivé (le contrôleur n\'est pas trimmé automatiquement)',
    (WidgetTester tester) async {
      fakeRepository.catalogToReturn = const RaceCatalog(
        races: [_elfe],
        subraces: [],
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Race personnalisée'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '   ');
      await tester.pumpAndSettle();

      await tester.tap(find.text('SUIVANT'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(readDraft(), const CharacterCreationDraft());
    },
  );

  testWidgets('le bouton "Retour" navigue vers la liste des personnages', (
    WidgetTester tester,
  ) async {
    fakeRepository.catalogToReturn = const RaceCatalog(
      races: [_humain],
      subraces: [],
    );

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('RETOUR'));
    await tester.pumpAndSettle();

    expect(find.text('Liste des personnages'), findsOneWidget);
  });

  testWidgets(
    'le bouton "Retour" utilise la variante "parchemin" du bouton secondaire '
    '(maquette 02_étape_1_race.png)',
    (WidgetTester tester) async {
      fakeRepository.catalogToReturn = const RaceCatalog(
        races: [_humain],
        subraces: [],
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final backButton = tester
          .widgetList<SecondaryButton>(find.byType(SecondaryButton))
          .firstWhere((button) => button.label == 'Retour');

      expect(backButton.surface, SecondaryButtonSurface.parchment);
    },
  );

  testWidgets(
    'retaper sur la race déjà sélectionnée ne réinitialise pas la sous-race '
    'déjà choisie',
    (WidgetTester tester) async {
      fakeRepository.catalogToReturn = const RaceCatalog(
        races: [_elfe],
        subraces: [_hautElfe],
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Elfe'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Haut-elfe'));
      await tester.pumpAndSettle();

      // Retaper sur "Elfe" (déjà sélectionnée) ne doit rien changer : la
      // sous-race choisie doit rester affichée et "Suivant" doit rester
      // actif immédiatement, sans re-choisir "Haut-elfe".
      await tester.tap(find.text('Elfe'));
      await tester.pumpAndSettle();

      expect(find.text('Haut-elfe'), findsOneWidget);

      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      expect(
        readDraft(),
        const CharacterCreationDraft(raceId: 1, subraceId: 10),
      );
    },
  );

  testWidgets(
    'revenir sur l\'étape avec un brouillon déjà rempli affiche la race et '
    'la sous-race déjà choisies (retour en arrière depuis une étape '
    'suivante, docs/cahier-des-charges/05-ux-navigation.md)',
    (WidgetTester tester) async {
      fakeRepository.catalogToReturn = const RaceCatalog(
        races: [_elfe, _humain],
        subraces: [_hautElfe],
      );
      container
          .read(characterCreationDraftControllerProvider.notifier)
          .setRace(raceId: 1, subraceId: 10);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Haut-elfe'), findsOneWidget);
      final tiles = tester.widgetList<SelectableOptionTile>(
        find.byType(SelectableOptionTile),
      );
      expect(tiles.firstWhere((tile) => tile.title == 'Elfe').selected, true);
      expect(
        tiles.firstWhere((tile) => tile.title == 'Humain').selected,
        false,
      );
      expect(
        tiles.firstWhere((tile) => tile.title == 'Haut-elfe').selected,
        true,
      );

      // "Suivant" doit déjà être actif : pas besoin de re-choisir quoi que
      // ce soit pour avancer.
      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      expect(
        readDraft(),
        const CharacterCreationDraft(raceId: 1, subraceId: 10),
      );
    },
  );

  testWidgets(
    'revenir sur l\'étape avec un brouillon déjà rempli avec une race '
    'personnalisée affiche l\'option "Race personnalisée" sélectionnée et '
    'le texte déjà saisi (retour en arrière depuis une étape suivante, '
    'docs/cahier-des-charges/05-ux-navigation.md)',
    (WidgetTester tester) async {
      fakeRepository.catalogToReturn = const RaceCatalog(
        races: [_elfe, _humain],
        subraces: [_hautElfe],
      );
      container
          .read(characterCreationDraftControllerProvider.notifier)
          .setRace(raceCustomText: 'Gobelours');

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final tiles = tester.widgetList<SelectableOptionTile>(
        find.byType(SelectableOptionTile),
      );
      expect(
        tiles.firstWhere((tile) => tile.title == 'Race personnalisée').selected,
        true,
      );
      expect(tiles.firstWhere((tile) => tile.title == 'Elfe').selected, false);
      expect(
        tiles.firstWhere((tile) => tile.title == 'Humain').selected,
        false,
      );

      expect(find.text('Gobelours'), findsOneWidget);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, 'Gobelours');

      // "Suivant" doit déjà être actif : le texte n'est pas vide, pas besoin
      // de re-saisir quoi que ce soit pour avancer.
      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      expect(
        readDraft(),
        const CharacterCreationDraft(raceCustomText: 'Gobelours'),
      );
    },
  );
}
