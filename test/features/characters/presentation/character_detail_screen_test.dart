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
import 'package:personnages/core/widgets/wood_back_header.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_adventure.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/characters/domain/level_up_apply_result.dart';
import 'package:personnages/features/characters/domain/level_up_choice_selection.dart';
import 'package:personnages/features/characters/domain/level_up_level_data.dart';
import 'package:personnages/features/characters/domain/rest_type.dart';
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
}
