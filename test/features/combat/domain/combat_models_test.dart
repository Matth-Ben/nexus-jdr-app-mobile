import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/combat/domain/combat.dart';
import 'package:personnages/features/combat/domain/combat_enums.dart';
import 'package:personnages/features/combat/domain/combat_participant.dart';

void main() {
  test('Combat.fromJson lit la ligne combats', () {
    final combat = Combat.fromJson({
      'id': 'c1',
      'group_id': 'g1',
      'status': 'active',
      'round': 1,
      'current_participant_id': null,
      'started_by': 'u1',
      'created_at': '2026-11-14T09:00:00+00:00',
      'ended_at': null,
    });
    expect(combat.groupId, 'g1');
    expect(combat.status, CombatStatus.active);
    expect(combat.currentParticipantId, isNull);
    expect(combat.createdAt, DateTime.utc(2026, 11, 14, 9));
    expect(combat.isActive, isTrue);
  });

  test('CombatParticipant.fromJson lit la ligne et ne porte aucun PV', () {
    final p = CombatParticipant.fromJson({
      'id': 'p1',
      'combat_id': 'c1',
      'group_id': 'g1',
      'character_id': null,
      'user_id': null,
      'name': 'Gobelin 2',
      'kind': 'npc',
      'initiative': 14,
      'sort_order': 3,
      'status': 'waiting',
    });
    expect(p.kind, ParticipantKind.npc);
    expect(p.status, ParticipantStatus.waiting);
    expect(p.initiative, 14);
    expect(p.toJson().keys, isNot(contains('hp')));
    expect(p.toJson().keys.any((k) => k.contains('hp')), isFalse);
  });
}
