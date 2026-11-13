import '../../groups/domain/group_detail.dart';
import 'combat_enums.dart';
import 'combat_participant.dart';
import 'combat_permissions.dart';
import 'combat_snapshot.dart';

/// Ce que le joueur courant peut faire de **sa** initiative dans un combat
/// actif (`set_my_initiative`).
enum PlayerInitiativeAccess {
  /// Pas concerné : propriétaire/MJ (il pilote via les contrôles du MJ), non
  /// membre ou membre MJ.
  notAPlayer,

  /// Membre sans personnage : le serveur répondrait `no_character`, aucune
  /// action n'est proposée.
  noCharacter,

  /// MJ absent : lecture seule pour tous, y compris sa propre initiative
  /// (`gm_absent`) ; l'action reste visible mais désactivée avec un indice.
  masterAbsent,

  /// Le MJ a retiré la ligne de son personnage courant (jamais réintégrée
  /// dans le même combat en V1 : `participant_removed`).
  removed,

  /// Saisie permise (la ligne existe, ou sera créée paresseusement par le
  /// serveur au premier appel).
  allowed,
}

/// Éligibilité du joueur courant et sa ligne de combat.
typedef PlayerInitiativeStatus = ({
  PlayerInitiativeAccess access,
  CombatParticipant? row,
});

/// Calcule [PlayerInitiativeStatus] pour l'utilisateur courant de [group].
///
/// La ligne « à lui » est celle de **son personnage courant** (`group_members`
/// `character_id`) : un personnage changé A→B→A peut laisser une ligne
/// retirée d'un ancien personnage sans que la saisie soit refusée. Une ligne
/// absente (membre arrivé après le lancement, personnage changé) est tolérée :
/// le serveur la crée au premier `set_my_initiative`.
///
/// Le serveur reste l'autorité (`participant_removed`, `gm_absent`,
/// `no_character`...) : ce calcul décide seulement de ce que l'UI propose.
PlayerInitiativeStatus playerInitiativeStatus(
  CombatSnapshot snapshot,
  GroupDetail group,
) {
  final member = group.currentMember;
  if (member == null || group.isOwner || member.isGameMaster) {
    return (access: PlayerInitiativeAccess.notAPlayer, row: null);
  }
  final characterId = member.characterId;
  if (characterId == null) {
    return (access: PlayerInitiativeAccess.noCharacter, row: null);
  }
  CombatParticipant? row;
  for (final participant in snapshot.participants) {
    if (participant.userId == group.currentUserId &&
        participant.characterId == characterId &&
        participant.kind == ParticipantKind.pc) {
      row = participant;
      break;
    }
  }
  if (row != null && row.isRemoved) {
    return (access: PlayerInitiativeAccess.removed, row: row);
  }
  if (isCombatMasterAbsent(group)) {
    return (access: PlayerInitiativeAccess.masterAbsent, row: row);
  }
  return (access: PlayerInitiativeAccess.allowed, row: row);
}

/// `true` si [participant] est **la ligne du joueur courant** et qu'il peut
/// proposer d'en éditer l'initiative (« Renseigner », « Modifier mon
/// initiative »). Jamais la ligne d'un autre joueur, d'un PNJ ni d'une ligne
/// retirée. `masterAbsent` reste « éditable » : l'action est affichée mais
/// désactivée par l'appelant.
bool isOwnEditableRow(
  PlayerInitiativeStatus status,
  CombatParticipant participant,
) {
  final row = status.row;
  if (row == null || row.id != participant.id || participant.isRemoved) {
    return false;
  }
  return status.access == PlayerInitiativeAccess.allowed ||
      status.access == PlayerInitiativeAccess.masterAbsent;
}

/// `true` s'il faut proposer « Renseigner mon initiative » en dehors de la
/// liste : joueur éligible dont la ligne n'existe pas encore.
bool shouldOfferFirstInitiative(PlayerInitiativeStatus status) =>
    status.row == null &&
    (status.access == PlayerInitiativeAccess.allowed ||
        status.access == PlayerInitiativeAccess.masterAbsent);

/// `true` si le personnage courant du joueur a été retiré du combat (message
/// « Le MJ t'a retiré de ce combat »).
bool wasRemovedFromCombat(PlayerInitiativeStatus status) =>
    status.access == PlayerInitiativeAccess.removed;
