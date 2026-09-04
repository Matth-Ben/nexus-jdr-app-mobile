// Test de non-régression (revue QA/code) : `CharacterRepository.castSpell`/
// `useClassFeature` écrivent une valeur *absolue* (`slots_used`/
// `uses_remaining`), pas un incrément atomique côté serveur — sans verrou,
// deux taps rapprochés sur la même action (avant résolution réseau du
// premier) pouvaient résoudre dans le désordre et laisser l'un écraser
// silencieusement l'autre, perdant une consommation d'emplacement de sort ou
// d'usage d'aptitude sans aucune erreur visible. CORRIGÉ dans
// `character_detail_screen.dart` (verrous [_isCastingSpell]/[_isUsingFeature],
// même mécanique que [_isApplyingRest] pour le repos) : ce fichier prouve
// qu'un second tap pendant que le premier est encore en vol ne déclenche
// aucun second appel réseau.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_class_feature.dart';
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
  final Completer<void> castSpellGate = Completer<void>();
  final Completer<void> useFeatureGate = Completer<void>();

  int castSpellCallCount = 0;
  int useClassFeatureCallCount = 0;
  int? lastCastSlotsUsed;
  int? lastUsedFeatureRemaining;

  @override
  Future<List<CharacterSummary>> fetchCharacters() async => const [];

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) async =>
      detail;

  @override
  Future<WriteOutcome> castSpell({
    required String characterId,
    required int slotLevel,
    required int slotsUsed,
  }) async {
    castSpellCallCount++;
    await castSpellGate.future;
    lastCastSlotsUsed = slotsUsed;
    return WriteOutcome.synced;
  }

  @override
  Future<WriteOutcome> useClassFeature({
    required String characterId,
    required int classFeatureId,
    required int usesRemaining,
  }) async {
    useClassFeatureCallCount++;
    await useFeatureGate.future;
    lastUsedFeatureRemaining = usesRemaining;
    return WriteOutcome.synced;
  }

  @override
  Future<void> applyRest({
    required String characterId,
    required RestType type,
    required String className,
  }) => throw UnimplementedError();

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
}

const detail = CharacterDetail(
  id: '1',
  name: 'Test',
  classes: [
    CharacterDetailClassRow(
      classId: 1,
      hitDie: 8,
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
  spellSlots: [CharacterSpellSlot(level: 1, total: 3, used: 0)],
  classFeatures: [
    CharacterClassFeature(
      id: 7,
      name: 'Rage',
      level: 1,
      usesMax: 2,
      usesRemaining: 2,
      restType: 'repos_long',
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
    'un second tap sur le même sort pendant que le premier lancer est '
    'encore en vol ne déclenche aucun second appel réseau (CORRIGÉ)',
    (tester) async {
      final repository = await pumpDetail(tester);

      await tester.tap(find.text('SORTS'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bouclier'));
      // Le tap sur la ligne de sort ouvre directement le panneau "Infos"
      // (plus de sheet intermédiaire "Infos"/"Lancer") : "Lancer" y est un
      // `PrimaryButton`, rendu en majuscules.
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PrimaryButton, 'LANCER'));
      // `pumpAndSettle()` ici ne dépend pas de la résolution de
      // `castSpellGate` (jamais tiré par une animation) : elle règle la
      // fermeture du panneau, laissant le temps au verrou de se poser côté
      // écran pendant que l'appel réseau reste en vol en arrière-plan.
      await tester.pumpAndSettle();

      expect(repository.castSpellCallCount, 1);

      // Le tap sur la ligne de sort (verrouillée) ne doit rien déclencher :
      // ni réouverture du panneau, ni second appel réseau.
      await tester.tap(find.text('Bouclier'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(
        repository.castSpellCallCount,
        1,
        reason:
            'Un second tap pendant que le premier est en vol ne doit '
            'jamais déclencher un second appel réseau (risque '
            'd\'écrasement silencieux, écriture à valeur absolue).',
      );
      expect(find.text('BOUCLIER'), findsNothing);

      repository.castSpellGate.complete();
      await tester.pumpAndSettle();

      expect(repository.castSpellCallCount, 1);
      expect(repository.lastCastSlotsUsed, 1);
    },
  );

  testWidgets(
    'un second tap sur la même aptitude pendant que la première utilisation '
    'est encore en vol ne déclenche aucun second appel réseau (CORRIGÉ)',
    (tester) async {
      final repository = await pumpDetail(tester);

      await tester.tap(find.text('COMP.'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rage'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Utiliser'));
      await tester.pumpAndSettle();

      expect(repository.useClassFeatureCallCount, 1);

      await tester.tap(find.text('Rage'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(
        repository.useClassFeatureCallCount,
        1,
        reason:
            'Un second tap pendant que le premier est en vol ne doit '
            'jamais déclencher un second appel réseau.',
      );
      expect(find.text('Infos'), findsNothing);

      repository.useFeatureGate.complete();
      await tester.pumpAndSettle();

      expect(repository.useClassFeatureCallCount, 1);
      expect(repository.lastUsedFeatureRemaining, 1);
    },
  );
}
