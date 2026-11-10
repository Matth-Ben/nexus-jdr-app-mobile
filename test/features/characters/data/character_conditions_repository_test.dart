// Écriture des conditions (P6, P6b) : remplacement complet du tableau,
// hors-ligne ou erreur de transport = mise en file (queued), erreurs
// d'autorisation gérées (jamais mises en file).

import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:personnages/core/cache/app_database.dart'
    hide PendingCharacterWrite;
import 'package:personnages/core/cache/pending_character_write_queue.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/core/network/connectivity_checker.dart';
import 'package:personnages/features/characters/data/character_detail_cache.dart';
import 'package:personnages/features/characters/data/character_conditions_repository.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/condition_type.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Connectivity implements ConnectivityChecker {
  _Connectivity(this.connected);

  final bool connected;

  @override
  Future<bool> hasConnection() async => connected;

  @override
  Stream<bool> get onConnectivityRestored => const Stream.empty();

  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();
}

/// Client Supabase réel dont le transport HTTP est fabriqué, authentifié en
/// mémoire — même technique que `character_repository_test.dart`.
Future<SupabaseClient> _client({
  String? ownerId = 'owner-1',
  required http.Response Function(http.Request request) respond,
  List<http.Request>? sent,
}) async {
  final client = SupabaseClient(
    'https://fake.supabase.test',
    'fake-anon-key',
    httpClient: MockClient((request) async {
      sent?.add(request);
      return respond(request);
    }),
    postgrestOptions: const PostgrestClientOptions(retryEnabled: false),
    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
  );
  if (ownerId != null) {
    await client.auth.recoverSession(
      jsonEncode({
        'access_token': 'fake-access-token-$ownerId',
        'token_type': 'bearer',
        'user': {'id': ownerId},
      }),
    );
  }
  return client;
}

http.Response _json(Object body, int status, http.Request request) =>
    http.Response(
      jsonEncode(body),
      status,
      request: request,
      headers: {'content-type': 'application/json'},
    );

