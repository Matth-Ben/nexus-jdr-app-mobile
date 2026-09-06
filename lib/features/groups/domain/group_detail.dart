import 'package:freezed_annotation/freezed_annotation.dart';

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
  }) = _GroupDetail;

  bool get isOwner => ownerId == currentUserId;

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

  /// Identifiants de personnage de tous les membres — voir
  /// `GroupRepository.subscribeToMemberUpdates`.
  List<String> get memberCharacterIds =>
      members.map((member) => member.characterId).toList();
}
