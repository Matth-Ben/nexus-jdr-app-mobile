// Tests de `SupabaseGroupRepository` — même stratégie de double que
// `test/features/characters/data/character_repository_test.dart`
// (`SupabaseClient` réel, transport HTTP entièrement fabriqué via
// `MockClient`) : corps de requête envoyé aux 3 edge functions
// (`create-group`/`preview-group-invite`/`join-group`), mapping des
// réponses/erreurs, et écritures directes (`claim_group_treasure_currency`,
// `claimTreasureItem`).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/groups/data/group_repository.dart';
import 'package:personnages/features/groups/domain/group_failure.dart';
import 'package:personnages/features/groups/domain/group_invite_failure.dart';
import 'package:personnages/features/groups/domain/group_treasure_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('SupabaseGroupRepository.createGroup', () {
    test(
      'envoie {name, character_id} à create-group et mappe la réponse',
      () async {
        http.Request? capturedRequest;
        final client = _buildFakeClient(
          onRequest: (request) => capturedRequest = request,
          responses: {
            'create-group': {
              'id': 'group-1',
              'name': 'Les Lames',
              'invite_code': 'AB3F7K2M',
            },
          },
        );
        final repository = SupabaseGroupRepository(client);

        final created = await repository.createGroup(
          name: 'Les Lames',
          characterId: 'char-1',
        );

        expect(capturedRequest, isNotNull);
        expect(
          capturedRequest!.url.path,
          endsWith('/functions/v1/create-group'),
        );
        final body = jsonDecode(capturedRequest!.body) as Map<String, dynamic>;
        expect(body, {'name': 'Les Lames', 'character_id': 'char-1'});
        expect(created.id, 'group-1');
        expect(created.name, 'Les Lames');
        expect(created.inviteCode, 'AB3F7K2M');
      },
    );

    test(
      'erreur edge function -> GroupFailure avec le message serveur',
      () async {
        final client = _buildFakeClient(
          statusCode: 500,
          responses: {
            'create-group': {
              'error': 'internal_error',
              'message': 'Erreur serveur.',
            },
          },
        );
        final repository = SupabaseGroupRepository(client);

        await expectLater(
          repository.createGroup(name: 'Les Lames', characterId: 'char-1'),
          throwsA(
            isA<GroupFailure>().having(
              (f) => f.message,
              'message',
              'Erreur serveur.',
            ),
          ),
        );
      },
    );
  });

  group('SupabaseGroupRepository.previewGroupInvite', () {
    test('envoie {code} et mappe {name, member_count}', () async {
      http.Request? capturedRequest;
      final client = _buildFakeClient(
        onRequest: (request) => capturedRequest = request,
        responses: {
          'preview-group-invite': {'name': 'Les Lames', 'member_count': 3},
        },
      );
      final repository = SupabaseGroupRepository(client);

      final preview = await repository.previewGroupInvite('AB3F7K2M');

      final body = jsonDecode(capturedRequest!.body) as Map<String, dynamic>;
      expect(body, {'code': 'AB3F7K2M'});
      expect(preview.name, 'Les Lames');
      expect(preview.memberCount, 3);
    });

    test('404 invalid_code -> GroupInviteFailureKind.invalidCode', () async {
      final client = _buildFakeClient(
        statusCode: 404,
        responses: {
          'preview-group-invite': {
            'error': 'invalid_code',
            'message': "Ce code d'invitation n'est pas valide.",
          },
        },
      );
      final repository = SupabaseGroupRepository(client);

      await expectLater(
        repository.previewGroupInvite('INVALIDE'),
        throwsA(
          isA<GroupInviteFailure>().having(
            (f) => f.kind,
            'kind',
            GroupInviteFailureKind.invalidCode,
          ),
        ),
      );
    });
  });

  group('SupabaseGroupRepository.joinGroup', () {
    test('envoie {code, character_id} et mappe {group_id, name}', () async {
      http.Request? capturedRequest;
      final client = _buildFakeClient(
        onRequest: (request) => capturedRequest = request,
        responses: {
          'join-group': {'group_id': 'group-1', 'name': 'Les Lames'},
        },
      );
      final repository = SupabaseGroupRepository(client);

      final joined = await repository.joinGroup(
        code: 'AB3F7K2M',
        characterId: 'char-1',
      );

      final body = jsonDecode(capturedRequest!.body) as Map<String, dynamic>;
      expect(body, {'code': 'AB3F7K2M', 'character_id': 'char-1'});
      expect(joined.groupId, 'group-1');
      expect(joined.name, 'Les Lames');
    });

    test(
      '409 already_in_group -> GroupInviteFailureKind.alreadyInGroup',
      () async {
        final client = _buildFakeClient(
          statusCode: 409,
          responses: {
            'join-group': {
              'error': 'already_in_group',
              'message': 'Ce personnage est déjà membre de ce groupe.',
            },
          },
        );
        final repository = SupabaseGroupRepository(client);

        await expectLater(
          repository.joinGroup(code: 'AB3F7K2M', characterId: 'char-1'),
          throwsA(
            isA<GroupInviteFailure>().having(
              (f) => f.kind,
              'kind',
              GroupInviteFailureKind.alreadyInGroup,
            ),
          ),
        );
      },
    );

    test('exception réseau (pas de réponse reçue) -> generic', () async {
      final client = _buildFakeClient(throwOnRequest: true);
      final repository = SupabaseGroupRepository(client);

      await expectLater(
        repository.joinGroup(code: 'AB3F7K2M', characterId: 'char-1'),
        throwsA(
          isA<GroupInviteFailure>().having(
            (f) => f.kind,
            'kind',
            GroupInviteFailureKind.generic,
          ),
        ),
      );
    });
  });

  group('SupabaseGroupRepository.claimTreasureCurrency', () {
    const groupId = 'group-1';
    const characterId = 'char-1';
    const ownerId = 'owner-1';

    test(
      'appelle la RPC avec p_character_id et retourne true (le crédit '
      'personnel est fait côté serveur, dans le même appel atomique)',
      () async {
        final requests = <http.Request>[];
        final client = await _buildSignedInFakeClient(
          ownerId: ownerId,
          onRequest: requests.add,
          rpcResults: {'claim_group_treasure_currency': true},
        );
        final repository = SupabaseGroupRepository(client);

        final claimed = await repository.claimTreasureCurrency(
          groupId: groupId,
          characterId: characterId,
          currency: CurrencyKind.gold,
          amount: 10,
        );

        expect(claimed, isTrue);
        final rpcRequest = requests.firstWhere(
          (request) =>
              request.url.path.endsWith('/rpc/claim_group_treasure_currency'),
        );
        final rpcBody = jsonDecode(rpcRequest.body) as Map<String, dynamic>;
        expect(rpcBody, {
          'p_group_id': groupId,
          'p_character_id': characterId,
          'p_currency': 'gp',
          'p_amount': 10,
        });

        // Plus aucun second appel séparé vers `characters` : la RPC crédite
        // désormais l'inventaire personnel elle-même, dans le même appel
        // atomique que la décrémentation du butin.
        expect(
          requests.any(
            (request) => request.url.path.endsWith('/characters'),
          ),
          isFalse,
        );
      },
    );

    test('rpc false (solde insuffisant/pas membre) -> retourne false sans '
        'créditer', () async {
      final requests = <http.Request>[];
      final client = await _buildSignedInFakeClient(
        ownerId: ownerId,
        onRequest: requests.add,
        rpcResults: {'claim_group_treasure_currency': false},
      );
      final repository = SupabaseGroupRepository(client);

      final claimed = await repository.claimTreasureCurrency(
        groupId: groupId,
        characterId: characterId,
        currency: CurrencyKind.gold,
        amount: 10,
      );

      expect(claimed, isFalse);
      expect(
        requests.any(
          (request) =>
              request.url.path.endsWith('/characters') &&
              request.method == 'PATCH',
        ),
        isFalse,
        reason: 'aucune écriture personnelle si la réclamation RPC échoue',
      );
    });
  });

  group('SupabaseGroupRepository.claimTreasureItem', () {
    const groupId = 'group-1';
    const characterId = 'char-1';

    test('quantité partielle réclamée : décrémente items sans retirer '
        "l'entrée, insère dans l'inventaire personnel", () async {
      final requests = <http.Request>[];
      final client = _buildFakeClient(
        onRequest: requests.add,
        responses: {
          'group_treasure': [
            {
              'items': [
                {'item_id': 7, 'display_name': 'Potion', 'quantity': 5},
              ],
            },
          ],
        },
      );
      final repository = SupabaseGroupRepository(client);

      await repository.claimTreasureItem(
        groupId: groupId,
        characterId: characterId,
        item: const GroupTreasureItem(
          itemId: 7,
          displayName: 'Potion',
          quantity: 5,
        ),
        quantity: 2,
      );

      final updateRequest = requests.firstWhere(
        (request) =>
            request.url.path.endsWith('/group_treasure') &&
            request.method == 'PATCH',
      );
      final updateBody = jsonDecode(updateRequest.body) as Map<String, dynamic>;
      expect(updateBody['items'], [
        {'item_id': 7, 'display_name': 'Potion', 'quantity': 3},
      ]);

      final insertRequest = requests.firstWhere(
        (request) =>
            request.url.path.endsWith('/character_inventory') &&
            request.method == 'POST',
      );
      final insertBody = jsonDecode(insertRequest.body) as Map<String, dynamic>;
      expect(insertBody, {
        'character_id': characterId,
        'item_id': 7,
        'quantity': 2,
      });
    });

    test('quantité totale réclamée : retire complètement l\'entrée', () async {
      final requests = <http.Request>[];
      final client = _buildFakeClient(
        onRequest: requests.add,
        responses: {
          'group_treasure': [
            {
              'items': [
                {'item_id': 7, 'display_name': 'Potion', 'quantity': 2},
              ],
            },
          ],
        },
      );
      final repository = SupabaseGroupRepository(client);

      await repository.claimTreasureItem(
        groupId: groupId,
        characterId: characterId,
        item: const GroupTreasureItem(
          itemId: 7,
          displayName: 'Potion',
          quantity: 2,
        ),
        quantity: 2,
      );

      final updateRequest = requests.firstWhere(
        (request) =>
            request.url.path.endsWith('/group_treasure') &&
            request.method == 'PATCH',
      );
      final updateBody = jsonDecode(updateRequest.body) as Map<String, dynamic>;
      expect(updateBody['items'], isEmpty);
    });

    test(
      "entrée déjà retirée entretemps (course perdue) : n'écrit rien",
      () async {
        final requests = <http.Request>[];
        final client = _buildFakeClient(
          onRequest: requests.add,
          responses: {
            'group_treasure': [
              {'items': <Map<String, dynamic>>[]},
            ],
          },
        );
        final repository = SupabaseGroupRepository(client);

        await repository.claimTreasureItem(
          groupId: groupId,
          characterId: characterId,
          item: const GroupTreasureItem(
            itemId: 7,
            displayName: 'Potion',
            quantity: 2,
          ),
          quantity: 1,
        );

        expect(
          requests.any(
            (request) => request.method == 'PATCH' || request.method == 'POST',
          ),
          isFalse,
        );
      },
    );
  });
}

