/// Catégorie d'échec renvoyée par `set-group-character` — en miroir des
/// codes `error` du contrat de l'edge function (voir la doc de
/// `GroupRepository.setGroupCharacter`).
///
/// Type dédié (plutôt que de réutiliser [GroupInviteFailureKind]) : cette
/// edge function sert un usage radicalement différent (rattacher un nouveau
/// personnage à une ligne `group_members` ORPHELINE existante, jamais créer
/// d'adhésion) et porte 2 natures d'échec qui n'ont pas d'équivalent côté
/// `preview-group-invite`/`join-group` ([characterNotOwned], [notMember],
/// [notEligible]).
enum GroupCharacterReassignmentFailureKind {
  /// `error: "character_not_owned"` (403) — le personnage choisi
  /// n'appartient pas au joueur connecté.
  characterNotOwned,

  /// `error: "not_member"` (404) — le joueur connecté n'a pas de ligne
  /// `group_members` pour ce groupe.
  notMember,

  /// `error: "not_eligible"` (409) — la ligne `group_members` du joueur
  /// connecté n'est pas orpheline (a déjà un personnage, ou est MJ
  /// volontaire) : cette edge function ne sert jamais à changer de
  /// personnage à volonté, ni à "devenir MJ".
  notEligible,

  /// `error: "already_in_group"` (409) — le personnage choisi est déjà
  /// membre de ce groupe sous une autre ligne `group_members`.
  alreadyInGroup,

  /// Tout le reste : erreur réseau, erreur serveur, ou toute exception qui
  /// n'est pas une réponse d'erreur JSON reconnue de l'edge function.
  generic,
}

/// Échec typé du rattachement d'un nouveau personnage par un membre orphelin
/// (`GroupCharacterReassignmentScreen`) — voir
/// [GroupCharacterReassignmentFailureKind].
class GroupCharacterReassignmentFailure implements Exception {
  const GroupCharacterReassignmentFailure(this.kind, {this.serverMessage});

  final GroupCharacterReassignmentFailureKind kind;
  final String? serverMessage;

  @override
  String toString() => serverMessage ?? kind.name;

  @override
  bool operator ==(Object other) =>
      other is GroupCharacterReassignmentFailure &&
      other.kind == kind &&
      other.serverMessage == serverMessage;

  @override
  int get hashCode => Object.hash(kind, serverMessage);
}
