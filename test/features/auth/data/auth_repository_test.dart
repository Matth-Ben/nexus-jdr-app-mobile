// Tests de `SupabaseAuthRepository` contre un vrai `SupabaseClient`/
// `GoTrueClient` (voir la stratégie de double ci-dessous) : couvre les 4
// méthodes du dépôt (`resetPasswordForEmail`, `signInWithPassword`, `signUp`,
// `signOut`), en particulier le chemin `AuthRetryableFetchException` (échec
// réseau avant réponse HTTP, voir `auth_error_mapper.dart`) sur chacune —
// avant ces tests, seule `resetPasswordForEmail` était exercée ici, les 3
// autres n'étaient couvertes qu'indirectement via `_FakeAuthRepository` dans
// `test/features/auth/presentation/login_screen_test.dart`, qui ne passe
// jamais par `SupabaseAuthRepository` ni par son mapping d'erreurs réel.
//
// Même stratégie de double que
// `test/features/character_creation/data/character_creation_repository_test.dart`
// (voir la doc de classe de ce fichier pour le rationale détaillé) : un vrai
// `SupabaseClient`/`GoTrueClient` tourne, seule la réponse HTTP est fabriquée
// via `package:http/testing.dart` (`MockClient`), au lieu de mocker
// `SupabaseClient` lui-même (classe concrète, pas une interface).
//
// `authFlowType: AuthFlowType.implicit` (plutôt que le `pkce` par défaut)
// évite que `GoTrueClient._generatePKCECodeChallenge` réclame un
// `GotrueAsyncStorage` (typiquement `shared_preferences`, indisponible dans
// un test VM pur) : sous flux implicite, cette méthode renvoie `null`
// immédiatement sans jamais toucher au stockage.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:personnages/features/auth/data/auth_repository.dart';
import 'package:personnages/features/auth/domain/auth_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('SupabaseAuthRepository.resetPasswordForEmail', () {
    test(
      "appelle l'endpoint /recover avec l'e-mail et le redirectTo web attendu",
      () async {
        http.Request? capturedRequest;

        final client = _buildFakeSupabaseClient((request) async {
          capturedRequest = request;
          return http.Response('{}', 200, request: request);
        });

        await SupabaseAuthRepository(
          client,
        ).resetPasswordForEmail(email: 'joueur@exemple.com');

        expect(capturedRequest, isNotNull);
        expect(capturedRequest!.url.path, endsWith('/recover'));
        expect(
          capturedRequest!.url.queryParameters['redirect_to'],
          'https://nexus-jdr.app/update-password',
        );
        final body =
            jsonDecode(capturedRequest!.body) as Map<String, dynamic>;
        expect(body['email'], 'joueur@exemple.com');
      },
    );

    test(
      'traduit une AuthException (ex. rate limit) en AuthFailure, même '
      'gestion que les autres méthodes du dépôt',
      () async {
        final client = _buildFakeSupabaseClient((request) async {
          return http.Response(
            jsonEncode({
              'error_code': 'over_email_send_rate_limit',
              'msg': 'Email rate limit exceeded',
            }),
            429,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        });

        await expectLater(
          SupabaseAuthRepository(
            client,
          ).resetPasswordForEmail(email: 'joueur@exemple.com'),
          throwsA(isA<AuthFailure>()),
        );
      },
    );

    test(
      "remonte un message réseau générique quand l'appel échoue sans "
      'réponse HTTP (ex. absence de réseau) — le SDK enveloppe déjà ce cas '
      'dans une `AuthRetryableFetchException` (`AuthException`), traitée '
      'par `mapAuthException` (voir `auth_error_mapper_test.dart`), jamais '
      "par le `catch` générique de ce dépôt (`mapUnknownError` n'est donc "
      'pas atteint directement ici, seulement via le message identique '
      'qu\'il produit)',
      () async {
        final client = _buildFakeSupabaseClient((request) async {
          throw Exception('Pas de réseau (double de test).');
        });

        await expectLater(
          SupabaseAuthRepository(
            client,
          ).resetPasswordForEmail(email: 'joueur@exemple.com'),
          throwsA(
            isA<AuthFailure>().having(
              (failure) => failure.message,
              'message',
              contains('connexion internet'),
            ),
          ),
        );
      },
    );
  });

  group('SupabaseAuthRepository.signInWithPassword', () {
    test(
      "remonte un message réseau générique quand l'appel échoue sans "
      'réponse HTTP (ex. absence de réseau) - même mécanisme '
      '`AuthRetryableFetchException` que `resetPasswordForEmail` ci-dessus, '
      "vérifié ici directement sur `signInWithPassword` plutôt que déduit "
      'par analogie',
      () async {
        final client = _buildFakeSupabaseClient((request) async {
          throw Exception('Pas de réseau (double de test).');
        });

        await expectLater(
          SupabaseAuthRepository(client).signInWithPassword(
            email: 'joueur@exemple.com',
            password: 'password1234',
          ),
          throwsA(
            isA<AuthFailure>().having(
              (failure) => failure.message,
              'message',
              contains('connexion internet'),
            ),
          ),
        );
      },
    );

    test(
      'traduit une AuthException (identifiants invalides) en AuthFailure '
      'avec le message dédié',
      () async {
        final client = _buildFakeSupabaseClient((request) async {
          return http.Response(
            jsonEncode({
              'error_code': 'invalid_credentials',
              'msg': 'Invalid login credentials',
            }),
            400,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        });

        await expectLater(
          SupabaseAuthRepository(client).signInWithPassword(
            email: 'joueur@exemple.com',
            password: 'mauvais-mot-de-passe',
          ),
          throwsA(
            isA<AuthFailure>().having(
              (failure) => failure.message,
              'message',
              'Adresse e-mail ou mot de passe incorrect.',
            ),
          ),
        );
      },
    );
  });

  group('SupabaseAuthRepository.signUp', () {
    test(
      "remonte un message réseau générique quand l'appel échoue sans "
      'réponse HTTP (ex. absence de réseau) - même mécanisme '
      '`AuthRetryableFetchException` que `resetPasswordForEmail` ci-dessus, '
      "vérifié ici directement sur `signUp` plutôt que déduit par analogie",
      () async {
        final client = _buildFakeSupabaseClient((request) async {
          throw Exception('Pas de réseau (double de test).');
        });

        await expectLater(
          SupabaseAuthRepository(client).signUp(
            email: 'nouveau@exemple.com',
            password: 'password1234',
          ),
          throwsA(
            isA<AuthFailure>().having(
              (failure) => failure.message,
              'message',
              contains('connexion internet'),
            ),
          ),
        );
      },
    );
  });

  group('SupabaseAuthRepository.signOut', () {
    test(
      "remonte un message réseau générique quand l'appel échoue sans "
      'réponse HTTP (ex. absence de réseau) - même mécanisme '
      '`AuthRetryableFetchException` que `resetPasswordForEmail` ci-dessus, '
      "vérifié ici directement sur `signOut` plutôt que déduit par analogie. "
      'Nécessite une session active au préalable : '
      '`GoTrueClient._signOut` ne contacte `/logout` que si un '
      '`accessToken` courant existe (session absente -> retour silencieux, '
      'aucun appel réseau, voir `package:gotrue/src/gotrue_client.dart`) — '
      'sans session active, ce test ne prouverait donc rien sur le '
      'traitement réel de `AuthRetryableFetchException` par `signOut`.',
      () async {
        final client = _buildFakeSupabaseClient((request) async {
          if (request.url.path.endsWith('/token')) {
            return http.Response(
              jsonEncode(_fakeSessionJson()),
              200,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path.endsWith('/logout')) {
            throw Exception('Pas de réseau (double de test).');
          }
          return http.Response('{}', 200, request: request);
        });

        await client.auth.signInWithPassword(
          email: 'joueur@exemple.com',
          password: 'password1234',
        );
        expect(client.auth.currentSession, isNotNull);

        await expectLater(
          SupabaseAuthRepository(client).signOut(),
          throwsA(
            isA<AuthFailure>().having(
              (failure) => failure.message,
              'message',
              contains('connexion internet'),
            ),
          ),
        );
      },
    );
  });
}

/// JSON minimal d'une session GoTrue valide (`access_token`/`user.id`
/// requis par `Session.fromJson`/`User.fromJson`, voir
/// `package:gotrue/src/types/session.dart` et `.../types/user.dart`) - sert
/// uniquement à établir une session active dans le test `signOut` ci-dessus
/// (le contenu exact des autres champs n'a pas d'importance ici).
Map<String, dynamic> _fakeSessionJson() {
  return {
    'access_token': 'fake-access-token',
    'token_type': 'bearer',
    'expires_in': 3600,
    'refresh_token': 'fake-refresh-token',
    'user': {
      'id': 'fake-user-id',
      'aud': 'authenticated',
      'app_metadata': <String, dynamic>{},
      'created_at': '2026-01-01T00:00:00Z',
    },
  };
}

SupabaseClient _buildFakeSupabaseClient(
  Future<http.Response> Function(http.Request request) handler,
) {
  return SupabaseClient(
    'https://fake.supabase.test',
    'fake-anon-key',
    httpClient: MockClient(handler),
    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
  );
}