/// Fabrique un `SupabaseClient` réel dont le transport HTTP est fabriqué de
/// toutes pièces — [responses] associe un segment de chemin final (nom de
/// table ou d'edge function) à la réponse JSON déjà décodée à renvoyer :
/// une `List`/`Map` telle quelle (une table), directement encodée sans
/// enveloppe supplémentaire — même principe que
/// `character_repository_test.dart::_buildSignedInFakeSupabaseClient`, mais
/// sans authentification (les 3 edge functions et `claimTreasureItem` ne
/// lisent jamais `auth.currentUser`).
SupabaseClient _buildFakeClient({
  Map<String, dynamic> responses = const {},
  int statusCode = 200,
  bool throwOnRequest = false,
  void Function(http.Request request)? onRequest,
}) {
  Future<http.Response> handler(http.Request request) async {
    onRequest?.call(request);
    if (throwOnRequest) {
      throw const SocketException('Pas de réseau (double de test).');
    }
    final key = request.url.pathSegments.last;
    final body = responses[key] ?? const <dynamic>[];
    return http.Response(
      jsonEncode(body),
      statusCode,
      request: request,
      headers: {'content-type': 'application/json'},
    );
  }

  return SupabaseClient(
    'https://fake.supabase.test',
    'fake-anon-key',
    httpClient: MockClient(handler),
    postgrestOptions: const PostgrestClientOptions(retryEnabled: false),
    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
  );
}

