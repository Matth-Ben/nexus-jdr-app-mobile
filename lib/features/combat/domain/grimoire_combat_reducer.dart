import 'grimoire_combat_view.dart';
import 'grimoire_failure.dart';
import 'grimoire_message.dart';
import 'grimoire_participant.dart';

/// Évènement **reçu** à signaler au joueur (annonce, haptique), produit par
/// une transition pure. Jamais émis au chargement ni sur un `state` de
/// reprise (spec `docs/combat-grimoire-ui.md` §10).
enum GrimoireCombatEventKind {
  /// « Combat ! Le MJ lance un combat dans {group}. »
  combatStarted,

  /// « Le MJ demande ton initiative. » (aussi quand il la redemande).
  initiativeRequested,

  /// « Initiative {value} envoyée au MJ. »
  initiativeSent,

  /// « Le MJ a reçu ton initiative. »
  initiativeReceived,

  /// « Le MJ a retenu {value}. »
  initiativeCorrected,

  /// « L'ordre d'initiative est dévoilé. »
  orderRevealed,

  /// « Round {round}. Tour de {name}. » (`turn` seulement).
  turn,

  /// « C'est ton tour. » (assertive, haptique) — `turn` seulement.
  yourTurn,

  /// « Le MJ semble hors ligne. La dernière vue reste affichée. »
  gmOffline,

  /// « Le MJ est de retour. »
  gmBack,

  /// « Le combat est terminé. »
  ended,

  /// 10 min sans message : bandeaux retirés (aucune annonce).
  expired,
}

/// Évènement d'une transition : [value] (initiative), [round] et [name]
/// (tour) selon le [kind].
typedef GrimoireCombatEvent = ({
  GrimoireCombatEventKind kind,
  int? value,
  int? round,
  String? name,
});

/// Résultat d'une transition : nouvelle vue, évènements à signaler, et
/// besoin de redemander l'état complet (`state_request` : trou de `seq`,
/// combat inconnu, contenu invalide).
typedef GrimoireStep = ({
  GrimoireCombatView view,
  List<GrimoireCombatEvent> events,
  bool requestState,
});

GrimoireCombatEvent grimoireEvent(
  GrimoireCombatEventKind kind, {
  int? value,
  int? round,
  String? name,
}) => (kind: kind, value: value, round: round, name: name);

GrimoireStep _unchanged(GrimoireCombatView view, {bool requestState = false}) =>
    (view: view, events: const [], requestState: requestState);

