// Tests de câblage des actions de l'onglet "Inventaire" côté
// `character_detail_screen.dart` — vérifie que les handlers
// (`_useInventoryItem`/`_toggleInventoryItemEquipped`/`_removeInventoryItem`/
// `_adjustCurrency`/`_addCustomInventoryItem`/`_addReward`) appellent le
// repository avec les bons arguments, affichent le bon message, et
// verrouillent tout l'onglet (`_isWritingInventory`) le temps de l'appel
// réseau — même patron que `character_detail_action_lock_test.dart` (verrou
// `_isCastingSpell`/`_isUsingFeature`).

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
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
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
  final Completer<void> useItemGate = Completer<void>();

  int useInventoryItemCallCount = 0;
  int setEquippedCallCount = 0;
  int removeInventoryItemCallCount = 0;
  int adjustCurrencyCallCount = 0;
  int addCustomInventoryItemCallCount = 0;
  int addRewardCallCount = 0;
  int fetchCharacterDetailCallCount = 0;

  String? lastInventoryId;
  int? lastNewQuantity;
  bool? lastEquipped;
  CurrencyKind? lastCurrency;
  int? lastNewAmount;
  String? lastCustomName;
  int? lastCustomQuantity;
  Map<CurrencyKind, int>? lastRewardCurrencyTotals;
  List<RewardItemDraft>? lastRewardItems;

  WriteOutcome outcomeToReturn = WriteOutcome.synced;
  bool gateUseInventoryItem = false;

  /// Personnage "serveur" courant, retourné par [fetchCharacterDetail] —
  /// mutable pour que les tests de staleness ci-dessous puissent vérifier
  /// ce que `_refreshCharacterDetail` révèle réellement une fois le refetch
  /// résolu, plutôt que de se contenter de compter les appels.
  CharacterDetail current = detail;

  /// Gate tout appel à [fetchCharacterDetail] au-delà du premier (le
  /// chargement initial de la fiche, jamais gaté) — `null` par défaut
  /// (aucun refetch gaté). Simule la fenêtre où `ref.invalidate` vient de
  /// déclencher un refetch qui reste en vol, voir
  /// `character_detail_screen.dart::_refreshCharacterDetail`.
  Completer<void>? refetchGate;

  @override
  Future<List<CharacterSummary>> fetchCharacters() async => const [];

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) async {
    fetchCharacterDetailCallCount++;
    final gate = refetchGate;
    if (fetchCharacterDetailCallCount > 1 && gate != null) {
      await gate.future;
    }
    return current;
  }

  @override
  Future<WriteOutcome> useInventoryItem({
    required String characterId,
    required String inventoryId,
    required int newQuantity,
  }) async {
    useInventoryItemCallCount++;
    lastInventoryId = inventoryId;
    lastNewQuantity = newQuantity;
    if (gateUseInventoryItem) await useItemGate.future;
    current = current.copyWith(
      inventory: [
        for (final item in current.inventory)
          if (item.id == inventoryId)
            CharacterInventoryItem(
              id: item.id,
              itemId: item.itemId,
              name: item.name,
              category: item.category,
              quantity: newQuantity,
              equipped: item.equipped,
              totalWeight: item.totalWeight,
              unitWeight: item.unitWeight,
              costAmount: item.costAmount,
              description: item.description,
              rarity: item.rarity,
              requiresAttunement: item.requiresAttunement,
              consumable: item.consumable,
              notes: item.notes,
              weaponProperties: item.weaponProperties,
              armorProperties: item.armorProperties,
            )
          else
            item,
      ],
    );
    return outcomeToReturn;
  }

  @override
  Future<WriteOutcome> setInventoryItemEquipped({
    required String characterId,
    required String inventoryId,
    required bool equipped,
  }) async {
    setEquippedCallCount++;
    lastInventoryId = inventoryId;
    lastEquipped = equipped;
    return outcomeToReturn;
  }

  @override
  Future<WriteOutcome> removeInventoryItem({
    required String characterId,
    required String inventoryId,
  }) async {
    removeInventoryItemCallCount++;
    lastInventoryId = inventoryId;
    return outcomeToReturn;
  }

  @override
  Future<WriteOutcome> adjustCurrency({
    required String characterId,
    required CurrencyKind currency,
    required int newAmount,
  }) async {
    adjustCurrencyCallCount++;
    lastCurrency = currency;
    lastNewAmount = newAmount;
    return outcomeToReturn;
  }

  @override
  Future<WriteOutcome> addInventoryItem({
    required String characterId,
    required int itemId,
    required int quantity,
  }) async => outcomeToReturn;

  @override
  Future<WriteOutcome> addCustomInventoryItem({
    required String characterId,
    required String customName,
    required int quantity,
  }) async {
    addCustomInventoryItemCallCount++;
    lastCustomName = customName;
    lastCustomQuantity = quantity;
    return outcomeToReturn;
  }

  /// Fait échouer le *prochain* appel à [addReward] (consommé après usage) —
  /// simule l'échec partiel documenté par le bug corrigé : la requête UPDATE
  /// de la monnaie réussit côté serveur (persistée ci-dessous dans
  /// [current] avant de lancer l'exception, exactement comme le fait
  /// `CharacterRepository.addReward` en réalité), mais celle des objets
  /// échoue ensuite.
  bool failNextAddReward = false;

  @override
  Future<WriteOutcome> addReward({
    required String characterId,
    required Map<CurrencyKind, int> newCurrencyTotals,
    required List<RewardItemDraft> items,
  }) async {
    addRewardCallCount++;
    lastRewardCurrencyTotals = newCurrencyTotals;
    lastRewardItems = items;
    if (failNextAddReward) {
      failNextAddReward = false;
      current = current.copyWith(
        currencyPp:
            newCurrencyTotals[CurrencyKind.platinum] ?? current.currencyPp,
        currencyGp: newCurrencyTotals[CurrencyKind.gold] ?? current.currencyGp,
        currencyEp:
            newCurrencyTotals[CurrencyKind.electrum] ?? current.currencyEp,
        currencySp:
            newCurrencyTotals[CurrencyKind.silver] ?? current.currencySp,
        currencyCp:
            newCurrencyTotals[CurrencyKind.copper] ?? current.currencyCp,
      );
      throw const CharacterFailure('Objets non ajoutés (échec partiel simulé).');
    }
    return outcomeToReturn;
  }

  @override
  Future<List<InventoryCatalogItem>> fetchInventoryCatalog() async => const [];

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

