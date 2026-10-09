import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:personnages/core/network/timeout_http_client.dart';

/// Couvre [TimeoutHttpClient] (dette D12 du registre `docs/dette-technique.md`)
/// avec un délai injecté très court plutôt que les 15 secondes réelles de
/// production — voir la doc de classe de [TimeoutHttpClient] pour le
/// rationale du choix (délai global plutôt que `.timeout(...)` dispersé).
void main() {
  group('TimeoutHttpClient', () {
    test(
      "délègue normalement à l'inner client une requête qui répond avant "
      'le délai',
      () async {
        final inner = MockClient(
          (request) async => http.Response('ok', 200),
        );
        final client = TimeoutHttpClient(
          inner: inner,
          timeout: const Duration(milliseconds: 100),
        );

        final response = await client.get(Uri.parse('https://exemple.test'));

        expect(response.statusCode, 200);
        expect(response.body, 'ok');
      },
    );

    test(
      'lève une TimeoutException quand la requête dépasse le délai '
      '(scénario D12 : interface réseau active mais requête qui ne '
      "n'aboutit jamais)",
      () async {
        final inner = MockClient((request) async {
          // Simule un Wi-Fi sans débit réel : la requête ne répond jamais
          // avant que le test ne l'abandonne lui-même.
          await Future<void>.delayed(const Duration(seconds: 5));
          return http.Response('trop tard', 200);
        });
        final client = TimeoutHttpClient(
          inner: inner,
          timeout: const Duration(milliseconds: 20),
        );

        await expectLater(
          client.get(Uri.parse('https://exemple.test')),
          throwsA(isA<TimeoutException>()),
        );
      },
    );

    test('timeout vaut 15 secondes par défaut (valeur imposée, dette D12)', () {
      final client = TimeoutHttpClient();
      expect(client.timeout, const Duration(seconds: 15));
      client.close();
    });

    test('close() ferme bien le client interne', () async {
      var closed = false;
      final inner = _ClosingTrackerClient(onClose: () => closed = true);
      final client = TimeoutHttpClient(inner: inner);

      client.close();

      expect(closed, isTrue);
    });
  });
}

class _ClosingTrackerClient extends http.BaseClient {
  _ClosingTrackerClient({required this.onClose});

  final void Function() onClose;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      throw UnimplementedError('non utilisé par ce test');

  @override
  void close() => onClose();
}
