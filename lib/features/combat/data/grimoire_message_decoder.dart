import '../domain/combat_enums.dart';
import '../domain/grimoire_message.dart';
import '../domain/grimoire_participant.dart';

/// Version de l'enveloppe des messages du combat lue par cette app.
const int kGrimoireMessageVersion = 1;

/// Bornes d'initiative du contrat (celles de Nexus).
const int kGrimoireInitiativeMin = -20;
const int kGrimoireInitiativeMax = 60;

/// Longueur maximale d'un nom de participant (contrat : 1 à 80).
const int kGrimoireNameMaxLength = 80;

/// Contenu utile d'un broadcast reçu : `realtime_client` livre l'enveloppe
/// Phoenix (`{type: broadcast, event, payload}`) ; le message est dans
/// `payload`. Toléré aussi : le message seul.
Map<String, dynamic>? unwrapGrimoireBroadcast(Map<String, dynamic> raw) {
  final inner = raw['payload'];
  if (inner is Map && raw['event'] is String) {
    return Map<String, dynamic>.from(inner);
  }
  return raw;
}

/// `true` si [payload] est le signal `channel_rotated` envoyé par la base
/// (contrat §2.3) : relire les sujets et se réabonner. Il n'est jamais compté
/// comme un message du MJ.
bool isGrimoireChannelRotated(Map<String, dynamic> payload) =>
    _int(payload['v']) == kGrimoireMessageVersion &&
    payload['type'] == 'channel_rotated';

/// Décode un message du MJ reçu sur `:gm` (contrat DeepCore §4.1, §4.2).
///
/// Renvoie `null` (message ignoré, **non compté** pour l'expiration) si
/// l'enveloppe est invalide : `v` différent de 1, `combat_id` ou `seq`
/// absents, ou `channel_rotated`. Une enveloppe valide d'un type inconnu, ou
/// d'un type connu au contenu invalide, donne [GrimoireUnknownMessage]
/// (compté ; un contenu invalide redemande l'état complet). Les clés
/// inconnues sont ignorées (ajout compatible).
GrimoireMessage? decodeGrimoireMessage(Map<String, dynamic> payload) {
  if (_int(payload['v']) != kGrimoireMessageVersion) return null;
  final type = payload['type'];
  final combatId = _id(payload['combat_id']);
  final seq = _int(payload['seq']);
  if (type is! String || combatId == null || seq == null || seq < 1) {
    return null;
  }
  if (type == 'channel_rotated') return null;
  final sentAt = _date(payload['sent_at']);
  GrimoireMessage malformed() => GrimoireMessage.unknown(
    combatId: combatId,
    seq: seq,
    sentAt: sentAt,
    type: type,
    malformed: true,
  );

  switch (type) {
    case 'combat_start':
      final round = _round(payload['round']);
      final participants = _participants(payload['participants']);
      if (round == null || participants == null) return malformed();
      return GrimoireMessage.combatStart(
        combatId: combatId,
        seq: seq,
        sentAt: sentAt,
        round: round,
        participants: participants,
      );
    case 'initiative_request':
      final raw = payload['character_ids'];
      final ids = raw == null ? null : _ids(raw);
      if (raw != null && ids == null) return malformed();
      return GrimoireMessage.initiativeRequest(
        combatId: combatId,
        seq: seq,
        sentAt: sentAt,
        characterIds: ids,
      );
    case 'order':
      final round = _round(payload['round']);
      final participants = _participants(payload['participants']);
      final current = payload['current_participant_id'];
      if (round == null ||
          participants == null ||
          (current != null && _id(current) == null)) {
        return malformed();
      }
      return GrimoireMessage.order(
        combatId: combatId,
        seq: seq,
        sentAt: sentAt,
        round: round,
        participants: participants,
        currentParticipantId: _id(current),
      );
    case 'turn':
      final round = _round(payload['round']);
      final current = payload['current_participant_id'];
      if (round == null || (current != null && _id(current) == null)) {
        return malformed();
      }
      return GrimoireMessage.turn(
        combatId: combatId,
        seq: seq,
        sentAt: sentAt,
        round: round,
        currentParticipantId: _id(current),
      );
    case 'participant_removed':
      final participantId = _id(payload['participant_id']);
      if (participantId == null) return malformed();
      return GrimoireMessage.participantRemoved(
        combatId: combatId,
        seq: seq,
        sentAt: sentAt,
        participantId: participantId,
      );
    case 'combat_end':
      final rounds = _round(payload['rounds']);
      final count = _int(payload['participant_count']);
      if (rounds == null || count == null || count < 0) return malformed();
      return GrimoireMessage.combatEnd(
        combatId: combatId,
        seq: seq,
        sentAt: sentAt,
        rounds: rounds,
        participantCount: count,
      );
    case 'state':
      final status = payload['status'];
      if (status == 'none') {
        return GrimoireMessage.state(
          combatId: combatId,
          seq: seq,
          sentAt: sentAt,
          active: false,
          round: 1,
          initiativeRequestedFor: const [],
          participants: const [],
        );
      }
      final round = _round(payload['round']);
      final participants = _participants(payload['participants']);
      final current = payload['current_participant_id'];
      final rawRequested = payload['initiative_requested_for'];
      final requested = rawRequested == null
          ? const <String>[]
          : _ids(rawRequested);
      if (status != 'active' ||
          round == null ||
          participants == null ||
          requested == null ||
          (current != null && _id(current) == null)) {
        return malformed();
      }
      return GrimoireMessage.state(
        combatId: combatId,
        seq: seq,
        sentAt: sentAt,
        active: true,
        round: round,
        currentParticipantId: _id(current),
        initiativeRequestedFor: requested,
        participants: participants,
      );
    default:
      return GrimoireMessage.unknown(
        combatId: combatId,
        seq: seq,
        sentAt: sentAt,
        type: type,
      );
  }
}

