// Tests de non-regression documentant 2 bugs de course entre un ajustement
// PV (_applyHpState, ex. le stepper "+"/"-" ou HpAdjustmentSheet) et un
// repos long (_applyRest), trouves en revue QA puis en revue de code du
// chantier "Repos court/long" (voir les rapports correspondants). CORRIGES
// dans character_detail_screen.dart (jeton [_restGeneration] +
// [_reassertCurrentHpState] pour le premier sens, verrou
// [_isApplyingRest]/`CharacterVitalsCard.hpActionsDisabled` pour le second) —
// meme traitement que character_detail_hp_stepper_race_test.dart.
//
// Les deux bugs partagent la meme cause racine (aucune coordination entre
// les deux flux d'ecriture PV) mais se produisent dans des sens opposes de
// la fenetre de course :
//
// 1. Ajustement PV demarre AVANT le repos, resout APRES lui (voir le 1er
//    test ci-dessous) :
//   a. _applyHpState bascule _localHpState de facon optimiste (avant son
//      await updateHp(...)).
//   b. _applyRest(RestType.long) ecrit current_hp = max_hp en base et
//      rafraichit la fiche pendant que l'appel precedent est encore en vol.
//   c. Quand le updateHp de l'etape (a) finit par resoudre, il ecrit en
//      base la valeur pre-repos qu'il avait calculee avant l'ouverture de
//      la feuille "Repos" - ecrasant silencieusement le current_hp correct
//      que le repos long venait d'etablir, sans aucune erreur visible pour
//      le joueur.
//
// 2. Ajustement PV demarre PENDANT que le repos ecrit encore en base,
//    resout AVANT lui (voir le 2e test ci-dessous) : le jeton
//    [_restGeneration] seul ne suffit pas a fermer ce sens (il a deja ete
//    avance par le repos avant que cet ajustement ne demarre, donc aucun
//    mismatch n'est detecte) - seul un verrou desactivant les steppers/le
//    crayon PV pendant la fenetre ferme cette course-la.

import "dart:async";
import "dart:typed_data";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:go_router/go_router.dart";
import "package:personnages/features/characters/data/character_repository.dart";
import "package:personnages/features/characters/domain/character_detail.dart";
import "package:personnages/features/characters/domain/character_detail_class_row.dart";
import "package:personnages/features/characters/domain/character_summary.dart";
import "package:personnages/features/characters/domain/level_up_apply_result.dart";
import "package:personnages/features/characters/domain/level_up_choice_selection.dart";
import "package:personnages/features/characters/domain/level_up_level_data.dart";
import "package:personnages/features/characters/domain/rest_type.dart";
import "package:personnages/features/characters/domain/write_outcome.dart";
import "package:personnages/features/characters/presentation/character_detail_screen.dart";
import "package:personnages/features/characters/presentation/providers/character_providers.dart";

class FakeRepository implements CharacterRepository {
  CharacterDetail current = detail;
  final Completer<void> updateHpGate = Completer<void>();

  /// `null` (défaut) : `applyRest` résout immédiatement, comme un vrai
  /// repos long dans le cas nominal — utilisé par le 1er test. Un test peut
  /// remplacer ce champ par un `Completer` non résolu avant de taper
  /// "Appliquer" pour garder le repos "en vol" le temps de vérifier que les
  /// actions PV sont bien verrouillées pendant cette fenêtre (2e test).
  Completer<void>? applyRestGate;

  int? lastPersistedCurrentHp;
  int updateHpCallCount = 0;
  int applyRestCallCount = 0;

