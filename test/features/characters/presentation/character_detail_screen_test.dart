// Tests de widget de la fiche personnage (onglet "Personnage").
//
// Le dépôt de test (`_FakeCharacterRepository`) est injecté via
// `overrideWithValue` sur `characterRepositoryProvider` — même principe que
// `character_list_screen_test.dart`. `characterDetailProvider` (famille
// Riverpod générée) n'a pas besoin d'override dédié : il délègue directement
// à ce dépôt.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/core/widgets/wood_back_header.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_adventure.dart';
import 'package:personnages/features/characters/domain/character_class_feature.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/character_spell_slot.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/characters/domain/inventory_catalog_item.dart';
import 'package:personnages/features/characters/domain/level_up_apply_result.dart';
import 'package:personnages/features/characters/domain/level_up_choice_selection.dart';
import 'package:personnages/features/characters/domain/level_up_level_data.dart';
import 'package:personnages/features/characters/domain/rest_type.dart';
import 'package:personnages/features/characters/domain/reward_item_draft.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/core/widgets/portrait_frame.dart';
import 'package:personnages/features/characters/presentation/character_detail_screen.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/features/characters/presentation/widgets/character_ability_score_grid.dart';

class _FakeCharacterRepository implements CharacterRepository {
  CharacterDetail? detailToReturn;
  Object? detailErrorToThrow;
  Completer<CharacterDetail>? detailCompleter;
  int fetchDetailCallCount = 0;

  int? lastUpdatedCurrentHp;
  int? lastUpdatedTemporaryHp;
  int updateHpCallCount = 0;
  WriteOutcome updateHpOutcomeToReturn = WriteOutcome.synced;

  String? lastRemovedPortraitUrl;
  int removePortraitCallCount = 0;

  int? lastAddedXpNewXp;
  int addXpCallCount = 0;
  Object? addXpErrorToThrow;
  WriteOutcome addXpOutcomeToReturn = WriteOutcome.synced;

  LevelUpLevelData? levelUpLevelDataToReturn;
  Object? levelUpLevelDataErrorToThrow;

  LevelUpApplyResult? applyLevelUpResultToReturn;
  Object? applyLevelUpErrorToThrow;
  int applyLevelUpCallCount = 0;

  RestType? lastAppliedRestType;
  String? lastAppliedRestClassName;
  int applyRestCallCount = 0;
  Object? applyRestErrorToThrow;

  String? lastLeftCharacterCampaignId;
  int leaveStoryCallCount = 0;
  Object? leaveStoryErrorToThrow;

  int? lastCastSlotLevel;
  int? lastCastSlotsUsed;
  int castSpellCallCount = 0;
  Object? castSpellErrorToThrow;
  WriteOutcome castSpellOutcomeToReturn = WriteOutcome.synced;

  int? lastUsedClassFeatureId;
  int? lastUsedFeatureRemaining;
  int useClassFeatureCallCount = 0;
  Object? useClassFeatureErrorToThrow;
  WriteOutcome useClassFeatureOutcomeToReturn = WriteOutcome.synced;

  String? lastUpdatedStoryAppearanceText;
  int updateStoryFieldsCallCount = 0;
  WriteOutcome updateStoryFieldsOutcomeToReturn = WriteOutcome.synced;

  @override
  Future<List<CharacterSummary>> fetchCharacters() async => const [];

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) async {
    fetchDetailCallCount++;
    if (detailCompleter != null) return detailCompleter!.future;
    if (detailErrorToThrow != null) throw detailErrorToThrow!;
    return detailToReturn ?? _baseDetail;
  }

  @override
  Future<WriteOutcome> updateHp({
    required String characterId,
    required int currentHp,
    required int temporaryHp,
  }) async {
    updateHpCallCount++;
    lastUpdatedCurrentHp = currentHp;
    lastUpdatedTemporaryHp = temporaryHp;
    return updateHpOutcomeToReturn;
  }

  @override
  Future<String> uploadPortrait({
    required String characterId,
    required Uint8List bytes,
  }) async => 'https://example.com/portrait.png';

  @override
  Future<void> removePortrait({
    required String characterId,
    required String portraitUrl,
  }) async {
    removePortraitCallCount++;
    lastRemovedPortraitUrl = portraitUrl;
  }

  @override
  Future<WriteOutcome> addXp({
    required String characterId,
    required int newXp,
  }) async {
    addXpCallCount++;
    if (addXpErrorToThrow != null) throw addXpErrorToThrow!;
    lastAddedXpNewXp = newXp;
    return addXpOutcomeToReturn;
  }

  @override
  Future<LevelUpLevelData> fetchLevelUpLevelData({
    required Object classId,
    required int targetLevel,
  }) async {
    if (levelUpLevelDataErrorToThrow != null) {
      throw levelUpLevelDataErrorToThrow!;
    }
    return levelUpLevelDataToReturn ??
        const LevelUpLevelData(choiceType: null, automaticFeatures: []);
  }

  @override
  Future<LevelUpApplyResult> applyLevelUp({
    required String characterId,
    required String className,
    required int hpRolled,
    required String hpMethod,
    required int hpGain,
    LevelUpChoiceSelection? choice,
  }) async {
    applyLevelUpCallCount++;
    if (applyLevelUpErrorToThrow != null) throw applyLevelUpErrorToThrow!;
    return applyLevelUpResultToReturn ??
        const LevelUpApplyResult(newLevel: 6, newMaxHp: 40, newCurrentHp: 28);
  }

  @override
  Future<void> applyRest({
    required String characterId,
    required RestType type,
    required String className,
  }) async {
    applyRestCallCount++;
    if (applyRestErrorToThrow != null) throw applyRestErrorToThrow!;
    lastAppliedRestType = type;
    lastAppliedRestClassName = className;
  }

  @override
  Future<void> leaveStory({required String characterCampaignId}) async {
    leaveStoryCallCount++;
    lastLeftCharacterCampaignId = characterCampaignId;
    if (leaveStoryErrorToThrow != null) throw leaveStoryErrorToThrow!;
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
  }) async {
    updateStoryFieldsCallCount++;
    lastUpdatedStoryAppearanceText = appearanceText;
    return updateStoryFieldsOutcomeToReturn;
  }

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
  }) async {
    castSpellCallCount++;
    if (castSpellErrorToThrow != null) throw castSpellErrorToThrow!;
    lastCastSlotLevel = slotLevel;
    lastCastSlotsUsed = slotsUsed;
    return castSpellOutcomeToReturn;
  }

  @override
  Future<WriteOutcome> useClassFeature({
    required String characterId,
    required int classFeatureId,
    required int usesRemaining,
  }) async {
    useClassFeatureCallCount++;
    if (useClassFeatureErrorToThrow != null) throw useClassFeatureErrorToThrow!;
    lastUsedClassFeatureId = classFeatureId;
    lastUsedFeatureRemaining = usesRemaining;
    return useClassFeatureOutcomeToReturn;
  }
}

