import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_error_mapper.dart';

/// Passerelle vers l'authentification par e-mail/mot de passe.
///
/// Abstraction (plutôt qu'une classe concrète directement injectée) pour
/// permettre aux tests de widgets de fournir un double sans jamais toucher à
/// `Supabase.instance.client` (voir `test/features/auth/presentation/login_screen_test.dart`).
abstract class AuthRepository {
  Future<void> signInWithPassword({
    required String email,
    required String password,
  });

  Future<void> signUp({required String email, required String password});
}

/// Implémentation réelle, basée sur `Supabase.instance.client.auth`.
///
/// Un compte est unique entre l'app "Histoires" et l'app "Personnages"
/// (`04-fonctionnalites-app-mobile.md` section 1) : ce dépôt ne fait
/// qu'appeler Supabase Auth normalement, aucune logique de compte séparée
/// côté mobile.
class SupabaseAuthRepository implements AuthRepository {
  const SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (error) {
      throw mapAuthException(error);
    } catch (_) {
      throw mapUnknownError();
    }
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    try {
      await _client.auth.signUp(email: email, password: password);
    } on AuthException catch (error) {
      throw mapAuthException(error);
    } catch (_) {
      throw mapUnknownError();
    }
  }
}
