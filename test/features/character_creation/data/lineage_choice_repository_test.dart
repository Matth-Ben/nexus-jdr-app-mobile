import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/features/character_creation/data/lineage_choice_repository.dart';
import 'package:personnages/features/character_creation/domain/character_creation_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// `SupabaseClient` réel dont seul le transport HTTP est fabriqué — même
/// principe que `subclass_choice_repository_test.dart`.
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

void main() {
  late AppDatabase cacheDb;
  late ReferenceDataCache cache;

  setUp(() {
    cacheDb = AppDatabase(NativeDatabase.memory());
    cache = ReferenceDataCache(cacheDb);
  });

  tearDown(() => cacheDb.close());

  // Les 19 lignes réelles `2024_lineage`/`subrace_id IS NULL` (Drakéide,
  // Tieffelin, Goliath) — mêmes données que la consigne de la tâche.
  Object okHandler(http.Request request) {
    switch (request.url.pathSegments.last) {
      case 'race_lineages':
        return [
          {'id': 34, 'race_id': 5, 'damage_type': 'acide'},
          {'id': 41, 'race_id': 5, 'damage_type': 'feu'},
          {'id': 31, 'race_id': 9, 'damage_type': null},
          {'id': 32, 'race_id': 9, 'damage_type': null},
          {'id': 33, 'race_id': 9, 'damage_type': null},
          {'id': 25, 'race_id': 24, 'damage_type': null},
        ];
      case 'translations':
        return [
          {'entity_id': '34', 'value': 'Ancêtre draconique 2024 : Noir'},
          {'entity_id': '41', 'value': 'Ancêtre draconique 2024 : Rouge'},
          {'entity_id': '31', 'value': 'Abyssal'},
          {'entity_id': '32', 'value': 'Chtonien'},
          {'entity_id': '33', 'value': 'Infernal'},
          {'entity_id': '25', 'value': 'Géant des nuages'},
        ];
      case 'racial_innate_spells':
        return [
          {'lineage_id': 31},
          {'lineage_id': 32},
          {'lineage_id': 33},
        ];
    }
    return const [];
  }

  group('SupabaseLineageChoiceRepository', () {
    test('groupe les lignées par race_id, titres/sous-titres exacts pour '
        'les 3 races concernées', () async {
      final catalog = await SupabaseLineageChoiceRepository(
        _client(okHandler),
        cache,
      ).fetchLineageChoices();

      expect(catalog.isConcerned(5), isTrue);
      expect(catalog.optionsFor(5).map((o) => o.name), [
        'Dragon noir',
        'Dragon rouge',
      ]);
      expect(catalog.optionsFor(5).map((o) => o.subtitle), [
        'Souffle et résistance : Acide',
        'Souffle et résistance : Feu',
      ]);

      expect(catalog.isConcerned(9), isTrue);
      expect(catalog.optionsFor(9).map((o) => o.name), [
        'Abyssal',
        'Chtonien',
        'Infernal',
      ]);
      expect(
        catalog
            .optionsFor(9)
            .every(
              (o) =>
                  o.subtitle ==
                  'Détermine les sorts innés acquis (niveaux 1, 3 et 5)',
            ),
        isTrue,
      );

      expect(catalog.isConcerned(24), isTrue);
      expect(catalog.optionsFor(24).single.name, 'Géant des nuages');
      expect(catalog.optionsFor(24).single.subtitle, isNull);

      // L'Elfe (sous-races existantes) n'est jamais concerné par ce
      // catalogue : aucune ligne mockée pour lui, comportement attendu.
      expect(catalog.isConcerned(1), isFalse);
      expect(catalog.optionsFor(1), isEmpty);
    });

    test(
      'la requête filtre bien sur lineage_group et subrace_id IS NULL',
      () async {
        final requests = <http.Request>[];
        final client = _client((request) {
          requests.add(request);
          return okHandler(request);
        });

        await SupabaseLineageChoiceRepository(
          client,
          cache,
        ).fetchLineageChoices();

        final lineagesRequest = requests.firstWhere(
          (r) => r.url.pathSegments.last == 'race_lineages',
        );
        expect(
          lineagesRequest.url.queryParameters['lineage_group'],
          'eq.2024_lineage',
        );
        expect(lineagesRequest.url.queryParameters['subrace_id'], 'is.null');
      },
    );

    test('aucune lignée : catalogue vide, aucune requête translations/'
        'racial_innate_spells', () async {
      final tables = <String>[];
      final client = _client((request) {
        tables.add(request.url.pathSegments.last);
        return const <Map<String, dynamic>>[];
      });

      final catalog = await SupabaseLineageChoiceRepository(
        client,
        cache,
      ).fetchLineageChoices();

      expect(catalog.optionsByRaceId, isEmpty);
      expect(tables, ['race_lineages']);
    });

    test('erreur HTTP : CharacterCreationFailure', () async {
      final client = _client(
        (request) => {'message': 'boom', 'code': 'PGRST000'},
        status: 500,
      );

      expect(
        SupabaseLineageChoiceRepository(client, cache).fetchLineageChoices(),
        throwsA(isA<CharacterCreationFailure>()),
      );
    });
  });

  group('SupabaseLineageChoiceRepository — hors-ligne (cache)', () {
    test('cache frais : aucune requête réseau', () async {
      await SupabaseLineageChoiceRepository(
        _client(okHandler),
        cache,
      ).fetchLineageChoices();

      var requests = 0;
      final offline = _client((request) {
        requests++;
        return const [];
      });
      final catalog = await SupabaseLineageChoiceRepository(
        offline,
        cache,
      ).fetchLineageChoices();

      expect(requests, 0);
      expect(catalog.optionsFor(24).single.name, 'Géant des nuages');
    });

    test('cache périmé + échec réseau : retombe sur le cache', () async {
      await SupabaseLineageChoiceRepository(
        _client(okHandler),
        cache,
      ).fetchLineageChoices();
      final entry = await cacheDb
          .select(cacheDb.cachedReferenceEntries)
          .getSingle();
      await cacheDb
          .into(cacheDb.cachedReferenceEntries)
          .insertOnConflictUpdate(
            CachedReferenceEntriesCompanion.insert(
              key: entry.key,
              payload: entry.payload,
              cachedAt: DateTime.now().subtract(const Duration(hours: 49)),
            ),
          );

      var requests = 0;
      final failing = _client((request) {
        requests++;
        return {'message': 'boom', 'code': 'PGRST000'};
      }, status: 500);
      final catalog = await SupabaseLineageChoiceRepository(
        failing,
        cache,
      ).fetchLineageChoices();

      expect(requests, greaterThan(0));
      expect(catalog.optionsFor(9), hasLength(3));
    });

    test('ni réseau ni cache : CharacterCreationFailure', () async {
      final failing = _client(
        (request) => {'message': 'boom', 'code': 'PGRST000'},
        status: 500,
      );
      expect(
        SupabaseLineageChoiceRepository(failing, cache).fetchLineageChoices(),
        throwsA(isA<CharacterCreationFailure>()),
      );
    });
  });
}
