// Equivalent de `character_detail_rest_stale_spell_slot_test.dart` pour la
// magie de pacte de l'Occultiste (`character_pact_slots`, table separee de
// `character_spell_slots` - voir `domain/spell_slot_progression.dart`) :
// verifie que `_reassertPactSlotState` protege un lancer de sort de pacte
// reste en vol au moment d'un repos (COURT ou LONG - la magie de pacte
// recharge aux deux, contrairement aux emplacements classiques), avec la
// meme classe de garde ([_restGeneration]) que le reste de l'ecran.
//
// Ajoute par qa-testeur : ce scenario (repos court/long en course avec un
// lancer de pacte en vol) n'avait aucune couverture avant ce fichier - voir
// `spell_info_panel_test.dart` pour la selection de l'emplacement de pacte
// dans la sheet, et `pact_slot_repository_integration_test.dart` pour le
// repository seul (sans le patron optimiste de l'ecran).

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/widgets/primary_button.dart';
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
import 'package:personnages/features/characters/domain/level_up_feat_option.dart';
import 'package:personnages/features/characters/domain/level_up_invocation_option.dart';
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
  bool? lastIsPactSlot;

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
    bool isPactSlot = false,
  }) async {
    castSpellCallCount++;
    lastIsPactSlot = isPactSlot;
    await castSpellGate.future;
    current = current.copyWith(
      pactSpellSlot: CharacterSpellSlot(
        level: slotLevel,
        total: 2,
        used: slotsUsed,
        isPact: true,
      ),
    );
    return WriteOutcome.synced;
  }

  @override
  Future<void> applyRest({
    required String characterId,
    required RestType type,
    required String className,
    int diceSpent = 0,
    int appliedGain = 0,
  }) async {
    // RAW 5e : la magie de pacte recharge au repos COURT ET long -
    // contrairement aux emplacements classiques, jamais seulement au repos
    // long (voir SupabaseCharacterRepository._resetPactSlot).
    current = current.copyWith(
      pactSpellSlot: const CharacterSpellSlot(
        level: 2,
        total: 2,
        used: 0,
        isPact: true,
      ),
    );
  }

  @override
  Future<WriteOutcome> setDead({
    required String characterId,
    required bool isDead,
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
  Future<List<LevelUpFeatOption>> fetchAvailableFeats({
    required String characterId,
  }) async => throw UnimplementedError();

  @override
  Future<List<LevelUpInvocationOption>> fetchAvailableInvocations({
    required String characterId,
  }) async => throw UnimplementedError();

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
      hitDie: 8,
      className: 'Occultiste',
      level: 3,
      isPrimary: true,
      savingThrowProficiencies: [],
    ),
  ],
  xp: 0,
  currentHp: 18,
  maxHp: 24,
  temporaryHp: 0,
  abilityScores: {},
  spells: [
    CharacterSpellEntry(
      id: 1,
      name: 'Rayon de givre',
      level: 1,
      school: 'Evocation',
      status: 'connu',
    ),
  ],
  // Occultiste "pur" : aucun emplacement classique, seulement le pool de
  // pacte (voir SpellSlotProgression.slotsForLevel pour cette classe) -
  // l'unique emplacement eligible pour le sort ci-dessus, donc castSpellFlow
  // appelle directement onCastSpell sans ouvrir de sheet de choix.
  spellSlots: [],
  pactSpellSlot: CharacterSpellSlot(level: 2, total: 2, used: 0, isPact: true),
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
    'un lancer de sort de pacte reste en vol au moment d un repos LONG ne '
    'doit pas ecraser le resultat du repos une fois qu il resout',
    (tester) async {
      final repository = await pumpDetail(tester);

      await tester.tap(find.text('SORTS'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rayon de givre'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PrimaryButton, 'LANCER'));
      await tester.pumpAndSettle();

      expect(repository.castSpellCallCount, 1);
      expect(repository.lastIsPactSlot, isTrue);

      // Un repos long demarre et resout pendant que le lancer de pacte
      // precedent est toujours en vol.
      await tester.tap(find.text('PERSO'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Prendre un repos'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PrimaryButton, 'APPLIQUER'));
      await tester.pumpAndSettle();

      expect(repository.current.pactSpellSlot!.used, 0);

      // Le lancer reste en vol resout enfin (avec la valeur pre-repos,
      // desormais obsolete).
      repository.castSpellGate.complete();
      await tester.pumpAndSettle();

      expect(
        repository.current.pactSpellSlot!.used,
        0,
        reason:
            'Le lancer de pacte reste en vol ne doit pas ecraser le repos '
            'long : slots_used = '
            '${repository.current.pactSpellSlot!.used} en base au lieu de 0.',
      );
    },
  );

  testWidgets(
    'un lancer de sort de pacte reste en vol au moment d un repos COURT ne '
    'doit pas ecraser le resultat du repos une fois qu il resout (la magie '
    'de pacte recharge aussi au repos court, contrairement aux emplacements '
    'classiques)',
    (tester) async {
      final repository = await pumpDetail(tester);

      await tester.tap(find.text('SORTS'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rayon de givre'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PrimaryButton, 'LANCER'));
      await tester.pumpAndSettle();

      expect(repository.castSpellCallCount, 1);
      expect(repository.lastIsPactSlot, isTrue);

      await tester.tap(find.text('PERSO'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Prendre un repos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('REPOS COURT'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PrimaryButton, 'APPLIQUER'));
      await tester.pumpAndSettle();

      expect(repository.current.pactSpellSlot!.used, 0);

      repository.castSpellGate.complete();
      await tester.pumpAndSettle();

      expect(
        repository.current.pactSpellSlot!.used,
        0,
        reason:
            'Le lancer de pacte reste en vol ne doit pas ecraser le repos '
            'court : slots_used = '
            '${repository.current.pactSpellSlot!.used} en base au lieu de 0.',
      );
    },
  );
}
