/// Échec de récupération/manipulation des personnages, porteur d'un message
/// déjà traduit et adapté à l'affichage utilisateur final.
///
/// Le mapping depuis les erreurs brutes de Supabase (`PostgrestException`)
/// vit dans `data/character_error_mapper.dart` — même principe que
/// `AuthFailure`/`features/auth/data/auth_error_mapper.dart`.
class CharacterFailure implements Exception {
  const CharacterFailure(this.message);

  final String message;

  @override
  String toString() => message;

  @override
  bool operator ==(Object other) =>
      other is CharacterFailure && other.message == message;

  @override
  int get hashCode => message.hashCode;
}