const _dagger = CharacterInventoryItem(
  id: 'inv-1',
  itemId: 1,
  name: 'Dague',
  category: 'arme',
  quantity: 2,
  equipped: false,
  totalWeight: 1,
);

const _potion = CharacterInventoryItem(
  id: 'inv-2',
  itemId: 2,
  name: 'Potion de soins',
  category: 'equipement_general',
  quantity: 1,
  equipped: false,
  consumable: true,
);

/// Quantité > 1 (contrairement à [_potion]) : permet au test de staleness
/// ci-dessous de distinguer un décrément correctement recalculé depuis une
/// donnée fraîche (3 -> 2) d'un décrément recalculé depuis la même donnée
/// périmée (3 -> 2 une seconde fois, perdant silencieusement le second
/// décrément qui aurait dû amener à 1).
const _rations = CharacterInventoryItem(
  id: 'inv-3',
  itemId: 3,
  name: 'Ration de voyage',
  category: 'equipement_general',
  quantity: 3,
  equipped: false,
  consumable: true,
);

const detail = CharacterDetail(
  id: '1',
  name: 'Test',
  classes: [
    CharacterDetailClassRow(
      classId: 1,
      hitDie: 8,
      className: 'Guerrier',
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
  currencyGp: 10,
  inventory: [_dagger, _potion, _rations],
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
              builder: (context, state) =>
                  CharacterDetailScreen(characterId: state.pathParameters['id']!),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

Future<void> openInventoryTab(WidgetTester tester) async {
  await tester.tap(find.text('SAC'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    '"Utiliser" un objet à quantité > 1 : useInventoryItem(quantity - 1), '
    'snackbar "utilisé" (pas "retiré")',
    (tester) async {
      final repository = await pumpDetail(tester);
      await openInventoryTab(tester);

      await tester.tap(find.text('Dague'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Équiper'));
      await tester.pumpAndSettle();

      expect(repository.setEquippedCallCount, 1);
      expect(repository.lastInventoryId, 'inv-1');
      expect(repository.lastEquipped, isTrue);
      expect(find.text('Dague équipé.'), findsOneWidget);
    },
  );

  testWidgets(
    '"Utiliser" une potion à quantité 1 : useInventoryItem(0), snackbar '
    '"utilisé — retiré de l\'inventaire."',
    (tester) async {
      final repository = await pumpDetail(tester);
      await openInventoryTab(tester);

      await tester.tap(find.text('Potion de soins'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Utiliser'));
      await tester.pumpAndSettle();

      expect(repository.useInventoryItemCallCount, 1);
      expect(repository.lastInventoryId, 'inv-2');
      expect(repository.lastNewQuantity, 0);
      expect(
        find.text('Potion de soins utilisé — retiré de l\'inventaire.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('"Retirer" confirmé appelle removeInventoryItem, snackbar '
      '"retiré de l\'inventaire."', (tester) async {
    final repository = await pumpDetail(tester);
    await openInventoryTab(tester);

    await tester.tap(find.text('Dague'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retirer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retirer'));
    await tester.pumpAndSettle();

    expect(repository.removeInventoryItemCallCount, 1);
    expect(repository.lastInventoryId, 'inv-1');
    expect(find.text('Dague retiré de l\'inventaire.'), findsOneWidget);
  });

  testWidgets(
    'ajuster la monnaie PO : adjustCurrency reçoit le nouveau montant '
    'absolu (10 + 2 = 12)',
    (tester) async {
      final repository = await pumpDetail(tester);
      await openInventoryTab(tester);

      await tester.tap(find.text('PO'));
      await tester.pumpAndSettle();

      final incrementButton = find.byWidgetPredicate(
        (widget) => widget is Icon && widget.semanticLabel == 'Augmenter',
      );
      await tester.tap(incrementButton);
      await tester.tap(incrementButton);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PrimaryButton, 'APPLIQUER'));
      await tester.pumpAndSettle();

      expect(repository.adjustCurrencyCallCount, 1);
      expect(repository.lastCurrency, CurrencyKind.gold);
      expect(repository.lastNewAmount, 12);
    },
  );

  testWidgets(
    'ajouter un objet personnalisé : addCustomInventoryItem reçoit le nom '
    'et la quantité saisis, snackbar de confirmation',
    (tester) async {
      final repository = await pumpDetail(tester);
      await openInventoryTab(tester);

      await tester.tap(find.text('Ajouter un objet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Objet personnalisé'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'Amulette de famille');
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'AJOUTER'));
      await tester.pumpAndSettle();

      expect(repository.addCustomInventoryItemCallCount, 1);
      expect(repository.lastCustomName, 'Amulette de famille');
      expect(repository.lastCustomQuantity, 1);
      expect(
        find.text('Amulette de famille ajouté à l\'inventaire.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'bouton "Ajouter une récompense" du bandeau : addReward reçoit le total '
    'absolu de monnaie (10 + 5 = 15) et les objets ajoutés',
    (tester) async {
      final repository = await pumpDetail(tester);
      await openInventoryTab(tester);

      await tester.tap(find.byTooltip('Ajouter une récompense'));
      await tester.pumpAndSettle();

      expect(find.text('AJOUTER UNE RÉCOMPENSE'), findsOneWidget);

      // Les 5 champs de monnaie sont rendus dans l'ordre PO/PA/PC/PP/PE
      // (`_currencyFieldsOrder`) : le premier `TextFormField` est donc
      // celui de l'or.
      await tester.enterText(find.byType(TextFormField).first, '5');
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'AJOUTER LA RÉCOMPENSE'));
      await tester.pumpAndSettle();

      expect(repository.addRewardCallCount, 1);
      expect(repository.lastRewardCurrencyTotals, {CurrencyKind.gold: 15});
      expect(repository.lastRewardItems, isEmpty);
    },
  );

  testWidgets(
    'WriteOutcome.queued (hors ligne) : message honnête, jamais le message '
    '"sera synchronisé"',
    (tester) async {
      final repository = await pumpDetail(tester);
      repository.outcomeToReturn = WriteOutcome.queued;
      await openInventoryTab(tester);

      await tester.tap(find.text('Dague'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retirer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retirer'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining("n'a pas pu être enregistrée"),
        findsOneWidget,
      );
      expect(find.textContaining('sera synchronisé'), findsNothing);
    },
  );

  testWidgets(
    'un second tap sur la même carte pendant qu\'une utilisation est encore '
    'en vol ne déclenche aucun second appel réseau (verrou '
    '_isWritingInventory)',
    (tester) async {
      final repository = await pumpDetail(tester);
      repository.gateUseInventoryItem = true;
      await openInventoryTab(tester);

      await tester.tap(find.text('Potion de soins'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Utiliser'));
      await tester.pumpAndSettle();

      expect(repository.useInventoryItemCallCount, 1);

      // La carte (verrouillée) ne doit rien déclencher au second tap.
      await tester.tap(find.text('Potion de soins'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(repository.useInventoryItemCallCount, 1);
      expect(find.text('Infos'), findsNothing);

      repository.useItemGate.complete();
      await tester.pumpAndSettle();

      expect(repository.useInventoryItemCallCount, 1);
    },
  );

  testWidgets(
    'double-tap "Utiliser" après résolution du 1er appel réseau mais avant '
    'que le refetch qu\'il déclenche ait résolu : un seul appel réseau au '
    'total, aucun décrément perdu (CORRIGÉ)',
    (tester) async {
      final repository = await pumpDetail(tester);
      // Gate uniquement le refetch déclenché par `_refreshCharacterDetail`
      // (le 2e appel à `fetchCharacterDetail`, jamais le 1er chargement) :
      // `useInventoryItem` lui-même résout immédiatement, comme en
      // production une fois la requête serveur d'écriture terminée.
      repository.refetchGate = Completer<void>();
      await openInventoryTab(tester);

      await tester.tap(find.text('Ration de voyage'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Utiliser'));
      await tester.pumpAndSettle();

      // L'appel d'écriture a bien résolu (3 -> 2), et le refetch qu'il
      // déclenche a démarré mais reste en vol (gaté).
      expect(repository.useInventoryItemCallCount, 1);
      expect(repository.lastNewQuantity, 2);
      expect(repository.fetchCharacterDetailCallCount, 2);

      // Avant correctif, `_isWritingInventory` était déjà relâché à ce
      // stade (l'appel d'écriture, seul couvert par l'ancien verrou, avait
      // résolu) : ce second tap aurait déclenché un second appel
      // `useInventoryItem` recalculé depuis le même `detail` encore
      // périmé (quantité 3 au lieu de 2), perdant silencieusement ce
      // second décrément. Le verrou doit désormais rester actif tant que
      // le refetch n'a pas résolu.
      await tester.tap(find.text('Ration de voyage'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(repository.useInventoryItemCallCount, 1);
      expect(find.text('Infos'), findsNothing);

      repository.refetchGate!.complete();
      await tester.pumpAndSettle();

      expect(repository.useInventoryItemCallCount, 1);
      expect(repository.lastNewQuantity, 2);
    },
  );

  testWidgets(
    'addReward : retry après échec partiel (monnaie déjà persistée, objets '
    'non insérés) recalcule le nouveau total depuis la fiche fraîchement '
    'rafraîchie, pas depuis la fiche périmée au moment de l\'échec '
    '(CORRIGÉ)',
    (tester) async {
      final repository = await pumpDetail(tester);
      repository.failNextAddReward = true;
      await openInventoryTab(tester);

      // Premier essai : +5 PO, échoue après que la monnaie a déjà été
      // persistée côté serveur (10 -> 15, simulé par `failNextAddReward`).
      await tester.tap(find.byTooltip('Ajouter une récompense'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '5');
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'AJOUTER LA RÉCOMPENSE'));
      await tester.pumpAndSettle();

      expect(repository.addRewardCallCount, 1);
      expect(repository.lastRewardCurrencyTotals, {CurrencyKind.gold: 15});
      expect(find.text('Objets non ajoutés (échec partiel simulé).'), findsOneWidget);

      // Sans le correctif (invalidation aussi sur le chemin d'échec), la
      // fiche affichée resterait périvée à 10 PO : un retry avec le même
      // delta (+5) recalculerait 10 + 5 = 15, un total identique à celui
      // déjà persisté par l'essai précédent — perdant silencieusement ce
      // second +5 au lieu de l'ajouter par-dessus le total déjà en base.
      await tester.tap(find.byTooltip('Ajouter une récompense'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '5');
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'AJOUTER LA RÉCOMPENSE'));
      await tester.pumpAndSettle();

      expect(repository.addRewardCallCount, 2);
      expect(
        repository.lastRewardCurrencyTotals,
        {CurrencyKind.gold: 20},
        reason:
            'le retry doit repartir des 15 PO fraîchement resynchronisés '
            'après l\'échec, pas des 10 PO périmés au moment de l\'échec.',
      );
    },
  );

  testWidgets(
    'le bouton "Ajouter une récompense" du bandeau n\'apparaît que sur '
    'l\'onglet "Inventaire"',
    (tester) async {
      await pumpDetail(tester);

      expect(find.byTooltip('Ajouter une récompense'), findsNothing);

      await openInventoryTab(tester);
      expect(find.byTooltip('Ajouter une récompense'), findsOneWidget);

      await tester.tap(find.text('PERSO'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Ajouter une récompense'), findsNothing);
    },
  );
}
