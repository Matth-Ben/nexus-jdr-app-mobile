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
