/// Code d'erreur stable associé à une [CharacterFailure].
///
/// **Choix architectural** (chantier "traduction de l'app" Phase B, lot
/// "Characters — liste") : même rationale exacte qu'`AuthErrorCode`
/// (`features/auth/domain/auth_failure.dart`) et `ProfileErrorCode`
/// (`features/profile/domain/profile_failure.dart`) — `data/character_error_mapper.dart`
/// vit dans la couche `data/` et n'a donc jamais accès à un
/// `BuildContext`/`AppLocalizations.of(context)`. `CharacterFailure` garde
/// donc la responsabilité de choisir un [code] (cet enum) à partir de
/// l'erreur Supabase brute — un simple identifiant stable, sans aucun texte —
/// et c'est à la couche `presentation/` de résoudre le texte final affiché,
/// via `AppLocalizations` (elle, a accès à `context`). [message] reste
/// produit en parallèle (texte français déjà construit, comportement
/// inchangé) pour que tous les appelants qui n'ont pas encore été migrés
/// continuent de fonctionner sans aucune modification : seul
/// `lib/features/characters/presentation/widgets/character_card_action_sheet.dart`
/// lit [code] à ce stade (actions "Archiver"/"Marquer comme mort"/
/// "Supprimer" de la liste de personnages), tous les autres appelants de ce
/// dépôt (`character_detail_screen.dart`, `level_up_screen.dart`...)
/// continuent de lire [message] directement — voir D141 du registre de
/// dette technique (`docs/dette-technique.md`).
///
/// **Précédent pour les prochains lots** : chaque futur lot qui migre un
/// écran consommant une [CharacterFailure] doit lire [code] (en complétant
/// cet enum si besoin) plutôt que [message], jusqu'à ce que plus aucun
/// appelant ne dépende de [message] — qui pourra alors être retiré.
enum CharacterErrorCode {
  /// Code Postgres générique de refus RLS (`42501`) — voir
  /// `data/character_error_mapper.dart::mapCharacterError`.
  accessDenied,

  /// Erreur survenue avant toute réponse HTTP (absence de réseau...), voir
  /// `data/character_error_mapper.dart::mapUnknownCharacterError`.
  network,

  /// Tout le reste : code Postgrest non mappé explicitement, ou erreur sans
  /// code exploitable, ou `CharacterFailure` construite directement par un
  /// appelant qui ne précise pas [code]. [CharacterFailure.message] reste
  /// dans ce cas la seule source de texte utilisable.
  generic,
}

/// Échec de récupération/manipulation des personnages, porteur d'un message
/// déjà traduit et adapté à l'affichage utilisateur final ([message]), ainsi
/// que d'un [code] stable permettant une résolution localisée côté
/// `presentation/` — voir la doc de classe d'[CharacterErrorCode] pour le
/// choix architectural complet.
///
/// Le mapping depuis les erreurs brutes de Supabase (`PostgrestException`)
/// vit dans `data/character_error_mapper.dart` — même principe que
/// `AuthFailure`/`features/auth/data/auth_error_mapper.dart`.
class CharacterFailure implements Exception {
  const CharacterFailure(
    this.message, {
    this.code = CharacterErrorCode.generic,
  });

  final String message;

  /// Voir la doc de classe d'[CharacterErrorCode].
  final CharacterErrorCode code;

  @override
  String toString() => message;

  @override
  bool operator ==(Object other) =>
      other is CharacterFailure &&
      other.message == message &&
      other.code == code;

  @override
  int get hashCode => Object.hash(message, code);
}
