// Tests de widget du flux "Montée de niveau" (increments 1 et 2).
//
// Même principe que les autres écrans de la fiche personnage : dépôt
// factice injecté via `overrideWithValue`, aucun appel réseau réel.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
import 'package:personnages/features/character_creation/domain/skill_catalog.dart';
import 'package:personnages/features/character_creation/domain/spell_catalog.dart';
import 'package:personnages/features/character_creation/domain/spell_option.dart';
import 'package:personnages/features/character_creation/domain/tool_catalog.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_providers.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_class_feature.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/characters/domain/inventory_catalog_item.dart';
import 'package:personnages/features/characters/domain/level_up_apply_result.dart';
import 'package:personnages/features/characters/domain/level_up_feat_option.dart';
import 'package:personnages/features/characters/domain/level_up_invocation_option.dart';
import 'package:personnages/features/characters/domain/level_up_choice_kind.dart';
import 'package:personnages/features/characters/domain/level_up_choice_selection.dart';
import 'package:personnages/features/characters/domain/level_up_level_data.dart';
import 'package:personnages/features/characters/domain/level_up_subclass_option.dart';
import 'package:personnages/features/characters/domain/rest_type.dart';
import 'package:personnages/features/characters/domain/reward_item_draft.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/features/characters/presentation/level_up_screen.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';

class _AppliedLevelUp {
  const _AppliedLevelUp({
    required this.classId,
    required this.className,
    required this.isMulticlassing,
    required this.hpRolled,
    required this.hpMethod,
    required this.hpGain,
    required this.choice,
    required this.initialSpellIds,
    required this.invocationIds,
  });

  final Object classId;
  final String className;
  final bool isMulticlassing;
  final int hpRolled;
  final String hpMethod;
  final int hpGain;
  final LevelUpChoiceSelection? choice;
  final List<int> initialSpellIds;
  final List<int> invocationIds;
}

/// Fake minimal de `CharacterCreationRepository` — seul
/// `fetchClassCatalog`/`fetchSpellCatalog` sont réellement exercés par
/// `levelUpStepDataProvider` (calcul des options de multiclassage et de la
/// sélection de sorts de départ, voir `presentation/providers/level_up_provider.dart`).
/// Catalogue de classes vide par défaut : la quasi-totalité des tests de ce
/// fichier ne portent pas sur le multiclassage, et une classe vide garantit
/// qu'aucune classe n'est jamais proposée comme option de multiclassage
/// (l'étape `classDecision` reste alors invisible), quels que soient les
/// scores de caractéristiques du personnage testé.
class _FakeCharacterCreationRepository implements CharacterCreationRepository {
  ClassCatalog classCatalogToReturn = const ClassCatalog(classes: []);
  Map<int, SpellCatalog> spellCatalogByClassId = {};

  @override
  Future<ClassCatalog> fetchClassCatalog() async => classCatalogToReturn;

  @override
  Future<SpellCatalog> fetchSpellCatalog({required int classId}) async =>
      spellCatalogByClassId[classId] ?? const SpellCatalog(spells: []);

  @override
  Future<RaceCatalog> fetchRaceCatalog() => throw UnimplementedError();

  @override
  Future<BackgroundCatalog> fetchBackgroundCatalog() =>
      throw UnimplementedError();

  @override
  Future<ToolCatalog> fetchToolCatalog() => throw UnimplementedError();

  @override
  Future<LanguageCatalog> fetchLanguageCatalog() => throw UnimplementedError();

  @override
  Future<ItemCatalog> fetchItemCatalog() => throw UnimplementedError();

  @override
  Future<SkillCatalog> fetchSkillCatalog() => throw UnimplementedError();

  @override
  Future<AlignmentCatalog> fetchAlignmentCatalog() =>
      throw UnimplementedError();

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
  }) => throw UnimplementedError();
}

class _FakeCharacterRepository implements CharacterRepository {
  CharacterDetail? detailToReturn;
  Object? detailErrorToThrow;
  Completer<CharacterDetail>? detailCompleter;
  int fetchDetailCallCount = 0;

  Map<int, LevelUpLevelData> levelDataByLevel = {};
  Object? levelDataErrorToThrow;
  final List<int> fetchLevelUpLevelDataCalls = [];

  LevelUpApplyResult? applyResultToReturn;
  Object? applyErrorToThrow;
  final List<_AppliedLevelUp> applyLevelUpCalls = [];

  // Vide par défaut (comportement neutre pour l'immense majorité des tests
  // de ce fichier, qui n'exercent ni le sous-mode "don" ni l'étape
  // "Invocations") — overridable par test comme `levelDataByLevel`.
  List<LevelUpFeatOption> featsToReturn = const [];
  List<LevelUpInvocationOption> invocationsToReturn = const [];

