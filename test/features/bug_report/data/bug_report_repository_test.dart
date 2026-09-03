// Tests de `SupabaseBugReportRepository.submitReport` — même stratégie de
// double que `test/features/characters/data/character_repository_test.dart`
// (`SupabaseClient` réel, transport HTTP entièrement fabriqué via
// `MockClient`, voir `_buildFakeSupabaseClient` en bas de ce fichier) :
// corps de requête envoyé à `functions.invoke('report-bug', ...)`, et
// mapping des réponses/erreurs (`status: "synced"`/`"failed"` tous deux
// traités comme un succès, tout code HTTP non-2xx ou exception réseau comme
// un échec).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:personnages/features/bug_report/data/bug_report_error_mapper.dart';
import 'package:personnages/features/bug_report/data/bug_report_repository.dart';
import 'package:personnages/features/bug_report/domain/bug_report_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'Nexus JDR — Personnages',
      packageName: 'app.nexusjdr.personnages',
      version: '1.2.3',
      buildNumber: '42',
      buildSignature: '',
    );
  });

  group('SupabaseBugReportRepository.submitReport', () {
    test('envoie le corps attendu (title/description/severity/appVersion/'
        'platform), sans `characterId` quand non fourni', () async {
      http.Request? capturedRequest;
      final client = _buildFakeSupabaseClient(
        onRequest: (request) => capturedRequest = request,
        responseBody: {'id': 'report-1', 'status': 'synced'},
      );
      final repository = SupabaseBugReportRepository(client);

      await repository.submitReport(
        title: 'Le bouton PV ne répond pas',
        description: 'Rien ne se passe au tap.',
        severity: 'mineur',
      );

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.url.path, endsWith('/functions/v1/report-bug'));
      final body = jsonDecode(capturedRequest!.body) as Map<String, dynamic>;
      expect(body['title'], 'Le bouton PV ne répond pas');
      expect(body['description'], 'Rien ne se passe au tap.');
      expect(body['severity'], 'mineur');
      expect(body['appVersion'], '1.2.3');
      expect(body['platform'], isA<String>());
      expect(body.containsKey('characterId'), isFalse);
    });

    test('inclut `characterId` dans le corps quand fourni', () async {
      http.Request? capturedRequest;
      final client = _buildFakeSupabaseClient(
        onRequest: (request) => capturedRequest = request,
        responseBody: {'id': 'report-1', 'status': 'synced'},
      );
      final repository = SupabaseBugReportRepository(client);

      await repository.submitReport(
        title: 'Titre',
        description: 'Description',
        severity: 'bloquant',
        characterId: 'char-42',
      );

      final body = jsonDecode(capturedRequest!.body) as Map<String, dynamic>;
      expect(body['characterId'], 'char-42');
    });

    test(
      '200 avec `status: "synced"` -> retourne normalement (succès)',
      () async {
        final client = _buildFakeSupabaseClient(
          responseBody: {'id': 'report-1', 'status': 'synced'},
        );
        final repository = SupabaseBugReportRepository(client);

        await expectLater(
          repository.submitReport(
            title: 'Titre',
            description: 'Description',
            severity: 'mineur',
          ),
          completes,
        );
      },
    );

    test('200 avec `status: "failed"` -> retourne normalement aussi (succès '
        'utilisateur malgré un échec de synchro GitHub transparent côté '
        'serveur)', () async {
      final client = _buildFakeSupabaseClient(
        responseBody: {'id': 'report-1', 'status': 'failed'},
      );
      final repository = SupabaseBugReportRepository(client);

      await expectLater(
        repository.submitReport(
          title: 'Titre',
          description: 'Description',
          severity: 'majeur',
        ),
        completes,
      );
    });

    test('400 invalid_body -> lève une BugReportFailure', () async {
      final client = _buildFakeSupabaseClient(
        statusCode: 400,
        responseBody: {
          'error': 'invalid_body',
          'message': 'Le titre est requis.',
        },
      );
      final repository = SupabaseBugReportRepository(client);

      await expectLater(
        repository.submitReport(
          title: 'Titre',
          description: 'Description',
          severity: 'mineur',
        ),
        throwsA(
          isA<BugReportFailure>().having(
            (f) => f.message,
            'message',
            'Le titre est requis.',
          ),
        ),
      );
    });

    test('401 unauthorized -> lève une BugReportFailure', () async {
      final client = _buildFakeSupabaseClient(
        statusCode: 401,
        responseBody: {'error': 'unauthorized', 'message': 'Non connecté.'},
      );
      final repository = SupabaseBugReportRepository(client);

      await expectLater(
        repository.submitReport(
          title: 'Titre',
          description: 'Description',
          severity: 'mineur',
        ),
        throwsA(isA<BugReportFailure>()),
      );
    });

    test('500 internal_error -> lève une BugReportFailure', () async {
      final client = _buildFakeSupabaseClient(
        statusCode: 500,
        responseBody: {'error': 'internal_error'},
      );
      final repository = SupabaseBugReportRepository(client);

      await expectLater(
        repository.submitReport(
          title: 'Titre',
          description: 'Description',
          severity: 'mineur',
        ),
        throwsA(
          isA<BugReportFailure>().having(
            (f) => f.message,
            'message',
            genericBugReportErrorMessage,
          ),
        ),
      );
    });

    test('exception réseau (pas de réponse reçue) -> lève une BugReportFailure '
        'générique', () async {
      final client = _buildFakeSupabaseClient(throwOnRequest: true);
      final repository = SupabaseBugReportRepository(client);

      await expectLater(
        repository.submitReport(
          title: 'Titre',
          description: 'Description',
          severity: 'mineur',
        ),
        throwsA(
          isA<BugReportFailure>().having(
            (f) => f.message,
            'message',
            genericBugReportErrorMessage,
          ),
        ),
      );
    });
  });
}

/// Fabrique un `SupabaseClient` réel dont le transport HTTP est entièrement
/// fabriqué (`MockClient`) — même principe que
/// `character_repository_test.dart::_buildSignedInFakeSupabaseClient`, mais
/// sans authentification en mémoire : `SupabaseBugReportRepository` ne lit
/// jamais `auth.currentUser` (l'edge function `report-bug` s'appuie sur le
/// jeton déjà géré automatiquement par `functions.invoke`, pas sur une
/// vérification cliente).
SupabaseClient _buildFakeSupabaseClient({
  void Function(http.Request request)? onRequest,
  Map<String, dynamic> responseBody = const {},
  int statusCode = 200,
  bool throwOnRequest = false,
}) {
  Future<http.Response> handler(http.Request request) async {
    onRequest?.call(request);
    if (throwOnRequest) {
      throw const SocketException('Pas de réseau (double de test).');
    }
    return http.Response(
      jsonEncode(responseBody),
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
