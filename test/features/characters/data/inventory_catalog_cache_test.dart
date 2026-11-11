import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/features/characters/data/inventory_catalog_cache.dart';

void main() {
  group('InventoryCatalogCache', () {
    test('buildPayload : version courante, isCurrent', () {
      final payload = InventoryCatalogCache.buildPayload(
        itemRows: [
          {'id': 1},
        ],
        nameRows: const [],
        descriptionRows: const [],
      );

      expect(payload['version'], InventoryCatalogCache.payloadVersion);
      expect(InventoryCatalogCache.isCurrent(payload), isTrue);
      expect(InventoryCatalogCache.isCurrent({'items': []}), isFalse);
      expect(InventoryCatalogCache.isCurrent('x'), isFalse);
      expect(InventoryCatalogCache.isCurrent(null), isFalse);
    });

    test('fromPayload : lignes par id, noms et descriptions', () {
      final snapshot = InventoryCatalogSnapshot.fromPayload({
        'version': 2,
        'items': [
          {'id': 11, 'weight': 0.5},
          {'id': 12},
          'pas une map',
          {'sans_id': true},
        ],
        'itemNames': [
          {'entity_id': '11', 'value': 'Dague'},
        ],
        'itemDescriptions': [
          {'entity_id': '11', 'value': 'Lame'},
        ],
      })!;

      expect(snapshot.itemRows.keys, [11, 12]);
      expect(snapshot.itemRows[11]!['weight'], 0.5);
      expect(snapshot.names, {'11': 'Dague'});
      expect(snapshot.descriptions, {'11': 'Lame'});
    });

    test('fromPayload : ancien format ou illisible, jamais d\'exception', () {
      expect(InventoryCatalogSnapshot.fromPayload(null), isNull);
      expect(InventoryCatalogSnapshot.fromPayload('x'), isNull);
      final old = InventoryCatalogSnapshot.fromPayload({'items': 3})!;
      expect(old.itemRows, isEmpty);
      expect(old.names, isEmpty);
      expect(old.descriptions, isEmpty);
    });

    test('read : null si absent, snapshot si présent', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final cache = ReferenceDataCache(db);

      expect(await InventoryCatalogCache.read(cache), isNull);

      await cache.put(InventoryCatalogCache.key, {
        'version': 2,
        'items': [
          {'id': 1},
        ],
      });

      expect((await InventoryCatalogCache.read(cache))!.itemRows.keys, [1]);
    });

    test('donnée de référence publique : la purge totale du cache à la '
        'déconnexion (ReferenceDataCache.clear) la vide, sans conséquence '
        'au-delà d une relecture réseau', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final cache = ReferenceDataCache(db);
      await cache.put(InventoryCatalogCache.key, {'version': 2, 'items': []});

      await cache.clear();

      expect(await InventoryCatalogCache.read(cache), isNull);
    });
  });
}
