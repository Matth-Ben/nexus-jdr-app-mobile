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
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/core/widgets/selectable_option_tile.dart';
import 'package:personnages/core/widgets/step_progress_bar.dart';
import 'package:personnages/features/character_creation/data/character_creation_repository.dart';
import 'package:personnages/features/character_creation/data/subclass_choice_repository.dart';
import 'package:personnages/features/character_creation/domain/alignment_catalog.dart';
import 'package:personnages/features/character_creation/domain/background_catalog.dart';
import 'package:personnages/features/character_creation/domain/character_creation_draft.dart';
import 'package:personnages/features/character_creation/domain/character_creation_failure.dart';
import 'package:personnages/features/character_creation/domain/class_catalog.dart';
import 'package:personnages/features/character_creation/domain/background_option.dart';
import 'package:personnages/features/character_creation/domain/class_option.dart';
import 'package:personnages/features/character_creation/domain/item_catalog.dart';
import 'package:personnages/features/character_creation/domain/language_catalog.dart';
import 'package:personnages/features/character_creation/domain/race_catalog.dart';
import 'package:personnages/features/character_creation/domain/skill_catalog.dart';
import 'package:personnages/features/character_creation/domain/spell_catalog.dart';
import 'package:personnages/features/character_creation/domain/subclass_choice_catalog.dart';
import 'package:personnages/features/character_creation/domain/subclass_choice_option.dart';
import 'package:personnages/features/character_creation/domain/tool_catalog.dart';
import 'package:personnages/features/character_creation/presentation/class_step_screen.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_draft_provider.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_providers.dart';
import 'package:personnages/features/character_creation/presentation/providers/subclass_choice_providers.dart';
import 'package:personnages/features/character_creation/presentation/widgets/draft_autosave_footer.dart';

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

  @override
  Future<SpellCatalog> fetchSpellCatalog({required int classId}) async =>
      const SpellCatalog(spells: []);

  @override
  Future<ItemCatalog> fetchItemCatalog() async => const ItemCatalog(items: []);

  @override
  Future<SkillCatalog> fetchSkillCatalog() async =>
      const SkillCatalog(skills: []);

  @override
  Future<AlignmentCatalog> fetchAlignmentCatalog() async =>
      const AlignmentCatalog(alignments: []);

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

class _FakeSubclassChoiceRepository implements SubclassChoiceRepository {
  SubclassChoiceCatalog catalog = const SubclassChoiceCatalog(
    optionsByClassId: {},
  );
  Object? errorToThrow;
  Completer<SubclassChoiceCatalog>? completer;
  int calls = 0;

  @override
  Future<SubclassChoiceCatalog> fetchLevelOneSubclassChoices() async {
    calls++;
    if (completer != null) return completer!.future;
    if (errorToThrow != null) throw errorToThrow!;
    return catalog;
  }
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
  late _FakeSubclassChoiceRepository fakeSubclassRepository;
  late ProviderContainer container;
  late GoRouter router;

