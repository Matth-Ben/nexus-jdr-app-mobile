// Tests de widget du flux "Montée de niveau" (increment 1).
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
import 'package:personnages/features/characters/domain/level_up_level_data.dart';
import 'package:personnages/features/characters/presentation/level_up_screen.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';

class _AppliedLevelUp {
  const _AppliedLevelUp({
    required this.hpRolled,
    required this.hpMethod,
    required this.hpGain,
  });

  final int hpRolled;
  final String hpMethod;
  final int hpGain;
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
        const LevelUpLevelData(blockingChoiceType: null, automaticFeatures: []);
  }

  @override
  Future<LevelUpApplyResult> applyLevelUp({
    required String characterId,
    required int hpRolled,
    required String hpMethod,
    required int hpGain,
  }) async {
    applyLevelUpCalls.add(
      _AppliedLevelUp(hpRolled: hpRolled, hpMethod: hpMethod, hpGain: hpGain),
    );
    if (applyErrorToThrow != null) throw applyErrorToThrow!;
    return applyResultToReturn!;
  }

  @override
  Future<void> addXp({required String characterId, required int newXp}) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateHp({
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
      'niveau 8 (amélioration de caractéristique) bloque avant l\'étape '
      '"Points de vie", header sans "NIVEAU {n}" (0 niveau validé cette '
      'session)',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail;

        await pushLevelUp(tester, 8);

        expect(find.text('MONTÉE DE NIVEAU'), findsOneWidget);
        expect(find.text('NIVEAU 8'), findsNothing);
        expect(find.text('Niveau 8 : choix requis'), findsOneWidget);
        expect(
          find.text(
            'Ce niveau nécessite un choix pas encore disponible dans '
            "l'app.",
          ),
          findsOneWidget,
        );
        expect(
          find.text('Amélioration de caractéristique ou don'),
          findsOneWidget,
        );
        expect(find.text('Points de vie'), findsNothing);

        await tester.tap(find.text('RETOUR À LA FICHE'));
        await tester.pumpAndSettle();
        expect(find.text('Fiche personnage'), findsOneWidget);
      },
    );

    testWidgets(
      'un choice_type de class_features bloque avec le libellé résolu',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail;
        fakeRepository.levelDataByLevel = {
          5: const LevelUpLevelData(
            blockingChoiceType: 'style_combat',
            automaticFeatures: [],
          ),
        };

        await pushLevelUp(tester, 5);

        expect(find.text('Niveau 5 : choix requis'), findsOneWidget);
        expect(
          find.text('Guerrier niveau 5 : Style de combat'),
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
          blockingChoiceType: null,
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
          5: const LevelUpLevelData(
            blockingChoiceType: null,
            automaticFeatures: [],
          ),
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
        5: const LevelUpLevelData(
          blockingChoiceType: null,
          automaticFeatures: [],
        ),
        6: const LevelUpLevelData(
          blockingChoiceType: null,
          automaticFeatures: [],
        ),
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
      'chaînage : si le niveau suivant déjà déverrouillé nécessite un choix '
      "(ex. amélioration de caractéristique niveau 8), le flux s'arrête "
      'proprement dessus SANS perdre le niveau déjà validé juste avant '
      '(condition 2 de LevelUpBlockRules revérifiée après chaque montée '
      'appliquée)',
      (tester) async {
        fakeRepository.detailToReturn = _baseDetail.copyWith(xp: 34000);
        fakeRepository.applyResultToReturn = const LevelUpApplyResult(
          newLevel: 7,
          newMaxHp: 44,
          newCurrentHp: 40,
        );
        // Niveau 7 : ni choice_type, ni niveau ASI -> pas de blocage (repli
        // par défaut du double). Niveau 8 : pas de choice_type non plus,
        // mais bloque quand même via la condition 2 (niveau ASI codé en
        // dur) -- aucune entrée `levelDataByLevel` nécessaire pour ce cas.
        fakeRepository.levelDataByLevel = {
          7: const LevelUpLevelData(
            blockingChoiceType: null,
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
          find.text('Amélioration de caractéristique ou don'),
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
}
