// Tests de widget de l'étape 6/9 de l'assistant de création ("Sorts").
//
// Même principe que `skills_and_tools_step_screen_test.dart` : dépôt
// factice injecté via `overrideWithValue`, aucun appel réseau réel. Cette
// étape n'est atteinte que pour une classe lanceuse de sorts (voir
// `skills_and_tools_step_screen_test.dart` pour le test du saut de cette
// étape côté étape 5/9) — le brouillon est donc toujours préparé ici avec
// une classe lanceuse, sauf le test dédié "classe non lanceuse atteinte
// directement" qui vérifie que l'écran reste robuste malgré tout (aucun
// onglet visible plutôt qu'un crash).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/widgets/checkable_option_tile.dart';
import 'package:personnages/features/character_creation/data/character_creation_repository.dart';
import 'package:personnages/features/character_creation/domain/background_catalog.dart';
import 'package:personnages/features/character_creation/domain/background_option.dart';
import 'package:personnages/features/character_creation/domain/character_creation_draft.dart';
import 'package:personnages/features/character_creation/domain/character_creation_failure.dart';
import 'package:personnages/features/character_creation/domain/class_catalog.dart';
import 'package:personnages/features/character_creation/domain/class_option.dart';
import 'package:personnages/features/character_creation/domain/class_skill_choices.dart';
import 'package:personnages/features/character_creation/domain/item_catalog.dart';
import 'package:personnages/features/character_creation/domain/language_catalog.dart';
import 'package:personnages/features/character_creation/domain/race_catalog.dart';
import 'package:personnages/features/character_creation/domain/skill_catalog.dart';
import 'package:personnages/features/character_creation/domain/spell_catalog.dart';
import 'package:personnages/features/character_creation/domain/spell_option.dart';
import 'package:personnages/features/character_creation/domain/tool_catalog.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_draft_provider.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_providers.dart';
import 'package:personnages/features/character_creation/presentation/spells_step_screen.dart';

class _FakeCharacterCreationRepository implements CharacterCreationRepository {
  ClassCatalog? classCatalogToReturn;
  Object? classCatalogErrorToThrow;
  Completer<ClassCatalog>? classCatalogCompleter;
  SpellCatalog? spellCatalogToReturn;
  Object? spellCatalogErrorToThrow;

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
      const BackgroundCatalog(backgrounds: []);

  @override
  Future<ToolCatalog> fetchToolCatalog() async => const ToolCatalog(tools: []);

  @override
  Future<LanguageCatalog> fetchLanguageCatalog() async =>
      const LanguageCatalog(languages: []);

