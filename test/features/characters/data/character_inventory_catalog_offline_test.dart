// T5b-2 (P15, F20) : cache du catalogue d'objets, ajout d'un objet du catalogue
// hors ligne (`inventoryItem` avec `itemId`) et butin avec objets (monnaie + N
// lignes en une transaction). Dépôt réel + file drift en mémoire +
// synchroniseur réel + faux serveur PostgREST du harnais (`test/support/`,
// tables `character_inventory`, `items` et `translations` simulées).

import 'package:drift/drift.dart' show Value;
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
import 'package:personnages/features/characters/data/inventory_catalog_cache.dart';
import 'package:personnages/features/characters/data/pending_character_write_syncer.dart';
import 'package:personnages/features/characters/data/sync_alert_recorder.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/characters/domain/reward_item_draft.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../support/fake_character_write_server.dart';
import '../../../support/fake_connectivity_checker.dart';

const _characterId = 'char-1';
const _ownerA = 'owner-1';
const _ownerB = 'owner-2';
const _srv1 = '11111111-1111-4111-8111-111111111111';
const _srv2 = '22222222-2222-4222-8222-222222222222';
const _table = 'character_inventory';

const _dagger = 11;
const _chainMail = 12;
const _shield = 13;
const _ring = 14;

Map<String, dynamic> _itemRow(
  int id,
  String category, {
  num? weight,
  Map<String, dynamic>? weapon,
  Map<String, dynamic>? armor,
  String? rarity,
  bool attunement = false,
  int? acBonus,
  String? acBonusKind,
}) => {
  'id': id,
  'category': category,
  'weight': weight,
  'cost': {'amount': 2, 'currency': 'gp'},
  'rarity': rarity,
  'requires_attunement': attunement,
  'consumable': false,
  'ac_bonus': acBonus,
  'ac_bonus_kind': acBonusKind,
  'weapon_properties': weapon,
  'armor_properties': armor,
};

List<Map<String, dynamic>> _catalogRows() => [
  _itemRow(
    _dagger,
    'arme',
    weight: 0.5,
    weapon: {
      'damage_dice': '1d4',
      'damage_type': 'perforant',
      'properties': ['légère'],
      'range': null,
    },
  ),
  _itemRow(
    _chainMail,
    'armure',
    weight: 20,
    armor: {
      'ac_base': 13,
      'ac_dex_bonus': 'aucun',
      'strength_requirement': null,
      'stealth_disadvantage': false,
      'slot': 'armure',
    },
  ),
  _itemRow(
    _shield,
    'armure',
    weight: 6,
    armor: {
      'ac_base': 2,
      'ac_dex_bonus': 'aucun',
      'strength_requirement': null,
      'stealth_disadvantage': false,
      'slot': 'bouclier',
    },
  ),
  _itemRow(
    _ring,
    'equipement_general',
    weight: 0,
    rarity: 'rare',
    attunement: true,
    acBonus: 1,
    acBonusKind: 'toujours',
  ),
];

List<Map<String, dynamic>> _translations() => [
  for (final entry in {
    _dagger: 'Dague',
    _chainMail: 'Cotte de mailles',
    _shield: 'Bouclier',
    _ring: 'Anneau de protection',
  }.entries)
    {
      'entity_type': 'item',
      'field_name': 'name',
      'locale': 'fr',
      'entity_id': '${entry.key}',
      'value': entry.value,
    },
  {
    'entity_type': 'item',
    'field_name': 'description',
    'locale': 'fr',
    'entity_id': '$_dagger',
    'value': 'Une petite lame.',
  },
  {
    'entity_type': 'item',
    'field_name': 'description',
    'locale': 'fr',
    'entity_id': '$_ring',
    'value': 'Un anneau magique.',
  },
];

Map<String, dynamic> _row(String id, String name, {bool attuned = false}) => {
  'id': id,
  'character_id': _characterId,
  'item_id': null,
  'custom_name': name,
  'quantity': 1,
  'equipped': false,
  'weapon_slot': null,
  'is_attuned': attuned,
};

/// File dont `enqueue` (enfilage unitaire) échoue au 3e appel : le butin doit
/// passer par `enqueueAll` (une transaction), jamais par des enfilages
/// successifs.
class _FlakyQueue extends PendingCharacterWriteQueue {
  _FlakyQueue(super.db, {super.now});

  int enqueueCalls = 0;

