// `SupabaseAccountLocaleRepository` : seule la clé `locale` part vers GoTrue
// (qui fusionne `data` dans `user_metadata`), jamais la copie locale entière,
// qui peut être périmée (nom ou avatar changés depuis l'app web).

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:personnages/features/profile/data/account_locale_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'writeLocale envoie seulement {locale} ; la session locale suit',
    () async {
      final sent = <Map<String, dynamic>>[];
      final client = SupabaseClient(
        'https://fake.supabase.test',
        'fake-anon-key',
        httpClient: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          sent.add(body);
          final data = body['data'] as Map<String, dynamic>? ?? const {};
          return http.Response(
            jsonEncode({
              'id': 'user-1',
              'aud': 'authenticated',
              'app_metadata': <String, dynamic>{},
              // GoTrue renvoie la fusion côté serveur.
              'user_metadata': {
                'full_name': 'Nom changé ailleurs',
                'onboarding_completed': true,
                ...data,
              },
              'created_at': '2026-01-01T00:00:00Z',
            }),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
        authOptions: const AuthClientOptions(
          authFlowType: AuthFlowType.implicit,
        ),
      );
      addTearDown(client.dispose);
      await client.auth.recoverSession(
        jsonEncode({
          'access_token': 'jeton',
          'token_type': 'bearer',
          'user': {
            'id': 'user-1',
            'aud': 'authenticated',
            'app_metadata': <String, dynamic>{},
            // Copie locale périmée : un ancien nom.
            'user_metadata': {'full_name': 'Ancien nom', 'locale': 'fr'},
            'created_at': '2026-01-01T00:00:00Z',
          },
        }),
      );
      final repository = SupabaseAccountLocaleRepository(client);
      expect(repository.hasAccount, isTrue);
      expect(repository.currentLocale(), 'fr');

      await repository.writeLocale('en');

      expect(sent, hasLength(1));
      expect(sent.single['data'], {'locale': 'en'});
      expect(repository.currentLocale(), 'en');
      expect(
        client.auth.currentUser!.userMetadata!['full_name'],
        'Nom changé ailleurs',
      );
    },
  );
}
