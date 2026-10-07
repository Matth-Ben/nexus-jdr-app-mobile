// Tests du coordinateur de synchro hors-ligne PV/XP
// (character_write_sync_coordinator.dart).
//
// Contrairement au reste des tests de ce depot, on ne passe pas par un
// double de CharacterRepository complet pour verifier l'invalidation :
// characterDetailProvider delegue directement a characterRepositoryProvider,
// donc un simple double de repository suffit a observer si
// characterDetailProvider(characterId) a ete re-resolu apres invalidation
// (le compteur d'appels de fetchCharacterDetail augmente).
//
// PendingCharacterWriteSyncer n'est pas une abstraction (classe concrete,
// jamais une interface -- voir sa documentation de classe : volontairement
// gardee hors de CharacterRepository) : le double utilise ici est un
// sous-type qui override sync() sans jamais appeler le reseau reel, avec un
// SupabaseClient/PendingCharacterWriteQueue factices jamais utilises (le
// super() les exige, mais sync() override ne les touche jamais).

import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/cache_providers.dart';
import 'package:personnages/core/cache/pending_character_write_queue.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/core/network/connectivity_checker.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/core/network/supabase_client_provider.dart';
import 'package:personnages/core/notifications/notification_providers.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/data/pending_character_write_syncer.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
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
import 'package:personnages/features/characters/presentation/providers/character_detail_provider.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/features/characters/presentation/providers/character_write_sync_coordinator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('CharacterWriteSyncCoordinator', () {
    late _FakeCharacterRepository fakeRepository;
    late _ScriptedSyncer fakeSyncer;
    late _FakeConnectivityChecker fakeConnectivity;
    late ProviderContainer container;

    setUp(() {
      fakeRepository = _FakeCharacterRepository();
      fakeSyncer = _ScriptedSyncer();
      fakeConnectivity = _FakeConnectivityChecker();
      container = ProviderContainer(
        overrides: [
          characterRepositoryProvider.overrideWithValue(fakeRepository),
          pendingCharacterWriteSyncerProvider.overrideWithValue(fakeSyncer),
          connectivityCheckerProvider.overrideWithValue(fakeConnectivity),
        ],
      );
      addTearDown(container.dispose);
    });

    test(
      'synchro de demarrage : sync() est appele une fois des que le '
      'coordinateur est instancie (avant tout retour de connectivite)',
      () async {
        fakeSyncer.resultToReturn = const {};

        container.read(characterWriteSyncCoordinatorProvider);
        await pumpEventQueue();

        expect(fakeSyncer.callCount, 1);
      },
    );

    test('un characterId synchronise avec succes invalide '
        'characterDetailProvider(characterId), qui se re-resout ensuite avec '
        'la donnee serveur fraiche', () async {
      const characterId = 'char-1';
      fakeRepository.detailToReturn = _detailWithHp(18);
      fakeSyncer.resultToReturn = const {};

      container.read(characterWriteSyncCoordinatorProvider);
      await pumpEventQueue();

      final values = <AsyncValue<CharacterDetail>>[];
      container.listen<AsyncValue<CharacterDetail>>(
        characterDetailProvider(characterId),
        (previous, next) => values.add(next),
        fireImmediately: true,
      );
      await pumpEventQueue();

      expect(fakeRepository.fetchDetailCallCountFor(characterId), 1);
      expect(values.last.value?.currentHp, 18);

      fakeRepository.detailToReturn = _detailWithHp(25);
      fakeSyncer.resultToReturn = {characterId};

      fakeConnectivity.emitRestored();
      await pumpEventQueue();

      expect(
        fakeRepository.fetchDetailCallCountFor(characterId),
        2,
        reason:
            'characterDetailProvider(characterId) doit avoir ete '
            'invalide par le coordinateur puis re-resolu (toujours '
            'ecoute), pas seulement marque obsolete sans jamais '
            'redemander la donnee serveur.',
      );
      expect(values.last.value?.currentHp, 25);
    });

    test('un characterId qui n a jamais synchronise (resultat vide) '
        'n invalide jamais characterDetailProvider', () async {
      const characterId = 'char-1';
      fakeRepository.detailToReturn = _detailWithHp(18);
      fakeSyncer.resultToReturn = const {};

      container.read(characterWriteSyncCoordinatorProvider);
      await pumpEventQueue();

      container.listen<AsyncValue<CharacterDetail>>(
        characterDetailProvider(characterId),
        (previous, next) {},
        fireImmediately: true,
      );
      await pumpEventQueue();
      expect(fakeRepository.fetchDetailCallCountFor(characterId), 1);

      fakeSyncer.resultToReturn = const {};
      fakeConnectivity.emitRestored();
      await pumpEventQueue();

      expect(
        fakeRepository.fetchDetailCallCountFor(characterId),
        1,
        reason:
            'aucune invalidation ne doit se produire pour un characterId '
            'jamais retourne par sync().',
      );
    });

    test('retour de connectivite : chaque evenement onConnectivityRestored '
        'declenche une nouvelle tentative de synchro', () async {
      fakeSyncer.resultToReturn = const {};
      container.read(characterWriteSyncCoordinatorProvider);
      await pumpEventQueue();
      expect(fakeSyncer.callCount, 1, reason: 'synchro de demarrage');

      fakeConnectivity.emitRestored();
      await pumpEventQueue();
      expect(fakeSyncer.callCount, 2);

      fakeConnectivity.emitRestored();
      await pumpEventQueue();
      expect(fakeSyncer.callCount, 3);
    });

    test('dispose() annule l abonnement a onConnectivityRestored : plus '
        'aucune synchro declenchee apres', () async {
      fakeSyncer.resultToReturn = const {};
      final coordinator = container.read(characterWriteSyncCoordinatorProvider);
      await pumpEventQueue();
      expect(fakeSyncer.callCount, 1);

      coordinator.dispose();
      fakeConnectivity.emitRestored();
      await pumpEventQueue();

      expect(
        fakeSyncer.callCount,
        1,
        reason:
            'dispose() doit annuler _subscription : un evenement de '
            'connectivite restauree emis apres ne doit plus jamais '
            'declencher sync().',
      );
    });

    test('plusieurs characterId synchronises en une seule passe invalident '
        'chacun leur characterDetailProvider respectif', () async {
      const idA = 'char-a';
      const idB = 'char-b';
      fakeRepository.detailByCharacterId[idA] = _detailWithHp(1, id: idA);
      fakeRepository.detailByCharacterId[idB] = _detailWithHp(1, id: idB);
      fakeSyncer.resultToReturn = const {};

      container.read(characterWriteSyncCoordinatorProvider);
      await pumpEventQueue();

      container.listen<AsyncValue<CharacterDetail>>(
        characterDetailProvider(idA),
        (previous, next) {},
        fireImmediately: true,
      );
      container.listen<AsyncValue<CharacterDetail>>(
        characterDetailProvider(idB),
        (previous, next) {},
        fireImmediately: true,
      );
      await pumpEventQueue();
      expect(fakeRepository.fetchDetailCallCountFor(idA), 1);
      expect(fakeRepository.fetchDetailCallCountFor(idB), 1);

      fakeSyncer.resultToReturn = {idA, idB};
      fakeConnectivity.emitRestored();
      await pumpEventQueue();

      expect(fakeRepository.fetchDetailCallCountFor(idA), 2);
      expect(fakeRepository.fetchDetailCallCountFor(idB), 2);
    });
  });

  // D34 du registre de dette technique : une écriture abandonnée par
  // `PendingCharacterWriteSyncer` (refus non rejouable répété au-delà du
  // seuil) doit être signalée au joueur, pas disparaître silencieusement.
  // Ces tests passent par un vrai `AppDatabase`/`PendingCharacterWriteQueue`
  // (contrairement au reste de ce fichier) : `consumeAbandonedMessages` n'a
  // pas de double, voir la doc de classe de `PendingCharacterWriteQueue`.
  group('CharacterWriteSyncCoordinator : signalement des abandons (D34)', () {
    late AppDatabase db;
    late PendingCharacterWriteQueue queue;
    late _ScriptedSyncer fakeSyncer;
    late _FakeConnectivityChecker fakeConnectivity;
    late SupabaseClient signedInClient;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      queue = PendingCharacterWriteQueue(db);
      fakeSyncer = _ScriptedSyncer();
      fakeConnectivity = _FakeConnectivityChecker();
      signedInClient = await _buildSignedInClient(ownerId: 'owner-1');
    });

    tearDown(() async {
      await db.close();
    });

    /// Insère directement une ligne abandonnée (contourne le classement
    /// d'erreur du synchroniseur, hors périmètre de ce test de la couche
    /// présentation — déjà couvert par
    /// `test/core/cache/pending_character_write_queue_test.dart` et
    /// `character_repository_pending_writes_test.dart`).
    Future<void> seedAbandonedWrite(String message) async {
      await db
          .into(db.pendingCharacterWrites)
          .insert(
            PendingCharacterWritesCompanion.insert(
              characterId: 'char-1',
              ownerId: 'owner-1',
              kind: 'hp',
              payload: '{"currentHp":1,"temporaryHp":0}',
              queuedAt: DateTime.now(),
              failureCount: const Value(5),
              abandoned: const Value(true),
              lastFailureMessage: Value(message),
            ),
          );
    }

    testWidgets(
      "une écriture abandonnée affiche un SnackBar global dès que le "
      'coordinateur démarre, et ne le réaffiche plus ensuite',
      (tester) async {
        await seedAbandonedWrite('Vos PV abandonnés (test).');
        fakeSyncer.resultToReturn = const {};
        final messengerKey = GlobalKey<ScaffoldMessengerState>();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              pendingCharacterWriteSyncerProvider.overrideWithValue(
                fakeSyncer,
              ),
              connectivityCheckerProvider.overrideWithValue(fakeConnectivity),
              pendingCharacterWriteQueueProvider.overrideWithValue(queue),
              supabaseClientProvider.overrideWithValue(signedInClient),
              scaffoldMessengerKeyProvider.overrideWithValue(messengerKey),
            ],
            child: MaterialApp(
              scaffoldMessengerKey: messengerKey,
              home: Consumer(
                builder: (context, ref, _) {
                  ref.watch(characterWriteSyncCoordinatorProvider);
                  return const Scaffold(body: SizedBox());
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Vos PV abandonnés (test).'), findsOneWidget);
        expect(
          (await db.select(db.pendingCharacterWrites).get()),
          isEmpty,
          reason: 'consommée (et donc supprimée) une fois affichée',
        );

        // Un nouveau retour de connectivité ne doit plus rien réafficher :
        // déjà consommée.
        await tester.pumpWidget(Container());
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              pendingCharacterWriteSyncerProvider.overrideWithValue(
                fakeSyncer,
              ),
              connectivityCheckerProvider.overrideWithValue(fakeConnectivity),
              pendingCharacterWriteQueueProvider.overrideWithValue(queue),
              supabaseClientProvider.overrideWithValue(signedInClient),
              scaffoldMessengerKeyProvider.overrideWithValue(messengerKey),
            ],
            child: MaterialApp(
              scaffoldMessengerKey: messengerKey,
              home: Consumer(
                builder: (context, ref, _) {
                  ref.watch(characterWriteSyncCoordinatorProvider);
                  return const Scaffold(body: SizedBox());
                },
              ),
            ),
          ),
        );
        fakeConnectivity.emitRestored();
        await tester.pumpAndSettle();

        expect(
          find.text('Vos PV abandonnés (test).'),
          findsNothing,
          reason: "déjà consommée : ne doit jamais réapparaître à l'écran",
        );
      },
    );

    testWidgets(
      "sans écriture abandonnée, aucun SnackBar n'est affiché",
      (tester) async {
        fakeSyncer.resultToReturn = const {};
        final messengerKey = GlobalKey<ScaffoldMessengerState>();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              pendingCharacterWriteSyncerProvider.overrideWithValue(
                fakeSyncer,
              ),
              connectivityCheckerProvider.overrideWithValue(fakeConnectivity),
              pendingCharacterWriteQueueProvider.overrideWithValue(queue),
              supabaseClientProvider.overrideWithValue(signedInClient),
              scaffoldMessengerKeyProvider.overrideWithValue(messengerKey),
            ],
            child: MaterialApp(
              scaffoldMessengerKey: messengerKey,
              home: Consumer(
                builder: (context, ref, _) {
                  ref.watch(characterWriteSyncCoordinatorProvider);
                  return const Scaffold(body: SizedBox());
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsNothing);
      },
    );
  });
}

