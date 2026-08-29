// Tests de widget de l'étape 3/9 de l'assistant de création ("Historique").
//
// Même principe que `class_step_screen_test.dart` : dépôt factice injecté
// via `overrideWithValue`, aucun appel réseau réel. Pas d'historique
// personnalisé à tester ici (contrairement à Race) : "Suivant" s'active dès
// qu'un historique est sélectionné.
//
// Couvre en plus la spécificité de cette étape : seule la ligne
// sélectionnée affiche la ligne "Aptitude : ...", et ce texte se déplace
// bien d'une ligne à l'autre quand la sélection change.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/core/widgets/selectable_option_tile.dart';
import 'package:personnages/core/widgets/step_progress_bar.dart';
import 'package:personnages/features/character_creation/data/character_creation_repository.dart';
import 'package:personnages/features/character_creation/domain/background_catalog.dart';
import 'package:personnages/features/character_creation/domain/background_option.dart';
import 'package:personnages/features/character_creation/domain/character_creation_draft.dart';
import 'package:personnages/features/character_creation/domain/character_creation_failure.dart';
import 'package:personnages/features/character_creation/domain/class_catalog.dart';
import 'package:personnages/features/character_creation/domain/class_option.dart';
import 'package:personnages/features/character_creation/domain/item_catalog.dart';
import 'package:personnages/features/character_creation/domain/language_catalog.dart';
import 'package:personnages/features/character_creation/domain/race_catalog.dart';
import 'package:personnages/features/character_creation/domain/skill_catalog.dart';
import 'package:personnages/features/character_creation/domain/spell_catalog.dart';
import 'package:personnages/features/character_creation/domain/tool_catalog.dart';
import 'package:personnages/features/character_creation/presentation/background_step_screen.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_draft_provider.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_providers.dart';

class _FakeCharacterCreationRepository implements CharacterCreationRepository {
  BackgroundCatalog? catalogToReturn;
  Object? catalogErrorToThrow;
  Completer<BackgroundCatalog>? catalogCompleter;

  @override
  Future<RaceCatalog> fetchRaceCatalog() async =>
      const RaceCatalog(races: [], subraces: []);

  @override
  Future<ClassCatalog> fetchClassCatalog() async =>
      const ClassCatalog(classes: []);

