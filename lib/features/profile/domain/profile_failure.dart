/// Code d'erreur stable associé à une [ProfileFailure].
///
/// **Précédent** : même rationale exacte que `AuthErrorCode`
/// (`features/auth/domain/auth_failure.dart`, chantier "traduction de
/// l'app" Phase B, lot "Auth") — `data/notification_preferences_repository
/// .dart` vit dans la couche `data/` et n'a donc jamais accès à un
/// `BuildContext`/`AppLocalizations.of(context)`. [ProfileFailure] garde
/// donc la responsabilité de choisir un [code] (cet enum) à partir de la
/// situation rencontrée — un simple identifiant stable, sans aucun texte —
/// et c'est à la couche `presentation/` de résoudre le texte final affiché,
/// via `AppLocalizations` (elle, a accès à `context`), le jour où un
/// appelant aura besoin d'afficher ce message précis à l'utilisateur.
///
/// À ce jour, aucun appelant de ce dépôt n'affiche
/// [ProfileFailure.message] à l'utilisateur (`SupabaseNotificationPreferencesRepository
/// ._requireOwnerId`, seul site qui lève cette exception, est systématiquement
/// intercepté par un `catch` générique qui affiche un message différent,
/// voir `presentation/profile_notifications_screen.dart::_toggle`) : [code]
/// reste donc pour l'instant un pur relevé d'intention, posé en même temps
/// que [message] pour que le jour où un appelant aura besoin du texte
/// précis, il lise [code] plutôt que de dupliquer un texte français en dur
/// à cet endroit — même consigne que celle documentée par `AuthErrorCode`
/// pour les futurs lots.
enum ProfileErrorCode {
  /// Session expirée — l'utilisateur doit se reconnecter pour continuer.
  /// Levée par `SupabaseNotificationPreferencesRepository._requireOwnerId`
  /// quand `_client.auth.currentUser` est `null`.
  sessionExpired,

  /// Tout le reste : aucun autre cas à ce jour.
  generic,
}

/// Échec porteur d'un message déjà traduit et adapté à l'affichage
/// utilisateur final ([message]), ainsi que d'un [code] stable permettant
/// une résolution localisée côté `presentation/` — voir la doc de classe
/// d'[ProfileErrorCode] pour le choix architectural complet. Même contrat
/// exact que `features/characters/domain/character_failure.dart::CharacterFailure`/
/// `features/auth/domain/auth_failure.dart::AuthFailure`, dupliqué ici plutôt
/// que réutilisé pour ne pas faire dépendre `features/profile/` de
/// `features/characters/`/`features/auth/` pour un simple message d'erreur.
class ProfileFailure implements Exception {
  const ProfileFailure(this.message, {this.code = ProfileErrorCode.generic});

  final String message;

  /// Voir la doc de classe d'[ProfileErrorCode].
  final ProfileErrorCode code;

  @override
  String toString() => message;

  @override
  bool operator ==(Object other) =>
      other is ProfileFailure && other.message == message && other.code == code;

  @override
  int get hashCode => Object.hash(message, code);
}
