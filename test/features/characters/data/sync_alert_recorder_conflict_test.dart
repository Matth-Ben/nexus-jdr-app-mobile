// T8 : persistance et dédoublonnage des alertes de conflit (valeur appliquée,
// nom d'objet, fusion, isolation par compte, purge).

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/pending_character_write_queue.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/core/cache/sync_alert_store.dart';
import 'package:personnages/features/characters/data/character_detail_cache.dart';
import 'package:personnages/features/characters/data/pending_character_write_syncer.dart';
import 'package:personnages/features/characters/data/sync_alert_recorder.dart';

const _owner = 'owner-1';

ServerValueConflict _hp(
  int server,
  int queued, {
  int serverTemp = 0,
  int queuedTemp = 0,
  String character = 'c1',
}) => ServerValueConflict(
  characterId: character,
  kind: PendingCharacterWriteKind.hp,
  serverValue: {'currentHp': server, 'temporaryHp': serverTemp},
  queuedValue: {'currentHp': queued, 'temporaryHp': queuedTemp},
);

ServerValueConflict _item(
  String lineId,
  int server,
  int queued, {
  String character = 'c1',
}) => ServerValueConflict(
  characterId: character,
  kind: PendingCharacterWriteKind.inventoryItem,
  targetId: lineId,
  serverValue: {'quantity': server},
  queuedValue: {'quantity': queued},
);

ServerValueConflict _currency(
  Map<String, dynamic> server,
  Map<String, dynamic> queued,
) => ServerValueConflict(
  characterId: 'c1',
  kind: PendingCharacterWriteKind.currency,
  serverValue: server,
  queuedValue: queued,
);

