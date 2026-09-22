import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/core/network/connectivity_checker.dart';
import 'package:personnages/features/characters/data/pact_weapon_repository.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Checker implements ConnectivityChecker {
  _Checker(this.connected);

  final bool connected;

  @override
  Future<bool> hasConnection() async => connected;

  @override
  Stream<bool> get onConnectivityRestored => const Stream.empty();
}

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

Object _okHandler(http.Request request) {
  switch (request.url.pathSegments.last) {
    case 'items':
      return [
        {
          'id': 2,
          'category': 'arme',
          'weapon_properties': {
            'damage_dice': '1d6',
            'damage_type': 'perforant',
            'properties': ['munitions(24/96)'],
          },
        },
        {
          'id': 1,
          'category': 'arme',
          'weapon_properties': {
            'damage_dice': '1d8',
            'damage_type': 'tranchant',
            'properties': ['polyvalente(1d10)'],
          },
        },
        {
          'id': 3,
          'category': 'arme',
          'weapon_properties': {
            'damage_dice': '1d4',
            'damage_type': 'perforant',
            'properties': ['finesse'],
          },
        },
      ];
    case 'translations':
      return [
        {'entity_id': '1', 'value': 'Épée longue'},
        {'entity_id': '2', 'value': 'Arc court'},
        {'entity_id': '3', 'value': 'dague'},
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

  group('fetchEligibleWeapons', () {
    test('réseau OK : armes de mêlée éligibles triées, cache écrit', () async {
      final result = await SupabasePactWeaponRepository(
        _client(_okHandler),
        _Checker(true),
        cache,
      ).fetchEligibleWeapons();

      expect(result.map((o) => o.name), ['dague', 'Épée longue']);
      expect(result.last.damageLabel, '1d8 tranchant');
      expect(await db.select(db.cachedReferenceEntries).get(), hasLength(1));
    });

    test('échec réseau : repli sur le cache', () async {
      await SupabasePactWeaponRepository(
        _client(_okHandler),
        _Checker(true),
        cache,
      ).fetchEligibleWeapons();

      final result = await SupabasePactWeaponRepository(
        failing(),
        _Checker(true),
        cache,
      ).fetchEligibleWeapons();

      expect(result.map((o) => o.name), ['dague', 'Épée longue']);
    });

    test('ni réseau ni cache : CharacterFailure', () async {
      expect(
        SupabasePactWeaponRepository(
          failing(),
          _Checker(true),
          cache,
        ).fetchEligibleWeapons(),
        throwsA(isA<CharacterFailure>()),
      );
    });

    test('catalogue vide : liste vide', () async {
      final result = await SupabasePactWeaponRepository(
        _client((request) => const <Map<String, dynamic>>[]),
        _Checker(true),
        cache,
      ).fetchEligibleWeapons();
      expect(result, isEmpty);
    });
  });

  group('setPactWeapon', () {
    test('en ligne : upsert de la ligne du personnage, synced', () async {
      http.Request? sent;
      final outcome = await SupabasePactWeaponRepository(
        _client(
          (request) => const <Map<String, dynamic>>[],
          onRequest: (request) => sent = request,
        ),
        _Checker(true),
      ).setPactWeapon(characterId: 'char-1', itemId: 7);

      expect(outcome, WriteOutcome.synced);
      expect(sent!.method, 'POST');
      expect(sent!.url.pathSegments.last, 'character_pact_weapons');
      expect(sent!.url.queryParameters['on_conflict'], 'character_id');
      expect(sent!.headers['Prefer'], contains('resolution=merge-duplicates'));
      expect(jsonDecode(sent!.body), {'character_id': 'char-1', 'item_id': 7});
    });

    test('hors ligne : aucune requête, queued', () async {
      var requests = 0;
      final outcome = await SupabasePactWeaponRepository(
        _client(
          (request) => const <Map<String, dynamic>>[],
          onRequest: (_) => requests++,
        ),
        _Checker(false),
      ).setPactWeapon(characterId: 'char-1', itemId: 7);

      expect(outcome, WriteOutcome.queued);
      expect(requests, 0);
    });

    test('erreur serveur : CharacterFailure', () async {
      expect(
        SupabasePactWeaponRepository(
          failing(),
          _Checker(true),
        ).setPactWeapon(characterId: 'char-1', itemId: 7),
        throwsA(isA<CharacterFailure>()),
      );
    });
  });
}