  @override
  Future<List<CharacterSummary>> fetchCharacters() async => const [];

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) async {
    fetchDetailCallCount++;
    if (detailCompleter != null) return detailCompleter!.future;
    if (detailErrorToThrow != null) throw detailErrorToThrow!;
    return detailToReturn!;
  }

  @override
  Future<LevelUpLevelData> fetchLevelUpLevelData({
    required Object classId,
    required int targetLevel,
  }) async {
    fetchLevelUpLevelDataCalls.add(targetLevel);
    if (levelDataErrorToThrow != null) throw levelDataErrorToThrow!;
    return levelDataByLevel[targetLevel] ??
        const LevelUpLevelData(choiceType: null, automaticFeatures: []);
  }

  @override
  Future<List<LevelUpFeatOption>> fetchAvailableFeats({
    required String characterId,
  }) async => featsToReturn;

  @override
  Future<List<LevelUpInvocationOption>> fetchAvailableInvocations({
    required String characterId,
  }) async => invocationsToReturn;

  @override
  Future<LevelUpApplyResult> applyLevelUp({
    required String characterId,
    required Object classId,
    required String className,
    required bool isMulticlassing,
    required int hpRolled,
    required String hpMethod,
    required int hpGain,
    LevelUpChoiceSelection? choice,
    List<int> initialSpellIds = const [],
    List<int> invocationIds = const [],
  }) async {
    applyLevelUpCalls.add(
      _AppliedLevelUp(
        classId: classId,
        className: className,
        isMulticlassing: isMulticlassing,
        hpRolled: hpRolled,
        hpMethod: hpMethod,
        hpGain: hpGain,
        choice: choice,
        initialSpellIds: initialSpellIds,
        invocationIds: invocationIds,
      ),
    );
    if (applyErrorToThrow != null) throw applyErrorToThrow!;
    // Simule la persistance réelle (`character_repository.dart::applyLevelUp`
    // écrit la nouvelle valeur de `character_classes.level` en base) : le
    // véritable `CharacterRepository` renverrait cette valeur mise à jour au
    // prochain `fetchCharacterDetail`, ce que l'écran déclenche bien via
    // `ref.invalidate(characterDetailProvider(...))` juste après cet appel
    // (voir `level_up_screen.dart::_continueFromSummary`). Nécessaire depuis
    // que `levelUpStepDataProvider` calcule le niveau interne de la classe
    // continuée depuis `primaryClass.level` plutôt que depuis `targetLevel`
    // (le niveau TOTAL) — sans cette mise à jour, un chaînage de plusieurs
    // niveaux dans les tests interrogerait indéfiniment le même niveau.
    final detail = detailToReturn;
    if (detail != null) {
      final targetClassId = (classId as num).toInt();
      final matched = detail.classes.any(
        (row) => (row.classId as num).toInt() == targetClassId,
      );
      // Reconstruit explicitement (pas de `copyWith` sur une classe simple) :
      // incrémente la classe continuée, ou ajoute la nouvelle classe de
      // multiclassage à son niveau 1.
      // Pour un personnage à une seule classe, `applyResultToReturn.newLevel`
      // (niveau TOTAL, voir sa doc de classe) est aussi le niveau de CETTE
      // classe (total == niveau de l'unique classe) : réutiliser cette
      // valeur plutôt qu'un simple `+ 1` permet aux quelques tests de ce
      // fichier qui forcent volontairement un grand saut de niveau via
      // `applyResultToReturn` (chaînage "forcé", XP très en avance) de rester
      // cohérents avec la classe primaire refetchée. Pour un personnage
      // multiclassé qui continue sa primaire, `newLevel` (TOTAL) ne
      // correspond plus au niveau de la seule classe primaire : `+ 1` reste
      // le seul calcul correct dans ce cas (une montée de niveau n'incrémente
      // jamais une classe de plus d'un niveau à la fois).
      final singleClassContinue =
          !isMulticlassing && detail.classes.length == 1;
      final newClasses = [
        for (final row in detail.classes)
          if ((row.classId as num).toInt() == targetClassId)
            CharacterDetailClassRow(
              classId: row.classId,
              className: row.className,
              level: isMulticlassing
                  ? 1
                  : singleClassContinue
                  ? applyResultToReturn!.newLevel
                  : row.level + 1,
              isPrimary: row.isPrimary,
              savingThrowProficiencies: row.savingThrowProficiencies,
              hitDie: row.hitDie,
              hitDiceSpent: row.hitDiceSpent,
            )
          else
            row,
        if (!matched)
          CharacterDetailClassRow(
            classId: classId,
            className: className,
            level: 1,
            isPrimary: false,
            savingThrowProficiencies: const [],
            hitDie: null,
          ),
      ];
      detailToReturn = detail.copyWith(classes: newClasses);
    }
    return applyResultToReturn!;
  }

  @override
  Future<WriteOutcome> addXp({
    required String characterId,
    required int newXp,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> updateHp({
    required String characterId,
    required int currentHp,
    required int temporaryHp,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<String> uploadPortrait({
    required String characterId,
    required Uint8List bytes,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> removePortrait({
    required String characterId,
    required String portraitUrl,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> applyRest({
    required String characterId,
    required RestType type,
    required String className,
    int diceSpent = 0,
    int appliedGain = 0,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> leaveStory({required String characterCampaignId}) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> updateStoryFields({
    required String characterId,
    String? appearanceText,
    String? traitsText,
    String? idealsText,
    String? bondsText,
    String? flawsText,
    String? backstoryText,
    String? alliesText,
    String? featuresText,
    String? treasureText,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> useInventoryItem({
    required String characterId,
    required String inventoryId,
    required int newQuantity,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> setInventoryItemEquipped({
    required String characterId,
    required String inventoryId,
    required bool equipped,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> removeInventoryItem({
    required String characterId,
    required String inventoryId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> adjustCurrency({
    required String characterId,
    required CurrencyKind currency,
    required int newAmount,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> addInventoryItem({
    required String characterId,
    required int itemId,
    required int quantity,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> addCustomInventoryItem({
    required String characterId,
    required String customName,
    required int quantity,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> addReward({
    required String characterId,
    required Map<CurrencyKind, int> newCurrencyTotals,
    required List<RewardItemDraft> items,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<InventoryCatalogItem>> fetchInventoryCatalog() {
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

const _baseDetail = CharacterDetail(
  id: 'char-1',
  name: 'Halltesse',
  classes: [
    CharacterDetailClassRow(
      classId: 1,
      hitDie: 10,
      className: 'Guerrier',
      level: 4,
      isPrimary: true,
      savingThrowProficiencies: [],
    ),
  ],
  xp: 2700,
  currentHp: 24,
  maxHp: 28,
  temporaryHp: 0,
  abilityScores: {'con': 14},
);

/// [_baseDetail] avec sa classe primaire (Guerrier) au niveau [level] plutôt
/// que 4 — nécessaire depuis que `levelUpStepDataProvider` calcule le niveau
/// interne de la classe continuée depuis `primaryClass.level` (voir la
/// correction de la branche "continuer" de `level_up_provider.dart`) : un
/// test qui pousse directement `targetLevel: N` (sans simuler les N-5
/// montées de niveau intermédiaires depuis le niveau 4 par défaut) doit
/// désormais fournir une fiche dont la classe primaire est déjà à `N - 1`,
/// sans quoi `fetchLevelUpLevelData`/`LevelUpBlockRules.evaluate` seraient
/// appelés avec un niveau différent de celui réellement testé.
CharacterDetail _baseDetailAtLevel(int level) => _baseDetail.copyWith(
  classes: [
    CharacterDetailClassRow(
      classId: 1,
      hitDie: 10,
      className: 'Guerrier',
      level: level,
      isPrimary: true,
      savingThrowProficiencies: const [],
    ),
  ],
);

void main() {
  late _FakeCharacterRepository fakeRepository;
  late _FakeCharacterCreationRepository fakeCreationRepository;
  late ProviderContainer container;
  late GoRouter router;

  setUp(() {
    fakeRepository = _FakeCharacterRepository();
    fakeCreationRepository = _FakeCharacterCreationRepository();
    container = ProviderContainer(
      overrides: [
        characterRepositoryProvider.overrideWithValue(fakeRepository),
        characterCreationRepositoryProvider.overrideWithValue(
          fakeCreationRepository,
        ),
      ],
    );
  });

  tearDown(() => container.dispose());

  GoRouter buildTestRouter() {
    router = GoRouter(
      initialLocation: '/characters/char-1',
      routes: [
        GoRoute(
          path: '/characters/:id',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Fiche personnage'))),
        ),
        GoRoute(
          path: '/characters/:id/level-up',
          builder: (context, state) => LevelUpScreen(
            characterId: state.pathParameters['id']!,
            initialTargetLevel: int.parse(state.uri.queryParameters['level']!),
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

  /// Instruction de l'étape `classDecision` (multiclassage) — voir
  /// [_LevelUpScreenState._buildClassDecision] côté écran.
  const classDecisionInstruction = "Choisissez comment ce niveau s'applique.";

  Future<void> pushLevelUp(WidgetTester tester, int level) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();
    router.push('/characters/char-1/level-up?level=$level');
    await tester.pumpAndSettle();
    // Auto-saute l'étape `classDecision` si elle s'affiche (sélection par
    // défaut "Continuer", voir `_continueCurrentClassSentinel`) : la quasi-
    // totalité des tests de ce fichier ne portent pas sur le multiclassage
    // (catalogue de classes vide par défaut, voir
    // `_FakeCharacterCreationRepository`), mais quelques-uns exercent des
    // scores de caractéristiques élevés pour une autre raison (ex. le
    // plafond ASI à 20) qui peuvent accessoirement satisfaire un prérequis
    // de multiclassage réel — ce garde-fou les laisse inchangés plutôt que de
    // les faire échouer sur une étape non liée à ce qu'ils exercent.
    if (find.text(classDecisionInstruction).evaluate().isNotEmpty) {
      await tester.tap(find.text('CONTINUER'));
      await tester.pumpAndSettle();
    }
  }

  /// Navigue jusqu'au flux, puis franchit l'annonce de niveau (increment 4)
  /// via son unique bouton "Continuer" — pour tous les tests qui exercent
  /// les étapes de saisie (points de vie/aptitudes/choix/sorts/récapitulatif)
  /// ou l'écran de blocage, sans porter sur l'annonce elle-même (voir le
  /// groupe "annonce de niveau" ci-dessous pour ces derniers).
  Future<void> pushPastAnnouncement(WidgetTester tester, int level) async {
    await pushLevelUp(tester, level);
    await tester.tap(find.text('CONTINUER'));
    await tester.pumpAndSettle();
  }

  testWidgets('affiche un indicateur de chargement pendant la récupération', (
    tester,
  ) async {
    fakeRepository.detailCompleter = Completer<CharacterDetail>();

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();
    router.push('/characters/char-1/level-up?level=5');
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('MONTÉE DE NIVEAU'), findsOneWidget);
  });

  testWidgets(
    'affiche un état d\'erreur avec un bouton "Réessayer" qui relance la '
    'requête',
    (tester) async {
      fakeRepository.detailErrorToThrow = const CharacterFailure(
        'Personnage introuvable.',
      );

      await pushLevelUp(tester, 5);

      expect(find.text('Personnage introuvable.'), findsOneWidget);
      expect(fakeRepository.fetchDetailCallCount, 1);

      fakeRepository.detailErrorToThrow = null;
      fakeRepository.detailToReturn = _baseDetail;

      await tester.tap(find.text('RÉESSAYER'));
      await tester.pumpAndSettle();

      expect(find.text('NIVEAU 5'), findsOneWidget);
    },
  );

  group('niveau bloqué (choix requis)', () {
    testWidgets(
      'un choice_type de class_features non résolu (ex. sort_domaine) '
      'bloque avec le libellé résolu — increment 2 : contrairement à '
      "sous_classe/style_combat/ennemi_jure, désormais gérés par l'étape "
      '"Choix à faire" (voir le groupe ci-dessous), les autres valeurs '
      'restent hors périmètre et continuent de bloquer',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail;
        fakeRepository.levelDataByLevel = {
          5: const LevelUpLevelData(
            choiceType: 'sort_domaine',
            automaticFeatures: [],
          ),
        };

        await pushPastAnnouncement(tester, 5);

        expect(find.text('Niveau 5 : choix requis'), findsOneWidget);
        expect(
          find.text('Guerrier niveau 5 : Sort de domaine'),
          findsOneWidget,
        );
      },
    );
  });

  group('flux complet, niveau non bloqué', () {
    setUp(() {
      fakeRepository.detailToReturn = _baseDetail;
      fakeRepository.levelDataByLevel = {
        5: const LevelUpLevelData(
          choiceType: null,
          automaticFeatures: [
            CharacterClassFeature(
              id: 10,
              name: 'Attaque supplémentaire',
              level: 5,
            ),
          ],
        ),
      };
    });

    testWidgets(
      'étape "Points de vie" : bascule sur "Valeur moyenne" affiche la '
      'valeur déterministe et l\'aperçu "Points de vie maximum"',
      (tester) async {
        await pushPastAnnouncement(tester, 5);

        expect(find.text('NIVEAU 5'), findsOneWidget);
        expect(find.text('Étape 1 sur 3 · Points de vie'), findsOneWidget);
        expect(find.text('Dé de vie de la classe : d10'), findsOneWidget);
        // Mode "Lancer le dé" par défaut : lien "Relancer le dé" visible.
        expect(find.text('Relancer le dé'), findsOneWidget);

        await tester.tap(find.text('VALEUR MOYENNE'));
        await tester.pumpAndSettle();

        // d10 -> moyenne 6, +2 (modificateur Con 14) -> gain 8.
        expect(find.text('6'), findsOneWidget);
        expect(find.text('+2 modificateur de Constitution'), findsOneWidget);
        expect(
          find.text('(moitié du dé arrondie au supérieur, +1)'),
          findsOneWidget,
        );
        expect(find.text('Relancer le dé'), findsNothing);
        expect(find.text('Points de vie maximum'), findsOneWidget);
        expect(find.text('28 → 36 (+8)'), findsOneWidget);
      },
    );

    testWidgets(
      'étape "Aptitudes de classe automatiques" affiche les aptitudes '
      'résolues, l\'état vide sinon',
      (tester) async {
        await pushPastAnnouncement(tester, 5);
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        expect(
          find.text('Étape 2 sur 3 · Aptitudes de classe'),
          findsOneWidget,
        );
        expect(find.text('Vous obtenez automatiquement :'), findsOneWidget);
        expect(find.text('Nouvelle aptitude'), findsOneWidget);
        expect(find.text('Attaque supplémentaire'), findsOneWidget);
      },
    );

    testWidgets(
      'état vide de l\'étape "Aptitudes" quand aucune aptitude automatique',
      (tester) async {
        fakeRepository.levelDataByLevel = {
          5: const LevelUpLevelData(choiceType: null, automaticFeatures: []),
        };

        await pushPastAnnouncement(tester, 5);
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        expect(
          find.text('Aucune nouvelle aptitude de classe à ce niveau.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '"Retour" de l\'étape "Aptitudes" ramène à l\'étape "Points de vie" '
      '(même écran, pas de navigation)',
      (tester) async {
        await pushPastAnnouncement(tester, 5);
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('RETOUR'));
        await tester.pumpAndSettle();

        expect(find.text('Étape 1 sur 3 · Points de vie'), findsOneWidget);
      },
    );

    testWidgets(
      '"Retour" de l\'étape "Points de vie" (première étape) revient à la '
      'fiche personnage',
      (tester) async {
        await pushPastAnnouncement(tester, 5);

        await tester.tap(find.text('RETOUR'));
        await tester.pumpAndSettle();

        expect(find.text('Fiche personnage'), findsOneWidget);
      },
    );

    testWidgets(
      'récapitulatif : affiche les gains (PV + aptitude), pas de bouton '
      '"Retour", "Continuer" appelle applyLevelUp avec les bons paramètres '
      'puis revient à la fiche (aucun seuil supplémentaire déjà franchi)',
      (tester) async {
        fakeRepository.applyResultToReturn = const LevelUpApplyResult(
          newLevel: 5,
          newMaxHp: 36,
          newCurrentHp: 32,
        );

        await pushPastAnnouncement(tester, 5);
        await tester.tap(find.text('VALEUR MOYENNE'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        expect(find.text('NIVEAU 5'), findsOneWidget);
        expect(find.text('Étape 1 sur 3'), findsNothing);
        expect(find.text('Points de vie maximum'), findsOneWidget);
        expect(find.text('28 → 36 (+8)'), findsOneWidget);
        expect(find.text('Nouvelle aptitude'), findsOneWidget);
        expect(find.textContaining('Retour'), findsNothing);

        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        expect(fakeRepository.applyLevelUpCalls, hasLength(1));
        expect(fakeRepository.applyLevelUpCalls.single.hpRolled, 6);
        expect(fakeRepository.applyLevelUpCalls.single.hpMethod, 'moyenne');
        expect(fakeRepository.applyLevelUpCalls.single.hpGain, 8);
        // Aucun choix à ce niveau (5, hors ASI, sans choice_type) : `null`,
        // comportement de l'increment 1 inchangé.
        expect(fakeRepository.applyLevelUpCalls.single.choice, isNull);

        // xp (2700) ne franchit pas le seuil du niveau 6 (14000) : retour à
        // la fiche, pas de chaînage.
        expect(find.text('Fiche personnage'), findsOneWidget);
      },
    );

    testWidgets('chaînage : un seuil XP supplémentaire déjà franchi enchaîne '
        'directement sur l\'étape "Points de vie" du niveau suivant, sans '
        'navigation', (tester) async {
      fakeRepository.detailToReturn = _baseDetail.copyWith(xp: 14000);
      fakeRepository.applyResultToReturn = const LevelUpApplyResult(
        newLevel: 5,
        newMaxHp: 36,
        newCurrentHp: 32,
      );
      fakeRepository.levelDataByLevel = {
        5: const LevelUpLevelData(choiceType: null, automaticFeatures: []),
        6: const LevelUpLevelData(choiceType: null, automaticFeatures: []),
      };

      await pushLevelUp(tester, 5);
      // Annonce du niveau 5 : remainingLevelsLabel déjà visible dessus.
      expect(find.text('Encore 1 niveau à valider ensuite'), findsOneWidget);

      await tester.tap(find.text('CONTINUER')); // annonce 5 -> Points de vie
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONTINUER')); // Points de vie -> Aptitudes
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONTINUER')); // Aptitudes -> Récapitulatif
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONTINUER')); // applique, enchaîne niveau 6
      await tester.pumpAndSettle();

      expect(fakeRepository.applyLevelUpCalls, hasLength(1));
      // Toujours sur le flux, jamais revenu à la fiche.
      expect(find.text('Fiche personnage'), findsNothing);
      // Le chaînage réaffiche une nouvelle annonce pour le niveau 6, pas
      // directement l'étape "Points de vie" (voir le groupe "annonce de
      // niveau" pour le détail de son contenu).
      expect(find.text('NIVEAU 6'), findsOneWidget);
      expect(find.text('Étape 1 sur 3 · Points de vie'), findsNothing);

      await tester.tap(find.text('CONTINUER')); // annonce 6 -> Points de vie
      await tester.pumpAndSettle();

      expect(find.text('NIVEAU 6'), findsOneWidget);
      expect(find.text('Étape 1 sur 3 · Points de vie'), findsOneWidget);
    });

    testWidgets(
      'chaînage : si le niveau suivant déjà déverrouillé reste bloqué (ex. '
      'choice_type non résolu), le flux s\'arrête proprement dessus SANS '
      'perdre le niveau déjà validé juste avant',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetailAtLevel(6)
            .copyWith(xp: 34000);
        fakeRepository.applyResultToReturn = const LevelUpApplyResult(
          newLevel: 7,
          newMaxHp: 44,
          newCurrentHp: 40,
        );
        // Niveau 7 : ni choice_type, ni niveau ASI -> pas de blocage.
        // Niveau 8 : choice_type non résolu (`sort_domaine`, valeur fictive
        // représentant tout `choice_type` futur non encore géré — `invocation`
        // ne peut plus servir cet exemple depuis que ce chantier l'a ajouté à
        // `resolvedChoiceTypes`) -> reste bloqué, indépendamment du fait que 8
        // soit aussi un niveau ASI (la condition 1 est évaluée en premier,
        // voir `LevelUpBlockRules.evaluate`).
        fakeRepository.levelDataByLevel = {
          7: const LevelUpLevelData(choiceType: null, automaticFeatures: []),
          8: const LevelUpLevelData(
            choiceType: 'sort_domaine',
            automaticFeatures: [],
          ),
        };

        await pushPastAnnouncement(tester, 7);
        // Annonce déjà franchie, mais son `remainingLevelsLabel` reste
        // affiché sur l'étape "Points de vie" (voir `LevelUpHeader`).
        expect(find.text('Encore 1 niveau à valider ensuite'), findsOneWidget);

        await tester.tap(find.text('VALEUR MOYENNE'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER')); // Points de vie -> Aptitudes
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER')); // Aptitudes -> Récapitulatif
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER')); // applique, enchaîne niveau 8
        await tester.pumpAndSettle();

        // Le niveau 7 a bien été appliqué (écrit une seule fois) avant que
        // le chaînage ne bute sur le niveau 8 bloqué.
        expect(fakeRepository.applyLevelUpCalls, hasLength(1));

        // Le chaînage réaffiche d'abord l'annonce du niveau 8 (avant même de
        // savoir qu'il est bloqué, voir `_buildData`) : le joueur a atteint
        // ce niveau, indépendamment de la capacité de l'app à l'accompagner
        // sur son étape "Choix à faire".
        expect(find.text('Fiche personnage'), findsNothing);
        expect(find.text('MONTÉE DE NIVEAU'), findsOneWidget);
        expect(find.text('NIVEAU 8'), findsOneWidget);
        expect(find.text('Niveau 8 : choix requis'), findsNothing);

        await tester.tap(find.text('CONTINUER')); // annonce 8 -> blocage
        await tester.pumpAndSettle();

        // Jamais revenu à la fiche : le flux reste affiché sur l'écran de
        // blocage du niveau 8, pas de perte silencieuse du niveau validé.
        expect(find.text('Fiche personnage'), findsNothing);
        expect(find.text('NIVEAU ATTEINT'), findsOneWidget);
        expect(find.text('MONTÉE DE NIVEAU'), findsNothing);
        // `_targetLevel - 1` : le dernier niveau réellement validé (7), pas
        // le niveau bloqué (8).
        expect(find.text('NIVEAU 7'), findsOneWidget);
        expect(find.text('Niveau 8 : choix requis'), findsOneWidget);
        expect(
          find.text('Guerrier niveau 8 : Sort de domaine'),
          findsOneWidget,
        );

        await tester.tap(find.text('RETOUR À LA FICHE'));
        await tester.pumpAndSettle();
        expect(find.text('Fiche personnage'), findsOneWidget);
      },
    );

    testWidgets('un échec de applyLevelUp affiche un bandeau d\'erreur sur le '
        'récapitulatif, sans naviguer', (tester) async {
      fakeRepository.applyErrorToThrow = const CharacterFailure(
        'Impossible de sauvegarder. Réessayez.',
      );

      await pushPastAnnouncement(tester, 5);
      await tester.tap(find.text('CONTINUER'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONTINUER'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONTINUER'));
      await tester.pumpAndSettle();

      expect(
        find.text('Impossible de sauvegarder. Réessayez.'),
        findsOneWidget,
      );
      expect(find.text('Fiche personnage'), findsNothing);
    });
  });

  group('annonce de niveau (increment 4)', () {
    testWidgets(
      "s'affiche en premier, avant l'étape \"Points de vie\" : détail des "
      'aptitudes automatiques, aucun contenu des étapes suivantes',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail;
        fakeRepository.levelDataByLevel = {
          5: const LevelUpLevelData(
            choiceType: null,
            automaticFeatures: [
              CharacterClassFeature(
                id: 10,
                name: 'Attaque supplémentaire',
                level: 5,
              ),
            ],
          ),
        };

        await pushLevelUp(tester, 5);

        expect(find.text('MONTÉE DE NIVEAU'), findsOneWidget);
        expect(find.text('NIVEAU 5'), findsOneWidget);
        // Aucun `stepLabel` sur l'annonce (précède l'étape 1) et header
        // suivi directement de la carte de gains, sans sous-titre
        // intermédiaire.
        expect(find.textContaining('Étape'), findsNothing);
        expect(find.text('Nouvelle aptitude'), findsOneWidget);
        expect(find.text('Attaque supplémentaire'), findsOneWidget);
        // Rien de l'étape "Points de vie" (pas encore atteinte) : le gain
        // de PV dépend d'un choix jet/moyenne pas encore fait.
        expect(find.text('Dé de vie de la classe : d10'), findsNothing);
        expect(find.text('Points de vie maximum'), findsNothing);
      },
    );

    testWidgets('état vide du bloc "aptitudes automatiques" : réutilise '
        '_EmptyFeaturesState tel quel', (tester) async {
      fakeRepository.detailToReturn = _baseDetail;
      fakeRepository.levelDataByLevel = {
        5: const LevelUpLevelData(choiceType: null, automaticFeatures: []),
      };

      await pushLevelUp(tester, 5);

      expect(
        find.text('Aucune nouvelle aptitude de classe à ce niveau.'),
        findsOneWidget,
      );
    });

    testWidgets(
      '"Continuer" transitionne vers l\'étape "Points de vie" quand le '
      'niveau n\'est pas bloqué',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail;
        fakeRepository.levelDataByLevel = {
          5: const LevelUpLevelData(choiceType: null, automaticFeatures: []),
        };

        await pushLevelUp(tester, 5);
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        expect(find.text('Étape 1 sur 3 · Points de vie'), findsOneWidget);
      },
    );

    testWidgets(
      '"Continuer" transitionne vers l\'écran de blocage quand le niveau '
      "l'est — l'annonce reste affichée en premier malgré le blocage "
      '(le joueur a atteint ce niveau, indépendamment du blocage)',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail;
        fakeRepository.levelDataByLevel = {
          5: const LevelUpLevelData(
            choiceType: 'sort_domaine',
            automaticFeatures: [],
          ),
        };

        await pushLevelUp(tester, 5);

        // L'annonce s'affiche d'abord, avant toute mention du blocage.
        expect(find.text('MONTÉE DE NIVEAU'), findsOneWidget);
        expect(find.text('Niveau 5 : choix requis'), findsNothing);

        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        expect(find.text('Niveau 5 : choix requis'), findsOneWidget);
        expect(
          find.text('Guerrier niveau 5 : Sort de domaine'),
          findsOneWidget,
        );
      },
    );

    group('teasers "à venir dans les prochaines étapes"', () {
      testWidgets(
        'absents quand ni choix ni changement d\'emplacements de sorts à ce '
        'niveau',
        (tester) async {
          fakeRepository.detailToReturn = _baseDetail;
          fakeRepository.levelDataByLevel = {
            5: const LevelUpLevelData(choiceType: null, automaticFeatures: []),
          };

          await pushLevelUp(tester, 5);

          expect(find.text('À venir dans les prochaines étapes'), findsNothing);
        },
      );

      testWidgets(
        'teaser "choix" seul (niveau ASI, classe non lanceuse) : libellé '
        'générique, jamais la valeur choisie (pas encore choisie), teaser '
        '"sorts" absent',
        (tester) async {
          fakeRepository.detailToReturn = _baseDetailAtLevel(7);
          fakeRepository.levelDataByLevel = {
            8: const LevelUpLevelData(choiceType: null, automaticFeatures: []),
          };

          await pushLevelUp(tester, 8);

          expect(
            find.text('À venir dans les prochaines étapes'),
            findsOneWidget,
          );
          expect(
            find.text('Un choix de Amélioration ou don vous attendra'),
            findsOneWidget,
          );
          expect(
            find.text('Vos emplacements de sorts vont évoluer'),
            findsNothing,
          );
        },
      );

      testWidgets(
        'teaser "sorts" seul (classe lanceuse, palier débloqué, pas de '
        'niveau ASI) : libellé générique, jamais les deltas exacts, teaser '
        '"choix" absent',
        (tester) async {
          fakeRepository.detailToReturn = _baseDetail.copyWith(
            classes: [
              const CharacterDetailClassRow(
                classId: 3,
                hitDie: 8,
                className: 'Clerc',
                level: 4,
                isPrimary: true,
                savingThrowProficiencies: [],
              ),
            ],
            xp: 0,
          );
          fakeRepository.levelDataByLevel = {
            5: const LevelUpLevelData(choiceType: null, automaticFeatures: []),
          };

          await pushLevelUp(tester, 5);

          expect(
            find.text('À venir dans les prochaines étapes'),
            findsOneWidget,
          );
          expect(
            find.text('Vos emplacements de sorts vont évoluer'),
            findsOneWidget,
          );
          expect(find.textContaining('Un choix de'), findsNothing);
          // Jamais les deltas exacts (redondant avec l'étape "Sorts" qui
          // suit immédiatement) : ni "Niveau 3 débloqué" ni les wordings
          // spécifiques de `_spellSlotGainRow`.
          expect(find.text('Niveau 3 débloqué'), findsNothing);
        },
      );

      testWidgets('les deux teasers ensemble (niveau ASI ET changement '
          "d'emplacements de sorts au même niveau, classe lanceuse)", (
        tester,
      ) async {
        fakeRepository.detailToReturn = _baseDetail.copyWith(
          classes: [
            const CharacterDetailClassRow(
              classId: 3,
              hitDie: 8,
              className: 'Clerc',
              level: 3,
              isPrimary: true,
              savingThrowProficiencies: [],
            ),
          ],
          xp: 0,
        );
        fakeRepository.levelDataByLevel = {
          4: const LevelUpLevelData(choiceType: null, automaticFeatures: []),
        };

        await pushLevelUp(tester, 4);

        expect(
          find.text('Un choix de Amélioration ou don vous attendra'),
          findsOneWidget,
        );
        expect(
          find.text('Vos emplacements de sorts vont évoluer'),
          findsOneWidget,
        );
      });

      testWidgets('aucun teaser quand le niveau va en fait bloquer, même si '
          'spellSlotChanges est non vide (Clerc niveau 3, `choice_type` '
          'fictif non résolu — `sort_domaine`, valeur qui n\'existe pas '
          'vraiment en base, remplace l\'ancien exemple "Barde niveau 2" '
          'devenu obsolète depuis que ce chantier a levé le blocage des 4 '
          'classes "à sorts connus" — `spellSlotChanges` est calculé '
          'indépendamment du blocage, voir `level_up_provider.dart` : '
          "l'étape \"Sorts\" ne sera jamais atteinte cette session, l'annonce "
          'ne doit donc promettre aucune étape à venir)', (tester) async {
        fakeRepository.detailToReturn = _baseDetail.copyWith(
          classes: [
            const CharacterDetailClassRow(
              classId: 3,
              hitDie: 8,
              className: 'Clerc',
              level: 2,
              isPrimary: true,
              savingThrowProficiencies: [],
            ),
          ],
          xp: 0,
        );
        fakeRepository.levelDataByLevel = {
          3: const LevelUpLevelData(
            choiceType: 'sort_domaine',
            automaticFeatures: [],
          ),
        };

        await pushLevelUp(tester, 3);

        // L'annonce s'affiche (le joueur a bien atteint ce niveau), mais
        // sans aucun teaser d'étape à venir : le niveau 3 va bloquer juste
        // après (`choice_type` non résolu), l'étape "Sorts" ne sera jamais
        // atteinte cette session malgré `spellSlotChanges.isNotEmpty` (Clerc
        // niveau 2 -> 3 débloque bien le palier de sorts de niveau 2).
        expect(find.text('MONTÉE DE NIVEAU'), findsOneWidget);
        expect(find.text('NIVEAU 3'), findsOneWidget);
        expect(find.text('À venir dans les prochaines étapes'), findsNothing);
        expect(
          find.text('Vos emplacements de sorts vont évoluer'),
          findsNothing,
        );
        expect(find.textContaining('Un choix de'), findsNothing);
      });
    });

    testWidgets(
      'chaînage multi-niveaux : une nouvelle annonce, avec son propre '
      'contenu, est réaffichée pour chaque niveau (pas seulement au '
      'premier)',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail.copyWith(xp: 14000);
        fakeRepository.applyResultToReturn = const LevelUpApplyResult(
          newLevel: 5,
          newMaxHp: 36,
          newCurrentHp: 32,
        );
        fakeRepository.levelDataByLevel = {
          5: const LevelUpLevelData(
            choiceType: null,
            automaticFeatures: [
              CharacterClassFeature(
                id: 10,
                name: 'Attaque supplémentaire',
                level: 5,
              ),
            ],
          ),
          6: const LevelUpLevelData(
            choiceType: null,
            automaticFeatures: [
              CharacterClassFeature(
                id: 11,
                name: 'Aptitude niveau 6',
                level: 6,
              ),
            ],
          ),
        };

        await pushLevelUp(tester, 5);
        // Annonce du niveau 5 : son propre contenu.
        expect(find.text('NIVEAU 5'), findsOneWidget);
        expect(find.text('Attaque supplémentaire'), findsOneWidget);

        await tester.tap(find.text('CONTINUER')); // annonce -> Points de vie
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER')); // Points de vie -> Aptitudes
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER')); // Aptitudes -> Récapitulatif
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER')); // applique, enchaîne
        await tester.pumpAndSettle();

        // Nouvelle annonce pour le niveau 6, avec son propre contenu — pas
        // un résidu de celle du niveau 5.
        expect(find.text('NIVEAU 6'), findsOneWidget);
        expect(find.text('Aptitude niveau 6'), findsOneWidget);
        expect(find.text('Attaque supplémentaire'), findsNothing);
      },
    );
  });

  group('étape "Choix à faire" (increment 2)', () {
    /// Navigue jusqu'à l'étape "Choix à faire" en franchissant les étapes
    /// "Points de vie"/"Aptitudes" avec leurs valeurs par défaut.
    Future<void> pushToChoiceStep(WidgetTester tester, int level) async {
      await pushPastAnnouncement(tester, level);
      await tester.tap(find.text('CONTINUER'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONTINUER'));
      await tester.pumpAndSettle();
    }

    group('variante amélioration de caractéristique (ASI)', () {
      setUp(() {
        fakeRepository.detailToReturn = _baseDetailAtLevel(7);
        fakeRepository.levelDataByLevel = {
          8: const LevelUpLevelData(choiceType: null, automaticFeatures: []),
        };
      });

      testWidgets('totalSteps passe à 4, étape affichée avec instruction et '
          'compteur de points restants', (tester) async {
        await pushPastAnnouncement(tester, 8);
        expect(find.text('Étape 1 sur 4 · Points de vie'), findsOneWidget);

        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();
        expect(
          find.text('Étape 2 sur 4 · Aptitudes de classe'),
          findsOneWidget,
        );

        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        expect(
          find.text('Étape 3 sur 4 · Amélioration ou don'),
          findsOneWidget,
        );
        expect(
          find.text('Répartissez 2 points entre vos caractéristiques.'),
          findsOneWidget,
        );
        expect(find.text('Points restants : 2/2'), findsOneWidget);
      });

      testWidgets(
        '"Continuer" désactivé tant que le budget n\'est pas entièrement '
        'dépensé, activé une fois les 2 points répartis sur une seule '
        'caractéristique (+2)',
        (tester) async {
          await pushToChoiceStep(tester, 8);

          // "Continuer" désactivé initialement (0/2 dépensé) : tap sans
          // effet, toujours sur l'étape "Choix à faire".
          await tester.tap(find.text('CONTINUER'), warnIfMissed: false);
          await tester.pumpAndSettle();
          expect(
            find.text('Étape 3 sur 4 · Amélioration ou don'),
            findsOneWidget,
          );

          // Icônes "+" dans l'ordre canonique For/Dex/Con/Int/Sag/Cha : la
          // 1ʳᵉ est celle de Force.
          await tester.tap(find.byIcon(Icons.add).first);
          await tester.pumpAndSettle();
          expect(find.text('Points restants : 1/2'), findsOneWidget);

          await tester.tap(find.byIcon(Icons.add).first);
          await tester.pumpAndSettle();
          expect(find.text('Tous les points sont répartis.'), findsOneWidget);
          expect(find.textContaining('Points restants :'), findsNothing);

          await tester.tap(find.text('CONTINUER'));
          await tester.pumpAndSettle();

          // Récapitulatif : une seule caractéristique augmentée de 2.
          expect(find.text('Amélioration de caractéristique'), findsOneWidget);
          expect(find.text('Force +2'), findsOneWidget);

          await tester.tap(find.text('CONTINUER'));
          await tester.pumpAndSettle();

          final choice = fakeRepository.applyLevelUpCalls.single.choice!;
          expect(choice.kind, LevelUpChoiceKind.abilityScoreImprovement);
          expect(choice.abilityAllocations, {'str': 2});
        },
      );

      testWidgets(
        'répartition +1/+1 sur deux caractéristiques : le récapitulatif '
        'respecte l\'ordre canonique For/Dex/Con/Int/Sag/Cha, pas l\'ordre '
        'de saisie (ici Dextérité tapée avant Force)',
        (tester) async {
          await pushToChoiceStep(tester, 8);

          // Dextérité (2ᵉ icône "+") avant Force (1ʳᵉ icône "+").
          await tester.tap(find.byIcon(Icons.add).at(1));
          await tester.pumpAndSettle();
          await tester.tap(find.byIcon(Icons.add).first);
          await tester.pumpAndSettle();

          expect(find.text('Tous les points sont répartis.'), findsOneWidget);

          await tester.tap(find.text('CONTINUER'));
          await tester.pumpAndSettle();

          expect(find.text('Force +1, Dextérité +1'), findsOneWidget);

          await tester.tap(find.text('CONTINUER'));
          await tester.pumpAndSettle();

          final choice = fakeRepository.applyLevelUpCalls.single.choice!;
          expect(choice.abilityAllocations, {'str': 1, 'dex': 1});
        },
      );

      testWidgets('"Retour" de l\'étape "Choix à faire" ramène à l\'étape '
          '"Aptitudes"', (tester) async {
        await pushToChoiceStep(tester, 8);

        await tester.tap(find.text('RETOUR'));
        await tester.pumpAndSettle();

        expect(
          find.text('Étape 2 sur 4 · Aptitudes de classe'),
          findsOneWidget,
        );
      });

      testWidgets(
        'plafond de score à 20 : une caractéristique à 19 permet +1 mais ne '
        'permet pas un second +1 sur la même caractéristique une fois à 20, '
        'même s\'il reste du budget — docs/cahier-des-charges '
        '04-fonctionnalites-app-mobile.md section 6 point 3.',
        (tester) async {
          fakeRepository.detailToReturn = _baseDetailAtLevel(7)
              .copyWith(abilityScores: {'str': 19, 'con': 14});

          await pushToChoiceStep(tester, 8);

          // 1er "+" sur Force (19 -> 20) : autorisé, budget 1/2 restant.
          await tester.tap(find.byIcon(Icons.add).first);
          await tester.pumpAndSettle();
          expect(find.text('19 → 20 (+1)'), findsOneWidget);
          expect(find.text('Points restants : 1/2'), findsOneWidget);

          // 2e "+" sur Force (déjà à 20) : doit être refusé malgré le
          // budget restant — ne doit PAS afficher "19 → 21 (+2)".
          await tester.tap(find.byIcon(Icons.add).first, warnIfMissed: false);
          await tester.pumpAndSettle();
          expect(find.text('19 → 21 (+2)'), findsNothing);
          expect(find.text('19 → 20 (+1)'), findsOneWidget);
          expect(find.text('Points restants : 1/2'), findsOneWidget);
        },
      );

      testWidgets(
        'plafond de score à 20 : une caractéristique déjà à 20 ne peut plus '
        'être incrémentée du tout, même si le budget est entièrement '
        'disponible.',
        (tester) async {
          fakeRepository.detailToReturn = _baseDetailAtLevel(7)
              .copyWith(abilityScores: {'wis': 20, 'con': 14});

          await pushToChoiceStep(tester, 8);

          // Sagesse (4e "+" dans l'ordre canonique For/Dex/Con/Int/Sag/Cha)
          // est déjà à 20 : le tap ne doit rien changer. `ensureVisible`
          // d'abord : cette ligne est sous le fold de la
          // SingleChildScrollView, un tap direct serait silencieusement
          // ignoré (hors zone de hit-test) et ne prouverait rien.
          final wisIncrement = find.byIcon(Icons.add).at(4);
          await tester.ensureVisible(wisIncrement);
          await tester.pumpAndSettle();
          await tester.tap(wisIncrement, warnIfMissed: false);
          await tester.pumpAndSettle();
          expect(find.text('20 → 21 (+1)'), findsNothing);
          expect(find.text('Points restants : 2/2'), findsOneWidget);
        },
      );
    });

    group('variante sous-classe', () {
      setUp(() {
        fakeRepository.detailToReturn = _baseDetailAtLevel(2);
        fakeRepository.levelDataByLevel = {
          3: const LevelUpLevelData(
            choiceType: 'sous_classe',
            automaticFeatures: [],
            availableSubclasses: [
              LevelUpSubclassOption(
                id: 5,
                name: 'Champion',
                description: 'Un archétype simple et redoutable.',
              ),
              LevelUpSubclassOption(id: 8, name: 'Chevalier occulte'),
            ],
          ),
        };
      });

      testWidgets('liste les sous-classes avec description en sous-titre quand '
          'renseignée, sélection exclusive, récapitulatif et applyLevelUp '
          'corrects', (tester) async {
        await pushToChoiceStep(tester, 3);

        expect(find.text('Étape 3 sur 4 · Sous-classe'), findsOneWidget);
        expect(find.text('Choisissez une sous-classe.'), findsOneWidget);
        expect(find.text('Champion'), findsOneWidget);
        expect(find.text('Un archétype simple et redoutable.'), findsOneWidget);
        expect(find.text('Chevalier occulte'), findsOneWidget);

        // "Continuer" désactivé tant qu'aucune sous-classe n'est choisie.
        await tester.tap(find.text('CONTINUER'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text('Étape 3 sur 4 · Sous-classe'), findsOneWidget);

        await tester.tap(find.text('Champion'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        expect(find.text('Sous-classe'), findsOneWidget);
        expect(find.text('Champion'), findsOneWidget);

        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        final choice = fakeRepository.applyLevelUpCalls.single.choice!;
        expect(choice.kind, LevelUpChoiceKind.subclass);
        expect(choice.subclassId, 5);
      });
    });

    group('variante style de combat', () {
      setUp(() {
        fakeRepository.detailToReturn = _baseDetailAtLevel(1);
        fakeRepository.levelDataByLevel = {
          2: const LevelUpLevelData(
            choiceType: 'style_combat',
            choiceClassFeatureId: 42,
            automaticFeatures: [],
          ),
        };
      });

      testWidgets(
        'liste les 6 options standard, sans sous-titre, récapitulatif et '
        'applyLevelUp corrects (character_class_options)',
        (tester) async {
          await pushToChoiceStep(tester, 2);

          expect(find.text('Étape 3 sur 4 · Style de combat'), findsOneWidget);
          expect(find.text('Choisissez un style de combat.'), findsOneWidget);
          for (final style in [
            'Archerie',
            'Défense',
            'Duel',
            'Combat à deux armes',
            'Combat à deux mains',
            'Protection',
          ]) {
            expect(find.text(style), findsOneWidget);
          }

          await tester.tap(find.text('Duel'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('CONTINUER'));
          await tester.pumpAndSettle();

          expect(find.text('Style de combat'), findsOneWidget);
          expect(find.text('Duel'), findsOneWidget);

          await tester.tap(find.text('CONTINUER'));
          await tester.pumpAndSettle();

          final choice = fakeRepository.applyLevelUpCalls.single.choice!;
          expect(choice.kind, LevelUpChoiceKind.fightingStyle);
          expect(choice.classFeatureId, 42);
          expect(choice.chosenValue, 'Duel');
        },
      );
    });

    group('variante ennemi juré', () {
      setUp(() {
        fakeRepository.detailToReturn = _baseDetailAtLevel(5);
        fakeRepository.levelDataByLevel = {
          6: const LevelUpLevelData(
            choiceType: 'ennemi_jure',
            choiceClassFeatureId: 77,
            automaticFeatures: [],
          ),
        };
      });

      testWidgets(
        'liste les 12 types de créatures, récapitulatif et applyLevelUp '
        'corrects',
        (tester) async {
          await pushToChoiceStep(tester, 6);

          expect(find.text('Étape 3 sur 4 · Ennemi juré'), findsOneWidget);
          expect(find.text('Choisissez un ennemi juré.'), findsOneWidget);
          expect(find.text('Morts-vivants'), findsOneWidget);

          // 12 options : "Dragons" (5ᵉ) peut être hors du viewport initial
          // du `SingleChildScrollView` sur la taille d'écran de test —
          // `ensureVisible` le fait défiler avant le tap.
          await tester.ensureVisible(find.text('Dragons'));
          await tester.tap(find.text('Dragons'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('CONTINUER'));
          await tester.pumpAndSettle();

          expect(find.text('Ennemi juré'), findsOneWidget);
          expect(find.text('Dragons'), findsOneWidget);

          await tester.tap(find.text('CONTINUER'));
          await tester.pumpAndSettle();

          final choice = fakeRepository.applyLevelUpCalls.single.choice!;
          expect(choice.kind, LevelUpChoiceKind.favoredEnemy);
          expect(choice.classFeatureId, 77);
          expect(choice.chosenValue, 'Dragons');
        },
      );
    });

    testWidgets(
      'état vide (cas défensif, 0 sous-classe disponible) : message dédié, '
      '"Continuer" durablement désactivé',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetailAtLevel(2);
        fakeRepository.levelDataByLevel = {
          3: const LevelUpLevelData(
            choiceType: 'sous_classe',
            automaticFeatures: [],
          ),
        };

        await pushToChoiceStep(tester, 3);

        expect(
          find.text('Aucune option disponible pour ce choix.'),
          findsOneWidget,
        );

        await tester.tap(find.text('CONTINUER'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text('Étape 3 sur 4 · Sous-classe'), findsOneWidget);
      },
    );

    testWidgets(
      'chaînage : deux étapes "Choix à faire" de variante liste consécutives '
      '(style de combat niveau 5 puis ennemi juré niveau 6) — la sélection '
      "de la 1ère étape ne fuite pas dans la 2e (_resetChoiceState)",
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail.copyWith(xp: 14000);
        fakeRepository.levelDataByLevel = {
          5: const LevelUpLevelData(
            choiceType: 'style_combat',
            choiceClassFeatureId: 50,
            automaticFeatures: [],
          ),
          6: const LevelUpLevelData(
            choiceType: 'ennemi_jure',
            choiceClassFeatureId: 60,
            automaticFeatures: [],
          ),
        };
        fakeRepository.applyResultToReturn = const LevelUpApplyResult(
          newLevel: 5,
          newMaxHp: 36,
          newCurrentHp: 32,
        );

        await pushToChoiceStep(tester, 5);
        await tester.tap(find.text('Duel'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();
        expect(find.text('Duel'), findsOneWidget);
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        // Chaînage direct vers le niveau 6 : une nouvelle annonce d'abord
        // (increment 4), puis repasse par "Points de vie"/"Aptitudes" avant
        // de ré-atteindre l'étape "Choix à faire", cette fois pour
        // "ennemi_jure".
        expect(find.text('NIVEAU 6'), findsOneWidget);
        await tester.tap(find.text('CONTINUER')); // annonce -> Points de vie
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        expect(find.text('Étape 3 sur 4 · Ennemi juré'), findsOneWidget);
        // Aucune tuile "Duel" sur cette étape (liste d'ennemis jurés) : si
        // `_selectedListOptionId` n'avait pas été remis à `null`, il
        // contiendrait toujours la chaîne 'Duel' — sans effet visible ici
        // faute de tuile correspondante, d'où la vérification directe du
        // bouton "Continuer" ci-dessous, qui doit rester désactivé tant
        // qu'aucun ennemi juré n'a été sélectionné pour CE niveau.
        expect(find.text('Duel'), findsNothing);
        await tester.tap(find.text('CONTINUER'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text('Étape 3 sur 4 · Ennemi juré'), findsOneWidget);

        await tester.ensureVisible(find.text('Dragons'));
        await tester.tap(find.text('Dragons'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        // Récapitulatif du niveau 6 : "Dragons" (ennemi juré fraîchement
        // choisi), jamais "Duel" (résidu du style de combat du niveau 5).
        expect(find.text('Ennemi juré'), findsOneWidget);
        expect(find.text('Dragons'), findsOneWidget);
        expect(find.text('Duel'), findsNothing);

        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        expect(fakeRepository.applyLevelUpCalls, hasLength(2));
        final secondChoice = fakeRepository.applyLevelUpCalls[1].choice!;
        expect(secondChoice.kind, LevelUpChoiceKind.favoredEnemy);
        expect(secondChoice.chosenValue, 'Dragons');
      },
    );

    testWidgets(
      'chaînage : deux étapes ASI consécutives (niveau 4 puis niveau 8, '
      "chaînage forcé via applyResultToReturn) — l'allocation repart de "
      "zéro pour le 2e niveau (_resetChoiceState)",
      (tester) async {
        fakeRepository.detailToReturn = _baseDetailAtLevel(3)
            .copyWith(xp: 34000);
        fakeRepository.levelDataByLevel = {
          4: const LevelUpLevelData(choiceType: null, automaticFeatures: []),
          8: const LevelUpLevelData(choiceType: null, automaticFeatures: []),
        };
        fakeRepository.applyResultToReturn = const LevelUpApplyResult(
          newLevel: 7,
          newMaxHp: 40,
          newCurrentHp: 36,
        );

        await pushToChoiceStep(tester, 4);
        await tester.tap(find.byIcon(Icons.add).first);
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.add).first);
        await tester.pumpAndSettle();
        expect(find.text('Tous les points sont répartis.'), findsOneWidget);
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();
        expect(find.text('Force +2'), findsOneWidget);
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        // Chaînage forcé vers le niveau 8 (résultat truqué newLevel: 7,
        // xp 34000 déverrouille déjà le niveau 8) : une nouvelle annonce
        // d'abord (increment 4), avant de repasser par "Points de
        // vie"/"Aptitudes".
        expect(find.text('NIVEAU 8'), findsOneWidget);
        await tester.tap(find.text('CONTINUER')); // annonce -> Points de vie
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        // Budget repart à 2/2, aucune caractéristique déjà augmentée : si
        // `_abilityAllocations` n'avait pas été remis à `null`, le budget
        // du niveau 4 (déjà entièrement dépensé) resterait épuisé ici.
        expect(
          find.text('Étape 3 sur 4 · Amélioration ou don'),
          findsOneWidget,
        );
        expect(find.text('Points restants : 2/2'), findsOneWidget);
        expect(find.text('10 → 12 (+2)'), findsNothing);

        await tester.tap(find.byIcon(Icons.add).at(1));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.add).at(1));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        // Récapitulatif du niveau 8 : "Dextérité +2" uniquement, jamais de
        // "Force +2" résiduel du niveau 4.
        expect(find.text('Dextérité +2'), findsOneWidget);
        expect(find.text('Force +2'), findsNothing);
      },
    );
  });

  group('étape "Sorts" (increment 3)', () {
    /// Classe primaire "Clerc" (lanceur complet "préparé", jamais bloqué par
    /// `LevelUpBlockRules` quel que soit le niveau — voir
    /// `domain/level_up_block_reason.dart`) au niveau [level].
    CharacterDetailClassRow clercClass({required int level}) =>
        CharacterDetailClassRow(
          classId: 3,
          hitDie: 8,
          className: 'Clerc',
          level: level,
          isPrimary: true,
          savingThrowProficiencies: [],
        );

    testWidgets(
      '1 ligne (niveau 5, palier 3 débloqué) : étape numérotée 3 sur 4 '
      "(pas d'étape \"Choix à faire\" à ce niveau), wording \"Nouveaux "
      'emplacements de sorts", "Retour" ramène à "Aptitudes"',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail.copyWith(
          classes: [clercClass(level: 4)],
          xp: 0,
        );
        fakeRepository.levelDataByLevel = {
          5: const LevelUpLevelData(choiceType: null, automaticFeatures: []),
        };
        fakeRepository.applyResultToReturn = const LevelUpApplyResult(
          newLevel: 5,
          newMaxHp: 30,
          newCurrentHp: 26,
        );

        await pushPastAnnouncement(tester, 5);
        expect(find.text('Étape 1 sur 4 · Points de vie'), findsOneWidget);

        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();
        expect(
          find.text('Étape 2 sur 4 · Aptitudes de classe'),
          findsOneWidget,
        );

        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        expect(
          find.text('Étape 3 sur 4 · Emplacements de sorts'),
          findsOneWidget,
        );
        expect(
          find.text('Vos emplacements de sorts sont recalculés :'),
          findsOneWidget,
        );
        expect(find.text('Nouveaux emplacements de sorts'), findsOneWidget);
        expect(find.text('Niveau 3 débloqué'), findsOneWidget);

        // "Retour" : aucune étape "Choix à faire" à ce niveau -> "Aptitudes".
        await tester.tap(find.text('RETOUR'));
        await tester.pumpAndSettle();
        expect(
          find.text('Étape 2 sur 4 · Aptitudes de classe'),
          findsOneWidget,
        );
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        // "Continuer" toujours actif (pur recalcul automatique) -> mène au
        // récapitulatif, qui reprend le même bloc "Sorts".
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();
        expect(find.text('Étape 3 sur 4'), findsNothing);
        expect(find.text('Nouveaux emplacements de sorts'), findsOneWidget);
        expect(find.text('Niveau 3 débloqué'), findsOneWidget);

        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        expect(fakeRepository.applyLevelUpCalls, hasLength(1));
        expect(fakeRepository.applyLevelUpCalls.single.className, 'Clerc');
      },
    );

    testWidgets(
      '2 lignes (niveau 3) : palier 1 renforcé ET palier 2 débloqué dans la '
      'même étape, triées par niveau de sort croissant',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail.copyWith(
          classes: [clercClass(level: 2)],
          xp: 0,
        );
        fakeRepository.levelDataByLevel = {
          3: const LevelUpLevelData(choiceType: null, automaticFeatures: []),
        };

        await pushPastAnnouncement(tester, 3);
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        expect(
          find.text('Étape 3 sur 4 · Emplacements de sorts'),
          findsOneWidget,
        );
        expect(find.text('Emplacements de sorts renforcés'), findsOneWidget);
        expect(find.text('Niveau 1 : 3 → 4 (+1)'), findsOneWidget);
        expect(find.text('Nouveaux emplacements de sorts'), findsOneWidget);
        expect(find.text('Niveau 2 débloqué'), findsOneWidget);
      },
    );

    testWidgets(
      'étape absente pour une classe non lanceuse (Guerrier, scénario par '
      'défaut de ce fichier) : totalSteps reste 3',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail;
        fakeRepository.levelDataByLevel = {
          5: const LevelUpLevelData(choiceType: null, automaticFeatures: []),
        };

        await pushPastAnnouncement(tester, 5);
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        // Directement le récapitulatif (pas d'étape "Sorts" ni "Choix à
        // faire" à ce niveau) : aucun bloc "Sorts" affiché.
        expect(find.textContaining('Étape'), findsNothing);
        expect(find.text('Nouveaux emplacements de sorts'), findsNothing);
        expect(find.text('Emplacements de sorts renforcés'), findsNothing);
      },
    );

    testWidgets(
      'étape absente quand le recalcul ne change rien à ce niveau (niveau '
      '14, palier identique au niveau 13) même pour une classe lanceuse : '
      'saut direct au récapitulatif, cas défensif de la spec visuelle',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail.copyWith(
          classes: [clercClass(level: 13)],
          xp: 0,
        );
        fakeRepository.levelDataByLevel = {
          14: const LevelUpLevelData(choiceType: null, automaticFeatures: []),
        };

        await pushPastAnnouncement(tester, 14);
        // Niveau 14 : ni ASI (4/8/12/16/19), ni choice_type -> pas d'étape
        // "Choix à faire" non plus. totalSteps == 3 confirme qu'aucune étape
        // "Sorts" n'est comptée (sinon 4).
        expect(find.text('Étape 1 sur 3 · Points de vie'), findsOneWidget);

        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        // Directement le récapitulatif.
        expect(find.text('Étape 1 sur 3'), findsNothing);
        expect(find.text('Nouveaux emplacements de sorts'), findsNothing);
        expect(find.text('Emplacements de sorts renforcés'), findsNothing);
      },
    );

    testWidgets(
      'totalSteps == 5 quand "Choix à faire" (ASI) ET "Sorts" sont toutes '
      'les deux déclenchées au même niveau (niveau 4, Clerc) : numérotation '
      '3/5 puis 4/5, "Retour" de "Sorts" ramène à "Choix à faire", '
      'récapitulatif dans l\'ordre PV -> Aptitudes -> Choix -> Sorts',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail.copyWith(
          classes: [clercClass(level: 3)],
          xp: 0,
        );
        // Niveau 4 : niveau ASI standard, sans choice_type déclaré ici — le
        // choix ASI est résolu indépendamment de `class_features`, voir
        // `LevelUpBlockRules.abilityScoreImprovementLevels`.
        fakeRepository.levelDataByLevel = {
          4: const LevelUpLevelData(choiceType: null, automaticFeatures: []),
        };
        fakeRepository.applyResultToReturn = const LevelUpApplyResult(
          newLevel: 4,
          newMaxHp: 30,
          newCurrentHp: 26,
        );

        await pushPastAnnouncement(tester, 4);
        expect(find.text('Étape 1 sur 5 · Points de vie'), findsOneWidget);

        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();
        expect(
          find.text('Étape 2 sur 5 · Aptitudes de classe'),
          findsOneWidget,
        );

        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();
        expect(
          find.text('Étape 3 sur 5 · Amélioration ou don'),
          findsOneWidget,
        );

        // Répartit le budget ASI (+1 Force, 1ʳᵉ icône "+") pour activer
        // "Continuer".
        await tester.tap(find.byIcon(Icons.add).first);
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.add).first);
        await tester.pumpAndSettle();

        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        expect(
          find.text('Étape 4 sur 5 · Emplacements de sorts'),
          findsOneWidget,
        );
        expect(find.text('Emplacements de sorts renforcés'), findsOneWidget);
        expect(find.text('Niveau 2 : 2 → 3 (+1)'), findsOneWidget);

        // "Retour" de l'étape "Sorts" : ramène à "Choix à faire" (présente à
        // ce niveau), jamais directement à "Aptitudes".
        await tester.tap(find.text('RETOUR'));
        await tester.pumpAndSettle();
        expect(
          find.text('Étape 3 sur 5 · Amélioration ou don'),
          findsOneWidget,
        );
        expect(find.text('Tous les points sont répartis.'), findsOneWidget);

        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        // Récapitulatif : ordre PV -> Aptitudes -> Choix -> Sorts.
        expect(find.text('Points de vie maximum'), findsOneWidget);
        expect(find.text('Amélioration de caractéristique'), findsOneWidget);
        expect(find.text('Force +2'), findsOneWidget);
        expect(find.text('Emplacements de sorts renforcés'), findsOneWidget);
        expect(find.text('Niveau 2 : 2 → 3 (+1)'), findsOneWidget);

        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        final applied = fakeRepository.applyLevelUpCalls.single;
        expect(applied.className, 'Clerc');
        expect(applied.choice!.kind, LevelUpChoiceKind.abilityScoreImprovement);
      },
    );
  });

  group('étape classDecision (multiclassage)', () {
    testWidgets(
      'invisible (saut direct à l\'annonce) quand aucune classe n\'est '
      'éligible au multiclassage (catalogue vide, comportement par défaut '
      'de tous les autres tests de ce fichier)',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail.copyWith(
          abilityScores: {'str': 18, 'con': 14},
        );
        fakeRepository.levelDataByLevel = {
          5: const LevelUpLevelData(choiceType: null, automaticFeatures: []),
        };
        // Catalogue vide (défaut de `_FakeCharacterCreationRepository`) :
        // même avec Force 18 (Guerrier remplit son propre prérequis), aucune
        // classe candidate ne peut jamais être proposée.

        await pushLevelUp(tester, 5);

        expect(
          find.text(classDecisionInstruction),
          findsNothing,
          reason:
              'pushLevelUp aurait déjà tapé "Continuer" si cette étape '
              "s'était affichée, mais on vérifie explicitement qu'elle "
              "n'apparaît jamais.",
        );
        expect(find.text('MONTÉE DE NIVEAU'), findsOneWidget);
      },
    );

    testWidgets(
      'une classe éligible : tuiles "Continuer"/"Se multiclasser" affichées, '
      '"Continuer" présélectionné par défaut',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail.copyWith(
          abilityScores: {'str': 15, 'con': 14},
        );
        fakeCreationRepository.classCatalogToReturn = const ClassCatalog(
          classes: [
            ClassOption(id: 1, name: 'Guerrier', description: '', hitDie: 10),
            ClassOption(id: 2, name: 'Barbare', description: '', hitDie: 12),
          ],
        );
        fakeRepository.levelDataByLevel = {
          5: const LevelUpLevelData(choiceType: null, automaticFeatures: []),
          1: const LevelUpLevelData(choiceType: null, automaticFeatures: []),
        };

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();
        router.push('/characters/char-1/level-up?level=5');
        await tester.pumpAndSettle();

        expect(find.text(classDecisionInstruction), findsOneWidget);
        expect(find.text('Continuer en Guerrier'), findsOneWidget);
        expect(
          find.text('Vous progressez dans votre voie actuelle (niveau 4 → 5).'),
          findsOneWidget,
        );
        expect(find.text('Se multiclasser en Barbare'), findsOneWidget);
        expect(
          find.text(
            'Vous débutez au niveau 1 dans cette classe. Prérequis rempli : '
            'Force.',
          ),
          findsOneWidget,
        );
        // Pas de `stepLabel` ("Étape X sur N") sur cette phase.
        expect(find.textContaining('Étape'), findsNothing);

        // "Continuer" présélectionné : valider directement mène à l'annonce
        // (comportement historique, classe primaire).
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();
        expect(find.text('NIVEAU 5'), findsOneWidget);
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();
        expect(find.text('Dé de vie de la classe : d10'), findsOneWidget);
      },
    );

    testWidgets(
      'plusieurs classes éligibles : une tuile par classe candidate',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail.copyWith(
          abilityScores: {'str': 15, 'dex': 15, 'con': 14},
        );
        fakeCreationRepository.classCatalogToReturn = const ClassCatalog(
          classes: [
            ClassOption(id: 1, name: 'Guerrier', description: '', hitDie: 10),
            ClassOption(id: 2, name: 'Barbare', description: '', hitDie: 12),
            ClassOption(id: 6, name: 'Roublard', description: '', hitDie: 8),
          ],
        );
        fakeRepository.levelDataByLevel = {
          5: const LevelUpLevelData(choiceType: null, automaticFeatures: []),
        };

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();
        router.push('/characters/char-1/level-up?level=5');
        await tester.pumpAndSettle();

        expect(find.text('Se multiclasser en Barbare'), findsOneWidget);
        expect(find.text('Se multiclasser en Roublard'), findsOneWidget);
      },
    );

    testWidgets(
      'sélectionner "Se multiclasser" adapte les étapes PV/Aptitudes à la '
      'nouvelle classe (dé de vie, bandeau de contexte, maîtrises de '
      'multiclassage) et applyLevelUp reçoit classId/isMulticlassing '
      'corrects',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail.copyWith(
          abilityScores: {'str': 15, 'con': 14},
        );
        fakeCreationRepository.classCatalogToReturn = const ClassCatalog(
          classes: [
            ClassOption(id: 1, name: 'Guerrier', description: '', hitDie: 10),
            ClassOption(id: 2, name: 'Barbare', description: '', hitDie: 12),
          ],
        );
        fakeRepository.levelDataByLevel = {
          1: const LevelUpLevelData(choiceType: null, automaticFeatures: []),
        };
        fakeRepository.applyResultToReturn = const LevelUpApplyResult(
          newLevel: 5,
          newMaxHp: 34,
          newCurrentHp: 30,
        );

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();
        router.push('/characters/char-1/level-up?level=5');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Se multiclasser en Barbare'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER')); // classDecision -> annonce
        await tester.pumpAndSettle();

        await tester.tap(find.text('CONTINUER')); // annonce -> Points de vie
        await tester.pumpAndSettle();

        expect(find.text('Étape 1 sur 3 · Points de vie'), findsOneWidget);
        expect(
          find.text('Dé de vie de Barbare (niveau 1) : d12'),
          findsOneWidget,
        );
        expect(
          find.text('Nouvelle classe : Barbare (niveau 1)'),
          findsOneWidget,
        );

        await tester.tap(find.text('CONTINUER')); // Points de vie -> Aptitudes
        await tester.pumpAndSettle();

        expect(
          find.text('Étape 2 sur 3 · Aptitudes & maîtrises'),
          findsOneWidget,
        );
        expect(find.text('Maîtrises de multiclassage :'), findsOneWidget);
        expect(find.text('Nouvelle maîtrise'), findsWidgets);
        expect(find.text('Maîtrise des boucliers'), findsOneWidget);
        expect(
          find.text('Maîtrise des armes courantes et de guerre'),
          findsOneWidget,
        );

        await tester.tap(find.text('CONTINUER')); // Aptitudes -> Récapitulatif
        await tester.pumpAndSettle();
        expect(
          find.text('Nouvelle classe : Barbare (niveau 1)'),
          findsOneWidget,
        );

        await tester.tap(find.text('CONTINUER')); // applique
        await tester.pumpAndSettle();

        final applied = fakeRepository.applyLevelUpCalls.single;
        expect(applied.classId, 2);
        expect(applied.className, 'Barbare');
        expect(applied.isMulticlassing, isTrue);
      },
    );

    testWidgets(
      'écran de blocage en branche multiclasse : le niveau interpolé est '
      'celui DANS la nouvelle classe (1), jamais le niveau total du '
      'personnage',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail.copyWith(
          abilityScores: {'str': 15, 'wis': 15, 'con': 14},
        );
        fakeCreationRepository.classCatalogToReturn = const ClassCatalog(
          classes: [
            ClassOption(id: 1, name: 'Guerrier', description: '', hitDie: 10),
            ClassOption(id: 3, name: 'Clerc', description: '', hitDie: 8),
          ],
        );
        fakeRepository.levelDataByLevel = {
          1: const LevelUpLevelData(
            choiceType: 'sort_domaine',
            automaticFeatures: [],
          ),
        };

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();
        router.push('/characters/char-1/level-up?level=5');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Se multiclasser en Clerc'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER')); // classDecision -> annonce
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER')); // annonce -> blocage
        await tester.pumpAndSettle();

        expect(find.text('Niveau 1 : choix requis'), findsOneWidget);
        expect(find.text('Clerc niveau 1 : Sort de domaine'), findsOneWidget);
      },
    );

    testWidgets(
      'sélection de sorts de départ (multiclassage dans une classe "à sorts '
      'connus") : "Continuer" désactivé tant que les quotas ne sont pas '
      'atteints, applyLevelUp reçoit les identifiants de sorts choisis',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail.copyWith(
          abilityScores: {'str': 15, 'cha': 15, 'con': 14},
        );
        fakeCreationRepository.classCatalogToReturn = const ClassCatalog(
          classes: [
            ClassOption(id: 1, name: 'Guerrier', description: '', hitDie: 10),
            ClassOption(id: 5, name: 'Barde', description: '', hitDie: 8),
          ],
        );
        fakeCreationRepository.spellCatalogByClassId = {
          5: const SpellCatalog(
            spells: [
              SpellOption(
                id: 100,
                name: 'Lumières dansantes',
                level: 0,
                school: 'Évocation',
                castingTime: '1 action',
              ),
              SpellOption(
                id: 101,
                name: 'Prestidigitation',
                level: 0,
                school: 'Transmutation',
                castingTime: '1 action',
              ),
              SpellOption(
                id: 200,
                name: 'Charme-personne',
                level: 1,
                school: 'Enchantement',
                castingTime: '1 action',
              ),
              SpellOption(
                id: 201,
                name: 'Détection de la magie',
                level: 1,
                school: 'Divination',
                castingTime: '1 action',
              ),
              SpellOption(
                id: 202,
                name: 'Sommeil',
                level: 1,
                school: 'Enchantement',
                castingTime: '1 action',
              ),
              SpellOption(
                id: 203,
                name: 'Vague tonnante',
                level: 1,
                school: 'Évocation',
                castingTime: '1 action',
              ),
            ],
          ),
        };
        fakeRepository.levelDataByLevel = {
          1: const LevelUpLevelData(choiceType: null, automaticFeatures: []),
        };
        fakeRepository.applyResultToReturn = const LevelUpApplyResult(
          newLevel: 5,
          newMaxHp: 30,
          newCurrentHp: 26,
        );

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();
        router.push('/characters/char-1/level-up?level=5');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Se multiclasser en Barde'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER')); // classDecision -> annonce
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER')); // annonce -> Points de vie
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER')); // Points de vie -> Aptitudes
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER')); // Aptitudes -> Sorts
        await tester.pumpAndSettle();

        expect(find.text('Étape 3 sur 4 · Sorts'), findsOneWidget);
        expect(find.text('SORTS MINEURS CONNUS'), findsOneWidget);
        expect(find.text('0 / 2'), findsOneWidget);

        // "Continuer" désactivé initialement (aucun sort choisi).
        await tester.tap(find.text('CONTINUER'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text('Étape 3 sur 4 · Sorts'), findsOneWidget);

        await tester.tap(find.text('Lumières dansantes'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Prestidigitation'));
        await tester.pumpAndSettle();
        expect(find.text('2 / 2'), findsOneWidget);

        // Quota cantrips atteint, mais pas encore le quota niveau 1 : le
        // bouton reste désactivé.
        await tester.tap(find.text('CONTINUER'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text('Étape 3 sur 4 · Sorts'), findsOneWidget);

        await tester.tap(find.text('Sorts'));
        await tester.pumpAndSettle();
        for (final spell in [
          'Charme-personne',
          'Détection de la magie',
          'Sommeil',
          'Vague tonnante',
        ]) {
          await tester.ensureVisible(find.text(spell));
          await tester.pumpAndSettle();
          await tester.tap(find.text(spell));
          await tester.pumpAndSettle();
        }
        expect(find.text('4 / 4'), findsOneWidget);

        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER')); // applique
        await tester.pumpAndSettle();

        final applied = fakeRepository.applyLevelUpCalls.single;
        expect(applied.className, 'Barde');
        expect(applied.initialSpellIds.toSet(), {100, 101, 200, 201, 202, 203});
      },
    );

    testWidgets(
      'multiclassage en Rôdeur niveau 1 : PAS de sélection de sorts de '
      'départ (contrairement à Barde/Ensorceleur/Occultiste) — RAW 5e, le '
      'Rôdeur n\'a aucun sort/emplacement au niveau 1 (sa magie démarre au '
      'niveau 2), le quota de 2 de `SpellcastingRules.levelOneSpellQuotaFor` '
      "est une simplification propre à l'assistant de création qui ne "
      "s'applique pas ici : étape \"Sorts\" absente, totalSteps cohérent "
      'sans elle (3, comme pour une classe "préparée")',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail.copyWith(
          abilityScores: {'str': 15, 'dex': 15, 'wis': 15, 'con': 14},
        );
        fakeCreationRepository.classCatalogToReturn = const ClassCatalog(
          classes: [
            ClassOption(id: 1, name: 'Guerrier', description: '', hitDie: 10),
            ClassOption(id: 7, name: 'Rôdeur', description: '', hitDie: 10),
          ],
        );
        fakeRepository.levelDataByLevel = {
          1: const LevelUpLevelData(choiceType: null, automaticFeatures: []),
        };
        fakeRepository.applyResultToReturn = const LevelUpApplyResult(
          newLevel: 5,
          newMaxHp: 30,
          newCurrentHp: 26,
        );

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();
        router.push('/characters/char-1/level-up?level=5');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Se multiclasser en Rôdeur'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER')); // classDecision -> annonce
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER')); // annonce -> Points de vie
        await tester.pumpAndSettle();

        expect(find.text('Étape 1 sur 3 · Points de vie'), findsOneWidget);

        await tester.tap(find.text('CONTINUER')); // Points de vie -> Aptitudes
        await tester.pumpAndSettle();

        expect(
          find.text('Étape 2 sur 3 · Aptitudes & maîtrises'),
          findsOneWidget,
        );

        await tester.tap(
          find.text('CONTINUER'),
        ); // Aptitudes -> Récapitulatif (jamais "Sorts")
        await tester.pumpAndSettle();

        expect(find.textContaining('Sorts'), findsNothing);
        expect(
          find.text('Nouvelle classe : Rôdeur (niveau 1)'),
          findsOneWidget,
        );

        await tester.tap(find.text('CONTINUER')); // applique
        await tester.pumpAndSettle();

        final applied = fakeRepository.applyLevelUpCalls.single;
        expect(applied.className, 'Rôdeur');
        expect(applied.initialSpellIds, isEmpty);
      },
    );
  });

  group('étape classDecision : continuer une classe SECONDAIRE (personnage déjà '
      'multiclassé) — lève la limite "toujours la primaire, jamais la '
      'secondaire"', () {
    testWidgets(
      'personnage multiclassé (2 classes), catalogue de multiclassage vide '
      ': une tuile "Continuer" par classe possédée (primaire incluse), la '
      'primaire reste présélectionnée par défaut',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail.copyWith(
          classes: const [
            CharacterDetailClassRow(
              classId: 1,
              hitDie: 10,
              className: 'Guerrier',
              level: 4,
              isPrimary: true,
              savingThrowProficiencies: [],
            ),
            CharacterDetailClassRow(
              classId: 6,
              hitDie: 8,
              className: 'Roublard',
              level: 2,
              isPrimary: false,
              savingThrowProficiencies: [],
            ),
          ],
        );
        // Catalogue de classes vide (défaut de
        // `_FakeCharacterCreationRepository`) : aucune option de
        // multiclassage supplémentaire, seules les 2 tuiles "Continuer"
        // (une par classe déjà possédée) sont attendues.

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();
        router.push('/characters/char-1/level-up?level=7');
        await tester.pumpAndSettle();

        expect(find.text(classDecisionInstruction), findsOneWidget);
        expect(find.text('Continuer en Guerrier'), findsOneWidget);
        expect(
          find.text('Vous progressez dans votre voie actuelle (niveau 4 → 5).'),
          findsOneWidget,
        );
        expect(find.text('Continuer en Roublard'), findsOneWidget);
        expect(
          find.text('Vous progressez dans votre voie actuelle (niveau 2 → 3).'),
          findsOneWidget,
        );
        expect(find.textContaining('Se multiclasser'), findsNothing);

        // Aucune tuile secondaire tapée : "Continuer" reste présélectionné
        // sur la primaire (comportement historique, voir
        // `_ensureClassDecisionSelected` côté écran).
        await tester.tap(find.text('CONTINUER')); // classDecision -> annonce
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER')); // annonce -> Points de vie
        await tester.pumpAndSettle();

        expect(find.text('Dé de vie de la classe : d10'), findsOneWidget);
      },
    );

    testWidgets('choisir de continuer la classe secondaire fait progresser SON '
        'niveau (pas celui de la primaire) : dé de vie de la bonne classe à '
        "l'étape Points de vie, applyLevelUp reçoit le classId de la classe "
        'secondaire ET isMulticlassing=false (continuer n\'est pas '
        'multiclasser)', (tester) async {
      fakeRepository.detailToReturn = _baseDetail.copyWith(
        classes: const [
          CharacterDetailClassRow(
            classId: 1,
            hitDie: 10,
            className: 'Guerrier',
            level: 4,
            isPrimary: true,
            savingThrowProficiencies: [],
          ),
          CharacterDetailClassRow(
            classId: 6,
            hitDie: 8,
            className: 'Roublard',
            level: 2,
            isPrimary: false,
            savingThrowProficiencies: [],
          ),
        ],
      );
      fakeRepository.applyResultToReturn = const LevelUpApplyResult(
        newLevel: 7,
        newMaxHp: 40,
        newCurrentHp: 36,
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      router.push('/characters/char-1/level-up?level=7');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuer en Roublard'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONTINUER')); // classDecision -> annonce
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONTINUER')); // annonce -> Points de vie
      await tester.pumpAndSettle();

      // Dé de vie du Roublard (d8), jamais celui du Guerrier (d10) : la
      // classe réellement ciblée par `data` est bien la secondaire.
      expect(find.text('Dé de vie de la classe : d8'), findsOneWidget);
      // Pas de bandeau "Nouvelle classe" : continuer une classe déjà
      // possédée n'est pas un multiclassage (`isMulticlassing` reste
      // faux), contrairement à "Se multiclasser".
      expect(find.textContaining('Nouvelle classe'), findsNothing);

      await tester.tap(find.text('CONTINUER')); // Points de vie -> Aptitudes
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONTINUER')); // Aptitudes -> Récapitulatif
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONTINUER')); // applique
      await tester.pumpAndSettle();

      final applied = fakeRepository.applyLevelUpCalls.single;
      expect(applied.classId, 6);
      expect(applied.className, 'Roublard');
      expect(applied.isMulticlassing, isFalse);
    });

    testWidgets(
      '3 classes possédées : les 3 apparaissent comme options "Continuer"',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail.copyWith(
          classes: const [
            CharacterDetailClassRow(
              classId: 1,
              hitDie: 10,
              className: 'Guerrier',
              level: 3,
              isPrimary: true,
              savingThrowProficiencies: [],
            ),
            CharacterDetailClassRow(
              classId: 6,
              hitDie: 8,
              className: 'Roublard',
              level: 2,
              isPrimary: false,
              savingThrowProficiencies: [],
            ),
            CharacterDetailClassRow(
              classId: 4,
              hitDie: 6,
              className: 'Magicien',
              level: 1,
              isPrimary: false,
              savingThrowProficiencies: [],
            ),
          ],
        );

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();
        router.push('/characters/char-1/level-up?level=7');
        await tester.pumpAndSettle();

        expect(find.text('Continuer en Guerrier'), findsOneWidget);
        expect(find.text('Continuer en Roublard'), findsOneWidget);
        expect(find.text('Continuer en Magicien'), findsOneWidget);
      },
    );

    testWidgets(
      'classe secondaire choisie bloquée à SON niveau suivant : le message '
      'de blocage cite le niveau et le nom de la classe secondaire, jamais '
      'ceux de la primaire (même logique déjà établie pour la primaire, '
      'généralisée ici — voir `domain/level_up_block_reason.dart`)',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail.copyWith(
          classes: const [
            CharacterDetailClassRow(
              classId: 1,
              hitDie: 10,
              className: 'Guerrier',
              level: 4,
              isPrimary: true,
              savingThrowProficiencies: [],
            ),
            CharacterDetailClassRow(
              classId: 6,
              hitDie: 8,
              className: 'Roublard',
              level: 2,
              isPrimary: false,
              savingThrowProficiencies: [],
            ),
          ],
        );
        // Niveau 3 = niveau interne SUIVANT du Roublard (2 + 1) : un
        // `choice_type` non résolu à ce niveau doit bloquer en citant le
        // Roublard, jamais le Guerrier (qui resterait à son niveau 4 ce
        // tour-ci, la primaire n'étant pas la classe choisie).
        fakeRepository.levelDataByLevel = {
          3: const LevelUpLevelData(
            choiceType: 'sort_domaine',
            automaticFeatures: [],
          ),
        };

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();
        router.push('/characters/char-1/level-up?level=7');
        await tester.pumpAndSettle();

        await tester.tap(find.text('Continuer en Roublard'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER')); // classDecision -> annonce
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER')); // annonce -> blocage
        await tester.pumpAndSettle();

        expect(
          fakeRepository.fetchLevelUpLevelDataCalls,
          [5, 3],
          reason:
              "premier appel (5) : previsualisation par defaut de la primaire "
              "(Guerrier niveau 4 + 1) avant tout commit, pour le sous-titre "
              "'bloque' eventuel de sa tuile -- voir '_continueOptionTile' "
              "cote ecran. Second appel (3), apres avoir commis le Roublard : "
              "le niveau interne interroge doit alors etre celui DANS le "
              "Roublard (2 + 1 = 3), jamais un niveau du Guerrier.",
        );
        expect(find.text('Niveau 3 : choix requis'), findsOneWidget);
        expect(
          find.text('Roublard niveau 3 : Sort de domaine'),
          findsOneWidget,
        );
        expect(find.textContaining('Guerrier niveau'), findsNothing);
      },
    );
  });

  group('régression : continuer la classe primaire après un multiclassage', () {
    testWidgets(
      '"Continuer" sur la classe primaire interroge le vrai niveau interne '
      'suivant de la primaire (niveau actuel + 1), jamais le niveau TOTAL + 1 '
      'du personnage, dès qu\'une classe secondaire existe déjà — chemin de '
      'jeu normal après tout multiclassage, pas un cas limite',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail.copyWith(
          classes: const [
            CharacterDetailClassRow(
              classId: 1,
              hitDie: 10,
              className: 'Guerrier',
              level: 4,
              isPrimary: true,
              savingThrowProficiencies: [],
            ),
            CharacterDetailClassRow(
              classId: 6,
              hitDie: 8,
              className: 'Roublard',
              level: 1,
              isPrimary: false,
              savingThrowProficiencies: [],
            ),
          ],
          xp: 0,
        );
        // Niveau TOTAL du personnage = 4 (Guerrier) + 1 (Roublard) = 5 :
        // l'appelant réel (liste des personnages) passerait donc
        // `initialTargetLevel: 6` (total + 1) pour la prochaine montée de
        // niveau — alors que le vrai niveau suivant DANS la classe primaire
        // (Guerrier) est 5 (4 + 1), pas 6. Seul le niveau 5 doit être
        // interrogé/affiché pour la classe qui progresse réellement.
        fakeRepository.levelDataByLevel = {
          5: const LevelUpLevelData(
            choiceType: null,
            automaticFeatures: [
              CharacterClassFeature(
                id: 20,
                name: 'Vrai niveau 5 (Guerrier)',
                level: 5,
              ),
            ],
          ),
          6: const LevelUpLevelData(
            choiceType: null,
            automaticFeatures: [
              CharacterClassFeature(
                id: 21,
                name: 'Faux niveau 6 (bug)',
                level: 6,
              ),
            ],
          ),
        };

        await pushLevelUp(tester, 6);

        // Catalogue de classes vide (défaut) : aucune option de
        // multiclassage n'est proposée, "Continuer" est le seul chemin —
        // exactement le cas décrit par la régression.
        expect(find.text(classDecisionInstruction), findsNothing);

        expect(
          fakeRepository.fetchLevelUpLevelDataCalls,
          [5],
          reason:
              'le niveau interrogé doit être celui DANS la classe primaire '
              '(4 + 1 = 5), jamais le niveau TOTAL + 1 du personnage (6).',
        );
        expect(find.text('NIVEAU 6'), findsOneWidget); // niveau TOTAL, inchangé
        expect(find.text('Vrai niveau 5 (Guerrier)'), findsOneWidget);
        expect(find.text('Faux niveau 6 (bug)'), findsNothing);
      },
    );
  });

  group('sous-mode "don" (alternative a l\'ASI)', () {
    const featOption = LevelUpFeatOption(
      id: 55,
      name: 'Robuste',
      description:
          'Votre total de points de vie maximum augmente de 2, et '
          'augmente de 2 supplementaires a chaque fois que vous gagnez un '
          'niveau dans cette classe.',
    );

    Future<void> pushToChoiceStep(WidgetTester tester, int level) async {
      await pushPastAnnouncement(tester, level);
      await tester.tap(find.text('CONTINUER'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONTINUER'));
      await tester.pumpAndSettle();
    }

    setUp(() {
      fakeRepository.detailToReturn = _baseDetailAtLevel(7);
      fakeRepository.levelDataByLevel = {
        8: const LevelUpLevelData(choiceType: null, automaticFeatures: []),
      };
      fakeRepository.featsToReturn = const [featOption];
    });
    testWidgets(
      'toggle "Choisir un don" : Continuer desactive tant qu aucun don '
      'n est selectionne, puis ecrit LevelUpChoiceSelection.feat (jamais '
      'une repartition de caracteristiques) ; recapitulatif titre "Don"',
      (tester) async {
        await pushToChoiceStep(tester, 8);

        expect(find.text('Etape 3 sur 4 . Amelioration ou don'), findsNothing);
        expect(
          find.text('Étape 3 sur 4 · Amélioration ou don'),
          findsOneWidget,
        );
        expect(
          find.text('Répartissez 2 points entre vos caractéristiques.'),
          findsOneWidget,
        );

        await tester.tap(find.text('CHOISIR UN DON'));
        await tester.pumpAndSettle();

        expect(find.text('Choisissez un don.'), findsOneWidget);
        expect(find.text('Robuste'), findsOneWidget);

        await tester.tap(find.text('CONTINUER'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text('Choisissez un don.'), findsOneWidget);

        await tester.tap(find.text('Robuste'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        expect(find.text('Don'), findsOneWidget);
        expect(find.text('Robuste'), findsOneWidget);
        expect(find.text('Amélioration de caractéristique'), findsNothing);

        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        final choice = fakeRepository.applyLevelUpCalls.single.choice!;
        expect(choice.kind, LevelUpChoiceKind.abilityScoreImprovement);
        expect(choice.featId, 55);
        expect(choice.abilityAllocations, isNull);
      },
    );
    testWidgets(
      'basculer entre Repartir +2 et Choisir un don preserve la selection '
      'de chacun (les deux sous-choix restent en memoire simultanement, '
      'jamais effaces par la bascule)',
      (tester) async {
        await pushToChoiceStep(tester, 8);

        await tester.tap(find.byIcon(Icons.add).first);
        await tester.pumpAndSettle();
        expect(find.text('Points restants : 1/2'), findsOneWidget);

        await tester.tap(find.text('CHOISIR UN DON'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Robuste'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('RÉPARTIR +2'));
        await tester.pumpAndSettle();
        expect(find.text('Points restants : 1/2'), findsOneWidget);

        await tester.tap(find.text('CHOISIR UN DON'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        expect(find.text('Étape 3 sur 4 · Amélioration ou don'), findsNothing);
        expect(find.text('Don'), findsOneWidget);
        expect(find.text('Robuste'), findsOneWidget);
      },
    );
    testWidgets(
      'bouton info ouvre le panneau Infos du don (description complete, '
      'prerequis) ; sa fermeture ne modifie pas la selection en cours',
      (tester) async {
        fakeRepository.featsToReturn = const [
          LevelUpFeatOption(
            id: 60,
            name: 'Vigilant',
            description:
                'Vous ne pouvez jamais etre surpris tant que vous etes '
                'conscient.',
            prerequisiteText: 'Sagesse 13 ou plus',
          ),
        ];

        await pushToChoiceStep(tester, 8);
        await tester.tap(find.text('CHOISIR UN DON'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.info_outline));
        await tester.pumpAndSettle();

        expect(find.text('VIGILANT'), findsOneWidget);
        expect(
          find.text(
            'Vous ne pouvez jamais etre surpris tant que vous etes '
            'conscient.',
          ),
          findsOneWidget,
        );
        expect(find.text('Prérequis : Sagesse 13 ou plus'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(find.text('Choisissez un don.'), findsOneWidget);
        await tester.tap(find.text('CONTINUER'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text('Choisissez un don.'), findsOneWidget);
      },
    );
  });
  group('etape "Invocations" (Occultiste)', () {
    CharacterDetailClassRow occultisteClass({required int level}) =>
        CharacterDetailClassRow(
          classId: 9,
          hitDie: 8,
          className: 'Occultiste',
          level: level,
          isPrimary: true,
          savingThrowProficiencies: const [],
        );

    testWidgets(
      'niveau 2 (choice_type invocation en base, jamais bloquant, jamais '
      'une etape Choix a faire) : enchaine Sorts (delta positif) puis '
      'Invocations, quota effectif 2, pluriel au recapitulatif, '
      'applyLevelUp recoit les 2 invocationIds ET le sort choisi',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail.copyWith(
          classes: [occultisteClass(level: 1)],
          xp: 0,
        );
        fakeRepository.levelDataByLevel = {
          2: const LevelUpLevelData(
            choiceType: 'invocation',
            automaticFeatures: [],
          ),
        };
        fakeCreationRepository.spellCatalogByClassId = {
          9: const SpellCatalog(
            spells: [
              SpellOption(
                id: 300,
                name: 'Armure de mage',
                level: 1,
                school: 'Abjuration',
                castingTime: '1 action',
              ),
            ],
          ),
        };
        fakeRepository.invocationsToReturn = const [
          LevelUpInvocationOption(
            id: 401,
            name: 'Agile esquive',
            description: '',
          ),
          LevelUpInvocationOption(
            id: 402,
            name: 'Bete familiere',
            description: '',
          ),
          LevelUpInvocationOption(
            id: 403,
            name: 'Vue dans les tenebres',
            description: '',
          ),
        ];

        await pushPastAnnouncement(tester, 2);
        expect(find.text('Étape 1 sur 5 · Points de vie'), findsOneWidget);

        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        expect(find.text('Étape 3 sur 5 · Sorts'), findsOneWidget);
        await tester.tap(find.text('Armure de mage'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        expect(find.text('Étape 4 sur 5 · Invocations'), findsOneWidget);
        expect(find.text('0 / 2'), findsOneWidget);

        await tester.tap(find.text('CONTINUER'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text('Étape 4 sur 5 · Invocations'), findsOneWidget);

        await tester.tap(find.text('Agile esquive'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Vue dans les tenebres'));
        await tester.pumpAndSettle();
        expect(find.text('2 / 2'), findsOneWidget);

        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        expect(find.text('Nouveaux sorts appris'), findsOneWidget);
        expect(find.text('Armure de mage'), findsOneWidget);
        expect(find.text('Nouvelles invocations occultistes'), findsOneWidget);
        expect(
          find.text('Agile esquive, Vue dans les tenebres'),
          findsOneWidget,
        );

        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        final applied = fakeRepository.applyLevelUpCalls.single;
        expect(applied.className, 'Occultiste');
        expect(applied.initialSpellIds, [300]);
        expect(applied.invocationIds.toSet(), {401, 403});
      },
    );
    testWidgets(
      'niveau 18 (delta 1, pas etape Sorts a ce niveau) : quota effectif '
      '1, Continuer desactive puis active, singulier au recapitulatif',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail.copyWith(
          classes: [occultisteClass(level: 17)],
          xp: 0,
        );
        fakeRepository.levelDataByLevel = {
          18: const LevelUpLevelData(choiceType: null, automaticFeatures: []),
        };
        fakeRepository.invocationsToReturn = const [
          LevelUpInvocationOption(
            id: 501,
            name: 'Ailes du diable',
            description: '',
          ),
          LevelUpInvocationOption(
            id: 502,
            name: 'Vision dans les tenebres',
            description: '',
          ),
        ];

        await pushPastAnnouncement(tester, 18);
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        expect(find.text('Étape 3 sur 4 · Invocations'), findsOneWidget);
        expect(find.text('0 / 1'), findsOneWidget);

        await tester.tap(find.text('CONTINUER'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.text('Étape 3 sur 4 · Invocations'), findsOneWidget);

        await tester.tap(find.text('Ailes du diable'));
        await tester.pumpAndSettle();
        expect(find.text('1 / 1'), findsOneWidget);

        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        expect(find.text('Nouvelle invocation occultiste'), findsOneWidget);
        expect(find.text('Ailes du diable'), findsOneWidget);

        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        expect(fakeRepository.applyLevelUpCalls.single.invocationIds, [501]);
      },
    );

    testWidgets(
      'quota effectif 0 (personnage ayant epuise toutes les invocations en '
      'base) : etat vide affiche, Continuer actif immediatement, aucune '
      'invocation ecrite',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail.copyWith(
          classes: [occultisteClass(level: 17)],
          xp: 0,
        );
        fakeRepository.levelDataByLevel = {
          18: const LevelUpLevelData(choiceType: null, automaticFeatures: []),
        };
        fakeRepository.invocationsToReturn = const [];

        await pushPastAnnouncement(tester, 18);
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        expect(find.text('0 / 0'), findsOneWidget);
        expect(
          find.text(
            'Vous connaissez déjà toutes les invocations occultistes '
            'disponibles.',
          ),
          findsOneWidget,
        );

        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        expect(find.textContaining('invocation occultiste'), findsNothing);

        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        expect(fakeRepository.applyLevelUpCalls.single.invocationIds, isEmpty);
      },
    );
  });
}
