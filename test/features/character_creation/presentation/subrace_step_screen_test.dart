// Tests de widget de l'étape "Sous-race" de l'assistant de création, second
// écran de l'étape 1/9 "Race" — atteinte uniquement depuis `RaceStepScreen`
// pour une race qui a des sous-races (voir sa doc de classe). Même principe
// que `race_step_screen_test.dart` : dépôt factice injecté via
// `overrideWithValue`, aucun appel réseau réel, vérification du brouillon
// via un `ProviderContainer` plutôt qu'un double de dépôt.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/core/widgets/selectable_option_tile.dart';
import 'package:personnages/features/character_creation/data/character_creation_repository.dart';
import 'package:personnages/features/character_creation/domain/alignment_catalog.dart';
import 'package:personnages/features/character_creation/domain/background_catalog.dart';
import 'package:personnages/features/character_creation/domain/background_option.dart';
import 'package:personnages/features/character_creation/domain/character_creation_draft.dart';
import 'package:personnages/features/character_creation/domain/class_catalog.dart';
import 'package:personnages/features/character_creation/domain/class_option.dart';
import 'package:personnages/features/character_creation/domain/item_catalog.dart';
import 'package:personnages/features/character_creation/domain/language_catalog.dart';
import 'package:personnages/features/character_creation/domain/race_catalog.dart';
import 'package:personnages/features/character_creation/domain/race_option.dart';
import 'package:personnages/features/character_creation/domain/race_trait.dart';
import 'package:personnages/features/character_creation/domain/skill_catalog.dart';
import 'package:personnages/features/character_creation/domain/spell_catalog.dart';
import 'package:personnages/features/character_creation/domain/subclass_catalog.dart';
import 'package:personnages/features/character_creation/domain/subrace_option.dart';
import 'package:personnages/features/character_creation/domain/tool_catalog.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_draft_provider.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_providers.dart';
import 'package:personnages/features/character_creation/presentation/subrace_step_screen.dart';

class _FakeCharacterCreationRepository implements CharacterCreationRepository {
  RaceCatalog? catalogToReturn;

