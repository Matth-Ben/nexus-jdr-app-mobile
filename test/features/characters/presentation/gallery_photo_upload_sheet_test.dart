// Tests de widget du bottom sheet "Ajouter une photo"
// (`presentation/widgets/gallery_photo_upload_sheet.dart`), ouvert depuis la
// tuile "+" de la carte "Galerie" de l'onglet "Histoire"
// (`character_gallery_card.dart`).
//
// Comme pour `portrait_upload_sheet.dart` (voir la documentation de classe
// de `character_gallery_card_test.dart`), le flux d'upload réel
// (`image_picker` pour les actions "Prendre une photo"/"Choisir dans la
// galerie") n'est pas exercé ici — aucune couverture préexistante dans ce
// dépôt pour ce sheet, ce fichier se limite au rendu des 3 actions et au
// dialogue "Utiliser une URL" (flux "URL invalide", déterministe, sans appel
// réseau réel : `fetchPortraitBytesFromUrl` lève synchronement avant toute
// E/S dès que l'URL n'a ni schéma ni autorité).

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/characters/domain/inventory_catalog_item.dart';
import 'package:personnages/features/characters/domain/level_up_apply_result.dart';
import 'package:personnages/features/characters/domain/level_up_arcane_shot_option.dart';
import 'package:personnages/features/characters/domain/level_up_choice_selection.dart';
import 'package:personnages/features/characters/domain/level_up_draconic_ancestry_option.dart';
import 'package:personnages/features/characters/domain/level_up_elemental_discipline_option.dart';
import 'package:personnages/features/characters/domain/level_up_feat_option.dart';
import 'package:personnages/features/characters/domain/level_up_infusion_option.dart';
import 'package:personnages/features/characters/domain/level_up_infusion_swap.dart';
import 'package:personnages/features/characters/domain/level_up_invocation_option.dart';
import 'package:personnages/features/characters/domain/level_up_level_data.dart';
import 'package:personnages/features/characters/domain/level_up_maneuver_option.dart';
import 'package:personnages/features/characters/domain/level_up_metamagic_option.dart';
import 'package:personnages/features/characters/domain/level_up_metamagic_swap.dart';
import 'package:personnages/features/characters/domain/level_up_rune_option.dart';
import 'package:personnages/features/characters/domain/reward_item_draft.dart';
import 'package:personnages/features/characters/domain/rest_type.dart';
import 'package:personnages/features/characters/domain/weapon_slot.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/features/characters/presentation/widgets/gallery_photo_upload_sheet.dart';
import 'package:personnages/l10n/app_localizations.dart';

class _FakeCharacterRepository implements CharacterRepository {
  int addGalleryPhotoCallCount = 0;
  Uint8List? lastBytes;
  Object? errorToThrow;

  @override
  Future<void> addGalleryPhoto({
    required String characterId,
    required Uint8List bytes,
  }) async {
    addGalleryPhotoCallCount++;
    lastBytes = bytes;
    if (errorToThrow != null) throw errorToThrow!;
  }

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
    String? description,
    String? damageDice,
    String? damageType,
    List<String> properties = const [],
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
  Future<WriteOutcome> setArmorClassBonus({
    required String characterId,
    required int bonus,
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
  Future<List<LevelUpElementalDisciplineOption>>
  fetchAvailableElementalDisciplines({
    required String characterId,
    required Object classId,
    required int subclassId,
    required int targetLevel,
  }) async => throw UnimplementedError();

  @override
  Future<List<LevelUpManeuverOption>> fetchAvailableManeuvers({
    required String characterId,
    required Object classId,
    required int subclassId,
    required int targetLevel,
  }) async => throw UnimplementedError();

  @override
  Future<List<LevelUpArcaneShotOption>> fetchAvailableArcaneShots({
    required String characterId,
    required Object classId,
    required int subclassId,
    required int targetLevel,
  }) async => throw UnimplementedError();

  @override
  Future<List<LevelUpRuneOption>> fetchAvailableRunes({
    required String characterId,
    required Object classId,
    required int subclassId,
    required int targetLevel,
  }) async => throw UnimplementedError();

  @override
  Future<List<LevelUpInfusionOption>> fetchAvailableInfusions({
    required String characterId,
    required Object classId,
    required int targetLevel,
  }) async => throw UnimplementedError();

  @override
  Future<List<String>> fetchKnownInfusionNames({
    required String characterId,
  }) async => throw UnimplementedError();

  @override
  Future<List<LevelUpMetamagicOption>> fetchAvailableMetamagicOptions({
    required String characterId,
    required Object classId,
    required int targetLevel,
  }) async => throw UnimplementedError();

  @override
  Future<List<String>> fetchKnownMetamagicNames({
    required String characterId,
    required Object classId,
  }) async => throw UnimplementedError();

  @override
  Future<List<LevelUpDraconicAncestryOption>>
  fetchAvailableDraconicAncestryOptions({required Object subclassId}) async =>
      throw UnimplementedError();

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
    List<String> elementalDisciplineNames = const [],
    List<String> maneuverNames = const [],
    List<String> arcaneShotNames = const [],
    List<String> runeNames = const [],
    List<String> infusionNames = const [],
    LevelUpInfusionSwap? infusionSwap,
    List<String> metamagicNames = const [],
    LevelUpMetamagicSwap? metamagicSwap,
    List<int> expertiseSkillIds = const [],
    bool expertiseThievesToolsSubstitution = false,
    String? draconicAncestryDamageType,
    List<int> racialInnateSpellIds = const [],
  }) => throw UnimplementedError();

