/// Catégorie d'échec renvoyée par `preview-story-invite`/`join-story` (voir
/// `data/story_invite_repository.dart`), en miroir des codes `error` du
/// contrat des deux edge functions
/// (`docs/cahier-des-charges/12-partage-et-groupes.md` section 5).
///
/// Un type d'énumération (plutôt qu'un simple message déjà traduit, comme
/// [CharacterFailure]) : contrairement au reste de l'app, les écrans de ce
/// flux ont besoin de distinguer le cas précisément pour choisir une action
/// différente selon le contexte (ex. bouton "Modifier le code" uniquement
/// pour [invalidCode]/[inviteDisabled], jamais pour [generic]) — voir la
/// spec visuelle des étapes 2 et 3/4.
enum StoryInviteFailureKind {
  /// `error: "invalid_code"` (404) — code introuvable.
  invalidCode,

  /// `error: "invite_disabled"` (403) — code existant mais invitation
  /// désactivée par le MJ.
  inviteDisabled,

  /// `error: "character_not_owned"` (403, `join-story` uniquement) —
  /// personnage sélectionné n'appartenant pas au joueur connecté. Ne devrait
  /// jamais arriver en pratique (l'étape 3/4 ne propose que les personnages
  /// du joueur connecté, voir `charactersProvider`) : traité comme
  /// [generic] côté affichage, pas de libellé dédié dans la spec visuelle.
  characterNotOwned,

  /// `error: "already_joined"` (409, `join-story` uniquement) — personnage
  /// déjà rattaché à cette histoire.
  alreadyJoined,

  /// Tout le reste : erreur réseau, `internal_error`/`invalid_body` serveur,
  /// ou toute exception qui n'est pas une réponse d'erreur JSON reconnue de
  /// l'edge function.
  generic,
}

/// Échec typé du flux "Rejoindre une histoire" — voir [StoryInviteFailureKind]
/// pour le détail de chaque catégorie. [serverMessage] porte le message déjà
/// traduit renvoyé par le serveur quand disponible (jamais affiché tel quel
/// pour [StoryInviteFailureKind.invalidCode]/[inviteDisabled] à l'étape 2,
/// qui ont leur propre copie dédiée — voir la spec visuelle — mais utile pour
/// le diagnostic et pour les cas non explicitement mis en forme par l'écran).
class StoryInviteFailure implements Exception {
  const StoryInviteFailure(this.kind, {this.serverMessage});

  final StoryInviteFailureKind kind;
  final String? serverMessage;

  @override
  String toString() => serverMessage ?? kind.name;

  // Même patron que `CharacterFailure`
  // (`features/characters/domain/character_failure.dart`) — utile en test
  // (comparaison directe d'une exception attendue) et pour toute future
  // déduplication.
  @override
  bool operator ==(Object other) =>
      other is StoryInviteFailure &&
      other.kind == kind &&
      other.serverMessage == serverMessage;

  @override
  int get hashCode => Object.hash(kind, serverMessage);
}
