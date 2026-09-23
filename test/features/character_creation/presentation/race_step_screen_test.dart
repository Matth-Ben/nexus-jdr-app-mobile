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
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/widgets/destructive_button.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/core/widgets/selectable_option_tile.dart';
import 'package:personnages/core/widgets/step_progress_bar.dart';
import 'package:personnages/features/character_creation/data/character_creation_repository.dart';
import 'package:personnages/features/character_creation/domain/alignment_catalog.dart';
import 'package:personnages/features/character_creation/domain/background_catalog.dart';
import 'package:personnages/features/character_creation/domain/background_option.dart';
import 'package:personnages/features/character_creation/domain/character_creation_draft.dart';
import 'package:personnages/features/character_creation/domain/character_creation_failure.dart';
import 'package:personnages/features/character_creation/domain/class_catalog.dart';
import 'package:personnages/features/character_creation/domain/class_option.dart';
import 'package:personnages/features/character_creation/domain/item_catalog.dart';
import 'package:personnages/features/character_creation/domain/language_catalog.dart';
import 'package:personnages/features/character_creation/domain/race_catalog.dart';
import 'package:personnages/features/character_creation/domain/race_option.dart';
import 'package:personnages/features/character_creation/domain/race_trait.dart';
import 'package:personnages/features/character_creation/domain/skill_catalog.dart';
import 'package:personnages/features/character_creation/domain/spell_catalog.dart';
import 'package:personnages/features/character_creation/domain/subrace_option.dart';
import 'package:personnages/features/character_creation/domain/tool_catalog.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_draft_provider.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_providers.dart';
import 'package:personnages/features/character_creation/presentation/race_step_screen.dart';
import 'package:personnages/features/character_creation/presentation/widgets/draft_autosave_footer.dart';

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

  // Non exercé par ces tests (étape 1 "Race" uniquement) : implémentation
  // minimale requise pour satisfaire `CharacterCreationRepository`.
  @override
  Future<ToolCatalog> fetchToolCatalog() async => const ToolCatalog(tools: []);

  // Non exercé par ces tests (étape 1 "Race" uniquement) : implémentation
  // minimale requise pour satisfaire `CharacterCreationRepository`.
  @override
  Future<LanguageCatalog> fetchLanguageCatalog() async =>
      const LanguageCatalog(languages: []);

  // Non exercé par ces tests (étape 1 "Race" uniquement) : implémentation
  // minimale requise pour satisfaire `CharacterCreationRepository`.
  @override
  Future<SpellCatalog> fetchSpellCatalog({required int classId}) async =>
      const SpellCatalog(spells: []);

  @override
  Future<ItemCatalog> fetchItemCatalog() async => const ItemCatalog(items: []);

  // Non exercé par ces tests (étape 1 "Race" uniquement) : implémentation
  // minimale requise pour satisfaire `CharacterCreationRepository`.
  @override
  Future<SkillCatalog> fetchSkillCatalog() async =>
      const SkillCatalog(skills: []);

  @override
  Future<AlignmentCatalog> fetchAlignmentCatalog() async =>
      const AlignmentCatalog(alignments: []);

  // Non exercé par ces tests (étape 1 "Race" uniquement) : implémentation
  // minimale requise pour satisfaire `CharacterCreationRepository`.
  @override
  Future<String> createCharacter({
    required CharacterCreationDraft draft,
    required String characterName,
    required RaceCatalog raceCatalog,
    required ClassOption classOption,
    required BackgroundOption backgroundOption,
    required SkillCatalog skillCatalog,
    required ToolCatalog toolCatalog,
    required LanguageCatalog languageCatalog,
    required SpellCatalog spellCatalog,
    required ItemCatalog itemCatalog,
  }) async => throw UnimplementedError();
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

