// Tests de widget de la sheet "Ajouter une note"/"Modifier la note"
// (`presentation/widgets/character_journal_entry_edit_sheet.dart`) — pattern
// autoportant calqué sur `character_story_edit_sheet_test.dart` : bandeau
// d'erreur inline (échec réseau/hors-ligne/générique) avec texte saisi
// préservé, `closeEnabled` désactivé pendant la sauvegarde. Le cas "mode
// ajout, tap Enregistrer, succès" est déjà exercé de bout en bout par
// `character_journal_card_test.dart` — ce fichier se concentre sur les
// chemins d'échec propres à la sheet elle-même.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/core/widgets/sheet_header_bar.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/character_journal_entry.dart';
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
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/features/characters/presentation/widgets/character_journal_entry_edit_sheet.dart';

class FakeRepository implements CharacterRepository {
  final Completer<void> gate = Completer<void>();
  bool gateAdd = false;

  int addJournalEntryCallCount = 0;
  String? lastBody;
  WriteOutcome outcomeToReturn = WriteOutcome.synced;
  Object? errorToThrow;

  @override
  Future<WriteOutcome> addJournalEntry({
    required String characterId,
    required String body,
  }) async {
    addJournalEntryCallCount++;
    lastBody = body;
    if (gateAdd) await gate.future;
    final error = errorToThrow;
    if (error != null) throw error;
    return outcomeToReturn;
  }

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
  Future<List<InventoryCatalogItem>> fetchInventoryCatalog() async => const [];

  @override
  Future<void> applyRest({
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
  }) => throw UnimplementedError();
}

Future<FakeRepository> _pumpSheet(WidgetTester tester) async {
  final repository = FakeRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [characterRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showJournalEntryEditSheet(
                  context,
                  characterId: 'char-1',
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
  return repository;
}

void main() {
  testWidgets('mode ajout : titre "AJOUTER UNE NOTE", champ vide', (
    tester,
  ) async {
    await _pumpSheet(tester);

    expect(find.text('AJOUTER UNE NOTE'), findsOneWidget);
    final field = tester.widget<TextFormField>(find.byType(TextFormField));
    expect(field.controller!.text, isEmpty);
  });

  testWidgets(
    'pendant la sauvegarde : bouton "Enregistrer" en isLoading, "Annuler" '
    'et le X du SheetHeaderBar désactivés',
    (tester) async {
      final repository = await _pumpSheet(tester);
      repository.gateAdd = true;

      await tester.enterText(find.byType(TextFormField), 'Note de séance.');
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pump();

      final primaryButton = tester.widget<PrimaryButton>(
        find.byType(PrimaryButton),
      );
      expect(primaryButton.isLoading, isTrue);

      final secondaryButton = tester.widget<SecondaryButton>(
        find.widgetWithText(SecondaryButton, 'ANNULER'),
      );
      expect(secondaryButton.onPressed, isNull);

      final header = tester.widget<SheetHeaderBar>(find.byType(SheetHeaderBar));
      expect(header.closeEnabled, isFalse);

      repository.gate.complete();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'WriteOutcome.queued (hors ligne) : bandeau d\'alerte inline, sheet '
    'reste ouverte, texte saisi préservé',
    (tester) async {
      final repository = await _pumpSheet(tester);
      repository.outcomeToReturn = WriteOutcome.queued;

      await tester.enterText(find.byType(TextFormField), 'Note pas envoyée.');
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining("n'a pas pu être enregistrée"),
        findsOneWidget,
      );
      expect(
        tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
        'Note pas envoyée.',
      );
    },
  );

  testWidgets(
    'CharacterFailure : bandeau d\'alerte inline affiche failure.message, '
    'sheet reste ouverte, texte saisi préservé',
    (tester) async {
      final repository = await _pumpSheet(tester);
      repository.errorToThrow = const CharacterFailure('Erreur serveur.');

      await tester.enterText(find.byType(TextFormField), 'Note en cours.');
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pumpAndSettle();

      expect(find.text('Erreur serveur.'), findsOneWidget);
      expect(
        tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
        'Note en cours.',
      );
    },
  );

  testWidgets(
    'échec inattendu (pas une CharacterFailure) : bandeau générique',
    (tester) async {
      final repository = await _pumpSheet(tester);
      repository.errorToThrow = Exception('boom');

      await tester.enterText(find.byType(TextFormField), 'Note.');
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pumpAndSettle();

      expect(
        find.text("Impossible d'enregistrer cette note. Réessayez."),
        findsOneWidget,
      );
    },
  );

  testWidgets('"Annuler" ferme la sheet sans appeler addJournalEntry', (
    tester,
  ) async {
    final repository = await _pumpSheet(tester);

    await tester.tap(find.widgetWithText(SecondaryButton, 'ANNULER'));
    await tester.pumpAndSettle();

    expect(repository.addJournalEntryCallCount, 0);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('mode édition (entry non nul) : titre "MODIFIER LA NOTE", '
      'champ préempli', (tester) async {
    final repository = FakeRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [characterRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showJournalEntryEditSheet(
                    context,
                    characterId: 'char-1',
                    entry: CharacterJournalEntry(
                      id: 'entry-1',
                      body: 'Note existante.',
                      createdAt: DateTime(2026, 9, 1),
                    ),
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

    expect(find.text('MODIFIER LA NOTE'), findsOneWidget);
    expect(find.text('Note existante.'), findsOneWidget);
  });
}
