// Tests de widget de la carte "Journal de campagne" de l'onglet "Histoire"
// — voir `docs/cahier-des-charges/11-fonctionnalites-a-ajouter.md`, section
// "Onglet Histoire".
//
// `CharacterJournalCard` porte elle-même les actions d'ajout/modification/
// suppression (voir sa documentation de classe) : le dépôt de test
// (`_FakeCharacterRepository`) est injecté via `overrideWithValue`, même
// principe que `character_adventures_card_test.dart`.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
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
import 'package:personnages/features/characters/presentation/widgets/character_journal_card.dart';

class _FakeCharacterRepository implements CharacterRepository {
  int addJournalEntryCallCount = 0;
  int updateJournalEntryCallCount = 0;
  int removeJournalEntryCallCount = 0;

  String? lastBody;
  String? lastEntryId;

  WriteOutcome outcomeToReturn = WriteOutcome.synced;
  Object? errorToThrow;

  @override
  Future<WriteOutcome> addJournalEntry({
    required String characterId,
    required String body,
  }) async {
    addJournalEntryCallCount++;
    lastBody = body;
    if (errorToThrow != null) throw errorToThrow!;
    return outcomeToReturn;
  }

  @override
  Future<WriteOutcome> updateJournalEntry({
    required String characterId,
    required String entryId,
    required String body,
  }) async {
    updateJournalEntryCallCount++;
    lastEntryId = entryId;
    lastBody = body;
    if (errorToThrow != null) throw errorToThrow!;
    return outcomeToReturn;
  }

  @override
  Future<WriteOutcome> removeJournalEntry({
    required String characterId,
    required String entryId,
  }) async {
    removeJournalEntryCallCount++;
    lastEntryId = entryId;
    if (errorToThrow != null) throw errorToThrow!;
    return outcomeToReturn;
  }

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
  Future<List<InventoryCatalogItem>> fetchInventoryCatalog() =>
      throw UnimplementedError();

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
  Future<WriteOutcome> addXp({required String characterId, required int newXp}) =>
      throw UnimplementedError();

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
  Future<void> applyRest({
    required String characterId,
    required RestType type,
    required String className,
    int diceSpent = 0,
    int appliedGain = 0,
  }) => throw UnimplementedError();
}

CharacterDetail _detail({List<CharacterJournalEntry> journalEntries = const []}) {
  return CharacterDetail(
    id: '1',
    name: 'Test',
    classes: const [],
    xp: 0,
    currentHp: 10,
    maxHp: 10,
    temporaryHp: 0,
    abilityScores: const {},
    journalEntries: journalEntries,
  );
}

Future<void> _pump(
  WidgetTester tester,
  CharacterDetail detail,
  _FakeCharacterRepository repository, {
  bool actionsDisabled = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [characterRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        home: Scaffold(
          body: CharacterJournalCard(
            detail: detail,
            actionsDisabled: actionsDisabled,
          ),
        ),
      ),
    ),
  );
}

