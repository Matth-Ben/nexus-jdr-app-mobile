import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/features/characters/data/warlock_pact_spell_repository.dart';
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
    case 'subclass_spells':
      return [
        {'subclass_id': 91, 'spell_id': 20, 'class_level': 1},
      ];
    case 'spells':
      return [
        {
          'id': 20,
          'level': 1,
          'school': 'Évocation',
          'casting_time': '1 action',
          'is_incomplete': false,
        },
      ];
    case 'translations':
      return [
        {'entity_id': '20', 'value': 'Mains brûlantes'},
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

  test('fetchPatronExtendedSpells : réseau OK écrit le cache', () async {
    final result = await SupabaseWarlockPactSpellRepository(
      _client(_okHandler),
      cache,
    ).fetchPatronExtendedSpells(subclassIds: [91]);

    expect(result[91]!.single.spell.name, 'Mains brûlantes');
    expect(await db.select(db.cachedReferenceEntries).get(), hasLength(1));
  });

  test(
    'fetchPatronExtendedSpells : échec réseau, repli sur le cache',
    () async {
      await SupabaseWarlockPactSpellRepository(
        _client(_okHandler),
        cache,
      ).fetchPatronExtendedSpells(subclassIds: [91]);

      final result = await SupabaseWarlockPactSpellRepository(
        failing(),
        cache,
      ).fetchPatronExtendedSpells(subclassIds: [91]);

      expect(result[91]!.single.spell.name, 'Mains brûlantes');
      expect(result[91]!.single.classLevel, 1);
    },
  );

  test(
    'fetchPatronExtendedSpells : ni réseau ni cache -> CharacterFailure',
    () async {
      expect(
        SupabaseWarlockPactSpellRepository(
          failing(),
          cache,
        ).fetchPatronExtendedSpells(subclassIds: [91]),
        throwsA(isA<CharacterFailure>()),
      );
    },
  );

  test(
    'fetchPatronExtendedSpells : sous-classe sans liste étendue -> vide',
    () async {
      final result = await SupabaseWarlockPactSpellRepository(
        _client((request) => const <Map<String, dynamic>>[]),
        cache,
      ).fetchPatronExtendedSpells(subclassIds: [55]);

      expect(result, isEmpty);
    },
  );
}