/// Applique un message de Grimoire à [view] (règles du contrat DeepCore
/// §4.1 à §4.4).
///
/// - Message d'un **autre** combat : ignoré (l'état complet est redemandé),
///   sauf `combat_start` ou `state`, qui remplacent la vue.
/// - Même combat : `seq` inférieur ou égal au dernier appliqué ignoré (sauf
///   `state` à `seq` égal), mais **compté** pour l'expiration ; un trou de
///   `seq` redemande l'état complet (le message est quand même appliqué).
/// - Combat terminé : plus rien n'est appliqué.
///
/// [receivedAt] : horloge de Nexus à la réception (jamais `sent_at`).
/// [resyncing] : premier `state` attendu après un (ré)abonnement, appliqué
/// **sans** évènement (comme un `state` qui charge un combat inconnu).
GrimoireStep applyGrimoireMessage(
  GrimoireCombatView view,
  GrimoireMessage message, {
  required GrimoireIdentity me,
  required DateTime receivedAt,
  bool resyncing = false,
}) {
  final sameCombat = view.combatId != null && view.combatId == message.combatId;
  final isState = message is GrimoireState;
  if (!sameCombat && message is! GrimoireCombatStart && !isState) {
    // Annonce manquée (ou fin d'un autre combat) : rien n'est appliqué.
    return _unchanged(view, requestState: true);
  }
  if (sameCombat && view.status == GrimoireCombatStatus.ended) {
    return _unchanged(view);
  }

  // Un `state` de reprise ou de chargement s'applique sans rien annoncer.
  final silent =
      isState &&
      (resyncing || !sameCombat || view.status == GrimoireCombatStatus.none);
  final events = <GrimoireCombatEvent>[];
  var requestState = false;
  GrimoireCombatView base;
  if (sameCombat) {
    final last = view.lastSeq ?? 0;
    final stale = message.seq < last || (message.seq == last && !isState);
    // Tout message du combat affiché compte, même déjà appliqué.
    final revived = view.copyWith(
      lastReceivedAt: receivedAt,
      liveness: GrimoireLiveness.live,
    );
    if (view.liveness != GrimoireLiveness.live) {
      events.add(grimoireEvent(GrimoireCombatEventKind.gmBack));
    }
    if (stale) {
      return (
        view: revived,
        events: silent ? const [] : List.unmodifiable(events),
        requestState: false,
      );
    }
    requestState = message.seq > last + 1;
    base = revived;
  } else {
    // Nouveau combat : la vue repart de zéro (initiative comprise).
    base = GrimoireCombatView(
      combatId: message.combatId,
      lastReceivedAt: receivedAt,
    );
  }
  base = base.copyWith(
    lastSeq: message.seq,
    lastSentAt: message.sentAt ?? base.lastSentAt,
  );

  final reduction = _Reduction(
    previous: view,
    base: base,
    me: me,
    receivedAt: receivedAt,
    isNewCombat: !sameCombat,
    events: events,
  );
  final next = switch (message) {
    GrimoireCombatStart() => reduction.combatStart(message),
    GrimoireInitiativeRequest() => reduction.initiativeRequest(message),
    GrimoireOrder() => reduction.order(message),
    GrimoireTurn() => reduction.turn(message),
    GrimoireParticipantRemoved() => reduction.participantRemoved(message),
    GrimoireCombatEnd() => reduction.combatEnd(message),
    GrimoireState() => reduction.state(message),
    GrimoireUnknownMessage() => reduction.unknown(message),
  };
  return (
    view: next,
    events: silent ? const [] : List.unmodifiable(events),
    requestState: requestState || reduction.requestState,
  );
}

/// Fait avancer la minuterie d'expiration à l'instant [now] (horloge de
/// Nexus) : 90 s sans message → MJ hors ligne, 10 min → expiré.
///
/// [canJudgeGm] : téléphone en ligne **et** canal `SUBSCRIBED` ; sinon Nexus
/// ne sait pas qui est coupé et ne conclut jamais à « MJ hors ligne ».
/// [graceUntil] : fin de l'attente après un (ré)abonnement (5 s) ; aucune
/// transition avant.
GrimoireStep tickGrimoireCombat(
  GrimoireCombatView view, {
  required DateTime now,
  required bool canJudgeGm,
  DateTime? graceUntil,
}) {
  final last = view.lastReceivedAt;
  if (!view.isRunning || last == null) return _unchanged(view);
  if (graceUntil != null && now.isBefore(graceUntil)) return _unchanged(view);
  final silence = now.difference(last);
  var liveness = view.liveness;
  if (silence >= kGrimoireExpireAfter) {
    liveness = GrimoireLiveness.expired;
  } else if (silence >= kGrimoireGmOfflineAfter &&
      canJudgeGm &&
      liveness == GrimoireLiveness.live) {
    liveness = GrimoireLiveness.gmOffline;
  }
  if (liveness == view.liveness) return _unchanged(view);
  final expired = liveness == GrimoireLiveness.expired;
  return (
    view: view.copyWith(
      liveness: liveness,
      // Fin de « À toi de jouer » à l'expiration.
      yourTurn: expired ? false : view.yourTurn,
    ),
    events: [
      grimoireEvent(
        expired
            ? GrimoireCombatEventKind.expired
            : GrimoireCombatEventKind.gmOffline,
      ),
    ],
    requestState: false,
  );
}

