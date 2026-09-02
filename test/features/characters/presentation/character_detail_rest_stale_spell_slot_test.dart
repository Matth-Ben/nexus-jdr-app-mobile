// Test de non-régression documentant, pour le lancer de sort, la même
// classe de course que `character_detail_rest_stale_hp_test.dart` (voir sa
// documentation de tête pour le rationale détaillé) : un lancer de sort resté
// en vol au moment d'un repos long peut voir son écriture (déjà résolue avec
// une valeur d'emplacement devenue obsolète) écraser silencieusement le
// résultat du repos une fois celui-ci déjà appliqué en base — CORRIGÉ dans
// `character_detail_screen.dart` avec le même jeton [_restGeneration]/la
// même méthode de réaffirmation ([_reassertSpellSlotState]) que pour les PV,
// voir la spec de la tâche ("couvre ce cas avec le même type de garde, pas
// une nouvelle mécanique").

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
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
import 'package:personnages/features/characters/presentation/character_detail_screen.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';

class FakeRepository implements CharacterRepository {
  CharacterDetail current = detail;
  final Completer<void> castSpellGate = Completer<void>();

  int castSpellCallCount = 0;
  int? lastPersistedSlotsUsed;

  @override
  Future<List<CharacterSummary>> fetchCharacters() async => const [];

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) async =>
      current;

  @override
  Future<WriteOutcome> castSpell({
    required String characterId,
    required int slotLevel,
    required int slotsUsed,
  }) async {
    castSpellCallCount++;
    await castSpellGate.future;
    lastPersistedSlotsUsed = slotsUsed;
    current = current.copyWith(
      spellSlots: [
        CharacterSpellSlot(level: slotLevel, total: 3, used: slotsUsed),
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
    if (type == RestType.long) {
      current = current.copyWith(
        currentHp: current.maxHp,
        temporaryHp: 0,
        spellSlots: const [CharacterSpellSlot(level: 1, total: 3, used: 0)],
      );
    }
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
  Future<WriteOutcome> useClassFeature({
    required String characterId,
    required int classFeatureId,
    required int usesRemaining,
  }) => throw UnimplementedError();
}

const detail = CharacterDetail(
  id: '1',
  name: 'Test',
  classes: [
    CharacterDetailClassRow(
      classId: 1,
      hitDie: 6,
      className: 'Magicien',
      level: 3,
      isPrimary: true,
      savingThrowProficiencies: [],
    ),
  ],
  xp: 0,
  currentHp: 18,
  maxHp: 30,
  temporaryHp: 0,
  abilityScores: {},
  spells: [
    CharacterSpellEntry(
      id: 1,
      name: 'Bouclier',
      level: 1,
      school: 'Abjuration',
      status: 'connu',
    ),
  ],
  spellSlots: [CharacterSpellSlot(level: 1, total: 3, used: 1)],
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
    'un lancer de sort resté en vol au moment d\'un repos long ne doit plus '
    'écraser le résultat du repos une fois qu\'il résout (CORRIGÉ)',
    (tester) async {
      final repository = await pumpDetail(tester);

      // Lance "Bouclier" (niveau 1, seul niveau éligible) : appel réseau
      // gaté, reste en vol.
      await tester.tap(find.text('SORTS'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bouclier'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lancer'));
      await tester.pumpAndSettle();

      expect(repository.castSpellCallCount, 1);

      // Un repos long démarre et résout pendant que le lancer précédent est
      // toujours en vol.
      await tester.tap(find.text('PERSO'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Prendre un repos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('APPLIQUER'));
      await tester.pumpAndSettle();

      expect(repository.current.spellSlots.single.used, 0);

      // Le lancer resté en vol résout enfin (avec la valeur pré-repos,
      // désormais obsolète).
      repository.castSpellGate.complete();
      await tester.pumpAndSettle();

      expect(
        repository.current.spellSlots.single.used,
        0,
        reason:
            'Le lancer resté en vol ne doit plus écraser le repos long : '
            'slots_used = ${repository.current.spellSlots.single.used} en '
            'base au lieu de 0.',
      );
    },
  );
}