  setUp(() {
    fakeRepository = _FakeCharacterCreationRepository();
    fakeSubclassRepository = _FakeSubclassChoiceRepository();
    container = ProviderContainer(
      overrides: [
        characterCreationRepositoryProvider.overrideWithValue(fakeRepository),
        subclassChoiceRepositoryProvider.overrideWithValue(
          fakeSubclassRepository,
        ),
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

  testWidgets(
    'affiche un indicateur de chargement pendant la récupération, avec un '
    'pied de page "Abandonner" toujours accessible (régression corrigée : '
    'avant, seule l\'icône croix du bandeau, disparue avec '
    '`DraftAutosaveFooter`, permettait d\'abandonner depuis cet état)',
    (WidgetTester tester) async {
      fakeRepository.catalogCompleter = Completer<ClassCatalog>();

      await tester.pumpWidget(buildTestWidget());
      router.push('/characters/new/step-2');
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Voir race_step_screen_test.dart pour le rationale : le bandeau bois
      // complet ne doit apparaître qu'une fois les données chargées.
      expect(find.byType(StepProgressBar), findsNothing);

      expect(find.byType(DraftAutosaveFooter), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(DraftAutosaveFooter),
          matching: find.text('Abandonner'),
        ),
      );
      // `pump(duration)` plutôt que `pumpAndSettle()` : voir
      // `race_step_screen_test.dart` pour le rationale (le
      // `CircularProgressIndicator` du `Completer` jamais résolu anime
      // indéfiniment, `pumpAndSettle()` ne convergerait jamais).
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Abandonner la création ?'), findsOneWidget);
    },
  );

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
    'le titre d\'étape et la barre de progression sont sur le bandeau bois, '
    'pas sur le fond parchemin (non-régression de la dette de fond corrigée '
    'par l\'agent dev-flutter : le bois doit s\'étendre jusque sous '
    'StepProgressBar, comme les étapes 6/9 et 7/9)',
    (WidgetTester tester) async {
      fakeRepository.catalogToReturn = const ClassCatalog(
        classes: [_magicien, _guerrier],
      );

      await pumpClassStep(tester);

      final title = tester.widget<Text>(find.text('2. Classe'));
      expect(title.style?.color, AppColors.textOnWood);

      final stepLabel = tester.widget<Text>(find.text('Étape 2 / 9'));
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

  group('aide contextuelle / abandon (docs/cahier-des-charges/'
      '11-fonctionnalites-a-ajouter.md section 3)', () {
    testWidgets('icône "?" du bandeau ouvre l\'aide de l\'étape 2 "Classe"', (
      tester,
    ) async {
      await pumpClassStep(tester);

      await tester.tap(find.byIcon(Icons.help_outline));
      await tester.pumpAndSettle();

      expect(find.text('2. CLASSE'), findsOneWidget);
    });

    testWidgets(
      'lien "Abandonner" du pied de page ouvre la confirmation d\'abandon',
      (tester) async {
        await pumpClassStep(tester);

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

    testWidgets(
      'lien "Abandonner" du pied de page reste accessible même en état '
      "d'erreur de chargement du catalogue (régression corrigée : avant, "
      'seul "Retour" restait disponible depuis cet état, sans aucun moyen '
      'de revenir à la confirmation d\'abandon)',
      (tester) async {
        fakeRepository.catalogErrorToThrow = const CharacterCreationFailure(
          'Impossible de charger les classes disponibles. Réessayez.',
        );

        await pumpClassStep(tester);

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

  group('choix de sous-classe au niveau 1', () {
    const clerc = ClassOption(
      id: 3,
      name: 'Clerc',
      description: 'Prêtre.',
      hitDie: 8,
    );
    const vie = SubclassChoiceOption(
      id: 31,
      name: 'Domaine de la Vie',
      description:
          'Soigne les blessures. Une description volontairement longue pour '
          "vérifier qu'elle n'est jamais tronquée sur une seule ligne dans "
          "la tuile de sous-classe affichée à l'écran.",
    );
    const guerre = SubclassChoiceOption(id: 32, name: 'Domaine de la Guerre');

    void givenClericCatalog({List<SubclassChoiceOption>? options}) {
      fakeRepository.catalogToReturn = const ClassCatalog(
        classes: [_magicien, _guerrier, clerc],
      );
      fakeSubclassRepository.catalog = SubclassChoiceCatalog(
        optionsByClassId: {
          3: options ?? const [vie, guerre],
        },
      );
    }

    Future<void> pumpClassStepWithoutSettling(WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      router.push('/characters/new/step-2');
      await tester.pump();
      await tester.pump();
    }

    bool nextEnabled(WidgetTester tester) =>
        tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed !=
        null;

    testWidgets('aucun bloc pour une classe non concernée, "Suivant" actif', (
      tester,
    ) async {
      givenClericCatalog();
      await pumpClassStep(tester);

      await tester.tap(find.text('Guerrier'));
      await tester.pumpAndSettle();

      expect(find.text('Domaine divin'), findsNothing);
      expect(find.text('Domaine de la Vie'), findsNothing);
      expect(nextEnabled(tester), isTrue);
    });

    testWidgets(
      'classe concernée : bloc sous la tuile, "Suivant" bloqué jusqu\'au '
      'choix, description non tronquée, brouillon écrit',
      (tester) async {
        givenClericCatalog();
        await pumpClassStep(tester);

        await tester.tap(find.text('Clerc'));
        await tester.pumpAndSettle();

        expect(find.text('Domaine divin'), findsOneWidget);
        expect(
          find.text('Ce choix se fait dès le niveau 1 pour cette classe.'),
          findsOneWidget,
        );
        expect(find.text('Choisis une option pour continuer.'), findsOneWidget);
        expect(nextEnabled(tester), isFalse);

        final clercTop = tester.getTopLeft(find.text('Clerc')).dy;
        final blockTop = tester.getTopLeft(find.text('Domaine divin')).dy;
        expect(blockTop, greaterThan(clercTop));

        final descriptionText = tester.widget<Text>(
          find.textContaining('Soigne les blessures'),
        );
        expect(descriptionText.maxLines, isNull);

        await tester.tap(find.text('Domaine de la Vie'));
        await tester.pumpAndSettle();

        expect(find.text('Choisis une option pour continuer.'), findsNothing);
        expect(nextEnabled(tester), isTrue);

        await tester.tap(find.text('SUIVANT'));
        await tester.pumpAndSettle();

        expect(readDraft().classId, 3);
        expect(readDraft().subclassId, 31);
        expect(find.text('Étape suivante'), findsOneWidget);
      },
    );

    testWidgets('changer de classe efface la sous-classe, recliquer la même '
        'classe la conserve', (tester) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      givenClericCatalog();
      await pumpClassStep(tester);

      await tester.tap(find.text('Clerc'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Domaine de la Vie'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Clerc'));
      await tester.pumpAndSettle();
      expect(nextEnabled(tester), isTrue);

      await tester.tap(find.text('Guerrier'));
      await tester.pumpAndSettle();
      expect(find.text('Domaine divin'), findsNothing);

      await tester.tap(find.text('Clerc'));
      await tester.pumpAndSettle();
      expect(find.text('Choisis une option pour continuer.'), findsOneWidget);
      expect(nextEnabled(tester), isFalse);
    });

    testWidgets('réhydrate la sous-classe depuis le brouillon', (tester) async {
      givenClericCatalog();
      container
          .read(characterCreationDraftControllerProvider.notifier)
          .setClass(classId: 3, subclassId: 32);

      await pumpClassStep(tester);

      final tiles = tester.widgetList<SelectableOptionTile>(
        find.byType(SelectableOptionTile),
      );
      expect(
        tiles.firstWhere((t) => t.title == 'Domaine de la Guerre').selected,
        isTrue,
      );
      expect(nextEnabled(tester), isTrue);
    });

    testWidgets('chargement : indicateur réservé, "Suivant" désactivé', (
      tester,
    ) async {
      givenClericCatalog();
      await pumpClassStep(tester);
      // Le catalogue de sous-classes est déjà résolu : on simule le
      // chargement en invalidant puis en bloquant la nouvelle requête.
      fakeSubclassRepository.completer = Completer<SubclassChoiceCatalog>();
      container.invalidate(subclassChoiceCatalogProvider);

      await tester.tap(find.text('Clerc'));
      await tester.pump();

      expect(find.text('Domaine divin'), findsOneWidget);
      final box = tester.widget<SizedBox>(
        find
            .ancestor(
              of: find.byType(CircularProgressIndicator),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(box.height, 72);
      expect(nextEnabled(tester), isFalse);
    });

    testWidgets('erreur sur une classe CONNUE concernée : message, '
        '"Réessayer" relance, "Suivant" désactivé', (tester) async {
      givenClericCatalog();
      await pumpClassStep(tester);
      // Le catalogue a déjà été chargé (Clerc connu concerné) ; un
      // rechargement échoue ensuite.
      fakeSubclassRepository.errorToThrow = const CharacterCreationFailure('x');
      container.invalidate(subclassChoiceCatalogProvider);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Clerc'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(
        find.text(
          'Impossible de charger les sous-classes disponibles. Réessaie.',
        ),
        findsOneWidget,
      );
      expect(nextEnabled(tester), isFalse);
      final callsBefore = fakeSubclassRepository.calls;

      fakeSubclassRepository.errorToThrow = null;
      await tester.tap(find.text('RÉESSAYER'));
      await tester.pumpAndSettle();

      expect(fakeSubclassRepository.calls, callsBefore + 1);
      expect(find.text('Domaine de la Vie'), findsOneWidget);
    });

    testWidgets('catalogue indisponible (ni réseau ni cache) : Guerrier, '
        '"Suivant" actif, aucun bloc ni erreur', (tester) async {
      givenClericCatalog();
      fakeSubclassRepository.errorToThrow = const CharacterCreationFailure('x');
      await pumpClassStep(tester);

      await tester.tap(find.text('Guerrier'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsNothing);
      expect(find.text('RÉESSAYER'), findsNothing);
      expect(nextEnabled(tester), isTrue);

      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      expect(readDraft().classId, 2);
      expect(readDraft().subclassId, isNull);
      expect(find.text('Étape suivante'), findsOneWidget);
    });

    testWidgets('catalogue en cours de chargement : Guerrier, "Suivant" actif '
        'et passe une fois la réponse reçue', (tester) async {
      givenClericCatalog();
      fakeSubclassRepository.completer = Completer<SubclassChoiceCatalog>();
      await pumpClassStepWithoutSettling(tester);

      await tester.tap(find.text('Guerrier'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(nextEnabled(tester), isTrue);

      await tester.tap(find.text('SUIVANT'));
      await tester.pump();
      expect(find.text('Étape suivante'), findsNothing);

      fakeSubclassRepository.completer!.complete(
        fakeSubclassRepository.catalog,
      );
      await tester.pumpAndSettle();

      expect(readDraft().classId, 2);
      expect(find.text('Étape suivante'), findsOneWidget);
    });

    testWidgets('catalogue en cours de chargement : Clerc ne passe pas sans '
        'son choix une fois la réponse reçue', (tester) async {
      givenClericCatalog();
      fakeSubclassRepository.completer = Completer<SubclassChoiceCatalog>();
      await pumpClassStepWithoutSettling(tester);

      await tester.tap(find.text('Clerc'));
      await tester.pump();
      await tester.tap(find.text('SUIVANT'));
      await tester.pump();

      fakeSubclassRepository.completer!.complete(
        fakeSubclassRepository.catalog,
      );
      await tester.pumpAndSettle();

      expect(find.text('Étape suivante'), findsNothing);
      expect(find.text('Domaine divin'), findsOneWidget);
      expect(nextEnabled(tester), isFalse);
    });

    testWidgets('liste vide (cas défensif) : message et "Suivant" débloqué, '
        'sous-classe null', (tester) async {
      givenClericCatalog(options: const []);
      await pumpClassStep(tester);

      await tester.tap(find.text('Clerc'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining("Aucune sous-classe n'est disponible"),
        findsOneWidget,
      );
      expect(nextEnabled(tester), isTrue);

      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      expect(readDraft().classId, 3);
      expect(readDraft().subclassId, isNull);
    });

    testWidgets('sémantique : conteneur "<titre>, choix obligatoire"', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      givenClericCatalog();
      await pumpClassStep(tester);

      await tester.tap(find.text('Clerc'));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(RegExp('Domaine divin, choix obligatoire')),
        findsOneWidget,
      );
      handle.dispose();
    });
  });
}