  @override
  Future<RaceCatalog> fetchRaceCatalog() async =>
      catalogToReturn ?? const RaceCatalog(races: [], subraces: []);

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

const _elfe = RaceOption(
  id: 1,
  name: 'Elfe',
  abilityBonuses: {'dex': 2},
  traits: [],
  source: '',
);

const _hautElfe = SubraceOption(
  id: 10,
  raceId: 1,
  name: 'Haut-elfe',
  abilityBonuses: {'int': 1},
  traits: [RaceTrait(name: 'Cantrip elfique', description: '...')],
  traits2024: [RaceTrait(name: 'Cantrip elfique', description: '...')],
);

const _elfeDesBois = SubraceOption(
  id: 11,
  raceId: 1,
  name: 'Elfe des bois',
  abilityBonuses: {'wis': 1},
  traits: [RaceTrait(name: 'Camouflage naturel', description: '...')],
  traits2024: [RaceTrait(name: 'Camouflage naturel', description: '...')],
);

// Fixtures du chantier "différenciation 2014/2024 pour les races", étendu
// aux sous-races le 30/10/2026 — voir `SubraceStepScreen._isSubraceAvailable`.
// `traits2024: null` (valeur par défaut) pour les sous-races sans contenu
// 2024 propre, `traits2024: [...]` pour celles qui en ont un (peu importe le
// contenu réel, seule la nullité compte pour ce filtre).
const _eladrin = SubraceOption(
  id: 12,
  raceId: 1,
  name: 'Eladrin',
  abilityBonuses: {'cha': 1},
  traits: [RaceTrait(name: 'Pas féerique', description: '...')],
);

const _elfeMarin = SubraceOption(
  id: 13,
  raceId: 1,
  name: 'Elfe marin',
  abilityBonuses: {'con': 1},
  traits: [RaceTrait(name: 'Enfant de la mer', description: '...')],
);

const _elfeNoir = SubraceOption(
  id: 14,
  raceId: 1,
  name: 'Elfe noir (Drow)',
  abilityBonuses: {'cha': 1},
  traits: [RaceTrait(name: 'Magie drow', description: '...')],
  traits2024: [RaceTrait(name: 'Magie drow', description: '...')],
);

const _shadarKai = SubraceOption(
  id: 15,
  raceId: 1,
  name: 'Shadar-kai',
  abilityBonuses: {'con': 1},
  traits: [RaceTrait(name: 'Pas de l\'ombre', description: '...')],
);

const _gnome = RaceOption(
  id: 2,
  name: 'Gnome',
  abilityBonuses: {'int': 2},
  traits: [],
  source: '',
);

const _gnomeDesForets = SubraceOption(
  id: 20,
  raceId: 2,
  name: 'Gnome des forêts',
  abilityBonuses: {'dex': 1},
  traits: [RaceTrait(name: 'Illusion naturelle', description: '...')],
  traits2024: [RaceTrait(name: 'Illusion naturelle', description: '...')],
);

const _gnomeDesProfondeurs = SubraceOption(
  id: 21,
  raceId: 2,
  name: 'Gnome des profondeurs (Svirfnebelin)',
  abilityBonuses: {'dex': 1},
  traits: [RaceTrait(name: 'Camouflage souterrain', description: '...')],
);

const _gnomeDesRoches = SubraceOption(
  id: 22,
  raceId: 2,
  name: 'Gnome des roches',
  abilityBonuses: {'con': 1},
  traits: [RaceTrait(name: 'Bricolage', description: '...')],
  traits2024: [RaceTrait(name: 'Bricolage', description: '...')],
);

void main() {
  late _FakeCharacterCreationRepository fakeRepository;
  late ProviderContainer container;
  late GoRouter router;

  setUp(() {
    fakeRepository = _FakeCharacterCreationRepository();
    fakeRepository.catalogToReturn = const RaceCatalog(
      races: [_elfe],
      subraces: [_hautElfe, _elfeDesBois],
    );
    container = ProviderContainer(
      overrides: [
        characterCreationRepositoryProvider.overrideWithValue(fakeRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  // `initialLocation` reste l'étape "Race" (stub) : `SubraceStepScreen` est
  // atteinte via un `push`, comme dans la vraie navigation
  // (`race_step_screen.dart` pousse `/characters/new/subrace`).
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
          path: '/characters/new/subrace',
          builder: (context, state) => const SubraceStepScreen(),
        ),
        GoRoute(
          path: '/characters/new/step-2',
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

  Future<void> pumpSubraceStep(WidgetTester tester) async {
    container
        .read(characterCreationDraftControllerProvider.notifier)
        .setRace(raceId: 1, subraceId: null);
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();
    router.push('/characters/new/subrace');
    await tester.pumpAndSettle();
  }

  testWidgets(
    'charge le nom de la race et la liste de ses sous-races depuis le '
    'brouillon',
    (WidgetTester tester) async {
      await pumpSubraceStep(tester);

      expect(find.textContaining('Elfe'), findsWidgets);
      expect(find.text('Haut-elfe'), findsOneWidget);
      expect(find.text('Elfe des bois'), findsOneWidget);
    },
  );

  testWidgets('"Suivant" est désactivé tant qu\'aucune sous-race n\'est '
      'choisie', (WidgetTester tester) async {
    await pumpSubraceStep(tester);

    await tester.tap(find.text('SUIVANT'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(readDraft(), const CharacterCreationDraft(raceId: 1));
    expect(find.text('Étape suivante'), findsNothing);
  });

  testWidgets('sélectionner une sous-race puis "Suivant" écrit le brouillon et '
      'navigue vers l\'étape 2/9', (WidgetTester tester) async {
    await pumpSubraceStep(tester);

    await tester.tap(find.text('Haut-elfe'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('SUIVANT'));
    await tester.pumpAndSettle();

    expect(readDraft(), const CharacterCreationDraft(raceId: 1, subraceId: 10));
    expect(find.text('Étape suivante'), findsOneWidget);
  });

  testWidgets('le bouton "Retour" revient à l\'étape Race', (
    WidgetTester tester,
  ) async {
    await pumpSubraceStep(tester);

    await tester.tap(find.text('RETOUR'));
    await tester.pumpAndSettle();

    expect(find.text('Étape Race'), findsOneWidget);
  });

  testWidgets(
    'le bouton "Retour" utilise la variante "parchemin" du bouton secondaire',
    (WidgetTester tester) async {
      await pumpSubraceStep(tester);

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
          .setRace(raceId: 1, subraceId: 11);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      router.push('/characters/new/subrace');
      await tester.pumpAndSettle();

      final tiles = tester.widgetList<SelectableOptionTile>(
        find.byType(SelectableOptionTile),
      );
      expect(
        tiles.firstWhere((tile) => tile.title == 'Elfe des bois').selected,
        true,
      );
      expect(
        tiles.firstWhere((tile) => tile.title == 'Haut-elfe').selected,
        false,
      );

      final nextButton = tester.widget<PrimaryButton>(
        find.byType(PrimaryButton),
      );
      expect(nextButton.onPressed, isNotNull);

      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      expect(
        readDraft(),
        const CharacterCreationDraft(raceId: 1, subraceId: 11),
      );
    },
  );

  testWidgets(
    'aucun raceId dans le brouillon (cas défensif, ex. deep-link direct) '
    'redirige vers l\'étape 1 "Race"',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      router.push('/characters/new/subrace');
      await tester.pumpAndSettle();

      expect(find.text('Étape Race'), findsOneWidget);
    },
  );

  group('chantier "différenciation 2014/2024 pour les races", étendu aux '
      'sous-races (30/10/2026)', () {
    // `setEdition` AVANT `setRace` : `setEdition` efface `raceId`/
    // `subraceId` quand l'édition change réellement (voir
    // `CharacterCreationDraftController.setEdition`), l'ordre inverse
    // perdrait donc la race choisie ci-dessous.
    //
    // Surface de test agrandie en hauteur — même rationale que
    // `race_step_screen_test.dart::pumpTallRaceStep` (voir son commentaire) :
    // avec 6 sous-races (Elfe en édition 2014), la hauteur par défaut
    // (~600) laisse certaines tuiles hors du `ListView`, qui ne construit
    // que les éléments visibles, et `find.text(...)` les manquerait.
    Future<void> pumpSubraceStepForEdition(
      WidgetTester tester, {
      required String edition,
      required RaceCatalog catalog,
      required int raceId,
    }) async {
      tester.view.physicalSize = const Size(800, 1300);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      fakeRepository.catalogToReturn = catalog;
      container
          .read(characterCreationDraftControllerProvider.notifier)
          .setEdition(edition);
      container
          .read(characterCreationDraftControllerProvider.notifier)
          .setRace(raceId: raceId, subraceId: null);
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      router.push('/characters/new/subrace');
      await tester.pumpAndSettle();
    }

    testWidgets('édition 2024, Elfe : seules Haut-elfe/Elfe des bois/Elfe noir '
        '(Drow) apparaissent (Eladrin/Elfe marin/Shadar-kai, sans '
        'traits2024, sont masquées — décision du 30/10/2026, masquage '
        'complet comme pour les races)', (WidgetTester tester) async {
      await pumpSubraceStepForEdition(
        tester,
        edition: '2024',
        catalog: const RaceCatalog(
          races: [_elfe],
          subraces: [
            _eladrin,
            _elfeDesBois,
            _elfeMarin,
            _elfeNoir,
            _hautElfe,
            _shadarKai,
          ],
        ),
        raceId: 1,
      );

      expect(find.text('Haut-elfe'), findsOneWidget);
      expect(find.text('Elfe des bois'), findsOneWidget);
      expect(find.text('Elfe noir (Drow)'), findsOneWidget);
      expect(find.text('Eladrin'), findsNothing);
      expect(find.text('Elfe marin'), findsNothing);
      expect(find.text('Shadar-kai'), findsNothing);
    });

    testWidgets(
      'édition 2014, Elfe : les 6 sous-races restent toutes affichées '
      '(non-régression)',
      (WidgetTester tester) async {
        await pumpSubraceStepForEdition(
          tester,
          edition: '2014',
          catalog: const RaceCatalog(
            races: [_elfe],
            subraces: [
              _eladrin,
              _elfeDesBois,
              _elfeMarin,
              _elfeNoir,
              _hautElfe,
              _shadarKai,
            ],
          ),
          raceId: 1,
        );

        for (final name in [
          'Eladrin',
          'Elfe des bois',
          'Elfe marin',
          'Elfe noir (Drow)',
          'Haut-elfe',
          'Shadar-kai',
        ]) {
          expect(find.text(name), findsOneWidget);
        }
      },
    );

    testWidgets(
      'édition 2024, Gnome : seules Gnome des forêts/Gnome des roches '
      'apparaissent (Gnome des profondeurs/Svirfnebelin, sans '
      'traits2024, est masqué)',
      (WidgetTester tester) async {
        await pumpSubraceStepForEdition(
          tester,
          edition: '2024',
          catalog: const RaceCatalog(
            races: [_gnome],
            subraces: [_gnomeDesForets, _gnomeDesProfondeurs, _gnomeDesRoches],
          ),
          raceId: 2,
        );

        expect(find.text('Gnome des forêts'), findsOneWidget);
        expect(find.text('Gnome des roches'), findsOneWidget);
        expect(find.text('Gnome des profondeurs (Svirfnebelin)'), findsNothing);
      },
    );

    testWidgets(
      'édition 2014, Gnome : les 3 sous-races restent toutes affichées '
      '(non-régression)',
      (WidgetTester tester) async {
        await pumpSubraceStepForEdition(
          tester,
          edition: '2014',
          catalog: const RaceCatalog(
            races: [_gnome],
            subraces: [_gnomeDesForets, _gnomeDesProfondeurs, _gnomeDesRoches],
          ),
          raceId: 2,
        );

        expect(find.text('Gnome des forêts'), findsOneWidget);
        expect(
          find.text('Gnome des profondeurs (Svirfnebelin)'),
          findsOneWidget,
        );
        expect(find.text('Gnome des roches'), findsOneWidget);
      },
    );
  });
}
