import 'package:supabase_flutter/supabase_flutter.dart';

/// Fine enveloppe autour de `Supabase.instance.client.auth.onAuthStateChange`
/// — un `Stream<AuthState>` **brut**, jamais enveloppé dans un `AsyncValue`
/// Riverpod (contrairement à `authStateChangesProvider`,
/// `features/auth/presentation/providers/auth_providers.dart`) — même
/// rationale que `ConnectivityChecker`
/// (`core/network/connectivity_checker.dart`) : les tests peuvent injecter un
/// double sans jamais toucher à `Supabase.instance.client`.
///
/// **Pourquoi une seconde abstraction alors qu'`authStateChangesProvider`
/// existe déjà** (piège découvert en écrivant
/// `CharacterCreationCatalogPreloader`, premier consommateur de ce flux
/// depuis un objet Dart pur plutôt que depuis un widget) : `Ref.listen`
/// documente explicitement que "Listeners will automatically be removed when
/// the provider rebuilds" — en pratique, un abonnement établi via
/// `_ref.listen(authStateChangesProvider, ...)` depuis un provider
/// `keepAlive` qui n'est lui-même jamais *activement* écouté (ex. un test
/// qui ne fait que `container.read(...)`, par opposition à `ref.watch(...)`
/// dans un widget réel comme `main.dart`) peut rester silencieusement inerte
/// : aucun événement du flux source ne parvient plus au callback, sans la
/// moindre erreur. `CharacterWriteSyncCoordinator`
/// (`features/characters/presentation/providers/character_write_sync_coordinator.dart`)
/// évite déjà ce piège pour la connectivité en s'abonnant directement au
/// `Stream<bool>` brut de `ConnectivityChecker` plutôt que via `Ref.listen`
/// sur un `StreamProvider` — [AuthStateStream] applique le même principe ici.
/// `authStateChangesProvider` reste utile tel quel pour les écrans qui font
/// un vrai `ref.watch` (ex. `currentUserProvider`), seulement inadapté à un
/// abonnement `Ref.listen` déclenché une fois au démarrage.
abstract class AuthStateStream {
  Stream<AuthState> get onAuthStateChange;
}

/// Implémentation réelle, basée sur `Supabase.instance.client.auth`.
class SupabaseAuthStateStream implements AuthStateStream {
  const SupabaseAuthStateStream(this._client);

  final SupabaseClient _client;

  @override
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;
}
