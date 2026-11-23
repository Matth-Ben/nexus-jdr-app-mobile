import 'dart:async';

import 'package:personnages/features/combat/data/grimoire_combat_gateway.dart';
import 'package:personnages/features/combat/domain/grimoire_failure.dart';

/// Faux canal `:gm` piloté par le test : [emit] livre un message du MJ (dans
/// l'enveloppe Phoenix, comme `realtime_client`), [signal] un état du canal.
class FakeGrimoireGmLink implements GrimoireGmLink {
  FakeGrimoireGmLink(
    this.topic,
    this.presenceKey,
    this._onBroadcast,
    this._onSignal,
  );

  final String topic;
  final String presenceKey;
  final void Function(Map<String, dynamic>) _onBroadcast;
  final void Function(GrimoireChannelSignal) _onSignal;

  int tracks = 0;
  bool closed = false;

  void emit(Map<String, dynamic> message) => _onBroadcast({
    'type': 'broadcast',
    'event': message['type'],
    'payload': message,
  });

  void signal(GrimoireChannelSignal signal) => _onSignal(signal);

  @override
  Future<void> trackPresence() async => tracks++;

  @override
  Future<void> close() async => closed = true;
}

/// Envoi enregistré vers le meneur.
typedef FakeLeaderMessage = ({
  String groupId,
  String type,
  Map<String, Object?> payload,
});

/// Fausse passerelle du combat Grimoire. Par défaut **inerte** : les sujets
/// sont lus, le canal passe `SUBSCRIBED` (microtâche) et rien n'arrive —
/// aucun combat Grimoire, comme un groupe sans Grimoire ouvert.
class FakeGrimoireCombatGateway implements GrimoireCombatGateway {
  FakeGrimoireCombatGateway({this.autoSubscribe = true});

  /// Le canal passe `SUBSCRIBED` dès son ouverture.
  bool autoSubscribe;

  GrimoireLiveTopics topics = (
    epoch: 1,
    gmTopic: 'grimoire:v1:group:group-1:e1:gm',
    isLeader: false,
  );

  /// Échec de `group_live_channels` (ex. `group_not_found`).
  GrimoireFailure? topicsFailure;
  int topicsReads = 0;

  final List<FakeGrimoireGmLink> links = [];
  final List<FakeLeaderMessage> sent = [];

  /// Échec des envois par type (`initiative`, `state_request`), tant qu'il
  /// est posé.
  final Map<String, GrimoireFailure> failures = {};

  /// Si posé, tout envoi attend ce signal (état « envoi en cours »).
  Completer<void>? sendGate;

  FakeGrimoireGmLink get lastLink => links.last;

  List<FakeLeaderMessage> get stateRequests =>
      sent.where((message) => message.type == 'state_request').toList();

  List<FakeLeaderMessage> get initiatives =>
      sent.where((message) => message.type == 'initiative').toList();

  @override
  Future<GrimoireLiveTopics> fetchLiveChannels(String groupId) async {
    topicsReads++;
    final failure = topicsFailure;
    if (failure != null) throw failure;
    return topics;
  }

  @override
  GrimoireGmLink openGmChannel({
    required String topic,
    required String presenceKey,
    required void Function(Map<String, dynamic> payload) onBroadcast,
    required void Function(GrimoireChannelSignal signal) onSignal,
  }) {
    final link = FakeGrimoireGmLink(topic, presenceKey, onBroadcast, onSignal);
    links.add(link);
    if (autoSubscribe) {
      scheduleMicrotask(() {
        if (!link.closed) link.signal(GrimoireChannelSignal.subscribed);
      });
    }
    return link;
  }

  @override
  Future<void> sendToLeader({
    required String groupId,
    required String type,
    required Map<String, Object?> payload,
  }) async {
    sent.add((groupId: groupId, type: type, payload: payload));
    final gate = sendGate;
    if (gate != null) await gate.future;
    final failure = failures[type];
    if (failure != null) throw failure;
  }
}