  @override
  Future<SpellCatalog> fetchSpellCatalog({required int classId}) async {
    if (spellCatalogErrorToThrow != null) {
      throw spellCatalogErrorToThrow!;
    }
    return spellCatalogToReturn ?? const SpellCatalog(spells: []);
  }

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

// Barde : cantrips (quota 2) ET sorts de niveau 1 (quota 4) -> les deux
// onglets sont visibles, le sélecteur de pilules est affiché.
const _barde = ClassOption(
  id: 2,
  name: 'Barde',
  description: '',
  hitDie: 8,
  skillChoices: ClassSkillChoices(count: 0, choices: []),
);

// Paladin : aucun cantrip (quota 0), seulement des sorts de niveau 1 (quota
// 2) -> un seul onglet visible, pas de sélecteur (voir `SpellsStepScreen`).
const _paladin = ClassOption(
  id: 7,
  name: 'Paladin',
  description: '',
  hitDie: 10,
  skillChoices: ClassSkillChoices(count: 0, choices: []),
);

// Guerrier : non lanceur de sorts (`SpellcastingRules.isSpellcastingClass`
// -> false) -> aucun quota, aucun onglet visible. Cette étape ne devrait
// normalement jamais être atteinte pour cette classe (voir
// `skills_and_tools_step_screen_test.dart`), mais l'écran doit rester
// robuste si elle l'est malgré tout (navigation directe, lien profond...).
const _guerrier = ClassOption(
  id: 1,
  name: 'Guerrier',
  description: '',
  hitDie: 10,
  skillChoices: ClassSkillChoices(count: 0, choices: []),
);

const _traitDeFeu = SpellOption(
  id: 1,
  name: 'Trait de feu',
  level: 0,
  school: 'Évocation',
  castingTime: '1 action',
);
const _lumieresDansantes = SpellOption(
  id: 2,
  name: 'Lumières dansantes',
  level: 0,
  school: 'Invocation',
  castingTime: '1 action',
);
const _reparation = SpellOption(
  id: 3,
  name: 'Réparation',
  level: 0,
  school: 'Transmutation',
  castingTime: '1 action',
);
const _benediction = SpellOption(
  id: 4,
  name: 'Bénédiction',
  level: 1,
  school: 'Enchantement',
  castingTime: '1 action',
);
const _soinDesBlessures = SpellOption(
  id: 5,
  name: 'Soin des blessures',
  level: 1,
  school: 'Évocation',
  castingTime: '1 action',
);

const _bardeSpellCatalog = SpellCatalog(
  spells: [
    _traitDeFeu,
    _lumieresDansantes,
    _reparation,
    _benediction,
    _soinDesBlessures,
  ],
);

const _paladinSpellCatalog = SpellCatalog(
  spells: [_benediction, _soinDesBlessures],
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

  // `initialLocation` reste l'étape "Compétences et outils" (stub) :
  // `SpellsStepScreen` est atteinte via un `push`, comme dans la vraie
  // navigation (`skills_and_tools_step_screen.dart` pousse
  // `/characters/new/step-6`).
  GoRouter buildTestRouter() {
    router = GoRouter(
      initialLocation: '/characters/new/step-5',
      routes: [
        GoRoute(
          path: '/characters/new/step-5',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Étape Compétences et outils')),
          ),
        ),
        GoRoute(
          path: '/characters/new/step-6',
          builder: (context, state) => const SpellsStepScreen(),
        ),
        GoRoute(
          path: '/characters/new/step-7',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Étape Équipement'))),
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

  void selectClass(int classId) {
    container
        .read(characterCreationDraftControllerProvider.notifier)
        .setClass(classId: classId);
  }

  Future<void> pumpSpellsStep(WidgetTester tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();
    router.push('/characters/new/step-6');
    await tester.pumpAndSettle();
  }

  testWidgets('affiche un indicateur de chargement pendant la récupération', (
    WidgetTester tester,
  ) async {
    fakeRepository.classCatalogCompleter = Completer<ClassCatalog>();
    selectClass(2);

    await tester.pumpWidget(buildTestWidget());
    router.push('/characters/new/step-6');
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets(
    'affiche un état d\'erreur avec un bouton "Réessayer" si le catalogue '
    'de classes échoue à charger',
    (WidgetTester tester) async {
      fakeRepository.classCatalogErrorToThrow = const CharacterCreationFailure(
        'Impossible de charger les classes disponibles. Réessayez.',
      );
      selectClass(2);

      await pumpSpellsStep(tester);

      expect(
        find.text('Impossible de charger les classes disponibles. Réessayez.'),
        findsOneWidget,
      );

      fakeRepository.classCatalogErrorToThrow = null;
      fakeRepository.classCatalogToReturn = const ClassCatalog(
        classes: [_barde],
      );
      fakeRepository.spellCatalogToReturn = _bardeSpellCatalog;

      await tester.tap(find.text('RÉESSAYER'));
      await tester.pumpAndSettle();

      expect(find.text('SORTS MINEURS CONNUS'), findsOneWidget);
    },
  );

  group('classe avec cantrips ET sorts de niveau 1 (Barde) — les deux '
      'onglets sont visibles', () {
    setUp(() {
      fakeRepository.classCatalogToReturn = const ClassCatalog(
        classes: [_barde],
      );
      fakeRepository.spellCatalogToReturn = _bardeSpellCatalog;
      selectClass(2);
    });

    testWidgets(
      'onglet "Mineurs" actif par défaut : titre, badge de quota et sorts '
      'mineurs triés alphabétiquement, sorts de niveau 1 absents',
      (WidgetTester tester) async {
        await pumpSpellsStep(tester);

        expect(find.text('Mineurs'), findsOneWidget);
        expect(find.text('Niveau 1'), findsOneWidget);

        expect(find.text('SORTS MINEURS CONNUS'), findsOneWidget);
        expect(find.text('0 / 2'), findsOneWidget);
        expect(find.text('Trait de feu'), findsOneWidget);
        expect(find.text('Lumières dansantes'), findsOneWidget);
        expect(find.text('Réparation'), findsOneWidget);
        expect(find.text('Évocation · 1 action'), findsOneWidget);

        // Sorts de niveau 1 pas affichés tant qu'on est sur l'onglet
        // "Mineurs".
        expect(find.text('Bénédiction'), findsNothing);
        expect(find.text('Soin des blessures'), findsNothing);
      },
    );

    testWidgets('cocher un sort mineur met à jour le badge de quota', (
      WidgetTester tester,
    ) async {
      await pumpSpellsStep(tester);

      await tester.tap(find.text('Trait de feu'));
      await tester.pumpAndSettle();

      expect(find.text('1 / 2'), findsOneWidget);
    });

    testWidgets(
      'quota de sorts mineurs atteint : les candidats restants deviennent '
      'estompés/non cliquables, un sort coché reste décochable',
      (WidgetTester tester) async {
        await pumpSpellsStep(tester);

        await tester.tap(find.text('Trait de feu'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Lumières dansantes'));
        await tester.pumpAndSettle();
        expect(find.text('2 / 2'), findsOneWidget);

        final reparationTile = tester.widget<CheckableOptionTile>(
          find.ancestor(
            of: find.text('Réparation'),
            matching: find.byType(CheckableOptionTile),
          ),
        );
        expect(reparationTile.enabled, isFalse);

        await tester.tap(find.text('Réparation'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text('2 / 2'), findsOneWidget);

        // Un sort déjà coché reste décochable malgré le quota atteint.
        await tester.tap(find.text('Trait de feu'));
        await tester.pumpAndSettle();
        expect(find.text('1 / 2'), findsOneWidget);
      },
    );

    testWidgets(
      'taper "Niveau 1" bascule sur l\'onglet niveau 1, avec son propre '
      'titre/badge/candidats',
      (WidgetTester tester) async {
        await pumpSpellsStep(tester);

        await tester.tap(find.text('Niveau 1'));
        await tester.pumpAndSettle();

        expect(find.text('SORTS DE NIVEAU 1 CONNUS'), findsOneWidget);
        expect(find.text('0 / 4'), findsOneWidget);
        expect(find.text('Bénédiction'), findsOneWidget);
        expect(find.text('Soin des blessures'), findsOneWidget);
        expect(find.text('Trait de feu'), findsNothing);
      },
    );

    testWidgets(
      '"Suivant" exige le quota exact des DEUX onglets, même si un seul est '
      'affiché à la fois',
      (WidgetTester tester) async {
        await pumpSpellsStep(tester);

        // Rien sélectionné -> bloqué.
        await tester.tap(find.text('SUIVANT'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text('Étape Équipement'), findsNothing);

        // Quota de cantrips seul atteint -> toujours bloqué (niveau 1
        // manquant, même si son onglet n'est pas affiché actuellement).
        await tester.tap(find.text('Trait de feu'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Lumières dansantes'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('SUIVANT'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text('Étape Équipement'), findsNothing);

        // Bascule sur "Niveau 1" et complète son quota (4, mais seulement 2
        // candidats disponibles dans cette fixture : le quota exact exigé
        // ici est donc borné aux 2 candidats fournis pour rester
        // atteignable dans ce test).
        await tester.tap(find.text('Niveau 1'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Bénédiction'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Soin des blessures'));
        await tester.pumpAndSettle();

        // Quota de niveau 1 (4) non atteint avec seulement 2 candidats :
        // "Suivant" reste bloqué, ce qui est le comportement attendu tant
        // que le contenu peuplé ne fournit pas assez de candidats — pas un
        // bug de cet écran (voir `SpellcastingRules`, quotas MVP).
        await tester.tap(find.text('SUIVANT'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text('Étape Équipement'), findsNothing);
      },
    );

    testWidgets(
      'revenir sur l\'étape avec un brouillon déjà rempli réhydrate les 2 '
      'sélections (retour en arrière depuis une étape suivante, '
      'docs/cahier-des-charges/05-ux-navigation.md)',
      (WidgetTester tester) async {
        container
            .read(characterCreationDraftControllerProvider.notifier)
            .setSpells(
              classCantripChoices: const ['Trait de feu'],
              classLevelOneSpellChoices: const ['Bénédiction'],
            );

        await pumpSpellsStep(tester);

        expect(find.text('1 / 2'), findsOneWidget);
        final traitDeFeuTile = tester.widget<CheckableOptionTile>(
          find.ancestor(
            of: find.text('Trait de feu'),
            matching: find.byType(CheckableOptionTile),
          ),
        );
        expect(traitDeFeuTile.checked, isTrue);

        await tester.tap(find.text('Niveau 1'));
        await tester.pumpAndSettle();

        expect(find.text('1 / 4'), findsOneWidget);
        final benedictionTile = tester.widget<CheckableOptionTile>(
          find.ancestor(
            of: find.text('Bénédiction'),
            matching: find.byType(CheckableOptionTile),
          ),
        );
        expect(benedictionTile.checked, isTrue);
      },
    );

    testWidgets('"Retour" revient à l\'étape Compétences et outils', (
      WidgetTester tester,
    ) async {
      await pumpSpellsStep(tester);

      await tester.tap(find.text('RETOUR'));
      await tester.pumpAndSettle();

      expect(find.text('Étape Compétences et outils'), findsOneWidget);
    });

    testWidgets(
      'basculer d\'onglet ne réinitialise jamais l\'onglet par défaut : '
      'revenir sur "Mineurs" garde la sélection déjà faite',
      (WidgetTester tester) async {
        await pumpSpellsStep(tester);

        await tester.tap(find.text('Trait de feu'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Niveau 1'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mineurs'));
        await tester.pumpAndSettle();

        expect(find.text('1 / 2'), findsOneWidget);
        final tile = tester.widget<CheckableOptionTile>(
          find.ancestor(
            of: find.text('Trait de feu'),
            matching: find.byType(CheckableOptionTile),
          ),
        );
        expect(tile.checked, isTrue);
      },
    );
  });

  group('classe sans cantrip (Paladin) — un seul onglet visible', () {
    setUp(() {
      fakeRepository.classCatalogToReturn = const ClassCatalog(
        classes: [_paladin],
      );
      fakeRepository.spellCatalogToReturn = _paladinSpellCatalog;
      selectClass(7);
    });

    testWidgets('affiche directement les sorts de niveau 1, sans sélecteur de '
        'pilules ni onglet "Mineurs"', (WidgetTester tester) async {
      await pumpSpellsStep(tester);

      expect(find.text('Mineurs'), findsNothing);
      expect(find.text('Niveau 1'), findsNothing);

      expect(find.text('SORTS DE NIVEAU 1 CONNUS'), findsOneWidget);
      expect(find.text('0 / 2'), findsOneWidget);
      expect(find.text('Bénédiction'), findsOneWidget);
      expect(find.text('Soin des blessures'), findsOneWidget);
    });

    testWidgets('"Suivant" ne dépend que du quota de niveau 1 (seul onglet '
        'visible)', (WidgetTester tester) async {
      await pumpSpellsStep(tester);

      await tester.tap(find.text('Bénédiction'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Soin des blessures'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      expect(find.text('Étape Équipement'), findsOneWidget);
      expect(
        readDraft().classLevelOneSpellChoices,
        containsAll(['Bénédiction', 'Soin des blessures']),
      );
      expect(readDraft().classCantripChoices, isEmpty);
    });
  });

  testWidgets('classe non lanceuse de sorts atteignant malgré tout cette étape '
      '(lien profond, navigation manuelle) : aucun onglet, "Suivant" reste '
      'toujours actif plutôt que de bloquer l\'utilisateur sans recours', (
    WidgetTester tester,
  ) async {
    fakeRepository.classCatalogToReturn = const ClassCatalog(
      classes: [_guerrier],
    );
    fakeRepository.spellCatalogToReturn = const SpellCatalog(spells: []);
    selectClass(1);

    await pumpSpellsStep(tester);

    expect(find.text('Mineurs'), findsNothing);
    expect(find.text('Niveau 1'), findsNothing);
    expect(find.text('SORTS MINEURS CONNUS'), findsNothing);

    await tester.tap(find.text('SUIVANT'));
    await tester.pumpAndSettle();

    expect(find.text('Étape Équipement'), findsOneWidget);
  });

  testWidgets(
    'NON-REGRESSION : le bouton Reessayer relance bien fetchSpellCatalog '
    'quand c est LUI (et non fetchClassCatalog) qui a echoue -- bug corrige '
    'ou spellCatalogProvider (une family) netait jamais invalide par '
    'onRetry dans spells_step_screen.dart. Ici classCatalogProvider reussit '
    'des le premier essai, donc l invalider seul naurait rien change : '
    'sans le fix, l utilisateur restait bloque sur l erreur meme apres '
    'correction du probleme serveur.',
    (WidgetTester tester) async {
      fakeRepository.classCatalogToReturn = const ClassCatalog(
        classes: [_barde],
      );
      fakeRepository.spellCatalogErrorToThrow = const CharacterCreationFailure(
        'Impossible de charger les sorts disponibles. Réessayez.',
      );
      selectClass(2);

      await pumpSpellsStep(tester);

      expect(
        find.text('Impossible de charger les sorts disponibles. Réessayez.'),
        findsOneWidget,
      );

      // Le "serveur" est corrigé : un nouvel essai devrait réussir.
      fakeRepository.spellCatalogErrorToThrow = null;
      fakeRepository.spellCatalogToReturn = _bardeSpellCatalog;

      await tester.tap(find.text('RÉESSAYER'));
      await tester.pumpAndSettle();

      expect(find.text('SORTS MINEURS CONNUS'), findsOneWidget);
    },
  );

  testWidgets(
    'classe introuvable dans le catalogue (id du brouillon absent) -> état '
    'd\'erreur explicite plutôt qu\'un crash',
    (WidgetTester tester) async {
      fakeRepository.classCatalogToReturn = const ClassCatalog(
        classes: [_barde],
      );
      selectClass(999);

      await pumpSpellsStep(tester);

      expect(find.textContaining('Classe introuvable'), findsOneWidget);
    },
  );
}