  @override
  Future<List<CharacterSummary>> fetchCharacters() async => const [];

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) async =>
      current;

  @override
  Future<WriteOutcome> updateHp({
    required String characterId,
    required int currentHp,
    required int temporaryHp,
  }) async {
    updateHpCallCount++;
    await updateHpGate.future;
    lastPersistedCurrentHp = currentHp;
    current = current.copyWith(currentHp: currentHp, temporaryHp: temporaryHp);
    return WriteOutcome.synced;
  }

  @override
  Future<void> applyRest({
    required String characterId,
    required RestType type,
    required String className,
  }) async {
    applyRestCallCount++;
    final gate = applyRestGate;
    if (gate != null) await gate.future;
    if (type == RestType.long) {
      current = current.copyWith(currentHp: current.maxHp, temporaryHp: 0);
    }
  }

  @override
  Future<String> uploadPortrait({
    required String characterId,
    required Uint8List bytes,
  }) => throw UnimplementedError();

  @override
  Future<void> removePortrait({
    required String characterId,
    required String portraitUrl,
  }) async {}

  @override
  Future<WriteOutcome> addXp({
    required String characterId,
    required int newXp,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<LevelUpLevelData> fetchLevelUpLevelData({
    required Object classId,
    required int targetLevel,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<LevelUpApplyResult> applyLevelUp({
    required String characterId,
    required String className,
    required int hpRolled,
    required String hpMethod,
    required int hpGain,
    LevelUpChoiceSelection? choice,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> leaveStory({required String characterCampaignId}) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> castSpell({
    required String characterId,
    required int slotLevel,
    required int slotsUsed,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> useClassFeature({
    required String characterId,
    required int classFeatureId,
    required int usesRemaining,
  }) {
    throw UnimplementedError();
  }
}

const detail = CharacterDetail(
  id: "1",
  name: "Test",
  classes: [
    CharacterDetailClassRow(
      classId: 1,
      hitDie: 8,
      className: "Guerrier",
      level: 1,
      isPrimary: true,
      savingThrowProficiencies: [],
    ),
  ],
  xp: 0,
  currentHp: 18,
  maxHp: 30,
  temporaryHp: 0,
  abilityScores: {},
);

Future<FakeRepository> pumpDetail(WidgetTester tester) async {
  final repository = FakeRepository();
  await tester.binding.setSurfaceSize(const Size(800, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [characterRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: "/characters/1",
          routes: [
            GoRoute(
              path: "/characters/:id",
              builder: (context, state) => CharacterDetailScreen(
                characterId: state.pathParameters["id"]!,
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets(
    "un ajustement PV encore en vol au moment d un repos long n ecrase "
    "plus le resultat du repos une fois qu il resout (CORRIGE)",
    (tester) async {
      final repository = await pumpDetail(tester);

      await tester.tap(find.bySemanticsLabel("Augmenter"));
      await tester.pump();

      await tester.tap(find.text("Prendre un repos"));
      await tester.pumpAndSettle();
      await tester.tap(find.text("APPLIQUER"));
      await tester.pumpAndSettle();

      expect(repository.current.currentHp, 30);

      repository.updateHpGate.complete();
      await tester.pumpAndSettle();

      expect(
        repository.current.currentHp,
        30,
        reason:
            "L ajustement PV reste en vol ne doit plus ecraser le repos "
            "long : current_hp = ${repository.current.currentHp} en base "
            "au lieu de 30.",
      );
      expect(
        find.text("30 / 30"),
        findsWidgets,
        reason:
            "L ecran doit afficher 30/30 (resultat du repos long), pas la "
            "valeur pre-repos.",
      );
    },
  );

  testWidgets(
    "les actions PV (stepper +/-, crayon) sont desactivees pendant qu un "
    "repos long est encore en vol, et reactivees une fois resolu (CORRIGE : "
    "ferme le sens de course inverse du test precedent)",
    (tester) async {
      final repository = await pumpDetail(tester);
      repository.applyRestGate = Completer<void>();

      await tester.tap(find.text("Prendre un repos"));
      await tester.pumpAndSettle();
      // "Repos long" est le segment sélectionné par défaut (spec DA).
      await tester.tap(find.text("APPLIQUER"));
      // `pump()`, pas `pumpAndSettle()` : `applyRest` est gaté, en attente
      // indéfinie tant que `applyRestGate` n'est pas complété — laisse le
      // temps à `_applyRest` de démarrer (verrou posé) sans jamais résoudre.
      await tester.pump();

      final decrementInkWell = tester.widget<InkWell>(
        find.ancestor(
          of: find.bySemanticsLabel("Diminuer"),
          matching: find.byType(InkWell),
        ),
      );
      expect(
        decrementInkWell.onTap,
        isNull,
        reason:
            "Le stepper '-' doit être désactivé tant que le repos long est "
            "en vol.",
      );
      final incrementInkWell = tester.widget<InkWell>(
        find.ancestor(
          of: find.bySemanticsLabel("Augmenter"),
          matching: find.byType(InkWell),
        ),
      );
      expect(incrementInkWell.onTap, isNull);
      final adjustHpButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.edit_outlined),
          matching: find.byType(IconButton),
        ),
      );
      expect(adjustHpButton.onPressed, isNull);

      // Un tap sur un bouton désactivé (`onTap`/`onPressed` nul) ne
      // déclenche aucun appel réseau — vérifie explicitement qu'aucune
      // écriture PV n'a pu démarrer pendant la fenêtre, pas seulement que
      // le widget est visuellement désactivé.
      await tester.tap(find.bySemanticsLabel("Diminuer"), warnIfMissed: false);
      await tester.pump();
      expect(repository.updateHpCallCount, 0);

      repository.applyRestGate!.complete();
      await tester.pumpAndSettle();

      expect(repository.current.currentHp, 30);
      expect(find.text("30 / 30"), findsWidgets);

      final decrementAfter = tester.widget<InkWell>(
        find.ancestor(
          of: find.bySemanticsLabel("Diminuer"),
          matching: find.byType(InkWell),
        ),
      );
      expect(
        decrementAfter.onTap,
        isNotNull,
        reason: "Le stepper doit être réactivé une fois le repos résolu.",
      );
    },
  );
}
