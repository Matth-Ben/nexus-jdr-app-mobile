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

  /// Déconnecte l'utilisateur courant (ex. action "Se déconnecter" du menu
  /// profil de la liste des personnages).
  Future<void> signOut();

  /// Déclenche l'envoi d'un e-mail de réinitialisation de mot de passe.
  ///
  /// Le lien reçu ouvre `https://nexus-jdr.app/update-password`, page déjà
  /// fonctionnelle de l'app web "Histoires" (compte unique entre les deux
  /// apps) — ce dépôt ne construit aucun écran de réinitialisation, il ne
  /// fait que déclencher l'envoi de l'e-mail.
  ///
  /// Côté UI, l'appelant doit rester neutre sur le résultat (succès ou
  /// échec) : ne jamais confirmer ou infirmer qu'un compte existe pour
  /// [email], même principe que `requestPasswordReset` côté web
  /// (`apps/web/app/(auth)/actions.ts`).
  Future<void> resetPasswordForEmail({required String email});
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

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (error) {
      throw mapAuthException(error);
    } catch (_) {
      throw mapUnknownError();
    }
  }

  @override
  Future<void> resetPasswordForEmail({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'https://nexus-jdr.app/update-password',
      );
    } on AuthException catch (error) {
      throw mapAuthException(error);
    } catch (_) {
      throw mapUnknownError();
    }
  }
}
