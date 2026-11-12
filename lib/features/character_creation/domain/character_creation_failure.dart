/// Code d'erreur stable d'une [CharacterCreationFailure] (D141), traduit côté
/// présentation.
enum CharacterCreationErrorCode {
  /// Refus RLS (`42501`).
  accessDenied,

  /// Erreur avant toute réponse HTTP (absence de réseau...).
  network,

  /// Aucune session active pendant la création d'un personnage.
  sessionExpiredCreate,

  /// Aucune session active pendant la modification d'un personnage.
  sessionExpiredEdit,

  /// Aucune session active pendant l'import d'un personnage.
  sessionExpiredImport,

  /// Personnage à modifier introuvable.
  characterNotFound,

  /// Tout le reste : [CharacterCreationFailure.message] fait foi.
  generic,
}

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
///
/// [code] (D141) est un identifiant stable résolu en texte localisé par la
/// couche `presentation/` (`presentation/character_creation_failure_l10n.dart`) ;
/// [message] (français) ne sert que pour [CharacterCreationErrorCode.generic]
/// (message brut du serveur ou repli propre à l'opération).
class CharacterCreationFailure implements Exception {
  const CharacterCreationFailure(
    this.message, {
    this.code = CharacterCreationErrorCode.generic,
  });

  final String message;

  /// Voir [CharacterCreationErrorCode].
  final CharacterCreationErrorCode code;

  @override
  String toString() => message;

  @override
  bool operator ==(Object other) =>
      other is CharacterCreationFailure &&
      other.message == message &&
      other.code == code;

  @override
  int get hashCode => Object.hash(message, code);
}
