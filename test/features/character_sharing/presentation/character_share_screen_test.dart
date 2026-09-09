// Tests de widget de l'écran "Partager le personnage" (gérer le lien).
//
// Deux dépôts de test injectés via `overrideWithValue` — même principe que
// `character_detail_screen_test.dart` : `_FakeCharacterRepository` pour
// `characterDetailProvider` (l'écran lit `detail.shareToken` depuis lui),
// `_FakeCharacterSharingRepository` pour `characterSharingRepositoryProvider`
// (les 3 opérations d'écriture du partage).

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/features/character_sharing/data/character_sharing_repository.dart';
import 'package:personnages/features/character_sharing/presentation/character_share_screen.dart';
import 'package:personnages/features/character_sharing/presentation/providers/character_sharing_providers.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/characters/domain/inventory_catalog_item.dart';
import 'package:personnages/features/characters/domain/level_up_apply_result.dart';
import 'package:personnages/features/characters/domain/level_up_choice_selection.dart';
import 'package:personnages/features/characters/domain/level_up_feat_option.dart';
import 'package:personnages/features/characters/domain/level_up_invocation_option.dart';
import 'package:personnages/features/characters/domain/level_up_level_data.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/characters/domain/rest_type.dart';
import 'package:personnages/features/characters/domain/reward_item_draft.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';

class _FakeCharacterRepository implements CharacterRepository {
  CharacterDetail? detailToReturn;

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) async =>
      detailToReturn ?? _baseDetail;

  @override
  Future<List<CharacterSummary>> fetchCharacters() async => const [];

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
  }) => throw UnimplementedError();

  @override
  Future<List<LevelUpInvocationOption>> fetchAvailableInvocations({
    required String characterId,
  }) => throw UnimplementedError();

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
}

class _FakeCharacterSharingRepository implements CharacterSharingRepository {
  String? tokenToReturn;
  Object? regenerateErrorToThrow;
  Object? disableErrorToThrow;
  int regenerateCallCount = 0;
  int disableCallCount = 0;

  @override
  Future<String> regenerateShareToken(String characterId) async {
    regenerateCallCount++;
    if (regenerateErrorToThrow != null) throw regenerateErrorToThrow!;
    return tokenToReturn ?? 'new-token-abc';
  }

  @override
  Future<void> disableShareToken(String characterId) async {
    disableCallCount++;
    if (disableErrorToThrow != null) throw disableErrorToThrow!;
  }

  @override
  Future<CharacterDetail?> fetchSharedCharacter(String token) =>
      throw UnimplementedError();
}

const _baseDetail = CharacterDetail(
  id: 'char-1',
  name: 'Halltesse Ambrelune',
  raceName: 'Elfe',
  classes: [
    CharacterDetailClassRow(
      classId: 1,
      hitDie: 8,
      className: 'Magicienne',
      level: 5,
      isPrimary: true,
      savingThrowProficiencies: ['int', 'wis'],
    ),
  ],
  xp: 0,
  currentHp: 18,
  maxHp: 30,
  temporaryHp: 0,
  abilityScores: {},
);

