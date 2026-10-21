// Tests de widget de `ClassChoiceStepScreen` (correctif D99,
// `docs/dette-technique.md`) : second écran de l'étape 2/9 "Classe"
// (Guerrier/Rôdeur) OU de l'étape 5/9 "Compétences et outils" (Roublard).
//
// Même principe que les autres écrans de l'assistant : dépôt factice injecté
// via `overrideWithValue`, aucun appel réseau réel.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/widgets/checkable_option_tile.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/character_creation/data/character_creation_repository.dart';
import 'package:personnages/features/character_creation/domain/alignment_catalog.dart';
import 'package:personnages/features/character_creation/domain/background_catalog.dart';
import 'package:personnages/features/character_creation/domain/background_option.dart';
import 'package:personnages/features/character_creation/domain/character_creation_draft.dart';
import 'package:personnages/features/character_creation/domain/character_creation_failure.dart';
import 'package:personnages/features/character_creation/domain/character_edit_snapshot.dart';
import 'package:personnages/features/character_creation/domain/class_catalog.dart';
import 'package:personnages/features/character_creation/domain/class_option.dart';
import 'package:personnages/features/character_creation/domain/item_catalog.dart';
import 'package:personnages/features/character_creation/domain/language_catalog.dart';
import 'package:personnages/features/character_creation/domain/race_catalog.dart';
import 'package:personnages/features/character_creation/domain/skill_catalog.dart';
import 'package:personnages/features/character_creation/domain/spell_catalog.dart';
import 'package:personnages/features/character_creation/domain/tool_catalog.dart';
import 'package:personnages/features/character_creation/presentation/class_choice_step_screen.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_draft_provider.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_providers.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_edit_session_provider.dart';

class _FakeCharacterCreationRepository implements CharacterCreationRepository {
  ClassCatalog? classCatalogToReturn;
  BackgroundCatalog? backgroundCatalogToReturn;
  Object? classCatalogErrorToThrow;
  Completer<ClassCatalog>? classCatalogCompleter;

  @override
  Future<RaceCatalog> fetchRaceCatalog() async =>
      const RaceCatalog(races: [], subraces: []);

  @override
  Future<ClassCatalog> fetchClassCatalog() async {
    if (classCatalogCompleter != null) return classCatalogCompleter!.future;
    if (classCatalogErrorToThrow != null) throw classCatalogErrorToThrow!;
    return classCatalogToReturn ?? const ClassCatalog(classes: []);
  }