void main() {
  const characterId = 'char-1';
  late AppDatabase db;
  late PendingCharacterWriteQueue queue;
  late ReferenceDataCache cache;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    queue = PendingCharacterWriteQueue(db);
    cache = ReferenceDataCache(db);
  });

  tearDown(() => db.close());

  test('connecté : PATCH characters avec le tableau complet des clés '
      'canoniques, filtré sur id ET owner_id', () async {
    final sent = <http.Request>[];
    final repository = SupabaseCharacterConditionsRepository(
      await _client(
        sent: sent,
        respond: (r) => _json(
          [
            {'id': characterId},
          ],
          200,
          r,
        ),
      ),
      _Connectivity(true),
      queue,
      cache,
    );

    final outcome = await repository.setConditions(
      characterId: characterId,
      conditions: [
        ConditionType.stunned,
        ConditionType.blinded,
        ConditionType.stunned,
      ],
    );

    expect(outcome, WriteOutcome.synced);
    final patch = sent.singleWhere((r) => r.method == 'PATCH');
    expect(patch.url.pathSegments.last, 'characters');
    expect(jsonDecode(patch.body), {
      'conditions': ['blinded', 'stunned'],
    });
    expect(patch.url.queryParameters['id'], 'eq.$characterId');
    expect(patch.url.queryParameters['owner_id'], 'eq.owner-1');
  });

  test('clés inconnues réinjectées dans le tableau écrit (désélection d une '
      'condition connue effective)', () async {
    final sent = <http.Request>[];
    final repository = SupabaseCharacterConditionsRepository(
      await _client(
        sent: sent,
        respond: (r) => _json(
          [
            {'id': characterId},
          ],
          200,
          r,
        ),
      ),
      _Connectivity(true),
      queue,
      cache,
    );

    await repository.setConditions(
      characterId: characterId,
      conditions: [ConditionType.prone],
      unknownKeys: ['futur_etat'],
    );

    expect(jsonDecode(sent.singleWhere((r) => r.method == 'PATCH').body), {
      'conditions': ['prone', 'futur_etat'],
    });
  });

  test('aucune condition : le tableau vide REMPLACE l\'ancien', () async {
    final sent = <http.Request>[];
    final repository = SupabaseCharacterConditionsRepository(
      await _client(
        sent: sent,
        respond: (r) => _json(
          [
            {'id': characterId},
          ],
          200,
          r,
        ),
      ),
      _Connectivity(true),
      queue,
      cache,
    );

    await repository.setConditions(characterId: characterId, conditions: []);

    expect(jsonDecode(sent.singleWhere((r) => r.method == 'PATCH').body), {
      'conditions': <String>[],
    });
  });

  test('hors-ligne : queued, aucune requête envoyée, une ligne en file '
      '(tableau complet, clés inconnues préservées)', () async {
    final sent = <http.Request>[];
    final repository = SupabaseCharacterConditionsRepository(
      await _client(
        sent: sent,
        respond: (r) => throw const SocketException('pas de réseau'),
      ),
      _Connectivity(false),
      queue,
      cache,
    );

    final outcome = await repository.setConditions(
      characterId: characterId,
      conditions: [ConditionType.prone],
      unknownKeys: ['futur_etat'],
    );

    expect(outcome, WriteOutcome.queued);
    expect(sent, isEmpty);
    final rows = await queue.allForOwner('owner-1');
    expect(rows, hasLength(1));
    expect(rows.single.kind, PendingCharacterWriteKind.conditions);
    expect(rows.single.targetId, '');
    expect(rows.single.characterId, characterId);
    expect(rows.single.payload, {
      'conditions': ['prone', 'futur_etat'],
    });
  });

  test(
    'deux sélections hors ligne : une seule ligne, la dernière gagne',
    () async {
      final repository = SupabaseCharacterConditionsRepository(
        await _client(respond: (r) => throw const SocketException('x')),
        _Connectivity(false),
        queue,
        cache,
      );

      await repository.setConditions(
        characterId: characterId,
        conditions: [ConditionType.prone],
      );
      await repository.setConditions(
        characterId: characterId,
        conditions: [ConditionType.blinded, ConditionType.charmed],
      );

      final rows = await queue.allForOwner('owner-1');
      expect(rows, hasLength(1));
      expect(rows.single.payload['conditions'], ['blinded', 'charmed']);
    },
  );

  test('refus Postgres 42501 : échec, rien en file', () async {
    final repository = SupabaseCharacterConditionsRepository(
      await _client(
        respond: (r) => _json({'message': 'denied', 'code': '42501'}, 403, r),
      ),
      _Connectivity(true),
      queue,
      cache,
    );

    await expectLater(
      repository.setConditions(
        characterId: characterId,
        conditions: [ConditionType.prone],
      ),
      throwsA(isA<CharacterFailure>()),
    );
    expect(await queue.allForOwner('owner-1'), isEmpty);
  });

  test('0 ligne mise à jour : échec, rien en file', () async {
    final repository = SupabaseCharacterConditionsRepository(
      await _client(respond: (r) => _json([], 200, r)),
      _Connectivity(true),
      queue,
      cache,
    );

    await expectLater(
      repository.setConditions(
        characterId: characterId,
        conditions: [ConditionType.prone],
      ),
      throwsA(isA<CharacterFailure>()),
    );
    expect(await queue.allForOwner('owner-1'), isEmpty);
  });

  test('écriture en ligne réussie : retire l\'entrée périmée de la file et '
      'reporte les conditions dans le cache de la fiche', () async {
    await queue.enqueue(
      characterId: characterId,
      ownerId: 'owner-1',
      kind: PendingCharacterWriteKind.conditions,
      targetId: '',
      payload: {
        'conditions': ['prone'],
      },
    );
    await cache.put(
      CharacterDetailCache.keyFor(ownerId: 'owner-1', characterId: characterId),
      {
        CharacterDetailCache.rowKey: {'id': characterId, 'conditions': []},
      },
    );
    final repository = SupabaseCharacterConditionsRepository(
      await _client(
        respond: (r) => _json(
          [
            {'id': characterId},
          ],
          200,
          r,
        ),
      ),
      _Connectivity(true),
      queue,
      cache,
    );

    final outcome = await repository.setConditions(
      characterId: characterId,
      conditions: [ConditionType.blinded],
    );

    expect(outcome, WriteOutcome.synced);
    expect(await queue.allForOwner('owner-1'), isEmpty);
    final row = await CharacterDetailCache(cache)
        .readRow(ownerId: 'owner-1', characterId: characterId);
    expect(row?['conditions'], ['blinded']);
  });

  test('session absente : CharacterFailure, aucune requête', () async {
    final sent = <http.Request>[];
    final repository = SupabaseCharacterConditionsRepository(
      await _client(
        ownerId: null,
        sent: sent,
        respond: (r) => _json([], 200, r),
      ),
      _Connectivity(true),
      queue,
      cache,
    );

    await expectLater(
      repository.setConditions(characterId: characterId, conditions: []),
      throwsA(isA<CharacterFailure>()),
    );
    expect(sent, isEmpty);
  });

  test(
    'RLS qui refuse en silence (0 ligne mise à jour) : accessDenied',
    () async {
      final repository = SupabaseCharacterConditionsRepository(
        await _client(respond: (r) => _json([], 200, r)),
        _Connectivity(true),
        queue,
        cache,
      );

      await expectLater(
        repository.setConditions(
          characterId: characterId,
          conditions: [ConditionType.prone],
        ),
        throwsA(
          isA<CharacterFailure>().having(
            (f) => f.code,
            'code',
            CharacterErrorCode.accessDenied,
          ),
        ),
      );
    },
  );

  test('erreur Postgres 42501 : accessDenied', () async {
    final repository = SupabaseCharacterConditionsRepository(
      await _client(
        respond: (r) => _json({'message': 'denied', 'code': '42501'}, 403, r),
      ),
      _Connectivity(true),
      queue,
      cache,
    );

    await expectLater(
      repository.setConditions(
        characterId: characterId,
        conditions: [ConditionType.prone],
      ),
      throwsA(
        isA<CharacterFailure>().having(
          (f) => f.code,
          'code',
          CharacterErrorCode.accessDenied,
        ),
      ),
    );
  });

  test(
    'erreur de transport (en ligne déclaré) : queued, mise en file',
    () async {
      final repository = SupabaseCharacterConditionsRepository(
        await _client(respond: (r) => throw const SocketException('coupé')),
        _Connectivity(true),
        queue,
        cache,
      );

      final outcome = await repository.setConditions(
        characterId: characterId,
        conditions: [ConditionType.prone],
      );

      expect(outcome, WriteOutcome.queued);
      final rows = await queue.allForOwner('owner-1');
      expect(rows.single.payload['conditions'], ['prone']);
    },
  );
}
