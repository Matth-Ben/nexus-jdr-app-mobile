// Tests de widget de l'étape 9/9 de l'assistant de création
// ("Récapitulatif").
//
// Même principe que les étapes précédentes : dépôt factice injecté via
// `overrideWithValue`, aucun appel réseau réel. La pile de navigation est
// reconstruite en poussant successivement toutes les routes stub 2 à 9,
// comme la vraie navigation (chaque étape pousse la suivante) — nécessaire
// pour vérifier la mécanique "pop N fois" des icônes crayon
// (`SummaryStepScreen._editStep`, voir sa documentation).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/character_creation/data/character_creation_repository.dart';
import 'package:personnages/features/character_creation/domain/alignment_catalog.dart';
import 'package:personnages/features/character_creation/domain/background_catalog.dart';
import 'package:personnages/features/character_creation/domain/background_option.dart';
import 'package:personnages/features/character_creation/domain/character_creation_draft.dart';
import 'package:personnages/features/character_creation/domain/character_creation_failure.dart';
import 'package:personnages/features/character_creation/domain/class_catalog.dart';
import 'package:personnages/features/character_creation/domain/class_option.dart';
import 'package:personnages/features/character_creation/domain/class_skill_choices.dart';
import 'package:personnages/features/character_creation/domain/equipment_choice_tab.dart';
import 'package:personnages/features/character_creation/domain/item_catalog.dart';
import 'package:personnages/features/character_creation/domain/language_catalog.dart';
import 'package:personnages/features/character_creation/domain/language_option.dart';
import 'package:personnages/features/character_creation/domain/race_catalog.dart';
import 'package:personnages/features/character_creation/domain/race_option.dart';
import 'package:personnages/features/character_creation/domain/skill_catalog.dart';
import 'package:personnages/features/character_creation/domain/skill_option.dart';
import 'package:personnages/features/character_creation/domain/spell_catalog.dart';
import 'package:personnages/features/character_creation/domain/spell_option.dart';
import 'package:personnages/features/character_creation/domain/tool_catalog.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_draft_provider.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_providers.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_return_route_provider.dart';
import 'package:personnages/features/character_creation/presentation/summary_step_screen.dart';

class _FakeCharacterCreationRepository implements CharacterCreationRepository {
  RaceCatalog raceCatalogToReturn = const RaceCatalog(races: [], subraces: []);
  ClassCatalog classCatalogToReturn = const ClassCatalog(classes: []);
  BackgroundCatalog backgroundCatalogToReturn = const BackgroundCatalog(
    backgrounds: [],
  );
  SkillCatalog skillCatalogToReturn = const SkillCatalog(skills: []);
  ToolCatalog toolCatalogToReturn = const ToolCatalog(tools: []);
  LanguageCatalog languageCatalogToReturn = const LanguageCatalog(
    languages: [],
  );
  SpellCatalog spellCatalogToReturn = const SpellCatalog(spells: []);
  ItemCatalog itemCatalogToReturn = const ItemCatalog(items: []);

  Object? classCatalogErrorToThrow;
  Completer<ClassCatalog>? classCatalogCompleter;

  Object? createCharacterErrorToThrow;
  Completer<String>? createCharacterCompleter;
  CharacterCreationDraft? capturedDraft;
  String? capturedCharacterName;
  int createCharacterCallCount = 0;

  @override
  Future<RaceCatalog> fetchRaceCatalog() async => raceCatalogToReturn;

  @override
  Future<ClassCatalog> fetchClassCatalog() async {
    if (classCatalogCompleter != null) {
      return classCatalogCompleter!.future;
    }
    if (classCatalogErrorToThrow != null) {
      throw classCatalogErrorToThrow!;
    }
    return classCatalogToReturn;
  }

  @override
  Future<BackgroundCatalog> fetchBackgroundCatalog() async =>
      backgroundCatalogToReturn;

  @override
  Future<ToolCatalog> fetchToolCatalog() async => toolCatalogToReturn;

  @override
  Future<LanguageCatalog> fetchLanguageCatalog() async =>
      languageCatalogToReturn;

  @override
  Future<SpellCatalog> fetchSpellCatalog({required int classId}) async =>
      spellCatalogToReturn;

  @override
  Future<ItemCatalog> fetchItemCatalog() async => itemCatalogToReturn;

  @override
  Future<SkillCatalog> fetchSkillCatalog() async => skillCatalogToReturn;

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
  }) async {
    createCharacterCallCount++;
    capturedDraft = draft;
    capturedCharacterName = characterName;
    if (createCharacterCompleter != null) {
      return createCharacterCompleter!.future;
    }
    if (createCharacterErrorToThrow != null) {
      throw createCharacterErrorToThrow!;
    }
    return 'new-character-id';
  }
}

