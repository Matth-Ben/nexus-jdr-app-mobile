import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/notifications/push_token_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/test_environment.dart';

/// Test d'intégration de `SupabasePushTokenRepository` contre un vrai stack
/// Supabase local (voir `test_integration/README.md`) : la table
/// `user_push_tokens` (chantier "Notifications" —
/// `docs/cahier-des-charges/15-profil-parametres.md` section 3) a `token`
/// pour clé primaire — ce fichier vérifie le vrai comportement d'upsert
/// (`onConflict: 'token'`, y compris la réattribution d'un jeton existant à
/// un autre utilisateur — cas réel d'une réinstallation de l'app sous un
/// autre compte) et la vraie policy RLS (CRUD `owner_id = auth.uid()`),
/// jamais exercés par un double factice.
void main() {
  group('SupabasePushTokenRepository (intégration)', () {
    late SupabaseClient client;
    late String ownerId;
    late SupabasePushTokenRepository repository;

    setUpAll(() async {
      client = createTestSupabaseClient();
      await signUpTestUser(client);
      ownerId = client.auth.currentUser!.id;
      repository = SupabasePushTokenRepository(client);
    });

    test('upsertToken crée une ligne (token, user_id, platform)', () async {
      final token = 'fcm-token-${DateTime.now().microsecondsSinceEpoch}';
      addTearDown(() async {
        await client.from('user_push_tokens').delete().eq('token', token);
      });

      await repository.upsertToken(token: token, platform: 'android');

      final row = await client
          .from('user_push_tokens')
          .select('user_id, platform')
          .eq('token', token)
          .single();
      expect(row['user_id'], ownerId);
      expect(row['platform'], 'android');
    });

    test(
      'upsertToken avec un jeton déjà existant réécrit la ligne (onConflict: '
      "'token'), jamais un doublon",
      () async {
        final token = 'fcm-token-${DateTime.now().microsecondsSinceEpoch}';
        addTearDown(() async {
          await client.from('user_push_tokens').delete().eq('token', token);
        });

        await repository.upsertToken(token: token, platform: 'android');
        await repository.upsertToken(token: token, platform: 'android');

        final rows = await client
            .from('user_push_tokens')
            .select('token')
            .eq('token', token);
        expect(rows, hasLength(1));
      },
    );

    group('isolation cross-utilisateur (RLS)', () {
      late SupabaseClient otherClient;

      setUpAll(() async {
        otherClient = createTestSupabaseClient();
        await signUpTestUser(otherClient);
      });

      test("un jeton enregistré par un joueur n'est jamais visible depuis la "
          'session d\'un autre joueur', () async {
        final token = 'fcm-token-${DateTime.now().microsecondsSinceEpoch}';
        addTearDown(() async {
          await client.from('user_push_tokens').delete().eq('token', token);
        });
        await repository.upsertToken(token: token, platform: 'android');

        final rowsFromOtherSession = await otherClient
            .from('user_push_tokens')
            .select('token')
            .eq('token', token);

        expect(rowsFromOtherSession, isEmpty);
      });

      test('réattribution : réinstallation de l\'app sous un autre compte sur '
          'le même appareil réclame bien le jeton existant (RPC '
          'claim_push_token, ex-bug trouvé en QA : un upsert direct échouait '
          'silencieusement sous RLS)', () async {
        final token = 'fcm-token-${DateTime.now().microsecondsSinceEpoch}';
        addTearDown(() async {
          await client.from('user_push_tokens').delete().eq('token', token);
        });

        await repository.upsertToken(token: token, platform: 'android');

        final otherRepository = SupabasePushTokenRepository(otherClient);
        await otherRepository.upsertToken(token: token, platform: 'android');

        final row = await otherClient
            .from('user_push_tokens')
            .select('user_id')
            .eq('token', token)
            .single();
        expect(row['user_id'], otherClient.auth.currentUser!.id);

        final rowsFromFirstSession = await client
            .from('user_push_tokens')
            .select('token')
            .eq('token', token);
        expect(rowsFromFirstSession, isEmpty);
      });
    });
  });
}
