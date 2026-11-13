import 'combat_view_state.dart';

enum CombatAnnouncementKind {
  /// « Round N. Tour de X. »
  turn,

  /// « C'est ton tour. »
  yourTurn,

  /// « Le combat est terminé. »
  ended,
}

/// Annonce sémantique polie à émettre pour un changement **reçu**.
typedef CombatAnnouncement = ({
  CombatAnnouncementKind kind,
  int? round,
  String? name,
});

/// Décide s'il faut annoncer le passage de [previous] à [next]. Jamais au
/// chargement : il faut un état actif connu avant le changement (un passage
/// `loading`/`none`/`error` → `active` est un chargement, pas un changement).
/// Seuls un nouveau round/tour actif ou la fin du combat sont annoncés ; un
/// simple changement d'initiative ou de péremption ne l'est pas.
CombatAnnouncement? combatAnnouncementFor({
  required CombatViewState previous,
  required CombatViewState next,
  String? currentUserId,
}) {
  if (previous.phase != CombatPhase.active || previous.snapshot == null) {
    return null;
  }
  if (next.phase == CombatPhase.ended) {
    return (kind: CombatAnnouncementKind.ended, round: null, name: null);
  }
  final nextSnapshot = next.snapshot;
  if (next.phase != CombatPhase.active || nextSnapshot == null) return null;
  final before = previous.snapshot!;
  final changed =
      before.combat.round != nextSnapshot.combat.round ||
      before.combat.currentParticipantId !=
          nextSnapshot.combat.currentParticipantId;
  final current = nextSnapshot.currentParticipant;
  if (!changed || current == null) return null;
  final mine = currentUserId != null && current.userId == currentUserId;
  return (
    kind: mine ? CombatAnnouncementKind.yourTurn : CombatAnnouncementKind.turn,
    round: nextSnapshot.combat.round,
    name: current.name,
  );
}
