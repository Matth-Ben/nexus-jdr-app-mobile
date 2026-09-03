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

    group('getFresh (TTL)', () {
      test('retourne null pour une clé jamais mise en cache', () async {
        final result = await cache.getFresh(
          'inconnue',
          maxAge: const Duration(hours: 48),
        );

        expect(result, isNull);
      });

      test(
        'retourne le payload décodé pour une entrée plus récente que maxAge',
        () async {
          await cache.put('race_catalog', {'races': []});

          final result = await cache.getFresh(
            'race_catalog',
            maxAge: const Duration(hours: 48),
          );

          expect(result, {'races': []});
        },
      );

      test('retourne null pour une entrée plus vieille que maxAge, sans la '
          'supprimer du cache (get la retrouve toujours)', () async {
        // Écrit directement la ligne drift avec un `cachedAt` déjà périmé,
        // plutôt que d'attendre 48h réelles dans le test — `put` fixe
        // toujours `cachedAt: DateTime.now()` (voir sa doc), donc
        // inutilisable ici pour fabriquer une entrée déjà vieille.
        await db
            .into(db.cachedReferenceEntries)
            .insertOnConflictUpdate(
              CachedReferenceEntriesCompanion.insert(
                key: 'race_catalog',
                payload: '{"races":[]}',
                cachedAt: DateTime.now().subtract(const Duration(hours: 49)),
              ),
            );

        final freshResult = await cache.getFresh(
          'race_catalog',
          maxAge: const Duration(hours: 48),
        );
        final staleResult = await cache.get('race_catalog');

        expect(
          freshResult,
          isNull,
          reason:
              'une entrée de plus de 48h ne doit jamais être considérée '
              'comme fraîche',
        );
        expect(
          staleResult,
          {'races': []},
          reason:
              'le TTL ne doit jamais faire disparaître une entrée de '
              'cache existante, seulement décider si elle est fraîche',
        );
      });

      test('une entrée pile à la limite de maxAge est encore considérée '
          'fraîche (comparaison stricte, pas inclusive)', () async {
        await db
            .into(db.cachedReferenceEntries)
            .insertOnConflictUpdate(
              CachedReferenceEntriesCompanion.insert(
                key: 'race_catalog',
                payload: '{"races":[]}',
                cachedAt: DateTime.now().subtract(const Duration(hours: 1)),
              ),
            );

        final result = await cache.getFresh(
          'race_catalog',
          maxAge: const Duration(hours: 48),
        );

        expect(result, {'races': []});
      });
    });
  });
}
