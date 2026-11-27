/// Code d'erreur stable d'une [GroupFailure] (D141), traduit côté
/// présentation.
enum GroupErrorCode {
  /// Refus RLS (`42501`).
  accessDenied,

  /// Erreur avant toute réponse HTTP, ou réponse sans message exploitable.
  network,

  /// Groupe absent ou supprimé entre-temps.
  groupNotFound,

  /// Aucune session Supabase active.
  sessionExpired,

  /// Aucun code d'invitation libre trouvé après les tentatives.
  inviteCodeGenerationFailed,

  /// `combat_active` (P0001) : un combat est en cours dans le groupe. Le
  /// serveur refuse alors la dissolution, le départ du propriétaire et
  /// « Devenir MJ » (migration DeepCore `20261119090000`). L'appelant affiche
  /// le message propre à son action quand il en a un.
  combatActive,

  /// `mj_already_assigned` (P0001) : un autre membre est déjà MJ sans
  /// personnage dans ce groupe. Personne n'est rétrogradé automatiquement.
  mjAlreadyAssigned,

  /// `not_group_owner` (42501) : action réservée au propriétaire du groupe.
  notGroupOwner,

  /// `not_member` (P0002) : le joueur connecté n'a plus de ligne
  /// `group_members` dans ce groupe.
  notMember,

  /// Conflit transitoire de la base (`40P01` interblocage, `40001`
  /// sérialisation) : la transaction a été annulée sans effet, il suffit de
  /// réessayer.
  transientConflict,

  /// La fonction serveur appelée n'existe pas encore (`PGRST202` : migration
  /// DeepCore pas encore appliquée sur ce projet).
  serverOutdated,

  /// Butin commun modifié entre-temps par un autre membre (objet modifié,
  /// attribué ou retiré, monnaie changée) : rien n'a été écrit, l'appelant
  /// recharge le butin (décision 91).
  treasureStale,

  /// Tout le reste : [GroupFailure.message] (brut) fait foi.
  generic,
}

/// Échec de récupération/manipulation d'un groupe, porteur d'un message déjà
/// traduit et adapté à l'affichage utilisateur final — même principe que
/// `CharacterFailure`/`StoryInviteFailure`.
///
/// [code] (D141) est un identifiant stable résolu en texte localisé par la
/// couche `presentation/` (`presentation/group_failure_l10n.dart`) ;
/// [message] (français) ne sert que pour [GroupErrorCode.generic] (message
/// brut du serveur).
class GroupFailure implements Exception {
  const GroupFailure(this.message, {this.code = GroupErrorCode.generic});

  final String message;

  /// Voir [GroupErrorCode].
  final GroupErrorCode code;

  @override
  String toString() => message;

  @override
  bool operator ==(Object other) =>
      other is GroupFailure && other.message == message && other.code == code;

  @override
  int get hashCode => Object.hash(message, code);
}
