import 'package:freezed_annotation/freezed_annotation.dart';

import '../../groups/domain/group_member.dart';
import 'grimoire_failure.dart';
import 'grimoire_participant.dart';

part 'grimoire_combat_view.freezed.dart';

/// Délai sans message de Grimoire au-delà duquel le MJ est dit « hors ligne »
/// (contrat DeepCore §4.4 : trois périodes de `state` en moyenne).
const Duration kGrimoireGmOfflineAfter = Duration(seconds: 90);

/// Délai sans message au-delà duquel le combat affiché expire (bandeaux
/// retirés, « Pas de nouvelles du MJ ») : l'échéance à laquelle Grimoire
/// abandonne une fin qui ne part pas.
const Duration kGrimoireExpireAfter = Duration(minutes: 10);

/// Attente après un (ré)abonnement (réponse au `state_request`) avant de
/// conclure à un silence du MJ (spec `docs/combat-grimoire-ui.md` §7).
const Duration kGrimoireResyncGrace = Duration(seconds: 5);

/// Un `state` reçu plus longtemps que ce délai après un envoi d'initiative
/// réussi et qui liste encore le personnage : « Non reçue » (spec §3).
const Duration kGrimoireNotReceivedAfter = Duration(seconds: 5);

/// `state_request` envoyé ce délai après un envoi d'initiative réussi
/// (arbitrage Q3 du 23/11/2026).
const Duration kGrimoireStateRequestAfterSend = Duration(seconds: 2);

/// Fenêtre « Connexion au combat… » de l'écran ouvert sans état connu.
const Duration kGrimoireConnectingWindow = Duration(seconds: 5);

/// Identité du joueur courant dans un groupe : son compte et son personnage
/// courant (`group_members.character_id`, détail du groupe).
typedef GrimoireIdentity = ({String userId, String? characterId});

/// Personnages morts du groupe (décision 58, arbitrage Q7) : le contrat n'a
/// pas de champ « mort » ; Nexus lit `characters.is_dead`, déjà suivi en temps
/// réel par le détail du groupe, le même champ que Grimoire.
Set<String> grimoireDeadCharacterIds(Iterable<GroupMember> members) => {
  for (final member in members)
    if (member.isDead == true) ?member.characterId,
};

/// Le participant est-il un héros mort ? Rapproché par `character_id` : un
/// `pc` non relié ou un `npc` ne l'est jamais.
bool isGrimoireParticipantDead(
  GrimoireParticipant participant,
  Set<String> deadCharacterIds,
) {
  final characterId = participant.characterId;
  return participant.isPc &&
      characterId != null &&
      deadCharacterIds.contains(characterId);
}

/// Phase du combat Grimoire connu pour un groupe.
enum GrimoireCombatStatus {
  /// Aucun combat connu (ou `state` `none`).
  none,

  /// Annoncé, ordre pas encore dévoilé (`participants` vide). Préparation et
  /// premier tour caché sont volontairement identiques.
  preparing,

  /// Ordre dévoilé.
  active,

  /// `combat_end` reçu : plus rien n'est appliqué pour ce combat.
  ended,
}

/// Fraîcheur du combat affiché, mesurée depuis la **réception** du dernier
/// message de Grimoire (horloge de Nexus, jamais `sent_at`).
enum GrimoireLiveness {
  /// Moins de 90 s sans message (ou attente après un réabonnement).
  live,

  /// 90 s sans message : « MJ hors ligne », la dernière vue reste affichée.
  gmOffline,

  /// 10 min sans message : bandeaux retirés, « Pas de nouvelles du MJ ».
  expired,
}

/// Machine d'états de l'initiative du joueur (spec §3).
enum GrimoireInitiativeStatus {
  /// Pas concerné : aucune carte.
  idle,

  /// Le MJ demande l'initiative, pas encore envoyée.
  requested,

  /// Envoi en cours (`send_to_group_leader`).
  sending,

  /// Envoi réussi, en attente de confirmation du MJ.
  sent,

  /// Le MJ a l'initiative (le personnage n'est plus demandé, ou sa ligne en
  /// porte une).
  received,

  /// Un `state` reçu plus de 5 s après l'envoi liste encore le personnage.
  notReceived,

  /// Le MJ redemande l'initiative après un envoi.
  requestedAgain,

  /// Dernier envoi en échec (voir [GrimoireInitiative.failure]).
  failed,
}

/// Initiative du joueur dans le combat affiché : **mémoire seulement** (la
/// valeur envoyée n'est jamais persistée ; relancer l'app l'oublie).
@freezed
abstract class GrimoireInitiative with _$GrimoireInitiative {
  const GrimoireInitiative._();

  const factory GrimoireInitiative({
    @Default(GrimoireInitiativeStatus.idle) GrimoireInitiativeStatus status,

    /// Dernière valeur envoyée avec succès (ou en cours d'envoi).
    int? sentValue,

    /// Horloge de Nexus au moment de l'envoi réussi.
    DateTime? sentAt,

    /// Échec du dernier envoi ([GrimoireInitiativeStatus.failed]).
    GrimoireFailure? failure,
  }) = _GrimoireInitiative;

  /// Statuts où le joueur peut (r)envoyer son initiative.
  bool get canSend =>
      status == GrimoireInitiativeStatus.requested ||
      status == GrimoireInitiativeStatus.notReceived ||
      status == GrimoireInitiativeStatus.requestedAgain ||
      status == GrimoireInitiativeStatus.failed;

  /// Envoi réussi en attente de confirmation (ou non confirmé).
  bool get awaitingReceipt =>
      status == GrimoireInitiativeStatus.sent ||
      status == GrimoireInitiativeStatus.notReceived;
}

