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
import 'package:personnages/features/characters/domain/level_up_feat_option.dart';
import 'package:personnages/features/characters/domain/level_up_invocation_option.dart';
import 'package:personnages/features/characters/domain/level_up_choice_selection.dart';
import 'package:personnages/features/characters/domain/level_up_level_data.dart';
import 'package:personnages/features/characters/domain/rest_type.dart';
import 'package:personnages/features/characters/domain/reward_item_draft.dart';
import 'package:personnages/features/characters/domain/weapon_slot.dart';
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
  Future<WriteOutcome> setDead({
    required String characterId,
    required bool isDead,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> setArchived({
    required String characterId,
    required bool isArchived,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> deleteCharacter({required String characterId}) =>
      throw UnimplementedError();

  @override
  Future<WriteOutcome> setInspiration({
    required String characterId,
    required bool inspiration,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> setSpellFavorite({
    required String characterId,
    required int spellId,
    required bool isFavorite,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> setSpellPrepared({
    required String characterId,
    required int spellId,
    required bool prepared,
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
  }) => throw UnimplementedError();

  @override
  Future<void> addGalleryPhoto({
    required String characterId,
    required Uint8List bytes,
  }) => throw UnimplementedError();

  @override
  Future<void> removeGalleryPhoto({
    required String characterId,
    required String photoId,
    required String url,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> addJournalEntry({
    required String characterId,
    required String body,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> updateJournalEntry({
    required String characterId,
    required String entryId,
    required String body,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> removeJournalEntry({
    required String characterId,
    required String entryId,
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
    bool isPactSlot = false,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> setInnateSpellUsesSpent({
    required String characterId,
    required int spellId,
    required int usesSpent,
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
  Future<WriteOutcome> equipWeaponToSlot({
    required String characterId,
    required String inventoryId,
    required WeaponSlot slot,
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> setInventoryItemAttuned({
    required String characterId,
    required String inventoryId,
    required bool attuned,
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
  Future<WriteOutcome> applyRest({
    required String characterId,
    required RestType type,
    required String className,
    int diceSpent = 0,
    int appliedGain = 0,
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
    List<int> racialInnateSpellIds = const [],
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

const _kit = InventoryCatalogItem(
  id: 2,
  name: 'Kit de crochetage',
  category: 'outil',
  costAmount: 25,
);

const _epee = InventoryCatalogItem(
  id: 3,
  name: 'Épée longue',
  category: 'arme',
  costAmount: 10,
);

const _zanbato = InventoryCatalogItem(
  id: 4,
  name: 'Zanbato',
  category: 'arme',
  costAmount: 20,
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

    testWidgets('tri alphabétique normalisé (accents ignorés) à l\'intérieur '
        'd\'une catégorie, pas un compareTo brut', (tester) async {
      // Sous `String.compareTo` brut, "Épée longue" se classerait APRÈS
      // "Zanbato" (« É » a un point de code UTF-16 supérieur à « Z ») —
      // `FrenchTextNormalizer` corrige ce travers.
      await _pumpAndPick(
        tester,
        repository: FakeRepository(catalog: const [_zanbato, _epee]),
      );
      await tester.tap(find.text('Depuis le catalogue'));
      await tester.pumpAndSettle();

      final epeeCenter = tester.getCenter(find.text('Épée longue'));
      final zanbatoCenter = tester.getCenter(find.text('Zanbato'));
      expect(
        epeeCenter.dy,
        lessThan(zanbatoCenter.dy),
        reason: '"Épée longue" doit être affichée avant "Zanbato"',
      );
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

  group('sélection multiple (pickInventoryAdditions)', () {
    Future<List<PickedInventoryAddition>> Function() pumpMulti(
      WidgetTester tester,
    ) {
      List<PickedInventoryAddition>? result;
      return () async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              characterRepositoryProvider.overrideWithValue(
                FakeRepository(catalog: const [_dagger, _kit]),
              ),
            ],
            child: MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        result = await pickInventoryAdditions(context);
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
        return result ?? const [];
      };
    }

    testWidgets('coche plusieurs objets, ajuste une quantité, "Ajouter (2)" '
        'renvoie toute la sélection dans l\'ordre', (tester) async {
      List<PickedInventoryAddition>? result;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            characterRepositoryProvider.overrideWithValue(
              FakeRepository(catalog: const [_dagger, _kit]),
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      result = await pickInventoryAdditions(context);
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

      expect(find.text('AJOUTER DES OBJETS'), findsOneWidget);
      final addButton = tester.widget<PrimaryButton>(
        find.byType(PrimaryButton),
      );
      expect(addButton.onPressed, isNull);

      await tester.tap(find.text('Dague'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kit de crochetage'));
      await tester.pumpAndSettle();
      // Quantité de la dague : 1 -> 3.
      final increment = find.byWidgetPredicate(
        (widget) => widget is Icon && widget.semanticLabel == 'Augmenter',
      );
      await tester.tap(increment.first);
      await tester.pumpAndSettle();
      await tester.tap(increment.first);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(PrimaryButton, 'AJOUTER (2)'));
      await tester.pumpAndSettle();

      expect(find.text('AJOUTER DES OBJETS'), findsNothing);
      expect(result, isNotNull);
      expect(result!.map((pick) => pick.item), [_dagger, _kit]);
      expect(result!.map((pick) => pick.quantity), [3, 1]);
    });

    testWidgets('« − » à la quantité 1 retire l\'objet de la sélection', (
      tester,
    ) async {
      await pumpMulti(tester)();

      await tester.tap(find.text('Dague'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(PrimaryButton, 'AJOUTER (1)'), findsOneWidget);

      await tester.tap(
        find.byWidgetPredicate(
          (widget) => widget is Icon && widget.semanticLabel == 'Diminuer',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(PrimaryButton, 'AJOUTER'), findsOneWidget);
    });

    testWidgets('fermer la sheet sans valider renvoie une liste vide', (
      tester,
    ) async {
      List<PickedInventoryAddition>? result;
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
                      result = await pickInventoryAdditions(context);
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
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(result, isEmpty);
    });
  });
}