  @override
  Future<WriteOutcome> applyRest({
    required String characterId,
    required RestType type,
    required String className,
    Map<String, int> hitDiceSpentByClassId = const {},
    int appliedGain = 0,
    Map<String, int> hitDiceRecoveredByClassId = const {},
  }) => throw UnimplementedError();
}

Future<_FakeCharacterRepository> _pumpSheet(
  WidgetTester tester, {
  Locale locale = const Locale('fr'),
}) async {
  final repository = _FakeCharacterRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [characterRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: Consumer(
          builder: (context, ref, _) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showAddGalleryPhotoSheet(
                  context,
                  ref: ref,
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
  testWidgets('affiche les 3 actions ("Prendre une photo"/"Choisir dans la '
      'galerie"/"Utiliser une URL")', (tester) async {
    await _pumpSheet(tester);

    expect(find.text('Prendre une photo'), findsOneWidget);
    expect(find.text('Choisir dans la galerie'), findsOneWidget);
    expect(find.text('Utiliser une URL'), findsOneWidget);
  });

  testWidgets('"Utiliser une URL" : URL invalide affiche l\'erreur dans le '
      'dialogue, qui reste ouvert', (tester) async {
    await _pumpSheet(tester);

    await tester.tap(find.text('Utiliser une URL'));
    await tester.pumpAndSettle();

    expect(find.text('URL de la photo'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'pas une url');
    await tester.tap(find.widgetWithText(PrimaryButton, 'SUIVANT'));
    await tester.pumpAndSettle();

    expect(find.text('URL invalide.'), findsOneWidget);
    expect(find.text('URL de la photo'), findsOneWidget);
  });

  testWidgets(
    '"Utiliser une URL" : "Annuler" referme le dialogue sans erreur',
    (tester) async {
      await _pumpSheet(tester);

      await tester.tap(find.text('Utiliser une URL'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(SecondaryButton, 'ANNULER'));
      await tester.pumpAndSettle();

      expect(find.text('URL de la photo'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'actions, dialogue "Use a URL" (titre, placeholder, boutons) et erreur '
    '"URL invalide." (non traduite, voir D147) en anglais',
    (tester) async {
      await _pumpSheet(tester, locale: const Locale('en'));

      expect(find.text('Take a photo'), findsOneWidget);
      expect(find.text('Choose from gallery'), findsOneWidget);
      expect(find.text('Use a URL'), findsOneWidget);

      await tester.tap(find.text('Use a URL'));
      await tester.pumpAndSettle();

      expect(find.text('Photo URL'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).decoration?.hintText,
        'https://...',
      );

      await tester.enterText(find.byType(TextField), 'pas une url');
      await tester.tap(find.widgetWithText(PrimaryButton, 'NEXT'));
      await tester.pumpAndSettle();

      // `PortraitUrlFetchFailure.message` vient de `data/portrait_url_fetcher
      // .dart` (sans `BuildContext`) : reste figé en français même en
      // anglais — voir D147 du registre de dette technique.
      expect(find.text('URL invalide.'), findsOneWidget);

      await tester.tap(find.widgetWithText(SecondaryButton, 'CANCEL'));
      await tester.pumpAndSettle();

      expect(find.text('Photo URL'), findsNothing);
    },
  );
}
