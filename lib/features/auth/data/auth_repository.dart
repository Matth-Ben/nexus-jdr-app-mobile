import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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
  /// [displayName] : pseudo optionnel saisi à l'inscription (champ "Pseudo"
  /// de `login_screen.dart`, mode inscription) — `null`/vide après `trim()`
  /// n'ajoute aucune clé `data` à l'appel `signUp` plutôt que d'y stocker une
  /// chaîne vide, même règle que [updateDisplayName]. Si fourni, stocké sous
  /// la même clé `full_name` que [updateDisplayName] (cohérence avec le
  /// profil, `docs/cahier-des-charges/15-profil-parametres.md` section 2).
  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  });

  /// Démarre le flux OAuth web Google (`signInWithOAuth`, pas le SDK natif
  /// `google_sign_in` — évite la configuration SHA-1/client IDs natifs par
  /// plateforme, voir la doc de classe de [SupabaseAuthRepository]).
  ///
  /// Ouvre un navigateur système puis revient dans l'app via le schéma
  /// personnalisé `nexusjdr://login-callback/` (enregistré dans
  /// `android/app/src/main/AndroidManifest.xml` et `ios/Runner/Info.plist`) —
  /// pas l'App Link universel `https://nexus-jdr.app`, qui dépend d'un
  /// entitlement Associated Domains côté iOS non disponible tant que le
  /// compte Apple Developer n'est pas actif (même blocage que Sign in with
  /// Apple, explicitement hors périmètre).
  ///
  /// Comme pour [signInWithPassword], aucune session n'est retournée
  /// directement par cet appel : une fois l'utilisateur revenu dans l'app
  /// après authentification côté navigateur, `onAuthStateChange` (déjà
  /// câblé côté routeur) déclenche la redirection.
  Future<void> signInWithGoogle();

  /// Démarre le flux natif "Sign in with Apple" (`signInWithIdToken`, pas
  /// `signInWithOAuth` comme [signInWithGoogle]) — obligation Apple App
  /// Store Review Guideline 4.8 : toute app proposant une connexion sociale
  /// tierce (ici Google) doit aussi proposer Sign in with Apple. Voir la doc
  /// de classe de [SupabaseAuthRepository.signInWithApple] pour le détail du
  /// flux et, surtout, pour la dépendance bloquante qui empêche ce flux de
  /// fonctionner en conditions réelles tant que le compte Apple Developer
  /// Program n'est pas créé.
  ///
  /// Contrairement à [signInWithGoogle], ne passe jamais par un navigateur
  /// système : le SDK natif iOS affiche directement la feuille système
  /// Apple, et [SupabaseAuthRepository.signInWithApple] résout la session
  /// Supabase elle-même (pas de redirection `onAuthStateChange` à attendre
  /// après un retour d'URL — même mécanisme qu'[signInWithPassword]/[signUp]
  /// de ce point de vue).
  Future<void> signInWithApple();

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

  /// Marque le carousel d'onboarding comme vu
  /// (`user_metadata['onboarding_completed'] = true`) — appelée en sortie de
  /// `features/onboarding/presentation/onboarding_screen.dart` (bouton
  /// "Passer" ou CTA final "C'est parti !"), que l'écran ait été ouvert
  /// automatiquement par le routeur (première connexion, voir
  /// [computeAuthRedirect] dans `core/router/app_router.dart`) ou
  /// volontairement (profil > Aide et support > "Revoir la présentation de
  /// l'app").
  ///
  /// Idempotente : rappelable sans effet de bord si déjà `true`. Même
  /// mécanisme de fusion que [updateDisplayName]/[updateAvatar] (ne jamais
  /// écraser le reste de `user_metadata`).
  ///
  /// Écriture directe uniquement, sans file d'attente hors-ligne — même
  /// remarque que [updateDisplayName] : l'appelant ([OnboardingScreen])
  /// n'attend d'ailleurs jamais le résultat de cet appel pour naviguer (voir
  /// sa doc de classe), un échec réseau ici ne doit jamais bloquer la sortie
  /// de l'écran.
  Future<void> markOnboardingSeen();
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
  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final trimmedDisplayName = displayName?.trim();
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        // Clé `full_name` jamais vide (voir la doc de
        // `AuthRepository.signUp`) : pas de `data` du tout si le pseudo
        // n'a pas été renseigné, plutôt qu'une chaîne blanche stockée.
        data: trimmedDisplayName == null || trimmedDisplayName.isEmpty
            ? null
            : {'full_name': trimmedDisplayName},
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
  Future<void> signInWithGoogle() async {
    try {
      // `signInWithOAuth` construit l'URL /authorize localement (aucun
      // appel HTTP) puis délègue l'ouverture du navigateur à `launchUrl`
      // (package `url_launcher`), qui renvoie un `bool` plutôt que de
      // lever une exception quand aucune application ne peut gérer l'URL
      // (ex. aucun navigateur disponible) — ce retour doit être vérifié
      // explicitement, sinon la méthode se termine silencieusement sans
      // jamais ouvrir de navigateur ni signaler d'erreur à l'appelant.
      final launched = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'nexusjdr://login-callback/',
      );
      if (!launched) {
        throw const AuthFailure(
          "Impossible d'ouvrir le navigateur pour continuer avec Google. "
          'Réessayez.',
        );
      }
    } on AuthException catch (error) {
      throw mapAuthException(error);
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw mapUnknownError();
    }
  }

  /// **Non testable en conditions réelles tant que deux prérequis externes à
  /// ce dépôt ne sont pas réunis** (signalé au chef de projet plutôt que
  /// laissé comme un oubli silencieux) :
  /// 1. Le compte Apple Developer Program n'est pas encore créé — sans lui,
  ///    impossible d'activer la capacité "Sign In with Apple" sur l'App ID
  ///    côté portail developer.apple.com (voir aussi
  ///    `ios/Runner/Runner.entitlements`, qui déclare la capacité côté
  ///    projet Xcode mais ne peut pas être "vraie" côté Apple sans cette
  ///    activation).
  /// 2. Le fournisseur Apple n'est pas configuré côté dashboard Supabase
  ///    Auth (Authentication > Providers > Apple) — pour le flux natif
  ///    `idToken` utilisé ici, le "Client ID" attendu par Supabase est le
  ///    bundle identifier de l'app (pas un Services ID web), à renseigner
  ///    une fois le point 1 résolu.
  ///
  /// Flux natif recommandé par Supabase pour Flutter/iOS (contrairement à
  /// [signInWithGoogle], qui reste volontairement sur le flux web
  /// `signInWithOAuth`) :
  /// 1. Génère un nonce aléatoire ([_generateRawNonce]) et le hash en
  ///    SHA-256 — Apple renvoie ce hash dans le jeton d'identité signé qu'il
  ///    délivre, pour prouver que la réponse correspond bien à cette
  ///    requête précise (protection contre le replay) ; Supabase revérifie
  ///    lui-même ce hash côté serveur une fois le nonce brut transmis à
  ///    [signInWithIdToken] ci-dessous, donc ce dépôt n'a besoin de rien
  ///    vérifier localement.
  /// 2. Demande les scopes `email`/`fullName` via
  ///    `SignInWithApple.getAppleIDCredential` — Apple ne garantit ces
  ///    informations qu'à la toute première autorisation d'un utilisateur
  ///    donné pour cette app (comportement Apple documenté, pas un bug de ce
  ///    dépôt) : un utilisateur qui se déconnecte puis se reconnecte peut ne
  ///    plus recevoir `email`/`givenName`/`familyName`, Supabase retombe
  ///    alors sur les données déjà stockées côté `auth.users` lors de la
  ///    première connexion.
  /// 3. Transmet `identityToken` (jeton signé par Apple) et le nonce **brut**
  ///    (jamais le hash) à `signInWithIdToken` — c'est Supabase qui revérifie
  ///    le hash de ce nonce brut contre celui signé par Apple dans le jeton,
  ///    jamais ce dépôt.
  ///
  /// Annulation volontaire (l'utilisateur ferme la feuille système Apple) :
  /// le package lève une [SignInWithAppleAuthorizationException] avec
  /// `AuthorizationErrorCode.canceled` — traitée ici comme un simple retour
  /// silencieux (aucune exception propagée), jamais comme une
  /// [AuthFailure] générique "problème inconnu" : même convention que
  /// `BugReportScreenshotPicker.pick` (`features/bug_report/data/
  /// bug_report_screenshot_picker.dart`), qui traite de la même façon
  /// l'annulation d'un sélecteur natif. L'appelant (`login_screen.dart`) n'a
  /// donc rien de particulier à faire pour ce cas : pas de bandeau d'erreur,
  /// l'écran retombe simplement dans son état initial une fois l'appel
  /// résolu.
  @override
  Future<void> signInWithApple() async {
    final rawNonce = _generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final identityToken = credential.identityToken;
      if (identityToken == null) {
        // Ne devrait jamais se produire côté iOS (le SDK natif Apple fournit
        // toujours un jeton d'identité en cas de succès) — gardé comme repli
        // explicite plutôt qu'un `!` qui planterait l'app sur un cas limite
        // non documenté par Apple.
        throw mapUnknownError();
      }

      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: identityToken,
        nonce: rawNonce,
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      // Annulation volontaire : retour silencieux (voir la doc de la
      // méthode). Toute autre `AuthorizationErrorCode` (ex. `failed`,
      // `invalidResponse`) reste une vraie panne, mappée en erreur
      // générique.
      if (error.code == AuthorizationErrorCode.canceled) {
        return;
      }
      throw mapUnknownError();
    } on AuthException catch (error) {
      throw mapAuthException(error);
    } on AuthFailure {
      rethrow;
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

  @override
  Future<void> markOnboardingSeen() async {
    // Fusion par-dessus `user_metadata` existant — même mécanisme que
    // [updateDisplayName]/[updateAvatar] (voir leur doc), jamais un
    // écrasement.
    final existingMetadata = Map<String, dynamic>.from(
      _client.auth.currentUser?.userMetadata ?? const <String, dynamic>{},
    );
    existingMetadata['onboarding_completed'] = true;

    try {
      await _client.auth.updateUser(UserAttributes(data: existingMetadata));
    } on AuthException catch (error) {
      throw mapAuthException(error);
    } catch (_) {
      throw mapUnknownError();
    }
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

/// Caractères autorisés pour le nonce brut de
/// [SupabaseAuthRepository.signInWithApple] — alphanumérique uniquement,
/// suffisant pour un nonce (pas besoin de symboles spéciaux, qui
/// compliqueraient sans bénéfice un éventuel encodage côté transport).
const String _nonceCharset =
    '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

/// Génère un nonce aléatoire cryptographiquement sûr ([Random.secure], pas
/// [Random] par défaut qui n'offre aucune garantie cryptographique) pour
/// [SupabaseAuthRepository.signInWithApple] — voir sa doc de classe pour le
/// rôle exact de ce nonce dans le flux Apple/Supabase. 32 caractères : même
/// longueur que l'exemple du guide officiel Supabase pour ce flux.
String _generateRawNonce([int length = 32]) {
  final random = Random.secure();
  return List.generate(
    length,
    (_) => _nonceCharset[random.nextInt(_nonceCharset.length)],
  ).join();
}
