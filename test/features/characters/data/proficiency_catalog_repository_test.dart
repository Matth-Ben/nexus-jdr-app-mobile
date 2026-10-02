import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/features/characters/data/proficiency_catalog_repository.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient _client(
  Object Function(http.Request request) handler, {
  int status = 200,
}) {
  return SupabaseClient(
    'https://fake.supabase.test',
    'fake-anon-key',
    httpClient: MockClient((request) async {
      return http.Response(
        jsonEncode(handler(request)),
        status,
        request: request,
        headers: {'content-type': 'application/json'},
      );
    }),
    postgrestOptions: const PostgrestClientOptions(retryEnabled: false),
    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
  );
}

Object _okHandler(http.Request request) {
  switch (request.url.pathSegments.last) {
    case 'items':
      final category = request.url.queryParameters['category'];
      if (category == 'eq.arme') {
        return [
          {
            'id': 1,
            'category': 'arme',
            'weapon_properties': {
              'damage_dice': '1d4',
              'damage_type': 'perforant',
              'properties': ['finesse', 'légère', 'lancer'],
            },
          },
          {
            'id': 2,
            'category': 'arme',
            'weapon_properties': {
              'damage_dice': '1d8',
              'damage_type': 'tranchant',
              'properties': [],
            },
          },
        ];
      }
      if (category == 'eq.armure') {
        return [
          {
            'id': 10,
            'category': 'armure',
            'armor_properties': {
              'ac_base': 11,
              'ac_dex_bonus': 'illimite',
              'strength_requirement': null,
              'stealth_disadvantage': false,
            },
          },
        ];
      }
      if (category == 'eq.bouclier') {
        return [
          {
            'id': 20,
            'category': 'bouclier',
            'armor_properties': {
              'ac_base': 2,
              'ac_dex_bonus': 'aucun',
              'strength_requirement': null,
              'stealth_disadvantage': false,
            },
          },
        ];
      }
      return const [];
    case 'translations':
      return [
        {'entity_id': '1', 'value': 'Dague'},
        {'entity_id': '2', 'value': 'Épée longue'},
        {'entity_id': '10', 'value': 'Armure de cuir'},
        {'entity_id': '20', 'value': 'Bouclier'},
      ];
  }
  return const [];
}

void main() {
  late AppDatabase db;
  late ReferenceDataCache cache;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    cache = ReferenceDataCache(db);
  });

  tearDown(() => db.close());

  SupabaseClient failing() => _client(
    (request) => {'message': 'boom', 'code': 'PGRST000'},
    status: 500,
  );

  group('fetchCatalog', () {
    test('réseau OK : armes/armures/boucliers résolus et noms traduits, '
        'cache écrit', () async {
      final catalog = await SupabaseProficiencyCatalogRepository(
        _client(_okHandler),
        cache,
      ).fetchCatalog();

      expect(catalog.weapons.map((w) => w.name), ['Dague', 'Épée longue']);
      expect(catalog.weapons.first.damageDice, '1d4');
      expect(catalog.weapons.first.properties, ['finesse', 'légère', 'lancer']);

      expect(catalog.armors.map((a) => a.name), ['Armure de cuir']);
      expect(catalog.armors.single.category, 'armure');
      expect(catalog.armors.single.acDexBonus, 'illimite');

      expect(catalog.shields.map((s) => s.name), ['Bouclier']);
      expect(catalog.shields.single.category, 'bouclier');
      expect(catalog.shields.single.acBase, 2);

      expect(await db.select(db.cachedReferenceEntries).get(), hasLength(1));
    });

    test('échec réseau : repli sur le cache', () async {
      await SupabaseProficiencyCatalogRepository(
        _client(_okHandler),
        cache,
      ).fetchCatalog();

      final catalog = await SupabaseProficiencyCatalogRepository(
        failing(),
        cache,
      ).fetchCatalog();

      expect(catalog.weapons.map((w) => w.name), ['Dague', 'Épée longue']);
      expect(catalog.shields.single.name, 'Bouclier');
    });

    test('ni réseau ni cache : CharacterFailure', () async {
      expect(
        SupabaseProficiencyCatalogRepository(failing(), cache).fetchCatalog(),
        throwsA(isA<CharacterFailure>()),
      );
    });

    test('catalogue vide : listes vides, pas de requête translations '
        '(aucun id à résoudre)', () async {
      var translationsRequested = false;
      final catalog = await SupabaseProficiencyCatalogRepository(
        _client((request) {
          if (request.url.pathSegments.last == 'translations') {
            translationsRequested = true;
          }
          return const <Map<String, dynamic>>[];
        }),
        cache,
      ).fetchCatalog();

      expect(catalog.weapons, isEmpty);
      expect(catalog.armors, isEmpty);
      expect(catalog.shields, isEmpty);
      expect(translationsRequested, isFalse);
    });
  });
}
