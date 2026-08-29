import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';

void main() {
  group('ReferenceDataCache', () {
    late AppDatabase db;
    late ReferenceDataCache cache;

    setUp(() {
      // Base drift en mémoire, jamais un vrai fichier disque dans les tests
      // (voir la doc de classe d'`AppDatabase`).
      db = AppDatabase(NativeDatabase.memory());
      cache = ReferenceDataCache(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('get retourne null pour une clé jamais mise en cache', () async {
      final result = await cache.get('inconnue');

      expect(result, isNull);
    });

    test('put puis get restitue le payload encodé/décodé en JSON', () async {
      await cache.put('race_catalog', {
        'races': [
          {
            'id': 1,
            'ability_bonuses': {'dex': 2},
            'traits': [
              {'name': 'Vision dans le noir', 'description': '18 mètres'},
            ],
          },
        ],
      });

      final result = await cache.get('race_catalog');

      expect(result, {
        'races': [
          {
            'id': 1,
            'ability_bonuses': {'dex': 2},
            'traits': [
              {'name': 'Vision dans le noir', 'description': '18 mètres'},
            ],
          },
        ],
      });
    });

    test('put sur une clé déjà présente la remplace (upsert)', () async {
      await cache.put('spell_catalog:1', {'spells': []});
      await cache.put('spell_catalog:1', {
        'spells': [
          {'id': 42},
        ],
      });

      final result = await cache.get('spell_catalog:1');

      expect(result, {
        'spells': [
          {'id': 42},
        ],
      });
    });

    test('deux clés distinctes (ex. spell_catalog paramétré par classId) '
        'restent indépendantes', () async {
      await cache.put('spell_catalog:1', {'spells': 'classe 1'});
      await cache.put('spell_catalog:2', {'spells': 'classe 2'});

      expect(await cache.get('spell_catalog:1'), {'spells': 'classe 1'});
      expect(await cache.get('spell_catalog:2'), {'spells': 'classe 2'});
    });
  });
}