const _baseDetail = CharacterDetail(
  id: '1',
  name: 'Halltesse Ambrelune',
  raceName: 'Elfe',
  subraceName: null,
  backgroundName: null,
  alignmentName: null,
  classes: [
    CharacterDetailClassRow(
      classId: 1,
      hitDie: 8,
      className: 'Magicienne',
      level: 5,
      isPrimary: true,
      savingThrowProficiencies: ['int', 'wis'],
    ),
  ],
  xp: 7000,
  currentHp: 18,
  maxHp: 30,
  temporaryHp: 0,
  abilityScores: {
    'str': 8,
    'dex': 14,
    'con': 12,
    'int': 18,
    'wis': 13,
    'cha': 10,
  },
);

void main() {
  late _FakeCharacterRepository fakeRepository;

  setUp(() {
    fakeRepository = _FakeCharacterRepository();
  });

  GoRouter buildTestRouter() {
    return GoRouter(
      initialLocation: '/characters/1',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('Liste'))),
        ),
        GoRoute(
          path: '/characters/:id',
          builder: (context, state) =>
              CharacterDetailScreen(characterId: state.pathParameters['id']!),
        ),
        GoRoute(
          // Stub : la navigation *vers* le flux de montée de niveau (avec
          // le bon `level`) est testée ici ; le flux lui-même a ses propres
          // tests dans `level_up_screen_test.dart`.
          path: '/characters/:id/level-up',
          builder: (context, state) => Scaffold(
            body: Center(
              child: Text(
                'Montée de niveau : ${state.uri.queryParameters['level']}',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        characterRepositoryProvider.overrideWithValue(fakeRepository),
      ],
      child: MaterialApp.router(routerConfig: buildTestRouter()),
    );
  }

  // Surface de test agrandie : la carte "Jets de sauvegarde" (en bas de la
  // liste défilante de l'onglet "Personnage") est autrement en dehors du
  // `cacheExtent` par défaut d'un `ListView` sur la taille d'écran de test
  // standard (800×600) — ses widgets ne seraient alors jamais matérialisés
  // dans l'arbre, et introuvables par `find.text(...)`.
  Future<void> pumpDetail(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildTestWidget());
  }

  testWidgets('affiche un indicateur de chargement pendant la récupération', (
    tester,
  ) async {
    fakeRepository.detailCompleter = Completer<CharacterDetail>();

    await pumpDetail(tester);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // Pas de barre d'onglets pendant le chargement (spec des états).
    expect(find.text('PERSO'), findsNothing);
  });

  testWidgets(
    'affiche un état d\'erreur avec un bouton "Réessayer" qui relance la '
    'requête',
    (tester) async {
      fakeRepository.detailErrorToThrow = const CharacterFailure(
        'Personnage introuvable.',
      );

      await pumpDetail(tester);
      await tester.pumpAndSettle();

      expect(find.text('Personnage introuvable.'), findsOneWidget);
      expect(fakeRepository.fetchDetailCallCount, 1);

      await tester.tap(find.text('RÉESSAYER'));
      await tester.pumpAndSettle();

      expect(fakeRepository.fetchDetailCallCount, 2);
    },
  );

  testWidgets('affiche le nom, le sous-titre et masque la ligne historique/'
      'alignement quand les deux sont absents', (tester) async {
    fakeRepository.detailToReturn = _baseDetail;

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    expect(find.text('Halltesse Ambrelune'), findsOneWidget);
    expect(find.text('Elfe · Magicienne · Niveau 5'), findsOneWidget);
    expect(find.textContaining('Historique :'), findsNothing);
  });

  testWidgets('affiche la ligne historique/alignement quand renseignée', (
    tester,
  ) async {
    fakeRepository.detailToReturn = _baseDetail.copyWith(
      backgroundName: 'Noble',
      alignmentName: 'Loyal Bon',
    );

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    expect(find.text('Historique : Noble · Loyal Bon'), findsOneWidget);
  });

  testWidgets(
    'format multiclasse : "{ClasseA} {niveauA} / {ClasseB} {niveauB}"',
    (tester) async {
      fakeRepository.detailToReturn = _baseDetail.copyWith(
        classes: const [
          CharacterDetailClassRow(
            classId: 1,
            hitDie: 8,
            className: 'Guerrier',
            level: 3,
            isPrimary: true,
            savingThrowProficiencies: ['str', 'con'],
          ),
          CharacterDetailClassRow(
            classId: 2,
            hitDie: 8,
            className: 'Magicien',
            level: 2,
            isPrimary: false,
            savingThrowProficiencies: ['int', 'wis'],
          ),
        ],
      );

      await pumpDetail(tester);
      await tester.pumpAndSettle();

      expect(find.text('Guerrier 3 / Magicien 2'), findsOneWidget);
    },
  );

  testWidgets('affiche les 6 caractéristiques avec score et modificateur', (
    tester,
  ) async {
    fakeRepository.detailToReturn = _baseDetail;

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    // Recherche restreinte à la grille de caractéristiques : les jets de
    // sauvegarde affichent aussi des bonus signés, parfois identiques par
    // coïncidence (ex. dex +2 non maîtrisée dans les deux cartes).
    final grid = find.byType(CharacterAbilityScoreGrid);
    // int: 18 -> +4 ; str: 8 -> −1.
    expect(
      find.descendant(of: grid, matching: find.text('18')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: grid, matching: find.text('+4')),
      findsOneWidget,
    );
    expect(find.descendant(of: grid, matching: find.text('8')), findsOneWidget);
    expect(
      find.descendant(of: grid, matching: find.text('−1')),
      findsOneWidget,
    );
  });

  testWidgets(
    'la carte "Jets de sauvegarde" affiche les 6 caractéristiques, maîtrisées '
    'depuis la classe principale uniquement',
    (tester) async {
      fakeRepository.detailToReturn = _baseDetail;

      await pumpDetail(tester);
      await tester.pumpAndSettle();

      expect(find.text('JETS DE SAUVEGARDE'), findsOneWidget);
      expect(find.text('For'), findsOneWidget);
      expect(find.text('Dex'), findsOneWidget);
      expect(find.text('Con'), findsOneWidget);
      expect(find.text('Int'), findsOneWidget);
      expect(find.text('Sag'), findsOneWidget);
      expect(find.text('Cha'), findsOneWidget);
    },
  );

  testWidgets(
    'affiche la carte "Apparence physique" seulement si au moins un des 7 '
    'champs est renseigné',
    (tester) async {
      fakeRepository.detailToReturn = _baseDetail;

      await pumpDetail(tester);
      await tester.pumpAndSettle();

      expect(find.text('APPARENCE PHYSIQUE'), findsNothing);
    },
  );

  testWidgets(
    'la carte "Apparence physique" affiche les champs renseignés, sous la '
    'carte "Jets de sauvegarde"',
    (tester) async {
      fakeRepository.detailToReturn = _baseDetail.copyWith(
        sexe: 'Femme',
        eyes: 'Argentés',
      );

      await pumpDetail(tester);
      await tester.pumpAndSettle();

      expect(find.text('APPARENCE PHYSIQUE'), findsOneWidget);
      expect(find.text('Sexe'), findsOneWidget);
      expect(find.text('Femme'), findsOneWidget);
      expect(find.text('Yeux'), findsOneWidget);
      expect(find.text('Argentés'), findsOneWidget);
      // Champs non renseignés omis.
      expect(find.text('Taille'), findsNothing);

      final savingThrowsPosition = tester.getTopLeft(
        find.text('JETS DE SAUVEGARDE'),
      );
      final appearancePosition = tester.getTopLeft(
        find.text('APPARENCE PHYSIQUE'),
      );
      expect(appearancePosition.dy, greaterThan(savingThrowsPosition.dy));
    },
  );

  testWidgets(
    'affiche la carte "Aventures" seulement si au moins une histoire est '
    'rattachée, après la carte "Apparence physique"',
    (tester) async {
      fakeRepository.detailToReturn = _baseDetail;

      await pumpDetail(tester);
      await tester.pumpAndSettle();

      expect(find.text('AVENTURES'), findsNothing);
    },
  );

  testWidgets(
    'la carte "Aventures" affiche une ligne par histoire rattachée, sous '
    'la carte "Apparence physique"',
    (tester) async {
      fakeRepository.detailToReturn = _baseDetail.copyWith(
        sexe: 'Femme',
        adventures: const [
          CharacterAdventure(
            characterCampaignId: 'cc-1',
            storyId: 'story-1',
            storyTitle: 'La Malédiction du Nord',
          ),
        ],
      );

      await pumpDetail(tester);
      await tester.pumpAndSettle();

      expect(find.text('AVENTURES'), findsOneWidget);
      expect(find.text('La Malédiction du Nord'), findsOneWidget);

      final appearancePosition = tester.getTopLeft(
        find.text('APPARENCE PHYSIQUE'),
      );
      final adventuresPosition = tester.getTopLeft(find.text('AVENTURES'));
      expect(adventuresPosition.dy, greaterThan(appearancePosition.dy));
    },
  );

  testWidgets('affiche les bandeaux PV et XP', (tester) async {
    fakeRepository.detailToReturn = _baseDetail;

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    expect(find.text('POINTS DE VIE'), findsOneWidget);
    expect(find.text('18 / 30'), findsOneWidget);
    expect(find.text('EXPÉRIENCE'), findsOneWidget);
    expect(find.text('7000 / 14000'), findsOneWidget);
  });

  testWidgets('affiche la puce "+N PV temp." seulement si temporary_hp > 0', (
    tester,
  ) async {
    fakeRepository.detailToReturn = _baseDetail.copyWith(temporaryHp: 4);

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    expect(find.text('+4 PV temp.'), findsOneWidget);
  });

  testWidgets('le stepper rapide "+" appelle updateHp avec un soin de 1 PV', (
    tester,
  ) async {
    fakeRepository.detailToReturn = _baseDetail;

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    // `find.byIcon(Icons.add)` matche aussi le bouton "+" de l'en-tête XP
    // (ouverture d'`AddXpSheet`, voir `add_xp_sheet_test.dart`/
    // `level_up_screen_test.dart`) : distingue via le `semanticLabel`
    // "Augmenter" du stepper rapide (`StepperCounter`).
    await tester.tap(find.bySemanticsLabel('Augmenter'));
    await tester.pumpAndSettle();

    expect(fakeRepository.updateHpCallCount, 1);
    expect(fakeRepository.lastUpdatedCurrentHp, 19);
    expect(fakeRepository.lastUpdatedTemporaryHp, 0);
  });

  testWidgets(
    'updateHp mis en file (mode hors-ligne) : affiche le SnackBar hors '
    'ligne, en gardant la valeur optimiste affichée',
    (tester) async {
      fakeRepository.detailToReturn = _baseDetail;
      fakeRepository.updateHpOutcomeToReturn = WriteOutcome.queued;

      await pumpDetail(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Augmenter'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Hors ligne : sera synchronisé dès que la connexion '
          'revient.',
        ),
        findsOneWidget,
      );
      // La valeur optimiste (19) reste affichée : aucune raison de revenir
      // à la valeur serveur, l'écriture n'a jamais échoué, elle est
      // seulement en attente.
      expect(find.text('19 / 30'), findsOneWidget);
    },
  );

  testWidgets('le bouton crayon PV ouvre la feuille d\'ajustement détaillée', (
    tester,
  ) async {
    fakeRepository.detailToReturn = _baseDetail;

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await tester.pumpAndSettle();

    expect(find.text('Ajuster les PV'), findsOneWidget);
    expect(find.text('DÉGÂTS'), findsOneWidget);
    expect(find.text('SOINS'), findsOneWidget);
  });

  testWidgets(
    'taper le portrait ouvre le bottom sheet d\'upload, sans "Retirer le '
    'portrait" quand le personnage n\'a pas encore de portrait',
    (tester) async {
      fakeRepository.detailToReturn = _baseDetail;

      await pumpDetail(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PortraitFrame));
      await tester.pumpAndSettle();

      expect(find.text('Prendre une photo'), findsOneWidget);
      expect(find.text('Choisir dans la galerie'), findsOneWidget);
      expect(find.text('Utiliser une URL'), findsOneWidget);
      expect(find.text('Retirer le portrait'), findsNothing);
    },
  );

  testWidgets('"Retirer le portrait" est proposé quand le personnage a déjà un '
      'portrait, et appelle removePortrait après confirmation', (tester) async {
    fakeRepository.detailToReturn = _baseDetail.copyWith(
      portraitUrl: 'https://example.com/halltesse.png',
    );

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PortraitFrame));
    await tester.pumpAndSettle();

    expect(find.text('Retirer le portrait'), findsOneWidget);
    await tester.tap(find.text('Retirer le portrait'));
    await tester.pumpAndSettle();

    expect(find.text('Retirer le portrait ?'), findsOneWidget);
    await tester.tap(find.text('Retirer'));
    await tester.pumpAndSettle();

    expect(fakeRepository.removePortraitCallCount, 1);
    expect(
      fakeRepository.lastRemovedPortraitUrl,
      'https://example.com/halltesse.png',
    );
    expect(find.text('Portrait retiré.'), findsOneWidget);
  });

  testWidgets('la navigation entre les 5 onglets fonctionne : "Personnage", '
      '"Compétences", "Sorts", "Inventaire" et "Histoire" ont chacun un vrai '
      'contenu, avec le titre du bandeau qui suit l\'onglet actif', (
    tester,
  ) async {
    fakeRepository.detailToReturn = _baseDetail.copyWith(
      appearanceText: 'Cheveux argentés.',
    );

    await pumpDetail(tester);
    await tester.pumpAndSettle();

    expect(find.text('Halltesse Ambrelune'), findsOneWidget);
    expect(find.text('FICHE'), findsOneWidget);

    await tester.tap(find.text('COMP.'));
    await tester.pumpAndSettle();
    expect(find.text('LES 18 COMPÉTENCES'), findsOneWidget);
    expect(find.text('Halltesse Ambrelune'), findsNothing);
    expect(find.text('COMPÉTENCES'), findsOneWidget);
    expect(find.text('FICHE'), findsNothing);

    await tester.tap(find.text('SORTS'));
    await tester.pumpAndSettle();
    // Preuve que l'onglet a bien basculé sur `CharacterSpellsTabBody` (voir
    // `character_spells_tab_body_test.dart` pour le détail de ce contenu) :
    // aucun sort sur `_baseDetail` -> état vide de l'onglet Sorts. Le
    // libellé de l'onglet et le titre du bandeau sont tous les deux "SORTS"
    // (seul onglet dans ce cas, voir `CharacterDetailTab.spells`) : 2
    // occurrences de "SORTS" à ce stade (bouton actif + bandeau), le titre
    // du bandeau est vérifié précisément via `WoodBackHeader`.
    expect(find.text('AUCUN SORT'), findsOneWidget);
    expect(find.text('LES 18 COMPÉTENCES'), findsNothing);
    expect(find.text('SORTS'), findsNWidgets(2));
    expect(
      find.descendant(
        of: find.byType(WoodBackHeader),
        matching: find.text('SORTS'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('SAC'));
    await tester.pumpAndSettle();
    // Rangée de stat boxes toujours affichée, même sans monnaie/inventaire
    // (voir `character_inventory_tab_body_test.dart` pour le détail de ce
    // contenu) : "0" (PO) prouve que l'onglet a bien basculé sur
    // `CharacterInventoryTabBody`, pas sur un autre onglet.
    expect(find.text('PO'), findsOneWidget);
    expect(find.text('Ajouter un objet'), findsOneWidget);
    expect(find.text('INVENTAIRE'), findsOneWidget);

    await tester.tap(find.text('HIST.'));
    await tester.pumpAndSettle();
    // Preuve que l'onglet a bien basculé sur `CharacterStoryTabBody` (voir
    // `character_story_tab_body_test.dart` pour le détail de ce contenu).
    expect(find.text('APPARENCE PHYSIQUE'), findsOneWidget);
    expect(find.text('Cheveux argentés.'), findsOneWidget);
    expect(find.text('HISTOIRE'), findsOneWidget);

    await tester.tap(find.text('PERSO'));
    await tester.pumpAndSettle();
    expect(find.text('Halltesse Ambrelune'), findsOneWidget);
    expect(find.text('FICHE'), findsOneWidget);
  });

  testWidgets(
    'icône "Modifier" du bandeau bois : n\'apparaît que sur l\'onglet '
    '"Histoire", ouvre la sheet d\'édition préremplie, un succès invalide '
    'la fiche et affiche le SnackBar de confirmation',
    (tester) async {
      fakeRepository.detailToReturn = _baseDetail.copyWith(
        appearanceText: 'Cheveux argentés.',
      );

      await pumpDetail(tester);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Modifier'), findsNothing);

      await tester.tap(find.text('HIST.'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Modifier'), findsOneWidget);

      await tester.tap(find.byTooltip('Modifier'));
      await tester.pumpAndSettle();

      expect(find.text("MODIFIER L'HISTOIRE"), findsOneWidget);
      expect(
        tester
            .widgetList<TextFormField>(find.byType(TextFormField))
            .first
            .controller!
            .text,
        'Cheveux argentés.',
      );

      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pumpAndSettle();

      expect(fakeRepository.updateStoryFieldsCallCount, 1);
      expect(
        fakeRepository.lastUpdatedStoryAppearanceText,
        'Cheveux argentés.',
      );
      expect(
        fakeRepository.fetchDetailCallCount,
        greaterThan(1),
        reason:
            'un succès doit invalider `characterDetailProvider`, '
            'déclenchant un refetch',
      );
      expect(find.text('Histoire mise à jour.'), findsOneWidget);
    },
  );

  group('déclenchement de la montée de niveau (increment 1)', () {
    testWidgets(
      'le bouton "+" du bandeau XP ouvre AddXpSheet ; valider appelle '
      'addXp avec le nouveau total et rafraîchit la fiche',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail;

        await pumpDetail(tester);
        await tester.pumpAndSettle();

        // `find.byIcon(Icons.add)` matche aussi le stepper rapide "+" du
        // bandeau PV (`semanticLabel` "Augmenter") : le bouton "+" du
        // bandeau XP est le seul `IconButton` parmi les deux icônes
        // trouvées (le stepper rapide n'utilise pas `IconButton`, voir
        // `StepperCounter._StepperButton`).
        expect(find.byIcon(Icons.add), findsNWidgets(2));
        await tester.tap(
          find.ancestor(
            of: find.byIcon(Icons.add),
            matching: find.byType(IconButton),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text("Ajouter de l'XP"), findsOneWidget);

        await tester.enterText(find.byType(TextFormField), '250');
        await tester.pumpAndSettle();
        await tester.tap(find.text('AJOUTER'));
        await tester.pumpAndSettle();

        expect(fakeRepository.addXpCallCount, 1);
        expect(fakeRepository.lastAddedXpNewXp, 7250);
        expect(fakeRepository.fetchDetailCallCount, greaterThan(1));
      },
    );

    testWidgets(
      'ajouter assez d\'XP pour franchir le seuil pousse immédiatement le '
      'flux de montée de niveau, ciblant totalLevel + 1',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail;

        await pumpDetail(tester);
        await tester.pumpAndSettle();

        await tester.tap(
          find.ancestor(
            of: find.byIcon(Icons.add),
            matching: find.byType(IconButton),
          ),
        );
        await tester.pumpAndSettle();

        // xp actuelle 7000, seuil niveau 6 = 14000 -> 7500 suffit à le
        // franchir.
        await tester.enterText(find.byType(TextFormField), '7500');
        await tester.pumpAndSettle();
        await tester.tap(find.text('AJOUTER'));
        await tester.pumpAndSettle();

        expect(fakeRepository.lastAddedXpNewXp, 14500);
        expect(find.text('Montée de niveau : 6'), findsOneWidget);
      },
    );

    testWidgets(
      'lien "Monter de niveau manuellement" visible tant que l\'XP n\'a pas '
      'franchi le seuil, et ouvre le flux ciblant totalLevel + 1',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail;

        await pumpDetail(tester);
        await tester.pumpAndSettle();

        expect(find.text('Monter de niveau manuellement'), findsOneWidget);
        expect(find.textContaining('DISPONIBLE'), findsNothing);

        await tester.tap(find.text('Monter de niveau manuellement'));
        await tester.pumpAndSettle();

        expect(find.text('Montée de niveau : 6'), findsOneWidget);
      },
    );

    testWidgets(
      'bandeau "NIVEAU {n} DISPONIBLE" remplace le lien discret quand le '
      'seuil est déjà franchi, et ouvre le même flux',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail.copyWith(xp: 14000);

        await pumpDetail(tester);
        await tester.pumpAndSettle();

        expect(find.text('Monter de niveau manuellement'), findsNothing);
        expect(find.text('NIVEAU 6 DISPONIBLE'), findsOneWidget);

        await tester.tap(find.text('NIVEAU 6 DISPONIBLE'));
        await tester.pumpAndSettle();

        expect(find.text('Montée de niveau : 6'), findsOneWidget);
      },
    );

    testWidgets(
      'un échec de addXp affiche un SnackBar, sans pousser le flux de '
      'montée de niveau',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail;
        fakeRepository.addXpErrorToThrow = const CharacterFailure(
          "Impossible d'ajouter l'XP. Réessayez.",
        );

        await pumpDetail(tester);
        await tester.pumpAndSettle();

        await tester.tap(
          find.ancestor(
            of: find.byIcon(Icons.add),
            matching: find.byType(IconButton),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextFormField), '250');
        await tester.pumpAndSettle();
        await tester.tap(find.text('AJOUTER'));
        await tester.pumpAndSettle();

        expect(
          find.text("Impossible d'ajouter l'XP. Réessayez."),
          findsOneWidget,
        );
        expect(find.textContaining('Montée de niveau'), findsNothing);
      },
    );

    testWidgets(
      'addXp mis en file (mode hors-ligne) : affiche le SnackBar hors ligne '
      "et ne déclenche jamais l'ouverture automatique de la montée de "
      'niveau, même si le seuil serait franchi',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail;
        fakeRepository.addXpOutcomeToReturn = WriteOutcome.queued;

        await pumpDetail(tester);
        await tester.pumpAndSettle();

        await tester.tap(
          find.ancestor(
            of: find.byIcon(Icons.add),
            matching: find.byType(IconButton),
          ),
        );
        await tester.pumpAndSettle();

        // xp actuelle 7000, seuil niveau 6 = 14000 -> 7500 suffit à le
        // franchir : si la mise en file déclenchait quand même la montée de
        // niveau, ce test échouerait sur l'assertion `findsNothing`
        // ci-dessous.
        await tester.enterText(find.byType(TextFormField), '7500');
        await tester.pumpAndSettle();
        await tester.tap(find.text('AJOUTER'));
        await tester.pumpAndSettle();

        expect(fakeRepository.addXpCallCount, 1);
        expect(
          find.text(
            'Hors ligne : sera synchronisé dès que la connexion '
            'revient.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Montée de niveau'), findsNothing);
        // Aucun rafraîchissement depuis le serveur pour un résultat mis en
        // file (voir `_addXp` : `ref.invalidate` n'est appelé que pour
        // `WriteOutcome.synced`).
        expect(fakeRepository.fetchDetailCallCount, 1);
      },
    );
  });

  group('lien "Prendre un repos" et feuille "Repos"', () {
    testWidgets(
      'le lien "Prendre un repos" ouvre RestSheet avec les PV actuels/max',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail;

        await pumpDetail(tester);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Prendre un repos'));
        await tester.pumpAndSettle();

        expect(find.text('Repos'), findsOneWidget);
        expect(find.text('PV actuels : 18 / 30'), findsOneWidget);
      },
    );

    testWidgets(
      'appliquer un repos long appelle applyRest(RestType.long), rafraîchit '
      'la fiche et affiche la confirmation',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail;

        await pumpDetail(tester);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Prendre un repos'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('APPLIQUER'));
        await tester.pumpAndSettle();

        expect(fakeRepository.applyRestCallCount, 1);
        expect(fakeRepository.lastAppliedRestType, RestType.long);
        expect(fakeRepository.lastAppliedRestClassName, 'Magicienne');
        expect(fakeRepository.fetchDetailCallCount, greaterThan(1));
        expect(
          find.text('Repos long effectué. PV restaurés au maximum.'),
          findsOneWidget,
        );
        // Bascule optimiste immédiate du bandeau PV (résultat connu à
        // l'avance pour un repos long), avant même que le rafraîchissement
        // réseau ne confirme la même valeur.
        expect(find.text('30 / 30'), findsOneWidget);
      },
    );

    testWidgets(
      'appliquer un repos court appelle applyRest(RestType.short) et affiche '
      'une confirmation sobre',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail;

        await pumpDetail(tester);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Prendre un repos'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('REPOS COURT'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('APPLIQUER'));
        await tester.pumpAndSettle();

        expect(fakeRepository.applyRestCallCount, 1);
        expect(fakeRepository.lastAppliedRestType, RestType.short);
        expect(find.text('Repos court effectué.'), findsOneWidget);
      },
    );

    testWidgets('un échec de applyRest affiche un SnackBar d\'erreur', (
      tester,
    ) async {
      fakeRepository.detailToReturn = _baseDetail;
      fakeRepository.applyRestErrorToThrow = const CharacterFailure(
        "Impossible d'effectuer le repos. Réessayez.",
      );

      await pumpDetail(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Prendre un repos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('APPLIQUER'));
      await tester.pumpAndSettle();

      expect(
        find.text("Impossible d'effectuer le repos. Réessayez."),
        findsOneWidget,
      );
    });
  });

  group('lancer un sort (increment 1 — actions d\'écriture)', () {
    Future<void> pumpSpellsTab(WidgetTester tester) async {
      fakeRepository.detailToReturn = _baseDetail.copyWith(
        spells: const [
          CharacterSpellEntry(
            id: 1,
            name: 'Bouclier',
            level: 1,
            school: 'Abjuration',
            status: 'connu',
          ),
        ],
        spellSlots: const [CharacterSpellSlot(level: 1, total: 3, used: 1)],
      );

      await pumpDetail(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('SORTS'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bouclier'));
      await tester.pumpAndSettle();
      // Le tap sur la ligne de sort ouvre directement le panneau "Infos"
      // (`showSpellInfoPanel`, plus de sheet intermédiaire "Infos"/"Lancer")
      // — son bouton "Lancer" est un `PrimaryButton`, rendu en majuscules.
      await tester.tap(find.widgetWithText(PrimaryButton, 'LANCER'));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'appelle castSpell avec le niveau retenu et le nouveau total consommé, '
      'affiche une confirmation',
      (tester) async {
        await pumpSpellsTab(tester);

        expect(fakeRepository.castSpellCallCount, 1);
        expect(fakeRepository.lastCastSlotLevel, 1);
        // 1 déjà consommé + 1 = 2.
        expect(fakeRepository.lastCastSlotsUsed, 2);
        expect(
          find.text('Bouclier lancé (emplacement niveau 1).'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'hors ligne (queued) : message dédié (pas de promesse de synchro) et '
      "revert de l'état optimiste, castSpell n'étant jamais mis en file",
      (tester) async {
        fakeRepository.castSpellOutcomeToReturn = WriteOutcome.queued;

        await pumpSpellsTab(tester);

        expect(
          find.text(
            "Hors ligne : cette action n'a pas pu être enregistrée. "
            'Réessayez une fois reconnecté.',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            'Hors ligne : sera synchronisé dès que la connexion revient.',
          ),
          findsNothing,
        );
        // Revert : l'état optimiste (1 restant) ne doit pas rester affiché
        // puisque rien ne sera synchronisé plus tard.
        expect(
          find.bySemanticsLabel('Emplacements de sorts : 2 restants sur 3'),
          findsOneWidget,
        );
      },
    );

    testWidgets('échec : affiche un message d\'erreur dédié', (tester) async {
      fakeRepository.castSpellErrorToThrow = const CharacterFailure(
        'Impossible de lancer ce sort. Réessayez.',
      );

      await pumpSpellsTab(tester);

      expect(
        find.text('Impossible de lancer ce sort. Réessayez.'),
        findsOneWidget,
      );
    });

    testWidgets(
      "échec : l'état optimiste revient à l'affichage d'avant (pastilles "
      "d'emplacement), pas seulement le message d'erreur",
      (tester) async {
        fakeRepository.castSpellErrorToThrow = const CharacterFailure(
          'Impossible de lancer ce sort. Réessayez.',
        );

        await pumpSpellsTab(tester);

        // 1 déjà consommé sur 3 avant le tap : la bascule optimiste était
        // passée à 2 consommés (1 restant) le temps de l'appel. Après
        // l'échec, doit revenir à 2 restants sur 3 (état d'avant), pas rester
        // sur la valeur optimiste jamais confirmée.
        expect(
          find.bySemanticsLabel('Emplacements de sorts : 2 restants sur 3'),
          findsOneWidget,
          reason:
              "L'état optimiste (1 restant) ne doit pas rester affiché après "
              "l'échec de l'appel réseau.",
        );
        expect(
          find.bySemanticsLabel('Emplacements de sorts : 1 restants sur 3'),
          findsNothing,
        );
      },
    );

    testWidgets('sort niveau 0 : aucun appel réseau, confirmation immédiate', (
      tester,
    ) async {
      fakeRepository.detailToReturn = _baseDetail.copyWith(
        spells: const [
          CharacterSpellEntry(
            id: 1,
            name: 'Lumière',
            level: 0,
            school: 'Évocation',
            status: 'connu',
          ),
        ],
      );

      await pumpDetail(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('SORTS'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lumière'));
      await tester.pumpAndSettle();
      // Le tap sur la ligne de sort ouvre directement le panneau "Infos"
      // (`showSpellInfoPanel`, plus de sheet intermédiaire "Infos"/"Lancer")
      // — son bouton "Lancer" est un `PrimaryButton`, rendu en majuscules.
      await tester.tap(find.widgetWithText(PrimaryButton, 'LANCER'));
      await tester.pumpAndSettle();

      expect(fakeRepository.castSpellCallCount, 0);
      expect(find.text('Lumière lancé.'), findsOneWidget);
    });
  });

  group('utiliser une aptitude de classe (increment 1 — actions '
      'd\'écriture)', () {
    Future<void> pumpSkillsTab(WidgetTester tester) async {
      fakeRepository.detailToReturn = _baseDetail.copyWith(
        classFeatures: const [
          CharacterClassFeature(
            id: 7,
            name: 'Rage',
            level: 1,
            usesMax: 2,
            usesRemaining: 1,
            restType: 'repos_long',
          ),
        ],
      );

      await pumpDetail(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('COMP.'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rage'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Utiliser'));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'appelle useClassFeature avec le nouveau total restant, affiche une '
      'confirmation',
      (tester) async {
        await pumpSkillsTab(tester);

        expect(fakeRepository.useClassFeatureCallCount, 1);
        expect(fakeRepository.lastUsedClassFeatureId, 7);
        expect(fakeRepository.lastUsedFeatureRemaining, 0);
        expect(find.text('Rage utilisée.'), findsOneWidget);
      },
    );

    testWidgets(
      'hors ligne (queued) : message dédié (pas de promesse de synchro) et '
      "revert de l'état optimiste, useClassFeature n'étant jamais mis en "
      'file',
      (tester) async {
        fakeRepository.useClassFeatureOutcomeToReturn = WriteOutcome.queued;

        await pumpSkillsTab(tester);

        expect(
          find.text(
            "Hors ligne : cette action n'a pas pu être enregistrée. "
            'Réessayez une fois reconnecté.',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            'Hors ligne : sera synchronisé dès que la connexion revient.',
          ),
          findsNothing,
        );
        // Revert : l'état optimiste (0 restant) ne doit pas rester affiché.
        expect(find.text('1 / 2 · repos long'), findsOneWidget);
      },
    );

    testWidgets('échec : affiche un message d\'erreur dédié', (tester) async {
      fakeRepository.useClassFeatureErrorToThrow = const CharacterFailure(
        "Impossible d'utiliser cette aptitude. Réessayez.",
      );

      await pumpSkillsTab(tester);

      expect(
        find.text("Impossible d'utiliser cette aptitude. Réessayez."),
        findsOneWidget,
      );
    });

    testWidgets(
      "échec : l'état optimiste revient au compteur d'usage d'avant, pas "
      "seulement le message d'erreur",
      (tester) async {
        fakeRepository.useClassFeatureErrorToThrow = const CharacterFailure(
          "Impossible d'utiliser cette aptitude. Réessayez.",
        );

        await pumpSkillsTab(tester);

        // usesRemaining: 1 avant le tap : la bascule optimiste était passée à
        // 0 ("0 / 2 · repos long") le temps de l'appel. Après l'échec, doit
        // revenir à "1 / 2 · repos long" (état d'avant), pas rester sur la
        // valeur optimiste jamais confirmée.
        expect(
          find.text('1 / 2 · repos long'),
          findsOneWidget,
          reason:
              "L'état optimiste (0 / 2) ne doit pas rester affiché après "
              "l'échec de l'appel réseau.",
        );
        expect(find.text('0 / 2 · repos long'), findsNothing);
      },
    );
  });
}