/// Même mécanisme que `character_repository_pending_writes_test.dart::
/// _buildSignedInClient` (transport HTTP fabriqué, session restaurée en
/// mémoire sans requête) — voir sa documentation. Dupliqué ici plutôt que
/// partagé : fichiers de test indépendants, par convention de ce dépôt (voir
/// D17 du registre de dette technique).
Future<SupabaseClient> _buildSignedInClient({required String ownerId}) async {
  final client = SupabaseClient(
    'https://fake.supabase.test',
    'fake-anon-key',
    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
  );
  await client.auth.recoverSession(
    jsonEncode({
      'access_token': 'fake-access-token-$ownerId',
      'token_type': 'bearer',
      'user': {'id': ownerId},
    }),
  );
  return client;
}

CharacterDetail _detailWithHp(int currentHp, {String id = 'char-1'}) {
  return CharacterDetail(
    id: id,
    name: 'Personnage de test',
    raceName: null,
    subraceName: null,
    backgroundName: null,
    alignmentName: null,
    classes: const [
      CharacterDetailClassRow(
        classId: 1,
        hitDie: 8,
        className: 'Guerrier',
        level: 1,
        isPrimary: true,
        savingThrowProficiencies: ['str', 'con'],
      ),
    ],
    xp: 0,
    currentHp: currentHp,
    maxHp: 30,
    temporaryHp: 0,
    abilityScores: const {
      'str': 10,
      'dex': 10,
      'con': 10,
      'int': 10,
      'wis': 10,
      'cha': 10,
    },
  );
}

