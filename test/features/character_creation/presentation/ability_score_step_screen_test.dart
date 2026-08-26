// Tests de widget de l'étape 4/9 de l'assistant de création
// ("Caractéristiques").
//
// Le dépôt de test (`_FakeCharacterCreationRepository`) est injecté via
// `overrideWithValue`, même principe que `race_step_screen_test.dart` :
// cette étape réutilise `raceCatalogProvider` (déjà chargé aux étapes
// précédentes) pour calculer les bonus raciaux, mais ne fait elle-même
// aucun nouvel appel réseau ni écriture — tout passe par le brouillon en
// mémoire (`character_creation_draft_provider.dart`).
//
// `initialLocation` reste l'étape "Historique" (stub) : `AbilityScoreStepScreen`
// est atteinte via un `push`, comme dans la vraie navigation
// (`background_step_screen.dart` pousse `/characters/new/step-4`) — même
// principe que `background_step_screen_test.dart`, nécessaire pour que le
// bouton "Retour" (`context.pop()`) ait effectivement une route à dépiler.
//
// Surface de test agrandie en hauteur (`tester.view.physicalSize`, largeur
// inchangée à 800 logiques comme le reste de la suite) : la hauteur par
// défaut (~600) ne suffit pas à afficher les 6 lignes de caractéristiques
// sans défilement, ce qui ferait manquer certaines lignes aux
// `find.text(...)` (`ListView` ne construit que les éléments visibles).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/features/character_creation/data/character_creation_repository.dart';
import 'package:personnages/features/character_creation/domain/ability_score_method.dart';
import 'package:personnages/features/character_creation/domain/background_catalog.dart';
import 'package:personnages/features/character_creation/domain/character_creation_draft.dart';
import 'package:personnages/features/character_creation/domain/class_catalog.dart';
import 'package:personnages/features/character_creation/domain/language_catalog.dart';
import 'package:personnages/features/character_creation/domain/race_catalog.dart';
import 'package:personnages/features/character_creation/domain/tool_catalog.dart';
import 'package:personnages/features/character_creation/domain/race_option.dart';
import 'package:personnages/features/character_creation/presentation/ability_score_step_screen.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_draft_provider.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_providers.dart';

class _FakeCharacterCreationRepository implements CharacterCreationRepository {
  RaceCatalog? catalogToReturn;

  @override
  Future<RaceCatalog> fetchRaceCatalog() async =>
      catalogToReturn ?? const RaceCatalog(races: [], subraces: []);

  // Non exercé par ces tests (étape 4 "Caractéristiques" n'utilise que le
  // catalogue de races) : implémentation minimale requise pour satisfaire
  // `CharacterCreationRepository`.
  @override
  Future<ClassCatalog> fetchClassCatalog() async =>
      const ClassCatalog(classes: []);

  @override
  Future<BackgroundCatalog> fetchBackgroundCatalog() async =>
      const BackgroundCatalog(backgrounds: []);

  @override
  Future<ToolCatalog> fetchToolCatalog() async => const ToolCatalog(tools: []);

  @override
  Future<LanguageCatalog> fetchLanguageCatalog() async =>
      const LanguageCatalog(languages: []);
}

const _elfe = RaceOption(
  id: 1,
  name: 'Elfe',
  abilityBonuses: {'dex': 2},
  traits: [],
);

