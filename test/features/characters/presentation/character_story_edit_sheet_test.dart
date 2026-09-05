// Tests de widget de la sheet "Modifier l'histoire"
// (`presentation/widgets/character_story_edit_sheet.dart`) — pattern
// autoportant (voir sa documentation de classe) : préremplissage synchrone,
// chargement (spinner intégré au bouton "Enregistrer"), bandeau d'erreur
// inline (échec réseau/hors-ligne/générique) avec texte saisi préservé,
// `closeEnabled` désactivé pendant la sauvegarde.

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
import 'package:personnages/features/characters/presentation/widgets/character_story_edit_sheet.dart';

/// Double minimal — seule [updateStoryFields] est exercée par ce fichier,
/// même rationale de duplication que le reste de ce dépôt (voir
/// `add_reward_sheet_test.dart::_FakeInventoryCatalogRepository`).
class FakeRepository implements CharacterRepository {
  final Completer<void> gate = Completer<void>();
  bool gateUpdateStoryFields = false;

  int updateStoryFieldsCallCount = 0;
  Map<String, String?>? lastPayload;
  WriteOutcome outcomeToReturn = WriteOutcome.synced;
  Object? errorToThrow;

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
  }) async {
    updateStoryFieldsCallCount++;
    lastPayload = {
      'appearanceText': appearanceText,
      'traitsText': traitsText,
      'idealsText': idealsText,
      'bondsText': bondsText,
      'flawsText': flawsText,
      'backstoryText': backstoryText,
      'alliesText': alliesText,
      'featuresText': featuresText,
      'treasureText': treasureText,
    };
    if (gateUpdateStoryFields) await gate.future;
    final error = errorToThrow;
    if (error != null) throw error;
    return outcomeToReturn;
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

const _detail = CharacterDetail(
  id: 'char-1',
  name: 'Aranea',
  classes: [],
  xp: 0,
  currentHp: 10,
  maxHp: 10,
  temporaryHp: 0,
  abilityScores: {},
  appearanceText: 'Cheveux argentés tressés.',
  traitsText: "Curieuse jusqu'à l'imprudence.",
  idealsText: 'Le savoir doit être partagé.',
  bondsText: 'Recherche le maître qui a scellé le grimoire.',
  flawsText: 'Incapable de résister à un mystère.',
  backstoryText: 'Élevée dans une enclave forestière.',
  alliesText: "L'Ordre des Archivistes.",
  featuresText: 'Une cicatrice fine sur la joue.',
  treasureText: 'Un grimoire scellé.',
);

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
                onPressed: () => showCharacterStoryEditSheet(
                  context,
                  characterId: 'char-1',
                  detail: _detail,
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
  testWidgets('préremplit les 9 champs depuis `detail`, dans l\'ordre '
      'canonique 1..9', (tester) async {
    await _pumpSheet(tester);

    expect(find.text("MODIFIER L'HISTOIRE"), findsOneWidget);
    for (final label in const [
      'APPARENCE PHYSIQUE',
      'TRAITS DE PERSONNALITÉ',
      'IDÉAUX',
      'LIENS',
      'DÉFAUTS',
      'HISTOIRE PERSONNELLE',
      'ALLIÉS',
      'PARTICULARITÉS',
      'TRÉSOR',
    ]) {
      expect(find.text(label), findsOneWidget);
    }

    final fields = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .toList();
    expect(fields, hasLength(9));
    expect(fields[0].controller!.text, 'Cheveux argentés tressés.');
    expect(fields[1].controller!.text, "Curieuse jusqu'à l'imprudence.");
    expect(fields[2].controller!.text, 'Le savoir doit être partagé.');
    expect(
      fields[3].controller!.text,
      'Recherche le maître qui a scellé le grimoire.',
    );
    expect(fields[4].controller!.text, 'Incapable de résister à un mystère.');
    expect(fields[5].controller!.text, 'Élevée dans une enclave forestière.');
    expect(fields[6].controller!.text, "L'Ordre des Archivistes.");
    expect(fields[7].controller!.text, 'Une cicatrice fine sur la joue.');
    expect(fields[8].controller!.text, 'Un grimoire scellé.');
  });

  testWidgets(
    '"Enregistrer" : envoie les valeurs modifiées trimées, `null` pour un '
    'champ vidé, ferme la sheet et affiche le SnackBar de confirmation',
    (tester) async {
      final repository = await _pumpSheet(tester);

      await tester.enterText(
        find.byType(TextFormField).first,
        '  Nouvelle apparence.  ',
      );
      await tester.enterText(find.byType(TextFormField).at(1), '   ');
      await tester.pump();

      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pumpAndSettle();

      expect(repository.updateStoryFieldsCallCount, 1);
      expect(repository.lastPayload!['appearanceText'], 'Nouvelle apparence.');
      expect(
        repository.lastPayload!['traitsText'],
        isNull,
        reason:
            'un champ vidé (texte blanc après trim) doit être envoyé '
            'comme `null`, jamais une chaîne blanche',
      );
      expect(
        repository.lastPayload!['idealsText'],
        'Le savoir doit être partagé.',
        reason: 'un champ non modifié conserve sa valeur préremplie',
      );

      expect(
        find.byType(TextFormField),
        findsNothing,
        reason: 'la sheet doit se fermer après un succès',
      );
      expect(find.text('Histoire mise à jour.'), findsOneWidget);
    },
  );

  testWidgets(
    'pendant la sauvegarde : bouton "Enregistrer" en isLoading, "Annuler" et '
    'le X du `SheetHeaderBar` désactivés (`closeEnabled: false`)',
    (tester) async {
      final repository = await _pumpSheet(tester);
      repository.gateUpdateStoryFields = true;

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
    'pendant la sauvegarde : ni le geste retour Android, ni un tap sur le '
    'voile ne ferment la sheet (`isDismissible: false`, `enableDrag: false`, '
    '`PopScope(canPop: !_isSaving)`)',
    (tester) async {
      final repository = await _pumpSheet(tester);
      repository.gateUpdateStoryFields = true;

      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pump();

      // Geste retour Android : passe par `Navigator.maybePop`, un chemin
      // entièrement distinct du voile/du drag (voir la documentation de
      // `_CharacterStoryEditSheetContentState.build`) — seul le
      // `PopScope(canPop: !_isSaving)` le bloque. `NavigatorState.maybePop`
      // retourne toujours `true` (même quand le `PopScope` refuse le pop —
      // ce booléen ne signifie que "la requête de retour a été prise en
      // charge", pas "la route a été dépilée"), donc seul l'état réel de
      // l'arbre fait foi. Pas de `pumpAndSettle` ici : le spinner
      // indéterminé de "Enregistrer" (`isLoading: true`) tourne tant que le
      // réseau est gaté, ce qui l'empêcherait de se stabiliser — quelques
      // pumps explicites suffisent à laisser l'éventuelle animation de
      // fermeture de la sheet se dérouler.
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.byType(TextFormField),
        findsNWidgets(9),
        reason:
            'le geste retour ne doit pas fermer la sheet pendant la '
            'sauvegarde',
      );

      // Tap sur le voile (zone au-dessus de la sheet, `heightFactor: 0.92`) :
      // `isDismissible: false` fait que `ModalBarrier` ne relaie même pas
      // l'appel à `Navigator.maybePop`.
      await tester.tapAt(const Offset(400, 10));
      await tester.pump();
      expect(
        find.byType(TextFormField),
        findsNWidgets(9),
        reason:
            'un tap sur le voile ne doit pas fermer la sheet pendant la '
            'sauvegarde',
      );

      expect(
        repository.updateStoryFieldsCallCount,
        1,
        reason:
            'aucune de ces tentatives de fermeture ne doit avoir '
            'redéclenché un appel réseau',
      );

      repository.gate.complete();
      await tester.pumpAndSettle();

      expect(
        find.byType(TextFormField),
        findsNothing,
        reason:
            'une fois la sauvegarde résolue, la sheet se ferme '
            'normalement via son propre bouton "Enregistrer"',
      );
    },
  );

  testWidgets(
    'WriteOutcome.queued (hors ligne) : bandeau d\'alerte inline honnête, '
    'sheet reste ouverte, texte saisi préservé',
    (tester) async {
      final repository = await _pumpSheet(tester);
      repository.outcomeToReturn = WriteOutcome.queued;

      await tester.enterText(
        find.byType(TextFormField).first,
        'Apparence modifiée pas encore enregistrée.',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining("n'a pas pu être enregistrée"),
        findsOneWidget,
      );
      expect(find.byType(TextFormField), findsNWidgets(9));
      expect(
        tester
            .widgetList<TextFormField>(find.byType(TextFormField))
            .first
            .controller!
            .text,
        'Apparence modifiée pas encore enregistrée.',
      );

      final primaryButton = tester.widget<PrimaryButton>(
        find.byType(PrimaryButton),
      );
      expect(primaryButton.isLoading, isFalse);
    },
  );

  testWidgets(
    'CharacterFailure : bandeau d\'alerte inline affiche `failure.message`, '
    'sheet reste ouverte, texte saisi préservé',
    (tester) async {
      final repository = await _pumpSheet(tester);
      repository.errorToThrow = const CharacterFailure('Erreur serveur.');

      await tester.enterText(
        find.byType(TextFormField).first,
        'Apparence en cours de saisie.',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pumpAndSettle();

      expect(find.text('Erreur serveur.'), findsOneWidget);
      expect(
        tester
            .widgetList<TextFormField>(find.byType(TextFormField))
            .first
            .controller!
            .text,
        'Apparence en cours de saisie.',
      );
    },
  );

  testWidgets(
    'échec inattendu (pas une `CharacterFailure`) : bandeau générique '
    '"Impossible d\'enregistrer les modifications. Réessayez."',
    (tester) async {
      final repository = await _pumpSheet(tester);
      repository.errorToThrow = Exception('boom');

      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pumpAndSettle();

      expect(
        find.text("Impossible d'enregistrer les modifications. Réessayez."),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'widget démonté pendant l\'appel réseau non résolu (autre chemin de '
    'navigation) : `ref.invalidate` est gardé par `mounted`, aucune '
    'exception ne fuit du try/catch de `_submit`',
    (tester) async {
      final repository = await _pumpSheet(tester);
      repository.gateUpdateStoryFields = true;

      await tester.tap(find.widgetWithText(PrimaryButton, 'ENREGISTRER'));
      await tester.pump();

      // Démonte tout l'arbre (donc la sheet et son `ConsumerState`) pendant
      // que l'appel réseau `updateStoryFields` est toujours en vol —
      // simule un chemin de navigation qui contournerait le `PopScope`
      // ci-dessus (ex. déconnexion forcée qui remplace toute la racine de
      // l'app), seul cas restant où `_submit` peut se retrouver démonté
      // avant que `await` ne se résolve.
      await tester.pumpWidget(const SizedBox());

      repository.gate.complete();
      await tester.pump();
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason:
            '`ref.invalidate` doit être gardé par `mounted` (vérifié '
            'avant, pas après) : `ConsumerState.invalidate` lève un '
            '`StateError` sur un widget démonté, qui ne doit jamais fuir '
            'hors du try/catch de `_submit`',
      );
    },
  );
}
