import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/data/portrait_url_fetcher.dart';

/// 1x1 PNG transparent valide (le plus petit fichier PNG décodable qui
/// existe) — utilisé pour vérifier que [fetchPortraitBytesFromUrl] accepte
/// bien une vraie image plutôt que de se fier au seul code 200.
final Uint8List _validPngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42Yb'
  'AAAAAElFTkSuQmCC',
);

/// Sert de faux serveur HTTP local pour tester `dart:io HttpClient` (pas de
/// dépendance `package:http` à mocker ici, voir le commentaire de classe de
/// `data/portrait_url_fetcher.dart`) sans dépendre d'un vrai réseau/URL
/// externe — ce test doit rester déterministe et hors-ligne.
void main() {
  late HttpServer server;
  late String baseUrl;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    baseUrl = 'http://${server.address.address}:${server.port}';
    unawaited(
      server.forEach((request) async {
        switch (request.uri.path) {
          case '/valid.png':
            request.response.headers.contentType = ContentType('image', 'png');
            request.response.add(_validPngBytes);
          case '/not-an-image':
            request.response.headers.contentType = ContentType.html;
            request.response.write('<html>pas une image</html>');
          case '/not-found':
            request.response.statusCode = HttpStatus.notFound;
          default:
            request.response.statusCode = HttpStatus.notFound;
        }
        await request.response.close();
      }),
    );
  });

  tearDown(() async {
    await server.close(force: true);
  });

  group('fetchPortraitBytesFromUrl', () {
    test('télécharge et retourne les octets d\'une vraie image PNG (200 + '
        'contenu décodable)', () async {
      final bytes = await fetchPortraitBytesFromUrl('$baseUrl/valid.png');
      expect(bytes, _validPngBytes);
    });

    test('rejette une réponse 200 dont le contenu n\'est pas une image '
        'décodable (ex. une page HTML) plutôt que de planter plus tard sur '
        'l\'écran de recadrage', () async {
      await expectLater(
        fetchPortraitBytesFromUrl('$baseUrl/not-an-image'),
        throwsA(
          isA<PortraitUrlFetchFailure>().having(
            (failure) => failure.message,
            'message',
            contains('image valide'),
          ),
        ),
      );
    });

    test(
      'rejette un code de statut non 200 avec le code dans le message',
      () async {
        await expectLater(
          fetchPortraitBytesFromUrl('$baseUrl/not-found'),
          throwsA(
            isA<PortraitUrlFetchFailure>().having(
              (failure) => failure.message,
              'message',
              contains('404'),
            ),
          ),
        );
      },
    );

    test(
      'rejette une URL sans schéma/autorité sans tenter de requête',
      () async {
        await expectLater(
          fetchPortraitBytesFromUrl('pas-une-url'),
          throwsA(isA<PortraitUrlFetchFailure>()),
        );
      },
    );

    test('rejette une chaîne vide (champ non saisi)', () async {
      await expectLater(
        fetchPortraitBytesFromUrl('   '),
        throwsA(isA<PortraitUrlFetchFailure>()),
      );
    });
  });
}