void main() {
  late _FakeCharacterCreationRepository fakeRepository;
  late ProviderContainer container;
  late GoRouter router;

  setUp(() {
    fakeRepository = _FakeCharacterCreationRepository()
      ..catalogToReturn = const RaceCatalog(races: [_elfe], subraces: []);
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
    router = GoRouter(
      initialLocation: '/characters/new/step-3',
      routes: [
        GoRoute(
          path: '/characters/new/step-3',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Étape historique'))),
        ),
        GoRoute(
          path: '/characters/new/step-4',
          builder: (context, state) => const AbilityScoreStepScreen(),
        ),
        GoRoute(
          path: '/characters/new/step-5',
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

  /// Ligne de caractéristique (`_AbilityRow`) contenant le libellé en
  /// majuscules [label] (ex. 'SAGESSE'), pour scoper une recherche de
  /// bouton +/- ou de texte de modificateur à CETTE ligne plutôt qu'à
  /// l'écran entier — plusieurs lignes peuvent afficher le même
  /// modificateur (ex. deux caractéristiques à +1), une recherche globale
  /// par texte serait alors ambiguë.
  Finder rowFor(String label) =>
      find.ancestor(of: find.text(label), matching: find.byType(Row)).first;

  /// Monte l'écran (poussé depuis l'étape "Historique", voir plus haut) sur
  /// une surface assez grande pour afficher les 6 lignes de
  /// caractéristiques sans défilement.
  Future<void> pumpAbilityScoreStep(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();
    router.push('/characters/new/step-4');
    await tester.pumpAndSettle();
  }

  testWidgets(
    'affiche par défaut la méthode "Tableau" avec les 6 caractéristiques '
    'et leur modificateur, bonus racial inclus',
    (WidgetTester tester) async {
      container
          .read(characterCreationDraftControllerProvider.notifier)
          .setRace(raceId: 1, subraceId: null, raceCustomText: null);

      await pumpAbilityScoreStep(tester);

      expect(find.text('FORCE'), findsOneWidget);
      expect(find.text('DEXTÉRITÉ'), findsOneWidget);
      expect(find.text('CONSTITUTION'), findsOneWidget);
      expect(find.text('INTELLIGENCE'), findsOneWidget);
      expect(find.text('SAGESSE'), findsOneWidget);
      expect(find.text('CHARISME'), findsOneWidget);

      // Assignation par défaut : str=15, dex=14, con=13, int=12, wis=10,
      // cha=8. Force : 15, pas de bonus racial (Elfe ne bonifie que Dex) →
      // modificateur +2.
      expect(
        find.descendant(
          of: rowFor('FORCE'),
          matching: find.text('Modificateur +2'),
        ),
        findsOneWidget,
      );
      // Dextérité : 14 (base) + 2 (bonus racial Elfe) = 16 → modificateur +3.
      expect(
        find.descendant(
          of: rowFor('DEXTÉRITÉ'),
          matching: find.text('Modificateur +3'),
        ),
        findsOneWidget,
      );
      expect(find.text('15'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
    },
  );

  testWidgets(
    'le bouton "+" échange la valeur avec la caractéristique détenant la '
    'valeur immédiatement supérieure (méthode Tableau)',
    (WidgetTester tester) async {
      await pumpAbilityScoreStep(tester);

      // Sagesse vaut 10 par défaut ; la valeur immédiatement supérieure
      // (12) est détenue par Intelligence.
      final plusButtonInSagesseRow = find.descendant(
        of: rowFor('SAGESSE'),
        matching: find.byIcon(Icons.add),
      );

      await tester.tap(plusButtonInSagesseRow);
      await tester.pumpAndSettle();

      // Sagesse passe à 12 (modificateur +1), Intelligence redescend à 10
      // (modificateur +0) : pas de race choisie dans ce test, aucun bonus
      // racial n'entre en jeu.
      expect(
        find.descendant(
          of: rowFor('SAGESSE'),
          matching: find.text('Modificateur +1'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: rowFor('INTELLIGENCE'),
          matching: find.text('Modificateur +0'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'basculer sur "Points" réinitialise les scores à 8 et affiche les '
    'points restants',
    (WidgetTester tester) async {
      await pumpAbilityScoreStep(tester);

      await tester.tap(find.text('POINTS'));
      await tester.pumpAndSettle();

      expect(find.text('Points restants : 27/27'), findsOneWidget);
      expect(
        find.text('8'),
        findsNWidgets(6),
        reason: 'les 6 caractéristiques repartent à 8 en achat par points',
      );
    },
  );

  testWidgets(
    'en méthode "Points", incrémenter une caractéristique décrémente les '
    'points restants du coût marginal',
    (WidgetTester tester) async {
      await pumpAbilityScoreStep(tester);

      await tester.tap(find.text('POINTS'));
      await tester.pumpAndSettle();

      final plusButtonInForceRow = find.descendant(
        of: rowFor('FORCE'),
        matching: find.byIcon(Icons.add),
      );

      await tester.tap(plusButtonInForceRow);
      await tester.pumpAndSettle();

      expect(find.text('Points restants : 26/27'), findsOneWidget);
    },
  );

  testWidgets(
    'basculer sur "Dés" affiche un bouton "Relancer les dés" et des scores '
    'valides',
    (WidgetTester tester) async {
      await pumpAbilityScoreStep(tester);

      await tester.tap(find.text('DÉS'));
      await tester.pumpAndSettle();

      expect(find.text('Relancer les dés'), findsOneWidget);

      // Relancer ne doit pas planter et doit garder 6 lignes affichées.
      await tester.tap(find.text('Relancer les dés'));
      await tester.pumpAndSettle();

      expect(find.text('FORCE'), findsOneWidget);
      expect(find.text('CHARISME'), findsOneWidget);
    },
  );

  testWidgets(
    '"Suivant" est toujours actif (pas de validation bloquante sur cette '
    'étape) et enregistre la méthode et les scores dans le brouillon',
    (WidgetTester tester) async {
      await pumpAbilityScoreStep(tester);

      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      expect(find.text('Étape suivante'), findsOneWidget);
      final draft = readDraft();
      expect(draft.abilityScoreMethod, AbilityScoreMethod.standardArray);
      expect(draft.abilityScores, {
        'str': 15,
        'dex': 14,
        'con': 13,
        'int': 12,
        'wis': 10,
        'cha': 8,
      });
    },
  );

  testWidgets('le bouton "Retour" navigue vers l\'étape précédente', (
    WidgetTester tester,
  ) async {
    await pumpAbilityScoreStep(tester);

    await tester.tap(find.text('RETOUR'));
    await tester.pumpAndSettle();

    expect(find.text('Étape historique'), findsOneWidget);
  });

  testWidgets('revenir sur l\'étape avec un brouillon déjà rempli réhydrate la '
      'méthode et les scores déjà choisis (retour en arrière, '
      'docs/cahier-des-charges/05-ux-navigation.md)', (
    WidgetTester tester,
  ) async {
    container
        .read(characterCreationDraftControllerProvider.notifier)
        .setAbilityScores(
          method: AbilityScoreMethod.pointBuy,
          scores: const {
            'str': 12,
            'dex': 12,
            'con': 12,
            'int': 12,
            'wis': 12,
            'cha': 12,
          },
        );

    await pumpAbilityScoreStep(tester);

    expect(find.text('Points restants : 3/27'), findsOneWidget);
    expect(find.text('12'), findsNWidgets(6));

    await tester.tap(find.text('SUIVANT'));
    await tester.pumpAndSettle();

    expect(readDraft().abilityScores, {
      'str': 12,
      'dex': 12,
      'con': 12,
      'int': 12,
      'wis': 12,
      'cha': 12,
    });
  });

  testWidgets(
    'un aller-retour Tableau -> Points -> Tableau repart proprement sur '
    "l'assignation par défaut du Tableau (pas de score dupliqué/invalide "
    'conservé de la méthode intermédiaire)',
    (WidgetTester tester) async {
      await pumpAbilityScoreStep(tester);

      // Permute d'abord Sagesse/Intelligence pour s'assurer que l'écran ne
      // repart pas juste "par coïncidence" de l'assignation par défaut :
      // Sagesse (10) <-> Intelligence (12).
      await tester.tap(
        find.descendant(
          of: rowFor('SAGESSE'),
          matching: find.byIcon(Icons.add),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: rowFor('SAGESSE'),
          matching: find.text('Modificateur +1'),
        ),
        findsOneWidget,
        reason: 'Sagesse doit valoir 12 après la permutation',
      );

      // Bascule sur "Points" : repart à 8 partout (déjà couvert par un
      // autre test), puis revient sur "Tableau".
      await tester.tap(find.text('POINTS'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('TABLEAU'));
      await tester.pumpAndSettle();

      // Le retour sur "Tableau" doit repartir sur l'assignation par défaut
      // canonique (str=15, dex=14, con=13, int=12, wis=10, cha=8), PAS sur
      // la permutation faite avant de basculer, et pas non plus sur un état
      // incohérent hérité de "Points" (ex. un 8 qui resterait affiché sur
      // une caractéristique alors que le pool du Tableau ne permet pas six
      // fois la valeur 8).
      expect(
        find.descendant(
          of: rowFor('SAGESSE'),
          matching: find.text('Modificateur +0'),
        ),
        findsOneWidget,
        reason: 'Sagesse doit être revenue à sa valeur par défaut (10)',
      );
      expect(
        find.descendant(
          of: rowFor('INTELLIGENCE'),
          matching: find.text('Modificateur +1'),
        ),
        findsOneWidget,
        reason: 'Intelligence doit être revenue à sa valeur par défaut (12)',
      );
      // Le pool des 6 valeurs du Tableau standard est de nouveau entier :
      // aucune valeur du "Points" (8 partout) ne doit persister.
      expect(find.text('15'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
      expect(find.text('13'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
    },
  );
}
