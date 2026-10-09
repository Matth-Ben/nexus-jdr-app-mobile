import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/cache/pending_character_write_queue.dart';
import '../../../core/cache/reference_data_cache.dart';
import '../domain/auth_failure.dart';
import 'auth_error_mapper.dart';

/// Message de l'[AuthFailure] levée par [SupabaseAuthRepository.signOut]/
/// [SupabaseAuthRepository.deleteAccount] quand des écritures PV/XP restent
/// en attente de synchro après une tentative (D31 du registre de dette
/// technique) — voir la doc de classe de [SupabaseAuthRepository]. Exporté
/// (plutôt qu'un littéral répété) pour que
/// `features/profile/presentation/profile_delete_account_screen.dart`
/// puisse distinguer ce cas précis de toute autre erreur de suppression de
/// compte, qu'il affiche sinon derrière un message générique fixe (spec de
/// la tâche d'origine de cet écran) — ce message-ci, contrairement aux
/// erreurs serveur brutes que ce générique masque volontairement, est déjà
/// un texte applicatif sûr à afficher tel quel.
const String pendingHpXpWritesBlockedMessage =
    'Des ajustements de PV/XP sont encore en attente de synchronisation — '
    'réessayez une fois la connexion rétablie.';

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

  /// Renvoie `true` si une confirmation par e-mail est nécessaire avant que
  /// le compte soit actif (aucune session créée par cet appel — c'est le
  /// cas sur ce projet Supabase, voir la doc de classe de
  /// [SupabaseAuthRepository.signUp]), `false` si le compte est
  /// immédiatement actif (session créée, comme pour [signInWithPassword]).
  /// L'appelant (`login_screen.dart`) en a besoin pour savoir s'il doit
  /// afficher un message "vérifie ta boîte mail" plutôt que de compter sur
  /// une redirection automatique qui n'aura pas lieu.
  Future<bool> signUp({required String email, required String password});

  /// Déconnecte l'utilisateur courant (ex. action "Se déconnecter" du menu
  /// profil de la liste des personnages).
  ///
  /// D31 du registre de dette technique ("cache local jamais purgé") : avant
  /// de déconnecter, tente de synchroniser toute écriture PV/XP encore en
  /// attente (`core/cache/pending_character_write_queue.dart`) puis purge le
  /// cache local (catalogue de référence + file d'attente du compte) une
  /// fois la déconnexion effective — voir la doc de classe de
  /// [SupabaseAuthRepository] pour le détail. S'il reste une écriture en
  /// attente après la tentative de synchro (vraiment hors ligne), lève une
  /// [AuthFailure] **sans déconnecter** plutôt que de perdre silencieusement
  /// l'ajustement : l'appelant doit pouvoir réessayer une fois la connexion
  /// rétablie.
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

  /// Supprime définitivement le compte connecté — étape finale de l'écran
  /// "Supprimer mon compte"
  /// (`features/profile/presentation/profile_delete_account_screen.dart`),
  /// appelée uniquement après reconfirmation du mot de passe par
  /// [signInWithPassword] (voir la documentation de classe de cet écran pour
  /// le flux complet).
  ///
  /// Appelle l'edge function Supabase `delete-account` (déployée côté dépôt
  /// web, jamais une migration/RLS gérée depuis ce dépôt) : `POST` authentifié
  /// (jeton déjà géré automatiquement par `functions.invoke`, aucun corps
  /// requis), qui supprime `auth.users` via `admin.deleteUser` — la
  /// suppression cascade automatiquement en base vers tous les personnages/
  /// inventaire/sorts/rattachements du joueur (contrainte de clé étrangère
  /// côté dépôt web, jamais reproduite ici). Un code 200 (`{ deleted: true
  /// }`) est le seul succès reconnu ; toute autre situation (401 non
  /// authentifié, 500 erreur serveur, exception réseau) lève une
  /// [AuthFailure].
  ///
  /// Ne déconnecte **pas** le joueur elle-même : c'est à l'appelant
  /// d'enchaîner avec [signOut] une fois cette méthode résolue avec succès
  /// (voir la doc de classe de `ProfileDeleteAccountScreen`), pour que la
  /// séquence "supprimer puis déconnecter" reste explicite et visible d'un
  /// seul coup d'œil côté UI plutôt que cachée dans ce repository.
  ///
  /// D31 du registre de dette technique : même garde-fou que [signOut],
  /// appliqué **avant** l'appel à l'edge function (une écriture PV/XP encore
  /// en attente après tentative de synchro bloque la suppression elle-même,
  /// avec une [AuthFailure] explicite — le compte n'est alors jamais
  /// supprimé). Le cache local n'est purgé qu'**après** une suppression
  /// effectivement confirmée par le serveur : à ce stade il n'y a plus de
  /// session à synchroniser, la purge peut donc être inconditionnelle (voir
  /// la doc de classe de [SupabaseAuthRepository]).
  Future<void> deleteAccount();
}

