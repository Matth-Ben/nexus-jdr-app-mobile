// Tests de widget de l'ecran de recadrage de portrait
// (`presentation/widgets/portrait_crop_screen.dart`) - verrouillage pendant
// l'envoi, erreurs (`CharacterFailure`/generique), succes (upload +
// invalidation du provider + pop(true)), et blocage du geste retour Android
// pendant l'envoi via `PopScope(canPop: !_isUploading)`.
//
// Ecran original dont `features/profile/presentation/widgets/
// avatar_crop_screen.dart` est une copie volontaire (voir sa documentation
// de classe) - ce fichier est calque sur
// `test/features/profile/presentation/widgets/avatar_crop_screen_test.dart`,
// avec deux differences assumees :
// - pas de verification de connectivite avant l'upload (portrait_crop_screen
//   n'en fait aucune, contrairement a `AvatarCropScreen` - voir sa
//   documentation de classe pour le rationale inverse) ;
// - `_submit` capture l'image via `RenderRepaintBoundary.toImage()`, une
//   operation asynchrone reelle (hors de l'horloge simulee du test) - toute
//   interaction qui va jusqu'a cet appel doit passer par `tester.runAsync`,
//   sans quoi `pumpAndSettle` ne se termine jamais (timeout), meme rationale
//   que le fichier soeur.
//
// Ce fichier comble une lacune de couverture historique : aucun test de
// widget n'existait pour cet ecran avant ce chantier QA, ce qui avait laisse
// passer l'absence de `PopScope` corrigee ici (le geste retour systeme
// contournait auparavant le garde-fou `_isUploading`, qui ne couvrait que le
// bouton retour visible du `WoodBackHeader`).

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
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
import 'package:personnages/features/characters/presentation/widgets/portrait_crop_screen.dart';

final Uint8List _fakePngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGNgAAAAAgABSK+kc'
  'QAAAABJRU5ErkJggg==',
);

/// Seules `uploadPortrait`/`fetchCharacterDetail` sont exercées par
/// `PortraitCropScreen` (la seconde via `ref.invalidate` après succès, qui
/// ne déclenche un appel que si quelque chose observe encore le provider —
/// jamais le cas dans ces tests) : le reste de l'interface lève
/// `UnimplementedError`, même principe que `_FakeCharacterRepository` dans
/// `character_detail_screen_test.dart`.
class _FakeCharacterRepository implements CharacterRepository {
  final Completer<void> gate = Completer<void>();
  bool gateUploadPortrait = false;

  int uploadPortraitCallCount = 0;
  String? lastCharacterId;
  Uint8List? lastBytes;
  Object? errorToThrow;

  @override
  Future<String> uploadPortrait({
    required String characterId,
    required Uint8List bytes,
  }) async {
    uploadPortraitCallCount++;
    lastCharacterId = characterId;
    lastBytes = bytes;
    if (gateUploadPortrait) await gate.future;
    final error = errorToThrow;
    if (error != null) throw error;
    return 'https://exemple.com/portrait.png';
  }

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<CharacterSummary>> fetchCharacters() async => const [];