  @override
  Future<BackgroundCatalog> fetchBackgroundCatalog() async =>
      backgroundCatalogToReturn ?? const BackgroundCatalog(backgrounds: []);

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

/// `classes.id = 5`, le VRAI id du Guerrier.
const _guerrier = ClassOption(
  id: 5,
  name: 'Guerrier',
  description: 'Maître du combat.',
  hitDie: 10,
);

/// `classes.id = 8`, le VRAI id du Rôdeur.
const _rodeur = ClassOption(
  id: 8,
  name: 'Rôdeur',
  description: 'Chasseur et pisteur.',
  hitDie: 10,
);

/// `classes.id = 9`, le VRAI id du Roublard, avec sa maîtrise d'outils de
/// voleur toujours accordée automatiquement (candidate à la substitution
/// d'Expertise).
const _roublard = ClassOption(
  id: 9,
  name: 'Roublard',
  description: 'Discret et habile.',
  hitDie: 8,
  grantedToolNames: ['outils de voleur'],
);

/// Même id (9) mais sans maîtrise d'outils octroyée, pour le cas défensif
/// "aucune option disponible".
const _roublardSansOutils = ClassOption(
  id: 9,
  name: 'Roublard',
  description: 'Discret et habile.',
  hitDie: 8,
);

const _ermite = BackgroundOption(
  id: 10,
  name: 'Ermite',
  skillProficiencies: ['Médecine'],
  featureName: '',
  featureDescription: '',
);

/// Historique sans aucune compétence accordée, pour le cas défensif
/// "aucune option disponible" (contrairement à [_ermite]).
const _ermiteSansCompetence = BackgroundOption(
  id: 10,
  name: 'Ermite',
  skillProficiencies: [],
  featureName: '',
  featureDescription: '',
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
          path: '/characters/new/class-choice',
          builder: (context, state) => const ClassChoiceStepScreen(),
        ),
        GoRoute(
          path: '/characters/new/step-3',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Étape Historique'))),
        ),
        GoRoute(
          path: '/characters/new/step-7',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Étape Équipement'))),
        ),
        GoRoute(
          path: '/characters/new/step-8',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Étape Apparence'))),
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

  bool nextEnabled(WidgetTester tester) =>
      tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed !=
      null;

  Future<void> pumpClassChoiceStep(WidgetTester tester) async {
    // Surface de test agrandie en hauteur — même rationale que
    // `skills_and_tools_step_screen_test.dart` (le pied de page
    // "Brouillon sauvegardé automatiquement · Abandonner" réduit la hauteur
    // disponible pour la liste défilante, ce qui fait manquer certaines
    // options à la hauteur par défaut (~600)).
    tester.view.physicalSize = const Size(800, 1300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();
    router.push('/characters/new/class-choice');
    await tester.pumpAndSettle();
  }

  group('Guerrier (style_combat) et Rôdeur (ennemi_jure)', () {
    testWidgets(
      'Guerrier : affiche les 6 styles de combat, bloque "Suivant" tant '
      "qu'aucun n'est choisi",
      (WidgetTester tester) async {
        fakeRepository.classCatalogToReturn = const ClassCatalog(
          classes: [_guerrier],
        );
        container
            .read(characterCreationDraftControllerProvider.notifier)
            .setClass(classId: 5);

        await pumpClassChoiceStep(tester);

        expect(find.text('2. Style de combat'), findsOneWidget);
        expect(find.text('Archerie'), findsOneWidget);
        expect(find.text('Combat à deux armes'), findsOneWidget);
        expect(find.text('Combat à deux mains'), findsOneWidget);
        expect(find.text('Défense'), findsOneWidget);
        expect(find.text('Duel'), findsOneWidget);
        expect(find.text('Protection'), findsOneWidget);
        expect(find.byIcon(Icons.security), findsWidgets);
        expect(nextEnabled(tester), isFalse);
      },
    );

    testWidgets(
      'Guerrier : choisir un style puis "Suivant" écrit le brouillon et '
      'navigue directement vers l\'étape 3/9 (jamais la sous-classe)',
      (WidgetTester tester) async {
        fakeRepository.classCatalogToReturn = const ClassCatalog(
          classes: [_guerrier],
        );
        container
            .read(characterCreationDraftControllerProvider.notifier)
            .setClass(classId: 5);

        await pumpClassChoiceStep(tester);

        await tester.tap(find.text('Duel'));
        await tester.pumpAndSettle();
        expect(nextEnabled(tester), isTrue);

        await tester.tap(find.text('SUIVANT'));
        await tester.pumpAndSettle();

        expect(
          readDraft(),
          const CharacterCreationDraft(
            classId: 5,
            classFeatureChoiceValue: 'Duel',
          ),
        );
        expect(find.text('Étape Historique'), findsOneWidget);
      },
    );

    testWidgets(
      'Rôdeur : affiche les ennemis jurés avec l\'icône dédiée, titre '
      '"2. Ennemi juré"',
      (WidgetTester tester) async {
        fakeRepository.classCatalogToReturn = const ClassCatalog(
          classes: [_rodeur],
        );
        container
            .read(characterCreationDraftControllerProvider.notifier)
            .setClass(classId: 8);

        await pumpClassChoiceStep(tester);

        expect(find.text('2. Ennemi juré'), findsOneWidget);
        expect(find.text('Dragons'), findsOneWidget);
        expect(find.byIcon(Icons.gps_fixed), findsWidgets);

        await tester.tap(find.text('Dragons'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('SUIVANT'));
        await tester.pumpAndSettle();

        expect(
          readDraft(),
          const CharacterCreationDraft(
            classId: 8,
            classFeatureChoiceValue: 'Dragons',
          ),
        );
        expect(find.text('Étape Historique'), findsOneWidget);
      },
    );

    testWidgets('le bouton "Retour" revient à l\'étape Classe', (
      WidgetTester tester,
    ) async {
      fakeRepository.classCatalogToReturn = const ClassCatalog(
        classes: [_guerrier],
      );
      container
          .read(characterCreationDraftControllerProvider.notifier)
          .setClass(classId: 5);

      await pumpClassChoiceStep(tester);

      await tester.tap(find.text('RETOUR'));
      await tester.pumpAndSettle();

      expect(find.text('Étape Classe'), findsOneWidget);
    });

    testWidgets('erreur de chargement du catalogue de classes : message et '
        '"Réessayer", "Suivant" désactivé', (WidgetTester tester) async {
      fakeRepository.classCatalogErrorToThrow = const CharacterCreationFailure(
        'x',
      );
      container
          .read(characterCreationDraftControllerProvider.notifier)
          .setClass(classId: 5);

      await pumpClassChoiceStep(tester);

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(nextEnabled(tester), isFalse);

      fakeRepository.classCatalogErrorToThrow = null;
      fakeRepository.classCatalogToReturn = const ClassCatalog(
        classes: [_guerrier],
      );
      await tester.tap(find.text('RÉESSAYER'));
      await tester.pumpAndSettle();

      expect(find.text('Archerie'), findsOneWidget);
    });
  });

  group('cas défensif : classe non concernée / absente du brouillon', () {
    testWidgets(
      'classId absent du brouillon redirige vers l\'étape 2 "Classe"',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();
        router.push('/characters/new/class-choice');
        await tester.pumpAndSettle();

        expect(find.text('Étape Classe'), findsOneWidget);
      },
    );

    testWidgets(
      'classe non concernée (Magicien) redirige vers l\'étape 2 "Classe"',
      (WidgetTester tester) async {
        container
            .read(characterCreationDraftControllerProvider.notifier)
            .setClass(classId: 1);

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();
        router.push('/characters/new/class-choice');
        await tester.pumpAndSettle();

        expect(find.text('Étape Classe'), findsOneWidget);
      },
    );
  });

  group('Roublard (expertise)', () {
    Future<void> pumpRoublardStep(
      WidgetTester tester, {
      ClassOption classOption = _roublard,
      List<String> classSkillChoices = const ['Discrétion', 'Perception'],
      BackgroundOption backgroundOption = _ermite,
    }) async {
      fakeRepository.classCatalogToReturn = ClassCatalog(
        classes: [classOption],
      );
      fakeRepository.backgroundCatalogToReturn = BackgroundCatalog(
        backgrounds: [backgroundOption],
      );
      final notifier = container.read(
        characterCreationDraftControllerProvider.notifier,
      );
      notifier.setClass(classId: 9);
      notifier.setBackground(backgroundId: 10);
      notifier.setSkillsAndTools(
        classSkillChoices: classSkillChoices,
        classToolChoices: const [],
        backgroundLanguageChoices: const [],
      );
      await pumpClassChoiceStep(tester);
    }

    testWidgets('affiche "COMPÉTENCES MAÎTRISÉES" avec le badge de quota et '
        'les compétences candidates (classe + historique)', (
      WidgetTester tester,
    ) async {
      await pumpRoublardStep(tester);

      expect(find.text('2. Expertise'), findsOneWidget);
      expect(find.text('COMPÉTENCES MAÎTRISÉES'), findsOneWidget);
      expect(find.text('0 / 2 choisies'), findsOneWidget);
      expect(find.text('Discrétion'), findsOneWidget);
      expect(find.text('Perception'), findsOneWidget);
      // Compétence accordée par l'historique (Ermite), elle aussi
      // candidate — union dédupliquée classe/race/historique.
      expect(find.text('Médecine'), findsOneWidget);
      expect(nextEnabled(tester), isFalse);
    });

    testWidgets("régression D100 (`docs/dette-technique.md`) : AUCUNE option "
        "'outils de voleur' n'est affichée à ce stade (niveau 1, création) "
        "même si la classe l'accorde automatiquement (`grantedToolNames`) — "
        'RAW, la substitution de l\'Expertise par les outils de voleur '
        "n'existe qu'au niveau 6", (WidgetTester tester) async {
      await pumpRoublardStep(tester);

      expect(find.text('outils de voleur'), findsNothing);
    });

    testWidgets('2 compétences choisies -> "Suivant" actif, écrit '
        'expertiseSkillChoices sans substitution outils', (
      WidgetTester tester,
    ) async {
      await pumpRoublardStep(tester);

      await tester.tap(find.text('Discrétion'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Perception'));
      await tester.pumpAndSettle();

      expect(nextEnabled(tester), isTrue);

      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      final draft = readDraft();
      expect(draft.expertiseSkillChoices, ['Discrétion', 'Perception']);
      expect(draft.expertiseThievesToolsSubstitution, isFalse);
      expect(find.text('Étape Équipement'), findsOneWidget);
    });

    testWidgets(
      'quota atteint : les tuiles non cochées restantes sont désactivées, '
      'la tuile cochée reste décochable',
      (WidgetTester tester) async {
        await pumpRoublardStep(tester);

        await tester.tap(find.text('Discrétion'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Perception'));
        await tester.pumpAndSettle();

        final medecineTile = tester.widget<CheckableOptionTile>(
          find.ancestor(
            of: find.text('Médecine'),
            matching: find.byType(CheckableOptionTile),
          ),
        );
        expect(medecineTile.enabled, isFalse);

        final discretionTile = tester.widget<CheckableOptionTile>(
          find.ancestor(
            of: find.text('Discrétion'),
            matching: find.byType(CheckableOptionTile),
          ),
        );
        expect(discretionTile.enabled, isTrue);
        expect(discretionTile.checked, isTrue);
      },
    );

    testWidgets(
      'aucune compétence candidate ET aucun outil octroyé (cas défensif) : '
      'texte non bloquant, "Suivant" déjà actif',
      (WidgetTester tester) async {
        await pumpRoublardStep(
          tester,
          classOption: _roublardSansOutils,
          classSkillChoices: const [],
          backgroundOption: _ermiteSansCompetence,
        );

        expect(
          find.textContaining("Aucune option n'est disponible"),
          findsOneWidget,
        );
        expect(nextEnabled(tester), isTrue);
      },
    );

    testWidgets('mode modification : "Suivant" pousse l\'étape 8/9 "Apparence" '
        '(étape Équipement toujours sautée), pas l\'étape 7/9', (
      WidgetTester tester,
    ) async {
      const editDraft = CharacterCreationDraft(classId: 9);
      container
          .read(characterCreationDraftControllerProvider.notifier)
          .replaceWith(editDraft);
      container
          .read(characterEditSessionControllerProvider.notifier)
          .start(
            CharacterEditSession(
              snapshot: CharacterEditSnapshot(
                characterId: 'c1',
                name: 'Fennick',
                primaryClassId: 9,
                primaryClassLevel: 1,
                totalLevel: 1,
                maxHp: 10,
                currentHp: 10,
              ),
              originalDraft: editDraft,
            ),
          );
      await pumpRoublardStep(tester);

      await tester.tap(find.text('Discrétion'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Perception'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      expect(find.text('Étape Apparence'), findsOneWidget);
      expect(find.text('Étape Équipement'), findsNothing);
    });
  });
}
