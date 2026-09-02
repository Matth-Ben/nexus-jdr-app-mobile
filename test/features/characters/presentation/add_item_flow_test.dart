// Tests de widget des sheets "+ Ajouter un objet"
// (`presentation/widgets/add_item_flow.dart`) — entrée à 2 choix, sheet
// "Depuis le catalogue" (recherche + regroupement par catégorie + sheet de
// quantité), sheet "Objet personnalisé".

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
import 'package:personnages/features/characters/presentation/widgets/add_item_flow.dart';

class FakeRepository implements CharacterRepository {
  FakeRepository({this.catalog = const [], this.throwOnFetch = false});

  final List<InventoryCatalogItem> catalog;
  final bool throwOnFetch;

  @override
  Future<List<InventoryCatalogItem>> fetchInventoryCatalog() async {
    if (throwOnFetch) {
      throw Exception('boom');
    }
    return catalog;
  }

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
}

const _dagger = InventoryCatalogItem(
  id: 1,
  name: 'Dague',
  category: 'arme',
  costAmount: 2,
  weight: 0.5,
);

const _kit = InventoryCatalogItem(
  id: 2,
  name: 'Kit de crochetage',
  category: 'outil',
  costAmount: 25,
);

/// Monte un bouton "Ouvrir" qui déclenche [pickInventoryAddition] — utilisé
/// par les tests qui n'ont pas besoin d'inspecter le résultat final (états
/// intermédiaires des sheets), voir les tests dédiés plus bas pour ceux qui
/// vérifient le résultat retourné.
Future<void> _pumpAndPick(
  WidgetTester tester, {
  required FakeRepository repository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [characterRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => pickInventoryAddition(context),
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
}

void main() {
  testWidgets('sheet d\'entrée : 2 choix "Depuis le catalogue"/"Objet '
      'personnalisé"', (tester) async {
    await _pumpAndPick(tester, repository: FakeRepository());

    expect(find.text('Depuis le catalogue'), findsOneWidget);
    expect(find.text('Objet personnalisé'), findsOneWidget);
  });

  group('sheet "Depuis le catalogue"', () {
    testWidgets('groupe les objets par catégorie, tri alpha à l\'intérieur, '
        'sous-titre coût/poids', (tester) async {
      await _pumpAndPick(
        tester,
        repository: FakeRepository(catalog: const [_dagger, _kit]),
      );
      await tester.tap(find.text('Depuis le catalogue'));
      await tester.pumpAndSettle();

      expect(find.text('AJOUTER UN OBJET'), findsOneWidget);
      expect(find.text('ARME'), findsOneWidget);
      expect(find.text('OUTIL'), findsOneWidget);
      expect(find.text('Dague'), findsOneWidget);
      expect(find.text('2 po · 0,5 kg'), findsOneWidget);
      expect(find.text('Kit de crochetage'), findsOneWidget);
      // Pas de poids connu -> pas de "· X kg" dans le sous-titre.
      expect(find.text('25 po'), findsOneWidget);
    });

    testWidgets('le champ de recherche filtre la liste', (tester) async {
      await _pumpAndPick(
        tester,
        repository: FakeRepository(catalog: const [_dagger, _kit]),
      );
      await tester.tap(find.text('Depuis le catalogue'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'crochet');
      await tester.pump();

      expect(find.text('Dague'), findsNothing);
      expect(find.text('Kit de crochetage'), findsOneWidget);
    });

    testWidgets('tap sur une ligne ouvre la sheet de quantité, "Ajouter" '
        'ferme les 2 sheets et retourne le résultat', (tester) async {
      PickedInventoryAddition? result;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            characterRepositoryProvider.overrideWithValue(
              FakeRepository(catalog: const [_dagger]),
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      result = await pickInventoryAddition(context);
                    },
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
      await tester.tap(find.text('Depuis le catalogue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dague'));
      await tester.pumpAndSettle();

      expect(find.text('Ajouter Dague'), findsOneWidget);

      final incrementButton = find.byWidgetPredicate(
        (widget) => widget is Icon && widget.semanticLabel == 'Augmenter',
      );
      await tester.tap(incrementButton);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PrimaryButton, 'AJOUTER'));
      await tester.pumpAndSettle();

      // Les 2 sheets sont fermées.
      expect(find.text('Ajouter Dague'), findsNothing);
      expect(find.text('AJOUTER UN OBJET'), findsNothing);

      expect(result, isNotNull);
      expect(result!.isCustom, isFalse);
      expect(result!.item, _dagger);
      expect(result!.quantity, 2);
      expect(result!.displayName, 'Dague');
    });

    testWidgets('un catalogue vide affiche un état vide, pas une erreur', (
      tester,
    ) async {
      await _pumpAndPick(tester, repository: FakeRepository());
      await tester.tap(find.text('Depuis le catalogue'));
      await tester.pumpAndSettle();

      expect(find.text('Aucun objet trouvé.'), findsOneWidget);
    });

    testWidgets('une erreur de chargement affiche un état d\'erreur avec '
        'bouton "Réessayer"', (tester) async {
      await _pumpAndPick(
        tester,
        repository: FakeRepository(throwOnFetch: true),
      );
      await tester.tap(find.text('Depuis le catalogue'));
      await tester.pumpAndSettle();

      expect(find.text('RÉESSAYER'), findsOneWidget);
    });
  });

  group('sheet "Objet personnalisé"', () {
    testWidgets('bouton "Ajouter" désactivé tant que le nom est vide', (
      tester,
    ) async {
      await _pumpAndPick(tester, repository: FakeRepository());
      await tester.tap(find.text('Objet personnalisé'));
      await tester.pumpAndSettle();

      final button = tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, 'AJOUTER'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('retourne le nom saisi et la quantité (défaut 1)', (
      tester,
    ) async {
      PickedInventoryAddition? result;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            characterRepositoryProvider.overrideWithValue(FakeRepository()),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      result = await pickInventoryAddition(context);
                    },
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
      await tester.tap(find.text('Objet personnalisé'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'Amulette de famille');
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'AJOUTER'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.isCustom, isTrue);
      expect(result!.customName, 'Amulette de famille');
      expect(result!.quantity, 1);
      expect(result!.displayName, 'Amulette de famille');
    });
  });
}