  @override
  Future<void> enqueue({
    required String characterId,
    required String ownerId,
    required PendingCharacterWriteKind kind,
    required String targetId,
    required Map<String, dynamic> payload,
  }) {
    if (++enqueueCalls == 3) throw StateError('app tuée entre deux enfilages');
    return super.enqueue(
      characterId: characterId,
      ownerId: ownerId,
      kind: kind,
      targetId: targetId,
      payload: payload,
    );
  }
}

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

  Future<void> build({PendingCharacterWriteQueue? customQueue}) async {
    queue = customQueue ?? PendingCharacterWriteQueue(db, now: () => clock);
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
        'currency_gp': 10,
        'currency_pp': 0,
        'currency_ep': 0,
        'currency_sp': 4,
        'currency_cp': 0,
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
        _table: rows,
      },
    );
    server.tables[_table] = rows;
    server.tables['items'] = _catalogRows();
    server.tables['translations'] = _translations();
    client = await buildSignedInClient(server, ownerId: _ownerA);
    repository = SupabaseCharacterRepository(
      client,
      cache,
      queue,
      connectivity,
    );
    syncer = PendingCharacterWriteSyncer(client, queue, cache, repository);
  }

  setUp(() async {
    clock = DateTime.utc(2026, 11, 10, 12);
    db = AppDatabase(NativeDatabase.memory());
    await build();
  });

  tearDown(() async {
    await connectivity.close();
    await db.close();
  });

  void goOffline() {
    connectivity.goOffline();
    server.down = true;
  }

  void goOnline() {
    server.down = false;
    connectivity.goOnline();
  }

  Future<CharacterDetail> openOnline() =>
      repository.fetchCharacterDetail(_characterId);

  Future<CharacterDetail> reopen() => openOnline();

  /// Catalogue chargé (cache écrit), puis les traductions du faux serveur sont
  /// vidées : une fiche relue ne peut plus connaître les noms d'objets que par
  /// le cache du catalogue ou par ce que le dépôt y a reporté.
  Future<void> primeCatalogCache() async {
    await repository.fetchInventoryCatalog();
    server.tables['translations']!.clear();
  }

  Future<List<PendingCharacterWrite>> lines([
    PendingCharacterWriteKind kind = PendingCharacterWriteKind.inventoryItem,
  ]) async => [
    for (final line in await queue.allForOwner(_ownerA))
      if (line.kind == kind) line,
  ];

  List<RecordedRequest> inventoryWrites() => [
    for (final w in server.writes)
      if (w.table == _table) w,
  ];

  List<RecordedRequest> gets(String table) => [
    for (final r in server.requests)
      if (r.method == 'GET' && r.table == table) r,
  ];

  Future<String> addCatalogOffline(int itemId, {int quantity = 1}) async {
    final before = {for (final l in await lines()) l.targetId};
    goOffline();
    final outcome = await repository.addInventoryItem(
      characterId: _characterId,
      itemId: itemId,
      quantity: quantity,
    );
    expect(outcome, WriteOutcome.queued);
    return (await lines())
        .firstWhere((l) => !before.contains(l.targetId))
        .targetId;
  }

  Future<void> ageCatalogCache() =>
      (db.update(
        db.cachedReferenceEntries,
      )..where((e) => e.key.equals(InventoryCatalogCache.key))).write(
        CachedReferenceEntriesCompanion(
          cachedAt: Value(DateTime.now().subtract(const Duration(days: 5))),
        ),
      );

  // ---------------------------------------------------------------------
  group('cache du catalogue (fetchInventoryCatalog)', () {
    test('premier chargement en ligne : select élargi, cache complet écrit '
        '(version 2)', () async {
      final items = await repository.fetchInventoryCatalog();

      expect(items.map((i) => i.name), [
        'Dague',
        'Cotte de mailles',
        'Bouclier',
        'Anneau de protection',
      ]);
      final select = gets('items').single.query['select']!;
      for (final column in [
        'rarity',
        'requires_attunement',
        'consumable',
        'ac_bonus',
        'ac_bonus_kind',
        'weapon_properties',
        'armor_properties',
      ]) {
        expect(select, contains(column));
      }
      final cached = await cache.get(InventoryCatalogCache.key) as Map;
      expect(cached['version'], 2);
      expect(cached['items'], hasLength(4));
      final dagger = (cached['items'] as List).first as Map;
      expect(dagger['weapon_properties']['damage_dice'], '1d4');
      expect(dagger['rarity'], isNull);
      expect(cached['itemNames'], hasLength(4));
      expect(cached['itemDescriptions'], hasLength(2));
    });

    test('cache frais : aucun appel réseau', () async {
      await repository.fetchInventoryCatalog();
      final before = server.requests.length;
      server.down = true;

      final items = await repository.fetchInventoryCatalog();

      expect(items, hasLength(4));
      expect(server.requests.length, before);
    });

    test(
      'cache périmé + hors ligne : repli sur le cache, sans requête',
      () async {
        await repository.fetchInventoryCatalog();
        await ageCatalogCache();
        final before = server.requests.length;
        goOffline();

        final items = await repository.fetchInventoryCatalog();

        expect(items.map((i) => i.id), [_dagger, _chainMail, _shield, _ring]);
        expect(server.requests.length, before);
      },
    );

    test('cache périmé + réseau en échec (transport) : repli sur le cache '
        'périmé', () async {
      await repository.fetchInventoryCatalog();
      await ageCatalogCache();
      server.down = true;

      final items = await repository.fetchInventoryCatalog();

      expect(items, hasLength(4));
    });

    test('cache périmé + en ligne : rafraîchi depuis le réseau', () async {
      await repository.fetchInventoryCatalog();
      await ageCatalogCache();
      server.tables['items']!.add(_itemRow(15, 'equipement_general'));

      final items = await repository.fetchInventoryCatalog();

      expect(items, hasLength(5));
      final cached = await cache.get(InventoryCatalogCache.key) as Map;
      expect(cached['items'], hasLength(5));
    });

    test('jamais chargé + hors ligne : erreur dédiée (code network), pas de '
        'crash', () async {
      goOffline();

      await expectLater(
        repository.fetchInventoryCatalog(),
        throwsA(
          isA<CharacterFailure>().having(
            (f) => f.code,
            'code',
            CharacterErrorCode.network,
          ),
        ),
      );
      expect(server.requests, isEmpty);
    });

    test('jamais chargé + réseau coupé alors que l\'appareil se croit en ligne '
        ': même erreur dédiée', () async {
      server.down = true;

      await expectLater(
        repository.fetchInventoryCatalog(),
        throwsA(
          isA<CharacterFailure>().having(
            (f) => f.code,
            'code',
            CharacterErrorCode.network,
          ),
        ),
      );
    });

    test('cache d\'une version antérieure (sans version ni nouveaux champs) : '
        'refetch en ligne', () async {
      await cache.put(InventoryCatalogCache.key, {
        'items': [
          {
            'id': _dagger,
            'category': 'arme',
            'cost': {'amount': 2},
          },
        ],
        'itemNames': [
          {'entity_id': '$_dagger', 'value': 'Dague'},
        ],
      });

      final items = await repository.fetchInventoryCatalog();

      expect(items, hasLength(4), reason: 'le cache ancien n\'est pas frais');
      expect((await cache.get(InventoryCatalogCache.key) as Map)['version'], 2);
    });

    test('cache d\'une version antérieure + hors ligne : objets partiels, pas '
        'de crash', () async {
      await cache.put(InventoryCatalogCache.key, {
        'items': [
          {
            'id': _dagger,
            'category': 'arme',
            'cost': {'amount': 2},
          },
        ],
        'itemNames': [
          {'entity_id': '$_dagger', 'value': 'Dague'},
        ],
      });
      await openOnline();
      goOffline();

      final items = await repository.fetchInventoryCatalog();

      expect(items.single.name, 'Dague');
      expect(items.single.weight, isNull);
      // L'ajout hors ligne d'un tel objet ne plante pas non plus.
      final id = await addCatalogOffline(_dagger);
      final item = (await reopen()).inventory.singleWhere((i) => i.id == id);
      expect(item.name, 'Dague');
      expect(item.unitWeight, isNull);
    });

    test('cache corrompu : traité comme absent', () async {
      await cache.put(InventoryCatalogCache.key, 'pas une map');

      expect(await repository.fetchInventoryCatalog(), hasLength(4));
    });

    test('les armes naturelles restent exclues', () async {
      server.tables['items']!.add(
        _itemRow(
          20,
          'arme',
          weapon: {
            'damage_dice': '1d4',
            'damage_type': 'tranchant',
            'properties': ['naturelle'],
          },
        ),
      );

      expect(
        (await repository.fetchInventoryCatalog()).map((i) => i.id),
        isNot(contains(20)),
      );
    });
  });

  // ---------------------------------------------------------------------
  group('ajout d\'un objet du catalogue', () {
    test('hors ligne : queued, itemId + UUID client, aucune écriture réseau, '
        'objet complet visible dans la fiche', () async {
      await primeCatalogCache();
      await openOnline();

      final id = await addCatalogOffline(_dagger, quantity: 2);

      expect(isUuid(id), isTrue);
      final line = (await lines()).single;
      expect(line.payload, {'op': 'add', 'itemId': _dagger, 'quantity': 2});
      expect(server.writes, isEmpty);
      final item = (await reopen()).inventory.singleWhere((i) => i.id == id);
      expect(item.itemId, _dagger);
      expect(item.name, 'Dague');
      expect(item.quantity, 2);
      expect(item.category, 'arme');
      expect(item.unitWeight, 0.5);
      expect(item.totalWeight, 1.0);
      expect(item.costAmount, 2.0);
      expect(item.description, 'Une petite lame.');
      expect(item.weaponProperties!.damageDice, '1d4');
      expect(item.weaponProperties!.properties, ['légère']);
      expect(item.isCustom, isFalse);
    });

    test('erreur de transport en ligne : queued', () async {
      server.failBefore(1);

      final outcome = await repository.addInventoryItem(
        characterId: _characterId,
        itemId: _dagger,
        quantity: 1,
      );

      expect(outcome, WriteOutcome.queued);
      final line = (await lines()).single;
      expect(line.payload['itemId'], _dagger);
      expect(isUuid(line.targetId), isTrue);
    });

    test('en ligne : INSERT avec UUID client et item_id, synced, rien en '
        'file ; deux ajouts = deux lignes (pas de fusion)', () async {
      final first = await repository.addInventoryItem(
        characterId: _characterId,
        itemId: _dagger,
        quantity: 3,
      );
      final second = await repository.addInventoryItem(
        characterId: _characterId,
        itemId: _dagger,
        quantity: 1,
      );

      expect(first, WriteOutcome.synced);
      expect(second, WriteOutcome.synced);
      final posts = inventoryWrites();
      expect(posts.map((p) => p.method), ['POST', 'POST']);
      final bodies = [for (final p in posts) p.body! as Map];
      expect(isUuid(bodies[0]['id'] as String), isTrue);
      expect(bodies[0]['id'], isNot(bodies[1]['id']));
      expect(bodies[0]['item_id'], _dagger);
      expect(bodies[0]['character_id'], _characterId);
      expect(bodies[0]['quantity'], 3);
      expect(bodies[0].containsKey('custom_name'), isFalse);
      expect(rows.where((r) => r['item_id'] == _dagger), hasLength(2));
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });

    test('en ligne : le cache de la fiche reçoit l\'objet complet (nom, poids, '
        'propriétés), relisible hors ligne', () async {
      await primeCatalogCache();
      await openOnline();

      final outcome = await repository.addInventoryItem(
        characterId: _characterId,
        itemId: _dagger,
        quantity: 1,
      );
      expect(outcome, WriteOutcome.synced);
      final id =
          rows.singleWhere((r) => r['item_id'] == _dagger)['id'] as String;
      goOffline();

      final item = (await reopen()).inventory.singleWhere((i) => i.id == id);
      expect(item.name, 'Dague');
      expect(item.unitWeight, 0.5);
      expect(item.description, 'Une petite lame.');
      expect(item.weaponProperties!.damageDice, '1d4');
    });

    for (final code in ['42501', '23503']) {
      test('refus serveur $code en ligne : échec, rien en file', () async {
        server.rejectWith(code);

        await expectLater(
          repository.addInventoryItem(
            characterId: _characterId,
            itemId: _dagger,
            quantity: 1,
          ),
          throwsA(isA<CharacterFailure>()),
        );

        expect(await queue.allForOwner(_ownerA), isEmpty);
        expect(server.appliedWrites, isEmpty);
      });
    }

    test(
      'itemId ou quantité invalide : refusé, rien en file ni en réseau',
      () async {
        for (final (itemId, quantity) in [
          (0, 1),
          (-3, 1),
          (_dagger, 0),
          (_dagger, -1),
        ]) {
          await expectLater(
            repository.addInventoryItem(
              characterId: _characterId,
              itemId: itemId,
              quantity: quantity,
            ),
            throwsA(isA<CharacterFailure>()),
          );
        }
        expect(await queue.allForOwner(_ownerA), isEmpty);
        expect(server.writes, isEmpty);
      },
    );

    test('ajout + équipement hors ligne : un seul INSERT avec l\'état final, '
        'aucun PATCH', () async {
      await primeCatalogCache();
      await openOnline();
      final id = await addCatalogOffline(_dagger);
      await repository.setInventoryItemEquipped(
        characterId: _characterId,
        inventoryId: id,
        equipped: true,
      );

      expect(await lines(PendingCharacterWriteKind.inventoryState), isEmpty);
      expect((await lines()).single.payload, {
        'op': 'add',
        'itemId': _dagger,
        'quantity': 1,
        'equipped': true,
      });
      expect(
        (await reopen()).inventory.singleWhere((i) => i.id == id).equipped,
        isTrue,
      );

      goOnline();
      expect(await syncer.sync(), {_characterId});

      final writes = inventoryWrites();
      expect(writes.map((w) => w.method), ['POST']);
      expect((writes.single.body! as Map)['equipped'], true);
      expect((writes.single.body! as Map)['item_id'], _dagger);
      expect(rows.singleWhere((r) => r['id'] == id)['equipped'], true);
    });

    test('ajout puis retrait hors ligne : le tombstone remplace l\'ajout, '
        'synchro sans doublon', () async {
      await openOnline();
      final id = await addCatalogOffline(_dagger);

      await repository.removeInventoryItem(
        characterId: _characterId,
        inventoryId: id,
      );

      expect((await lines()).single.payload, {'op': 'delete'});
      expect((await reopen()).inventory.map((i) => i.id), isNot(contains(id)));
      goOnline();
      expect(await syncer.sync(), {_characterId});
      expect(inventoryWrites().map((w) => w.method), ['DELETE']);
      expect(rows.where((r) => r['id'] == id), isEmpty);
    });

    test("usage d'un objet du catalogue dont l'ajout est en file (T5b-3) : "
        "fusionné dans l'ajout, jamais refusé ; à 0 = tombstone, aucune "
        'requête', () async {
      final id = await addCatalogOffline(_dagger, quantity: 3);
      goOnline();

      expect(
        await repository.useInventoryItem(
          characterId: _characterId,
          inventoryId: id,
          newQuantity: 2,
        ),
        WriteOutcome.queued,
      );
      final payload = (await lines()).single.payload;
      expect(payload['op'], 'add');
      expect(payload['itemId'], isNotNull);
      expect(payload['quantity'], 2);

      expect(
        await repository.useInventoryItem(
          characterId: _characterId,
          inventoryId: id,
          newQuantity: 0,
        ),
        WriteOutcome.queued,
      );
      expect((await lines()).single.payload, {'op': 'delete'});
      expect(server.writes, isEmpty);
    });
  });

  // ---------------------------------------------------------------------
  group('superposition d\'un objet du catalogue en file', () {
    test('calculs dérivés : poids, CA d\'une armure et d\'un bouclier ajoutés '
        'et équipés', () async {
      await primeCatalogCache();
      final before = await openOnline();
      expect(before.armorClass, 10);
      expect(before.inventoryWeight, 0);
      goOffline();

      final mail = await addCatalogOffline(_chainMail);
      final shield = await addCatalogOffline(_shield);
      for (final id in [mail, shield]) {
        await repository.setInventoryItemEquipped(
          characterId: _characterId,
          inventoryId: id,
          equipped: true,
        );
      }

      final after = await reopen();
      expect(after.inventoryWeight, 26);
      expect(after.armorClass, 15, reason: 'cotte 13 + bouclier 2');
      final armor = after.inventory.singleWhere((i) => i.id == mail);
      expect(armor.armorProperties!.acBase, 13);
      expect(armor.name, 'Cotte de mailles');
    });

    test('harmonisation : le plafond de 3 compte les ajouts du catalogue en '
        'file', () async {
      await primeCatalogCache();
      await openOnline();
      final first = await addCatalogOffline(_ring);
      final second = await addCatalogOffline(_ring);
      final third = await addCatalogOffline(_ring);
      await repository.setInventoryItemAttuned(
        characterId: _characterId,
        inventoryId: first,
        attuned: true,
      );
      await repository.setInventoryItemAttuned(
        characterId: _characterId,
        inventoryId: second,
        attuned: true,
      );

      await expectLater(
        repository.setInventoryItemAttuned(
          characterId: _characterId,
          inventoryId: third,
          attuned: true,
        ),
        throwsA(isA<CharacterFailure>()),
      );

      final detail = await reopen();
      expect(detail.attunedItemCount, 3, reason: 'Corde + 2 anneaux');
      final ring = detail.inventory.singleWhere((i) => i.id == first);
      expect(ring.requiresAttunement, isTrue);
      expect(ring.rarity, 'rare');
      expect(ring.acBonus, 1);
    });

    test('objet absent du cache du catalogue : ligne minimale « Objet #id », '
        'sans crash', () async {
      await openOnline();
      final id = await addCatalogOffline(99, quantity: 2);

      final item = (await reopen()).inventory.singleWhere((i) => i.id == id);

      expect(item.name, 'Objet #99');
      expect(item.quantity, 2);
      expect(item.unitWeight, isNull);
      expect(item.armorProperties, isNull);
    });

    test('objet absent du cache mais déjà présent dans l\'inventaire : le nom '
        'connu est réutilisé', () async {
      rows.add({
        ..._row('33333333-3333-4333-8333-333333333333', 'x'),
        'item_id': 99,
        'custom_name': null,
      });
      server.tables['translations']!.add({
        'entity_type': 'item',
        'field_name': 'name',
        'locale': 'fr',
        'entity_id': '99',
        'value': 'Objet connu',
      });
      await openOnline();
      final id = await addCatalogOffline(99);

      final item = (await reopen()).inventory.singleWhere((i) => i.id == id);

      expect(item.name, 'Objet connu');
    });
  });

  // ---------------------------------------------------------------------
  group('butin avec objets', () {
    const items = [
      RewardItemDraft(itemId: _dagger, displayName: 'Dague', quantity: 2),
      RewardItemDraft(itemId: _shield, displayName: 'Bouclier', quantity: 1),
      RewardItemDraft(
        customName: 'Amulette',
        displayName: 'Amulette',
        quantity: 1,
        customDescription: 'Un souvenir',
      ),
    ];

    test('hors ligne : currency + N inventory_item (UUID distincts) en une '
        'transaction, objets et monnaie visibles, compteur à 4', () async {
      await primeCatalogCache();
      await openOnline();
      goOffline();

      final outcome = await repository.addReward(
        characterId: _characterId,
        newCurrencyTotals: const {CurrencyKind.gold: 25},
        items: items,
      );

      expect(outcome, WriteOutcome.queued);
      final currency = (await lines(PendingCharacterWriteKind.currency)).single;
      expect(currency.payload['totals'], {'currency_gp': 25});
      final item = await lines();
      expect(item, hasLength(3));
      expect({for (final l in item) l.targetId}, hasLength(3));
      expect(item.every((l) => isUuid(l.targetId)), isTrue);
      expect(
        item.map((l) => (l.payload['itemId'], l.payload['customName'])),
        unorderedEquals([(_dagger, null), (_shield, null), (null, 'Amulette')]),
      );
      expect(await queue.watchPendingCount(_ownerA).first, 4);
      expect(server.writes, isEmpty);
      final detail = await reopen();
      expect(detail.currencyGp, 25);
      expect(detail.inventory, hasLength(5));
      expect(
        detail.inventory.where((i) => i.itemId == _dagger).single.quantity,
        2,
      );
    });

    test(
      'hors ligne, objets seuls : N inventory_item, pas de ligne currency',
      () async {
        goOffline();

        final outcome = await repository.addReward(
          characterId: _characterId,
          newCurrencyTotals: const {},
          items: items,
        );

        expect(outcome, WriteOutcome.queued);
        expect(await lines(), hasLength(3));
        expect(await lines(PendingCharacterWriteKind.currency), isEmpty);
      },
    );

    test('atomicité : l\'enfilage passe par enqueueAll, jamais par des '
        'enfilages successifs (un enfilage unitaire qui échoue ne laisse '
        'rien de partiel)', () async {
      await connectivity.close();
      await db.close();
      db = AppDatabase(NativeDatabase.memory());
      final flaky = _FlakyQueue(db, now: () => clock);
      await build(customQueue: flaky);
      goOffline();

      final outcome = await repository.addReward(
        characterId: _characterId,
        newCurrencyTotals: const {CurrencyKind.gold: 25},
        items: items,
      );

      expect(outcome, WriteOutcome.queued);
      expect(flaky.enqueueCalls, 0);
      expect(await queue.allForOwner(_ownerA), hasLength(4));
    });

    test('rejeu du butin hors ligne : monnaie puis objets, une seule ligne '
        'par objet, file vidée', () async {
      goOffline();
      await repository.addReward(
        characterId: _characterId,
        newCurrencyTotals: const {CurrencyKind.gold: 25},
        items: items,
      );
      goOnline();

      expect(await syncer.sync(), {_characterId});

      expect(server.characterRow['currency_gp'], 25);
      expect(rows, hasLength(5));
      expect(rows.where((r) => r['item_id'] == _dagger), hasLength(1));
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });

    test('en ligne : UPDATE monnaie puis INSERT batché avec UUID clients, '
        'synced, rien en file', () async {
      final outcome = await repository.addReward(
        characterId: _characterId,
        newCurrencyTotals: const {CurrencyKind.gold: 25},
        items: items,
      );

      expect(outcome, WriteOutcome.synced);
      expect(server.writes.map((w) => '${w.method} ${w.table}'), [
        'PATCH characters',
        'POST $_table',
      ]);
      final body = server.writes.last.body! as List;
      expect(body, hasLength(3));
      expect({for (final r in body) (r as Map)['id']}, hasLength(3));
      expect(body.every((r) => isUuid((r as Map)['id'] as String)), isTrue);
      expect((body[2] as Map)['custom_name'], 'Amulette');
      expect((body[2] as Map)['custom_description'], 'Un souvenir');
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });

    test(
      'en ligne, transport coupé à l\'INSERT des objets (monnaie déjà '
      'écrite) : tous les objets sont mis en file, rien n\'est perdu',
      () async {
        server.onWriteApplied = (request) {
          if (request.table == 'characters') server.failBefore(1);
        };

        final outcome = await repository.addReward(
          characterId: _characterId,
          newCurrencyTotals: const {CurrencyKind.gold: 25},
          items: items,
        );

        expect(outcome, WriteOutcome.queued);
        expect(server.characterRow['currency_gp'], 25);
        expect(await lines(), hasLength(3));
        expect(await lines(PendingCharacterWriteKind.currency), isEmpty);
        server.onWriteApplied = null;

        expect(await syncer.sync(), {_characterId});

        expect(rows, hasLength(5));
        expect(await queue.allForOwner(_ownerA), isEmpty);
      },
    );

    test('réponse perdue après l\'INSERT batché : le rejeu reçoit 23505 = '
        'succès, aucun objet en double', () async {
      server.onWriteApplied = (request) {
        if (request.method == 'POST') server.failAfterApply(1);
      };

      final outcome = await repository.addReward(
        characterId: _characterId,
        newCurrencyTotals: const {},
        items: items,
      );

      expect(outcome, WriteOutcome.queued);
      expect(rows, hasLength(5), reason: 'le lot a bien été appliqué');
      server.onWriteApplied = null;

      expect(await syncer.sync(), {_characterId});

      expect(rows, hasLength(5), reason: 'aucun doublon');
      expect(rows.where((r) => r['item_id'] == _dagger), hasLength(1));
      expect(rows.where((r) => r['custom_name'] == 'Amulette'), hasLength(1));
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });

    test('refus serveur (42501) en ligne : échec, rien en file, aucun objet '
        'écrit', () async {
      server.rejectWith('42501');

      await expectLater(
        repository.addReward(
          characterId: _characterId,
          newCurrencyTotals: const {CurrencyKind.gold: 25},
          items: items,
        ),
        throwsA(isA<CharacterFailure>()),
      );

      expect(await queue.allForOwner(_ownerA), isEmpty);
      expect(rows, hasLength(2));
    });

    test(
      'objet invalide : tout le butin est refusé avant la moindre écriture',
      () async {
        for (final bad in [
          const RewardItemDraft(itemId: 0, displayName: 'x', quantity: 1),
          const RewardItemDraft(displayName: 'x', quantity: 1),
          const RewardItemDraft(customName: ' ', displayName: 'x', quantity: 1),
          const RewardItemDraft(itemId: _dagger, displayName: 'x', quantity: 0),
        ]) {
          await expectLater(
            repository.addReward(
              characterId: _characterId,
              newCurrencyTotals: const {CurrencyKind.gold: 25},
              items: [items.first, bad],
            ),
            throwsA(isA<CharacterFailure>()),
          );
        }
        expect(await queue.allForOwner(_ownerA), isEmpty);
        expect(server.writes, isEmpty);
      },
    );
  });

  // ---------------------------------------------------------------------
  group('rejeu d\'un ajout du catalogue', () {
    test('idempotent : réponse perdue après l\'INSERT, le rejeu reçoit 23505 '
        '= succès, même UUID, pas de doublon, `item_id` réaligné', () async {
      final id = await addCatalogOffline(_dagger);
      goOnline();
      server.failAfterApply(1);

      expect(await syncer.sync(), isEmpty);
      expect(rows.where((r) => r['id'] == id), hasLength(1));

      expect(await syncer.sync(), {_characterId});

      expect(rows.where((r) => r['id'] == id), hasLength(1));
      expect(await queue.allForOwner(_ownerA), isEmpty);
      final posts = server.requests.where(
        (r) => r.method == 'POST' && r.table == _table,
      );
      expect(posts.map((r) => r.applied), [true, false]);
      final patch = inventoryWrites().last;
      expect(patch.method, 'PATCH');
      // T5b-3 : la quantité effective de l'ajout est réalignée avec `item_id`.
      expect(patch.body, {'quantity': 1, 'item_id': _dagger});
      expect(patch.query['id'], 'eq.$id');
      expect(patch.query['character_id'], 'eq.$_characterId');
    });

    test('item_id disparu (23503) : non rejouable, abandon au seuil, alerte '
        '« votre inventaire »', () async {
      await addCatalogOffline(_dagger);
      goOnline();
      server.rejectWith('23503');

      final abandoned = <String>{};
      for (
        var i = 0;
        i < PendingCharacterWriteQueue.abandonAfterConsecutiveFailures;
        i++
      ) {
        final report = await syncer.syncWithReport();
        abandoned.addAll(report.abandonedCharacterIds);
        if (i == 0) expect(await lines(), hasLength(1));
      }

      expect(abandoned, {_characterId});
      expect(await queue.allForOwner(_ownerA), isEmpty);
      final recorder = SyncAlertRecorder(
        db,
        queue,
        SyncAlertStore(db),
        CharacterDetailCache(cache),
      );
      final consumed = await recorder.recordAbandoned(_ownerA);
      expect(consumed.single.kindKey, 'inventory_item');
      expect(consumed.single.message, contains('votre inventaire'));
    });

    test('l\'objet confirmé met à jour le cache de la fiche avec ses données '
        'complètes (relu hors ligne, file vide)', () async {
      await primeCatalogCache();
      await openOnline();
      final id = await addCatalogOffline(_chainMail);
      goOnline();
      expect(await syncer.sync(), {_characterId});
      expect(await queue.allForOwner(_ownerA), isEmpty);
      goOffline();

      final item = (await reopen()).inventory.singleWhere((i) => i.id == id);

      expect(item.name, 'Cotte de mailles');
      expect(item.unitWeight, 20);
      expect(item.armorProperties!.acBase, 13);
    });

    test(
      'rejouer un lot : refus répété sous le seuil, la ligne reste en file',
      () async {
        await addCatalogOffline(_dagger);
        goOnline();
        server.rejectWith('42501');

        final report = await syncer.syncWithReport();

        expect(report.synced, isEmpty);
        expect(await lines(), hasLength(1));
      },
    );

    const validId = '55555555-5555-4555-8555-555555555555';
    for (final bad in <Map<String, dynamic>>[
      {'op': 'add', 'itemId': 0, 'quantity': 1},
      {'op': 'add', 'itemId': -4, 'quantity': 1},
      {'op': 'add', 'itemId': 1.5, 'quantity': 1},
      {'op': 'add', 'itemId': '11', 'quantity': 1},
      {'op': 'add', 'itemId': 2147483648, 'quantity': 1},
      {'op': 'add', 'itemId': null, 'quantity': 1},
      {'op': 'add', 'quantity': 1},
      {'op': 'add', 'itemId': _dagger},
      {'op': 'add', 'itemId': _dagger, 'quantity': 0},
      {'op': 'add', 'itemId': _dagger, 'quantity': 1.5},
      {'op': 'add', 'itemId': _dagger, 'quantity': '2'},
      {'op': 'add', 'itemId': _dagger, 'quantity': 1, 'customName': ''},
      {'op': 'add', 'itemId': _dagger, 'quantity': 1, 'equipped': 'oui'},
    ]) {
      test('payload invalide $bad : aucune écriture, ligne supprimée, '
          'compteur à 0, les autres lignes sont rejouées', () async {
        await queue.enqueue(
          characterId: _characterId,
          ownerId: _ownerA,
          kind: PendingCharacterWriteKind.inventoryItem,
          targetId: validId,
          payload: bad,
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
      'isolation par ownerId : le rejeu d\'un compte ne touche jamais la '
      'file d\'un autre ; la purge ne retire que les lignes du compte',
      () async {
        await queue.enqueue(
          characterId: 'char-autre',
          ownerId: _ownerB,
          kind: PendingCharacterWriteKind.inventoryItem,
          targetId: '77777777-7777-4777-8777-777777777777',
          payload: {'op': 'add', 'itemId': _dagger, 'quantity': 1},
        );
        await addCatalogOffline(_shield);
        goOnline();

        expect(await syncer.sync(), {_characterId});

        expect(await queue.allForOwner(_ownerB), hasLength(1));
        expect(inventoryWrites(), hasLength(1));

        goOffline();
        await addCatalogOffline(_dagger);
        await queue.removeAllForOwner(_ownerA);
        expect(await queue.allForOwner(_ownerA), isEmpty);
        expect(await queue.allForOwner(_ownerB), hasLength(1));
      },
    );
  });
}
