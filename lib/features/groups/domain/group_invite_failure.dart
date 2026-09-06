/// Catégorie d'échec renvoyée par `preview-group-invite`/`join-group` — en
/// miroir des codes `error` du contrat des deux edge functions
/// (`docs/cahier-des-charges/12-partage-et-groupes.md` section 2).
///
/// Plus restreint que `StoryInviteFailureKind` : **contrairement aux
/// histoires, un groupe n'a pas de notion "invitation désactivée"** — seule
/// erreur possible côté code, [invalidCode].
enum GroupInviteFailureKind {
  /// `error: "invalid_code"` (404) — code introuvable.
  invalidCode,

  /// `error: "already_in_group"` (409, `join-group` uniquement) — personnage
  /// déjà membre de ce groupe.
  alreadyInGroup,

  /// Tout le reste : erreur réseau, erreur serveur, ou toute exception qui
  /// n'est pas une réponse d'erreur JSON reconnue de l'edge function.
  generic,
}

/// Échec typé du flux "Rejoindre un groupe" — voir [GroupInviteFailureKind].
class GroupInviteFailure implements Exception {
  const GroupInviteFailure(this.kind, {this.serverMessage});

  final GroupInviteFailureKind kind;
  final String? serverMessage;

  @override
  String toString() => serverMessage ?? kind.name;

  @override
  bool operator ==(Object other) =>
      other is GroupInviteFailure &&
      other.kind == kind &&
      other.serverMessage == serverMessage;

  @override
  int get hashCode => Object.hash(kind, serverMessage);
}
