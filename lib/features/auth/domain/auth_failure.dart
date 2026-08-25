/// Échec d'authentification porteur d'un message déjà traduit et adapté à
/// l'affichage utilisateur final.
///
/// Le mapping depuis les erreurs brutes de Supabase (`AuthException`) vit
/// dans `data/auth_error_mapper.dart`, pour que ni l'UI ni les tests n'aient
/// jamais à afficher/interpréter un message d'erreur Supabase non traduit.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;

  @override
  bool operator ==(Object other) =>
      other is AuthFailure && other.message == message;

  @override
  int get hashCode => message.hashCode;
}
