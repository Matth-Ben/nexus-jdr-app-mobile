// Tests de widget de la carte "Aventures" de l'onglet "Personnage" — voir
// `docs/cahier-des-charges/04-fonctionnalites-app-mobile.md` section 7.2.
//
// `CharacterAdventuresCard` porte elle-même l'action "Quitter l'histoire"
// (voir sa documentation de classe) : le dépôt de test
// (`_FakeCharacterRepository`) est injecté via `overrideWithValue`, même
// principe que `character_detail_screen_test.dart`.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/portrait_frame.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_adventure.dart';
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
import 'package:personnages/features/characters/presentation/widgets/character_adventures_card.dart';

class _FakeCharacterRepository implements CharacterRepository {
  String? lastLeftCharacterCampaignId;
  int leaveStoryCallCount = 0;
  Object? leaveStoryErrorToThrow;

  @override
  Future<void> leaveStory({required String characterCampaignId}) async {
    leaveStoryCallCount++;
    lastLeftCharacterCampaignId = characterCampaignId;
    if (leaveStoryErrorToThrow != null) throw leaveStoryErrorToThrow!;
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
  }) => throw UnimplementedError();

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
  Future<List<CharacterSummary>> fetchCharacters() async => const [];

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> updateHp({
    required String characterId,
    required int currentHp,
    required int temporaryHp,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<String> uploadPortrait({
    required String characterId,
    required Uint8List bytes,
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
  Future<WriteOutcome> addXp({
    required String characterId,
    required int newXp,
  }) {
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
    int diceSpent = 0,
    int appliedGain = 0,
  }) {
    throw UnimplementedError();
  }
}

CharacterDetail _detail({List<CharacterAdventure> adventures = const []}) {
  return CharacterDetail(
    id: '1',
    name: 'Test',
    classes: const [],
    xp: 0,
    currentHp: 10,
    maxHp: 10,
    temporaryHp: 0,
    abilityScores: const {},
    adventures: adventures,
  );
}

Future<void> _pump(
  WidgetTester tester,
  CharacterDetail detail,
  _FakeCharacterRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [characterRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        home: Scaffold(body: CharacterAdventuresCard(detail: detail)),
      ),
    ),
  );
}

void main() {
  late _FakeCharacterRepository fakeRepository;

  setUp(() {
    fakeRepository = _FakeCharacterRepository();
  });

  testWidgets(
    'affiche une ligne par histoire (titre + portrait de substitution '
    '`Icons.auto_stories`) séparées par un Divider',
    (tester) async {
      const adventures = [
        CharacterAdventure(
          characterCampaignId: 'cc-1',
          storyId: 'story-1',
          storyTitle: 'La Malédiction du Nord',
        ),
        CharacterAdventure(
          characterCampaignId: 'cc-2',
          storyId: 'story-2',
          storyTitle: 'Les Ombres de Faerûn',
        ),
      ];

      await _pump(tester, _detail(adventures: adventures), fakeRepository);

      expect(find.text('AVENTURES'), findsOneWidget);
      expect(find.text('La Malédiction du Nord'), findsOneWidget);
      expect(find.text('Les Ombres de Faerûn'), findsOneWidget);
      expect(find.byType(Divider), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(PortraitFrame).first,
          matching: find.byIcon(Icons.auto_stories),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('se réduit à SizedBox.shrink (filet de sécurité) quand aucune '
      'aventure n\'est rattachée', (tester) async {
    await _pump(tester, _detail(), fakeRepository);

    expect(find.text('AVENTURES'), findsNothing);
    expect(find.byType(CharacterAdventuresCard), findsOneWidget);
  });

  testWidgets(
    'tap sur "Quitter" ouvre la confirmation ; "Annuler" ne fait rien',
    (tester) async {
      const adventures = [
        CharacterAdventure(
          characterCampaignId: 'cc-1',
          storyId: 'story-1',
          storyTitle: 'La Malédiction du Nord',
        ),
      ];
      await _pump(tester, _detail(adventures: adventures), fakeRepository);

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      expect(find.text('Quitter « La Malédiction du Nord » ?'), findsOneWidget);
      expect(
        find.text(
          'Ton personnage garde toutes ses données. Seul le lien avec '
          'cette histoire disparaît.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('ANNULER'));
      await tester.pumpAndSettle();

      expect(fakeRepository.leaveStoryCallCount, 0);
      expect(find.text('La Malédiction du Nord'), findsOneWidget);
    },
  );

  testWidgets(
    'confirmer "Quitter" appelle leaveStory et affiche un SnackBar de '
    'succès',
    (tester) async {
      const adventures = [
        CharacterAdventure(
          characterCampaignId: 'cc-1',
          storyId: 'story-1',
          storyTitle: 'La Malédiction du Nord',
        ),
      ];
      await _pump(tester, _detail(adventures: adventures), fakeRepository);

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quitter'));
      await tester.pumpAndSettle();

      expect(fakeRepository.leaveStoryCallCount, 1);
      expect(fakeRepository.lastLeftCharacterCampaignId, 'cc-1');
      expect(find.text('Tu as quitté La Malédiction du Nord.'), findsOneWidget);
    },
  );

  testWidgets('un échec de leaveStory affiche un SnackBar d\'erreur', (
    tester,
  ) async {
    fakeRepository.leaveStoryErrorToThrow = Exception('boom');
    const adventures = [
      CharacterAdventure(
        characterCampaignId: 'cc-1',
        storyId: 'story-1',
        storyTitle: 'La Malédiction du Nord',
      ),
    ];
    await _pump(tester, _detail(adventures: adventures), fakeRepository);

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quitter'));
    await tester.pumpAndSettle();

    expect(
      find.text('Impossible de quitter cette histoire. Réessayez.'),
      findsOneWidget,
    );
  });

  group('CharacterAdventuresCard.hasContent', () {
    test('true si au moins une aventure est rattachée', () {
      expect(
        CharacterAdventuresCard.hasContent(
          _detail(
            adventures: const [
              CharacterAdventure(
                characterCampaignId: 'cc-1',
                storyId: 'story-1',
                storyTitle: 'Test',
              ),
            ],
          ),
        ),
        isTrue,
      );
    });

    test('false sans aucune aventure', () {
      expect(CharacterAdventuresCard.hasContent(_detail()), isFalse);
    });
  });
}
