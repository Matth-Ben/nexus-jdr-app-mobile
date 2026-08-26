// Tests de widget de l'étape 5/9 de l'assistant de création ("Compétences
// et outils").
//
// Même principe que `class_step_screen_test.dart`/`background_step_screen_test.dart`
// : dépôt factice injecté via `overrideWithValue`, aucun appel réseau réel.
// Contrairement aux étapes précédentes, cette étape ne choisit rien
// elle-même à partir d'une simple liste (`ClassOption`/`BackgroundOption`
// viennent du brouillon déjà rempli aux étapes 2/3), donc chaque test
// prépare le brouillon (`setClass`/`setBackground`) avant de pomper l'écran.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/widgets/checkable_option_tile.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/features/character_creation/data/character_creation_repository.dart';
import 'package:personnages/features/character_creation/domain/background_catalog.dart';
import 'package:personnages/features/character_creation/domain/background_option.dart';
import 'package:personnages/features/character_creation/domain/character_creation_draft.dart';
import 'package:personnages/features/character_creation/domain/character_creation_failure.dart';
import 'package:personnages/features/character_creation/domain/class_catalog.dart';
import 'package:personnages/features/character_creation/domain/class_option.dart';
import 'package:personnages/features/character_creation/domain/class_skill_choices.dart';
import 'package:personnages/features/character_creation/domain/class_tool_choice.dart';
import 'package:personnages/features/character_creation/domain/item_catalog.dart';
import 'package:personnages/features/character_creation/domain/language_catalog.dart';
import 'package:personnages/features/character_creation/domain/language_option.dart';
import 'package:personnages/features/character_creation/domain/race_catalog.dart';
import 'package:personnages/features/character_creation/domain/skill_catalog.dart';
import 'package:personnages/features/character_creation/domain/spell_catalog.dart';
import 'package:personnages/features/character_creation/domain/tool_catalog.dart';
import 'package:personnages/features/character_creation/domain/tool_option.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_draft_provider.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_providers.dart';
import 'package:personnages/features/character_creation/presentation/skills_and_tools_step_screen.dart';

class _FakeCharacterCreationRepository implements CharacterCreationRepository {
  ClassCatalog? classCatalogToReturn;
  BackgroundCatalog? backgroundCatalogToReturn;
  ToolCatalog? toolCatalogToReturn;
  LanguageCatalog? languageCatalogToReturn;
  Object? classCatalogErrorToThrow;
  Completer<ClassCatalog>? classCatalogCompleter;

  @override
  Future<RaceCatalog> fetchRaceCatalog() async =>
      const RaceCatalog(races: [], subraces: []);

  @override
  Future<ClassCatalog> fetchClassCatalog() async {
    if (classCatalogCompleter != null) {
      return classCatalogCompleter!.future;
    }
    if (classCatalogErrorToThrow != null) {
      throw classCatalogErrorToThrow!;
    }
    return classCatalogToReturn ?? const ClassCatalog(classes: []);
  }

  @override
  Future<BackgroundCatalog> fetchBackgroundCatalog() async =>
      backgroundCatalogToReturn ?? const BackgroundCatalog(backgrounds: []);

  @override
  Future<ToolCatalog> fetchToolCatalog() async =>
      toolCatalogToReturn ?? const ToolCatalog(tools: []);

