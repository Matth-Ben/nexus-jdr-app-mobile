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
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_class_feature.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/characters/domain/level_up_apply_result.dart';
import 'package:personnages/features/characters/domain/level_up_choice_kind.dart';
import 'package:personnages/features/characters/domain/level_up_choice_selection.dart';
import 'package:personnages/features/characters/domain/level_up_level_data.dart';
import 'package:personnages/features/characters/domain/level_up_subclass_option.dart';
import 'package:personnages/features/characters/domain/rest_type.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/features/characters/presentation/level_up_screen.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';

class _AppliedLevelUp {
  const _AppliedLevelUp({
    required this.className,
    required this.hpRolled,
    required this.hpMethod,
    required this.hpGain,
    required this.choice,
  });

  final String className;
  final int hpRolled;
  final String hpMethod;
  final int hpGain;
  final LevelUpChoiceSelection? choice;
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
  Future<LevelUpApplyResult> applyLevelUp({
    required String characterId,
    required String className,
    required int hpRolled,
    required String hpMethod,
    required int hpGain,
    LevelUpChoiceSelection? choice,
  }) async {
    applyLevelUpCalls.add(
      _AppliedLevelUp(
        className: className,
        hpRolled: hpRolled,
        hpMethod: hpMethod,
        hpGain: hpGain,
        choice: choice,
      ),
    );
    if (applyErrorToThrow != null) throw applyErrorToThrow!;
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
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> leaveStory({required String characterCampaignId}) {
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

void main() {
  late _FakeCharacterRepository fakeRepository;
  late ProviderContainer container;
  late GoRouter router;

  setUp(() {
    fakeRepository = _FakeCharacterRepository();
    container = ProviderContainer(
      overrides: [
        characterRepositoryProvider.overrideWithValue(fakeRepository),
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

  Future<void> pushLevelUp(WidgetTester tester, int level) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();
    router.push('/characters/char-1/level-up?level=$level');
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

        await pushLevelUp(tester, 5);

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
        await pushLevelUp(tester, 5);

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
        await pushLevelUp(tester, 5);
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

        await pushLevelUp(tester, 5);
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
        await pushLevelUp(tester, 5);
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
        await pushLevelUp(tester, 5);

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

        await pushLevelUp(tester, 5);
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
      expect(find.text('Encore 1 niveau à valider ensuite'), findsOneWidget);

      await tester.tap(find.text('CONTINUER'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONTINUER'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONTINUER'));
      await tester.pumpAndSettle();

      expect(fakeRepository.applyLevelUpCalls, hasLength(1));
      // Toujours sur le flux, jamais revenu à la fiche.
      expect(find.text('Fiche personnage'), findsNothing);
      expect(find.text('NIVEAU 6'), findsOneWidget);
      expect(find.text('Étape 1 sur 3 · Points de vie'), findsOneWidget);
    });

    testWidgets(
      'chaînage : si le niveau suivant déjà déverrouillé reste bloqué (ex. '
      'choice_type non résolu), le flux s\'arrête proprement dessus SANS '
      'perdre le niveau déjà validé juste avant',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail.copyWith(xp: 34000);
        fakeRepository.applyResultToReturn = const LevelUpApplyResult(
          newLevel: 7,
          newMaxHp: 44,
          newCurrentHp: 40,
        );
        // Niveau 7 : ni choice_type, ni niveau ASI -> pas de blocage.
        // Niveau 8 : choice_type non résolu (`invocation`) -> reste bloqué,
        // indépendamment du fait que 8 soit aussi un niveau ASI (la
        // condition 1 est évaluée en premier, voir
        // `LevelUpBlockRules.evaluate`).
        fakeRepository.levelDataByLevel = {
          7: const LevelUpLevelData(choiceType: null, automaticFeatures: []),
          8: const LevelUpLevelData(
            choiceType: 'invocation',
            automaticFeatures: [],
          ),
        };

        await pushLevelUp(tester, 7);
        expect(find.text('Encore 1 niveau à valider ensuite'), findsOneWidget);

        await tester.tap(find.text('VALEUR MOYENNE'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        // Le niveau 7 a bien été appliqué (écrit une seule fois) avant que
        // le chaînage ne bute sur le niveau 8 bloqué.
        expect(fakeRepository.applyLevelUpCalls, hasLength(1));

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
          find.text('Guerrier niveau 8 : Invocation occulte'),
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

      await pushLevelUp(tester, 5);
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

  group('étape "Choix à faire" (increment 2)', () {
    /// Navigue jusqu'à l'étape "Choix à faire" en franchissant les étapes
    /// "Points de vie"/"Aptitudes" avec leurs valeurs par défaut.
    Future<void> pushToChoiceStep(WidgetTester tester, int level) async {
      await pushLevelUp(tester, level);
      await tester.tap(find.text('CONTINUER'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONTINUER'));
      await tester.pumpAndSettle();
    }

    group('variante amélioration de caractéristique (ASI)', () {
      setUp(() {
        fakeRepository.detailToReturn = _baseDetail;
        fakeRepository.levelDataByLevel = {
          8: const LevelUpLevelData(choiceType: null, automaticFeatures: []),
        };
      });

      testWidgets('totalSteps passe à 4, étape affichée avec instruction et '
          'compteur de points restants', (tester) async {
        await pushLevelUp(tester, 8);
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
          find.text('Étape 3 sur 4 · Amélioration de caractéristique'),
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
            find.text('Étape 3 sur 4 · Amélioration de caractéristique'),
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
          fakeRepository.detailToReturn = _baseDetail.copyWith(
            abilityScores: {'str': 19, 'con': 14},
          );

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
          fakeRepository.detailToReturn = _baseDetail.copyWith(
            abilityScores: {'wis': 20, 'con': 14},
          );

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
        fakeRepository.detailToReturn = _baseDetail;
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
        fakeRepository.detailToReturn = _baseDetail;
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
        fakeRepository.detailToReturn = _baseDetail;
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
        fakeRepository.detailToReturn = _baseDetail;
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

        // Chaînage direct vers le niveau 6 (xp 14000 déverrouille déjà ce
        // niveau) : repasse par "Points de vie"/"Aptitudes" avant de
        // ré-atteindre l'étape "Choix à faire", cette fois pour
        // "ennemi_jure".
        expect(find.text('NIVEAU 6'), findsOneWidget);
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
        fakeRepository.detailToReturn = _baseDetail.copyWith(xp: 34000);
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
        // xp 34000 déverrouille déjà le niveau 8).
        expect(find.text('NIVEAU 8'), findsOneWidget);
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('CONTINUER'));
        await tester.pumpAndSettle();

        // Budget repart à 2/2, aucune caractéristique déjà augmentée : si
        // `_abilityAllocations` n'avait pas été remis à `null`, le budget
        // du niveau 4 (déjà entièrement dépensé) resterait épuisé ici.
        expect(
          find.text('Étape 3 sur 4 · Amélioration de caractéristique'),
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

        await pushLevelUp(tester, 5);
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

        await pushLevelUp(tester, 3);
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

        await pushLevelUp(tester, 5);
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

        await pushLevelUp(tester, 14);
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

        await pushLevelUp(tester, 4);
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
          find.text('Étape 3 sur 5 · Amélioration de caractéristique'),
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
          find.text('Étape 3 sur 5 · Amélioration de caractéristique'),
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
}
