// Tests de widget de la sheet "Ajouter une récompense"
// (`presentation/widgets/add_reward_sheet.dart`) — section "MONNAIE" (5
// champs, deltas), section "OBJETS" (liste locale, tuile "+ Ajouter un
// objet" réutilisant le flux du chemin "Objet personnalisé" — le chemin
// "Depuis le catalogue" a besoin de `ProviderScope`, testé séparément dans
// `add_item_flow_test.dart`).

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/characters/domain/inventory_catalog_item.dart';
import 'package:personnages/features/characters/domain/level_up_apply_result.dart';
import 'package:personnages/features/characters/domain/level_up_choice_selection.dart';
import 'package:personnages/features/characters/domain/level_up_level_data.dart';
import 'package:personnages/features/characters/domain/rest_type.dart';
import 'package:personnages/features/characters/domain/reward_item_draft.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/features/characters/presentation/widgets/add_reward_sheet.dart';

Map<CurrencyKind, int>? lastCurrencyDeltas;
List<RewardItemDraft>? lastItems;

/// Double minimal — seul `fetchInventoryCatalog` est exercé par le test
/// "Depuis le catalogue" ci-dessous (le reste de la sheet ne fait aucun
/// appel réseau, voir sa documentation de classe) ; copié de
/// `add_item_flow_test.dart::FakeRepository` (même rationale de duplication
/// que le reste de ce dépôt) plutôt que partagé, chaque fichier de test
/// restant lisible seul.
class _FakeInventoryCatalogRepository implements CharacterRepository {
  _FakeInventoryCatalogRepository({this.catalog = const []});

  final List<InventoryCatalogItem> catalog;

  @override
  Future<List<InventoryCatalogItem>> fetchInventoryCatalog() async => catalog;

  @override
  Future<List<CharacterSummary>> fetchCharacters() async => const [];

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) =>
      throw UnimplementedError();

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
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> addXp({
    required String characterId,
    required int newXp,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> castSpell({
    required String characterId,
    required int slotLevel,
    required int slotsUsed,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> useClassFeature({
    required String characterId,
    required int classFeatureId,
    required int usesRemaining,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> useInventoryItem({
    required String characterId,
    required String inventoryId,
    required int newQuantity,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> setInventoryItemEquipped({
    required String characterId,
    required String inventoryId,
    required bool equipped,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> removeInventoryItem({
    required String characterId,
    required String inventoryId,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> adjustCurrency({
    required String characterId,
    required CurrencyKind currency,
    required int newAmount,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> addInventoryItem({
    required String characterId,
    required int itemId,
    required int quantity,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> addCustomInventoryItem({
    required String characterId,
    required String customName,
    required int quantity,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> addReward({
    required String characterId,
    required Map<CurrencyKind, int> newCurrencyTotals,
    required List<RewardItemDraft> items,
  }) => throw UnimplementedError();

  @override
  Future<void> applyRest({
    required String characterId,
    required RestType type,
    required String className,
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
}

const _dagger = InventoryCatalogItem(
  id: 1,
  name: 'Dague',
  category: 'arme',
  costAmount: 2,
  weight: 0.5,
);

Future<void> _pumpSheet(WidgetTester tester) async {
  lastCurrencyDeltas = null;
  lastItems = null;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showAddRewardSheet(
                context,
                onApply: (deltas, items) {
                  lastCurrencyDeltas = deltas;
                  lastItems = items;
                },
              ),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('bouton "Ajouter la récompense" désactivé sans monnaie ni '
      'objet', (tester) async {
    await _pumpSheet(tester);

    final button = tester.widget<PrimaryButton>(
      find.widgetWithText(PrimaryButton, 'AJOUTER LA RÉCOMPENSE'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('saisir un montant de monnaie active le bouton et produit un '
      'delta pour cette seule monnaie (les autres champs vides sont '
      'omis)', (tester) async {
    await _pumpSheet(tester);

    // Premier TextFormField = PO (`_currencyFieldsOrder`).
    await tester.enterText(find.byType(TextFormField).first, '50');
    await tester.pump();

    await tester.tap(
      find.widgetWithText(PrimaryButton, 'AJOUTER LA RÉCOMPENSE'),
    );
    await tester.pumpAndSettle();

    expect(lastCurrencyDeltas, {CurrencyKind.gold: 50});
    expect(lastItems, isEmpty);
  });

  testWidgets(
    '"+ Ajouter un objet" -> "Objet personnalisé" ajoute une ligne à la '
    'liste locale, le bouton close la retire',
    (tester) async {
      await _pumpSheet(tester);

      await tester.tap(find.text('Ajouter un objet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Objet personnalisé'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).last,
        'Amulette de famille',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'AJOUTER'));
      await tester.pumpAndSettle();

      expect(find.text('Amulette de famille × 1'), findsOneWidget);

      final button = tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, 'AJOUTER LA RÉCOMPENSE'),
      );
      expect(button.onPressed, isNotNull);

      // Retire la ligne via le bouton close (le premier `Icons.close` est
      // celui du `SheetHeaderBar`, le dernier celui de la ligne d'objet).
      await tester.tap(find.byIcon(Icons.close).last);
      await tester.pumpAndSettle();

      expect(find.text('Amulette de famille × 1'), findsNothing);
      final buttonAfterRemoval = tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, 'AJOUTER LA RÉCOMPENSE'),
      );
      expect(buttonAfterRemoval.onPressed, isNull);
    },
  );

  testWidgets('validation avec un objet personnalisé : onApply reçoit la liste '
      'complète, un seul appel', (tester) async {
    await _pumpSheet(tester);

    await tester.tap(find.text('Ajouter un objet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Objet personnalisé'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, 'Amulette');
    await tester.pump();
    await tester.tap(find.widgetWithText(PrimaryButton, 'AJOUTER'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(PrimaryButton, 'AJOUTER LA RÉCOMPENSE'),
    );
    await tester.pumpAndSettle();

    expect(lastCurrencyDeltas, isEmpty);
    expect(lastItems, hasLength(1));
    expect(lastItems!.single.customName, 'Amulette');
    expect(lastItems!.single.quantity, 1);
    expect(lastItems!.single.isCustom, isTrue);
  });

  testWidgets(
    '"+ Ajouter un objet" -> "Depuis le catalogue" ajoute une ligne à la '
    'liste locale avec `itemId` (jamais `customName`), un seul appel à la '
    'validation',
    (tester) async {
      lastCurrencyDeltas = null;
      lastItems = null;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            characterRepositoryProvider.overrideWithValue(
              _FakeInventoryCatalogRepository(catalog: const [_dagger]),
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => showAddRewardSheet(
                      context,
                      onApply: (deltas, items) {
                        lastCurrencyDeltas = deltas;
                        lastItems = items;
                      },
                    ),
                    child: const Text('Ouvrir'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ajouter un objet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Depuis le catalogue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dague'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PrimaryButton, 'AJOUTER'));
      await tester.pumpAndSettle();

      expect(find.text('Dague × 1'), findsOneWidget);

      await tester.tap(
        find.widgetWithText(PrimaryButton, 'AJOUTER LA RÉCOMPENSE'),
      );
      await tester.pumpAndSettle();

      expect(lastCurrencyDeltas, isEmpty);
      expect(lastItems, hasLength(1));
      expect(lastItems!.single.itemId, 1);
      expect(lastItems!.single.customName, isNull);
      expect(lastItems!.single.quantity, 1);
      expect(lastItems!.single.isCustom, isFalse);
    },
  );
}
