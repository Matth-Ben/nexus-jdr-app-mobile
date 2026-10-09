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

  /// Délai au-delà duquel une requête en cours est abandonnée — voir la doc
  /// de classe pour le rationale de la valeur par défaut (15s, imposée hors
  /// test).
  final Duration timeout;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _inner.send(request).timeout(timeout);

  @override
  void close() => _inner.close();
}
