/// Échec porteur d'un message déjà traduit et adapté à l'affichage
/// utilisateur final — même contrat exact que
/// `features/characters/domain/character_failure.dart::CharacterFailure`/
/// `features/auth/domain/auth_failure.dart::AuthFailure`, dupliqué ici plutôt
/// que réutilisé pour ne pas faire dépendre `features/profile/` de
/// `features/characters/`/`features/auth/` pour un simple message d'erreur.
class ProfileFailure implements Exception {
  const ProfileFailure(this.message);

  final String message;

  @override
  String toString() => message;

  @override
  bool operator ==(Object other) =>
      other is ProfileFailure && other.message == message;

  @override
  int get hashCode => message.hashCode;
}
