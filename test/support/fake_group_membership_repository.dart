import 'dart:async';

import 'package:personnages/features/groups/data/group_membership_repository.dart';

/// Groupes du joueur pilotés par le test : [memberships] (la liste renvoyée),
/// [error] (échec de lecture, ex. hors ligne), [gate] (lecture lente).
class FakeGroupMembershipRepository implements GroupMembershipRepository {
  FakeGroupMembershipRepository([List<GroupMembership>? memberships])
    : memberships = memberships ?? [];

  List<GroupMembership> memberships;
  Object? error;
  Completer<void>? gate;
  int reads = 0;

  @override
  Future<List<GroupMembership>> fetchMyMemberships() async {
    reads++;
    final pending = gate;
    if (pending != null) await pending.future;
    final failure = error;
    if (failure != null) throw failure;
    return List.of(memberships);
  }
}

/// Appartenance de test (`characterId` : personnage courant dans le groupe ;
/// [linked] : groupe associé à une campagne de Grimoire, `story_title` posé ;
/// [owned] : le compte en est propriétaire, donc meneur).
GroupMembership membership(
  String groupId, {
  String? name,
  String? characterId = 'c-player',
  bool linked = true,
  bool owned = false,
}) => (
  groupId: groupId,
  groupName: name ?? 'Groupe $groupId',
  characterId: characterId,
  grimoireLinked: linked,
  ownedByMe: owned,
);
