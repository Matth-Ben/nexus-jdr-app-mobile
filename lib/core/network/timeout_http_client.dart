import 'dart:async';

import 'package:http/http.dart' as http;

/// [http.Client] injecté dans `Supabase.initialize`
/// (`main.dart::_initializeSupabaseAndFirebase`, paramètre `httpClient`) pour
/// border la durée de **toute** requête HTTP sortante à [timeout] — dette
/// D12 du registre `docs/dette-technique.md` ("aucun délai d'attente
/// réseau").
///
/// Choix d'un unique point d'entrée global plutôt que d'ajouter
/// `.timeout(...)` sur chacun des ~189 appels `.from(...)` de ce dépôt
/// (décision chef de projet) : un seul endroit à auditer/faire évoluer, et
/// couvre aussi les appels HTTP internes à `supabase_flutter`/`gotrue`/
/// `storage` qui ne passent jamais par `.from(...)` (ex. rafraîchissement de
/// session, upload Storage) — une politique dispersée sur les seuls appels
/// Postgrest les aurait laissés sans délai.
///
/// Sans lui, [ConnectivityChecker.hasConnection]
/// (`core/network/connectivity_checker.dart`) peut déclarer une interface
/// réseau "connectée" (Wi-Fi sans débit réel, signal faible...) alors
/// qu'aucune requête n'aboutit jamais côté serveur : sans délai global, la
/// requête HTTP sous-jacente pend indéfiniment — ni succès ni échec, l'app
/// reste bloquée sans jamais remonter d'erreur exploitable à l'appelant.
///
/// [timeout] vaut 15 secondes par défaut (valeur imposée par le chef de
/// projet pour cette dette, pas un choix de cet agent) : assez long pour
/// rester tolérant à un réseau mobile lent mais légitime, assez court pour
/// que l'échec reste perceptible par le joueur comme "l'app a réagi" plutôt
/// que "l'app est gelée". `SupabaseCharacterRepository.updateHp`/`addXp`
/// (`features/characters/data/character_repository.dart`) traitent
/// spécifiquement l'exception levée par ce délai (`TimeoutException`,
/// `dart:async`) comme une absence de connectivité (mise en file hors-ligne)
/// plutôt que comme une erreur dure — voir leur documentation ; aucune
/// autre méthode de ce dépôt ne fait cette distinction, elles bénéficient
/// seulement de ne plus jamais pendre indéfiniment.
///
/// ## Annulation réelle de la connexion (pas seulement de l'attente de
/// l'appelant)
///
/// `Future.timeout()` seul (implémentation initiale de cette classe) ne
/// fait que lever une [TimeoutException] côté appelant : il n'annule
/// jamais le [Future] d'origine — c'est documenté dans le SDK Dart lui-même
/// (`dart:async`, doc de `Future.timeout`). La vraie requête HTTP sous-jacente
/// continuait donc de tourner en arrière-plan indéfiniment (jusqu'à un
/// abandon niveau socket/OS), exactement le scénario de "connexion zombie"
/// que D12 vise à éliminer (Wi-Fi sans débit réel).
///
/// `package:http` ^1.6.0 (contrainte déjà en place dans `pubspec.yaml`)
/// expose le mixin `Abortable` (`http.dart::Abortable`) : un champ
/// `abortTrigger` (`Future<void>?`) que `IOClient.send`
/// (`package:http/src/io_client.dart`) surveille réellement — quand ce
/// `Future` se complète, `IOClient` appelle `HttpClientRequest.abort(...)`
/// sur la connexion `dart:io` sous-jacente, ce qui la ferme pour de vrai.
///
/// Ce que construisent les paquets dont dépend ce dépôt (vérifié dans le
/// cache pub, versions figées par `pubspec.lock`) :
/// - `postgrest` 2.9.1 (`PostgrestBuilder._execute`) construit déjà lui-même
///   un `http.AbortableRequest` pour chaque appel `.from(...)`, mais avec un
///   `abortTrigger` qui vaut `null` tant que l'appelant ne configure pas
///   explicitement `requestTimeout`/`abortSignal` sur le client Postgrest —
///   ce que ce dépôt ne fait pas : en pratique, les requêtes Postgrest qui
///   arrivent jusqu'ici sont donc des `Abortable` dont le déclencheur est
///   déjà présent mais non armé.
/// - `gotrue` 2.27.2 (`GotrueFetch._handleRequest`) appelle les méthodes de
///   confort du client (`get`/`post`/`put`/`patch`/`delete`), qui
///   construisent en interne un `http.Request` tout simple (corps déjà en
///   mémoire) — jamais `Abortable`.
/// - `storage_client` 2.8.0 (`Fetch._handleRequest`/`_handleMultipartRequest`)
///   construit soit un `http.Request` simple (CRUD du bucket), soit un
///   `http.MultipartRequest` pour `uploadBinary`/`upload` (utilisé par
///   `AuthRepository`/`CharacterRepository` pour les portraits et avatars) —
///   jamais `Abortable` non plus. Aucun appel de ce dépôt ne construit de
///   `StreamedRequest` (corps en flux non rejouable) : un `grep` sur
///   `StreamedRequest(` dans `postgrest-2.9.1`, `gotrue-2.27.2` et
///   `storage_client-2.8.0` ne retourne aucune occurrence.
///
/// Stratégie retenue : avant de transmettre la requête à [_inner], cette
/// classe la reconstruit donc en l'équivalent `Abortable` de son type
/// concret réel (`http.Request`/`http.AbortableRequest` →
/// `http.AbortableRequest` ; `http.MultipartRequest`/
/// `http.AbortableMultipartRequest` → `http.AbortableMultipartRequest`),
/// avec un déclencheur qu'elle arme elle-même ([Timer] de [timeout] couplé à
/// un [Completer]). Si la requête portait déjà un `abortTrigger` non nul
/// (mécanisme d'annulation propre à l'appelant, pas utilisé aujourd'hui par
/// ce dépôt mais qui pourrait l'être demain), il est combiné via
/// `Future.any([...])` plutôt qu'écrasé : les deux déclencheurs peuvent
/// annuler la requête, indépendamment l'un de l'autre.
///
/// Un type de requête qui ne serait ni `http.Request` ni
/// `http.MultipartRequest` (donc, d'après l'audit ci-dessus, qui ne peut pas
/// survenir avec les dépendances actuelles de ce dépôt) ne peut pas être
/// reconstruit en toute sécurité par cette classe : son corps pourrait être
/// un flux déjà entamé et non rejouable. Dans ce cas, [send] se contente du
/// comportement historique (`Future.timeout` sans annulation réelle) plutôt
/// que de risquer de corrompre une vraie requête — ce cas est documenté ici
/// plutôt que silencieusement toléré, pour qu'une future dépendance qui
/// introduirait un tel type de requête n'échappe pas à une revue.
///
/// [inner] (le client HTTP réellement utilisé pour émettre chaque requête)
/// est injectable uniquement pour les tests
/// (`test/core/network/timeout_http_client_test.dart`) — `http.Client()` par
/// défaut en dehors d'eux.
class TimeoutHttpClient extends http.BaseClient {
  TimeoutHttpClient({
    http.Client? inner,
    this.timeout = const Duration(seconds: 15),
  }) : _inner = inner ?? http.Client();

