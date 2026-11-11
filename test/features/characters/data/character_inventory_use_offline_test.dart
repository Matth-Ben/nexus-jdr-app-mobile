// T5b-3 (P15) : usage d'un objet (`useInventoryItem`) en file hors ligne
// (`inventoryItem`, op `quantity`), fusion avec l'ajout / le tombstone en file,
// rejeu et détection de conflit. Dépôt réel + file drift en mémoire + synchroniseur réel + faux serveur
// PostgREST du harnais (`test/support/`, table `character_inventory`
// simulée).

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/cache/app_database.dart'
    hide PendingCharacterWrite;
import 'package:personnages/core/cache/pending_character_write_queue.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/core/cache/sync_alert_store.dart';
import 'package:personnages/features/characters/data/character_detail_cache.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/data/pending_character_write_syncer.dart';
import 'package:personnages/features/characters/data/sync_alert_recorder.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../support/fake_character_write_server.dart';
import '../../../support/fake_connectivity_checker.dart';

const _characterId = 'char-1';
const _ownerA = 'owner-1';
const _ownerB = 'owner-2';
const _srv1 = '11111111-1111-4111-8111-111111111111';
const _srv2 = '22222222-2222-4222-8222-222222222222';
const _srvWeight = '33333333-3333-4333-8333-333333333333';
const _table = 'character_inventory';

Map<String, dynamic> _row(
  String id,
  String name, {
  int quantity = 1,
  bool equipped = false,
  bool attuned = false,
}) => {
  'id': id,
  'character_id': _characterId,
  'item_id': null,
  'custom_name': name,
  'quantity': quantity,
  'equipped': equipped,
  'weapon_slot': null,
  'is_attuned': attuned,
};