/// Variante authentifiée de [_buildFakeClient] — voir
/// `character_repository_test.dart::_buildSignedInFakeSupabaseClient` pour
/// le rationale complet du jeton non-JWT (`recoverSession` reste
/// entièrement en mémoire, jamais un vrai appel réseau). [rpcResults]
/// associe le nom d'une fonction Postgres à sa valeur de retour scalaire
/// brute (`true`/`false` pour `claim_group_treasure_currency`, jamais
/// enveloppée dans une liste, contrairement à une table) — PostgREST
/// renvoie la valeur de retour d'une fonction RPC telle quelle, pas comme
/// une ligne de table.
Future<SupabaseClient> _buildSignedInFakeClient({
  required String ownerId,
  Map<String, List<Map<String, dynamic>>> tableRows = const {},
  Map<String, dynamic> rpcResults = const {},
  void Function(http.Request request)? onRequest,
}) async {
  Future<http.Response> handler(http.Request request) async {
    onRequest?.call(request);
    final key = request.url.pathSegments.last;
    if (rpcResults.containsKey(key)) {
      return http.Response(
        jsonEncode(rpcResults[key]),
        200,
        request: request,
        headers: {'content-type': 'application/json'},
      );
    }
    final rows = tableRows[key] ?? const <Map<String, dynamic>>[];
    return http.Response(
      jsonEncode(rows),
      200,
      request: request,
      headers: {'content-type': 'application/json'},
    );
  }

  final client = SupabaseClient(
    'https://fake.supabase.test',
    'fake-anon-key',
    httpClient: MockClient(handler),
    postgrestOptions: const PostgrestClientOptions(retryEnabled: false),
    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
  );

  await client.auth.recoverSession(
    jsonEncode({
      'access_token': 'fake-access-token-$ownerId',
      'token_type': 'bearer',
      'user': {'id': ownerId},
    }),
  );

  return client;
}