const _elfe = RaceOption(
  id: 1,
  name: 'Elfe',
  abilityBonuses: {'dex': 2},
  traits: [],
);

const _magicien = ClassOption(
  id: 2,
  name: 'Magicien',
  description: '',
  hitDie: 6,
  skillChoices: ClassSkillChoices(count: 1, choices: ['Histoire']),
);

const _sage = BackgroundOption(
  id: 3,
  name: 'Sage',
  skillProficiencies: ['Arcanes'],
  featureName: '',
  featureDescription: '',
  equipment: ['Bourse (10 po)'],
);

const _histoireSkill = SkillOption(id: 10, name: 'Histoire', abilityId: 'int');
const _arcanesSkill = SkillOption(id: 11, name: 'Arcanes', abilityId: 'int');

const _elfiqueLanguage = LanguageOption(
  id: 20,
  name: 'Elfique',
  type: 'standard',
);

const _lumiereSpell = SpellOption(
  id: 30,
  name: 'Lumière',
  level: 0,
  school: 'Évocation',
  castingTime: '1 action',
);
const _boucherSpell = SpellOption(
  id: 31,
  name: 'Bouclier',
  level: 1,
  school: 'Abjuration',
  castingTime: '1 réaction',
);

/// Brouillon complet pour un Magicien (Elfe/Sage), lanceur de sorts, avec des
/// langues d'historique choisies — utilisé par la plupart des tests
/// ci-dessous, chacun ne surchargeant que ce qui l'intéresse via `copyWith`.
final _fullDraft = const CharacterCreationDraft(
  raceId: 1,
  classId: 2,
  backgroundId: 3,
  abilityScores: {
    'str': 8,
    'dex': 14,
    'con': 13,
    'int': 15,
    'wis': 10,
    'cha': 12,
  },
  classSkillChoices: ['Histoire'],
  backgroundLanguageChoices: ['Elfique'],
  classCantripChoices: ['Lumière'],
  classLevelOneSpellChoices: ['Bouclier'],
  equipmentChoiceTab: EquipmentChoiceTab.background,
  appearanceText: 'Grand et mince',
);

