import 'dart:async';

import 'package:personnages/features/combat/data/combat_repository.dart';
import 'package:personnages/features/combat/domain/combat.dart';
import 'package:personnages/features/combat/domain/combat_failure.dart';
import 'package:personnages/features/combat/domain/combat_participant.dart';
import 'package:personnages/features/combat/domain/combat_snapshot.dart';

import 'combat_fixtures.dart';

/// Faux canal Realtime piloté par le test : le test appelle [emitChange] (un
/// évènement `postgres_changes`) et [emitSubscribed] (le canal vient de se
/// (re)connecter).
class FakeCombatChannel implements CombatRealtimeSubscription {
  FakeCombatChannel(this.groupId, this._onChanged, this._onSubscribed);

  final String groupId;
  final void Function() _onChanged;
  final void Function() _onSubscribed;
  bool cancelled = false;

  void emitChange() => _onChanged();

  void emitSubscribed() => _onSubscribed();

  @override
  Future<void> cancel() async => cancelled = true;
}

/// Faux dépôt : [fetchResult] décide de la réponse de chaque refetch (peut être
/// remplacé en cours de test) ; [fetchGate] permet de garder un refetch en vol.
class FakeCombatRepository implements CombatRepository {
  CombatSnapshot? snapshot;
  CombatFailure? fetchFailure;

  /// Réponse par groupe (prioritaire sur [snapshot]) : plusieurs groupes.
  final Map<String, CombatSnapshot?> snapshotsByGroup = {};
  Completer<void>? fetchGate;
  int fetchCount = 0;
  int concurrentFetches = 0;
  int maxConcurrentFetches = 0;

  final List<FakeCombatChannel> channels = [];
  final List<String> calls = [];
  CombatFailure? writeFailure;

  /// Si posé, toute écriture attend ce signal (état « en cours »).
  Completer<void>? writeGate;

  FakeCombatChannel get lastChannel => channels.last;

  @override
  Future<CombatSnapshot?> fetchActiveCombat(String groupId) async {
    fetchCount++;
    concurrentFetches++;
    if (concurrentFetches > maxConcurrentFetches) {
      maxConcurrentFetches = concurrentFetches;
    }
    final gate = fetchGate;
    final failure = fetchFailure;
    final result = snapshotsByGroup.containsKey(groupId)
        ? snapshotsByGroup[groupId]
        : snapshot;
    try {
      if (gate != null) await gate.future;
      if (failure != null) throw failure;
      return result;
    } finally {
      concurrentFetches--;
    }
  }

  Future<T> _write<T>(String call, T value) async {
    calls.add(call);
    final gate = writeGate;
    if (gate != null) await gate.future;
    final failure = writeFailure;
    if (failure != null) throw failure;
    return value;
  }

  @override
  Future<Combat> startCombat(String groupId) =>
      _write('start:$groupId', fakeCombat(groupId: groupId));

  @override
  Future<Combat> endCombat(String combatId) =>
      _write('end:$combatId', fakeCombat(id: combatId));

  @override
  Future<CombatParticipant> setMyInitiative({
    required String combatId,
    required int initiative,
  }) => _write('mine:$combatId:$initiative', fakeParticipant('me'));

  @override
  Future<CombatParticipant> setParticipantInitiative({
    required String participantId,
    required int? initiative,
  }) =>
      _write('set:$participantId:$initiative', fakeParticipant(participantId));

  @override
  Future<List<CombatParticipant>> addNpcParticipants({
    required String combatId,
    required String baseName,
    int? initiative,
    int count = 1,
  }) => _write('add:$combatId:$baseName:$initiative:$count', const []);

  @override
  Future<CombatParticipant> removeParticipant(String participantId) =>
      _write('remove:$participantId', fakeParticipant(participantId));

  @override
  Future<List<CombatParticipant>> reorderParticipant({
    required String participantId,
    required int newSortOrder,
  }) => _write('reorder:$participantId:$newSortOrder', const []);

  @override
  CombatRealtimeSubscription subscribeToCombatUpdates({
    required String groupId,
    required void Function() onChanged,
    required void Function() onSubscribed,
  }) {
    final channel = FakeCombatChannel(groupId, onChanged, onSubscribed);
    channels.add(channel);
    return channel;
  }
}
