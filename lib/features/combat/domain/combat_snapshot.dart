import 'package:freezed_annotation/freezed_annotation.dart';

import '../../groups/domain/group_member.dart';
import 'combat.dart';
import 'combat_enums.dart';
import 'combat_participant.dart';

part 'combat_snapshot.freezed.dart';

/// Ordre d'affichage unique du client : initiative décroissante (`null` en
/// dernier), puis `sort_order` croissant. Le serveur place déjà les PJ avant
/// les PNJ puis l'ordre d'arrivée dans `sort_order` : le client n'a **aucune**
/// autre règle de tri. Le tri est stable (à clés identiques, l'ordre fourni
/// est conservé) et ne modifie pas la liste source.
extension CombatParticipantsOrdering on Iterable<CombatParticipant> {
  List<CombatParticipant> get sortedForDisplay {
    final indexed = toList().asMap().entries.toList();
    indexed.sort((a, b) {
      final left = a.value;
      final right = b.value;
      final leftInitiative = left.initiative;
      final rightInitiative = right.initiative;
      if (leftInitiative != rightInitiative) {
        if (leftInitiative == null) return 1;
        if (rightInitiative == null) return -1;
        return rightInitiative.compareTo(leftInitiative);
      }
      final byOrder = left.sortOrder.compareTo(right.sortOrder);
      if (byOrder != 0) return byOrder;
      return a.key.compareTo(b.key);
    });
    return [for (final entry in indexed) entry.value];
  }
}

/// Combat d'un groupe et ses participants, tel que lu en un seul aller-retour
/// (`CombatRepository.fetchActiveCombat`).
@freezed
abstract class CombatSnapshot with _$CombatSnapshot {
  const CombatSnapshot._();

  const factory CombatSnapshot({
    required Combat combat,
    required List<CombatParticipant> participants,
  }) = _CombatSnapshot;

  /// Participants actifs (en jeu), dans l'ordre d'affichage.
  List<CombatParticipant> get activeParticipants => participants
      .where((p) => p.status == ParticipantStatus.active)
      .sortedForDisplay;

  /// Participants mis en attente, dans l'ordre d'affichage.
  List<CombatParticipant> get waitingParticipants => participants
      .where((p) => p.status == ParticipantStatus.waiting)
      .sortedForDisplay;

  /// Participants retirés (jamais affichés dans la liste principale).
  List<CombatParticipant> get removedParticipants => participants
      .where((p) => p.status == ParticipantStatus.removed)
      .sortedForDisplay;

  /// Participants visibles (actifs + en attente), dans l'ordre d'affichage.
  List<CombatParticipant> get displayParticipants => participants
      .where((p) => p.status != ParticipantStatus.removed)
      .sortedForDisplay;

  /// Initiatives saisies sur le total de participants non retirés
  /// (« 2/4 »).
  ({int entered, int total}) get initiativeProgress {
    final visible = participants.where((p) => !p.isRemoved).toList();
    return (
      entered: visible.where((p) => p.hasInitiative).length,
      total: visible.length,
    );
  }

  /// « Tour en cours » : lu depuis le serveur, jamais calculé. `null` si
  /// `current_participant_id` est `null`, inconnu ou pointe un participant
  /// retiré.
  CombatParticipant? get currentParticipant {
    final id = combat.currentParticipantId;
    if (id == null) return null;
    for (final participant in participants) {
      if (participant.id == id) {
        return participant.isRemoved ? null : participant;
      }
    }
    return null;
  }

  /// Membres avec personnage qui n'ont pas encore de ligne participant
  /// (arrivés après le lancement, ou personnage changé) : le client les
  /// tolère. Un participant retiré compte comme « a une ligne » (il n'est pas
  /// réintégré dans le même combat).
  List<GroupMember> membersWithoutRow(Iterable<GroupMember> members) {
    final characterIds = {
      for (final participant in participants) ?participant.characterId,
    };
    return [
      for (final member in members)
        if (member.characterId != null &&
            !characterIds.contains(member.characterId))
          member,
    ];
  }
}
