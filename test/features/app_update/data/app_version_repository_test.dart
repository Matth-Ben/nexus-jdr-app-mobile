// Tests de `SupabaseAppVersionRepository` — même stratégie de double que
// `test/features/groups/data/group_repository_test.dart`
// (`SupabaseClient` réel, transport HTTP entièrement fabriqué via
// `MockClient`) : requête envoyée à `app_versions` (filtre `platform`) et
// mapping de la réponse.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:personnages/features/app_update/data/app_version_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('SupabaseAppVersionRepository.fetchCurrentPlatformVersion', () {
    test(
      'filtre sur la plateforme courante et mappe minimum/latest/store_url',
      () async {
        http.Request? capturedRequest;
        final client = _buildFakeClient(
          onRequest: (request) => capturedRequest = request,
          row: const {
            'min_supported_version': '0.3.0',
            'latest_version': '0.5.0',
            'store_url': 'https://play.google.com/store/apps/details?id=test',
          },
        );
        final repository = SupabaseAppVersionRepository(client);

        final row = await repository.fetchCurrentPlatformVersion();

        expect(capturedRequest, isNotNull);
        expect(capturedRequest!.url.path, endsWith('/rest/v1/app_versions'));
        expect(
          capturedRequest!.url.queryParameters['platform'],
          // `Platform.isIOS` est `false` sous `flutter test` (exécuté sur
          // hôte desktop) : la requête filtre donc toujours sur `android`
          // dans cet environnement de test, cohérent avec
          // `AppVersionRepository._platformLabel`.
          Platform.isIOS ? 'eq.ios' : 'eq.android',
        );
        expect(row.minimumSupportedVersion, '0.3.0');
        expect(row.latestVersion, '0.5.0');
        expect(
          row.storeUrl,
          'https://play.google.com/store/apps/details?id=test',
        );
      },
    );

    test('store_url absent (null) -> mappé à null, pas d\'exception', () async {
      final client = _buildFakeClient(
        row: const {
          'min_supported_version': '0.1.0',
          'latest_version': '0.1.0',
          'store_url': null,
        },
      );
      final repository = SupabaseAppVersionRepository(client);

      final row = await repository.fetchCurrentPlatformVersion();

      expect(row.storeUrl, isNull);
    });

    test(
      'aucune ligne pour la plateforme -> exception (jamais silencieux)',
      () async {
        final client = _buildFakeClient(row: null);
        final repository = SupabaseAppVersionRepository(client);

        await expectLater(
          repository.fetchCurrentPlatformVersion(),
          throwsA(anything),
        );
      },
    );
  });
}

/// Fabrique un `SupabaseClient` réel dont le transport HTTP est fabriqué de
/// toutes pièces — [row] est la ligne `app_versions` déjà décodée à renvoyer
/// (`null` simule `.maybeSingle()` sans résultat, réponse `[]`), même
/// principe que `group_repository_test.dart::_buildFakeClient`.
SupabaseClient _buildFakeClient({
  Map<String, dynamic>? row,
  void Function(http.Request request)? onRequest,
}) {
  Future<http.Response> handler(http.Request request) async {
    onRequest?.call(request);
    final body = row == null ? const <dynamic>[] : [row];
    return http.Response(
      // postgrest-dart décode `.maybeSingle()` à partir d'une liste JSON
      // standard (peu importe l'en-tête `Accept` envoyé, ignoré par ce
      // transport factice) — même convention que
      // `group_repository_test.dart`.
      jsonEncode(body),
      200,
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
