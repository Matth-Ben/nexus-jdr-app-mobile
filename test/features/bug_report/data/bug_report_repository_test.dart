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
import 'dart:typed_data';

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
      final client = await _buildFakeSupabaseClient(
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
      final client = await _buildFakeSupabaseClient(
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
        final client = await _buildFakeSupabaseClient(
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
      final client = await _buildFakeSupabaseClient(
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
      final client = await _buildFakeSupabaseClient(
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
      final client = await _buildFakeSupabaseClient(
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
      final client = await _buildFakeSupabaseClient(
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
      final client = await _buildFakeSupabaseClient(throwOnRequest: true);
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

    group('avec une capture d\'écran', () {
      const userId = 'AB12CD34-0000-4000-8000-00000000ABCD';
      const fileId = '3f2a9c1e-7b4d-4e8f-9a01-23456789abcd';
      final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3]);

      test('téléverse d\'abord dans `bug-report-screenshots` au chemin '
          '`<uid minuscule>/<uuid>.jpg` en image/jpeg sans upsert, puis '
          'transmet ce même chemin à `report-bug`', () async {
        final requests = <http.Request>[];
        final client = await _buildFakeSupabaseClient(
          userId: userId,
          onRequest: requests.add,
          responseBody: {'id': 'report-1', 'status': 'synced'},
        );
        final repository = SupabaseBugReportRepository(
          client,
          generateId: () => fileId,
        );

        await repository.submitReport(
          title: 'Titre',
          description: 'Description',
          severity: 'contenu',
          screenshotJpeg: jpeg,
        );

        expect(requests, hasLength(2));
        final upload = requests.first;
        expect(upload.method, 'POST');
        expect(
          upload.url.path,
          '/storage/v1/object/bug-report-screenshots/'
          '${userId.toLowerCase()}/$fileId.jpg',
        );
        expect(upload.headers['x-upsert'], 'false');
        expect(latin1.decode(upload.bodyBytes), contains('image/jpeg'));

        final invoke = requests.last;
        expect(invoke.url.path, endsWith('/functions/v1/report-bug'));
        final body = jsonDecode(invoke.body) as Map<String, dynamic>;
        expect(body['severity'], 'contenu');
        expect(
          body['screenshotPath'],
          'ab12cd34-0000-4000-8000-00000000abcd/$fileId.jpg',
        );
      });

      test(
        'sans capture : aucune requête Storage, pas de `screenshotPath`',
        () async {
          final requests = <http.Request>[];
          final client = await _buildFakeSupabaseClient(
            userId: userId,
            onRequest: requests.add,
            responseBody: {'id': 'report-1', 'status': 'synced'},
          );

          await SupabaseBugReportRepository(client).submitReport(
            title: 'Titre',
            description: 'Description',
            severity: 'mineur',
          );

          expect(requests, hasLength(1));
          final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
          expect(body.containsKey('screenshotPath'), isFalse);
        },
      );

      test('échec du téléversement -> BugReportFailure screenshotUpload, '
          '`report-bug` jamais appelé', () async {
        final requests = <http.Request>[];
        final client = await _buildFakeSupabaseClient(
          userId: userId,
          onRequest: requests.add,
          storageStatusCode: 403,
        );

        await expectLater(
          SupabaseBugReportRepository(
            client,
            generateId: () => fileId,
          ).submitReport(
            title: 'Titre',
            description: 'Description',
            severity: 'mineur',
            screenshotJpeg: jpeg,
          ),
          throwsA(
            isA<BugReportFailure>().having(
              (f) => f.kind,
              'kind',
              BugReportFailureKind.screenshotUpload,
            ),
          ),
        );
        expect(
          requests.where((r) => r.url.path.contains('/functions/')),
          isEmpty,
        );
      });

      test(
        'exception réseau pendant le téléversement -> screenshotUpload',
        () async {
          final client = await _buildFakeSupabaseClient(
            userId: userId,
            throwOnRequest: true,
          );

          await expectLater(
            SupabaseBugReportRepository(client).submitReport(
              title: 'Titre',
              description: 'Description',
              severity: 'mineur',
              screenshotJpeg: jpeg,
            ),
            throwsA(
              isA<BugReportFailure>().having(
                (f) => f.kind,
                'kind',
                BugReportFailureKind.screenshotUpload,
              ),
            ),
          );
        },
      );

      test(
        '400 screenshot_not_found -> BugReportFailure screenshotUpload',
        () async {
          final client = await _buildFakeSupabaseClient(
            userId: userId,
            statusCode: 400,
            responseBody: {
              'error': 'screenshot_not_found',
              'message': 'Capture introuvable.',
            },
          );

          await expectLater(
            SupabaseBugReportRepository(client).submitReport(
              title: 'Titre',
              description: 'Description',
              severity: 'mineur',
              screenshotJpeg: jpeg,
            ),
            throwsA(
              isA<BugReportFailure>().having(
                (f) => f.kind,
                'kind',
                BugReportFailureKind.screenshotUpload,
              ),
            ),
          );
        },
      );

      test(
        '400 invalid_body (chemin refusé) -> BugReportFailure generic',
        () async {
          final client = await _buildFakeSupabaseClient(
            userId: userId,
            statusCode: 400,
            responseBody: {
              'error': 'invalid_body',
              'message': 'Chemin invalide.',
            },
          );

          await expectLater(
            SupabaseBugReportRepository(client).submitReport(
              title: 'Titre',
              description: 'Description',
              severity: 'mineur',
              screenshotJpeg: jpeg,
            ),
            throwsA(
              isA<BugReportFailure>().having(
                (f) => f.kind,
                'kind',
                BugReportFailureKind.generic,
              ),
            ),
          );
        },
      );

      test(
        'aucune session -> BugReportFailure generic, aucune requête',
        () async {
          final requests = <http.Request>[];
          final client = await _buildFakeSupabaseClient(
            onRequest: requests.add,
          );

          await expectLater(
            SupabaseBugReportRepository(client).submitReport(
              title: 'Titre',
              description: 'Description',
              severity: 'mineur',
              screenshotJpeg: jpeg,
            ),
            throwsA(
              isA<BugReportFailure>().having(
                (f) => f.kind,
                'kind',
                BugReportFailureKind.generic,
              ),
            ),
          );
          expect(requests, isEmpty);
        },
      );
    });
  });
}

/// Fabrique un `SupabaseClient` réel dont le transport HTTP est entièrement
/// fabriqué (`MockClient`) — même principe que
/// `character_repository_test.dart::_buildSignedInFakeSupabaseClient`.
/// Authentifié en mémoire (`recoverSession`, sans requête réseau) seulement
/// si [userId] est fourni : le téléversement de la capture lit
/// `auth.currentUser`, contrairement à l'appel `report-bug` seul.
///
/// Les requêtes Storage (`/storage/v1/...`) reçoivent [storageStatusCode] ;
/// toutes les autres (`/functions/v1/report-bug`) [statusCode]/[responseBody].
Future<SupabaseClient> _buildFakeSupabaseClient({
  void Function(http.Request request)? onRequest,
  Map<String, dynamic> responseBody = const {},
  int statusCode = 200,
  int storageStatusCode = 200,
  bool throwOnRequest = false,
  String? userId,
}) async {
  Future<http.Response> handler(http.Request request) async {
    onRequest?.call(request);
    if (throwOnRequest) {
      throw const SocketException('Pas de réseau (double de test).');
    }
    if (request.url.path.contains('/storage/v1/')) {
      final ok = storageStatusCode < 300;
      return http.Response(
        jsonEncode(
          ok
              ? {'Key': request.url.path, 'Id': 'object-1'}
              : {
                  'statusCode': '$storageStatusCode',
                  'error': 'Unauthorized',
                  'message': 'new row violates row-level security policy',
                },
        ),
        storageStatusCode,
        request: request,
        headers: {'content-type': 'application/json'},
      );
    }
    return http.Response(
      jsonEncode(responseBody),
      statusCode,
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
  if (userId != null) {
    await client.auth.recoverSession(
      jsonEncode({
        'access_token': 'fake-access-token-$userId',
        'token_type': 'bearer',
        'user': {'id': userId},
      }),
    );
  }
  return client;
}