/// Vue d'un combat mené depuis Grimoire pour un groupe, reconstruite
/// uniquement à partir des messages reçus sur `:gm`. **En mémoire seulement** :
/// rien n'est écrit dans le cache `drift` (noms des autres joueurs, combat
/// éphémère). Toutes les transitions sont des fonctions pures de
/// `grimoire_combat_reducer.dart`.
@freezed
abstract class GrimoireCombatView with _$GrimoireCombatView {
  const GrimoireCombatView._();

  const factory GrimoireCombatView({
    @Default(GrimoireCombatStatus.none) GrimoireCombatStatus status,

    /// Combat affiché (`null` : aucun connu).
    String? combatId,

    /// Dernier `seq` appliqué du combat affiché.
    int? lastSeq,
    @Default(1) int round,

    /// Ordre arrêté par le MJ, **jamais retrié**.
    @Default(<GrimoireParticipant>[]) List<GrimoireParticipant> participants,
    String? currentParticipantId,

    /// Personnages dont l'initiative est demandée (`initiative_requested_for`
    /// du dernier `state`, complété par les `initiative_request`).
    @Default(<String>{}) Set<String> requestedCharacterIds,

    /// `initiative_request` avec `character_ids: null` : tous les `pc` sans
    /// initiative.
    @Default(false) bool requestedAll,

    /// Réception du dernier message compté (horloge de Nexus).
    DateTime? lastReceivedAt,

    /// `sent_at` du dernier message appliqué (affichage seulement).
    DateTime? lastSentAt,
    @Default(GrimoireLiveness.live) GrimoireLiveness liveness,

    /// « À toi de jouer » : posé seulement par un `turn` qui désigne le joueur.
    @Default(false) bool yourTurn,

    /// `participant_removed` du participant du joueur (bandeau « Le MJ t'a
    /// retiré de ce combat »), effacé s'il réapparaît dans un ordre.
    @Default(false) bool removedFromCombat,

    /// `combat_end` : rounds atteints et participants publics vus.
    int? endedRounds,
    int? endedParticipantCount,
    @Default(GrimoireInitiative()) GrimoireInitiative initiative,
  }) = _GrimoireCombatView;

  /// Combat annoncé, pas terminé (préparation ou ordre dévoilé).
  bool get isRunning =>
      status == GrimoireCombatStatus.preparing ||
      status == GrimoireCombatStatus.active;

  /// Combat **vivant** (décision 61) : annoncé, pas terminé, pas expiré. Tant
  /// qu'il l'est, Nexus l'affiche en priorité et désactive « Lancer un
  /// combat » (natif).
  bool get isAlive => isRunning && liveness != GrimoireLiveness.expired;

  /// Combat annoncé mais expiré (10 min sans message).
  bool get isExpired => isRunning && liveness == GrimoireLiveness.expired;

  GrimoireParticipant? participantById(String? id) {
    if (id == null) return null;
    for (final participant in participants) {
      if (participant.id == id) return participant;
    }
    return null;
  }

  /// Participant en surbrillance (`null` sans tour, ou tour inconnu).
  GrimoireParticipant? get currentParticipant =>
      participantById(currentParticipantId);

  /// « initiatives N/M » : N participants publics avec une initiative sur M
  /// participants publics.
  ({int entered, int total}) get initiativeProgress => (
    entered: participants.where((p) => p.hasInitiative).length,
    total: participants.length,
  );

  /// Ligne `pc` du joueur : `user_id` égal au sien ; si `user_id` vaut
  /// `null`, repli sur `character_id` égal à son personnage courant.
  GrimoireParticipant? mine(GrimoireIdentity me) {
    for (final participant in participants) {
      if (isMine(participant, me)) return participant;
    }
    return null;
  }

  /// `true` si [participant] est le `pc` du joueur [me].
  static bool isMine(GrimoireParticipant participant, GrimoireIdentity me) {
    if (!participant.isPc) return false;
    final userId = participant.userId;
    if (userId != null) return userId == me.userId;
    final characterId = participant.characterId;
    return characterId != null && characterId == me.characterId;
  }

  /// Le joueur est-il concerné par la demande d'initiative ? Son personnage
  /// courant est demandé, ou la demande vaut pour tous (`null`) et sa ligne
  /// n'a pas d'initiative connue.
  bool isConcerned(GrimoireIdentity me) {
    final characterId = me.characterId;
    if (characterId == null) return false;
    if (requestedCharacterIds.contains(characterId)) return true;
    return requestedAll && mine(me)?.initiative == null;
  }

  /// Valeur envoyée par le joueur quand le MJ en a retenu une autre (ordre
  /// dévoilé) ; `null` sinon, et quand la valeur envoyée est inconnue (app
  /// relancée).
  int? correctedFrom(GrimoireIdentity me) {
    final sent = initiative.sentValue;
    final kept = mine(me)?.initiative;
    if (status != GrimoireCombatStatus.active || sent == null || kept == null) {
      return null;
    }
    return kept == sent ? null : sent;
  }

  /// La carte d'initiative est-elle affichée ? Pendant la préparation, dans
  /// tout état sauf [GrimoireInitiativeStatus.idle] ; une fois l'ordre
  /// dévoilé, la ligne du joueur prend le relais d'une initiative reçue.
  bool get showsInitiativeCard {
    if (!isRunning || removedFromCombat) return false;
    final current = initiative.status;
    if (current == GrimoireInitiativeStatus.idle) return false;
    if (status == GrimoireCombatStatus.active &&
        current == GrimoireInitiativeStatus.received) {
      return false;
    }
    return true;
  }
}
