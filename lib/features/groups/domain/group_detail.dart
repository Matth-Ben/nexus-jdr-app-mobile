import 'package:freezed_annotation/freezed_annotation.dart';

import 'group_campaign_label.dart';
import 'group_member.dart';
import 'group_role.dart';

part 'group_detail.freezed.dart';

/// Détail complet d'un groupe, tel qu'affiché par l'écran "Groupe"
/// (`presentation/group_screen.dart`) — `docs/cahier-des-charges/
/// 12-partage-et-groupes.md` section 2.2.
@freezed
abstract class GroupDetail with _$GroupDetail {
  const GroupDetail._();

  const factory GroupDetail({
    required String id,
    required String name,
    required String ownerId,
    required String inviteCode,
    required String currentUserId,
    required List<GroupMember> members,

    /// `groups.story_title` brut : titre de la campagne associée, écrit par
    /// Grimoire. `null` : aucune campagne (ou colonne absente de DeepCore).
    String? storyTitle,

    /// `groups.story_summary_public` brut : résumé public de la campagne,
    /// lisible par les membres seulement. `null` : aucun résumé.
    String? storySummaryPublic,
  }) = _GroupDetail;

  bool get isOwner => ownerId == currentUserId;

  /// Titre affiché par la carte « Campagne » : `null` sans campagne ou
  /// s'il répète le nom du groupe (voir [GroupCampaignLabel.displayedTitle]).
  String? get campaignTitle => GroupCampaignLabel.displayedTitle(
    storyTitle: storyTitle,
    groupName: name,
  );

  /// Résumé affiché par la carte « Campagne » : `null` s'il est vide ou
  /// sans titre (voir [GroupCampaignLabel.displayedSummary]).
  String? get campaignSummary => GroupCampaignLabel.displayedSummary(
    storyTitle: storyTitle,
    storySummary: storySummaryPublic,
  );

  /// Carte « Campagne » affichée : un titre à montrer, ou à défaut un résumé
  /// (titre identique au nom du groupe, décision n° 36).
  bool get hasCampaignCard => campaignTitle != null || campaignSummary != null;

  /// `null` si le joueur connecté n'est plus membre de ce groupe (ne devrait
  /// pas arriver en pratique tant que cet écran reste ouvert : la RLS ne
  /// renverrait alors plus ce groupe du tout, voir
  /// `GroupRepository.fetchGroupDetail`).
  GroupMember? get currentMember {
    for (final member in members) {
      if (member.userId == currentUserId) return member;
    }
    return null;
  }

  GroupRole get currentUserRole => currentMember?.role ?? GroupRole.membre;

  /// « Devenir MJ » proposé : le joueur connecté est le **propriétaire** du
  /// groupe et y **joue un personnage** (ligne `group_members` avec
  /// personnage, donc pas MJ). Jamais pour un MJ (déjà MJ), un autre membre
  /// (`not_group_owner`), ni un propriétaire orphelin ou sans ligne membre.
  /// Le serveur reste l'autorité (`become_group_game_master`) : ce prédicat
  /// ne sert qu'à afficher l'action.
  bool get canBecomeGameMaster {
    final member = currentMember;
    return isOwner &&
        member != null &&
        member.characterId != null &&
        !member.isGameMaster;
  }

  /// Identifiants des lignes `group_members` ([GroupMember.membershipId])
  /// des membres actuels — voir `GroupRepository.subscribeToMemberUpdates`.
  Set<String> get memberRowIds => {
    for (final member in members) ?member.membershipId,
  };

  /// Identifiants de personnage de tous les membres — voir
  /// `GroupRepository.subscribeToMemberUpdates`. Un membre MJ sans
  /// personnage ([GroupMember.isGameMaster]) n'a pas de `characterId` : on
  /// retombe alors sur son `userId`, qui ne correspondra jamais à un
  /// `characters.id` réel (la table `characters` RLS-filtrée que
  /// `subscribeToMemberUpdates` écoute) — un identifiant inoffensif qui ne
  /// matchera simplement rien, plutôt qu'un `null` qui casserait `List<String>`.
  List<String> get memberCharacterIds =>
      members.map((member) => member.characterId ?? member.userId).toList();
}