/// Prochain instant où [tickGrimoireCombat] peut changer quelque chose
/// (90 s, 10 min, fin de l'attente après réabonnement), strictement après
/// [now] ; `null` si aucune minuterie n'est utile.
DateTime? nextGrimoireDeadline(
  GrimoireCombatView view, {
  required DateTime now,
  DateTime? graceUntil,
}) {
  final last = view.lastReceivedAt;
  if (!view.isRunning || last == null) return null;
  final candidates = <DateTime>[
    if (view.liveness == GrimoireLiveness.live)
      last.add(kGrimoireGmOfflineAfter),
    if (view.liveness != GrimoireLiveness.expired)
      last.add(kGrimoireExpireAfter),
    ?graceUntil,
  ].where((instant) => instant.isAfter(now)).toList()..sort();
  return candidates.isEmpty ? null : candidates.first;
}

/// Identité du joueur connue ou changée après coup (détail du groupe chargé,
/// personnage changé) : une demande d'initiative déjà reçue qui le concerne
/// passe à « Demandée », sans annonce (ce n'est pas un changement reçu).
GrimoireCombatView reconcileGrimoireInitiative(
  GrimoireCombatView view,
  GrimoireIdentity me,
) {
  if (!view.isRunning ||
      view.removedFromCombat ||
      view.initiative.status != GrimoireInitiativeStatus.idle ||
      !view.isConcerned(me)) {
    return view;
  }
  return view.copyWith(
    initiative: view.initiative.copyWith(
      status: GrimoireInitiativeStatus.requested,
    ),
  );
}

/// Envoi d'initiative lancé : bouton en chargement.
GrimoireCombatView markInitiativeSending(GrimoireCombatView view) =>
    view.copyWith(
      initiative: view.initiative.copyWith(
        status: GrimoireInitiativeStatus.sending,
        failure: null,
      ),
    );

/// Envoi réussi de [value] pour le combat [combatId], à [at] (horloge de
/// Nexus). Ignoré si le combat affiché a changé entre-temps.
GrimoireStep markInitiativeSent(
  GrimoireCombatView view, {
  required String combatId,
  required int value,
  required DateTime at,
}) {
  if (view.combatId != combatId) return _unchanged(view);
  return (
    view: view.copyWith(
      initiative: GrimoireInitiative(
        status: GrimoireInitiativeStatus.sent,
        sentValue: value,
        sentAt: at,
      ),
    ),
    events: [
      grimoireEvent(GrimoireCombatEventKind.initiativeSent, value: value),
    ],
    requestState: false,
  );
}

/// Envoi en échec : bouton réactivé avec le motif.
GrimoireCombatView markInitiativeFailed(
  GrimoireCombatView view, {
  required String combatId,
  required GrimoireFailure failure,
}) {
  if (view.combatId != combatId) return view;
  return view.copyWith(
    initiative: view.initiative.copyWith(
      status: GrimoireInitiativeStatus.failed,
      failure: failure,
    ),
  );
}

/// Accumulateur d'une transition (évènements et besoin d'état complet).
class _Reduction {
  _Reduction({
    required this.previous,
    required this.base,
    required this.me,
    required this.receivedAt,
    required this.isNewCombat,
    required this.events,
  });

  final GrimoireCombatView previous;
  final GrimoireCombatView base;
  final GrimoireIdentity me;
  final DateTime receivedAt;
  final bool isNewCombat;
  final List<GrimoireCombatEvent> events;
  bool requestState = false;

  void _emit(
    GrimoireCombatEventKind kind, {
    int? value,
    int? round,
    String? name,
  }) => events.add(grimoireEvent(kind, value: value, round: round, name: name));

