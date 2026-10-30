// Test d'intégration multi-écrans (widget) verrouillant le bug retour QA du
// 24/10/2026 (chantier "différenciation 2014/2024 pour les races") :
// `EditionStepScreen` -> `RaceStepScreen` -> retour -> `EditionStepScreen`
// -> nouveau choix d'édition -> `RaceStepScreen` (nouvelle instance).
//
// Repro confirmée par QA : un joueur choisit le Demi-elfe en édition 2014,
// revient en arrière jusqu'à `EditionStepScreen`, bascule sur 2024—
// `RaceStepScreen` réhydratait `_selectedRaceId` (Demi-elfe) sans revérifier
// sa disponibilité dans la nouvelle édition, laissant "Suivant" actif sur
// une race RAW-invalide, sans aucun message.
//
// Contrairement à `edition_step_screen_test.dart`/`race_step_screen_test.dart`
// (chacun teste SON écran en isolation, avec l'écran voisin stubé), ce
// fichier monte les deux VRAIS écrans sur un VRAI `GoRouter` (routes réelles
// de `core/router/app_router.dart` pour ce segment), pour que le `push`/
// `pop` entre eux soit authentique — seule façon de verrouiller un bug de
// navigation aller-retour entre deux écrans réels.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/character_creation/data/character_creation_repository.dart';
import 'package:personnages/features/character_creation/data/lineage_choice_repository.dart';
import 'package:personnages/features/character_creation/domain/alignment_catalog.dart';
import 'package:personnages/features/character_creation/domain/background_catalog.dart';
import 'package:personnages/features/character_creation/domain/background_option.dart';
import 'package:personnages/features/character_creation/domain/character_creation_draft.dart';
import 'package:personnages/features/character_creation/domain/class_catalog.dart';
import 'package:personnages/features/character_creation/domain/class_option.dart';
import 'package:personnages/features/character_creation/domain/item_catalog.dart';
import 'package:personnages/features/character_creation/domain/language_catalog.dart';
import 'package:personnages/features/character_creation/domain/lineage_choice_catalog.dart';
import 'package:personnages/features/character_creation/domain/race_catalog.dart';
import 'package:personnages/features/character_creation/domain/race_option.dart';
import 'package:personnages/features/character_creation/domain/skill_catalog.dart';
import 'package:personnages/features/character_creation/domain/spell_catalog.dart';
import 'package:personnages/features/character_creation/domain/subclass_catalog.dart';
import 'package:personnages/features/character_creation/domain/tool_catalog.dart';
import 'package:personnages/features/character_creation/presentation/edition_step_screen.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_draft_provider.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_providers.dart';
import 'package:personnages/features/character_creation/presentation/providers/lineage_choice_providers.dart';
import 'package:personnages/features/character_creation/presentation/race_step_screen.dart';

class _FakeCharacterCreationRepository implements CharacterCreationRepository {
  RaceCatalog catalogToReturn = const RaceCatalog(races: [], subraces: []);

