import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/features/characters/data/racial_innate_spell_repository.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

SupabaseClient _client(
  Object Function(http.Request request) handler, {
  int status = 200,
  void Function(http.Request request)? onRequest,
}) {
  return SupabaseClient(
    'https://fake.supabase.test',
    'fake-anon-key',
    httpClient: MockClient((request) async {
      onRequest?.call(request);
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

// Simule le Tieffelin (`race_id = 9`) : Thaumaturgie niveau 1, Représailles
// infernales niveau 3, Ténèbres niveau 5 — mêmes données réelles que la
// consigne de la tâche, le mock ne filtrant pas lui-même par query string
// (voir `character_creation_repository_test.dart`), seul le filtrage
// `lineage_id`/`character_level` CÔTÉ SERVEUR réel compte en production ;
// ici on renvoie directement ce qu'un vrai serveur renverrait déjà filtré
// par `character_level <= maxCharacterLevel` pour chaque test.
Object _okHandler(http.Request request) {
  switch (request.url.pathSegments.last) {
    case 'racial_innate_spells':
      return [
        {'spell_id': 24, 'subrace_id': null, 'character_level': 1},
      ];
    case 'translations':
      return [
        {'entity_id': '24', 'value': 'Thaumaturgie'},
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

  group('fetchApplicableGrants', () {
    test('réseau OK : sort résolu, cache écrit', () async {
      final result = await SupabaseRacialInnateSpellRepository(
        _client(_okHandler),
        cache,
      ).fetchApplicableGrants(raceId: 9, maxCharacterLevel: 1);

      expect(result, hasLength(1));
      expect(result.single.spellId, 24);
      expect(result.single.spellName, 'Thaumaturgie');
      expect(await db.select(db.cachedReferenceEntries).get(), hasLength(1));
    });

    test('aucun sort (spell_id tous nuls) : liste vide, pas de requête '
        "translations (aucun identifiant à résoudre)", () async {
      var translationsRequests = 0;
      final result = await SupabaseRacialInnateSpellRepository(
        _client((request) {
          if (request.url.pathSegments.last == 'translations') {
            translationsRequests++;
          }
          return const <Map<String, dynamic>>[];
        }),
        cache,
      ).fetchApplicableGrants(raceId: 2, maxCharacterLevel: 20);

      expect(result, isEmpty);
      expect(translationsRequests, 0);
    });

    test('échec réseau : repli sur le cache', () async {
      await SupabaseRacialInnateSpellRepository(
        _client(_okHandler),
        cache,
      ).fetchApplicableGrants(raceId: 9, maxCharacterLevel: 1);

      final result = await SupabaseRacialInnateSpellRepository(
        failing(),
        cache,
      ).fetchApplicableGrants(raceId: 9, maxCharacterLevel: 1);

      expect(result, hasLength(1));
      expect(result.single.spellName, 'Thaumaturgie');
    });

    test('ni réseau ni cache : CharacterFailure', () async {
      expect(
        SupabaseRacialInnateSpellRepository(
          failing(),
          cache,
        ).fetchApplicableGrants(raceId: 9, maxCharacterLevel: 1),
        throwsA(isA<CharacterFailure>()),
      );
    });

    test('clés de cache distinctes par race/sous-race/niveau max', () async {
      await SupabaseRacialInnateSpellRepository(
        _client(_okHandler),
        cache,
      ).fetchApplicableGrants(raceId: 9, maxCharacterLevel: 1);

      // Une race/niveau différent ne doit jamais retomber sur le cache de
      // la première lecture en cas d'échec réseau.
      expect(
        SupabaseRacialInnateSpellRepository(
          failing(),
          cache,
        ).fetchApplicableGrants(raceId: 2, subraceId: 3, maxCharacterLevel: 5),
        throwsA(isA<CharacterFailure>()),
      );
    });

    test('lineageId nul : filtre toujours lineage_id IS NULL seul '
        '(comportement historique inchangé)', () async {
      final requests = <http.Request>[];
      final client = _client((request) {
        requests.add(request);
        return _okHandler(request);
      });

      await SupabaseRacialInnateSpellRepository(
        client,
        cache,
      ).fetchApplicableGrants(raceId: 9, maxCharacterLevel: 1);

      final lineagesRequest = requests.firstWhere(
        (r) => r.url.pathSegments.last == 'racial_innate_spells',
      );
      expect(lineagesRequest.url.queryParameters['lineage_id'], 'is.null');
      expect(lineagesRequest.url.queryParameters['or'], isNull);
    });

    test('lineageId non nul (Tieffelin) : lignage_id.is.null OR lineage_id.eq.'
        '<id> dans la requête, les 3 sorts de la lignée choisie (niveaux '
        '1/3/5) sont renvoyés, ceux des 2 autres lignées non', () async {
      // Simule le filtrage serveur réel `lineage_id IS NULL OR
      // lineage_id = 32` (Chtonien) sur les 3 lignées fiélonnes du
      // Tieffelin : seules les lignes sans lignée (aucune ici) ou de la
      // lignée 32 doivent être renvoyées — jamais celles des lignées 31
      // (Abyssal) et 33 (Infernal).
      const allRows = [
        {
          'spell_id': 101,
          'subrace_id': null,
          'character_level': 1,
          'lineage_id': 32,
        },
        {
          'spell_id': 102,
          'subrace_id': null,
          'character_level': 3,
          'lineage_id': 32,
        },
        {
          'spell_id': 103,
          'subrace_id': null,
          'character_level': 5,
          'lineage_id': 32,
        },
        {
          'spell_id': 201,
          'subrace_id': null,
          'character_level': 1,
          'lineage_id': 31,
        },
        {
          'spell_id': 301,
          'subrace_id': null,
          'character_level': 1,
          'lineage_id': 33,
        },
      ];
      final requests = <http.Request>[];
      final client = _client((request) {
        requests.add(request);
        switch (request.url.pathSegments.last) {
          case 'racial_innate_spells':
            return [
              for (final row in allRows)
                if (row['lineage_id'] == null || row['lineage_id'] == 32) row,
            ];
          case 'translations':
            return [
              {'entity_id': '101', 'value': 'Thaumaturgie'},
              {'entity_id': '102', 'value': 'Représailles infernales'},
              {'entity_id': '103', 'value': 'Ténèbres'},
            ];
        }
        return const [];
      });

      final result = await SupabaseRacialInnateSpellRepository(
        client,
        cache,
      ).fetchApplicableGrants(raceId: 9, lineageId: 32, maxCharacterLevel: 5);

      expect(result.map((g) => g.spellId), [101, 102, 103]);
      expect(result.map((g) => g.characterLevel), [1, 3, 5]);

      final lineagesRequest = requests.firstWhere(
        (r) => r.url.pathSegments.last == 'racial_innate_spells',
      );
      expect(
        lineagesRequest.url.queryParameters['or'],
        '(lineage_id.is.null,lineage_id.eq.32)',
      );
      expect(lineagesRequest.url.queryParameters['lineage_id'], isNull);
    });
  });
}