  @override
  Future<WriteOutcome> updateHp({
    required String characterId,
    required int currentHp,
    required int temporaryHp,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> removePortrait({
    required String characterId,
    required String portraitUrl,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> addXp({required String characterId, required int newXp}) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> castSpell({
    required String characterId,
    required int slotLevel,
    required int slotsUsed,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> useClassFeature({
    required String characterId,
    required int classFeatureId,
    required int usesRemaining,
  }) {
    throw UnimplementedError();
  }

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
  Future<LevelUpLevelData> fetchLevelUpLevelData({
    required Object classId,
    required int targetLevel,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<LevelUpApplyResult> applyLevelUp({
    required String characterId,
    required String className,
    required int hpRolled,
    required String hpMethod,
    required int hpGain,
    LevelUpChoiceSelection? choice,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> applyRest({
    required String characterId,
    required RestType type,
    required String className,
  }) {
    throw UnimplementedError();
  }

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
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> leaveStory({required String characterCampaignId}) {
    throw UnimplementedError();
  }
}

Future<_FakeCharacterRepository> _pumpScreen(WidgetTester tester) async {
  final repository = _FakeCharacterRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [characterRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => PortraitCropScreen(
                      characterId: 'char-1',
                      imageBytes: _fakePngBytes,
                    ),
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
  return repository;
}

Future<void> _tapValiderAndSettle(WidgetTester tester) async {
  await tester.runAsync(() async {
    await tester.tap(find.widgetWithText(PrimaryButton, 'VALIDER'));
    await tester.pump();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await tester.pump();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await tester.pump();
  });
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('affiche le cadre de recadrage et les boutons Annuler/Valider', (
    tester,
  ) async {
    await _pumpScreen(tester);

    expect(find.text('RECADRAGE'), findsOneWidget);
    expect(find.widgetWithText(SecondaryButton, 'ANNULER'), findsOneWidget);
    expect(find.widgetWithText(PrimaryButton, 'VALIDER'), findsOneWidget);
  });

  testWidgets(
    "pendant l'envoi : Valider en isLoading, Annuler desactive",
    (tester) async {
      final repository = await _pumpScreen(tester);
      repository.gateUploadPortrait = true;

      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(PrimaryButton, 'VALIDER'));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      });

      expect(repository.uploadPortraitCallCount, 1);

      final primaryButton = tester.widget<PrimaryButton>(
        find.byType(PrimaryButton),
      );
      expect(primaryButton.isLoading, isTrue);

      final secondaryButton = tester.widget<SecondaryButton>(
        find.widgetWithText(SecondaryButton, 'ANNULER'),
      );
      expect(secondaryButton.onPressed, isNull);

      repository.gate.complete();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    "succes : envoie les octets captures a "
    "CharacterRepository.uploadPortrait pour le bon characterId, "
    "ferme l'ecran (pop(true))",
    (tester) async {
      final repository = await _pumpScreen(tester);

      await _tapValiderAndSettle(tester);

      expect(repository.uploadPortraitCallCount, 1);
      expect(repository.lastCharacterId, 'char-1');
      expect(repository.lastBytes, isNotNull);
      expect(repository.lastBytes!.isNotEmpty, isTrue);
      expect(find.text('RECADRAGE'), findsNothing);
    },
  );

  testWidgets(
    "CharacterFailure : bandeau d'alerte inline affiche failure.message, "
    "l'ecran reste ouvert",
    (tester) async {
      final repository = await _pumpScreen(tester);
      repository.errorToThrow = const CharacterFailure('Erreur serveur.');

      await _tapValiderAndSettle(tester);

      expect(find.text('Erreur serveur.'), findsOneWidget);
      expect(find.text('RECADRAGE'), findsOneWidget);
    },
  );

  testWidgets(
    'echec inattendu (pas une CharacterFailure) : bandeau generique fixe',
    (tester) async {
      final repository = await _pumpScreen(tester);
      repository.errorToThrow = Exception('boom');

      await _tapValiderAndSettle(tester);

      expect(
        find.text("Impossible d'envoyer le portrait. Réessayez."),
        findsOneWidget,
      );
      expect(find.text('RECADRAGE'), findsOneWidget);
    },
  );

  testWidgets(
    "le bouton retour visible (WoodBackHeader) reste garde par "
    "isUploading : aucun effet pendant l'envoi",
    (tester) async {
      final repository = await _pumpScreen(tester);
      repository.gateUploadPortrait = true;

      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(PrimaryButton, 'VALIDER'));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      });

      expect(repository.uploadPortraitCallCount, 1);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pump();

      expect(find.text('RECADRAGE'), findsOneWidget);

      repository.gate.complete();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'PopScope(canPop: !_isUploading) : le geste retour Android (systeme) '
    "est bloque pendant l'envoi, meme pattern que "
    'AvatarCropScreen/les 3 sheets de profil.',
    (tester) async {
      final repository = await _pumpScreen(tester);
      repository.gateUploadPortrait = true;

      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(PrimaryButton, 'VALIDER'));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      });

      expect(repository.uploadPortraitCallCount, 1);

      // `pump()` simple, jamais `pumpAndSettle()` ici : `PrimaryButton`
      // affiche un `CircularProgressIndicator` indéterminé tant que
      // `_isUploading` reste vrai, dont l'animation ne se termine jamais
      // (`pumpAndSettle` boucle indéfiniment dessus) - même raison que les
      // autres tests de ce fichier qui interagissent pendant l'envoi.
      await tester.binding.handlePopRoute();
      await tester.pump();

      expect(find.text('RECADRAGE'), findsOneWidget);

      repository.gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('RECADRAGE'), findsNothing);
    },
  );
}