  @override
  Future<RaceCatalog> fetchRaceCatalog() async => catalogToReturn;

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

/// Aucune lignée à choisir pour les races de ce test (Demi-elfe/Elfe n'en
/// ont pas) : toujours vide, même principe que `race_step_screen_test.dart`.
class _FakeLineageChoiceRepository implements LineageChoiceRepository {
  @override
  Future<LineageChoiceCatalog> fetchLineageChoices({
    required String edition,
  }) async => const LineageChoiceCatalog(optionsByRaceId: {});
}

/// Demi-elfe : `traits2024` null (pas d'équivalent 2024 RAW) — voir
/// `RaceStepScreen._isRaceAvailable`.
const _demiElfe = RaceOption(
  id: 7,
  name: 'Demi-elfe',
  abilityBonuses: {
    'cha': 2,
    'choice_others': {'count': 2, 'amount': 1},
  },
  traits: [],
  source: 'Manuel des Joueurs',
);

/// Elfe : disponible dans les deux éditions (`traits2024` non nul), gardée
/// comme race "normale" de contrôle.
const _elfe = RaceOption(
  id: 1,
  name: 'Elfe',
  abilityBonuses: {'dex': 2},
  traits: [],
  source: 'Manuel des Joueurs',
  traits2024: [],
);

void main() {
  late _FakeCharacterCreationRepository fakeRepository;
  late ProviderContainer container;
  late GoRouter router;

  setUp(() {
    fakeRepository = _FakeCharacterCreationRepository()
      ..catalogToReturn = const RaceCatalog(
        races: [_demiElfe, _elfe],
        subraces: [],
      );
    container = ProviderContainer(
      overrides: [
        characterCreationRepositoryProvider.overrideWithValue(fakeRepository),
        lineageChoiceRepositoryProvider.overrideWithValue(
          _FakeLineageChoiceRepository(),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  // Mêmes `path` que `core/router/app_router.dart` pour ce segment (Édition
  // -> Race), plus un stub pour l'étape 2/10 "Classe" (jamais exercée en
  // détail ici, juste une destination valide pour le `push` de
  // `RaceStepScreen._submit`) — voir la doc de classe de ce fichier.
  GoRouter buildTestRouter() {
    router = GoRouter(
      initialLocation: '/characters/new/edition',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Liste des personnages')),
          ),
        ),
        GoRoute(
          path: '/characters/new/edition',
          builder: (context, state) => const EditionStepScreen(),
        ),
        GoRoute(
          path: '/characters/new',
          builder: (context, state) => const RaceStepScreen(),
        ),
        GoRoute(
          path: '/characters/new/step-2',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Étape Classe'))),
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

  testWidgets(
    'Édition 2014 -> Race (Demi-elfe) -> retour -> Édition 2024 -> Race '
    '(nouvelle instance) : le Demi-elfe n\'est plus sélectionné, "Suivant" '
    'est désactivé, la tuile est entièrement absente de la liste (masquage '
    'complet depuis le 30/10/2026, auparavant grisée avec un message '
    'explicite) — le brouillon ne garde jamais une race RAW-invalide pour '
    'sa nouvelle édition (correctif retour QA du 24/10/2026)',
    (WidgetTester tester) async {
      // 1. Étape Édition, 2014 (déjà présélectionnée par défaut) -> Suivant.
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      expect(readDraft().edition, '2014');
      expect(find.text('2. Race'), findsOneWidget);

      // 2. Étape Race : sélectionne le Demi-elfe (valide en 2014) -> Suivant.
      expect(
        find.text('Demi-elfe'),
        findsOneWidget,
        reason: 'en 2014, aucune race n\'est masquée',
      );
      await tester.tap(find.text('Demi-elfe'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      expect(readDraft().raceId, _demiElfe.id);
      expect(find.text('Étape Classe'), findsOneWidget);

      // 3. Retour en arrière (navigation normale, deux `pop()`) jusqu'à
      // l'étape Édition — même chemin que la repro QA. `router.pop()`
      // directement sur le routeur plutôt qu'un tap UI : le stub "Étape
      // Classe" ci-dessus n'a pas de bouton "Retour" (même principe que
      // `appearance_and_backstory_step_screen_test.dart`).
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('2. Race'), findsOneWidget);

      await tester.tap(find.text('RETOUR'));
      await tester.pumpAndSettle();
      expect(find.text('1. Édition'), findsOneWidget);

      // 4. Bascule sur 2024 -> Suivant : le correctif de
      // `CharacterCreationDraftController.setEdition` doit effacer `raceId`
      // (et tout ce qui en dérive) AVANT même que `RaceStepScreen` ne soit
      // réaffichée.
      await tester.tap(find.text('2024 — Manuel des Joueurs revu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SUIVANT'));
      await tester.pumpAndSettle();

      expect(readDraft().edition, '2024');
      expect(
        readDraft().raceId,
        isNull,
        reason:
            'le Demi-elfe (race 2014) ne doit plus être dans le brouillon '
            'après bascule vers 2024',
      );

      // 5. Nouvelle instance de `RaceStepScreen` : plus aucune race
      // sélectionnée, "Suivant" désactivé, Demi-elfe entièrement absente de
      // la liste (décision du 30/10/2026) — c'est exactement le scénario
      // que QA a vu passer AVANT le correctif du 24/10/2026 (race encore
      // sélectionnée, "Suivant" encore actif, aucun message).
      expect(find.text('2. Race'), findsOneWidget);
      expect(
        find.text('Demi-elfe'),
        findsNothing,
        reason:
            'une race indisponible dans l\'édition courante ne doit plus '
            'apparaître du tout dans la liste, même grisée',
      );
      final nextButton = tester.widget<PrimaryButton>(
        find.byType(PrimaryButton),
      );
      expect(
        nextButton.onPressed,
        isNull,
        reason:
            '"Suivant" doit être désactivé : plus aucune race sélectionnée '
            'après la réinitialisation déclenchée par le changement '
            "d'édition",
      );
      expect(readDraft().raceId, isNull);
    },
  );
}
