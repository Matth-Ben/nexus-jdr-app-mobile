/// Code d'erreur stable associé à une [AuthFailure].
///
/// **Choix architectural** (chantier "traduction de l'app" Phase B, lot
/// "Auth") : `data/auth_error_mapper.dart` vit dans la couche `data/` et n'a
/// donc jamais accès à un `BuildContext`/`AppLocalizations.of(context)`. La
/// solution Flutter standard — faire remonter `AppLocalizations` en
/// paramètre jusqu'au point de production du message — aurait obligé à
/// changer la signature de `AuthRepository` (toutes ses méthodes) puisque
/// c'est elle qui appelle `mapAuthException` ; or `AuthRepository` est aussi
/// utilisée par plusieurs écrans hors du périmètre de ce lot
/// (`features/profile/presentation/widgets/change_password_sheet.dart`,
/// `change_email_sheet.dart`, `profile_delete_account_screen.dart`,
/// `profile_edit_screen.dart`, `avatar_edit_sheet.dart`,
/// `edit_display_name_sheet.dart`...), qu'il n'était pas question de
/// toucher pour ce lot.
///
/// À la place : `auth_error_mapper.dart` garde la responsabilité de choisir
/// un [code] (cet enum) à partir de l'erreur Supabase brute — un simple
/// identifiant stable, sans aucun texte — et c'est la couche
/// `presentation/` qui résout le texte final affiché, via
/// `AppLocalizations` (elle, a accès à `context`). [message] reste produit
/// en parallèle (texte français déjà construit, comportement inchangé)
/// pour que tous les appelants qui n'ont pas encore été migrés continuent
/// de fonctionner sans aucune modification : seul
/// `lib/features/auth/presentation/login_screen.dart` lit [code] à ce
/// stade, tous les autres écrans cités ci-dessus continuent de lire
/// [message] directement.
///
/// **Précédent pour les prochains lots** : chaque futur lot qui migre un
/// écran consommant une [AuthFailure] doit lire [code] (en complétant cet
/// enum si besoin) plutôt que [message], jusqu'à ce que plus aucun appelant
/// ne dépende de [message] — qui pourra alors être retiré.
enum AuthErrorCode {
  /// Identifiants de connexion incorrects (email ou mot de passe).
  invalidCredentials,

  /// Un compte existe déjà avec l'adresse e-mail saisie à l'inscription.
  emailAlreadyExists,

  /// Mot de passe refusé par Supabase car trop court (`weak_password`) —
  /// distinct de la validation locale faite avant tout appel réseau, voir
  /// `domain/auth_validators.dart`.
  weakPassword,

  /// Compte existant mais adresse e-mail non confirmée.
  emailNotConfirmed,

  /// Adresse e-mail refusée côté serveur (`validation_failed`) — distinct
  /// de la validation locale, voir `domain/auth_validators.dart`.
  invalidEmail,

  /// Trop de tentatives sur une courte période (`over_request_rate_limit`/
  /// `over_email_send_rate_limit`).
  tooManyRequests,

  /// Erreur survenue avant toute réponse HTTP (absence de réseau...), voir
  /// `mapUnknownError`.
  network,

  /// Tout le reste : code Supabase non mappé explicitement, ou erreur sans
  /// code exploitable. [AuthFailure.message] reste dans ce cas la seule
  /// source de texte utilisable (repli sur le message brut de Supabase ou
  /// un message générique, voir `mapAuthException`).
  generic,
}

/// Échec d'authentification porteur d'un message déjà traduit et adapté à
/// l'affichage utilisateur final ([message]), ainsi que d'un [code] stable
/// permettant une résolution localisée côté `presentation/` — voir la doc
/// de classe d'[AuthErrorCode] pour le choix architectural complet.
///
/// Le mapping depuis les erreurs brutes de Supabase (`AuthException`) vit
/// dans `data/auth_error_mapper.dart`, pour que ni l'UI ni les tests n'aient
/// jamais à afficher/interpréter un message d'erreur Supabase non traduit.
class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.code = AuthErrorCode.generic});

  final String message;

  /// Voir la doc de classe d'[AuthErrorCode].
  final AuthErrorCode code;

  @override
  String toString() => message;

  @override
  bool operator ==(Object other) =>
      other is AuthFailure && other.message == message && other.code == code;

  @override
  int get hashCode => Object.hash(message, code);
}