/// Implémentation réelle, basée sur `Supabase.instance.client.auth`.
///
/// Un compte est unique entre l'app "Histoires" et l'app "Personnages"
/// (`04-fonctionnalites-app-mobile.md` section 1) : ce dépôt ne fait
/// qu'appeler Supabase Auth normalement, aucune logique de compte séparée
/// côté mobile.
///
/// **D31 du registre de dette technique** ("cache local jamais purgé") :
/// [signOut]/[deleteAccount] purgent le cache local (drift,
/// `core/cache/app_database.dart`) — catalogue de référence
/// ([ReferenceDataCache], jamais spécifique à un compte, purge totale) et
/// file d'attente PV/XP hors-ligne ([PendingCharacterWriteQueue], scopée par
/// `ownerId`) — pour qu'un appareil partagé ou un compte supprimé ne laisse
/// jamais de donnée d'un ancien compte traîner localement. [auth] dépendant
/// de `core/cache` ne crée pas de cycle (`core/cache` ne dépend d'aucune
/// `feature`).
///
/// Avant toute purge, un garde-fou (D31, même patron que D35 —
/// `CharacterRepository._blockIfPendingHpOrXpWrites`,
/// `features/characters/data/character_repository.dart`) tente de
/// synchroniser best-effort ([syncPendingWrites], typiquement
/// `PendingCharacterWriteSyncer.sync` — injecté en fonction plutôt que la
/// classe concrète de `features/characters/data/`, pour que cette classe
/// reste libre de toute dépendance vers une autre `feature` ; voir
/// `core/sync/pending_write_sync_hook_provider.dart` pour l'indirection
/// neutre qui lit ce provider depuis
/// `features/auth/presentation/providers/auth_providers.dart`, et `lib/
/// main.dart` pour le point de câblage réel vers
/// `PendingCharacterWriteSyncer`) puis vérifie s'il reste une écriture PV/XP
/// en attente
/// pour le compte courant ([pendingWriteQueue.allForOwner]) : s'il en reste
/// (vraiment hors ligne), lève une [AuthFailure] **sans purger ni procéder**
/// à l'opération demandée plutôt que de perdre silencieusement un ajustement
/// de PV/XP — le joueur doit pouvoir réessayer une fois la connexion
/// rétablie.
///
/// [pendingWriteQueue]/[referenceDataCache]/[syncPendingWrites] sont
/// optionnels (`null` par défaut) : seul le câblage réel
/// (`auth_providers.dart` + l'`override` de `lib/main.dart`, voir plus haut)
/// les fournit. Laissés `null`, [signOut]/
/// [deleteAccount] se comportent exactement comme avant l'introduction de ce
/// garde-fou (aucune synchro, aucune purge) — permet à l'existant
/// `test/features/auth/data/auth_repository_test.dart` (qui construit
/// `SupabaseAuthRepository` avec le seul `client`, pour des méthodes sans
/// rapport avec ce garde-fou) de continuer à compiler et passer sans
/// modification.
class SupabaseAuthRepository implements AuthRepository {
  const SupabaseAuthRepository(
    this._client, {
    this.pendingWriteQueue,
    this.referenceDataCache,
    this.syncPendingWrites,
  });

  final SupabaseClient _client;

  /// Voir la doc de classe. `null` : garde-fou/purge désactivés (voir la doc
  /// de classe).
  final PendingCharacterWriteQueue? pendingWriteQueue;

  /// Voir la doc de classe. `null` : garde-fou/purge désactivés (voir la doc
  /// de classe).
  final ReferenceDataCache? referenceDataCache;

