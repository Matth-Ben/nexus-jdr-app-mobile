import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/supabase_client_provider.dart';
import '../../data/auth_repository.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return SupabaseAuthRepository(ref.watch(supabaseClientProvider));
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
