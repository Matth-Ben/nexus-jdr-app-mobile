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
import 'package:personnages/features/character_creation/domain/subclass_choice_catalog.dart';
import 'package:personnages/features/character_creation/domain/subclass_choice_option.dart';
import 'package:personnages/features/character_creation/domain/tool_catalog.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_draft_provider.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_providers.dart';
import 'package:personnages/features/character_creation/presentation/providers/subclass_choice_providers.dart';
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

const _clerc = ClassOption(
  id: 3,
  name: 'Clerc',
  description: 'Prêtre.',
  hitDie: 8,
);

const _vie = SubclassChoiceOption(id: 31, name: 'Domaine de la Vie');
const _guerre = SubclassChoiceOption(id: 32, name: 'Domaine de la Guerre');

void main() {
  late _FakeCharacterCreationRepository fakeRepository;
  late _FakeSubclassChoiceRepository fakeSubclassRepository;
  late ProviderContainer container;
  late GoRouter router;

  setUp(() {
    fakeRepository = _FakeCharacterCreationRepository();
    fakeRepository.catalogToReturn = const ClassCatalog(classes: [_clerc]);
    fakeSubclassRepository = _FakeSubclassChoiceRepository();
    fakeSubclassRepository.catalog = const SubclassChoiceCatalog(
      optionsByClassId: {
        3: [_vie, _guerre],
      },
    );
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

  bool nextEnabled(WidgetTester tester) =>
      tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed !=
      null;

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
}
