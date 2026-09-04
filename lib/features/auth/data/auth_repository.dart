import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/auth_failure.dart';
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

  /// Met à jour le mot de passe du compte connecté — sheet "Mot de passe" de
  /// `ProfileEditScreen` (`features/profile/presentation/profile_edit_screen.dart`).
  ///
  /// Aucune redemande du mot de passe actuel : la session déjà valide suffit
  /// à `Supabase Auth` pour accepter ce changement (même principe que
  /// `updatePassword` côté web, `apps/web/app/(auth)/actions.ts`).
  ///
  /// Écriture directe uniquement, sans file d'attente hors-ligne — même
  /// remarque que [updateDisplayName].
  Future<void> updatePassword({required String newPassword});

  /// Déclenche le changement d'adresse e-mail du compte connecté — sheet
  /// "Adresse email" de `ProfileEditScreen`.
  ///
  /// N'est **pas** effectif immédiatement : `Supabase Auth` envoie un e-mail
  /// de confirmation à [newEmail], le changement ne prend effet qu'une fois
  /// ce lien suivi — l'appelant ne doit donc jamais afficher un message
  /// "mis à jour" pour cette action (voir la sheet correspondante).
  ///
  /// Écriture directe uniquement, sans file d'attente hors-ligne — même
  /// remarque que [updateDisplayName].
  Future<void> updateEmail({required String newEmail});

  /// Envoie [bytes] (déjà recadrées en carré, voir
  /// `features/characters/presentation/widgets/portrait_crop_screen.dart`,
  /// dont le flux d'avatar est une variante) dans le bucket Storage partagé
  /// `character-portraits` (même bucket que les portraits de personnage,
  /// RLS déjà scopée par dossier `{user_id}/...` — aucune migration requise),
  /// sous `{ownerId}/avatar/{timestamp}.png`, puis fusionne l'URL publique
  /// résultante dans `user_metadata['avatar_url']` (même mécanisme de fusion
  /// que [updateDisplayName], jamais un écrasement de `user_metadata`).
  /// Retourne cette URL.
  Future<String> updateAvatar({required Uint8List bytes});

  /// Retire l'avatar du compte connecté : supprime le fichier correspondant
  /// du bucket en best-effort (silencieux si `avatar_url` ne pointe pas vers
  /// ce bucket, même règle que
  /// `CharacterRepository.removePortrait`/`PortraitStoragePathResolver`) puis
  /// retire la clé `avatar_url` de `user_metadata` (fusion, jamais un
  /// écrasement).
  Future<void> removeAvatar();
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

  /// Bucket Storage réutilisé tel quel pour les avatars de profil — même
  /// bucket que `PortraitStoragePathResolver.bucket`
  /// (`features/characters/domain/portrait_storage_path_resolver.dart`),
  /// dupliqué ici comme constante plutôt qu'importé pour ne pas introduire
  /// de dépendance de `features/auth/` vers `features/characters/`
  /// (architecture par fonctionnalité, voir `CLAUDE.md`) : la RLS du bucket
  /// (`{user_id}/...`) couvre `{ownerId}/avatar/...` exactement comme
  /// `{ownerId}/{characterId}/...`, aucune migration requise.
  static const String _avatarBucket = 'character-portraits';

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

  @override
  Future<void> updatePassword({required String newPassword}) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (error) {
      throw mapAuthException(error);
    } catch (_) {
      throw mapUnknownError();
    }
  }

  @override
  Future<void> updateEmail({required String newEmail}) async {
    try {
      await _client.auth.updateUser(UserAttributes(email: newEmail));
    } on AuthException catch (error) {
      throw mapAuthException(error);
    } catch (_) {
      throw mapUnknownError();
    }
  }

  @override
  Future<String> updateAvatar({required Uint8List bytes}) async {
    final ownerId = _requireOwnerId();
    // Même rationale de nom de fichier horodaté que
    // `CharacterRepository.uploadPortrait` : évite tout problème de cache
    // CDN/navigateur sur l'URL publique après un remplacement d'avatar.
    final path = '$ownerId/avatar/${DateTime.now().millisecondsSinceEpoch}.png';

    try {
      await _client.storage
          .from(_avatarBucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/png',
              upsert: true,
            ),
          );
      final publicUrl = _client.storage.from(_avatarBucket).getPublicUrl(path);

      // Fusion par-dessus `user_metadata` existant — voir la documentation
      // de [updateDisplayName].
      final existingMetadata = Map<String, dynamic>.from(
        _client.auth.currentUser?.userMetadata ?? const <String, dynamic>{},
      );
      existingMetadata['avatar_url'] = publicUrl;
      await _client.auth.updateUser(UserAttributes(data: existingMetadata));

      return publicUrl;
    } on StorageException catch (error) {
      throw AuthFailure(
        error.message.isNotEmpty
            ? error.message
            : "Impossible de mettre à jour l'avatar. Réessayez.",
      );
    } on AuthException catch (error) {
      throw mapAuthException(error);
    } catch (_) {
      throw mapUnknownError();
    }
  }

  @override
  Future<void> removeAvatar() async {
    _requireOwnerId();
    final existingMetadata = Map<String, dynamic>.from(
      _client.auth.currentUser?.userMetadata ?? const <String, dynamic>{},
    );
    final avatarUrl = existingMetadata['avatar_url'] as String?;

    try {
      if (avatarUrl != null) {
        final path = _resolveAvatarStoragePath(avatarUrl);
        // `path == null` : `avatar_url` ne pointe pas vers ce bucket (cas
        // qui ne devrait jamais se produire pour un avatar, contrairement au
        // portrait de personnage qui accepte une URL externe via "Utiliser
        // une URL" — retiré pour l'avatar, voir la spec de la tâche) — même
        // règle "best-effort" que `CharacterRepository.removePortrait`.
        if (path != null) {
          await _client.storage.from(_avatarBucket).remove([path]);
        }
      }
      existingMetadata.remove('avatar_url');
      await _client.auth.updateUser(UserAttributes(data: existingMetadata));
    } on StorageException catch (error) {
      throw AuthFailure(
        error.message.isNotEmpty
            ? error.message
            : "Impossible de mettre à jour l'avatar. Réessayez.",
      );
    } on AuthException catch (error) {
      throw mapAuthException(error);
    } catch (_) {
      throw mapUnknownError();
    }
  }

  String _requireOwnerId() {
    final ownerId = _client.auth.currentUser?.id;
    if (ownerId == null) {
      throw const AuthFailure(
        'Session expirée. Reconnectez-vous pour continuer.',
      );
    }
    return ownerId;
  }
}

/// Résout le chemin de stockage (`{owner_id}/avatar/...`) depuis l'URL
/// publique d'un avatar — copie volontaire de
/// `PortraitStoragePathResolver.resolve`
/// (`features/characters/domain/portrait_storage_path_resolver.dart`), même
/// rationale de duplication que [SupabaseAuthRepository._avatarBucket]
/// (pas de dépendance `features/auth/` → `features/characters/`).
String? _resolveAvatarStoragePath(String publicUrl) {
  // Bucket dupliqué en dur ici plutôt que via `SupabaseAuthRepository
  // ._avatarBucket` : garde cette fonction top-level totalement autonome
  // (testable isolément), voir la doc de classe pour le rationale de
  // duplication du nom de bucket.
  const marker = '/object/public/character-portraits/';
  final index = publicUrl.indexOf(marker);
  if (index == -1) return null;
  final path = publicUrl.substring(index + marker.length);
  return path.isEmpty ? null : path;
}