void main() {
  late _FakeCharacterCreationRepository fakeRepository;
  late ProviderContainer container;
  late GoRouter router;

  setUp(() {
    fakeRepository = _FakeCharacterCreationRepository()
      ..raceCatalogToReturn = const RaceCatalog(races: [_elfe], subraces: [])
      ..classCatalogToReturn = const ClassCatalog(classes: [_magicien])
      ..backgroundCatalogToReturn = const BackgroundCatalog(
        backgrounds: [_sage],
      )
      ..skillCatalogToReturn = const SkillCatalog(
        skills: [_histoireSkill, _arcanesSkill],
      )
      ..languageCatalogToReturn = const LanguageCatalog(
        languages: [_elfiqueLanguage],
      )
      ..spellCatalogToReturn = const SpellCatalog(
        spells: [_lumiereSpell, _boucherSpell],
      );
    container = ProviderContainer(
      overrides: [
        characterCreationRepositoryProvider.overrideWithValue(fakeRepository),
      ],
    );
    container.read(characterCreationDraftControllerProvider.notifier).state =
        _fullDraft;
  });

  tearDown(() {
    container.dispose();
  });

  // Pile complète, poussée pas à pas comme la vraie navigation (chaque
  // étape pousse la suivante) — nécessaire pour les tests de navigation
  // d'édition ("pop N fois").
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
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Étape Classe'))),
        ),
        GoRoute(
          path: '/characters/new/step-3',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Étape Historique'))),
        ),
        GoRoute(
          path: '/characters/new/step-4',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Étape Caractéristiques')),
          ),
        ),
        GoRoute(
          path: '/characters/new/step-5',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Étape Compétences'))),
        ),
        GoRoute(
          path: '/characters/new/step-6',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Étape Sorts'))),
        ),
        GoRoute(
          path: '/characters/new/step-7',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Étape Équipement'))),
        ),
        GoRoute(
          path: '/characters/new/step-8',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Étape Histoire'))),
        ),
        GoRoute(
          path: '/characters/new/step-9',
          builder: (context, state) => const SummaryStepScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Liste des personnages')),
          ),
        ),
        GoRoute(
          path: '/join/step-3',
          builder: (context, state) => Scaffold(
            body: Center(
              child: Text(
                'Étape 3 Rejoindre code=${state.uri.queryParameters['code']}',
              ),
            ),
          ),
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

  // Surface de test agrandie en hauteur — même rationale que
  // `ability_score_step_screen_test.dart` : le contenu de cet écran (champ
  // nom, carte d'en-tête, jusqu'à 8 lignes de résumé) dépasse la hauteur par
  // défaut du banc de test (~600 logiques), ce qui ferait manquer aux
  // `find.text(...)` les lignes non construites par la `ListView` (qui ne
  // construit que les éléments visibles).
  void growTestViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> pumpSummaryStep(WidgetTester tester) async {
    growTestViewport(tester);
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();
    for (final step in [
      'step-2',
      'step-3',
      'step-4',
      'step-5',
      'step-6',
      'step-7',
      'step-8',
      'step-9',
    ]) {
      router.push('/characters/new/$step');
    }
    await tester.pumpAndSettle();
  }

  CharacterCreationDraft readDraft() =>
      container.read(characterCreationDraftControllerProvider);

  testWidgets('affiche un indicateur de chargement pendant la récupération', (
    WidgetTester tester,
  ) async {
    fakeRepository.classCatalogCompleter = Completer<ClassCatalog>();

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();
    router.push('/characters/new/step-9');
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets(
    'affiche un état d\'erreur avec un bouton "Réessayer" si un catalogue '
    'échoue à charger',
    (WidgetTester tester) async {
      fakeRepository.classCatalogErrorToThrow = const CharacterCreationFailure(
        'Impossible de charger les classes disponibles. Réessayez.',
      );

      await pumpSummaryStep(tester);

      expect(
        find.text('Impossible de charger les classes disponibles. Réessayez.'),
        findsOneWidget,
      );

      fakeRepository.classCatalogErrorToThrow = null;

      await tester.tap(find.text('RÉESSAYER'));
      await tester.pumpAndSettle();

      expect(find.text('NOM DU PERSONNAGE'), findsOneWidget);
    },
  );

  testWidgets('affiche la carte d\'en-tête et les lignes de résumé toujours '
      'affichées, avec le champ nom et son texte d\'aide', (
    WidgetTester tester,
  ) async {
    await pumpSummaryStep(tester);

    expect(find.text('NOM DU PERSONNAGE'), findsOneWidget);
    expect(
      find.text('Requis pour retrouver facilement ton personnage'),
      findsOneWidget,
    );
    expect(find.text('Elfe · Magicien · Niveau 1'), findsOneWidget);

    expect(find.text('Caractéristiques'), findsOneWidget);
    expect(find.text('Compétences'), findsOneWidget);
    expect(find.text('Équipement'), findsOneWidget);
    expect(find.text('Historique : Sage'), findsOneWidget);
    expect(find.text('Histoire & portrait'), findsOneWidget);
    expect(find.text('Renseignés'), findsOneWidget);
  });

  testWidgets(
    'masque "Outils" quand classToolChoices est vide, affiche "Langues" '
    'quand backgroundLanguageChoices est non vide',
    (WidgetTester tester) async {
      await pumpSummaryStep(tester);

      expect(find.text('Outils'), findsNothing);
      expect(find.text('Langues'), findsOneWidget);
      expect(find.text('Elfique'), findsOneWidget);
    },
  );

  testWidgets(
    'affiche "Sorts mineurs"/"Sorts niveau 1" pour une classe lanceuse de '
    'sorts, avec le nombre sélectionné',
    (WidgetTester tester) async {
      await pumpSummaryStep(tester);

      expect(find.text('Sorts mineurs'), findsOneWidget);
      expect(find.text('1 sélectionné(s)'), findsNWidgets(2));
    },
  );

  testWidgets(
    'masque "Sorts mineurs"/"Sorts niveau 1" pour une classe non lanceuse '
    'de sorts',
    (WidgetTester tester) async {
      const guerrier = ClassOption(
        id: 4,
        name: 'Guerrier',
        description: '',
        hitDie: 10,
        skillChoices: ClassSkillChoices(count: 1, choices: ['Athlétisme']),
      );
      fakeRepository.classCatalogToReturn = const ClassCatalog(
        classes: [guerrier],
      );
      container.read(characterCreationDraftControllerProvider.notifier).state =
          _fullDraft.copyWith(classId: 4);

      await pumpSummaryStep(tester);

      expect(find.text('Sorts mineurs'), findsNothing);
      expect(find.text('Sorts niveau 1'), findsNothing);
    },
  );

  testWidgets(
    '"Créer le personnage" est désactivé tant que le nom est vide, activé '
    'dès qu\'un nom non blanc est saisi',
    (WidgetTester tester) async {
      await pumpSummaryStep(tester);

      var button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(button.onPressed, isNull);

      await tester.enterText(find.byType(TextFormField), 'Halltesse Ambrelune');
      await tester.pump();

      button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(button.onPressed, isNotNull);

      await tester.enterText(find.byType(TextFormField), '   ');
      await tester.pump();

      button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(button.onPressed, isNull);
    },
  );

  testWidgets('réhydrate le nom déjà saisi depuis le brouillon', (
    WidgetTester tester,
  ) async {
    container.read(characterCreationDraftControllerProvider.notifier).state =
        _fullDraft.copyWith(characterName: 'Halltesse Ambrelune');

    await pumpSummaryStep(tester);

    // `findsWidgets` (pas `findsOneWidget`) : le nom apparaît à la fois dans
    // le champ de saisie et dans l'aperçu de la carte d'en-tête (mis à jour
    // en direct à chaque frappe, voir `_HeaderCard`).
    expect(find.text('Halltesse Ambrelune'), findsWidgets);
    final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets(
    '"Retour" commite le nom saisi dans le brouillon avant de revenir à '
    "l'étape précédente",
    (WidgetTester tester) async {
      await pumpSummaryStep(tester);

      await tester.enterText(find.byType(TextFormField), 'Halltesse Ambrelune');
      await tester.tap(find.text('‹ Retour'));
      await tester.pumpAndSettle();

      expect(find.text('Étape Histoire'), findsOneWidget);
      expect(readDraft().characterName, 'Halltesse Ambrelune');
    },
  );

  testWidgets(
    'tapoter le crayon d\'une ligne dépile jusqu\'à l\'étape correspondante '
    '(ex. "Compétences" -> étape 5)',
    (WidgetTester tester) async {
      await pumpSummaryStep(tester);

      final competencesRow = find.ancestor(
        of: find.text('Compétences'),
        matching: find.byType(InkWell),
      );
      await tester.tap(competencesRow.first);
      await tester.pumpAndSettle();

      expect(find.text('Étape Compétences'), findsOneWidget);
    },
  );

  // Régression : pour une classe NON lanceuse de sorts, la navigation réelle
  // ne pousse jamais l'étape 6 (`skills_and_tools_step_screen.dart` saute
  // directement à `/characters/new/step-7`, voir son commentaire). La pile
  // reconstruite ci-dessous reproduit fidèlement ce cas (step-6 omise), ce
  // que `pumpSummaryStep` (toujours 8 étapes, step-6 incluse) ne fait
  // jamais — voir le rapport QA de l'étape 9/9 : `_editStep` calcule
  // `popsNeeded = _totalSteps - stepNumber` (une formule qui suppose que les
  // 9 étapes sont TOUTES présentes dans la pile), ce qui dépile un cran de
  // trop pour toute ligne ciblant une étape <= 5 dès que l'étape 6 est
  // absente de la pile.
  Future<void> pumpSummaryStepForNonCasterClass(WidgetTester tester) async {
    const guerrier = ClassOption(
      id: 4,
      name: 'Guerrier',
      description: '',
      hitDie: 10,
      skillChoices: ClassSkillChoices(count: 1, choices: ['Athlétisme']),
    );
    fakeRepository.classCatalogToReturn = const ClassCatalog(
      classes: [guerrier],
    );
    container.read(characterCreationDraftControllerProvider.notifier).state =
        _fullDraft.copyWith(classId: 4, classSkillChoices: ['Athlétisme']);

    growTestViewport(tester);
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();
    for (final step in [
      'step-2',
      'step-3',
      'step-4',
      'step-5',
      // Pas de 'step-6' : jamais poussée en navigation réelle pour une
      // classe non lanceuse de sorts (voir
      // `skills_and_tools_step_screen.dart`).
      'step-7',
      'step-8',
      'step-9',
    ]) {
      router.push('/characters/new/$step');
    }
    await tester.pumpAndSettle();
  }

  testWidgets(
    'RÉGRESSION : pour une classe non lanceuse de sorts (étape 6 absente de '
    'la pile), tapoter le crayon "Caractéristiques" dépile jusqu\'à l\'étape '
    '4 (Caractéristiques), pas l\'étape 3 (Historique)',
    (WidgetTester tester) async {
      await pumpSummaryStepForNonCasterClass(tester);

      final caracteristiquesRow = find.ancestor(
        of: find.text('Caractéristiques'),
        matching: find.byType(InkWell),
      );
      await tester.tap(caracteristiquesRow.first);
      await tester.pumpAndSettle();

      expect(
        find.text('Étape Caractéristiques'),
        findsOneWidget,
        reason:
            "_editStep dépile _totalSteps(9) - stepNumber(4) = 5 fois, alors "
            "que seuls 4 pops séparent l'étape 9 de l'étape 4 quand l'étape "
            "6 est absente de la pile (classe non lanceuse) : le 5e pop "
            "atterrit sur l'étape 3 (Historique) au lieu de 4.",
      );
    },
  );

  testWidgets(
    'RÉGRESSION : pour une classe non lanceuse de sorts (étape 6 absente de '
    'la pile), tapoter le crayon "Compétences" dépile jusqu\'à l\'étape 5 '
    '(Compétences), pas l\'étape 4 (Caractéristiques)',
    (WidgetTester tester) async {
      await pumpSummaryStepForNonCasterClass(tester);

      final competencesRow = find.ancestor(
        of: find.text('Compétences'),
        matching: find.byType(InkWell),
      );
      await tester.tap(competencesRow.first);
      await tester.pumpAndSettle();

      expect(
        find.text('Étape Compétences'),
        findsOneWidget,
        reason:
            "même bug que le test précédent, décalé d'une étape : "
            "_editStep dépile 9 - 5 = 4 fois au lieu des 3 pops réellement "
            "nécessaires, atterrissant sur l'étape 4 (Caractéristiques) au "
            "lieu de 5.",
      );
    },
  );

  testWidgets(
    'tapoter le crayon de la ligne "Équipement" dépile jusqu\'à l\'étape 7',
    (WidgetTester tester) async {
      await pumpSummaryStep(tester);

      final equipementRow = find.ancestor(
        of: find.text('Équipement'),
        matching: find.byType(InkWell),
      );
      await tester.tap(equipementRow.first);
      await tester.pumpAndSettle();

      expect(find.text('Étape Équipement'), findsOneWidget);
    },
  );

  testWidgets(
    '"Créer le personnage" appelle createCharacter avec le nom saisi, '
    'affiche le chargement, invalide la liste et navigue vers "/"',
    (WidgetTester tester) async {
      final completer = Completer<String>();
      fakeRepository.createCharacterCompleter = completer;

      await pumpSummaryStep(tester);
      await tester.enterText(find.byType(TextFormField), 'Halltesse Ambrelune');
      await tester.pump();
      await tester.tap(find.text('CRÉER LE PERSONNAGE'));
      await tester.pump();

      expect(fakeRepository.createCharacterCallCount, 1);
      expect(fakeRepository.capturedCharacterName, 'Halltesse Ambrelune');
      var button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(button.isLoading, isTrue);

      completer.complete('new-character-id');
      await tester.pumpAndSettle();

      expect(find.text('Liste des personnages'), findsOneWidget);
    },
  );

  testWidgets(
    '"Créer le personnage" navigue vers la route de retour posée par un '
    'sous-flux (ex. étape 3/4 "Rejoindre une histoire") plutôt que "/", et '
    'la consomme (remise à null)',
    (WidgetTester tester) async {
      container
          .read(characterCreationReturnRouteControllerProvider.notifier)
          .set('/join/step-3?code=AB3F7K');

      await pumpSummaryStep(tester);
      await tester.enterText(find.byType(TextFormField), 'Halltesse Ambrelune');
      await tester.pump();
      await tester.tap(find.text('CRÉER LE PERSONNAGE'));
      await tester.pumpAndSettle();

      expect(find.text('Étape 3 Rejoindre code=AB3F7K'), findsOneWidget);
      expect(find.text('Liste des personnages'), findsNothing);
      expect(
        container.read(characterCreationReturnRouteControllerProvider),
        isNull,
      );
    },
  );

  testWidgets('un échec de createCharacter affiche le bandeau d\'alerte et '
      'réactive le bouton, sans naviguer', (WidgetTester tester) async {
    fakeRepository.createCharacterErrorToThrow = const CharacterCreationFailure(
      'Impossible de créer le personnage. Réessayez.',
    );

    await pumpSummaryStep(tester);
    await tester.enterText(find.byType(TextFormField), 'Halltesse Ambrelune');
    await tester.pump();
    await tester.tap(find.text('CRÉER LE PERSONNAGE'));
    await tester.pumpAndSettle();

    expect(
      find.text('Impossible de créer le personnage. Réessayez.'),
      findsOneWidget,
    );
    final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
    expect(button.isLoading, isFalse);
    expect(button.onPressed, isNotNull);
    expect(find.text('Étape Histoire'), findsNothing);
  });
}