  /// Nouvelle liste publique : surbrillance, « Toi » réapparu, statut.
  GrimoireCombatView _withParticipants(
    GrimoireCombatView view,
    List<GrimoireParticipant> participants, {
    required int round,
    required String? currentParticipantId,
  }) {
    final wasPreparing =
        view.status == GrimoireCombatStatus.preparing ||
        view.status == GrimoireCombatStatus.none;
    final status = participants.isEmpty && wasPreparing
        ? GrimoireCombatStatus.preparing
        : GrimoireCombatStatus.active;
    final next = view.copyWith(
      status: status,
      round: round,
      participants: List.unmodifiable(participants),
      currentParticipantId: currentParticipantId,
    );
    final mine = next.mine(me);
    final current = next.currentParticipant;
    return next.copyWith(
      // « À toi de jouer » prend fin dès que le tour n'est plus le sien.
      yourTurn:
          view.yourTurn &&
          current != null &&
          GrimoireCombatView.isMine(current, me),
      removedFromCombat: view.removedFromCombat && mine == null,
    );
  }

  /// Initiative reçue quand la ligne du joueur en porte une, et valeur
  /// corrigée par le MJ.
  GrimoireCombatView _afterOrder(
    GrimoireCombatView before,
    GrimoireCombatView next,
  ) {
    // Ordre des évènements : le plus utile au joueur en dernier (la fusion
    // des annonces garde la plus récente).
    if (before.status != GrimoireCombatStatus.active &&
        next.status == GrimoireCombatStatus.active &&
        !isNewCombat) {
      _emit(GrimoireCombatEventKind.orderRevealed);
    }
    var view = next;
    final mineAfter = view.mine(me);
    final initiative = view.initiative;
    if (initiative.awaitingReceipt && mineAfter?.initiative != null) {
      view = view.copyWith(
        initiative: initiative.copyWith(
          status: GrimoireInitiativeStatus.received,
        ),
      );
      _emit(GrimoireCombatEventKind.initiativeReceived);
    }
    final kept = mineAfter?.initiative;
    final keptBefore = before.status == GrimoireCombatStatus.active
        ? before.mine(me)?.initiative
        : null;
    if (kept != null && kept != keptBefore && view.correctedFrom(me) != null) {
      _emit(GrimoireCombatEventKind.initiativeCorrected, value: kept);
    }
    return view;
  }

  GrimoireCombatView combatStart(GrimoireCombatStart message) {
    final view = _withParticipants(
      base,
      message.participants,
      round: message.round,
      currentParticipantId: isNewCombat ? null : base.currentParticipantId,
    );
    if (isNewCombat || previous.status == GrimoireCombatStatus.none) {
      _emit(GrimoireCombatEventKind.combatStarted);
    }
    return _afterOrder(base, view);
  }

  GrimoireCombatView initiativeRequest(GrimoireInitiativeRequest message) {
    final ids = message.characterIds;
    var view = ids == null
        ? base.copyWith(requestedAll: true)
        : base.copyWith(
            requestedCharacterIds: {...base.requestedCharacterIds, ...ids},
          );
    final characterId = me.characterId;
    final named =
        characterId != null &&
        (ids == null
            ? view.mine(me)?.initiative == null
            : ids.contains(characterId));
    if (!named) return view;
    final initiative = view.initiative;
    final GrimoireInitiativeStatus? status = switch (initiative.status) {
      GrimoireInitiativeStatus.idle => GrimoireInitiativeStatus.requested,
      GrimoireInitiativeStatus.sent ||
      GrimoireInitiativeStatus.received ||
      GrimoireInitiativeStatus.notReceived =>
        GrimoireInitiativeStatus.requestedAgain,
      _ => null,
    };
    if (status != null) {
      view = view.copyWith(initiative: initiative.copyWith(status: status));
      _emit(GrimoireCombatEventKind.initiativeRequested);
    }
    return view;
  }

  GrimoireCombatView order(GrimoireOrder message) {
    final view = _withParticipants(
      base,
      message.participants,
      round: message.round,
      currentParticipantId: message.currentParticipantId,
    );
    return _afterOrder(base, view);
  }