  @override
  Future<LanguageCatalog> fetchLanguageCatalog() async =>
      languageCatalogToReturn ?? const LanguageCatalog(languages: []);

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

// Classe sans aucune section outils (ni toolChoice, ni grantedToolNames) :
// "COMPÉTENCES DE CLASSE" est la seule section active pour elle.
const _guerrier = ClassOption(
  id: 1,
  name: 'Guerrier',
  description: '',
  hitDie: 10,
  skillChoices: ClassSkillChoices(
    count: 2,
    choices: ['Athlétisme', 'Intimidation', 'Perception'],
  ),
);

// Classe avec un vrai choix interactif d'outils (Barde) -> section 2
// interactive, candidats filtrés par catégorie dans le catalogue d'outils.
//
// Quota de compétences (2) volontairement différent du quota d'outils (1) :
// les deux sections affichent un badge "X / N choisies", des quotas
// distincts évitent toute ambiguïté de `find.text` entre les deux badges
// dans les tests ci-dessous.
const _barde = ClassOption(
  id: 2,
  name: 'Barde',
  description: '',
  hitDie: 8,
  skillChoices: ClassSkillChoices(
    count: 2,
    choices: ['Arcanes', 'Histoire', 'Religion'],
  ),
  toolChoice: ClassToolChoice(count: 1, categories: ['instrument']),
);

// Classe avec un octroi automatique d'outils précis (Druide) -> section 2
// affichée mais non interactive.
const _druide = ClassOption(
  id: 3,
  name: 'Druide',
  description: '',
  hitDie: 8,
  skillChoices: ClassSkillChoices(count: 1, choices: ['Nature']),
  grantedToolNames: ["Outils d'herboriste"],
);

const _ermite = BackgroundOption(
  id: 10,
  name: 'Ermite',
  skillProficiencies: [],
  featureName: '',
  featureDescription: '',
);

const _marin = BackgroundOption(
  id: 11,
  name: 'Marin',
  skillProficiencies: [],
  featureName: '',
  featureDescription: '',
  toolOrLanguageGrantedTools: ['Kit de déguisement'],
);

// Quota de langues (1) volontairement différent du quota de compétences du
// `_guerrier` (2) utilisé aux côtés de cet historique dans les tests de la
// section 4 : évite toute ambiguïté de `find.text` entre les deux badges.
const _noble = BackgroundOption(
  id: 12,
  name: 'Noble',
  skillProficiencies: [],
  featureName: '',
  featureDescription: '',
  languageChoiceCount: 1,
);

// Historique combinant à la fois un octroi automatique d'outils (section 3,
// verrouillée) ET un choix de langues (section 4, interactive) — forme
// réelle constatée pour "Ermite"/"Noble"/"Artisan de guilde"/"Gamin des
// rues" dans supabase/migrations/20260825090800_seed_backgrounds.sql
// (`tool_or_language_choices` avec les deux clés `tools`/`languages` à la
// fois), pas seulement l'une ou l'autre comme les fixtures précédentes de ce
// fichier. Quota de langues (3) volontairement distinct des quotas de
// compétences (2) et d'outils (1) du `_barde` utilisé à ses côtés dans le
// test des 4 sections simultanées ci-dessous : évite toute ambiguïté de
// `find.text` entre les 3 badges.
const _ermiteComplet = BackgroundOption(
  id: 13,
  name: 'Ermite',
  skillProficiencies: [],
  featureName: '',
  featureDescription: '',
  toolOrLanguageGrantedTools: ["Outils d'herboriste"],
  languageChoiceCount: 3,
);

const _lutTool = ToolOption(id: 100, name: 'Luth', category: 'instrument');
const _fluteTool = ToolOption(id: 101, name: 'Flûte', category: 'instrument');
const _desTool = ToolOption(id: 102, name: 'Dés à jouer', category: 'jeu');

const _communLanguage = LanguageOption(
  id: 200,
  name: 'Commun',
  type: 'standard',
);
const _nainLanguage = LanguageOption(id: 201, name: 'Nain', type: 'standard');
const _elfiqueLanguage = LanguageOption(
  id: 202,
  name: 'Elfique',
  type: 'standard',
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

  // `initialLocation` reste l'étape "Caractéristiques" (stub) :
  // `SkillsAndToolsStepScreen` est atteinte via un `push`, comme dans la
  // vraie navigation (`ability_score_step_screen.dart` pousse
  // `/characters/new/step-5`).
  //
  // La route stub "étape 6" affiche le même texte ("Étape suivante") que la
  // plupart des tests ci-dessous s'attendent à voir après "Suivant" (peu
  // importe la route exacte pour eux) ; la route stub "étape 7" affiche un
  // texte distinct ("Étape suivante (sorts sautés)") uniquement pour le
  // groupe de tests dédié au saut de l'étape 6/9 pour une classe non
  // lanceuse de sorts, qui a besoin de distinguer les deux routes.
  GoRouter buildTestRouter() {
    router = GoRouter(
      initialLocation: '/characters/new/step-4',
      routes: [
        GoRoute(
          path: '/characters/new/step-4',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Étape Caractéristiques')),
          ),
        ),
        GoRoute(
          path: '/characters/new/step-5',
          builder: (context, state) => const SkillsAndToolsStepScreen(),
        ),
        GoRoute(
          path: '/characters/new/step-6',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Étape suivante'))),
        ),
        GoRoute(
          path: '/characters/new/step-7',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Étape suivante (sorts sautés)')),
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

  CharacterCreationDraft readDraft() =>
      container.read(characterCreationDraftControllerProvider);

  void selectClassAndBackground({
    required int classId,
    required int backgroundId,
  }) {
    final notifier = container.read(
      characterCreationDraftControllerProvider.notifier,
    );
    notifier.setClass(classId: classId);
    notifier.setBackground(backgroundId: backgroundId);
  }

  Future<void> pumpSkillsAndToolsStep(WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();
    router.push('/characters/new/step-5');
    await tester.pumpAndSettle();
  }

  testWidgets('affiche un indicateur de chargement pendant la récupération', (
    WidgetTester tester,
  ) async {
    fakeRepository.classCatalogCompleter = Completer<ClassCatalog>();
    selectClassAndBackground(classId: 1, backgroundId: 10);

    await tester.pumpWidget(buildTestWidget());
    router.push('/characters/new/step-5');
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
      selectClassAndBackground(classId: 1, backgroundId: 10);

      await pumpSkillsAndToolsStep(tester);

      expect(
        find.text('Impossible de charger les classes disponibles. Réessayez.'),
        findsOneWidget,
      );

      fakeRepository.classCatalogErrorToThrow = null;
      fakeRepository.classCatalogToReturn = const ClassCatalog(
        classes: [_guerrier],
      );
      fakeRepository.backgroundCatalogToReturn = const BackgroundCatalog(
        backgrounds: [_ermite],
      );

      await tester.tap(find.text('RÉESSAYER'));
      await tester.pumpAndSettle();

      expect(find.text('COMPÉTENCES DE CLASSE'), findsOneWidget);
    },
  );

  group('section 1 "COMPÉTENCES DE CLASSE" (toujours affichée)', () {
    setUp(() {
      fakeRepository.classCatalogToReturn = const ClassCatalog(
        classes: [_guerrier],
      );
      fakeRepository.backgroundCatalogToReturn = const BackgroundCatalog(
        backgrounds: [_ermite],
      );
      selectClassAndBackground(classId: 1, backgroundId: 10);
    });

    testWidgets('affiche les candidats de compétences avec le badge de quota', (
      WidgetTester tester,
    ) async {
      await pumpSkillsAndToolsStep(tester);

      expect(find.text('COMPÉTENCES DE CLASSE'), findsOneWidget);
      expect(find.text('0 / 2 choisies'), findsOneWidget);
      expect(find.text('Athlétisme'), findsOneWidget);
      expect(find.text('For'), findsOneWidget);
      expect(find.text('Intimidation'), findsOneWidget);
      expect(find.text('Perception'), findsOneWidget);

      // Sections optionnelles absentes pour cette classe/historique.
      expect(find.text('OUTILS (CLASSE)'), findsNothing);
      expect(find.text('OUTILS (HISTORIQUE)'), findsNothing);
      expect(find.text('LANGUES (HISTORIQUE)'), findsNothing);
    });

    testWidgets('cocher une compétence met à jour le badge de quota', (
      WidgetTester tester,
    ) async {
      await pumpSkillsAndToolsStep(tester);

      await tester.tap(find.text('Athlétisme'));
      await tester.pumpAndSettle();

      expect(find.text('1 / 2 choisies'), findsOneWidget);
    });

    testWidgets(
      'quota atteint : les options restantes deviennent estompées/non '
      'cliquables, l\'option cochée reste décochable',
      (WidgetTester tester) async {
        await pumpSkillsAndToolsStep(tester);

        await tester.tap(find.text('Athlétisme'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Intimidation'));
        await tester.pumpAndSettle();

        expect(find.text('2 / 2 choisies'), findsOneWidget);

        // Perception (non cochée) doit être verrouillée.
        await tester.tap(find.text('Perception'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text('2 / 2 choisies'), findsOneWidget);

        // Athlétisme (cochée) reste décochable.
        await tester.tap(find.text('Athlétisme'));
        await tester.pumpAndSettle();
        expect(find.text('1 / 2 choisies'), findsOneWidget);
      },
    );

    testWidgets(
      '"Suivant" ne s\'active qu\'une fois le quota de compétences atteint',
      (WidgetTester tester) async {
        await pumpSkillsAndToolsStep(tester);

        await tester.tap(find.text('SUIVANT'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text('Étape suivante'), findsNothing);

        await tester.tap(find.text('Athlétisme'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('SUIVANT'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text('Étape suivante'), findsNothing);

        await tester.tap(find.text('Intimidation'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('SUIVANT'));
        await tester.pumpAndSettle();

        // Guerrier n'est pas lanceur de sorts : l'étape 6/9 est sautée (voir
        // le groupe de tests dédié en fin de fichier), d'où le texte distinct
        // de la route stub "étape 7".
        expect(find.text('Étape suivante (sorts sautés)'), findsOneWidget);
        expect(
          readDraft().classSkillChoices,
          containsAll(['Athlétisme', 'Intimidation']),
        );
        expect(readDraft().classSkillChoices.length, 2);
      },
    );
  });

  group('section 2 "OUTILS (CLASSE)" — choix interactif (Barde)', () {
    setUp(() {
      fakeRepository.classCatalogToReturn = const ClassCatalog(
        classes: [_barde],
      );
      fakeRepository.backgroundCatalogToReturn = const BackgroundCatalog(
        backgrounds: [_ermite],
      );
      fakeRepository.toolCatalogToReturn = const ToolCatalog(
        tools: [_lutTool, _fluteTool, _desTool],
      );
      selectClassAndBackground(classId: 2, backgroundId: 10);
    });

    testWidgets(
      'affichée avec seulement les outils de la catégorie du choix (jeu '
      'exclu, seul "instrument" est demandé)',
      (WidgetTester tester) async {
        await pumpSkillsAndToolsStep(tester);

        expect(find.text('OUTILS (CLASSE)'), findsOneWidget);
        expect(find.text('0 / 1 choisies'), findsOneWidget);
        expect(find.text('Luth'), findsOneWidget);
        expect(find.text('Flûte'), findsOneWidget);
        expect(find.text('Dés à jouer'), findsNothing);
      },
    );

    testWidgets('cocher un outil active la section, quota atteint verrouille '
        'l\'autre candidat', (WidgetTester tester) async {
      await pumpSkillsAndToolsStep(tester);

      await tester.tap(find.text('Luth'));
      await tester.pumpAndSettle();

      expect(find.text('1 / 1 choisies'), findsOneWidget);

      await tester.tap(find.text('Flûte'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('1 / 1 choisies'), findsOneWidget);
    });

    testWidgets(
      '"Suivant" exige à la fois le quota de compétences ET d\'outils',
      (WidgetTester tester) async {
        await pumpSkillsAndToolsStep(tester);

        // Compétences seules (quota 2, une manquante) -> pas assez.
        await tester.tap(find.text('Arcanes'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('SUIVANT'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text('Étape suivante'), findsNothing);

        // Quota de compétences atteint mais outil manquant -> toujours pas
        // assez.
        await tester.tap(find.text('Histoire'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('SUIVANT'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text('Étape suivante'), findsNothing);

        await tester.tap(find.text('Luth'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('SUIVANT'));
        await tester.pumpAndSettle();

        expect(find.text('Étape suivante'), findsOneWidget);
        expect(
          readDraft().classSkillChoices,
          containsAll(['Arcanes', 'Histoire']),
        );
        expect(readDraft().classSkillChoices.length, 2);
        expect(readDraft().classToolChoices, ['Luth']);
      },
    );
  });

  group('section 2 "OUTILS (CLASSE)" — octroi automatique (Druide)', () {
    setUp(() {
      fakeRepository.classCatalogToReturn = const ClassCatalog(
        classes: [_druide],
      );
      fakeRepository.backgroundCatalogToReturn = const BackgroundCatalog(
        backgrounds: [_ermite],
      );
      selectClassAndBackground(classId: 3, backgroundId: 10);
    });

    testWidgets(
      'affichée sans badge de quota, la ligne est cochée et non cliquable',
      (WidgetTester tester) async {
        await pumpSkillsAndToolsStep(tester);

        expect(find.text('OUTILS (CLASSE)'), findsOneWidget);
        expect(find.text("Outils d'herboriste"), findsOneWidget);

        final tile = tester.widget<CheckableOptionTile>(
          find.ancestor(
            of: find.text("Outils d'herboriste"),
            matching: find.byType(CheckableOptionTile),
          ),
        );
        expect(tile.checked, isTrue);
        expect(tile.enabled, isFalse);
      },
    );

    testWidgets(
      'ne bloque jamais "Suivant" : seul le quota de compétences compte',
      (WidgetTester tester) async {
        await pumpSkillsAndToolsStep(tester);

        await tester.tap(find.text('Nature'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('SUIVANT'));
        await tester.pumpAndSettle();

        expect(find.text('Étape suivante'), findsOneWidget);
        expect(readDraft().classToolChoices, isEmpty);
      },
    );
  });

  group('section 3 "OUTILS (HISTORIQUE)" — jamais interactive', () {
    setUp(() {
      fakeRepository.classCatalogToReturn = const ClassCatalog(
        classes: [_guerrier],
      );
      fakeRepository.backgroundCatalogToReturn = const BackgroundCatalog(
        backgrounds: [_marin],
      );
      selectClassAndBackground(classId: 1, backgroundId: 11);
    });

    testWidgets('affichée sans badge de quota, ligne cochée non cliquable', (
      WidgetTester tester,
    ) async {
      await pumpSkillsAndToolsStep(tester);

      expect(find.text('OUTILS (HISTORIQUE)'), findsOneWidget);
      expect(find.text('Kit de déguisement'), findsOneWidget);

      final tile = tester.widget<CheckableOptionTile>(
        find.ancestor(
          of: find.text('Kit de déguisement'),
          matching: find.byType(CheckableOptionTile),
        ),
      );
      expect(tile.checked, isTrue);
      expect(tile.enabled, isFalse);
      expect(tile.onTap, isNull);
    });

    testWidgets('taper la ligne ne modifie rien et ne bloque jamais '
        '"Suivant"', (WidgetTester tester) async {
      await pumpSkillsAndToolsStep(tester);

      await tester.tap(find.text('Kit de déguisement'), warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Athlétisme'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Intimidation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      // Guerrier n'est pas lanceur de sorts : l'étape 6/9 est sautée, même
      // remarque que le test "Suivant" ne s'active qu'une fois le quota de
      // compétences atteint" ci-dessus.
      expect(find.text('Étape suivante (sorts sautés)'), findsOneWidget);
    });
  });

  group('section 4 "LANGUES (HISTORIQUE)"', () {
    setUp(() {
      fakeRepository.classCatalogToReturn = const ClassCatalog(
        classes: [_guerrier],
      );
      fakeRepository.backgroundCatalogToReturn = const BackgroundCatalog(
        backgrounds: [_noble],
      );
      fakeRepository.languageCatalogToReturn = const LanguageCatalog(
        languages: [_communLanguage, _nainLanguage, _elfiqueLanguage],
      );
      selectClassAndBackground(classId: 1, backgroundId: 12);
    });

    testWidgets('affichée avec le badge de quota et tous les candidats', (
      WidgetTester tester,
    ) async {
      await pumpSkillsAndToolsStep(tester);

      expect(find.text('LANGUES (HISTORIQUE)'), findsOneWidget);
      expect(find.text('0 / 1 choisies'), findsOneWidget);
      expect(find.text('Commun'), findsOneWidget);
      expect(find.text('Nain'), findsOneWidget);
      expect(find.text('Elfique'), findsOneWidget);
    });

    testWidgets(
      '"Suivant" exige compétences ET langues, verrouille au quota atteint',
      (WidgetTester tester) async {
        await pumpSkillsAndToolsStep(tester);

        await tester.tap(find.text('Athlétisme'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('SUIVANT'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text('Étape suivante'), findsNothing);

        await tester.tap(find.text('Intimidation'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('SUIVANT'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text('Étape suivante'), findsNothing);

        await tester.tap(find.text('Commun'));
        await tester.pumpAndSettle();
        expect(find.text('1 / 1 choisies'), findsOneWidget);

        // Quota atteint : Nain doit être verrouillée.
        await tester.tap(find.text('Nain'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text('1 / 1 choisies'), findsOneWidget);

        await tester.tap(find.text('SUIVANT'));
        await tester.pumpAndSettle();

        // Guerrier n'est pas lanceur de sorts : l'étape 6/9 est sautée, même
        // remarque que les tests "Guerrier" ci-dessus.
        expect(find.text('Étape suivante (sorts sautés)'), findsOneWidget);
        expect(readDraft().backgroundLanguageChoices, ['Commun']);
      },
    );
  });

  testWidgets(
    'revenir sur l\'étape avec un brouillon déjà rempli réhydrate les 3 '
    'sélections (retour en arrière depuis une étape suivante, '
    'docs/cahier-des-charges/05-ux-navigation.md)',
    (WidgetTester tester) async {
      // Historique dédié à ce test, avec un quota de langues (3) distinct des
      // quotas de compétences (2) et d'outils (1) du Barde : les 3 sections
      // sont actives simultanément ici, des quotas distincts évitent toute
      // ambiguïté de `find.text` entre leurs 3 badges.
      const nobleTroisLangues = BackgroundOption(
        id: 12,
        name: 'Noble',
        skillProficiencies: [],
        featureName: '',
        featureDescription: '',
        languageChoiceCount: 3,
      );

      fakeRepository.classCatalogToReturn = const ClassCatalog(
        classes: [_barde],
      );
      fakeRepository.backgroundCatalogToReturn = const BackgroundCatalog(
        backgrounds: [nobleTroisLangues],
      );
      fakeRepository.toolCatalogToReturn = const ToolCatalog(
        tools: [_lutTool, _fluteTool],
      );
      fakeRepository.languageCatalogToReturn = const LanguageCatalog(
        languages: [_communLanguage, _nainLanguage, _elfiqueLanguage],
      );
      selectClassAndBackground(classId: 2, backgroundId: 12);
      container
          .read(characterCreationDraftControllerProvider.notifier)
          .setSkillsAndTools(
            classSkillChoices: const ['Arcanes', 'Histoire'],
            classToolChoices: const ['Luth'],
            backgroundLanguageChoices: const ['Commun', 'Nain', 'Elfique'],
          );

      await pumpSkillsAndToolsStep(tester);

      expect(find.text('2 / 2 choisies'), findsOneWidget);
      expect(find.text('1 / 1 choisies'), findsOneWidget);
      expect(find.text('3 / 3 choisies'), findsOneWidget);

      final arcanesTile = tester.widget<CheckableOptionTile>(
        find.ancestor(
          of: find.text('Arcanes'),
          matching: find.byType(CheckableOptionTile),
        ),
      );
      expect(arcanesTile.checked, isTrue);

      final luthTile = tester.widget<CheckableOptionTile>(
        find.ancestor(
          of: find.text('Luth'),
          matching: find.byType(CheckableOptionTile),
        ),
      );
      expect(luthTile.checked, isTrue);

      // "Elfique" est en bas d'une longue liste (`ListView`, chargement
      // paresseux des enfants hors viewport) : scroller jusqu'à ce qu'il
      // soit monté avant de le chercher.
      await tester.dragUntilVisible(
        find.text('Elfique'),
        find.byType(Scrollable),
        const Offset(0, -100),
      );
      final elfiqueTile = tester.widget<CheckableOptionTile>(
        find.ancestor(
          of: find.text('Elfique'),
          matching: find.byType(CheckableOptionTile),
        ),
      );
      expect(elfiqueTile.checked, isTrue);

      // "Suivant" doit déjà être actif : pas besoin de re-sélectionner.
      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      expect(find.text('Étape suivante'), findsOneWidget);
    },
  );

  testWidgets('le bouton "Retour" revient à l\'étape Caractéristiques', (
    WidgetTester tester,
  ) async {
    fakeRepository.classCatalogToReturn = const ClassCatalog(
      classes: [_guerrier],
    );
    fakeRepository.backgroundCatalogToReturn = const BackgroundCatalog(
      backgrounds: [_ermite],
    );
    selectClassAndBackground(classId: 1, backgroundId: 10);

    await pumpSkillsAndToolsStep(tester);

    await tester.tap(find.text('RETOUR'));
    await tester.pumpAndSettle();

    expect(find.text('Étape Caractéristiques'), findsOneWidget);
  });

  testWidgets(
    'le bouton "Retour" utilise la variante "parchemin" du bouton secondaire '
    '(maquette 06_étape_5_compétences_et_outils.png)',
    (WidgetTester tester) async {
      fakeRepository.classCatalogToReturn = const ClassCatalog(
        classes: [_guerrier],
      );
      fakeRepository.backgroundCatalogToReturn = const BackgroundCatalog(
        backgrounds: [_ermite],
      );
      selectClassAndBackground(classId: 1, backgroundId: 10);

      await pumpSkillsAndToolsStep(tester);

      final backButton = tester
          .widgetList<SecondaryButton>(find.byType(SecondaryButton))
          .firstWhere((button) => button.label == 'Retour');

      expect(backButton.surface, SecondaryButtonSurface.parchment);
    },
  );

  testWidgets(
    'classe introuvable dans le catalogue (id du brouillon absent) -> état '
    'd\'erreur explicite plutôt qu\'un crash',
    (WidgetTester tester) async {
      fakeRepository.classCatalogToReturn = const ClassCatalog(
        classes: [_guerrier],
      );
      fakeRepository.backgroundCatalogToReturn = const BackgroundCatalog(
        backgrounds: [_ermite],
      );
      selectClassAndBackground(classId: 999, backgroundId: 10);

      await pumpSkillsAndToolsStep(tester);

      expect(find.textContaining('Classe introuvable'), findsOneWidget);
    },
  );

  testWidgets(
    'historique introuvable dans le catalogue (id du brouillon absent) -> '
    'état d\'erreur explicite plutôt qu\'un crash (pendant symétrique du '
    'test "classe introuvable" ci-dessus)',
    (WidgetTester tester) async {
      fakeRepository.classCatalogToReturn = const ClassCatalog(
        classes: [_guerrier],
      );
      fakeRepository.backgroundCatalogToReturn = const BackgroundCatalog(
        backgrounds: [_ermite],
      );
      selectClassAndBackground(classId: 1, backgroundId: 999);

      await pumpSkillsAndToolsStep(tester);

      expect(find.textContaining('Historique introuvable'), findsOneWidget);
    },
  );

  group('les 4 sections actives simultanément (classe avec choix interactif '
      'd\'outils + historique avec outils fixes ET langues, ex. Barde + '
      'Ermite)', () {
    setUp(() {
      fakeRepository.classCatalogToReturn = const ClassCatalog(
        classes: [_barde],
      );
      fakeRepository.backgroundCatalogToReturn = const BackgroundCatalog(
        backgrounds: [_ermiteComplet],
      );
      fakeRepository.toolCatalogToReturn = const ToolCatalog(
        tools: [_lutTool, _fluteTool, _desTool],
      );
      fakeRepository.languageCatalogToReturn = const LanguageCatalog(
        languages: [_communLanguage, _nainLanguage, _elfiqueLanguage],
      );
      selectClassAndBackground(classId: 2, backgroundId: 13);
    });

    testWidgets(
      'les 4 titres de section sont affichés en même temps, la section '
      'outils d\'historique reste verrouillée',
      (WidgetTester tester) async {
        await pumpSkillsAndToolsStep(tester);

        expect(find.text('COMPÉTENCES DE CLASSE'), findsOneWidget);
        expect(find.text('OUTILS (CLASSE)'), findsOneWidget);

        // "OUTILS (HISTORIQUE)"/"LANGUES (HISTORIQUE)" sont plus bas dans
        // le `ListView` (chargement paresseux des enfants hors viewport,
        // même remarque que le test de réhydratation ci-dessus) : scroller
        // jusqu'à eux avant de les chercher.
        await tester.dragUntilVisible(
          find.text('OUTILS (HISTORIQUE)'),
          find.byType(Scrollable),
          const Offset(0, -100),
        );
        expect(find.text('OUTILS (HISTORIQUE)'), findsOneWidget);

        final grantedToolTile = tester.widget<CheckableOptionTile>(
          find.ancestor(
            of: find.text("Outils d'herboriste"),
            matching: find.byType(CheckableOptionTile),
          ),
        );
        expect(grantedToolTile.checked, isTrue);
        expect(grantedToolTile.enabled, isFalse);

        await tester.dragUntilVisible(
          find.text('LANGUES (HISTORIQUE)'),
          find.byType(Scrollable),
          const Offset(0, -100),
        );
        expect(find.text('LANGUES (HISTORIQUE)'), findsOneWidget);
      },
    );

    testWidgets(
      '"Suivant" exige les 3 quotas interactifs (compétences, outils, '
      'langues) à la fois ; l\'outil d\'historique verrouillé ne compte '
      'jamais',
      (WidgetTester tester) async {
        await pumpSkillsAndToolsStep(tester);

        // Rien de sélectionné -> bloqué.
        await tester.tap(find.text('SUIVANT'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text('Étape suivante'), findsNothing);

        // Quota de compétences (2) seul atteint -> toujours bloqué.
        await tester.tap(find.text('Arcanes'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Histoire'));
        await tester.pumpAndSettle();
        expect(find.text('2 / 2 choisies'), findsOneWidget);
        await tester.tap(find.text('SUIVANT'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text('Étape suivante'), findsNothing);

        // Quota d'outils (1) atteint en plus -> toujours bloqué (langues
        // manquantes).
        await tester.tap(find.text('Luth'));
        await tester.pumpAndSettle();
        expect(find.text('1 / 1 choisies'), findsOneWidget);
        await tester.tap(find.text('SUIVANT'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text('Étape suivante'), findsNothing);

        // Quota de langues (3) atteint en dernier -> les 3 quotas
        // interactifs sont maintenant exacts, "Suivant" s'active. Les 3
        // candidats de langue sont regroupés en bas du `ListView`
        // (chargement paresseux des enfants hors viewport, même remarque que
        // le test de réhydratation ci-dessus) : un seul scroll jusqu'au
        // dernier ("Elfique") les rend tous visibles/tapables d'un coup,
        // contrairement à 3 `dragUntilVisible` séparés qui laissaient le
        // geste de défilement dans un état intermédiaire faisant échouer le
        // hit-test du tap suivant (repro constatée en écrivant ce test).
        await tester.dragUntilVisible(
          find.text('Elfique'),
          find.byType(Scrollable),
          const Offset(0, -100),
        );
        await tester.tap(find.text('Commun'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Nain'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Elfique'));
        await tester.pumpAndSettle();
        expect(find.text('3 / 3 choisies'), findsOneWidget);

        await tester.tap(find.text('SUIVANT'));
        await tester.pumpAndSettle();

        expect(find.text('Étape suivante'), findsOneWidget);
        expect(
          readDraft().classSkillChoices,
          containsAll(['Arcanes', 'Histoire']),
        );
        expect(readDraft().classToolChoices, ['Luth']);
        expect(
          readDraft().backgroundLanguageChoices,
          containsAll(['Commun', 'Nain', 'Elfique']),
        );
        expect(readDraft().backgroundLanguageChoices.length, 3);
      },
    );
  });

  group('saut de l\'étape 6/9 "Sorts" pour une classe non lanceuse de sorts '
      '(SpellcastingRules.isSpellcastingClass)', () {
    testWidgets('"Suivant" pousse directement l\'étape 7/9 pour une classe non '
        'lanceuse (Guerrier)', (WidgetTester tester) async {
      fakeRepository.classCatalogToReturn = const ClassCatalog(
        classes: [_guerrier],
      );
      fakeRepository.backgroundCatalogToReturn = const BackgroundCatalog(
        backgrounds: [_ermite],
      );
      selectClassAndBackground(classId: 1, backgroundId: 10);

      await pumpSkillsAndToolsStep(tester);

      await tester.tap(find.text('Athlétisme'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Intimidation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      expect(find.text('Étape suivante (sorts sautés)'), findsOneWidget);
    });

    testWidgets(
      '"Suivant" pousse l\'étape 6/9 "Sorts" pour une classe lanceuse '
      '(Barde)',
      (WidgetTester tester) async {
        fakeRepository.classCatalogToReturn = const ClassCatalog(
          classes: [_barde],
        );
        fakeRepository.backgroundCatalogToReturn = const BackgroundCatalog(
          backgrounds: [_ermite],
        );
        fakeRepository.toolCatalogToReturn = const ToolCatalog(
          tools: [_lutTool],
        );
        selectClassAndBackground(classId: 2, backgroundId: 10);

        await pumpSkillsAndToolsStep(tester);

        await tester.tap(find.text('Arcanes'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Histoire'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Luth'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('SUIVANT'));
        await tester.pumpAndSettle();

        expect(find.text('Étape suivante'), findsOneWidget);
        expect(find.text('Étape suivante (sorts sautés)'), findsNothing);
      },
    );
  });
}
