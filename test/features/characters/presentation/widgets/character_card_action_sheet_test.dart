// Tests de widget de la sheet "Actions de personnage" (clic long sur une
// carte de `character_list_screen.dart`, hors mode sélection) — même patron
// que `item_action_sheet_test.dart`, mais cette sheet porte elle-même la
// logique des 5 actions (voir la documentation de classe de
// `character_card_action_sheet.dart` pour l'écart assumé par rapport à la
// signature initialement suggérée par la spec de la tâche), donc ce fichier
// couvre aussi la gestion d'erreur/les appels au dépôt.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/features/character_creation/data/character_edit_repository.dart';
import 'package:personnages/features/character_creation/domain/character_edit_snapshot.dart';
import 'package:personnages/features/character_creation/domain/character_edit_planner.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_edit_session_provider.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/characters/domain/inventory_catalog_item.dart';
import 'package:personnages/features/characters/domain/level_up_apply_result.dart';
import 'package:personnages/features/characters/domain/level_up_choice_selection.dart';
import 'package:personnages/features/characters/domain/level_up_elemental_discipline_option.dart';
import 'package:personnages/features/characters/domain/level_up_feat_option.dart';
import 'package:personnages/features/characters/domain/level_up_invocation_option.dart';
import 'package:personnages/features/characters/domain/level_up_level_data.dart';
import 'package:personnages/features/characters/domain/level_up_maneuver_option.dart';
import 'package:personnages/features/characters/domain/level_up_arcane_shot_option.dart';
import 'package:personnages/features/characters/domain/level_up_infusion_option.dart';
import 'package:personnages/features/characters/domain/level_up_infusion_swap.dart';
import 'package:personnages/features/characters/domain/level_up_metamagic_option.dart';
import 'package:personnages/features/characters/domain/level_up_metamagic_swap.dart';
import 'package:personnages/features/characters/domain/level_up_draconic_ancestry_option.dart';
import 'package:personnages/features/characters/domain/level_up_rune_option.dart';
import 'package:personnages/features/characters/domain/rest_type.dart';
import 'package:personnages/features/characters/domain/reward_item_draft.dart';
import 'package:personnages/features/characters/domain/weapon_slot.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/features/characters/presentation/widgets/character_card_action_sheet.dart';

const _character = CharacterSummary(
  id: '42',
  name: 'Halltesse Ambrelune',
  raceName: 'Elfe',
  className: 'Magicienne',
  level: 5,
  xp: 7000,
);

class _FakeCharacterRepository implements CharacterRepository {
  WriteOutcome setArchivedOutcome = WriteOutcome.synced;
  WriteOutcome setDeadOutcome = WriteOutcome.synced;
  WriteOutcome deleteOutcome = WriteOutcome.synced;
  Object? setArchivedError;
  Object? setDeadError;
  Object? deleteError;

  bool? lastSetArchivedValue;
  bool? lastSetDeadValue;
  int setArchivedCallCount = 0;
  int setDeadCallCount = 0;
  int deleteCallCount = 0;

  @override
  Future<WriteOutcome> setArchived({
    required String characterId,
    required bool isArchived,
  }) async {
    setArchivedCallCount++;
    lastSetArchivedValue = isArchived;
    if (setArchivedError != null) throw setArchivedError!;
    return setArchivedOutcome;
  }

  @override
  Future<WriteOutcome> setDead({
    required String characterId,
    required bool isDead,
  }) async {
    setDeadCallCount++;
    lastSetDeadValue = isDead;
    if (setDeadError != null) throw setDeadError!;
    return setDeadOutcome;
  }

  @override
  Future<WriteOutcome> deleteCharacter({required String characterId}) async {
    deleteCallCount++;
    if (deleteError != null) throw deleteError!;
    return deleteOutcome;
  }

  @override
  Future<List<CharacterSummary>> fetchCharacters() async => [_character];

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) =>
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
}

/// Fake minimal de `CharacterEditRepository` — seul [fetchSnapshot] est
/// exercé par ce fichier (toujours en échec, voir le test "Modifier" : la
/// chaîne complète de catalogues de `startCharacterEdit` est hors périmètre
/// de cette sheet, déjà déléguée telle quelle à cette fonction existante).
class _FailingCharacterEditRepository implements CharacterEditRepository {
  @override
  Future<CharacterEditSnapshot> fetchSnapshot(String characterId) =>
      throw StateError('boom');

