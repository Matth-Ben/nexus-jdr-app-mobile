// Tests de `SupabaseNotificationPreferencesRepository`
// (`features/profile/data/notification_preferences_repository.dart`) —
// `SupabaseClient` réel, transport HTTP entièrement fabriqué via
// `MockClient`, authentifié en mémoire (sans requête réseau) via
// `GoTrueClient.recoverSession` — même double et même rationale que
// `_buildSignedInFakeSupabaseClient` de
// `test/features/characters/data/character_repository_test.dart` (voir sa
// doc de classe pour le détail du mécanisme `recoverSession`), repris ici en
// version minimale (une seule table, pas de cache local).

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:personnages/features/profile/data/notification_preferences_repository.dart';
import 'package:personnages/features/profile/domain/notification_preferences.dart';
import 'package:personnages/features/profile/domain/profile_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<SupabaseClient> _signedInClient({
  required String ownerId,
  required Future<http.Response> Function(http.Request request) handler,
}) async {
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

// `request:` est requis par `PostgrestBuilder._parseResponse` (sinon
// `Null check operator used on a null value`) — même oubli à éviter que
// `_buildFakeClient` de `pact_weapon_repository_test.dart`, qui le passe
// systématiquement.
http.Response _jsonResponse(
  http.Request request,
  Object body, {
  int status = 200,
}) => http.Response(
  jsonEncode(body),
  status,
  request: request,
  headers: {'content-type': 'application/json'},
);

void main() {
  group('SupabaseNotificationPreferencesRepository.fetch', () {
    test('ligne existante : lit push_new_version_available comme les autres '
        'colonnes', () async {
      final client = await _signedInClient(
        ownerId: 'user-1',
        handler: (request) async => _jsonResponse(request, [
          {
            'push_enabled': true,
            'push_rest_reminder': false,
            'push_access_revoked': true,
            'push_new_version_available': false,
            'email_digest_enabled': true,
          },
        ]),
      );

      final prefs = await SupabaseNotificationPreferencesRepository(client)
          .fetch();

      expect(prefs.pushNewVersionAvailable, isFalse);
      expect(prefs.pushRestReminder, isFalse);
      expect(prefs.pushAccessRevoked, isTrue);
    });

    test('aucune ligne : defaults (pushNewVersionAvailable à true)', () async {
      final client = await _signedInClient(
        ownerId: 'user-1',
        handler: (request) async =>
            _jsonResponse(request, <Map<String, dynamic>>[]),
      );

      final prefs = await SupabaseNotificationPreferencesRepository(client)
          .fetch();

      expect(prefs, const NotificationPreferences.defaults());
      expect(prefs.pushNewVersionAvailable, isTrue);
    });

    test('pas de session : ProfileFailure, aucune requête envoyée', () async {
      var requests = 0;
      final client = SupabaseClient(
        'https://fake.supabase.test',
        'fake-anon-key',
        httpClient: MockClient((request) async {
          requests++;
          return _jsonResponse(request, <Map<String, dynamic>>[]);
        }),
        postgrestOptions: const PostgrestClientOptions(retryEnabled: false),
        authOptions: const AuthClientOptions(
          authFlowType: AuthFlowType.implicit,
        ),
      );

      await expectLater(
        SupabaseNotificationPreferencesRepository(client).fetch(),
        throwsA(isA<ProfileFailure>()),
      );
      expect(requests, 0);
    });
  });

  group('SupabaseNotificationPreferencesRepository.update', () {
    test(
      'pushNewVersionAvailable: false envoie push_new_version_available: '
      'false dans le upsert, fusionné avec le reste de la ligne existante',
      () async {
        http.Request? sent;
        final client = await _signedInClient(
          ownerId: 'user-1',
          handler: (request) async {
            if (request.method == 'GET') {
              return _jsonResponse(request, [
                {
                  'push_enabled': true,
                  'push_rest_reminder': true,
                  'push_access_revoked': true,
                  'push_new_version_available': true,
                  'email_digest_enabled': false,
                },
              ]);
            }
            sent = request;
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            // `.select().single()` attend un objet JSON unique en réponse
            // (en-tête `Accept: application/vnd.pgrst.object+json`), jamais
            // une liste — contrairement à la lecture `.select()` nue du
            // `fetch()` interne à `update()`, routée ci-dessus.
            return _jsonResponse(request, body);
          },
        );

        final updated = await SupabaseNotificationPreferencesRepository(client)
            .update(pushNewVersionAvailable: false);

        expect(updated.pushNewVersionAvailable, isFalse);
        expect(sent, isNotNull);
        final body = jsonDecode(sent!.body) as Map<String, dynamic>;
        expect(body['push_new_version_available'], isFalse);
        // Le reste de la ligne existante est réécrit tel quel (upsert
        // complet, jamais un PATCH partiel) — voir la doc de classe du
        // repository.
        expect(body['push_enabled'], isTrue);
        expect(body['push_rest_reminder'], isTrue);
        expect(body['push_access_revoked'], isTrue);
        expect(body['email_digest_enabled'], isFalse);
      },
    );

    test('aucune ligne existante : upsert depuis les defaults', () async {
      http.Request? sent;
      final client = await _signedInClient(
        ownerId: 'user-1',
        handler: (request) async {
          if (request.method == 'GET') {
            return _jsonResponse(request, <Map<String, dynamic>>[]);
          }
          sent = request;
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          return _jsonResponse(request, body);
        },
      );

      await SupabaseNotificationPreferencesRepository(client)
          .update(pushNewVersionAvailable: false);

      final body = jsonDecode(sent!.body) as Map<String, dynamic>;
      expect(body['push_new_version_available'], isFalse);
      expect(body['push_enabled'], isTrue);
      expect(body['push_rest_reminder'], isTrue);
      expect(body['push_access_revoked'], isTrue);
      expect(body['email_digest_enabled'], isFalse);
    });
  });
}