void main() {
  late AppDatabase db;
  late ReferenceDataCache cache;
  late SyncAlertStore store;
  late SyncAlertRecorder recorder;

  Future<void> seed({
    String owner = _owner,
    String character = 'c1',
    String name = 'Aria',
    int? maxHp = 30,
  }) => cache.put(
    CharacterDetailCache.keyFor(ownerId: owner, characterId: character),
    {
      CharacterDetailCache.rowKey: {
        'name': name,
        'max_hp': ?maxHp,
        'character_inventory': [
          {'id': 'l1', 'item_id': null, 'custom_name': 'Potion maison'},
          {'id': 'l2', 'item_id': 12, 'custom_name': null},
          {'id': 'l3', 'item_id': null, 'custom_name': 'Corde'},
          {'id': 'l4', 'item_id': 99, 'custom_name': null},
        ],
      },
      'itemNameRows': [
        {'entity_id': '12', 'value': 'Torche'},
      ],
    },
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    cache = ReferenceDataCache(db);
    store = SyncAlertStore(db);
    recorder = SyncAlertRecorder(
      db,
      PendingCharacterWriteQueue(db),
      store,
      CharacterDetailCache(cache),
    );
    await seed();
  });

  tearDown(() => db.close());

  Future<List<SyncAlert>> alerts([String owner = _owner]) =>
      store.allForOwner(owner);

  test('PV : persiste la valeur serveur, le max, les PV temporaires ET la '
      'valeur appliquée', () async {
    await recorder.recordConflict(
      ownerId: _owner,
      conflict: _hp(12, 5, serverTemp: 3, queuedTemp: 1),
    );

    final alert = (await alerts()).single;
    expect(alert.kind, SyncAlertKind.conflict);
    expect(alert.serverValue, {
      'currentHp': 12,
      'temporaryHp': 3,
      'maxHp': 30,
      'queued': {'currentHp': 5, 'temporaryHp': 1},
    });
  });

  test('PV sans max en cache : maxHp null persisté', () async {
    await seed(maxHp: null);
    await recorder.recordConflict(ownerId: _owner, conflict: _hp(12, 5));
    expect((await alerts()).single.serverValue!['maxHp'], isNull);
  });

  test(
    'le nom stocké reste complet (la troncature est à l\'affichage)',
    () async {
      final longName = 'A' * 32;
      await seed(name: longName);
      await recorder.recordConflict(ownerId: _owner, conflict: _hp(12, 5));
      expect((await alerts()).single.characterName, longName);
    },
  );

  test(
    'dédoublonnage : un second conflit non fermé met l\'alerte à jour '
    '(plus ancienne valeur serveur, plus récente valeur appliquée)',
    () async {
      await recorder.recordConflict(ownerId: _owner, conflict: _hp(12, 5));
      final first = (await alerts()).single;
      await recorder.recordConflict(ownerId: _owner, conflict: _hp(20, 8));

      final all = await alerts();
      expect(all, hasLength(1));
      expect(all.single.id, first.id, reason: 'même alerte, pas de ré-annonce');
      expect(all.single.serverValue!['currentHp'], 12);
      expect(all.single.serverValue!['queued'], {
        'currentHp': 8,
        'temporaryHp': 0,
      });
    },
  );

  test('alerte fermée : un nouveau conflit crée une nouvelle alerte', () async {
    await recorder.recordConflict(ownerId: _owner, conflict: _hp(12, 5));
    await store.dismiss(ownerId: _owner, id: (await alerts()).single.id);
    expect(await alerts(), isEmpty);

    await recorder.recordConflict(ownerId: _owner, conflict: _hp(20, 8));

    expect((await alerts()).single.serverValue!['currentHp'], 20);
  });

  test('non fermée : l\'alerte survit à un « redémarrage » (nouvelle '
      'instance du store)', () async {
    await recorder.recordConflict(ownerId: _owner, conflict: _hp(12, 5));
    final reopened = SyncAlertStore(db);
    expect(await reopened.allForOwner(_owner), hasLength(1));
  });

  test('(personnage, dataKind) différents : alertes séparées, jamais '
      'agrégées', () async {
    await seed(character: 'c2', name: 'Bren');
    await recorder.recordConflict(ownerId: _owner, conflict: _hp(12, 5));
    await recorder.recordConflict(
      ownerId: _owner,
      conflict: _hp(7, 2, character: 'c2'),
    );
    await recorder.recordConflict(ownerId: _owner, conflict: _item('l1', 3, 2));
    await recorder.recordConflict(
      ownerId: _owner,
      conflict: _item('l1', 3, 2, character: 'c2'),
    );

    expect(await alerts(), hasLength(4));
  });

  test('monnaies : seules les pièces en conflit, avec leur valeur '
      'appliquée ; fusion par pièce', () async {
    await recorder.recordConflict(
      ownerId: _owner,
      conflict: _currency({'currency_gp': 120}, {'currency_gp': 85}),
    );
    await recorder.recordConflict(
      ownerId: _owner,
      conflict: _currency(
        {'currency_gp': 130, 'currency_sp': 4},
        {'currency_gp': 70, 'currency_sp': 10},
      ),
    );

    final alert = (await alerts()).single;
    expect(alert.serverValue, {
      'currency_gp': 120,
      'currency_sp': 4,
      'queued': {'currency_gp': 70, 'currency_sp': 10},
    });
  });

  test('objets : nom retrouvé (personnalisé et catalogue), UNE alerte pour '
      'plusieurs objets du même personnage', () async {
    await recorder.recordConflict(ownerId: _owner, conflict: _item('l1', 5, 4));
    await recorder.recordConflict(ownerId: _owner, conflict: _item('l2', 9, 8));
    await recorder.recordConflict(ownerId: _owner, conflict: _item('l3', 2, 1));

    final alert = (await alerts()).single;
    final items = alert.serverValue!['items'] as List;
    expect(items.map((e) => (e as Map)['name']), [
      'Potion maison',
      'Torche',
      'Corde',
    ]);
    expect((items[1] as Map)['server'], 9);
    expect((items[1] as Map)['queued'], 8);
  });

  test(
    'objet : plus ancienne valeur serveur, plus récente appliquée',
    () async {
      await recorder.recordConflict(
        ownerId: _owner,
        conflict: _item('l1', 5, 4),
      );
      await recorder.recordConflict(
        ownerId: _owner,
        conflict: _item('l1', 9, 2),
      );

      final items = (await alerts()).single.serverValue!['items'] as List;
      expect(items, hasLength(1));
      expect((items.single as Map)['server'], 5);
      expect((items.single as Map)['queued'], 2);
    },
  );

  test('objet du catalogue sans nom en cache : nom null (repli à '
      'l\'affichage)', () async {
    await recorder.recordConflict(ownerId: _owner, conflict: _item('l4', 5, 4));
    final items = (await alerts()).single.serverValue!['items'] as List;
    expect((items.single as Map)['name'], isNull);
  });

  test('ancienne alerte (sans valeur appliquée) : remplacée par la nouvelle '
      'valeur, jamais d\'exception', () async {
    await store.add(
      ownerId: _owner,
      kind: SyncAlertKind.conflict,
      characterId: 'c1',
      characterName: 'Aria',
      dataKind: 'hp',
      serverValue: {'currentHp': 7, 'maxHp': 12},
    );

    await recorder.recordConflict(ownerId: _owner, conflict: _hp(12, 5));

    final alert = (await alerts()).single;
    expect(alert.serverValue!['queued'], {'currentHp': 5, 'temporaryHp': 0});
    expect(alert.serverValue!['currentHp'], 12);
  });

  test('isolation par compte ; purge par removeAllForOwner', () async {
    await seed(owner: 'owner-2');
    await recorder.recordConflict(ownerId: _owner, conflict: _hp(12, 5));
    await recorder.recordConflict(ownerId: 'owner-2', conflict: _hp(7, 2));

    expect(await alerts(), hasLength(1));
    expect((await alerts('owner-2')).single.serverValue!['currentHp'], 7);

    await store.removeAllForOwner(_owner);
    expect(await alerts(), isEmpty);
    expect(await alerts('owner-2'), hasLength(1));
  });
}