  GrimoireCombatView turn(GrimoireTurn message) {
    final view = base.copyWith(
      round: message.round,
      currentParticipantId: message.currentParticipantId,
    );
    final current = view.currentParticipant;
    if (message.currentParticipantId != null && current == null) {
      // Tour d'un participant inconnu : un `order` a été manqué.
      requestState = true;
    }
    if (base.status != GrimoireCombatStatus.active) requestState = true;
    final mineTurn = current != null && GrimoireCombatView.isMine(current, me);
    if (mineTurn) {
      _emit(GrimoireCombatEventKind.yourTurn, round: message.round);
    } else if (current != null) {
      _emit(
        GrimoireCombatEventKind.turn,
        round: message.round,
        name: current.name,
      );
    }
    return view.copyWith(yourTurn: mineTurn);
  }

  GrimoireCombatView participantRemoved(GrimoireParticipantRemoved message) {
    final removed = base.participantById(message.participantId);
    if (removed == null) return base;
    final view = base.copyWith(
      participants: List.unmodifiable([
        for (final participant in base.participants)
          if (participant.id != removed.id) participant,
      ]),
    );
    if (!GrimoireCombatView.isMine(removed, me)) return view;
    return view.copyWith(
      removedFromCombat: true,
      yourTurn: false,
      initiative: view.initiative.copyWith(
        status: GrimoireInitiativeStatus.idle,
        failure: null,
      ),
    );
  }

  GrimoireCombatView combatEnd(GrimoireCombatEnd message) {
    _emit(GrimoireCombatEventKind.ended);
    return base.copyWith(
      status: GrimoireCombatStatus.ended,
      endedRounds: message.rounds,
      endedParticipantCount: message.participantCount,
      yourTurn: false,
    );
  }

  GrimoireCombatView state(GrimoireState message) {
    if (!message.active) {
      return base.copyWith(
        status: GrimoireCombatStatus.none,
        participants: const [],
        currentParticipantId: null,
        requestedCharacterIds: const {},
        requestedAll: false,
        yourTurn: false,
        removedFromCombat: false,
        initiative: const GrimoireInitiative(),
      );
    }
    var view = _withParticipants(
      base.copyWith(
        requestedCharacterIds: Set.unmodifiable(message.initiativeRequestedFor),
        requestedAll: false,
      ),
      message.participants,
      round: message.round,
      currentParticipantId: message.currentParticipantId,
    );
    final characterId = me.characterId;
    final concerned =
        characterId != null &&
        message.initiativeRequestedFor.contains(characterId);
    final initiative = view.initiative;
    var status = initiative.status;
    switch (initiative.status) {
      case GrimoireInitiativeStatus.idle:
        if (concerned) {
          status = GrimoireInitiativeStatus.requested;
          _emit(GrimoireCombatEventKind.initiativeRequested);
        }
      case GrimoireInitiativeStatus.requested:
      case GrimoireInitiativeStatus.requestedAgain:
      case GrimoireInitiativeStatus.failed:
        if (!concerned) status = GrimoireInitiativeStatus.received;
      case GrimoireInitiativeStatus.sending:
        break;
      case GrimoireInitiativeStatus.sent:
        if (!concerned) {
          status = GrimoireInitiativeStatus.received;
          _emit(GrimoireCombatEventKind.initiativeReceived);
        } else {
          final sentAt = initiative.sentAt;
          if (sentAt != null &&
              receivedAt.difference(sentAt) > kGrimoireNotReceivedAfter) {
            status = GrimoireInitiativeStatus.notReceived;
          }
        }
      case GrimoireInitiativeStatus.notReceived:
        if (!concerned) {
          status = GrimoireInitiativeStatus.received;
          _emit(GrimoireCombatEventKind.initiativeReceived);
        }
      case GrimoireInitiativeStatus.received:
        if (concerned) {
          status = GrimoireInitiativeStatus.requestedAgain;
          _emit(GrimoireCombatEventKind.initiativeRequested);
        }
    }
    if (status != initiative.status) {
      view = view.copyWith(
        initiative: initiative.copyWith(
          status: status,
          failure: status == GrimoireInitiativeStatus.failed
              ? initiative.failure
              : null,
        ),
      );
    }
    return _afterOrder(base, view);
  }

  GrimoireCombatView unknown(GrimoireUnknownMessage message) {
    if (message.malformed) requestState = true;
    return base;
  }
}