  final http.Client _inner;

  /// Délai au-delà duquel une requête en cours est abandonnée **et
  /// réellement annulée** (voir la doc de classe pour la stratégie
  /// d'annulation et le rationale de la valeur par défaut, 15s, imposée hors
  /// test).
  final Duration timeout;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final ownAbort = Completer<void>();
    final timer = Timer(timeout, () {
      if (!ownAbort.isCompleted) {
        ownAbort.complete();
      }
    });

    final existingTrigger = switch (request) {
      http.Abortable(:final abortTrigger) => abortTrigger,
      _ => null,
    };
    final combinedTrigger = existingTrigger == null
        ? ownAbort.future
        : Future.any<void>([existingTrigger, ownAbort.future]);

    final outgoing = _withAbortTrigger(request, combinedTrigger);

    try {
      // `.timeout(timeout)` reste systématiquement en place, même pour une
      // requête correctement reconstruite en `Abortable` : c'est le
      // filet de sécurité qui garantit à l'appelant une `TimeoutException`
      // même si [_inner] n'honore pas réellement `abortTrigger` (ex.
      // `http.testing.MockClient` dans les tests, ou tout futur client
      // injecté qui ne serait pas un `IOClient`). La vraie annulation de la
      // connexion, elle, ne dépend pas de ce `.timeout()` : elle vient de
      // [combinedTrigger] remis à [outgoing] ci-dessus, qui continue à agir
      // sur la requête en arrière-plan même après que `.timeout()` a déjà
      // laissé filer une `TimeoutException` côté appelant — voir la doc de
      // classe pour le rationale (`Future.timeout()` seul n'annule jamais
      // le futur d'origine, mais ici l'annulation réelle vient d'ailleurs).
      return await _inner.send(outgoing ?? request).timeout(timeout);
    } on http.RequestAbortedException {
      if (ownAbort.isCompleted) {
        // C'est bien notre propre délai qui a déclenché l'annulation : les
        // appelants de ce dépôt (ex. `SupabaseCharacterRepository`) traitent
        // spécifiquement `TimeoutException` comme une absence de
        // connectivité, pas `RequestAbortedException` — on préserve ce
        // contrat.
        //
        // Limite connue (heuristique temporelle, pas un lien causal direct
        // avec l'exception attrapée) : `ownAbort.isCompleted` constate
        // seulement que notre propre [Timer] a fini par se compléter, pas
        // que c'est lui qui a causé cette `RequestAbortedException`
        // précise. Comme ci-dessus (cas des requêtes ni `Request` ni
        // `MultipartRequest`), ce n'est pas atteignable avec les
        // dépendances actuelles : `abortTrigger` externe (`existingTrigger`)
        // vaut toujours `null` en pratique, aucun appelant de ce dépôt ne
        // configurant `requestTimeout`/`abortSignal` sur le client
        // Postgrest. Si cela changeait un jour avec un délai externe proche
        // de [timeout], une course étroite entre les deux déclencheurs
        // pourrait requalifier à tort une annulation externe en
        // `TimeoutException` ici.
        throw TimeoutException(
          'Requête HTTP abandonnée après $timeout sans réponse (dette D12)',
          timeout,
        );
      }
      // Annulation déclenchée par le trigger déjà présent sur la requête
      // entrante (pas le nôtre) : on ne la requalifie pas, c'est le
      // mécanisme propre de l'appelant qui s'est exprimé.
      rethrow;
    } finally {
      timer.cancel();
    }
  }

  /// Reconstruit [request] en l'équivalent `Abortable` de son type concret,
  /// avec [trigger] comme `abortTrigger`. Retourne `null` si [request]
  /// n'est ni un `http.Request` ni un `http.MultipartRequest` (voir la doc
  /// de classe : ce cas n'est pas atteint avec les dépendances actuelles de
  /// ce dépôt).
  http.BaseRequest? _withAbortTrigger(
    http.BaseRequest request,
    Future<void> trigger,
  ) {
    if (request is http.MultipartRequest) {
      return http.AbortableMultipartRequest(
          request.method,
          request.url,
          abortTrigger: trigger,
        )
        ..headers.addAll(request.headers)
        ..fields.addAll(request.fields)
        ..files.addAll(request.files)
        ..followRedirects = request.followRedirects
        ..maxRedirects = request.maxRedirects
        ..persistentConnection = request.persistentConnection;
    }

    if (request is http.Request) {
      return http.AbortableRequest(
          request.method,
          request.url,
          abortTrigger: trigger,
        )
        ..headers.addAll(request.headers)
        ..bodyBytes = request.bodyBytes
        ..followRedirects = request.followRedirects
        ..maxRedirects = request.maxRedirects
        ..persistentConnection = request.persistentConnection;
    }

    return null;
  }

  @override
  void close() => _inner.close();
}