  @override
  Future<void> save({
    required String characterId,
    required CharacterEditPlan plan,
  }) => throw UnimplementedError();
}

void main() {
  late _FakeCharacterRepository fakeRepository;

  setUp(() {
    fakeRepository = _FakeCharacterRepository();
  });

  GoRouter buildTestRouter(CharacterSummary character) {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            // `Consumer` : `showCharacterCardActionSheet` a besoin d'un
            // vrai `WidgetRef` (appels directs à
            // `characterRepositoryProvider`/`charactersProvider`, voir
            // sa documentation de classe) — un bouton "Ouvrir" déclenche
            // l'appel réel, même patron que les autres sheets de ce
            // dépôt testées via un `Builder`/bouton minimal.
            body: Center(
              child: Consumer(
                builder: (context, ref, _) => ElevatedButton(
                  onPressed: () => showCharacterCardActionSheet(
                    context,
                    ref,
                    character: character,
                  ),
                  child: const Text('Ouvrir'),
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/characters/:id/share',
          builder: (context, state) => Scaffold(
            body: Center(child: Text('Partage ${state.pathParameters['id']}')),
          ),
        ),
      ],
    );
  }

  Widget buildTestWidget({CharacterSummary? character}) {
    return ProviderScope(
      overrides: [
        characterRepositoryProvider.overrideWithValue(fakeRepository),
        characterEditRepositoryProvider.overrideWithValue(
          _FailingCharacterEditRepository(),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: buildTestRouter(character ?? _character),
      ),
    );
  }

  Future<void> openSheet(
    WidgetTester tester, {
    CharacterSummary? character,
  }) async {
    await tester.pumpWidget(buildTestWidget(character: character));
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'affiche le nom, le résumé "Race · Classe · Niv. X" et les 5 actions '
    'dans l\'ordre attendu',
    (tester) async {
      await openSheet(tester);

      expect(find.text('Halltesse Ambrelune'), findsOneWidget);
      expect(find.text('Elfe · Magicienne · Niv. 5'), findsOneWidget);

      final labels = [
        'Modifier',
        'Partager',
        'Archiver ce personnage',
        'Marquer comme mort',
        'Supprimer le personnage',
      ];
      final positions = labels.map((label) {
        return tester.getTopLeft(find.text(label)).dy;
      }).toList();
      expect(
        positions,
        List<double>.from(positions)..sort(),
        reason: 'les actions doivent apparaître dans cet ordre',
      );
    },
  );

  testWidgets(
    'personnage archivé : "Désarchiver" au lieu de "Archiver ce personnage", '
    'appelle setArchived(isArchived: false)',
    (tester) async {
      await openSheet(tester, character: _character.copyWith(isArchived: true));

      expect(find.text('Désarchiver'), findsOneWidget);
      expect(find.text('Archiver ce personnage'), findsNothing);

      await tester.tap(find.text('Désarchiver'));
      await tester.pumpAndSettle();

      expect(fakeRepository.lastSetArchivedValue, isFalse);
    },
  );

  testWidgets(
    'personnage mort : "Ressusciter" au lieu de "Marquer comme mort", '
    'appelle setDead(isDead: false)',
    (tester) async {
      await openSheet(tester, character: _character.copyWith(isDead: true));

      expect(find.text('Ressusciter'), findsOneWidget);
      expect(find.text('Marquer comme mort'), findsNothing);

      await tester.tap(find.text('Ressusciter'));
      await tester.pumpAndSettle();

      expect(fakeRepository.lastSetDeadValue, isFalse);
    },
  );

  testWidgets('"Partager" navigue vers /characters/:id/share', (tester) async {
    await openSheet(tester);

    await tester.tap(find.text('Partager'));
    await tester.pumpAndSettle();

    expect(find.text('Partage 42'), findsOneWidget);
  });

  group('"Archiver ce personnage"/"Désarchiver"', () {
    testWidgets(
      'appelle setArchived(isArchived: true) pour un personnage actif, '
      'invalide charactersProvider au succès',
      (tester) async {
        await openSheet(tester);

        await tester.tap(find.text('Archiver ce personnage'));
        await tester.pumpAndSettle();

        expect(fakeRepository.setArchivedCallCount, 1);
        expect(fakeRepository.lastSetArchivedValue, isTrue);
      },
    );

    testWidgets('hors ligne (WriteOutcome.queued) : SnackBar "Hors ligne" sans '
        'promettre de synchronisation', (tester) async {
      fakeRepository.setArchivedOutcome = WriteOutcome.queued;
      await openSheet(tester);

      await tester.tap(find.text('Archiver ce personnage'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining("n'a pas pu être enregistrée"),
        findsOneWidget,
      );
    });

    testWidgets('CharacterFailure : affiche le message du dépôt', (
      tester,
    ) async {
      fakeRepository.setArchivedError = const CharacterFailure(
        'Erreur spécifique archivage.',
      );
      await openSheet(tester);

      await tester.tap(find.text('Archiver ce personnage'));
      await tester.pumpAndSettle();

      expect(find.text('Erreur spécifique archivage.'), findsOneWidget);
    });

    testWidgets('échec générique : message générique', (tester) async {
      fakeRepository.setArchivedError = StateError('boom');
      await openSheet(tester);

      await tester.tap(find.text('Archiver ce personnage'));
      await tester.pumpAndSettle();

      expect(
        find.text('Impossible de mettre à jour le statut. Réessayez.'),
        findsOneWidget,
      );
    });
  });

  group('"Marquer comme mort"/"Ressusciter"', () {
    testWidgets('appelle setDead(isDead: true) pour un personnage vivant', (
      tester,
    ) async {
      await openSheet(tester);

      await tester.tap(find.text('Marquer comme mort'));
      await tester.pumpAndSettle();

      expect(fakeRepository.setDeadCallCount, 1);
      expect(fakeRepository.lastSetDeadValue, isTrue);
    });

    testWidgets('hors ligne (WriteOutcome.queued) : SnackBar "Hors ligne" sans '
        'promettre de synchronisation', (tester) async {
      fakeRepository.setDeadOutcome = WriteOutcome.queued;
      await openSheet(tester);

      await tester.tap(find.text('Marquer comme mort'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining("n'a pas pu être enregistrée"),
        findsOneWidget,
      );
    });

    testWidgets('CharacterFailure : affiche le message du dépôt', (
      tester,
    ) async {
      fakeRepository.setDeadError = const CharacterFailure(
        'Erreur spécifique statut mort.',
      );
      await openSheet(tester);

      await tester.tap(find.text('Marquer comme mort'));
      await tester.pumpAndSettle();

      expect(find.text('Erreur spécifique statut mort.'), findsOneWidget);
    });

    testWidgets('échec générique : message générique', (tester) async {
      fakeRepository.setDeadError = StateError('boom');
      await openSheet(tester);

      await tester.tap(find.text('Marquer comme mort'));
      await tester.pumpAndSettle();

      expect(
        find.text('Impossible de mettre à jour le statut. Réessayez.'),
        findsOneWidget,
      );
    });
  });

  group('"Supprimer le personnage"', () {
    testWidgets(
      'ouvre le dialogue de confirmation ; "Annuler" ne supprime rien',
      (tester) async {
        await openSheet(tester);

        await tester.tap(find.text('Supprimer le personnage'));
        await tester.pumpAndSettle();

        expect(find.text('Supprimer Halltesse Ambrelune ?'), findsOneWidget);

        await tester.tap(find.text('ANNULER'));
        await tester.pumpAndSettle();

        expect(fakeRepository.deleteCallCount, 0);
      },
    );

    testWidgets('confirmer appelle deleteCharacter', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Supprimer le personnage'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();

      expect(fakeRepository.deleteCallCount, 1);
    });

    testWidgets('hors ligne (WriteOutcome.queued) : SnackBar "Hors ligne" sans '
        'promettre de synchronisation', (tester) async {
      fakeRepository.deleteOutcome = WriteOutcome.queued;
      await openSheet(tester);

      await tester.tap(find.text('Supprimer le personnage'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining("n'a pas pu être enregistrée"),
        findsOneWidget,
      );
    });

    testWidgets('échec générique : message générique', (tester) async {
      fakeRepository.deleteError = StateError('boom');
      await openSheet(tester);

      await tester.tap(find.text('Supprimer le personnage'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();

      expect(
        find.text('Impossible de supprimer le personnage. Réessayez.'),
        findsOneWidget,
      );
    });
  });

  testWidgets(
    '"Modifier" délègue à startCharacterEdit (affiche son message d\'erreur '
    'au rejet du dépôt d\'édition une fois la sheet refermée) — wiring '
    'vérifié, le détail du flux a ses propres tests',
    (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Modifier'));
      await tester.pumpAndSettle();

      expect(
        find.text('Impossible de charger le personnage à modifier. Réessayez.'),
        findsOneWidget,
      );
    },
  );
}