void main() {
  var clock = DateTime.utc(2026, 11, 10, 12);
  late AppDatabase db;
  late PendingCharacterWriteQueue queue;
  late ReferenceDataCache cache;
  late FakeConnectivityChecker connectivity;
  late FakeCharacterWriteServer server;
  late SupabaseClient client;
  late SupabaseCharacterRepository repository;
  late PendingCharacterWriteSyncer syncer;
  late List<Map<String, dynamic>> rows;

  setUp(() async {
    clock = DateTime.utc(2026, 11, 10, 12);
    db = AppDatabase(NativeDatabase.memory());
    queue = PendingCharacterWriteQueue(db, now: () => clock);
    cache = ReferenceDataCache(db);
    connectivity = FakeConnectivityChecker();
    rows = [
      _row(_srv1, 'Dague', quantity: 3),
      _row(_srv2, 'Corde', attuned: true),
    ];
    server = FakeCharacterWriteServer(
      characterRow: {
        'id': _characterId,
        'owner_id': _ownerA,
        'name': 'Aria',
        'xp': 100,
        'current_hp': 10,
        'max_hp': 12,
        'temporary_hp': 0,
        'character_classes': [
          {
            'class_id': 3,
            'level': 1,
            'is_primary': true,
            'classes': {
              'saving_throw_proficiencies': ['wis', 'cha'],
              'hit_die': 8,
            },
          },
        ],
        'character_ability_scores': [
          {'ability_id': 'wis', 'score': 10},
          {'ability_id': 'dex', 'score': 10},
        ],
        // Même liste que la table simulée : un POST/PATCH/DELETE est visible à
        // la relecture de la fiche.
        _table: rows,
      },
    );
    server.tables[_table] = rows;
    client = await buildSignedInClient(server, ownerId: _ownerA);
    repository = SupabaseCharacterRepository(
      client,
      cache,
      queue,
      connectivity,
    );
    syncer = PendingCharacterWriteSyncer(client, queue, cache, repository);
  });

  tearDown(() async {
    await connectivity.close();
    await db.close();
  });

  Future<CharacterDetail> openOnline() async {
    final detail = await repository.fetchCharacterDetail(_characterId);
    expect(detail.inventory, hasLength(rows.length));
    return detail;
  }

  void goOffline() {
    connectivity.goOffline();
    server.down = true;
  }

  void goOnline() {
    server.down = false;
    connectivity.goOnline();
  }

  Future<List<PendingCharacterWrite>> lines([
    PendingCharacterWriteKind kind = PendingCharacterWriteKind.inventoryItem,
  ]) async => [
    for (final line in await queue.allForOwner(_ownerA))
      if (line.kind == kind) line,
  ];

  Future<CharacterDetail> reopen() =>
      repository.fetchCharacterDetail(_characterId);

  List<RecordedRequest> inventoryWrites() => [
    for (final w in server.writes)
      if (w.table == _table) w,
  ];

  Future<String> addOffline(
    String name, {
    int quantity = 1,
    String? description,
    String? damageDice,
    String? damageType,
    List<String> properties = const [],
  }) async {
    goOffline();
    final outcome = await repository.addCustomInventoryItem(
      characterId: _characterId,
      customName: name,
      quantity: quantity,
      description: description,
      damageDice: damageDice,
      damageType: damageType,
      properties: properties,
    );
    expect(outcome, WriteOutcome.queued);
    // Même horodatage possible : l'ordre de file ne suit pas l'ordre d'appel.
    return (await lines())
        .singleWhere((l) => l.payload['customName'] == name)
        .targetId;
  }

  Future<void> syncUntilAbandoned() async {
    for (
      var i = 0;
      i < PendingCharacterWriteQueue.abandonAfterConsecutiveFailures;
      i++
    ) {
      await syncer.syncWithReport();
    }
  }

  Future<WriteOutcome> use(String id, int newQuantity) =>
      repository.useInventoryItem(
        characterId: _characterId,
        inventoryId: id,
        newQuantity: newQuantity,
      );

  Future<void> enqueueRaw(
    String targetId,
    Map<String, dynamic> payload, {
    String owner = _ownerA,
  }) => queue.enqueue(
    characterId: _characterId,
    ownerId: owner,
    kind: PendingCharacterWriteKind.inventoryItem,
    targetId: targetId,
    payload: payload,
  );

  int quantityOf(String id) =>
      rows.singleWhere((r) => r['id'] == id)['quantity'] as int;

  // ---------------------------------------------------------------------
  group('dépôt : usage hors ligne', () {
    test('hors ligne : queued, quantité effective décrémentée, ligne en file '
        'avec quantity + base, aucune requête', () async {
      await openOnline();
      goOffline();

      expect(await use(_srv1, 2), WriteOutcome.queued);

      final line = (await lines()).single;
      expect(line.targetId, _srv1);
      expect(line.payload, {'op': 'quantity', 'quantity': 2, 'base': 3});
      expect(server.writes, isEmpty);
      final detail = await reopen();
      expect(detail.inventory.singleWhere((i) => i.id == _srv1).quantity, 2);
      expect(quantityOf(_srv1), 3, reason: "le serveur n'a pas bougé");
    });

    test(
      'fiche jamais mise en cache : payload sans base (pas de détection)',
      () async {
        goOffline();

        expect(await use(_srv1, 2), WriteOutcome.queued);

        expect((await lines()).single.payload, {
          'op': 'quantity',
          'quantity': 2,
        });
      },
    );

    test(
      'erreur de transport en ligne : queued, base = quantité connue',
      () async {
        await openOnline();
        server.failBefore(1);

        expect(await use(_srv1, 2), WriteOutcome.queued);

        expect((await lines()).single.payload, {
          'op': 'quantity',
          'quantity': 2,
          'base': 3,
        });
      },
    );

    test('en ligne : UPDATE filtré id + personnage, synced, rien en file, '
        'cache de la fiche à jour', () async {
      await openOnline();

      expect(await use(_srv1, 2), WriteOutcome.synced);

      final patch = inventoryWrites().single;
      expect(patch.method, 'PATCH');
      expect(patch.query['id'], 'eq.$_srv1');
      expect(patch.query['character_id'], 'eq.$_characterId');
      expect(patch.body, {'quantity': 2});
      expect(quantityOf(_srv1), 2);
      expect(await queue.allForOwner(_ownerA), isEmpty);
      goOffline();
      expect(
        (await reopen()).inventory.singleWhere((i) => i.id == _srv1).quantity,
        2,
      );
    });

    test('en ligne, quantité 0 : DELETE, ligne retirée du cache', () async {
      await openOnline();

      expect(await use(_srv2, 0), WriteOutcome.synced);

      expect(inventoryWrites().single.method, 'DELETE');
      expect(rows.map((r) => r['id']), [_srv1]);
      goOffline();
      expect((await reopen()).inventory.map((i) => i.id), [_srv1]);
    });

    for (final code in ['42501', '23514']) {
      test('refus $code en ligne : échec, rien en file', () async {
        await openOnline();
        server.rejectWith(code);

        await expectLater(use(_srv1, 2), throwsA(isA<CharacterFailure>()));

        expect(await queue.allForOwner(_ownerA), isEmpty);
      });
    }

    test('zéro ligne en ligne (ligne absente du serveur) : échec, rien en '
        'file', () async {
      await openOnline();
      rows.removeWhere((r) => r['id'] == _srv1);

      await expectLater(use(_srv1, 2), throwsA(isA<CharacterFailure>()));

      expect(await queue.allForOwner(_ownerA), isEmpty);
    });

    test(
      'identifiant de ligne illisible hors ligne : refusé, rien en file',
      () async {
        goOffline();

        await expectLater(use('inv-1', 1), throwsA(isA<CharacterFailure>()));

        expect(await queue.allForOwner(_ownerA), isEmpty);
      },
    );

    test("en ligne avec un usage resté en file : écrit la valeur absolue et "
        "retire l'entrée périmée", () async {
      await openOnline();
      goOffline();
      await use(_srv1, 2);
      goOnline();

      expect(await use(_srv1, 1), WriteOutcome.synced);

      expect(quantityOf(_srv1), 1);
      expect(await queue.allForOwner(_ownerA), isEmpty);
      expect(inventoryWrites(), hasLength(1));
    });
  });

  // ---------------------------------------------------------------------
  group('fusion avec les autres écritures de la ligne', () {
    test('deux usages hors ligne : une seule ligne, valeur chaînée, base du '
        'premier conservée', () async {
      await openOnline();
      goOffline();

      await use(_srv1, 2);
      await use(_srv1, 1);

      final line = (await lines()).single;
      expect(line.payload, {'op': 'quantity', 'quantity': 1, 'base': 3});
      expect(
        (await reopen()).inventory.singleWhere((i) => i.id == _srv1).quantity,
        1,
      );
    });

    test(
      "base du premier enfilage conservée même si le cache a été rafraîchi "
      'entre-temps (relecture en ligne après une modification ailleurs)',
      () async {
        await openOnline();
        goOffline();
        await use(_srv1, 2);
        goOnline();
        rows.singleWhere((r) => r['id'] == _srv1)['quantity'] = 7;
        await reopen();
        goOffline();

        await use(_srv1, 1);

        expect((await lines()).single.payload, {
          'op': 'quantity',
          'quantity': 1,
          'base': 3,
        });
      },
    );

    test(
      "usage jusqu'à 0 : tombstone, ligne masquée, rejeu = DELETE",
      () async {
        await openOnline();
        goOffline();

        await use(_srv2, 0);

        expect((await lines()).single.payload, {'op': 'delete'});
        expect((await reopen()).inventory.map((i) => i.id), [_srv1]);
        goOnline();
        expect(await syncer.sync(), {_characterId});
        expect(inventoryWrites().single.method, 'DELETE');
        expect(rows.map((r) => r['id']), [_srv1]);
      },
    );

    test("usage chaîné jusqu'à 0 : le tombstone remplace l'usage", () async {
      await openOnline();
      goOffline();
      await use(_srv1, 2);
      await use(_srv1, 1);

      await use(_srv1, 0);

      expect((await lines()).single.payload, {'op': 'delete'});
    });

    test("usage puis retrait : tombstone (remplace l'usage)", () async {
      await openOnline();
      goOffline();
      await use(_srv1, 2);

      await repository.removeInventoryItem(
        characterId: _characterId,
        inventoryId: _srv1,
      );

      expect((await lines()).single.payload, {'op': 'delete'});
      expect((await reopen()).inventory.map((i) => i.id), [_srv2]);
    });

    test("usage d'une ligne dont l'ajout est en file : la quantité du "
        "payload d'ajout est modifiée, une seule ligne, un seul INSERT au "
        'rejeu avec la bonne quantité', () async {
      final id = await addOffline('Potion', quantity: 3);

      expect(await use(id, 2), WriteOutcome.queued);
      expect(await use(id, 1), WriteOutcome.queued);

      final line = (await lines()).single;
      expect(line.payload, {
        'op': 'add',
        'customName': 'Potion',
        'quantity': 1,
      });
      goOnline();
      final report = await syncer.syncWithReport();
      expect(report.synced, {_characterId});
      expect(report.conflicts, isEmpty);
      final posts = inventoryWrites();
      expect(posts.map((w) => w.method), ['POST']);
      expect((posts.single.body! as Map)['quantity'], 1);
      expect(quantityOf(id), 1);
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });

    test("INSERT à réponse perdue puis usage de la ligne : le rejeu (23505) "
        'réaligne la quantité effective sur le serveur', () async {
      final id = await addOffline('Potion', quantity: 3);
      goOnline();
      server.failAfterApply(1);
      expect(await syncer.sync(), isEmpty);
      expect(quantityOf(id), 3);

      expect(await use(id, 1), WriteOutcome.queued);
      final report = await syncer.syncWithReport();

      expect(report.synced, {_characterId});
      expect(quantityOf(id), 1);
      expect(rows.where((r) => r['id'] == id), hasLength(1));
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });

    test(
      "usage d'une ligne ajoutée avec état initial : l'état est conservé",
      () async {
        final id = await addOffline('Anneau');
        await repository.setInventoryItemAttuned(
          characterId: _characterId,
          inventoryId: id,
          attuned: true,
        );

        expect(await use(id, 4), WriteOutcome.queued);

        final payload = (await lines()).single.payload;
        expect(payload['quantity'], 4);
        expect(payload['attuned'], true);
      },
    );

    test("usage jusqu'à 0 d'une ligne dont l'ajout est en file : tombstone, "
        "ligne masquée, rejeu = DELETE idempotent (aucun INSERT)", () async {
      await openOnline();
      final id = await addOffline('Éphémère', quantity: 1);

      expect(await use(id, 0), WriteOutcome.queued);

      expect((await lines()).single.payload, {'op': 'delete'});
      expect((await reopen()).inventory.map((i) => i.id), [_srv1, _srv2]);
      goOnline();
      expect(await syncer.sync(), {_characterId});
      expect(inventoryWrites().map((w) => w.method), ['DELETE']);
      expect(rows.map((r) => r['id']), [_srv1, _srv2]);
    });

    test("usage d'une ligne dont le tombstone est en file : refusé "
        '(CharacterFailure), le tombstone reste', () async {
      goOffline();
      await repository.removeInventoryItem(
        characterId: _characterId,
        inventoryId: _srv1,
      );

      await expectLater(use(_srv1, 1), throwsA(isA<CharacterFailure>()));

      expect((await lines()).single.payload, {'op': 'delete'});
    });

    test('usage + équipement hors ligne : deux lignes indépendantes '
        '(inventoryItem + inventoryState), les deux rejouées', () async {
      await openOnline();
      goOffline();

      await use(_srv1, 2);
      expect(
        await repository.setInventoryItemEquipped(
          characterId: _characterId,
          inventoryId: _srv1,
          equipped: true,
        ),
        WriteOutcome.queued,
      );

      expect(await lines(), hasLength(1));
      expect(
        await lines(PendingCharacterWriteKind.inventoryState),
        hasLength(1),
      );
      final detail = await reopen();
      final item = detail.inventory.singleWhere((i) => i.id == _srv1);
      expect(item.quantity, 2);
      expect(item.equipped, isTrue);
      goOnline();
      final report = await syncer.syncWithReport();
      expect(report.abandonedCharacterIds, isEmpty);
      expect(quantityOf(_srv1), 2);
      expect(rows.singleWhere((r) => r['id'] == _srv1)['equipped'], true);
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });

    test("usage jusqu'à 0 avec un état en file : l'état est purgé (pas de "
        'UPDATE sur zéro ligne)', () async {
      await openOnline();
      goOffline();
      await repository.setInventoryItemEquipped(
        characterId: _characterId,
        inventoryId: _srv1,
        equipped: true,
      );

      await use(_srv1, 0);

      expect(await lines(PendingCharacterWriteKind.inventoryState), isEmpty);
      goOnline();
      final report = await syncer.syncWithReport();
      expect(report.abandonedCharacterIds, isEmpty);
      expect(rows.map((r) => r['id']), [_srv2]);
    });
  });

  // ---------------------------------------------------------------------
  group('rejeu', () {
    Future<void> useOffline(String id, int quantity) async {
      await openOnline();
      goOffline();
      expect(await use(id, quantity), WriteOutcome.queued);
    }

    test('UPDATE quantity absolu filtré id + personnage, ligne retirée de la '
        'file, cache à jour', () async {
      await useOffline(_srv1, 2);
      goOnline();

      final report = await syncer.syncWithReport();

      expect(report.synced, {_characterId});
      expect(report.conflicts, isEmpty);
      final patch = inventoryWrites().single;
      expect(patch.method, 'PATCH');
      expect(patch.query['id'], 'eq.$_srv1');
      expect(patch.query['character_id'], 'eq.$_characterId');
      expect(patch.body, {'quantity': 2});
      expect(quantityOf(_srv1), 2);
      expect(await queue.allForOwner(_ownerA), isEmpty);
      goOffline();
      expect(
        (await reopen()).inventory.singleWhere((i) => i.id == _srv1).quantity,
        2,
      );
    });

    test("idempotent : réponse perdue après l'UPDATE, le rejeu réécrit la "
        'même valeur absolue', () async {
      await useOffline(_srv1, 2);
      goOnline();
      server.failAfterApply(1);

      expect(await syncer.sync(), isEmpty);
      expect(quantityOf(_srv1), 2);
      expect(await lines(), hasLength(1));

      final report = await syncer.syncWithReport();

      expect(report.synced, {_characterId});
      expect(quantityOf(_srv1), 2);
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });

    test("conflit : serveur modifié entre-temps, l'écriture part quand même "
        'et un ServerValueConflict est signalé', () async {
      await useOffline(_srv1, 2);
      rows.singleWhere((r) => r['id'] == _srv1)['quantity'] = 7;
      goOnline();

      final report = await syncer.syncWithReport();

      expect(report.synced, {_characterId});
      expect(quantityOf(_srv1), 2);
      final conflict = report.conflicts.single;
      expect(conflict.characterId, _characterId);
      expect(conflict.kind, PendingCharacterWriteKind.inventoryItem);
      expect(conflict.serverValue, {'quantity': 7});
      expect(conflict.queuedValue, {'quantity': 2});
    });

    test('base conservée sur deux usages : le conflit se compare à la base '
        'du premier enfilage', () async {
      await useOffline(_srv1, 2);
      await use(_srv1, 1);
      rows.singleWhere((r) => r['id'] == _srv1)['quantity'] = 2;
      goOnline();

      final report = await syncer.syncWithReport();

      expect(quantityOf(_srv1), 1);
      expect(report.conflicts.single.serverValue, {'quantity': 2});
    });

    test('serveur inchangé (égal à la base) : aucun conflit', () async {
      await useOffline(_srv1, 2);
      goOnline();

      expect((await syncer.syncWithReport()).conflicts, isEmpty);
    });

    test('pas de faux conflit après une réponse perdue (serveur déjà égal à '
        'la valeur en file)', () async {
      await useOffline(_srv1, 2);
      goOnline();
      server.failAfterApply(1);
      await syncer.syncWithReport();

      final report = await syncer.syncWithReport();

      expect(report.synced, {_characterId});
      expect(report.conflicts, isEmpty);
    });

    test(
      'base absente : écriture sans détection, aucune lecture préalable',
      () async {
        await enqueueRaw(_srv1, {'op': 'quantity', 'quantity': 2});
        rows.singleWhere((r) => r['id'] == _srv1)['quantity'] = 9;
        goOnline();

        final report = await syncer.syncWithReport();

        expect(report.synced, {_characterId});
        expect(report.conflicts, isEmpty);
        expect(quantityOf(_srv1), 2);
        expect(
          server.requests.where((r) => r.table == _table && !r.isWrite),
          isEmpty,
        );
      },
    );

    test('base invalide : traitée comme absente (pas de détection), le '
        'payload reste valide', () async {
      await enqueueRaw(_srv1, {'op': 'quantity', 'quantity': 2, 'base': 'x'});
      rows.singleWhere((r) => r['id'] == _srv1)['quantity'] = 9;
      goOnline();

      final report = await syncer.syncWithReport();

      expect(report.synced, {_characterId});
      expect(report.conflicts, isEmpty);
      expect(quantityOf(_srv1), 2);
    });

    test(
      'quantité 0 en file : rejoué comme un DELETE, zéro ligne = succès',
      () async {
        await enqueueRaw(_srv1, {'op': 'quantity', 'quantity': 0});
        rows.removeWhere((r) => r['id'] == _srv1);
        goOnline();

        final report = await syncer.syncWithReport();

        expect(report.synced, {_characterId});
        expect(inventoryWrites().single.method, 'DELETE');
        expect(await queue.allForOwner(_ownerA), isEmpty);
      },
    );

    test('zéro ligne au rejeu (ligne supprimée ailleurs) : abandon au seuil '
        'puis alerte « votre inventaire »', () async {
      await useOffline(_srv1, 2);
      rows.removeWhere((r) => r['id'] == _srv1);
      goOnline();

      await syncUntilAbandoned();

      expect(await queue.allForOwner(_ownerA), isEmpty);
      final recorder = SyncAlertRecorder(
        db,
        queue,
        SyncAlertStore(db),
        CharacterDetailCache(cache),
      );
      final alerts = await recorder.recordAbandoned(_ownerA);
      expect(alerts.single.kindKey, 'inventory_item');
      expect(alerts.single.message, contains('votre inventaire'));
    });

    const validId = '55555555-5555-4555-8555-555555555555';
    for (final bad in <(String, Map<String, dynamic>)>[
      (validId, {'op': 'quantity'}),
      (validId, {'op': 'quantity', 'quantity': -1}),
      (validId, {'op': 'quantity', 'quantity': 1.5}),
      (validId, {'op': 'quantity', 'quantity': '2'}),
      (validId, {'op': 'quantity', 'quantity': null}),
      (validId, {'op': 'quantity', 'quantity': 2147483648}),
      (validId, {'op': 'inconnue', 'quantity': 2}),
      ('pas-un-uuid', {'op': 'quantity', 'quantity': 2}),
      ('', {'op': 'quantity', 'quantity': 2}),
    ]) {
      test(
        'payload invalide $bad : aucune écriture, ligne supprimée, compteur '
        "à 0, les autres lignes (et celles d'un autre compte) intactes",
        () async {
          await enqueueRaw(bad.$1, bad.$2);
          await enqueueRaw(bad.$1, bad.$2, owner: _ownerB);
          clock = clock.add(const Duration(seconds: 5));
          await queue.enqueue(
            characterId: _characterId,
            ownerId: _ownerA,
            kind: PendingCharacterWriteKind.xp,
            targetId: '',
            payload: {'newXp': 250},
          );
          clock = clock.add(const Duration(seconds: 5));
          await enqueueRaw(_srv2, {'op': 'quantity', 'quantity': 0});
          expect(await queue.watchPendingCount(_ownerA).first, 3);

          final synced = await syncer.sync();

          expect(synced, {_characterId});
          expect(await queue.allForOwner(_ownerA), isEmpty);
          expect(await queue.watchPendingCount(_ownerA).first, 0);
          expect(await queue.allForOwner(_ownerB), hasLength(1));
          expect(server.characterRow['xp'], 250);
          expect(inventoryWrites().map((w) => w.method), ['DELETE']);
          expect(rows.map((r) => r['id']), [_srv1]);
        },
      );
    }
  });

  // ---------------------------------------------------------------------
  group('isolation, purge et superposition', () {
    test("isolation par ownerId : le rejeu d'un compte ne touche jamais la "
        "file d'un autre", () async {
      await enqueueRaw('77777777-7777-4777-8777-777777777777', {
        'op': 'quantity',
        'quantity': 2,
      }, owner: _ownerB);
      await openOnline();
      goOffline();
      await use(_srv1, 2);
      goOnline();

      expect(await syncer.sync(), {_characterId});

      expect(await queue.allForOwner(_ownerB), hasLength(1));
      expect(inventoryWrites(), hasLength(1));
    });

    test("purge : removeAllForOwner retire les usages en file, pas ceux d'un "
        'autre compte', () async {
      await openOnline();
      goOffline();
      await use(_srv1, 2);
      await enqueueRaw('77777777-7777-4777-8777-777777777777', {
        'op': 'quantity',
        'quantity': 2,
      }, owner: _ownerB);

      await queue.removeAllForOwner(_ownerA);

      expect(await queue.allForOwner(_ownerA), isEmpty);
      expect(await queue.allForOwner(_ownerB), hasLength(1));
    });

    test('superposition : poids total et dérivés suivent la quantité '
        'effective ; une ligne à 0 est masquée', () async {
      rows.add({
        ..._row(_srvWeight, 'Sac', quantity: 4),
        'item_id': 5,
        'items': {'category': 'equipement_general', 'weight': 2.5},
      });
      final before = await openOnline();
      expect(before.inventoryWeight, 10);
      goOffline();

      await use(_srvWeight, 3);
      expect((await reopen()).inventoryWeight, 7.5);
      await use(_srvWeight, 0);

      final after = await reopen();
      expect(after.inventoryWeight, 0);
      expect(after.inventory.map((i) => i.id), isNot(contains(_srvWeight)));
    });

    test('payload invalide en file : ignoré par la superposition', () async {
      await openOnline();
      await enqueueRaw(_srv1, {'op': 'quantity', 'quantity': -3});
      goOffline();

      final item = (await reopen()).inventory.singleWhere((i) => i.id == _srv1);
      expect(item.quantity, 3);
    });
  });
}
