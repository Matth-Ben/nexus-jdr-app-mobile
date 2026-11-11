// T5b-1 (P15) : ajout d'objet personnalisé et retrait de ligne d'inventaire en
// file hors ligne (`inventoryItem`), et leur interaction avec `inventoryState`
// (T5a). Dépôt réel + file drift en mémoire + synchroniseur réel + faux serveur
// PostgREST du harnais (`test/support/`, table `character_inventory`
// simulée).

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/cache/app_database.dart'
    hide PendingCharacterWrite;
import 'package:personnages/core/cache/pending_character_write_queue.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/core/cache/sync_alert_store.dart';
import 'package:personnages/core/utils/uuid_v4.dart';
import 'package:personnages/features/characters/data/character_detail_cache.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/data/pending_character_write_syncer.dart';
import 'package:personnages/features/characters/data/sync_alert_recorder.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/weapon_slot.dart';
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
const _srvArmor = '44444444-4444-4444-8444-444444444444';
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
    rows = [_row(_srv1, 'Dague'), _row(_srv2, 'Corde', attuned: true)];
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

  Future<List<String>> consumeAlerts() async => [
    for (final a in await queue.consumeAbandoned(ownerId: _ownerA)) a.message,
  ];

  Future<void> syncUntilAbandoned() async {
    for (
      var i = 0;
      i < PendingCharacterWriteQueue.abandonAfterConsecutiveFailures;
      i++
    ) {
      await syncer.syncWithReport();
    }
  }

  // ---------------------------------------------------------------------
  group('dépôt : ajout d\'un objet personnalisé', () {
    test('hors ligne : queued, UUID client, une ligne, objet visible dans la '
        'fiche, aucune écriture réseau', () async {
      await openOnline();

      final id = await addOffline(
        'Zanbato',
        quantity: 2,
        description: 'Une lame',
        damageDice: '2d6',
        damageType: 'tranchant',
        properties: const ['lourde'],
      );

      expect(isUuid(id), isTrue);
      final line = (await lines()).single;
      expect(line.targetId, id);
      expect(line.payload, {
        'op': 'add',
        'customName': 'Zanbato',
        'quantity': 2,
        'customDescription': 'Une lame',
        'customDamageDice': '2d6',
        'customDamageType': 'tranchant',
        'customProperties': ['lourde'],
      });
      expect(server.writes, isEmpty);
      final detail = await reopen();
      final item = detail.inventory.singleWhere((i) => i.id == id);
      expect(item.name, 'Zanbato');
      expect(item.quantity, 2);
      expect(item.isCustom, isTrue);
      expect(item.description, 'Une lame');
      expect(item.weaponProperties!.damageDice, '2d6');
      expect(item.weaponProperties!.damageType, 'tranchant');
      expect(item.weaponProperties!.properties, ['lourde']);
      expect(item.equipped, isFalse);
      expect(detail.inventory, hasLength(3));
    });

    test('champs personnalisés vides : absents du payload', () async {
      await addOffline('Amulette', description: '');

      expect((await lines()).single.payload, {
        'op': 'add',
        'customName': 'Amulette',
        'quantity': 1,
      });
    });

    test('erreur de transport en ligne : queued', () async {
      server.failBefore(1);

      final outcome = await repository.addCustomInventoryItem(
        characterId: _characterId,
        customName: 'Amulette',
        quantity: 1,
      );

      expect(outcome, WriteOutcome.queued);
      final line = (await lines()).single;
      expect(line.payload['customName'], 'Amulette');
      expect(isUuid(line.targetId), isTrue);
    });

    test('en ligne : INSERT immédiat avec l\'UUID client, synced, rien en '
        'file, cache de la fiche à jour', () async {
      await openOnline();

      final outcome = await repository.addCustomInventoryItem(
        characterId: _characterId,
        customName: 'Amulette',
        quantity: 3,
      );

      expect(outcome, WriteOutcome.synced);
      final post = inventoryWrites().single;
      expect(post.method, 'POST');
      final body = post.body! as Map;
      expect(isUuid(body['id'] as String), isTrue);
      expect(body['character_id'], _characterId);
      expect(body['custom_name'], 'Amulette');
      expect(body['quantity'], 3);
      expect(body.containsKey('custom_description'), isFalse);
      expect(rows.where((r) => r['id'] == body['id']), hasLength(1));
      expect(await queue.allForOwner(_ownerA), isEmpty);
      final cached = await CharacterDetailCache(cache)
          .readRow(ownerId: _ownerA, characterId: _characterId);
      final cachedRows = cached!['character_inventory'] as List;
      expect(cachedRows.map((r) => (r as Map)['id']), contains(body['id']));
      goOffline();
      expect(
        (await reopen()).inventory.map((i) => i.name),
        contains('Amulette'),
      );
    });

    for (final code in ['42501', '23514']) {
      test('refus $code : échec, rien en file (ajout et retrait)', () async {
        server.rejectWith(code);

        await expectLater(
          repository.addCustomInventoryItem(
            characterId: _characterId,
            customName: 'Amulette',
            quantity: 1,
          ),
          throwsA(isA<CharacterFailure>()),
        );
        await expectLater(
          repository.removeInventoryItem(
            characterId: _characterId,
            inventoryId: _srv1,
          ),
          throwsA(isA<CharacterFailure>()),
        );
        expect(await queue.allForOwner(_ownerA), isEmpty);
      });
    }

    test('nom vide ou trop long, quantité < 1 : refusé, rien en file ni en '
        'réseau', () async {
      goOffline();

      for (final (name, quantity) in [
        ('', 1),
        ('   ', 1),
        ('x' * 201, 1),
        ('Amulette', 0),
        ('Amulette', -2),
      ]) {
        await expectLater(
          repository.addCustomInventoryItem(
            characterId: _characterId,
            customName: name,
            quantity: quantity,
          ),
          throwsA(isA<CharacterFailure>()),
        );
      }
      expect(await queue.allForOwner(_ownerA), isEmpty);
      expect(server.writes, isEmpty);
    });
  });

  // ---------------------------------------------------------------------
  group('dépôt : retrait', () {
    test('ligne serveur hors ligne : tombstone, ligne masquée, aucune '
        'écriture réseau', () async {
      await openOnline();
      goOffline();

      final outcome = await repository.removeInventoryItem(
        characterId: _characterId,
        inventoryId: _srv1,
      );

      expect(outcome, WriteOutcome.queued);
      final line = (await lines()).single;
      expect(line.targetId, _srv1);
      expect(line.payload, {'op': 'delete'});
      expect(server.writes, isEmpty);
      expect((await reopen()).inventory.map((i) => i.id), [_srv2]);
    });

    test('retrait déjà en file : idempotent, la ligne de file est inchangée '
        '(même version)', () async {
      goOffline();
      await repository.removeInventoryItem(
        characterId: _characterId,
        inventoryId: _srv1,
      );
      final before = (await lines()).single;
      clock = clock.add(const Duration(seconds: 5));

      final outcome = await repository.removeInventoryItem(
        characterId: _characterId,
        inventoryId: _srv1,
      );

      expect(outcome, WriteOutcome.queued);
      final after = (await lines()).single;
      expect(after.rawPayload, before.rawPayload);
      expect(after.queuedAt, before.queuedAt);
    });

    test('erreur de transport en ligne : tombstone en file, queued', () async {
      server.failBefore(1);

      final outcome = await repository.removeInventoryItem(
        characterId: _characterId,
        inventoryId: _srv1,
      );

      expect(outcome, WriteOutcome.queued);
      expect((await lines()).single.payload, {'op': 'delete'});
    });

    test(
      'en ligne : DELETE filtré id + character_id, synced, cache à jour',
      () async {
        await openOnline();

        final outcome = await repository.removeInventoryItem(
          characterId: _characterId,
          inventoryId: _srv1,
        );

        expect(outcome, WriteOutcome.synced);
        final delete = inventoryWrites().single;
        expect(delete.method, 'DELETE');
        expect(delete.query['id'], 'eq.$_srv1');
        expect(delete.query['character_id'], 'eq.$_characterId');
        expect(rows.map((r) => r['id']), [_srv2]);
        goOffline();
        expect((await reopen()).inventory.map((i) => i.id), [_srv2]);
      },
    );

    test('identifiant non UUID hors ligne : refusé (jamais accepté puis '
        'supprimé au rejeu)', () async {
      goOffline();

      await expectLater(
        repository.removeInventoryItem(
          characterId: _characterId,
          inventoryId: 'inv-1',
        ),
        throwsA(isA<CharacterFailure>()),
      );
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });

    test('ajout puis retrait hors ligne : le tombstone REMPLACE l\'ajout (une '
        'tentative de rejeu a pu atteindre le serveur) ; au retour du réseau '
        'un seul DELETE idempotent, aucun INSERT, aucun doublon', () async {
      await openOnline();
      final id = await addOffline('Éphémère');

      final outcome = await repository.removeInventoryItem(
        characterId: _characterId,
        inventoryId: id,
      );

      expect(outcome, WriteOutcome.queued);
      expect((await lines()).single.payload, {'op': 'delete'});
      expect((await reopen()).inventory.map((i) => i.id), [_srv1, _srv2]);
      goOnline();
      final report = await syncer.syncWithReport();
      expect(report.synced, {_characterId});
      expect(report.abandonedCharacterIds, isEmpty);
      expect(inventoryWrites().map((w) => w.method), ['DELETE']);
      expect(rows.map((r) => r['id']), [_srv1, _srv2]);
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });

    test('ajout dont la réponse a été perdue, puis retrait : la ligne '
        'créée côté serveur est bien supprimée (cas que le simple retrait '
        'de la file laisserait fuir)', () async {
      final id = await addOffline('Fantôme');
      goOnline();
      server.failAfterApply(1);
      expect(await syncer.sync(), isEmpty);
      expect(rows.where((r) => r['id'] == id), hasLength(1));

      goOffline();
      await repository.removeInventoryItem(
        characterId: _characterId,
        inventoryId: id,
      );
      expect((await lines()).single.payload, {'op': 'delete'});
      goOnline();
      await syncer.sync();

      expect(rows.where((r) => r['id'] == id), isEmpty);
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });
  });

  // ---------------------------------------------------------------------
  group('interaction avec inventoryState', () {
    test('ajout + équipement + set d\'arme + harmonisation hors ligne : une '
        'seule ligne de file, un seul INSERT à l\'état final, aucune '
        'alerte', () async {
      await openOnline();
      final id = await addOffline('Épée runique');

      expect(
        await repository.setInventoryItemEquipped(
          characterId: _characterId,
          inventoryId: id,
          equipped: true,
        ),
        WriteOutcome.queued,
      );
      expect(
        await repository.equipWeaponToSlot(
          characterId: _characterId,
          inventoryId: id,
          slot: WeaponSlot.principal,
        ),
        WriteOutcome.queued,
      );
      expect(
        await repository.setInventoryItemAttuned(
          characterId: _characterId,
          inventoryId: id,
          attuned: true,
        ),
        WriteOutcome.queued,
      );

      expect(await lines(PendingCharacterWriteKind.inventoryState), isEmpty);
      final line = (await lines()).single;
      expect(line.payload['equipped'], isTrue);
      expect(line.payload['weaponSlot'], 'principal');
      expect(line.payload['attuned'], isTrue);
      final item = (await reopen()).inventory.singleWhere((i) => i.id == id);
      expect(item.equipped, isTrue);
      expect(item.weaponSlot, WeaponSlot.principal);
      expect(item.isAttuned, isTrue);
      goOnline();

      final report = await syncer.syncWithReport();

      expect(report.synced, {_characterId});
      expect(report.abandonedCharacterIds, isEmpty);
      final post = inventoryWrites().single;
      expect(post.method, 'POST');
      final body = post.body! as Map;
      expect(body['id'], id);
      expect(body['equipped'], true);
      expect(body['weapon_slot'], 'principal');
      expect(body['is_attuned'], true);
      expect(rows.where((r) => r['id'] == id), hasLength(1));
      expect(await queue.allForOwner(_ownerA), isEmpty);
      expect(await consumeAlerts(), isEmpty);
    });

    test('déséquiper efface le set d\'arme de l\'ajout en attente', () async {
      final id = await addOffline('Épée');
      await repository.equipWeaponToSlot(
        characterId: _characterId,
        inventoryId: id,
        slot: WeaponSlot.secondary,
      );

      await repository.setInventoryItemEquipped(
        characterId: _characterId,
        inventoryId: id,
        equipped: false,
      );

      final line = (await lines()).single;
      expect(line.payload['equipped'], isFalse);
      expect(line.payload.containsKey('weaponSlot'), isFalse);
    });

    test('réseau revenu mais pas encore synchronisé : équiper une ligne '
        'encore en file se fusionne dans l\'ajout (aucun UPDATE sur zéro '
        'ligne), queued', () async {
      final id = await addOffline('Épée');
      goOnline();

      final outcome = await repository.setInventoryItemEquipped(
        characterId: _characterId,
        inventoryId: id,
        equipped: true,
      );

      expect(outcome, WriteOutcome.queued);
      expect(server.writes, isEmpty);
      expect((await lines()).single.payload['equipped'], isTrue);
      expect(await lines(PendingCharacterWriteKind.inventoryState), isEmpty);
    });

    test('retrait d\'une ligne serveur ayant un réglage en file : l\'entrée '
        'inventoryState est purgée, seul le DELETE part, aucune alerte '
        'parasite', () async {
      await openOnline();
      goOffline();
      await repository.setInventoryItemEquipped(
        characterId: _characterId,
        inventoryId: _srv1,
        equipped: true,
      );
      expect(
        await lines(PendingCharacterWriteKind.inventoryState),
        hasLength(1),
      );

      await repository.removeInventoryItem(
        characterId: _characterId,
        inventoryId: _srv1,
      );

      expect(await lines(PendingCharacterWriteKind.inventoryState), isEmpty);
      expect((await lines()).single.payload, {'op': 'delete'});
      goOnline();
      final report = await syncer.syncWithReport();
      expect(report.synced, {_characterId});
      expect(report.abandonedCharacterIds, isEmpty);
      expect(inventoryWrites().map((w) => w.method), ['DELETE']);
      expect(rows.map((r) => r['id']), [_srv2]);
      expect(await consumeAlerts(), isEmpty);
    });

    test('retrait en ligne d\'une ligne ayant un réglage resté en file : '
        'l\'entrée est purgée', () async {
      await openOnline();
      goOffline();
      await repository.setInventoryItemAttuned(
        characterId: _characterId,
        inventoryId: _srv1,
        attuned: true,
      );
      goOnline();

      final outcome = await repository.removeInventoryItem(
        characterId: _characterId,
        inventoryId: _srv1,
      );

      expect(outcome, WriteOutcome.synced);
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });

    test('réglage d\'une ligne dont le retrait est en file : refusé', () async {
      goOffline();
      await repository.removeInventoryItem(
        characterId: _characterId,
        inventoryId: _srv1,
      );

      await expectLater(
        repository.setInventoryItemEquipped(
          characterId: _characterId,
          inventoryId: _srv1,
          equipped: true,
        ),
        throwsA(isA<CharacterFailure>()),
      );
      expect(await lines(PendingCharacterWriteKind.inventoryState), isEmpty);
    });

    test(
      'réglage d\'une ligne serveur ordinaire : inchangé (inventoryState)',
      () async {
        goOffline();

        await repository.setInventoryItemEquipped(
          characterId: _characterId,
          inventoryId: _srv1,
          equipped: true,
        );

        expect(await lines(), isEmpty);
        expect(
          await lines(PendingCharacterWriteKind.inventoryState),
          hasLength(1),
        );
      },
    );

    test('plafond de 3 objets harmonisés : compte les ajouts en file '
        '(1 serveur + 2 ajouts = 3, le suivant est refusé)', () async {
      await openOnline();
      final a = await addOffline('Anneau A');
      final b = await addOffline('Anneau B');
      final c = await addOffline('Anneau C');
      for (final id in [a, b]) {
        await repository.setInventoryItemAttuned(
          characterId: _characterId,
          inventoryId: id,
          attuned: true,
        );
      }
      expect((await reopen()).attunedItemCount, 3);

      await expectLater(
        repository.setInventoryItemAttuned(
          characterId: _characterId,
          inventoryId: c,
          attuned: true,
        ),
        throwsA(isA<CharacterFailure>()),
      );
      expect((await reopen()).attunedItemCount, 3);
    });
  });

  // ---------------------------------------------------------------------
  group('rejeu', () {
    test(
      'ajout : INSERT avec l\'id client, ligne retirée, cache à jour',
      () async {
        await openOnline();
        final id = await addOffline('Amulette', quantity: 4);
        goOnline();

        expect(await syncer.sync(), {_characterId});

        final post = inventoryWrites().single;
        expect(post.method, 'POST');
        expect((post.body! as Map)['id'], id);
        expect((post.body! as Map)['character_id'], _characterId);
        expect((post.body! as Map)['quantity'], 4);
        expect(await queue.allForOwner(_ownerA), isEmpty);
        goOffline();
        expect(
          (await reopen()).inventory.singleWhere((i) => i.id == id).quantity,
          4,
        );
      },
    );

    test('retrait : DELETE filtré id + character_id ; ligne déjà supprimée '
        'ailleurs (zéro ligne) = succès', () async {
      goOffline();
      await repository.removeInventoryItem(
        characterId: _characterId,
        inventoryId: _srv1,
      );
      await repository.removeInventoryItem(
        characterId: _characterId,
        inventoryId: _srv2,
      );
      rows.removeWhere((r) => r['id'] == _srv2);
      goOnline();

      expect(await syncer.sync(), {_characterId});

      final deletes = inventoryWrites();
      expect(deletes, hasLength(2));
      for (final d in deletes) {
        expect(d.method, 'DELETE');
        expect(d.query['character_id'], 'eq.$_characterId');
      }
      expect(rows, isEmpty);
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });

    test('le DELETE ne supprime jamais la ligne d\'un autre personnage '
        '(filtre character_id)', () async {
      rows.add({..._row(_srv1, 'Ailleurs'), 'character_id': 'char-autre'});
      rows.removeAt(0);
      goOffline();
      await repository.removeInventoryItem(
        characterId: _characterId,
        inventoryId: _srv1,
      );
      goOnline();

      expect(await syncer.sync(), {_characterId});

      expect(rows.where((r) => r['id'] == _srv1), hasLength(1));
    });

    test('idempotent : réponse perdue après l\'INSERT, le rejeu reçoit 23505 '
        '= succès, même UUID, pas de doublon, état réaligné', () async {
      final id = await addOffline('Anneau');
      await repository.setInventoryItemAttuned(
        characterId: _characterId,
        inventoryId: id,
        attuned: true,
      );
      goOnline();
      server.failAfterApply(1);

      expect(await syncer.sync(), isEmpty);
      expect(rows.where((r) => r['id'] == id), hasLength(1));
      expect(await lines(), hasLength(1));

      expect(await syncer.sync(), {_characterId});

      expect(rows.where((r) => r['id'] == id), hasLength(1));
      expect(await queue.allForOwner(_ownerA), isEmpty);
      final posts = server.requests.where(
        (r) => r.method == 'POST' && r.table == _table,
      );
      expect(posts.map((r) => r.applied), [true, false]);
      final patch = inventoryWrites().last;
      expect(patch.method, 'PATCH');
      expect(patch.query['id'], 'eq.$id');
      expect(patch.query['character_id'], 'eq.$_characterId');
      expect((patch.body! as Map)['is_attuned'], true);
      expect(
        (patch.body! as Map).containsKey('quantity'),
        isFalse,
        reason: 'la quantité a pu être consommée depuis le premier envoi',
      );
    });

    test(
      'réalignement sur zéro ligne (id déjà pris par une ligne d\'un autre '
      'personnage) : abandon au seuil puis alerte « votre inventaire »',
      () async {
        final id = await addOffline('Collision');
        rows.add({..._row(id, 'Autre'), 'character_id': 'char-autre'});
        goOnline();

        await syncUntilAbandoned();

        expect(await queue.allForOwner(_ownerA), isEmpty);
        expect(rows.where((r) => r['id'] == id), hasLength(1));
        expect(rows.last['character_id'], 'char-autre');
        final recorder = SyncAlertRecorder(
          db,
          queue,
          SyncAlertStore(db),
          CharacterDetailCache(cache),
        );
        // `consumeAbandoned` a déjà été évité : l'alerte vient du recorder.
        final consumed = await recorder.recordAbandoned(_ownerA);
        expect(consumed.single.kindKey, 'inventory_item');
        expect(consumed.single.message, contains('votre inventaire'));
      },
    );

    for (final code in ['23503', '23514']) {
      test('INSERT refusé avec $code (contrainte) : non rejouable, abandon au '
          'seuil, alerte « votre inventaire »', () async {
        await addOffline('Refusé');
        goOnline();
        server.rejectWith(code);

        final abandoned = <String>{};
        for (
          var i = 0;
          i < PendingCharacterWriteQueue.abandonAfterConsecutiveFailures;
          i++
        ) {
          final report = await syncer.syncWithReport();
          abandoned.addAll(report.abandonedCharacterIds);
          if (i == 0) {
            expect(await lines(), hasLength(1), reason: 'pas encore abandonné');
          }
        }

        expect(abandoned, {_characterId});
        expect(await queue.allForOwner(_ownerA), isEmpty);
        expect(server.appliedWrites, isEmpty);
        final alerts = await consumeAlerts();
        expect(alerts.single, contains('votre inventaire'));
      });
    }

    test('refus RLS au rejeu (42501) : compté, rien d\'appliqué', () async {
      final id = await addOffline('Anneau');
      goOnline();
      server.rejectWith('42501');

      final report = await syncer.syncWithReport();

      expect(report.synced, isEmpty);
      expect((await lines()).single.targetId, id);
      expect(rows, hasLength(2));
    });

    const validId = '55555555-5555-4555-8555-555555555555';
    for (final bad in <(String, Map<String, dynamic>)>[
      (validId, {}),
      (validId, {'op': 'update'}),
      (validId, {'op': 'add'}),
      (validId, {'op': 'add', 'customName': '', 'quantity': 1}),
      (validId, {'op': 'add', 'customName': '  ', 'quantity': 1}),
      (validId, {'op': 'add', 'customName': 'A', 'quantity': 0}),
      (validId, {'op': 'add', 'customName': 'A', 'quantity': -1}),
      (validId, {'op': 'add', 'customName': 'A', 'quantity': 1.5}),
      (validId, {'op': 'add', 'customName': 'A', 'quantity': 2147483648}),
      (validId, {'op': 'add', 'customName': 'A', 'quantity': '2'}),
      (
        validId,
        {
          'op': 'add',
          'customName': 'A',
          'quantity': 1,
          'customProperties': 'lourde',
        },
      ),
      ('pas-un-uuid', {'op': 'add', 'customName': 'A', 'quantity': 1}),
      ('inv-1', {'op': 'delete'}),
      ('', {'op': 'delete'}),
    ]) {
      test('payload invalide $bad : aucune écriture, ligne supprimée, '
          'compteur à 0, les autres lignes sont rejouées', () async {
        await queue.enqueue(
          characterId: _characterId,
          ownerId: _ownerA,
          kind: PendingCharacterWriteKind.inventoryItem,
          targetId: bad.$1,
          payload: bad.$2,
        );
        clock = clock.add(const Duration(seconds: 5));
        await queue.enqueue(
          characterId: _characterId,
          ownerId: _ownerA,
          kind: PendingCharacterWriteKind.xp,
          targetId: '',
          payload: {'newXp': 250},
        );
        expect(await queue.watchPendingCount(_ownerA).first, 2);

        final synced = await syncer.sync();

        expect(synced, {_characterId});
        expect(await queue.allForOwner(_ownerA), isEmpty);
        expect(await queue.watchPendingCount(_ownerA).first, 0);
        expect(server.characterRow['xp'], 250);
        expect(inventoryWrites(), isEmpty);
        expect(rows, hasLength(2));
      });
    }

    test(
      'ordre de rejeu : inventoryItem avant inventoryState d\'une même '
      'cible (même horodatage), un INSERT puis un UPDATE, aucune alerte',
      () async {
        const id = '66666666-6666-4666-8666-666666666666';
        await queue.enqueue(
          characterId: _characterId,
          ownerId: _ownerA,
          kind: PendingCharacterWriteKind.inventoryState,
          targetId: id,
          payload: {'equipped': true},
        );
        await queue.enqueue(
          characterId: _characterId,
          ownerId: _ownerA,
          kind: PendingCharacterWriteKind.inventoryItem,
          targetId: id,
          payload: {'op': 'add', 'customName': 'Ordre', 'quantity': 1},
        );

        final report = await syncer.syncWithReport();

        expect(report.synced, {_characterId});
        expect(report.abandonedCharacterIds, isEmpty);
        expect(inventoryWrites().map((w) => w.method), ['POST', 'PATCH']);
        expect(rows.singleWhere((r) => r['id'] == id)['equipped'], true);
        expect(await queue.allForOwner(_ownerA), isEmpty);
      },
    );

    test('ordre de rejeu : l\'ajout (plus ancien) part avant le retrait '
        'd\'une autre ligne', () async {
      final id = await addOffline('Ajout');
      clock = clock.add(const Duration(seconds: 5));
      await repository.removeInventoryItem(
        characterId: _characterId,
        inventoryId: _srv1,
      );
      goOnline();

      expect(await syncer.sync(), {_characterId});

      expect(inventoryWrites().map((w) => w.method).toList(), [
        'POST',
        'DELETE',
      ]);
      expect((inventoryWrites().first.body! as Map)['id'], id);
    });

    test('isolation par ownerId : le rejeu d\'un compte ne touche jamais la '
        'file d\'un autre', () async {
      await queue.enqueue(
        characterId: 'char-autre',
        ownerId: _ownerB,
        kind: PendingCharacterWriteKind.inventoryItem,
        targetId: '77777777-7777-4777-8777-777777777777',
        payload: {'op': 'delete'},
      );
      goOffline();
      await repository.removeInventoryItem(
        characterId: _characterId,
        inventoryId: _srv1,
      );
      goOnline();

      expect(await syncer.sync(), {_characterId});

      expect(await queue.allForOwner(_ownerB), hasLength(1));
      expect(inventoryWrites(), hasLength(1));
    });

    test('purge (déconnexion / suppression de compte) : removeAllForOwner '
        'retire le kind inventoryItem, pas celui d\'un autre compte', () async {
      goOffline();
      await repository.removeInventoryItem(
        characterId: _characterId,
        inventoryId: _srv1,
      );
      await queue.enqueue(
        characterId: 'char-autre',
        ownerId: _ownerB,
        kind: PendingCharacterWriteKind.inventoryItem,
        targetId: '77777777-7777-4777-8777-777777777777',
        payload: {'op': 'delete'},
      );

      await queue.removeAllForOwner(_ownerA);

      expect(await queue.allForOwner(_ownerA), isEmpty);
      expect(await queue.allForOwner(_ownerB), hasLength(1));
    });
  });

  // ---------------------------------------------------------------------
  group('superposition de la fiche relue', () {
    test(
      'ajouts visibles, tombstones masquent, lignes serveur intactes',
      () async {
        await openOnline();
        final id = await addOffline('Ajout local', quantity: 5);
        await repository.removeInventoryItem(
          characterId: _characterId,
          inventoryId: _srv2,
        );

        final detail = await reopen();

        expect(
          detail.inventory.map((i) => (i.id, i.name, i.quantity)).toList(),
          [(_srv1, 'Dague', 1), (id, 'Ajout local', 5)],
        );
      },
    );

    test('hors ligne avec le cache : la ligne ajoutée reste visible', () async {
      await openOnline();
      final id = await addOffline('Local');

      expect(
        (await reopen()).inventory.map((i) => i.id),
        containsAll([_srv1, _srv2, id]),
      );
    });

    test('calculs dérivés : poids total, CA, harmonisés suivent l\'état '
        'effectif', () async {
      rows.addAll([
        {
          ..._row(_srvWeight, 'Sac'),
          'item_id': 5,
          'quantity': 2,
          'items': {'category': 'equipement_general', 'weight': 2.5},
        },
        {
          ..._row(_srvArmor, 'Cotte', equipped: true),
          'item_id': 6,
          'items': {
            'category': 'armure',
            'weight': 20,
            'armor_properties': {
              'ac_base': 14,
              'ac_dex_bonus': 'aucun',
              'stealth_disadvantage': false,
            },
          },
        },
      ]);
      final before = await openOnline();
      expect(before.inventoryWeight, 25);
      expect(before.attunedItemCount, 1);
      final armorBefore = before.armorClass;
      goOffline();

      await repository.removeInventoryItem(
        characterId: _characterId,
        inventoryId: _srvWeight,
      );
      await repository.removeInventoryItem(
        characterId: _characterId,
        inventoryId: _srvArmor,
      );
      await repository.removeInventoryItem(
        characterId: _characterId,
        inventoryId: _srv2,
      );
      final id = await addOffline('Anneau');
      await repository.setInventoryItemAttuned(
        characterId: _characterId,
        inventoryId: id,
        attuned: true,
      );
      final after = await reopen();

      expect(after.inventoryWeight, 0);
      expect(after.attunedItemCount, 1, reason: 'Corde retirée, Anneau ajouté');
      expect(after.armorClass, lessThan(armorBefore));
    });

    test('payload invalide en file : ignoré par la superposition', () async {
      await openOnline();
      await queue.enqueue(
        characterId: _characterId,
        ownerId: _ownerA,
        kind: PendingCharacterWriteKind.inventoryItem,
        targetId: _srv1,
        payload: {'op': 'remove'},
      );
      goOffline();

      expect((await reopen()).inventory, hasLength(2));
    });
  });
}
