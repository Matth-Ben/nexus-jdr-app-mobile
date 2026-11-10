// Écriture des conditions (P6) : remplacement complet du tableau, hors-ligne
// = rejectedOffline (rien d'envoyé), erreurs d'autorisation gérées.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:personnages/core/network/connectivity_checker.dart';
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
    );

    await repository.setConditions(characterId: characterId, conditions: []);

    expect(jsonDecode(sent.singleWhere((r) => r.method == 'PATCH').body), {
      'conditions': <String>[],
    });
  });

  test('hors-ligne : rejectedOffline, aucune requête envoyée', () async {
    final sent = <http.Request>[];
    final repository = SupabaseCharacterConditionsRepository(
      await _client(
        sent: sent,
        respond: (r) => throw const SocketException('pas de réseau'),
      ),
      _Connectivity(false),
    );

    final outcome = await repository.setConditions(
      characterId: characterId,
      conditions: [ConditionType.prone],
    );

    expect(outcome, WriteOutcome.rejectedOffline);
    expect(sent, isEmpty);
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

  test('erreur réseau : CharacterFailure de type network', () async {
    final repository = SupabaseCharacterConditionsRepository(
      await _client(respond: (r) => throw const SocketException('coupé')),
      _Connectivity(true),
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
          CharacterErrorCode.network,
        ),
      ),
    );
  });
}