/// Retourne systematiquement [resultToReturn] a chaque appel de sync(), tout
/// en comptant les appels -- jamais un vrai acces reseau/local (_client et
/// _pendingWrites du parent ne sont jamais lus par sync() overrides
/// ci-dessous).
class _ScriptedSyncer extends PendingCharacterWriteSyncer {
  _ScriptedSyncer() : this._(AppDatabase(NativeDatabase.memory()));

  _ScriptedSyncer._(AppDatabase db)
    : super(
        SupabaseClient('https://fake.supabase.test', 'fake-anon-key'),
        PendingCharacterWriteQueue(db),
        ReferenceDataCache(db),
      );

  Set<String> resultToReturn = const {};
  int callCount = 0;

  @override
  Future<Set<String>> sync() async {
    callCount++;
    return resultToReturn;
  }
}

/// onConnectivityRestored pilote manuellement via [emitRestored] -- jamais le
/// vrai canal de plateforme connectivity_plus.
class _FakeConnectivityChecker implements ConnectivityChecker {
  final _controller = StreamController<bool>.broadcast();

  @override
  Future<bool> hasConnection() async => true;

  @override
  Stream<bool> get onConnectivityRestored => _controller.stream;

  void emitRestored() => _controller.add(true);
}

/// Double minimal de CharacterRepository -- seul fetchCharacterDetail est
/// exerce par ces tests (compte les appels, par characterId, pour detecter
/// une invalidation suivie d'un rafraichissement effectif).
class _FakeCharacterRepository implements CharacterRepository {
  CharacterDetail? detailToReturn;
  final Map<String, CharacterDetail> detailByCharacterId = {};
  final Map<String, int> _fetchCallCountByCharacterId = {};

