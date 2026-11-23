import 'package:freezed_annotation/freezed_annotation.dart';

import 'grimoire_participant.dart';

part 'grimoire_message.freezed.dart';

/// Message de Grimoire reçu sur le sujet `:gm` d'un groupe (contrat DeepCore
/// `docs/api-v1/contrat-temps-reel-combat.md` §4.1 et §4.2), déjà validé par
/// le décodeur (`data/grimoire_message_decoder.dart`).
///
/// Enveloppe commune : [combatId] (tiré au hasard par Grimoire à chaque
/// combat), [seq] (≥ 1, strictement croissant dans un combat) et [sentAt]
/// (heure d'envoi, **affichage seulement** : jamais comparée à l'horloge du
/// téléphone). `channel_rotated`, envoyé par la base et pas par le MJ, n'est
/// pas un [GrimoireMessage].
@freezed
sealed class GrimoireMessage with _$GrimoireMessage {
  /// `combat_start` : annonce (préparation avec `participants` vide) ou combat
  /// annoncé directement à son premier tour public (liste fournie).
  const factory GrimoireMessage.combatStart({
    required String combatId,
    required int seq,
    DateTime? sentAt,
    required int round,
    required List<GrimoireParticipant> participants,
  }) = GrimoireCombatStart;

  /// `initiative_request` : [characterIds] liste les personnages nouvellement
  /// demandés ; `null` = tous les `pc` sans initiative.
  const factory GrimoireMessage.initiativeRequest({
    required String combatId,
    required int seq,
    DateTime? sentAt,
    List<String>? characterIds,
  }) = GrimoireInitiativeRequest;

  /// `order` : liste publique complète, dans l'ordre arrêté par le MJ (jamais
  /// retriée), round et surbrillance. Jamais « À toi de jouer ».
  const factory GrimoireMessage.order({
    required String combatId,
    required int seq,
    DateTime? sentAt,
    required int round,
    required List<GrimoireParticipant> participants,
    String? currentParticipantId,
  }) = GrimoireOrder;

  /// `turn` : tour **réellement** commencé. Seul message qui déclenche « À toi
  /// de jouer ».
  const factory GrimoireMessage.turn({
    required String combatId,
    required int seq,
    DateTime? sentAt,
    required int round,
    String? currentParticipantId,
  }) = GrimoireTurn;

  /// `participant_removed` : geste explicite du MJ, sans motif.
  const factory GrimoireMessage.participantRemoved({
    required String combatId,
    required int seq,
    DateTime? sentAt,
    required String participantId,
  }) = GrimoireParticipantRemoved;

  /// `combat_end` : plus aucun message de ce combat n'est appliqué ensuite.
  const factory GrimoireMessage.combatEnd({
    required String combatId,
    required int seq,
    DateTime? sentAt,
    required int rounds,
    required int participantCount,
  }) = GrimoireCombatEnd;

  /// `state` : état complet, remplace toute la vue (jamais « À toi de jouer »).
  /// [active] faux = `status: none` (aucun combat en cours).
  const factory GrimoireMessage.state({
    required String combatId,
    required int seq,
    DateTime? sentAt,
    required bool active,
    required int round,
    String? currentParticipantId,
    required List<String> initiativeRequestedFor,
    required List<GrimoireParticipant> participants,
  }) = GrimoireState;

  /// Enveloppe valide (`v` = 1, `combat_id`, `seq`) d'un type inconnu (ajout
  /// futur, ignoré) ou d'un type connu au contenu invalide ([malformed] :
  /// l'état complet est alors redemandé). Compte quand même comme un message
  /// du MJ pour l'expiration (§4.4).
  const factory GrimoireMessage.unknown({
    required String combatId,
    required int seq,
    DateTime? sentAt,
    required String type,
    @Default(false) bool malformed,
  }) = GrimoireUnknownMessage;
}
