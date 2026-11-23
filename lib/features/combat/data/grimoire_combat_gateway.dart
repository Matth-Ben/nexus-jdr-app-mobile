import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/connectivity_checker.dart';
import '../domain/grimoire_failure.dart';
import 'grimoire_error_mapper.dart';

/// Sujets courants d'un groupe (`api_v1.group_live_channels`) : seul le sujet
/// `:gm` sert à Nexus (le sujet `:players` est réservé au meneur).
typedef GrimoireLiveTopics = ({int epoch, String gmTopic, bool isLeader});

/// Signal d'état du canal `:gm` (statuts de `RealtimeChannel.subscribe`).
enum GrimoireChannelSignal { subscribed, error, closed, timedOut }

/// Canal `:gm` ouvert : présence et fermeture.
abstract class GrimoireGmLink {
  /// Annonce la présence (`track`, clé = `user_id`, métadonnées
  /// `{v: 1, client: nexus}`), **seulement au premier plan** : seul le
  /// meneur la voit (décision 49), Grimoire s'en sert pour ne notifier que les
  /// joueurs absents.
  Future<void> trackPresence();

  /// Quitte le canal (`removeChannel`) : la présence disparaît avec lui.
  Future<void> close();
}

/// Passerelle du combat mené depuis Grimoire (contrat DeepCore
/// `docs/api-v1/contrat-temps-reel-combat.md`) : lecture des sujets du
/// groupe, abonnement **privé** au sujet `:gm`, envoi vers le meneur par
/// `api_v1.send_to_group_leader` (émetteur garanti). Aucune écriture dans une
/// table, aucun cache : rien de ce combat n'est persisté.
abstract class GrimoireCombatGateway {
  /// `api_v1.group_live_channels(p_group_id)` : sujets de l'époque courante.
  /// Ne jamais construire les sujets soi-même. `group_not_found` : plus
  /// membre, ne plus s'abonner.
  Future<GrimoireLiveTopics> fetchLiveChannels(String groupId);

  /// S'abonne au sujet [topic] en canal **privé** (`private: true` : sinon un
  /// autre canal, public, du même nom). [onBroadcast] reçoit chaque broadcast
  /// (enveloppe Phoenix), [onSignal] chaque changement d'état du canal.
  /// Aucune écoute de la présence (Nexus ne la reçoit pas).
  GrimoireGmLink openGmChannel({
    required String topic,
    required String presenceKey,
    required void Function(Map<String, dynamic> payload) onBroadcast,
    required void Function(GrimoireChannelSignal signal) onSignal,
  });

  /// `api_v1.send_to_group_leader(p_group_id, p_type, p_payload)` : `initiative`
  /// (`combat_id`, `initiative`) ou `state_request` (`combat_id` facultatif).
  /// Hors ligne : [GrimoireFailure.offline] sans toucher le réseau.
  Future<void> sendToLeader({
    required String groupId,
    required String type,
    required Map<String, Object?> payload,
  });
}

class SupabaseGrimoireCombatGateway implements GrimoireCombatGateway {
  SupabaseGrimoireCombatGateway(this._client, this._connectivity);

  final SupabaseClient _client;
  final ConnectivityChecker _connectivity;

  static const String _schema = 'api_v1';

  @override
  Future<GrimoireLiveTopics> fetchLiveChannels(String groupId) async {
    try {
      final data = await _client
          .schema(_schema)
          .rpc<dynamic>('group_live_channels', params: {'p_group_id': groupId});
      final map = _asMap(data);
      final gm = map?['gm'];
      final epoch = map?['epoch'];
      if (map == null ||
          map['v'] != 1 ||
          gm is! String ||
          gm.isEmpty ||
          epoch is! int) {
        throw const GrimoireFailure(
          GrimoireFailureKind.other,
          rawMessage: 'réponse',
        );
      }
      return (epoch: epoch, gmTopic: gm, isLeader: map['is_leader'] == true);
    } on PostgrestException catch (error) {
      throw mapGrimoirePostgrestError(error);
    } catch (error) {
      throw mapGrimoireUnknownError(error);
    }
  }

  @override
  GrimoireGmLink openGmChannel({
    required String topic,
    required String presenceKey,
    required void Function(Map<String, dynamic> payload) onBroadcast,
    required void Function(GrimoireChannelSignal signal) onSignal,
  }) {
    // `enabled` : la présence doit être activée à l'entrée dans le canal pour
    // que `track` soit accepté, même sans écouteur de présence.
    final channel = _client.channel(
      topic,
      opts: RealtimeChannelConfig(
        private: true,
        key: presenceKey,
        enabled: true,
      ),
    );
    channel.onBroadcast(event: '*', callback: onBroadcast).subscribe((
      status,
      error,
    ) {
      onSignal(switch (status) {
        RealtimeSubscribeStatus.subscribed => GrimoireChannelSignal.subscribed,
        RealtimeSubscribeStatus.channelError => GrimoireChannelSignal.error,
        RealtimeSubscribeStatus.closed => GrimoireChannelSignal.closed,
        RealtimeSubscribeStatus.timedOut => GrimoireChannelSignal.timedOut,
      });
    });
    return _SupabaseGmLink(_client, channel);
  }

  @override
  Future<void> sendToLeader({
    required String groupId,
    required String type,
    required Map<String, Object?> payload,
  }) async {
    if (!await _connectivity.hasConnection()) {
      throw const GrimoireFailure.offline();
    }
    try {
      await _client
          .schema(_schema)
          .rpc<dynamic>(
            'send_to_group_leader',
            params: {
              'p_group_id': groupId,
              'p_type': type,
              'p_payload': payload,
            },
          );
    } on PostgrestException catch (error) {
      throw mapGrimoirePostgrestError(error);
    } catch (error) {
      throw mapGrimoireUnknownError(error);
    }
  }

  // PostgREST renvoie un objet pour un `jsonb` ; on tolère aussi une liste à
  // un élément.
  Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is List && value.length == 1 && value.first is Map) {
      return Map<String, dynamic>.from(value.first as Map);
    }
    return null;
  }
}

class _SupabaseGmLink implements GrimoireGmLink {
  _SupabaseGmLink(this._client, this._channel);

  final SupabaseClient _client;
  final RealtimeChannel _channel;

  @override
  Future<void> trackPresence() async {
    await _channel.track({'v': 1, 'client': 'nexus'});
  }

  @override
  Future<void> close() async {
    await _client.removeChannel(_channel);
  }
}