const _hautElfe = SubraceOption(
  id: 10,
  raceId: 1,
  name: 'Haut-elfe',
  abilityBonuses: {'int': 1},
  traits: [RaceTrait(name: 'Cantrip elfique', description: '...')],
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
          path: '/characters/new/subrace',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Étape sous-race'))),
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

  testWidgets(
    'affiche un indicateur de chargement pendant la récupération, avec un '
    'pied de page "Abandonner" toujours accessible (régression corrigée : '
    'avant, seule l\'icône croix du bandeau, disparue avec '
    '`DraftAutosaveFooter`, permettait d\'abandonner depuis cet état)',
    (WidgetTester tester) async {
      fakeRepository.catalogCompleter = Completer<RaceCatalog>();

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Le bandeau bois complet (titre/compteur/StepProgressBar) ne doit
      // apparaître qu'une fois les données chargées (`_Header`), jamais
      // pendant le chargement (`_MinimalHeader` seul) — verrouille la
      // séparation des deux, plutôt que de ne compter que sur la structure du
      // code (suggestion QA/code-reviewer).
      expect(find.byType(StepProgressBar), findsNothing);

      expect(find.byType(DraftAutosaveFooter), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(DraftAutosaveFooter),
          matching: find.text('Abandonner'),
        ),
      );
      // `pump(duration)` plutôt que `pumpAndSettle()` : le `Completer` du
      // catalogue de races n'est volontairement jamais résolu dans ce test,
      // donc le `CircularProgressIndicator` continue d'animer indéfiniment
      // sous le dialogue — `pumpAndSettle()` ne converge jamais dans ce cas
      // (attend la fin de toute animation en cours) et lève un timeout.
      // Une seule frame suffit à faire apparaître le dialogue de
      // confirmation (`showDialog`, transition ~150ms par défaut).
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Abandonner la création ?'), findsOneWidget);
    },
  );

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
    'le titre d\'étape et la barre de progression sont sur le bandeau bois, '
    'pas sur le fond parchemin (non-régression de la dette de fond corrigée '
    'par l\'agent dev-flutter : le bois doit s\'étendre jusque sous '
    'StepProgressBar, comme les étapes 6/9 et 7/9)',
    (WidgetTester tester) async {
      fakeRepository.catalogToReturn = const RaceCatalog(
        races: [_elfe, _humain],
        subraces: [],
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final title = tester.widget<Text>(find.text('1. Race'));
      expect(title.style?.color, AppColors.textOnWood);

      final stepLabel = tester.widget<Text>(find.text('Étape 1 / 9'));
      expect(stepLabel.style?.color, AppColors.textOnWoodMuted);

      final woodBanner = find
          .ancestor(
            of: find.text('CRÉATION'),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is ColoredBox && widget.color == AppColors.woodMedium,
            ),
          )
          .first;
      expect(
        find.descendant(of: woodBanner, matching: find.byType(StepProgressBar)),
        findsOneWidget,
      );
    },
  );

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
    'sélectionner une race avec sous-races active immédiatement "Suivant" '
    '(le choix de sous-race est sa propre étape, voir SubraceStepScreen) et '
    'navigue vers "/characters/new/subrace"',
    (WidgetTester tester) async {
      fakeRepository.catalogToReturn = const RaceCatalog(
        races: [_elfe],
        subraces: [_hautElfe],
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Aucun bloc de sous-race sur cet écran, quelle que soit la race.
      expect(find.text('Haut-elfe'), findsNothing);
      expect(find.text('Choisis une sous-race.'), findsNothing);

      await tester.tap(find.text('Elfe'));
      await tester.pumpAndSettle();

      expect(find.text('Haut-elfe'), findsNothing);

      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      expect(
        readDraft(),
        const CharacterCreationDraft(raceId: 1, subraceId: null),
      );
      expect(find.text('Étape sous-race'), findsOneWidget);
      expect(find.text('Étape suivante'), findsNothing);
    },
  );

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
    'revenir sur l\'étape avec un brouillon déjà rempli affiche la race déjà '
    'choisie (retour en arrière depuis une étape suivante, '
    'docs/cahier-des-charges/05-ux-navigation.md) — la sous-race '
    'précédemment choisie n\'est pas affichée sur cet écran (voir '
    'SubraceStepScreen) mais, la race n\'ayant pas changé, elle est '
    'conservée dans le brouillon plutôt qu\'effacée à tort '
    '(régression corrigée : `_submit` passait `subraceId: null` '
    'inconditionnellement, y compris sans changement de race)',
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

      expect(find.text('Haut-elfe'), findsNothing);
      final tiles = tester.widgetList<SelectableOptionTile>(
        find.byType(SelectableOptionTile),
      );
      expect(tiles.firstWhere((tile) => tile.title == 'Elfe').selected, true);
      expect(
        tiles.firstWhere((tile) => tile.title == 'Humain').selected,
        false,
      );

      // "Suivant" doit déjà être actif : pas besoin de re-choisir quoi que
      // ce soit pour avancer. La race a des sous-races : "Suivant" pousse
      // l'étape "Sous-race" plutôt que l'étape 2/9. La race n'a pas changé
      // (toujours Elfe) : le brouillon conserve la sous-race déjà choisie
      // (`SubraceStepScreen` la réhydratera, et l'écrasera si l'utilisateur
      // en choisit une autre).
      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      expect(
        readDraft(),
        const CharacterCreationDraft(raceId: 1, subraceId: 10),
      );
      expect(find.text('Étape sous-race'), findsOneWidget);
    },
  );

  testWidgets(
    'revenir sur l\'étape SANS changer de race et retaper "Suivant" ne doit '
    'pas effacer une sous-race déjà choisie sur `SubraceStepScreen` '
    '(régression : `_submit` passait `subraceId: null` inconditionnellement, '
    'même sans changement de race)',
    (WidgetTester tester) async {
      fakeRepository.catalogToReturn = const RaceCatalog(
        races: [_elfe, _humain],
        subraces: [_hautElfe],
      );
      // Simule un retour en arrière depuis `SubraceStepScreen`, qui a déjà
      // écrit `subraceId` dans le brouillon.
      container
          .read(characterCreationDraftControllerProvider.notifier)
          .setRace(raceId: 1, subraceId: 10);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // "Elfe" doit déjà apparaître sélectionné (réhydratation) : on ne
      // retape aucune tuile, on retape directement "Suivant".
      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      expect(
        readDraft(),
        const CharacterCreationDraft(raceId: 1, subraceId: 10),
      );
      expect(find.text('Étape sous-race'), findsOneWidget);
    },
  );

  testWidgets(
    'changer de race après un choix de sous-race efface bien la sous-race '
    'devenue obsolète (la nouvelle race pousse toujours vers '
    '`SubraceStepScreen`, qui réécrira `subraceId`)',
    (WidgetTester tester) async {
      const autreElfe = RaceOption(
        id: 3,
        name: 'Elfe des bois',
        abilityBonuses: {'dex': 2},
        traits: [],
      );
      const autreSousRace = SubraceOption(
        id: 20,
        raceId: 3,
        name: 'Sylvain',
        abilityBonuses: {},
        traits: [],
      );
      fakeRepository.catalogToReturn = const RaceCatalog(
        races: [_elfe, autreElfe],
        subraces: [_hautElfe, autreSousRace],
      );
      container
          .read(characterCreationDraftControllerProvider.notifier)
          .setRace(raceId: 1, subraceId: 10);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Elfe des bois'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      expect(
        readDraft(),
        const CharacterCreationDraft(raceId: 3, subraceId: null),
      );
      expect(find.text('Étape sous-race'), findsOneWidget);
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

  group('aide contextuelle / abandon (docs/cahier-des-charges/'
      '11-fonctionnalites-a-ajouter.md section 3)', () {
    testWidgets('icône "?" du bandeau ouvre l\'aide de l\'étape 1 "Race"', (
      tester,
    ) async {
      fakeRepository.catalogToReturn = const RaceCatalog(
        races: [_elfe],
        subraces: [],
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.help_outline));
      await tester.pumpAndSettle();

      expect(find.text('1. RACE'), findsOneWidget);
    });

    testWidgets(
      'lien "Abandonner" du pied de page ouvre la confirmation d\'abandon ; '
      'confirmer réinitialise le brouillon et revient à la liste',
      (tester) async {
        fakeRepository.catalogToReturn = const RaceCatalog(
          races: [_elfe],
          subraces: [],
        );

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();
        // Simule un choix déjà fait à une étape précédente (le brouillon
        // n'est mis à jour par cet écran qu'au tap "Suivant", voir
        // `RaceStepScreen._submit` — écrit directement dans le provider
        // pour vérifier que l'abandon l'efface, sans naviguer hors de cet
        // écran comme le ferait "Suivant").
        container
            .read(characterCreationDraftControllerProvider.notifier)
            .setClass(classId: 1);

        expect(readDraft(), isNot(const CharacterCreationDraft()));

        await tester.tap(
          find.descendant(
            of: find.byType(DraftAutosaveFooter),
            matching: find.text('Abandonner'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Abandonner la création ?'), findsOneWidget);

        // `find.byType(DestructiveButton)` plutôt que `find.text('Abandonner')`
        // : la dialogue de confirmation reste superposée au pied de page qui
        // porte lui-même le texte "Abandonner" (`DraftAutosaveFooter`), un
        // simple `find.text` serait donc ambigu (deux candidats).
        await tester.tap(find.byType(DestructiveButton));
        await tester.pumpAndSettle();

        expect(readDraft(), const CharacterCreationDraft());
        expect(find.text('Liste des personnages'), findsOneWidget);
      },
    );

    testWidgets(
      'lien "Abandonner" du pied de page reste accessible même en état '
      "d'erreur de chargement du catalogue (régression corrigée : avant, "
      'seul "Retour" restait disponible depuis cet état, sans aucun moyen '
      'de revenir à la confirmation d\'abandon)',
      (tester) async {
        fakeRepository.catalogErrorToThrow = const CharacterCreationFailure(
          'Impossible de charger les races disponibles. Réessayez.',
        );

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(DraftAutosaveFooter), findsOneWidget);

        await tester.tap(
          find.descendant(
            of: find.byType(DraftAutosaveFooter),
            matching: find.text('Abandonner'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Abandonner la création ?'), findsOneWidget);
      },
    );
  });
}
