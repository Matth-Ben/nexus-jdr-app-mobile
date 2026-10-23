// Tests de widget de l'étape "Sous-classe" de l'assistant de création,
// second écran de l'étape 2/9 "Classe" — atteinte uniquement depuis
// `ClassStepScreen` pour une classe qui choisit sa sous-classe au niveau 1
// (voir sa doc de classe). Même principe que `class_step_screen_test.dart` :
// dépôts factices injectés via `overrideWithValue`, aucun appel réseau réel.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/core/widgets/selectable_option_tile.dart';
import 'package:personnages/features/character_creation/data/character_creation_repository.dart';
import 'package:personnages/features/character_creation/data/subclass_choice_repository.dart';
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
import 'package:personnages/features/character_creation/domain/skill_catalog.dart';
import 'package:personnages/features/character_creation/domain/spell_catalog.dart';
import 'package:personnages/features/character_creation/domain/subclass_catalog.dart';
import 'package:personnages/features/character_creation/domain/subclass_choice_catalog.dart';
import 'package:personnages/features/character_creation/domain/subclass_choice_option.dart';
import 'package:personnages/features/character_creation/domain/subclass_feature_choice.dart';
import 'package:personnages/features/character_creation/domain/subclass_feature_option.dart';
import 'package:personnages/features/character_creation/domain/tool_catalog.dart';
import 'package:personnages/features/character_creation/data/subclass_feature_choice_repository.dart';
import 'package:personnages/features/character_creation/domain/character_edit_snapshot.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_draft_provider.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_providers.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_edit_session_provider.dart';
import 'package:personnages/features/character_creation/presentation/providers/subclass_choice_providers.dart';
import 'package:personnages/features/character_creation/presentation/providers/subclass_feature_choice_providers.dart';
import 'package:personnages/features/character_creation/presentation/subclass_step_screen.dart';

class _FakeCharacterCreationRepository implements CharacterCreationRepository {
  ClassCatalog? catalogToReturn;

  @override
  Future<RaceCatalog> fetchRaceCatalog() async =>
      const RaceCatalog(races: [], subraces: []);

  @override
  Future<ClassCatalog> fetchClassCatalog() async =>
      catalogToReturn ?? const ClassCatalog(classes: []);

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
  Future<SubclassCatalog> fetchSubclassCatalog() async =>
      const SubclassCatalog(subclasses: []);

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

  @override
  Future<SubclassChoiceCatalog> fetchLevelOneSubclassChoices() async {
    if (completer != null) return completer!.future;
    if (errorToThrow != null) throw errorToThrow!;
    return catalog;
  }
}

class _FakeSubclassFeatureChoiceRepository
    implements SubclassFeatureChoiceRepository {
  SubclassFeatureChoice? choiceToReturn;
  Object? errorToThrow;

  @override
  Future<SubclassFeatureChoice?> fetchFor(int subclassId) async {
    if (errorToThrow != null) throw errorToThrow!;
    return choiceToReturn;
  }
}

const _clerc = ClassOption(
  id: 3,
  name: 'Clerc',
  description: 'Prêtre.',
  hitDie: 8,
);

const _ensorceleur = ClassOption(
  id: 6,
  name: 'Ensorceleur',
  description: 'Lanceur inné.',
  hitDie: 6,
);

const _vie = SubclassChoiceOption(id: 31, name: 'Domaine de la Vie');
const _guerre = SubclassChoiceOption(id: 32, name: 'Domaine de la Guerre');
const _lignageDraconique = SubclassChoiceOption(
  id: 12,
  name: 'Lignage draconique',
);

const _dragonRouge = SubclassFeatureOption(id: 1, name: 'Dragon rouge');
const _dragonBleu = SubclassFeatureOption(id: 2, name: 'Dragon bleu');

