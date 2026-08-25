/// Échec d'une opération de l'assistant de création de personnage (lecture
/// du catalogue races/sous-races, enregistrement d'une étape en brouillon),
/// porteur d'un message déjà traduit et adapté à l'affichage utilisateur
/// final.
///
/// Le mapping depuis les erreurs brutes de Supabase (`PostgrestException`)
/// vit dans `data/character_creation_error_mapper.dart` — même principe que
/// `CharacterFailure`/`features/characters/domain/character_failure.dart`,
/// dupliqué plutôt que réutilisé pour ne pas coupler les deux
/// fonctionnalités entre elles.
class CharacterCreationFailure implements Exception {
  const CharacterCreationFailure(this.message);

  final String message;

  @override
  String toString() => message;

  @override
  bool operator ==(Object other) =>
      other is CharacterCreationFailure && other.message == message;

  @override
  int get hashCode => message.hashCode;
}