void main() {
  late _FakeCharacterRepository fakeRepository;

  setUp(() {
    fakeRepository = _FakeCharacterRepository();
  });

  final entry1 = CharacterJournalEntry(
    id: 'entry-1',
    body: 'Première séance : rencontre au Chaudron fumant.',
    createdAt: DateTime(2026, 9, 1, 20, 0),
  );
  final entry2 = CharacterJournalEntry(
    id: 'entry-2',
    body: 'Combat contre les gobelins de la mine.',
    createdAt: DateTime(2026, 9, 8, 20, 30),
  );

  testWidgets('affiche une ligne par entrée (date + texte), séparées par un '
      'Divider', (tester) async {
    await _pump(tester, _detail(journalEntries: [entry2, entry1]), fakeRepository);

    expect(find.text('JOURNAL DE CAMPAGNE'), findsOneWidget);
    expect(
      find.text('Combat contre les gobelins de la mine.'),
      findsOneWidget,
    );
    expect(
      find.text('Première séance : rencontre au Chaudron fumant.'),
      findsOneWidget,
    );
    expect(find.text('8 septembre 2026 · 20:30'), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget);
  });

  testWidgets('tuile "Ajouter une note" ouvre la sheet, saisie + '
      'Enregistrer appelle addJournalEntry', (tester) async {
    await _pump(tester, _detail(), fakeRepository);

    await tester.tap(find.text('Ajouter une note'));
    await tester.pumpAndSettle();

    expect(find.text('AJOUTER UNE NOTE'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Butin trouvé : 50 po.');
    await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
    await tester.pumpAndSettle();

    expect(fakeRepository.addJournalEntryCallCount, 1);
    expect(fakeRepository.lastBody, 'Butin trouvé : 50 po.');
    expect(find.text('Note ajoutée.'), findsOneWidget);
  });

  testWidgets('Enregistrer avec un champ vide ne fait rien (aucun appel, '
      'sheet reste ouverte)', (tester) async {
    await _pump(tester, _detail(), fakeRepository);

    await tester.tap(find.text('Ajouter une note'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
    await tester.pumpAndSettle();

    expect(fakeRepository.addJournalEntryCallCount, 0);
    expect(find.text('AJOUTER UNE NOTE'), findsOneWidget);
  });

  testWidgets(
    'tap sur une ligne ouvre "Modifier"/"Supprimer" ; "Modifier" préremplit '
    'et appelle updateJournalEntry',
    (tester) async {
      await _pump(tester, _detail(journalEntries: [entry1]), fakeRepository);

      await tester.tap(
        find.text('Première séance : rencontre au Chaudron fumant.'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Modifier'), findsOneWidget);
      expect(find.text('Supprimer'), findsOneWidget);

      await tester.tap(find.text('Modifier'));
      await tester.pumpAndSettle();

      expect(find.text('MODIFIER LA NOTE'), findsOneWidget);
      expect(
        tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
        'Première séance : rencontre au Chaudron fumant.',
      );

      await tester.enterText(
        find.byType(TextFormField),
        'Première séance, corrigée.',
      );
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pumpAndSettle();

      expect(fakeRepository.updateJournalEntryCallCount, 1);
      expect(fakeRepository.lastEntryId, 'entry-1');
      expect(fakeRepository.lastBody, 'Première séance, corrigée.');
      expect(find.text('Note modifiée.'), findsOneWidget);
    },
  );

  testWidgets(
    '"Supprimer" ouvre une confirmation ; confirmer appelle '
    'removeJournalEntry',
    (tester) async {
      await _pump(tester, _detail(journalEntries: [entry1]), fakeRepository);

      await tester.tap(
        find.text('Première séance : rencontre au Chaudron fumant.'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();

      expect(find.text('Supprimer cette note ?'), findsOneWidget);

      await tester.tap(find.text('Supprimer').last);
      await tester.pumpAndSettle();

      expect(fakeRepository.removeJournalEntryCallCount, 1);
      expect(fakeRepository.lastEntryId, 'entry-1');
      expect(find.text('Note supprimée.'), findsOneWidget);
    },
  );

  testWidgets(
    'actionsDisabled : ni la tuile "Ajouter une note" ni le tap sur une '
    'ligne ne sont proposés',
    (tester) async {
      await _pump(
        tester,
        _detail(journalEntries: [entry1]),
        fakeRepository,
        actionsDisabled: true,
      );

      expect(find.text('Ajouter une note'), findsNothing);

      await tester.tap(
        find.text('Première séance : rencontre au Chaudron fumant.'),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(find.text('Modifier'), findsNothing);
      expect(find.text('Supprimer'), findsNothing);
    },
  );

  group('CharacterJournalCard.hasVisibleContent', () {
    test('true si au moins une entrée existe, même en lecture seule', () {
      expect(
        CharacterJournalCard.hasVisibleContent(
          _detail(journalEntries: [entry1]),
          actionsDisabled: true,
        ),
        isTrue,
      );
    });

    test('true sans entrée si les actions sont actives (tuile "Ajouter")', () {
      expect(
        CharacterJournalCard.hasVisibleContent(
          _detail(),
          actionsDisabled: false,
        ),
        isTrue,
      );
    });

    test('false sans entrée en lecture seule (rien à ajouter/montrer)', () {
      expect(
        CharacterJournalCard.hasVisibleContent(
          _detail(),
          actionsDisabled: true,
        ),
        isFalse,
      );
    });
  });
}
