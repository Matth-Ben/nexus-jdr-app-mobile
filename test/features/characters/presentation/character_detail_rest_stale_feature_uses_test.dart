// Test de non-régression (revue QA — trouvé par un test de mutation) : même
// classe de course que `character_detail_rest_stale_spell_slot_test.dart`
// (voir sa documentation de tête pour le rationale détaillé), appliquée à
// `character_feature_uses.uses_remaining` — une utilisation d'aptitude
// restée en vol au moment d'un repos peut voir son écriture (déjà résolue
// avec une valeur devenue obsolète) écraser silencieusement le résultat du
// repos une fois celui-ci déjà appliqué en base.
//
// Utilise volontairement un REPOS COURT (pas long) : `character_feature_uses`
// est réinitialisée par les deux types de repos
// (`CharacterRepository.applyRest`/`_resetFeatureUses`), contrairement aux PV
// et aux emplacements de sorts (repos long seulement) — avant correctif,
// [_restGeneration] n'avançait que pour un repos long, laissant passer cette
// course précise pour un repos court. CORRIGÉ dans `character_detail_screen
// .dart` ([_restGeneration] avancé pour tout repos + [_reassertFeatureUsesState]).

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
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/characters/domain/level_up_apply_result.dart';
import 'package:personnages/features/characters/domain/level_up_choice_selection.dart';
import 'package:personnages/features/characters/domain/level_up_level_data.dart';
import 'package:personnages/features/characters/domain/rest_type.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/features/characters/presentation/character_detail_screen.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';

class FakeRepository implements CharacterRepository {
  CharacterDetail current = detail;
  final Completer<void> useFeatureGate = Completer<void>();

  @override
  Future<List<CharacterSummary>> fetchCharacters() async => const [];

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) async =>
      current;

  @override
  Future<WriteOutcome> useClassFeature({
    required String characterId,
    required int classFeatureId,
    required int usesRemaining,
  }) async {
    await useFeatureGate.future;
    current = current.copyWith(
      classFeatures: [
        CharacterClassFeature(
          id: classFeatureId,
          name: 'Rage',
          level: 1,
          usesMax: 2,
          usesRemaining: usesRemaining,
          restType: 'repos_court',
        ),
      ],
    );
    return WriteOutcome.synced;
  }

  @override
  Future<void> applyRest({
    required String characterId,
    required RestType type,
    required String className,
  }) async {
    // `_resetFeatureUses` (dépôt réel) réinitialise les aptitudes dont le
    // `rest_type` correspond, pour un repos COURT comme pour un repos long —
    // reproduit ici pour le seul champ pertinent à ce test.
    current = current.copyWith(
      classFeatures: [
        const CharacterClassFeature(
          id: 7,
          name: 'Rage',
          level: 1,
          usesMax: 2,
          usesRemaining: 2,
          restType: 'repos_court',
        ),
      ],
    );
  }

  @override
  Future<WriteOutcome> updateHp({
    required String characterId,
    required int currentHp,
    required int temporaryHp,
  }) => throw UnimplementedError();

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
  }) => throw UnimplementedError();

  @override
  Future<LevelUpLevelData> fetchLevelUpLevelData({
    required Object classId,
    required int targetLevel,
  }) => throw UnimplementedError();

  @override
  Future<LevelUpApplyResult> applyLevelUp({
    required String characterId,
    required String className,
    required int hpRolled,
    required String hpMethod,
    required int hpGain,
    LevelUpChoiceSelection? choice,
  }) => throw UnimplementedError();

  @override
  Future<void> leaveStory({required String characterCampaignId}) =>
      throw UnimplementedError();

  @override
  Future<WriteOutcome> castSpell({
    required String characterId,
    required int slotLevel,
    required int slotsUsed,
  }) => throw UnimplementedError();
}

const detail = CharacterDetail(
  id: '1',
  name: 'Test',
  classes: [
    CharacterDetailClassRow(
      classId: 1,
      hitDie: 10,
      className: 'Barbare',
      level: 3,
      isPrimary: true,
      savingThrowProficiencies: [],
    ),
  ],
  xp: 0,
  currentHp: 30,
  maxHp: 30,
  temporaryHp: 0,
  abilityScores: {},
  classFeatures: [
    CharacterClassFeature(
      id: 7,
      name: 'Rage',
      level: 1,
      usesMax: 2,
      usesRemaining: 1,
      restType: 'repos_court',
    ),
  ],
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
          initialLocation: '/characters/1',
          routes: [
            GoRoute(
              path: '/characters/:id',
              builder: (context, state) => CharacterDetailScreen(
                characterId: state.pathParameters['id']!,
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
    'une utilisation d\'aptitude restée en vol au moment d\'un repos court '
    'ne doit plus écraser le résultat du repos une fois qu\'elle résout '
    '(CORRIGÉ)',
    (tester) async {
      final repository = await pumpDetail(tester);

      // Utilise "Rage" (1 restant) : appel réseau gaté, reste en vol.
      await tester.tap(find.text('COMP.'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rage'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Utiliser'));
      await tester.pumpAndSettle();

      // Un repos court démarre et résout pendant que l'utilisation
      // précédente est toujours en vol.
      await tester.tap(find.text('PERSO'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Prendre un repos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('REPOS COURT'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('APPLIQUER'));
      await tester.pumpAndSettle();

      expect(repository.current.classFeatures.single.usesRemaining, 2);

      // L'utilisation restée en vol résout enfin (avec la valeur pré-repos,
      // désormais obsolète : 0).
      repository.useFeatureGate.complete();
      await tester.pumpAndSettle();

      expect(
        repository.current.classFeatures.single.usesRemaining,
        2,
        reason:
            "L'utilisation restée en vol ne doit plus écraser le repos "
            'court : uses_remaining = '
            '${repository.current.classFeatures.single.usesRemaining} en '
            'base au lieu de 2.',
      );
    },
  );
}
