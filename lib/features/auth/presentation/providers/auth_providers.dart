import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/supabase_client_provider.dart';
import '../../data/auth_repository.dart';
import '../../data/auth_state_stream.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return SupabaseAuthRepository(ref.watch(supabaseClientProvider));
}

/// [AuthStateStream] partagé par toute l'app — voir sa doc de classe pour le
/// rationale ("piège `Ref.listen`") qui le distingue d'[authStateChanges]
/// ci-dessous. `keepAlive` : même rationale que [authRepositoryProvider].
@Riverpod(keepAlive: true)
AuthStateStream authStateStream(Ref ref) {
  return SupabaseAuthStateStream(ref.watch(supabaseClientProvider));
}

/// État d'authentification exposé de façon centralisée via Riverpod plutôt
/// que de l'état local dispersé dans chaque écran — n'importe quelle
/// fonctionnalité peut `ref.watch` ce provider pour réagir à une
/// connexion/déconnexion (ex. écran de profil).
///
/// Le routeur (`core/router/app_router.dart`) écoute quant à lui directement
/// le flux `onAuthStateChange` pour piloter `GoRouter.refreshListenable`,
/// afin de rester découplé de Riverpod dans la configuration du routeur.
@Riverpod(keepAlive: true)
Stream<AuthState> authStateChanges(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
}

/// Utilisateur Supabase actuellement connecté — seul point d'accès à
/// `Supabase.instance.client.auth.currentUser` dans ce dépôt (jamais un accès
/// direct/statique depuis un widget), pour que les tests de widgets (écran de
/// profil, `features/profile/presentation/profile_screen.dart`) puissent
/// overrider ce provider avec un `User` construit à la main, sans jamais
/// fabriquer de vrai `SupabaseClient` — même rationale que [AuthRepository].
///
/// `ref.watch(authStateChanges)` (plutôt qu'une simple lecture non réactive)
/// pour que ce provider se recalcule à chaque événement d'auth, en
/// particulier `AuthChangeEvent.userUpdated` émis par
/// `SupabaseAuthRepository.updateDisplayName` : l'écran de profil reflète
/// ainsi un nom d'affichage tout juste modifié sans qu'aucun code appelant
/// n'ait besoin d'invalider ce provider explicitement (contrairement au reste
/// du dépôt, ex. `characterDetailProvider`).
@Riverpod(keepAlive: true)
User? currentUser(Ref ref) {
  ref.watch(authStateChangesProvider);
  return ref.watch(supabaseClientProvider).auth.currentUser;
}
