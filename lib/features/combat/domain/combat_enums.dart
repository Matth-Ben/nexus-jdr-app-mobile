import 'package:json_annotation/json_annotation.dart';

/// `combats.status` — voir la migration web `20261114090000_create_group_combats.sql`.
@JsonEnum()
enum CombatStatus {
  /// Combat en cours (un seul par groupe, index unique partiel côté serveur).
  active,

  /// Combat terminé par le MJ (`ended_at` renseigné).
  ended,
}

/// `combat_participants.kind` : personnage joueur ou PNJ/monstre (nom +
/// initiative seulement, jamais de PV).
@JsonEnum()
enum ParticipantKind { pc, npc }

/// `combat_participants.status`. Le retrait est un retrait logique
/// (`removed`), jamais un `DELETE` (voir `CombatRealtimeSubscription`).
@JsonEnum()
enum ParticipantStatus {
  active,

  /// Retiré par le MJ ou par le départ du membre : non modifiable, jamais
  /// réintégré dans le même combat en V1.
  removed,

  /// Mis en attente (V2) : toléré en lecture dès la V1.
  waiting,
}
