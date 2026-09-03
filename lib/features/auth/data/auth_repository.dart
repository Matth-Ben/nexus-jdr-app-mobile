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

  /// Met à jour le nom d'affichage (`user_metadata['full_name']`) de
  /// l'utilisateur courant — sheet "Modifier le profil" de l'écran
  /// `features/profile/presentation/profile_screen.dart`.
  ///
  /// [displayName] `null` ou vide (après `trim`) retire la clé `full_name`
  /// de `user_metadata` plutôt que d'y stocker une chaîne blanche —
  /// l'appelant retombe alors sur le nom par défaut "Aventurier" à
  /// l'affichage (jamais stocké comme valeur réelle, voir la doc de
  /// `_EditDisplayNameSheetContent`).
  ///
  /// Écriture directe uniquement, sans file d'attente hors-ligne
  /// (contrairement à `CharacterRepository.updateHp`/`addXp`/
  /// `updateStoryFields`...) : `Supabase Auth` n'a pas de mécanisme de
  /// synchro différée dans ce dépôt. L'appelant (la sheet) est responsable
  /// de vérifier la connectivité *avant* d'appeler cette méthode s'il veut
  /// éviter l'appel réseau plutôt que de laisser échouer.
  Future<void> updateDisplayName({required String? displayName});
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

  @override
  Future<void> updateDisplayName({required String? displayName}) async {
    // Fusionne par-dessus `user_metadata` existant plutôt que de l'écraser :
    // `UserAttributes.data` remplace tout `user_metadata` côté GoTrue, pas
    // seulement les clés fournies — voir la doc de
    // `AuthRepository.updateDisplayName`. `full_name` est la seule clé
    // utilisée par ce dépôt aujourd'hui, mais ce dépôt partage son compte
    // avec l'app web "Histoires" (`SupabaseAuthRepository`, doc de classe),
    // qui pourrait un jour y stocker d'autres clés.
    final existingMetadata = Map<String, dynamic>.from(
      _client.auth.currentUser?.userMetadata ?? const <String, dynamic>{},
    );
    final trimmed = displayName?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      existingMetadata.remove('full_name');
    } else {
      existingMetadata['full_name'] = trimmed;
    }

    try {
      await _client.auth.updateUser(UserAttributes(data: existingMetadata));
    } on AuthException catch (error) {
      throw mapAuthException(error);
    } catch (_) {
      throw mapUnknownError();
    }
  }
}