  /// Tentative de synchronisation best-effort de la file d'attente PV/XP du
  /// compte courant — voir la doc de classe. `null` : garde-fou/purge
  /// désactivés (voir la doc de classe).
  final Future<void> Function()? syncPendingWrites;

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
  Future<bool> signUp({required String email, required String password}) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      // Confirmation par e-mail activée sur ce projet Supabase (même
      // config que l'app web, voir `apps/web/app/(auth)/actions.ts`, qui ne
      // redirige jamais après un `signUp` réussi contrairement à son
      // `login`) : `signUp` réussit sans exception mais ne crée pas de
      // session tant que le lien de confirmation n'a pas été suivi.
      // `response.session == null` est le seul signal fiable pour le
      // distinguer d'un compte immédiatement actif.
      return response.session == null;
    } on AuthException catch (error) {
      throw mapAuthException(error);
    } catch (_) {
      throw mapUnknownError();
    }
  }

  @override
  Future<void> signOut() async {
    final ownerId = _client.auth.currentUser?.id;
    await _ensureNoPendingWrites(ownerId);

    try {
      await _client.auth.signOut();
    } on AuthException catch (error) {
      throw mapAuthException(error);
    } catch (_) {
      throw mapUnknownError();
    }

    await _purgeLocalCache(ownerId);
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

  @override
  Future<void> deleteAccount() async {
    final ownerId = _client.auth.currentUser?.id;
    // Garde-fou AVANT l'appel réseau de suppression (voir la doc de
    // `AuthRepository.deleteAccount`) : une écriture PV/XP encore en attente
    // doit bloquer la suppression elle-même, jamais seulement la purge qui
    // la suit — supprimer le compte puis découvrir un ajustement non
    // synchronisé serait trop tard, il n'y aurait plus de compte vers lequel
    // le rejouer.
    await _ensureNoPendingWrites(ownerId);

    try {
      // Aucun corps requis (voir la doc de
      // `AuthRepository.deleteAccount`) : le jeton d'authentification déjà
      // géré automatiquement par `functions.invoke` suffit à l'edge function
      // pour identifier le compte à supprimer.
      await _client.functions.invoke('delete-account');
    } on FunctionException catch (error) {
      // Couvre `FunctionsHttpException` (401/500...) comme
      // `FunctionsFetchException`/`FunctionsRelayException` (pas de réponse
      // HTTP reçue) — voir [mapDeleteAccountError] pour le détail du mapping.
      throw mapDeleteAccountError(error);
    } catch (_) {
      throw mapUnknownError();
    }

    // Purge APRÈS une suppression confirmée par le serveur (voir la doc de
    // `AuthRepository.deleteAccount`) : plus de session à synchroniser à ce
    // stade, la purge peut être inconditionnelle plutôt que re-vérifiée.
    await _purgeLocalCache(ownerId);
  }

  /// D31 du registre de dette technique — voir la doc de classe de
  /// [SupabaseAuthRepository] pour le rationale complet. Ne fait rien si
  /// [pendingWriteQueue]/[syncPendingWrites] n'ont pas été injectés, ou si
  /// [ownerId] est `null` (personne de connecté : rien à synchroniser ni à
  /// vérifier).
  Future<void> _ensureNoPendingWrites(String? ownerId) async {
    final queue = pendingWriteQueue;
    final sync = syncPendingWrites;
    if (queue == null || sync == null || ownerId == null) return;

    await sync();

    final stillPending = await queue.allForOwner(ownerId);
    if (stillPending.isNotEmpty) {
      throw const AuthFailure(pendingHpXpWritesBlockedMessage);
    }
  }

  /// D31 du registre de dette technique — voir la doc de classe de
  /// [SupabaseAuthRepository]. Toujours appelée seulement après
  /// [_ensureNoPendingWrites] (jamais de vérification propre ici) : purge le
  /// catalogue de référence sans condition ([ReferenceDataCache.clear],
  /// jamais spécifique à un compte) et la file d'attente PV/XP de [ownerId]
  /// ([PendingCharacterWriteQueue.removeAllForOwner], y compris d'éventuelles
  /// entrées déjà abandonnées — D34 — dont le message n'a pas encore été
  /// consommé, plus personne à qui l'afficher une fois le compte
  /// déconnecté/supprimé). Ne fait rien si [referenceDataCache]/
  /// [pendingWriteQueue] n'ont pas été injectés, ou pour la seule partie
  /// `ownerId` si celui-ci est `null`.
  Future<void> _purgeLocalCache(String? ownerId) async {
    final cache = referenceDataCache;
    if (cache != null) {
      await cache.clear();
    }

    final queue = pendingWriteQueue;
    if (queue != null && ownerId != null) {
      await queue.removeAllForOwner(ownerId);
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
