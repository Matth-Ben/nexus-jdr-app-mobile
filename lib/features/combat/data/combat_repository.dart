import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/connectivity_checker.dart';
import '../domain/combat.dart';
import '../domain/combat_failure.dart';
import '../domain/combat_participant.dart';
import '../domain/combat_snapshot.dart';
import 'combat_error_mapper.dart';

/// Handle d'abonnement Realtime (`CombatRepository.subscribeToCombatUpdates`)
/// — même principe que `GroupRealtimeSubscription` : permet de fermer le canal
/// sans exposer `RealtimeChannel` aux tests.
abstract class CombatRealtimeSubscription {
  Future<void> cancel();
}

/// Passerelle vers le combat de groupe — tables `combats` /
/// `combat_participants` (lecture seule côté client, RLS membres du groupe) et
/// 7 RPC d'écriture (migrations web `20261114090000_create_group_combats.sql`
/// et `20261114091000_group_combat_rpcs.sql`). Voir `docs/combat-groupe.md`.
///
/// **Aucune écriture directe sur les tables, aucune écriture hors ligne** :
/// pas de file de synchro, pas de cache drift. Hors ligne, les méthodes
/// d'écriture lèvent [CombatFailure.offline] sans toucher le réseau. Toutes
/// les erreurs sont des [CombatFailure].
abstract class CombatRepository {
  /// Combat actif du groupe et ses participants, en une seule requête
  /// (jointure embarquée). `null` si aucun combat actif (ou non accessible).
  Future<CombatSnapshot?> fetchActiveCombat(String groupId);

  /// RPC `start_combat(p_group_id)` — MJ uniquement.
  Future<Combat> startCombat(String groupId);

  /// RPC `end_combat(p_combat_id)` — propriétaire du groupe uniquement.
  Future<Combat> endCombat(String combatId);

  /// RPC `set_my_initiative(p_combat_id, p_initiative)` — le joueur écrit
  /// **sa seule** initiative (-20..60).
  Future<CombatParticipant> setMyInitiative({
    required String combatId,
    required int initiative,
  });

  /// RPC `set_participant_initiative(p_participant_id, p_initiative)` — MJ ;
  /// [initiative] `null` remet « initiative à saisir ».
  Future<CombatParticipant> setParticipantInitiative({
    required String participantId,
    required int? initiative,
  });

  /// RPC `add_npc_participants(p_combat_id, p_base_name, p_initiative,
  /// p_count)` — MJ ; auto-numérotation côté serveur pour [count] > 1 (max 20
  /// par appel, 60 PNJ non retirés par combat).
  Future<List<CombatParticipant>> addNpcParticipants({
    required String combatId,
    required String baseName,
    int? initiative,
    int count = 1,
  });

  /// RPC `remove_participant(p_participant_id)` — MJ ; retrait logique.
  Future<CombatParticipant> removeParticipant(String participantId);

  /// RPC `reorder_participant(p_participant_id, p_new_sort_order)` — MJ ;
  /// renvoie toutes les lignes du combat triées par `sort_order`.
  Future<List<CombatParticipant>> reorderParticipant({
    required String participantId,
    required int newSortOrder,
  });

  /// S'abonne (Supabase Realtime, `postgres_changes`) aux tables `combats` et
  /// `combat_participants`, filtrées sur `group_id = eq.<groupId>`.
  ///
  /// Stratégie **« notification de changement puis refetch complet »** :
  /// [onChanged] est appelé sans argument à chaque évènement (jamais de delta
  /// appliqué depuis le payload). [onSubscribed] est appelé à **chaque**
  /// (re)connexion du canal : l'appelant doit alors faire un resync complet
  /// (des évènements ont pu être manqués pendant la coupure).
  ///
  /// Piège F08 : les `DELETE` ne sont pas filtrables par `group_id` (REPLICA
  /// IDENTITY DEFAULT). Sans conséquence ici : le retrait d'un participant est
  /// un `UPDATE status = 'removed'` et la fin d'un combat un
  /// `UPDATE status = 'ended'`.
  CombatRealtimeSubscription subscribeToCombatUpdates({
    required String groupId,
    required void Function() onChanged,
    required void Function() onSubscribed,
  });
}

const String _participantColumns =
    'id, combat_id, group_id, character_id, user_id, name, kind, initiative, '
    'sort_order, status, created_at';

class SupabaseCombatRepository implements CombatRepository {
  SupabaseCombatRepository(this._client, this._connectivity);

  final SupabaseClient _client;
  final ConnectivityChecker _connectivity;

