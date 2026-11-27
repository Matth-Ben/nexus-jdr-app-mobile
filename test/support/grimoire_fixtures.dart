// Messages du combat mené depuis Grimoire, au format du contrat DeepCore
// `docs/api-v1/contrat-temps-reel-combat.md` §4 (tels que diffusés sur `:gm`).

import 'package:personnages/features/combat/data/grimoire_message_decoder.dart';
import 'package:personnages/features/combat/domain/grimoire_combat_reducer.dart';
import 'package:personnages/features/combat/domain/grimoire_combat_view.dart';
import 'package:personnages/features/combat/domain/grimoire_message.dart';

const kCombatA = '11111111-1111-4111-8111-111111111111';
const kCombatB = '22222222-2222-4222-8222-222222222222';

/// `sent_at` par défaut des messages (affichage seulement).
const kSentAt = '2026-11-23T20:04:00.000Z';

Map<String, dynamic> grimoireMessage(
  String type, {
  required int seq,
  String combatId = kCombatA,
  String sentAt = kSentAt,
  Map<String, dynamic> extra = const {},
}) => {
  'v': 1,
  'type': type,
  'combat_id': combatId,
  'seq': seq,
  'sent_at': sentAt,
  ...extra,
};

Map<String, dynamic> grimoireParticipant(
  String id, {
  String kind = 'pc',
  String? name,
  String? characterId,
  String? userId,
  int? initiative,
  String status = 'active',
}) => {
  'id': id,
  'kind': kind,
  'name': name ?? id,
  'character_id': characterId,
  'user_id': userId,
  'initiative': initiative,
  'status': status,
};

Map<String, dynamic> gCombatStart(
  int seq, {
  String combatId = kCombatA,
  int round = 1,
  List<Map<String, dynamic>> participants = const [],
  String sentAt = kSentAt,
}) => grimoireMessage(
  'combat_start',
  seq: seq,
  combatId: combatId,
  sentAt: sentAt,
  extra: {'round': round, 'participants': participants},
);

Map<String, dynamic> gInitiativeRequest(
  int seq,
  List<String>? characterIds, {
  String combatId = kCombatA,
}) => grimoireMessage(
  'initiative_request',
  seq: seq,
  combatId: combatId,
  extra: {'character_ids': characterIds},
);

Map<String, dynamic> gOrder(
  int seq,
  List<Map<String, dynamic>> participants, {
  String? current,
  int round = 1,
  String combatId = kCombatA,
  String sentAt = kSentAt,
}) => grimoireMessage(
  'order',
  seq: seq,
  combatId: combatId,
  sentAt: sentAt,
  extra: {
    'round': round,
    'participants': participants,
    'current_participant_id': current,
  },
);

Map<String, dynamic> gTurn(
  int seq,
  String current, {
  int round = 1,
  String combatId = kCombatA,
}) => grimoireMessage(
  'turn',
  seq: seq,
  combatId: combatId,
  extra: {'round': round, 'current_participant_id': current},
);

Map<String, dynamic> gRemoved(
  int seq,
  String participantId, {
  String combatId = kCombatA,
}) => grimoireMessage(
  'participant_removed',
  seq: seq,
  combatId: combatId,
  extra: {'participant_id': participantId},
);

Map<String, dynamic> gEnd(
  int seq, {
  int rounds = 3,
  int count = 4,
  String combatId = kCombatA,
}) => grimoireMessage(
  'combat_end',
  seq: seq,
  combatId: combatId,
  extra: {'rounds': rounds, 'participant_count': count},
);

Map<String, dynamic> gState(
  int seq, {
  List<Map<String, dynamic>> participants = const [],
  String? current,
  List<String> requested = const [],
  int round = 1,
  String status = 'active',
  String combatId = kCombatA,
  String sentAt = kSentAt,
}) => grimoireMessage(
  'state',
  seq: seq,
  combatId: combatId,
  sentAt: sentAt,
  extra: {
    'status': status,
    'round': round,
    'current_participant_id': current,
    'initiative_requested_for': requested,
    'participants': participants,
  },
);

Map<String, dynamic> gRotated({int epoch = 2}) => {
  'v': 1,
  'type': 'channel_rotated',
  'group_id': 'group-1',
  'epoch': epoch,
  'id': 'rot-1',
};

GrimoireMessage decoded(Map<String, dynamic> payload) =>
    decodeGrimoireMessage(payload)!;

/// Joueur courant des tests : compte `player-1`, personnage `c-player`.
const GrimoireIdentity kMe = (userId: 'player-1', characterId: 'c-player');

/// Distribution type : Aria (le joueur, 18), Gobelin (PNJ, 15), Brun (autre
/// joueur, sans initiative). Ordre du MJ conservé tel quel.
List<Map<String, dynamic>> grimoireRoster({
  int? ariaInitiative = 18,
  String? ariaUserId = 'player-1',
}) => [
  grimoireParticipant(
    'p-aria',
    name: 'Aria',
    characterId: 'c-player',
    userId: ariaUserId,
    initiative: ariaInitiative,
  ),
  grimoireParticipant('p-gob', kind: 'npc', name: 'Gobelin', initiative: 15),
  grimoireParticipant(
    'p-brun',
    name: 'Brun',
    characterId: 'c-brun',
    userId: 'player-2',
  ),
];

/// Applique une suite de messages à partir d'une vue vide (instants
/// successifs d'une seconde depuis [start]).
({GrimoireCombatView view, List<GrimoireCombatEvent> events}) applyAll(
  List<Map<String, dynamic>> messages, {
  GrimoireCombatView view = const GrimoireCombatView(),
  GrimoireIdentity me = kMe,
  DateTime? start,
}) {
  var current = view;
  final events = <GrimoireCombatEvent>[];
  var at = start ?? DateTime(2026, 11, 23, 21);
  for (final message in messages) {
    final step = applyGrimoireMessage(
      current,
      decoded(message),
      me: me,
      receivedAt: at,
    );
    current = step.view;
    events.addAll(step.events);
    at = at.add(const Duration(seconds: 1));
  }
  return (view: current, events: events);
}