void main() {
  late _FakeCharacterRepository fakeCharacterRepository;
  late _FakeCharacterSharingRepository fakeSharingRepository;

  setUp(() {
    fakeCharacterRepository = _FakeCharacterRepository();
    fakeSharingRepository = _FakeCharacterSharingRepository();
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        characterRepositoryProvider.overrideWithValue(fakeCharacterRepository),
        characterSharingRepositoryProvider.overrideWithValue(
          fakeSharingRepository,
        ),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/characters/char-1/share',
          routes: [
            GoRoute(
              path: '/characters/:id/share',
              builder: (context, state) => CharacterShareScreen(
                characterId: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Surface de test agrandie : "Désactiver le partage"/le dialogue de
  // confirmation sont autrement hors du viewport 800×600 par défaut — même
  // ajustement que `character_detail_screen_test.dart`.
  Future<void> pumpShareScreen(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildTestWidget());
  }

  testWidgets(
    'partage inactif (shareToken null) : affiche "Activer le partage", pas '
    'de lien ni de zone dangereuse',
    (tester) async {
      fakeCharacterRepository.detailToReturn = _baseDetail;

      await pumpShareScreen(tester);
      await tester.pumpAndSettle();

      expect(find.text('ACTIVER LE PARTAGE'), findsOneWidget);
      expect(find.text('Partage actif'), findsNothing);
      expect(find.text('ZONE DANGEREUSE'), findsNothing);
    },
  );

  testWidgets(
    'tap "Activer le partage" appelle regenerateShareToken puis affiche le '
    'lien une fois la fiche rafraîchie',
    (tester) async {
      fakeCharacterRepository.detailToReturn = _baseDetail;
      fakeSharingRepository.tokenToReturn = 'tok-xyz';

      await pumpShareScreen(tester);
      await tester.pumpAndSettle();

      // Préparé avant le tap : `_regenerate` invalide `characterDetailProvider`
      // juste après le succès de la régénération, ce qui déclenche
      // immédiatement une nouvelle lecture de ce dépôt — la valeur doit donc
      // déjà refléter le partage actif à ce moment-là, pas après coup.
      fakeCharacterRepository.detailToReturn = _baseDetail.copyWith(
        shareToken: 'tok-xyz',
      );

      await tester.tap(find.text('ACTIVER LE PARTAGE'));
      await tester.pumpAndSettle();

      expect(fakeSharingRepository.regenerateCallCount, 1);
      expect(find.text('Partage actif'), findsOneWidget);
      expect(find.textContaining('nexus-jdr.app/p/tok-xyz'), findsOneWidget);
    },
  );

  testWidgets(
    'partage actif : affiche le lien, "Régénérer le lien" et la zone '
    'dangereuse avec "Désactiver le partage"',
    (tester) async {
      fakeCharacterRepository.detailToReturn = _baseDetail.copyWith(
        shareToken: 'existing-token',
      );

      await pumpShareScreen(tester);
      await tester.pumpAndSettle();

      expect(find.text('Partage actif'), findsOneWidget);
      expect(
        find.textContaining('nexus-jdr.app/p/existing-token'),
        findsOneWidget,
      );
      expect(find.text('Régénérer le lien'), findsOneWidget);
      expect(find.text('ZONE DANGEREUSE'), findsOneWidget);
      expect(find.text('Désactiver le partage'), findsOneWidget);
    },
  );

  testWidgets(
    'tap "Désactiver le partage" ouvre une confirmation ; confirmer appelle '
    'disableShareToken',
    (tester) async {
      fakeCharacterRepository.detailToReturn = _baseDetail.copyWith(
        shareToken: 'existing-token',
      );

      await pumpShareScreen(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Désactiver le partage'));
      await tester.pumpAndSettle();

      expect(find.text('Désactiver le partage ?'), findsOneWidget);
      expect(fakeSharingRepository.disableCallCount, 0);

      await tester.tap(find.text('Désactiver'));
      await tester.pumpAndSettle();

      expect(fakeSharingRepository.disableCallCount, 1);
    },
  );

  testWidgets(
    'annuler la confirmation de désactivation n\'appelle pas disableShareToken',
    (tester) async {
      fakeCharacterRepository.detailToReturn = _baseDetail.copyWith(
        shareToken: 'existing-token',
      );

      await pumpShareScreen(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Désactiver le partage'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      expect(fakeSharingRepository.disableCallCount, 0);
      // Toujours affiché : la sheet n'a pas désactivé le partage.
      expect(find.text('Partage actif'), findsOneWidget);
    },
  );

  testWidgets('échec de régénération affiche le message d\'erreur en SnackBar', (
    tester,
  ) async {
    fakeCharacterRepository.detailToReturn = _baseDetail;
    fakeSharingRepository.regenerateErrorToThrow = const CharacterFailure(
      'Ce personnage est introuvable ou ne vous appartient plus.',
    );

    await pumpShareScreen(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('ACTIVER LE PARTAGE'));
    await tester.pumpAndSettle();

    expect(
      find.text('Ce personnage est introuvable ou ne vous appartient plus.'),
      findsOneWidget,
    );
  });
}