  @override
  Future<CombatSnapshot?> fetchActiveCombat(String groupId) async {
    try {
      // `limit(1)` plutôt que `maybeSingle()` : `maybeSingle` réécrit toute
      // erreur PostgREST avec le corps brut comme message et perd le code.
      final rows = await _client
          .from('combats')
          .select(
            'id, group_id, status, round, current_participant_id, '
            'started_by, created_at, ended_at, '
            'combat_participants($_participantColumns)',
          )
          .eq('group_id', groupId)
          .eq('status', 'active')
          .limit(1);
      if (rows.isEmpty) return null;
      final row = rows.first;
      final rawParticipants =
          (row['combat_participants'] as List<dynamic>?) ?? const [];
      return CombatSnapshot(
        combat: Combat.fromJson(row),
        participants: [
          for (final raw in rawParticipants)
            CombatParticipant.fromJson(raw as Map<String, dynamic>),
        ],
      );
    } on PostgrestException catch (error) {
      throw mapCombatPostgrestError(error);
    } catch (error) {
      throw mapCombatUnknownError(error);
    }
  }

  @override
  Future<Combat> startCombat(String groupId) => _write(
    () async => Combat.fromJson(
      _asMap(
        await _client.rpc('start_combat', params: {'p_group_id': groupId}),
      ),
    ),
  );

  @override
  Future<Combat> endCombat(String combatId) => _write(
    () async => Combat.fromJson(
      _asMap(
        await _client.rpc('end_combat', params: {'p_combat_id': combatId}),
      ),
    ),
  );

  @override
  Future<CombatParticipant> setMyInitiative({
    required String combatId,
    required int initiative,
  }) => _write(
    () async => CombatParticipant.fromJson(
      _asMap(
        await _client.rpc(
          'set_my_initiative',
          params: {'p_combat_id': combatId, 'p_initiative': initiative},
        ),
      ),
    ),
  );

  @override
  Future<CombatParticipant> setParticipantInitiative({
    required String participantId,
    required int? initiative,
  }) => _write(
    () async => CombatParticipant.fromJson(
      _asMap(
        await _client.rpc(
          'set_participant_initiative',
          params: {
            'p_participant_id': participantId,
            'p_initiative': initiative,
          },
        ),
      ),
    ),
  );

  @override
  Future<List<CombatParticipant>> addNpcParticipants({
    required String combatId,
    required String baseName,
    int? initiative,
    int count = 1,
  }) => _write(
    () async => _asParticipants(
      await _client.rpc(
        'add_npc_participants',
        params: {
          'p_combat_id': combatId,
          'p_base_name': baseName,
          'p_initiative': initiative,
          'p_count': count,
        },
      ),
    ),
  );

  @override
  Future<CombatParticipant> removeParticipant(String participantId) => _write(
    () async => CombatParticipant.fromJson(
      _asMap(
        await _client.rpc(
          'remove_participant',
          params: {'p_participant_id': participantId},
        ),
      ),
    ),
  );

  @override
  Future<List<CombatParticipant>> reorderParticipant({
    required String participantId,
    required int newSortOrder,
  }) => _write(
    () async => _asParticipants(
      await _client.rpc(
        'reorder_participant',
        params: {
          'p_participant_id': participantId,
          'p_new_sort_order': newSortOrder,
        },
      ),
    ),
  );

  @override
  CombatRealtimeSubscription subscribeToCombatUpdates({
    required String groupId,
    required void Function() onChanged,
    required void Function() onSubscribed,
  }) {
    // Nom de canal unique par abonnement (horodaté) : évite toute collision
    // avec un abonnement précédent encore en cours de désabonnement.
    final channel = _client.channel(
      'combat-$groupId-${DateTime.now().microsecondsSinceEpoch}',
    );
    for (final table in const ['combats', 'combat_participants']) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'group_id',
          value: groupId,
        ),
        callback: (payload) => onChanged(),
      );
    }
    channel.subscribe((status, error) {
      if (status == RealtimeSubscribeStatus.subscribed) onSubscribed();
    });
    return _CombatChannelSubscription(_client, channel);
  }

  /// Garde commune des écritures : refus immédiat hors ligne (aucun appel
  /// réseau), mapping des erreurs en [CombatFailure].
  Future<T> _write<T>(Future<T> Function() call) async {
    if (!await _connectivity.hasConnection()) {
      throw const CombatFailure.offline();
    }
    try {
      return await call();
    } on PostgrestException catch (error) {
      throw mapCombatPostgrestError(error);
    } catch (error) {
      throw mapCombatUnknownError(error);
    }
  }

  // PostgREST renvoie un objet pour un type composite scalaire ; on tolère
  // aussi une liste à un élément.
  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is List && value.length == 1 && value.first is Map) {
      return value.first as Map<String, dynamic>;
    }
    throw const CombatFailure(CombatFailureKind.unknown, rawMessage: 'réponse');
  }

  List<CombatParticipant> _asParticipants(Object? value) {
    if (value is! List) {
      throw const CombatFailure(
        CombatFailureKind.unknown,
        rawMessage: 'réponse',
      );
    }
    return [
      for (final row in value)
        CombatParticipant.fromJson(row as Map<String, dynamic>),
    ];
  }
}

class _CombatChannelSubscription implements CombatRealtimeSubscription {
  _CombatChannelSubscription(this._client, this._channel);

  final SupabaseClient _client;
  final RealtimeChannel _channel;

  @override
  Future<void> cancel() async {
    await _client.removeChannel(_channel);
  }
}
