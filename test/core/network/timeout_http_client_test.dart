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

    test(
      'annule réellement la connexion sous-jacente au lieu de se contenter '
      "de lever une exception côté appelant (régression : Future.timeout() "
      "seul ne fait jamais ça — voir la doc de TimeoutHttpClient)",
      () async {
        final inner = _AbortAwareFakeClient();
        final client = TimeoutHttpClient(
          inner: inner,
          timeout: const Duration(milliseconds: 20),
        );

        await expectLater(
          client.get(Uri.parse('https://exemple.test')),
          throwsA(isA<TimeoutException>()),
        );

        // La preuve de la "vraie" annulation : ce n'est pas seulement
        // l'appelant qui a vu une TimeoutException (ce que `Future.timeout`
        // seul suffirait déjà à produire), c'est le client interne — qui
        // joue ici le rôle que jouerait `IOClient` avec une connexion
        // `dart:io` réelle — qui a observé un `abortTrigger` non nul *avant*
        // même l'expiration du délai, puis a vu ce déclencheur se compléter
        // et a lui-même agi en conséquence (ici : lever
        // `RequestAbortedException`, comme le fait `IOClient.send` en
        // appelant `HttpClientRequest.abort(...)`).
        expect(
          inner.sawNonNullAbortTriggerBeforeCompletion,
          isTrue,
          reason:
              'la requête transmise au client interne doit déjà porter un '
              "abortTrigger non nul au moment de l'appel, preuve que "
              'TimeoutHttpClient a bien armé un mécanisme de la dette '
              "http.Abortable plutôt que de compter sur Future.timeout()",
        );

        // `client.get(...)` peut déjà avoir levé sa `TimeoutException` via le
        // filet de sécurité `.timeout()` avant même que le déclencheur
        // d'annulation (piloté par le même délai, mais dans une opération
        // asynchrone distincte côté client interne) n'ait fini d'être
        // observé — c'est précisément pour ça que l'annulation réelle ne
        // doit pas dépendre de l'ordre d'arrivée face à `.timeout()` (voir
        // la doc de classe). On attend donc explicitement ce signal plutôt
        // que de supposer un ordre strict entre les deux.
        await inner.aborted;
        expect(
          inner.observedAbortSignal,
          isTrue,
          reason:
              "le déclencheur doit s'être réellement complété et avoir été "
              "observé par le client interne — c'est ce signal qui, avec un "
              '`IOClient` réel, fermerait la connexion `dart:io` sous-jacente '
              'via `HttpClientRequest.abort(...)`',
        );
      },
    );

    test(
      "compose avec un abortTrigger déjà présent sur la requête entrante "
      "plutôt que de l'écraser (ex. requête Postgrest déjà Abortable)",
      () async {
        final inner = _AbortAwareFakeClient();
        final client = TimeoutHttpClient(
          inner: inner,
          // Délai long : ce n'est pas lui qui doit déclencher l'annulation
          // dans ce test, mais le trigger déjà présent sur la requête.
          timeout: const Duration(seconds: 30),
        );
        final externalAbort = Completer<void>();
        final request = http.AbortableRequest(
          'GET',
          Uri.parse('https://exemple.test'),
          abortTrigger: externalAbort.future,
        );

        final responseFuture = client.send(request);

        // Laisse le client interne recevoir la requête et observer son
        // abortTrigger (combiné) avant de déclencher l'annulation externe.
        await Future<void>.delayed(Duration.zero);
        externalAbort.complete();

        await expectLater(
          responseFuture,
          throwsA(isA<http.RequestAbortedException>()),
        );
        expect(
          inner.sawNonNullAbortTriggerBeforeCompletion,
          isTrue,
          reason:
              "le trigger externe doit être combiné (Future.any) avec celui "
              "de TimeoutHttpClient, pas remplacé",
        );
        // C'est le trigger externe qui a déclenché l'annulation, pas le
        // délai de 30s de TimeoutHttpClient : l'exception reste donc une
        // RequestAbortedException brute, pas requalifiée en
        // TimeoutException (voir TimeoutHttpClient.send).
      },
    );
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

/// Client HTTP factice qui joue, pour les tests, le rôle que jouerait
/// `package:http`'s `IOClient` avec une vraie connexion `dart:io` : il
/// observe `request.abortTrigger` et réagit réellement à sa complétion
/// (au lieu de simplement ignorer la requête jusqu'à ce que l'appelant se
/// lasse) — exactement le comportement que `IOClient.send` implémente via
/// `HttpClientRequest.abort(...)` (voir `package:http/src/io_client.dart`).
///
/// `IOClient` lui-même n'est pas mockable directement (il encapsule un
/// vrai `dart:io.HttpClient`), donc ce double est le seul moyen, dans ce
/// dépôt, d'observer depuis un test qu'un `abortTrigger` a été transmis et
/// a produit un effet réel plutôt que d'être simplement ignoré.
class _AbortAwareFakeClient extends http.BaseClient {
  /// `true` si, au moment de l'appel à [send], la requête reçue portait
  /// déjà un `abortTrigger` non nul.
  bool sawNonNullAbortTriggerBeforeCompletion = false;

  /// `true` si ce déclencheur s'est bien complété et a été observé par ce
  /// client (preuve que le signal d'annulation est allé jusqu'au bout,
  /// pas seulement jusqu'à l'appelant).
  bool observedAbortSignal = false;

  final Completer<void> _abortedCompleter = Completer<void>();

  /// Se complète quand ce client a réellement observé le déclencheur
  /// d'annulation — à utiliser dans les tests pour attendre ce signal sans
  /// supposer un ordre strict avec le filet de sécurité `.timeout()` de
  /// [TimeoutHttpClient] (les deux sont pilotés par le même délai, mais
  /// restent deux opérations asynchrones indépendantes).
  Future<void> get aborted => _abortedCompleter.future;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final abortTrigger = switch (request) {
      http.Abortable(:final abortTrigger?) => abortTrigger,
      _ => null,
    };
    sawNonNullAbortTriggerBeforeCompletion = abortTrigger != null;

    if (abortTrigger == null) {
      // Pas de mécanisme d'annulation transmis : simule une connexion qui
      // ne répond jamais (le scénario D12 que `TimeoutHttpClient` doit
      // justement éviter de laisser tourner indéfiniment).
      await Future<void>.delayed(const Duration(seconds: 5));
      return http.StreamedResponse(const Stream.empty(), 200);
    }

    // Reproduit ce que fait réellement `IOClient` : dès que le
    // déclencheur se complète, la "connexion" est abandonnée pour de vrai
    // (ici : lever `RequestAbortedException`) plutôt que de continuer à
    // tourner en arrière-plan.
    await abortTrigger;
    observedAbortSignal = true;
    _abortedCompleter.complete();
    throw http.RequestAbortedException(request.url);
  }
}
