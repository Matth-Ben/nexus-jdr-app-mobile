// Tests de widget de la carte "Galerie" de l'onglet "Histoire" — voir
// `docs/cahier-des-charges/11-fonctionnalites-a-ajouter.md`, section
// "Onglet Histoire".
//
// `CharacterGalleryCard` porte elle-même l'ouverture de la sheet d'ajout et
// de la visionneuse plein écran (voir sa documentation de classe) : le
// dépôt de test (`_FakeCharacterRepository`) est injecté via
// `overrideWithValue`, même principe que `character_adventures_card_test
// .dart`. Le flux d'upload (`image_picker`) lui-même n'est pas exercé ici
// (pas de couverture existante non plus pour `portrait_upload_sheet.dart`
// dans ce dépôt) — ce fichier se limite au rendu de la carte, à la
// visionneuse plein écran et à `hasVisibleContent`.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_gallery_photo.dart';
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
import 'package:personnages/features/characters/presentation/widgets/character_gallery_card.dart';

class _FakeCharacterRepository implements CharacterRepository {
  int removeGalleryPhotoCallCount = 0;
  String? lastRemovedPhotoId;
  String? lastRemovedUrl;
  Object? removeErrorToThrow;

  @override
  Future<void> removeGalleryPhoto({
    required String characterId,
    required String photoId,
    required String url,
  }) async {
    removeGalleryPhotoCallCount++;
    lastRemovedPhotoId = photoId;
    lastRemovedUrl = url;
    if (removeErrorToThrow != null) throw removeErrorToThrow!;
  }

  @override
  Future<void> addGalleryPhoto({
    required String characterId,
    required Uint8List bytes,
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

CharacterDetail _detail({List<CharacterGalleryPhoto> galleryPhotos = const []}) {
  return CharacterDetail(
    id: '1',
    name: 'Test',
    classes: const [],
    xp: 0,
    currentHp: 10,
    maxHp: 10,
    temporaryHp: 0,
    abilityScores: const {},
    galleryPhotos: galleryPhotos,
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
          body: CharacterGalleryCard(
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

  final photo1 = CharacterGalleryPhoto(
    id: 'photo-1',
    url: 'https://example.com/1.png',
    createdAt: DateTime(2026, 9, 1),
  );
  final photo2 = CharacterGalleryPhoto(
    id: 'photo-2',
    url: 'https://example.com/2.png',
    createdAt: DateTime(2026, 9, 5),
  );

  testWidgets('affiche une vignette par photo, plus la tuile "+"', (
    tester,
  ) async {
    await _pump(tester, _detail(galleryPhotos: [photo1, photo2]), fakeRepository);

    expect(find.text('GALERIE'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(2));
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('inventaire vide : seule la tuile "+" est affichée', (
    tester,
  ) async {
    await _pump(tester, _detail(), fakeRepository);

    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('actionsDisabled : la tuile "+" n\'est jamais affichée', (
    tester,
  ) async {
    await _pump(
      tester,
      _detail(galleryPhotos: [photo1]),
      fakeRepository,
      actionsDisabled: true,
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);
  });

  testWidgets(
    'tap sur une vignette ouvre la visionneuse plein écran avec "Retirer '
    'cette photo"',
    (tester) async {
      await _pump(tester, _detail(galleryPhotos: [photo1]), fakeRepository);

      await tester.tap(find.byType(Image).first);
      await tester.pumpAndSettle();

      expect(find.text('Retirer cette photo'), findsOneWidget);
    },
  );

  testWidgets(
    'visionneuse : actionsDisabled masque "Retirer cette photo"',
    (tester) async {
      await _pump(
        tester,
        _detail(galleryPhotos: [photo1]),
        fakeRepository,
        actionsDisabled: true,
      );

      await tester.tap(find.byType(Image).first);
      await tester.pumpAndSettle();

      expect(find.text('Retirer cette photo'), findsNothing);
      // La croix de fermeture reste disponible en lecture seule.
      expect(find.byIcon(Icons.close), findsOneWidget);
    },
  );

  testWidgets(
    'visionneuse : "Retirer cette photo" confirmé appelle '
    'removeGalleryPhoto et referme la visionneuse',
    (tester) async {
      await _pump(tester, _detail(galleryPhotos: [photo1]), fakeRepository);

      await tester.tap(find.byType(Image).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retirer cette photo'));
      await tester.pumpAndSettle();

      expect(find.text('Retirer cette photo ?'), findsOneWidget);

      await tester.tap(find.text('Retirer').last);
      await tester.pumpAndSettle();

      expect(fakeRepository.removeGalleryPhotoCallCount, 1);
      expect(fakeRepository.lastRemovedPhotoId, 'photo-1');
      expect(fakeRepository.lastRemovedUrl, 'https://example.com/1.png');
      expect(find.text('Photo retirée.'), findsOneWidget);
      // La visionneuse s'est refermée : la croix n'est plus là.
      expect(find.byIcon(Icons.close), findsNothing);
    },
  );

  group('CharacterGalleryCard.hasVisibleContent', () {
    test('true avec au moins une photo, même en lecture seule', () {
      expect(
        CharacterGalleryCard.hasVisibleContent(
          _detail(galleryPhotos: [photo1]),
          actionsDisabled: true,
        ),
        isTrue,
      );
    });

    test('true sans photo si les actions sont actives (tuile "+")', () {
      expect(
        CharacterGalleryCard.hasVisibleContent(
          _detail(),
          actionsDisabled: false,
        ),
        isTrue,
      );
    });

    test('false sans photo en lecture seule (rien à ajouter/montrer)', () {
      expect(
        CharacterGalleryCard.hasVisibleContent(
          _detail(),
          actionsDisabled: true,
        ),
        isFalse,
      );
    });
  });
}