void main() {
  late _FakeCharacterCreationRepository fakeRepository;
  late _FakeSubclassChoiceRepository fakeSubclassRepository;
  late _FakeSubclassFeatureChoiceRepository fakeFeatureRepository;
  late ProviderContainer container;
  late GoRouter router;

  setUp(() {
    fakeRepository = _FakeCharacterCreationRepository();
    fakeRepository.catalogToReturn = const ClassCatalog(
      classes: [_clerc, _ensorceleur],
    );
    fakeSubclassRepository = _FakeSubclassChoiceRepository();
    fakeSubclassRepository.catalog = const SubclassChoiceCatalog(
      optionsByClassId: {
        3: [_vie, _guerre],
        6: [_lignageDraconique],
      },
    );
    fakeFeatureRepository = _FakeSubclassFeatureChoiceRepository();
    container = ProviderContainer(
      overrides: [
        characterCreationRepositoryProvider.overrideWithValue(fakeRepository),
        subclassChoiceRepositoryProvider.overrideWithValue(
          fakeSubclassRepository,
        ),
        subclassFeatureChoiceRepositoryProvider.overrideWithValue(
          fakeFeatureRepository,
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  // `initialLocation` reste l'étape "Classe" (stub) : `SubclassStepScreen`
  // est atteinte via un `push`, comme dans la vraie navigation
  // (`class_step_screen.dart` pousse `/characters/new/subclass`).
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
          path: '/characters/new/subclass',
          builder: (context, state) => const SubclassStepScreen(),
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

  Future<void> pumpSubclassStep(WidgetTester tester) async {
    container
        .read(characterCreationDraftControllerProvider.notifier)
        .setClass(classId: 3, subclassId: null);
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();
    router.push('/characters/new/subclass');
    await tester.pumpAndSettle();
  }

  /// Variante pour le second choix de niveau 1 propre à la sous-classe
  /// (Ancêtre draconique, correctif D99) — classe/sous-classe paramétrables,
  /// la sous-classe étant déjà choisie à l'arrivée (contrairement à
  /// [pumpSubclassStep], qui part d'un choix encore vide).
  Future<void> pumpSubclassFeatureStep(
    WidgetTester tester, {
    required int classId,
    required int subclassId,
  }) async {
    container
        .read(characterCreationDraftControllerProvider.notifier)
        .setClass(classId: classId, subclassId: subclassId);
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();
    router.push('/characters/new/subclass');
    await tester.pumpAndSettle();
  }

  bool nextEnabled(WidgetTester tester) =>
      tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed !=
      null;

  /// Variante [pumpSubclassFeatureStep] démarrant une session de
  /// modification avant de pomper l'écran — correctif D102
  /// (`docs/dette-technique.md`) : au niveau 1 (classe modifiable),
  /// `SubclassFeatureChoiceBlock` s'affiche désormais comme à la création ;
  /// au-delà, il reste hors de portée (voir le groupe de tests dédié).
  Future<void> pumpSubclassFeatureStepInEditMode(
    WidgetTester tester, {
    required int classId,
    required int subclassId,
    int totalLevel = 1,
  }) async {
    final draft = CharacterCreationDraft(
      classId: classId,
      subclassId: subclassId,
    );
    container
        .read(characterCreationDraftControllerProvider.notifier)
        .replaceWith(draft);
    container
        .read(characterEditSessionControllerProvider.notifier)
        .start(
          CharacterEditSession(
            snapshot: CharacterEditSnapshot(
              characterId: 'c1',
              name: 'Brunhilde',
              primaryClassId: classId,
              primaryClassLevel: totalLevel,
              totalLevel: totalLevel,
              maxHp: 8,
              currentHp: 8,
            ),
            originalDraft: draft,
          ),
        );
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();
    router.push('/characters/new/subclass');
    await tester.pumpAndSettle();
  }

  testWidgets('charge le nom de la classe et les options de sous-classe', (
    WidgetTester tester,
  ) async {
    await pumpSubclassStep(tester);

    expect(find.textContaining('Clerc'), findsWidgets);
    expect(find.text('Domaine de la Vie'), findsOneWidget);
    expect(find.text('Domaine de la Guerre'), findsOneWidget);
  });

  testWidgets('"Suivant" est désactivé tant qu\'aucune sous-classe n\'est '
      'choisie', (WidgetTester tester) async {
    await pumpSubclassStep(tester);

    expect(nextEnabled(tester), isFalse);

    await tester.tap(find.text('SUIVANT'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(readDraft(), const CharacterCreationDraft(classId: 3));
    expect(find.text('Étape suivante'), findsNothing);
  });

  testWidgets(
    'sélectionner une sous-classe puis "Suivant" écrit le brouillon et '
    'navigue vers l\'étape 3/9',
    (WidgetTester tester) async {
      await pumpSubclassStep(tester);

      await tester.tap(find.text('Domaine de la Vie'));
      await tester.pumpAndSettle();

      expect(nextEnabled(tester), isTrue);

      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      expect(
        readDraft(),
        const CharacterCreationDraft(classId: 3, subclassId: 31),
      );
      expect(find.text('Étape suivante'), findsOneWidget);
    },
  );

  testWidgets('le bouton "Retour" revient à l\'étape Classe', (
    WidgetTester tester,
  ) async {
    await pumpSubclassStep(tester);

    await tester.tap(find.text('RETOUR'));
    await tester.pumpAndSettle();

    expect(find.text('Étape Classe'), findsOneWidget);
  });

  testWidgets(
    'le bouton "Retour" utilise la variante "parchemin" du bouton secondaire',
    (WidgetTester tester) async {
      await pumpSubclassStep(tester);

      final backButton = tester
          .widgetList<SecondaryButton>(find.byType(SecondaryButton))
          .firstWhere((button) => button.label == 'Retour');

      expect(backButton.surface, SecondaryButtonSurface.parchment);
    },
  );

  testWidgets(
    'réhydrate un brouillon déjà rempli (retour en arrière depuis une étape '
    'suivante, docs/cahier-des-charges/05-ux-navigation.md)',
    (WidgetTester tester) async {
      container
          .read(characterCreationDraftControllerProvider.notifier)
          .setClass(classId: 3, subclassId: 32);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      router.push('/characters/new/subclass');
      await tester.pumpAndSettle();

      final tiles = tester.widgetList<SelectableOptionTile>(
        find.byType(SelectableOptionTile),
      );
      expect(
        tiles.firstWhere((t) => t.title == 'Domaine de la Guerre').selected,
        isTrue,
      );
      expect(
        tiles.firstWhere((t) => t.title == 'Domaine de la Vie').selected,
        isFalse,
      );
      expect(nextEnabled(tester), isTrue);

      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      expect(
        readDraft(),
        const CharacterCreationDraft(classId: 3, subclassId: 32),
      );
    },
  );

  testWidgets(
    'aucun classId dans le brouillon (cas défensif, ex. deep-link direct) '
    'redirige vers l\'étape 2 "Classe"',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      router.push('/characters/new/subclass');
      await tester.pumpAndSettle();

      expect(find.text('Étape Classe'), findsOneWidget);
    },
  );

  testWidgets(
    'erreur de chargement du catalogue : message et "Réessayer", "Suivant" '
    'désactivé',
    (WidgetTester tester) async {
      fakeSubclassRepository.errorToThrow = const CharacterCreationFailure('x');

      await pumpSubclassStep(tester);

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(nextEnabled(tester), isFalse);

      fakeSubclassRepository.errorToThrow = null;
      await tester.tap(find.text('RÉESSAYER'));
      await tester.pumpAndSettle();

      expect(find.text('Domaine de la Vie'), findsOneWidget);
    },
  );

  group('SubclassFeatureChoiceBlock (correctif D99, Ancêtre draconique)', () {
    testWidgets(
      'affiche les options et bloque "Suivant" tant qu\'aucune n\'est '
      'choisie',
      (WidgetTester tester) async {
        fakeFeatureRepository.choiceToReturn = const SubclassFeatureChoice(
          classFeatureId: 368,
          featureName: 'Ancêtre draconique',
          options: [_dragonRouge, _dragonBleu],
        );

        await pumpSubclassFeatureStep(tester, classId: 6, subclassId: 12);

        expect(find.text('Ancêtre draconique'), findsOneWidget);
        expect(find.text('Dragon rouge'), findsOneWidget);
        expect(find.text('Dragon bleu'), findsOneWidget);
        expect(nextEnabled(tester), isFalse);
      },
    );

    testWidgets(
      'sélectionner une option écrit subclassFeatureChoiceValue dans le '
      'brouillon et active "Suivant"',
      (WidgetTester tester) async {
        fakeFeatureRepository.choiceToReturn = const SubclassFeatureChoice(
          classFeatureId: 368,
          featureName: 'Ancêtre draconique',
          options: [_dragonRouge, _dragonBleu],
        );

        await pumpSubclassFeatureStep(tester, classId: 6, subclassId: 12);

        await tester.tap(find.text('Dragon rouge'));
        await tester.pumpAndSettle();

        expect(nextEnabled(tester), isTrue);

        await tester.tap(find.text('SUIVANT'));
        await tester.pumpAndSettle();

        expect(
          readDraft(),
          const CharacterCreationDraft(
            classId: 6,
            subclassId: 12,
            subclassFeatureChoiceValue: 'Dragon rouge',
          ),
        );
      },
    );

    testWidgets(
      'sous-classe sans second choix (choix == null) : aucun bloc affiché, '
      '"Suivant" jamais bloqué par ce choix',
      (WidgetTester tester) async {
        fakeFeatureRepository.choiceToReturn = null;

        await pumpSubclassFeatureStep(tester, classId: 3, subclassId: 31);

        expect(find.text('Ancêtre draconique'), findsNothing);
        expect(nextEnabled(tester), isTrue);
      },
    );

    testWidgets('catalogue de class_options vide (D95, script SQL pas encore '
        'exécuté) : texte défensif non bloquant', (WidgetTester tester) async {
      fakeFeatureRepository.choiceToReturn = const SubclassFeatureChoice(
        classFeatureId: 368,
        featureName: 'Ancêtre draconique',
        options: [],
      );

      await pumpSubclassFeatureStep(tester, classId: 6, subclassId: 12);

      expect(
        find.textContaining("Aucune option n'est disponible"),
        findsOneWidget,
      );
      expect(nextEnabled(tester), isTrue);
    });

    testWidgets(
      'correctif D102 (docs/dette-technique.md) : en mode modification '
      "d'un personnage Ensorceleur de niveau 1 avec le Lignage draconique "
      'déjà choisi, le bloc "Ancêtre draconique" s\'affiche exactement '
      'comme à la création — `CharacterEditHydrator`/'
      '`CharacterEditPlanner`/`CharacterEditRepository` pré-remplissent et '
      'persistent désormais `subclassFeatureChoiceValue` au même titre que '
      'la sous-classe elle-même',
      (WidgetTester tester) async {
        fakeFeatureRepository.choiceToReturn = const SubclassFeatureChoice(
          classFeatureId: 368,
          featureName: 'Ancêtre draconique',
          options: [_dragonRouge, _dragonBleu],
        );

        await pumpSubclassFeatureStepInEditMode(
          tester,
          classId: 6,
          subclassId: 12,
        );

        expect(find.text('Ancêtre draconique'), findsOneWidget);
        expect(find.text('Dragon rouge'), findsOneWidget);
        expect(find.text('Dragon bleu'), findsOneWidget);
        expect(nextEnabled(tester), isFalse);

        await tester.tap(find.text('Dragon rouge'));
        await tester.pumpAndSettle();

        expect(nextEnabled(tester), isTrue);

        await tester.tap(find.text('SUIVANT'));
        await tester.pumpAndSettle();

        expect(readDraft().subclassFeatureChoiceValue, 'Dragon rouge');
        expect(find.text('Étape suivante'), findsOneWidget);
      },
    );

    testWidgets(
      'correctif D102 (docs/dette-technique.md) : au-delà du niveau 1, le '
      'bloc "Ancêtre draconique" reste hors de portée en édition (classe/'
      'sous-classe verrouillées) — accès direct défensif à cette route, '
      "cet écran n'étant de toute façon jamais poussé par "
      '`ClassStepScreen._submit` dans ce cas',
      (WidgetTester tester) async {
        fakeFeatureRepository.choiceToReturn = const SubclassFeatureChoice(
          classFeatureId: 368,
          featureName: 'Ancêtre draconique',
          options: [_dragonRouge, _dragonBleu],
        );

        await pumpSubclassFeatureStepInEditMode(
          tester,
          classId: 6,
          subclassId: 12,
          totalLevel: 5,
        );

        expect(find.text('Ancêtre draconique'), findsNothing);
        expect(find.text('Dragon rouge'), findsNothing);
        expect(find.text('Dragon bleu'), findsNothing);
      },
    );
  });
}