/// Entier JSON (un nombre entier en virgule flottante est accepté).
int? _int(Object? value) {
  if (value is int) return value;
  if (value is double && value == value.roundToDouble()) return value.toInt();
  return null;
}

int? _round(Object? value) {
  final round = _int(value);
  return round == null || round < 1 ? null : round;
}

String? _id(Object? value) =>
    value is String && value.trim().isNotEmpty ? value : null;

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

List<String>? _ids(Object? value) {
  if (value is! List) return null;
  final ids = <String>[];
  for (final raw in value) {
    final id = _id(raw);
    if (id == null) return null;
    ids.add(id);
  }
  return List.unmodifiable(ids);
}

/// Liste publique ; `null` si elle ou l'un de ses participants est invalide
/// (l'ordre arrêté par le MJ ne peut pas être reconstruit en partie).
List<GrimoireParticipant>? _participants(Object? value) {
  if (value is! List) return null;
  final participants = <GrimoireParticipant>[];
  for (final raw in value) {
    if (raw is! Map) return null;
    final participant = _participant(Map<String, dynamic>.from(raw));
    if (participant == null) return null;
    participants.add(participant);
  }
  return List.unmodifiable(participants);
}

GrimoireParticipant? _participant(Map<String, dynamic> json) {
  final id = _id(json['id']);
  final name = json['name'];
  final kind = switch (json['kind']) {
    'pc' => ParticipantKind.pc,
    'npc' => ParticipantKind.npc,
    _ => null,
  };
  if (id == null || kind == null || name is! String || name.trim().isEmpty) {
    return null;
  }
  final rawInitiative = json['initiative'];
  final initiative = rawInitiative == null ? null : _int(rawInitiative);
  if (rawInitiative != null &&
      (initiative == null ||
          initiative < kGrimoireInitiativeMin ||
          initiative > kGrimoireInitiativeMax)) {
    return null;
  }
  final characterId = json['character_id'];
  final userId = json['user_id'];
  return GrimoireParticipant(
    id: id,
    kind: kind,
    // Texte non fiable : affiché tel quel, borné à la longueur du contrat.
    name: name.runes.length > kGrimoireNameMaxLength
        ? String.fromCharCodes(name.runes.take(kGrimoireNameMaxLength))
        : name,
    characterId: _id(characterId),
    userId: _id(userId),
    initiative: initiative,
    // `waiting` accepté même si Grimoire n'envoie aujourd'hui que `active`.
    status: json['status'] == 'waiting'
        ? ParticipantStatus.waiting
        : ParticipantStatus.active,
  );
}