  int fetchDetailCallCountFor(String characterId) =>
      _fetchCallCountByCharacterId[characterId] ?? 0;

  @override
  Future<List<CharacterSummary>> fetchCharacters() async => const [];

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) async {
    _fetchCallCountByCharacterId[characterId] =
        (_fetchCallCountByCharacterId[characterId] ?? 0) + 1;
    return detailByCharacterId[characterId] ??
        detailToReturn ??
        _detailWithHp(0, id: characterId);
  }

  @override
  Future<WriteOutcome> setDead({
    required String characterId,
    required bool isDead,
  }) async => WriteOutcome.synced;

  @override
  Future<WriteOutcome> setArchived({
    required String characterId,
    required bool isArchived,
  }) async => WriteOutcome.synced;

  @override
  Future<WriteOutcome> deleteCharacter({required String characterId}) async =>
      WriteOutcome.synced;

  @override
  Future<WriteOutcome> setInspiration({
    required String characterId,
    required bool inspiration,
  }) async => WriteOutcome.synced;

  @override
  Future<WriteOutcome> setSpellFavorite({
    required String characterId,
    required int spellId,
    required bool isFavorite,
  }) async => WriteOutcome.synced;

  @override
  Future<WriteOutcome> setSpellPrepared({
    required String characterId,
    required int spellId,
    required bool prepared,
  }) async => WriteOutcome.synced;

  @override
  Future<WriteOutcome> updateHp({
    required String characterId,
    required int currentHp,
    required int temporaryHp,
  }) async => WriteOutcome.synced;

  @override
  Future<String> uploadPortrait({
    required String characterId,
    required dynamic bytes,
  }) async => 'https://example.com/portrait.png';

  @override
  Future<void> removePortrait({
    required String characterId,
    required String portraitUrl,
  }) async {}

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
  }) async => WriteOutcome.synced;

  @override
  Future<LevelUpLevelData> fetchLevelUpLevelData({
    required Object classId,
    required int targetLevel,
  }) {
    throw UnimplementedError();
  }

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
  }) async {}

  @override
  Future<void> leaveStory({required String characterCampaignId}) async {}

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
  Future<WriteOutcome> equipWeaponToSlot({
    required String characterId,
    required String inventoryId,
    required WeaponSlot slot,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WriteOutcome> setInventoryItemAttuned({
    required String characterId,
    required String inventoryId,
    required bool attuned,
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
    bool isPactSlot = false,
  }) async {
    throw UnimplementedError();
  }

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
  }) async {
    throw UnimplementedError();
  }
}
