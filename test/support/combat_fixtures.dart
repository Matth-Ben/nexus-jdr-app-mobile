import 'package:personnages/features/combat/domain/combat.dart';
import 'package:personnages/features/combat/domain/combat_enums.dart';
import 'package:personnages/features/combat/domain/combat_participant.dart';
import 'package:personnages/features/combat/domain/combat_snapshot.dart';

Combat fakeCombat({
  String id = 'combat-1',
  String groupId = 'group-1',
  CombatStatus status = CombatStatus.active,
  int round = 1,
  String? currentParticipantId,
}) => Combat(
  id: id,
  groupId: groupId,
  status: status,
  round: round,
  currentParticipantId: currentParticipantId,
);

CombatParticipant fakeParticipant(
  String id, {
  int? initiative,
  int sortOrder = 1,
  ParticipantKind kind = ParticipantKind.pc,
  ParticipantStatus status = ParticipantStatus.active,
  String? characterId,
  String? name,
  String combatId = 'combat-1',
}) => CombatParticipant(
  id: id,
  combatId: combatId,
  groupId: 'group-1',
  characterId: characterId,
  name: name ?? id,
  kind: kind,
  initiative: initiative,
  sortOrder: sortOrder,
  status: status,
);

CombatSnapshot fakeSnapshot({
  Combat? combat,
  List<CombatParticipant> participants = const [],
}) =>
    CombatSnapshot(combat: combat ?? fakeCombat(), participants: participants);
