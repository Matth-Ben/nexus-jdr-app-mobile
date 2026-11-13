import '../../groups/domain/group_detail.dart';

/// Règle « puis-je lancer un combat ? » (PR web #47, `no_game_master`) :
/// le MJ dans l'app est le **propriétaire du groupe ET** porteur d'une ligne
/// `group_members` avec `is_game_master = true` (MJ sans personnage). Un
/// propriétaire qui joue avec un personnage, ou un membre MJ non propriétaire,
/// ne peut pas lancer. Réutilise [GroupDetail.isOwner] et
/// [GroupMember.isGameMaster] (aucune logique dupliquée).
///
/// Le serveur reste l'autorité (`not_group_owner` / `no_game_master`) : ce
/// prédicat ne sert qu'à masquer l'action dans l'UI.
bool canStartCombat(GroupDetail group) {
  final member = group.currentMember;
  return group.isOwner && member != null && member.isGameMaster;
}

/// Seul le propriétaire du groupe peut terminer un combat, même sans ligne
/// membre (MJ absent).
bool canEndCombat(GroupDetail group) => group.isOwner;

/// Le propriétaire du groupe ne peut pas **quitter** le groupe pendant un
/// combat actif (décision du 12/11/2026 : « MJ absent » = lecture seule pour
/// tous). Un membre non propriétaire peut toujours partir (sa ligne
/// participant est retirée côté serveur).
bool isLeaveBlockedByCombat({
  required bool isOwner,
  required bool hasActiveCombat,
}) => isOwner && hasActiveCombat;

/// « MJ absent » : le propriétaire n'a plus de ligne `group_members` avec
/// `is_game_master` (il a quitté, ou n'est plus MJ). Le combat reste lisible
/// (« En attente du MJ »), seul le propriétaire peut encore le terminer.
bool isCombatMasterAbsent(GroupDetail group) => !group.members.any(
  (member) => member.userId == group.ownerId && member.isGameMaster,
);
