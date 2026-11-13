import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/combat/data/combat_error_mapper.dart';
import 'package:personnages/features/combat/domain/combat_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const cases = <String, (String, CombatFailureKind)>{
    'not_authenticated': ('28000', CombatFailureKind.notAuthenticated),
    'group_not_found': ('P0002', CombatFailureKind.groupNotFound),
    'combat_not_found': ('P0002', CombatFailureKind.combatNotFound),
    'participant_not_found': ('P0002', CombatFailureKind.participantNotFound),
    'not_group_owner': ('42501', CombatFailureKind.notGroupOwner),
    'no_game_master': ('P0001', CombatFailureKind.noGameMaster),
    'gm_absent': ('P0001', CombatFailureKind.gmAbsent),
    'combat_already_active': ('P0001', CombatFailureKind.combatAlreadyActive),
    'combat_not_active': ('P0001', CombatFailureKind.combatNotActive),
    'participant_removed': ('P0001', CombatFailureKind.participantRemoved),
    'no_character': ('P0001', CombatFailureKind.noCharacter),
    'npc_limit_per_call': ('P0001', CombatFailureKind.npcLimitPerCall),
    'npc_limit_per_combat': ('P0001', CombatFailureKind.npcLimitPerCombat),
    'invalid_initiative': ('22023', CombatFailureKind.invalidInitiative),
    'invalid_name': ('22023', CombatFailureKind.invalidName),
    'invalid_count': ('22023', CombatFailureKind.invalidCount),
    'invalid_sort_order': ('22023', CombatFailureKind.invalidSortOrder),
  };

  for (final entry in cases.entries) {
    test('${entry.key} (${entry.value.$1}) -> ${entry.value.$2}', () {
      final failure = mapCombatPostgrestError(
        PostgrestException(message: entry.key, code: entry.value.$1),
      );
      expect(failure.kind, entry.value.$2);
      expect(failure.sqlState, entry.value.$1);
      expect(failure.isConnectivity, isFalse);
    });
  }

  test('tous les codes serveur déclarés sont couverts par ce test', () {
    final declared = {
      for (final kind in CombatFailureKind.values)
        if (kind.serverCode != null) kind.serverCode,
    };
    expect(cases.keys.toSet(), declared);
  });

  test('code inconnu -> unknown avec le message brut', () {
    final failure = mapCombatPostgrestError(
      const PostgrestException(message: 'boom', code: 'XX000'),
    );
    expect(failure.kind, CombatFailureKind.unknown);
    expect(failure.rawMessage, 'boom');
  });

  test('échec de transport -> network', () {
    expect(
      mapCombatUnknownError(const SocketException('x')).kind,
      CombatFailureKind.network,
    );
    expect(
      mapCombatUnknownError(TimeoutException('x')).kind,
      CombatFailureKind.network,
    );
    expect(
      mapCombatUnknownError(StateError('x')).kind,
      CombatFailureKind.unknown,
    );
  });

  test('un CombatFailure est conservé tel quel', () {
    const failure = CombatFailure.offline();
    expect(identical(mapCombatUnknownError(failure), failure), isTrue);
  });
}