  @override
  Future<BackgroundCatalog> fetchBackgroundCatalog() async {
    if (catalogCompleter != null) {
      return catalogCompleter!.future;
    }
    if (catalogErrorToThrow != null) {
      throw catalogErrorToThrow!;
    }
    return catalogToReturn ?? const BackgroundCatalog(backgrounds: []);
  }

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

const _ermite = BackgroundOption(
  id: 1,
  name: 'Ermite',
  skillProficiencies: ['Médecine', 'Religion'],
  featureName: 'Découverte',
  featureDescription: 'un secret qui a changé ta vision du monde.',
);

const _soldat = BackgroundOption(
  id: 2,
  name: 'Soldat',
  skillProficiencies: ['Athlétisme', 'Intimidation'],
  featureName: 'Grade militaire',
  featureDescription: 'les soldats vous reconnaissent.',
);

const _sansCompetences = BackgroundOption(
  id: 3,
  name: 'Ermite (variante)',
  skillProficiencies: [],
  featureName: 'Retraite',
  featureDescription: 'un lieu isolé où se retirer.',
);

const _troisCompetences = BackgroundOption(
  id: 4,
  name: 'Criminel',
  skillProficiencies: ['Discrétion', 'Escamotage', 'Investigation'],
  featureName: 'Contact criminel',
  featureDescription: 'un intermédiaire fiable dans le milieu.',
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

  // `initialLocation` reste l'étape "Classe" (stub) : `BackgroundStepScreen`
  // est atteinte via un `push`, comme dans la vraie navigation
  // (`class_step_screen.dart` pousse `/characters/new/step-3`).
  GoRouter buildTestRouter() {
    router = GoRouter(
      initialLocation: '/characters/new/step-2',
      routes: [
        GoRoute(
          path: '/characters/new/step-2',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Étape Classe'))),
        ),
        GoRoute(
          path: '/characters/new/step-3',
          builder: (context, state) => const BackgroundStepScreen(),
        ),
        GoRoute(
          path: '/characters/new/step-4',
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

  Future<void> pumpBackgroundStep(WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();
    router.push('/characters/new/step-3');
    await tester.pumpAndSettle();
  }

  testWidgets('affiche un indicateur de chargement pendant la récupération', (
    WidgetTester tester,
  ) async {
    fakeRepository.catalogCompleter = Completer<BackgroundCatalog>();

    await tester.pumpWidget(buildTestWidget());
    router.push('/characters/new/step-3');
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // Voir race_step_screen_test.dart pour le rationale : le bandeau bois
    // complet ne doit apparaître qu'une fois les données chargées.
    expect(find.byType(StepProgressBar), findsNothing);
  });

  testWidgets(
    'affiche la liste des historiques avec leurs compétences, sans aptitude '
    'visible tant qu\'aucun n\'est sélectionné',
    (WidgetTester tester) async {
      fakeRepository.catalogToReturn = const BackgroundCatalog(
        backgrounds: [_ermite, _soldat],
      );

      await pumpBackgroundStep(tester);

      expect(find.text('Ermite'), findsOneWidget);
      expect(find.text('Compétences : Médecine, Religion'), findsOneWidget);
      expect(find.text('Soldat'), findsOneWidget);
      expect(
        find.text('Compétences : Athlétisme, Intimidation'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Aptitude : Découverte — un secret qui a changé ta vision du '
          'monde.',
        ),
        findsNothing,
      );
      expect(
        find.text(
          'Aptitude : Grade militaire — les soldats vous '
          'reconnaissent.',
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'sélectionner un historique affiche son aptitude, uniquement sur sa '
    'ligne',
    (WidgetTester tester) async {
      fakeRepository.catalogToReturn = const BackgroundCatalog(
        backgrounds: [_ermite, _soldat],
      );

      await pumpBackgroundStep(tester);

      await tester.tap(find.text('Ermite'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Aptitude : Découverte — un secret qui a changé ta vision du '
          'monde.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Aptitude : Grade militaire — les soldats vous '
          'reconnaissent.',
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'changer de sélection déplace l\'affichage de l\'aptitude d\'une ligne à '
    'l\'autre',
    (WidgetTester tester) async {
      fakeRepository.catalogToReturn = const BackgroundCatalog(
        backgrounds: [_ermite, _soldat],
      );

      await pumpBackgroundStep(tester);

      await tester.tap(find.text('Ermite'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Aptitude : Découverte — un secret qui a changé ta vision du '
          'monde.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Soldat'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Aptitude : Découverte — un secret qui a changé ta vision du '
          'monde.',
        ),
        findsNothing,
      );
      expect(
        find.text(
          'Aptitude : Grade militaire — les soldats vous '
          'reconnaissent.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'le titre d\'étape et la barre de progression sont sur le bandeau bois, '
    'pas sur le fond parchemin (non-régression de la dette de fond corrigée '
    'par l\'agent dev-flutter : le bois doit s\'étendre jusque sous '
    'StepProgressBar, comme les étapes 6/9 et 7/9)',
    (WidgetTester tester) async {
      fakeRepository.catalogToReturn = const BackgroundCatalog(
        backgrounds: [_ermite, _soldat],
      );

      await pumpBackgroundStep(tester);

      final title = tester.widget<Text>(find.text('3. Historique'));
      expect(title.style?.color, AppColors.textOnWood);

      final stepLabel = tester.widget<Text>(find.text('Étape 3 / 9'));
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
        'Impossible de charger les historiques disponibles. Réessayez.',
      );

      await pumpBackgroundStep(tester);

      expect(
        find.text(
          'Impossible de charger les historiques disponibles. Réessayez.',
        ),
        findsOneWidget,
      );

      fakeRepository.catalogErrorToThrow = null;
      fakeRepository.catalogToReturn = const BackgroundCatalog(
        backgrounds: [_ermite],
      );

      await tester.tap(find.text('RÉESSAYER'));
      await tester.pumpAndSettle();

      expect(find.text('Ermite'), findsOneWidget);
    },
  );

  testWidgets('le bouton "Suivant" est désactivé tant qu\'aucun historique '
      'n\'est sélectionné', (WidgetTester tester) async {
    fakeRepository.catalogToReturn = const BackgroundCatalog(
      backgrounds: [_ermite],
    );

    await pumpBackgroundStep(tester);

    await tester.tap(find.text('SUIVANT'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(readDraft(), const CharacterCreationDraft());
    expect(find.text('Étape suivante'), findsNothing);
  });

  testWidgets(
    'sélectionner un historique active "Suivant" et met à jour le brouillon',
    (WidgetTester tester) async {
      fakeRepository.catalogToReturn = const BackgroundCatalog(
        backgrounds: [_ermite, _soldat],
      );

      await pumpBackgroundStep(tester);

      await tester.tap(find.text('Soldat'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      expect(readDraft(), const CharacterCreationDraft(backgroundId: 2));
      expect(find.text('Étape suivante'), findsOneWidget);
    },
  );

  testWidgets(
    'changer de sélection avant de valider envoie le dernier historique '
    'choisi',
    (WidgetTester tester) async {
      fakeRepository.catalogToReturn = const BackgroundCatalog(
        backgrounds: [_ermite, _soldat],
      );

      await pumpBackgroundStep(tester);

      await tester.tap(find.text('Ermite'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Soldat'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      expect(readDraft(), const CharacterCreationDraft(backgroundId: 2));
    },
  );

  testWidgets('le bouton "Retour" revient à l\'étape Classe', (
    WidgetTester tester,
  ) async {
    fakeRepository.catalogToReturn = const BackgroundCatalog(
      backgrounds: [_ermite],
    );

    await pumpBackgroundStep(tester);

    await tester.tap(find.text('RETOUR'));
    await tester.pumpAndSettle();

    expect(find.text('Étape Classe'), findsOneWidget);
  });

  testWidgets(
    'le bouton "Retour" utilise la variante "parchemin" du bouton secondaire '
    '(maquette 04_étape_3_historique.png)',
    (WidgetTester tester) async {
      fakeRepository.catalogToReturn = const BackgroundCatalog(
        backgrounds: [_ermite],
      );

      await pumpBackgroundStep(tester);

      final backButton = tester
          .widgetList<SecondaryButton>(find.byType(SecondaryButton))
          .firstWhere((button) => button.label == 'Retour');

      expect(backButton.surface, SecondaryButtonSurface.parchment);
    },
  );

  testWidgets('un historique sans traduction résolue (id absent des tables '
      'translations) affiche un libellé générique et reste sélectionnable', (
    WidgetTester tester,
  ) async {
    const untranslated = BackgroundOption(
      id: 99,
      name: 'Historique #99',
      skillProficiencies: [],
      featureName: '',
      featureDescription: '',
    );
    fakeRepository.catalogToReturn = const BackgroundCatalog(
      backgrounds: [_ermite, untranslated],
    );

    await pumpBackgroundStep(tester);

    expect(find.text('Historique #99'), findsOneWidget);

    await tester.tap(find.text('Historique #99'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SUIVANT'));
    await tester.pumpAndSettle();

    expect(readDraft(), const CharacterCreationDraft(backgroundId: 99));
  });

  testWidgets('un catalogue d\'historiques vide n\'affiche aucune ligne et '
      'laisse "Suivant" désactivé, sans crash', (WidgetTester tester) async {
    fakeRepository.catalogToReturn = const BackgroundCatalog(backgrounds: []);

    await pumpBackgroundStep(tester);

    expect(find.byType(Text), findsWidgets);
    expect(find.text('Ermite'), findsNothing);
    expect(find.text('Soldat'), findsNothing);

    await tester.tap(find.text('SUIVANT'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(readDraft(), const CharacterCreationDraft());
    expect(find.text('Étape suivante'), findsNothing);
  });

  testWidgets(
    'un historique sans compétence affiche "Compétences : " vide, sans '
    'crash, et reste sélectionnable',
    (WidgetTester tester) async {
      fakeRepository.catalogToReturn = const BackgroundCatalog(
        backgrounds: [_sansCompetences],
      );

      await pumpBackgroundStep(tester);

      expect(find.text('Compétences : '), findsOneWidget);

      await tester.tap(find.text('Ermite (variante)'));
      await tester.pumpAndSettle();

      expect(
        find.text('Aptitude : Retraite — un lieu isolé où se retirer.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'un historique avec plus de deux compétences les affiche toutes sur '
    'sa ligne',
    (WidgetTester tester) async {
      fakeRepository.catalogToReturn = const BackgroundCatalog(
        backgrounds: [_troisCompetences],
      );

      await pumpBackgroundStep(tester);

      expect(
        find.text('Compétences : Discrétion, Escamotage, Investigation'),
        findsOneWidget,
      );
    },
  );

  testWidgets('retaper la ligne déjà sélectionnée ne fait pas disparaître son '
      'aptitude (pas de bascule on/off)', (WidgetTester tester) async {
    fakeRepository.catalogToReturn = const BackgroundCatalog(
      backgrounds: [_ermite, _soldat],
    );

    await pumpBackgroundStep(tester);

    await tester.tap(find.text('Ermite'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ermite'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Aptitude : Découverte — un secret qui a changé ta vision du '
        'monde.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Aptitude : Grade militaire — les soldats vous '
        'reconnaissent.',
      ),
      findsNothing,
    );
  });

  testWidgets(
    'allers-retours répétés entre deux historiques ne laissent jamais deux '
    'aptitudes affichées simultanément',
    (WidgetTester tester) async {
      fakeRepository.catalogToReturn = const BackgroundCatalog(
        backgrounds: [_ermite, _soldat],
      );

      await pumpBackgroundStep(tester);

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Ermite'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Aptitude : '), findsOneWidget);

        await tester.tap(find.text('Soldat'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Aptitude : '), findsOneWidget);
      }
    },
  );

  testWidgets(
    'revenir sur l\'étape avec un brouillon déjà rempli affiche l\'historique '
    'déjà choisi, aptitude comprise (retour en arrière depuis une étape '
    'suivante, docs/cahier-des-charges/05-ux-navigation.md)',
    (WidgetTester tester) async {
      fakeRepository.catalogToReturn = const BackgroundCatalog(
        backgrounds: [_ermite, _soldat],
      );
      container
          .read(characterCreationDraftControllerProvider.notifier)
          .setBackground(backgroundId: 2);

      await pumpBackgroundStep(tester);

      final tiles = tester.widgetList<SelectableOptionTile>(
        find.byType(SelectableOptionTile),
      );
      expect(tiles.firstWhere((tile) => tile.title == 'Soldat').selected, true);
      expect(
        tiles.firstWhere((tile) => tile.title == 'Ermite').selected,
        false,
      );
      expect(
        find.text(
          'Aptitude : Grade militaire — les soldats vous reconnaissent.',
        ),
        findsOneWidget,
      );

      // "Suivant" doit déjà être actif : pas besoin de re-sélectionner.
      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      expect(readDraft(), const CharacterCreationDraft(backgroundId: 2));
    },
  );
}
