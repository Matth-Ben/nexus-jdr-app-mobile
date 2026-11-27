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
    this._onSignal, {
    this.closeGate,
  });

  final String topic;
  final String presenceKey;
  final void Function(Map<String, dynamic>) _onBroadcast;
  final void Function(GrimoireChannelSignal) _onSignal;

  /// Si posé, la fermeture (`removeChannel`) attend ce signal.
  final Completer<void>? closeGate;

  int tracks = 0;

  /// Fermeture demandée (canal quitté côté client).
  bool closeRequested = false;

  /// Fermeture terminée.
  bool closed = false;

  /// Canal encore actif côté serveur avec une présence annoncée.
  bool get presenceActive => tracks > 0 && !closeRequested;

  void emit(Map<String, dynamic> message) => _onBroadcast({
    'type': 'broadcast',
    'event': message['type'],
    'payload': message,
  });

  void signal(GrimoireChannelSignal signal) => _onSignal(signal);

  @override
  Future<void> trackPresence() async => tracks++;

  @override
  Future<void> close() async {
    closeRequested = true;
    final gate = closeGate;
    if (gate != null) await gate.future;
    closed = true;
  }
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

  /// Sujets renvoyés ; `null` : sujet propre au groupe lu, époque 1.
  GrimoireLiveTopics? topics;

  /// Si posé, chaque fermeture de canal attend ce signal (fermeture lente).
  Completer<void>? closeGate;

  /// Échec de `group_live_channels` (ex. `group_not_found`).
  GrimoireFailure? topicsFailure;

  /// Si posé, la lecture des sujets attend ce signal (réseau lent).
  Completer<void>? topicsGate;
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
    final gate = topicsGate;
    if (gate != null) await gate.future;
    final failure = topicsFailure;
    if (failure != null) throw failure;
    return topics ??
        (
          epoch: 1,
          gmTopic: 'grimoire:v1:group:$groupId:e1:gm',
          isLeader: false,
        );
  }

  /// Dernier canal ouvert sur un sujet du groupe [groupId].
  FakeGrimoireGmLink linkFor(String groupId) =>
      links.lastWhere((link) => link.topic.contains(':group:$groupId:'));

  @override
  GrimoireGmLink openGmChannel({
    required String topic,
    required String presenceKey,
    required void Function(Map<String, dynamic> payload) onBroadcast,
    required void Function(GrimoireChannelSignal signal) onSignal,
  }) {
    final link = FakeGrimoireGmLink(
      topic,
      presenceKey,
      onBroadcast,
      onSignal,
      closeGate: closeGate,
    );
    links.add(link);
    if (autoSubscribe) {
      scheduleMicrotask(() {
        if (!link.closeRequested) {
          link.signal(GrimoireChannelSignal.subscribed);
        }
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
