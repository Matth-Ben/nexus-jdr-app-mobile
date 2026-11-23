// Modèle de vue du combat mené depuis Grimoire : transitions pures
// (`grimoire_combat_reducer.dart`), règles de `seq` et de `combat_id`,
// « À toi de jouer », minuteries (horloge injectée), initiative, héros mort.

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/combat/domain/combat_enums.dart';
import 'package:personnages/features/combat/domain/grimoire_combat_reducer.dart';
import 'package:personnages/features/combat/domain/grimoire_combat_session.dart';
import 'package:personnages/features/combat/domain/grimoire_combat_view.dart';
import 'package:personnages/features/combat/domain/grimoire_failure.dart';
import 'package:personnages/features/combat/domain/grimoire_participant.dart';
import 'package:personnages/features/groups/domain/group_member.dart';
import 'package:personnages/features/groups/domain/group_role.dart';

import '../../../support/grimoire_fixtures.dart';

final t0 = DateTime(2026, 11, 23, 21);

GrimoireStep step(
  GrimoireCombatView view,
  Map<String, dynamic> message, {
  DateTime? at,
  bool resyncing = false,
  GrimoireIdentity me = kMe,
}) => applyGrimoireMessage(
  view,
  decoded(message),
  me: me,
  receivedAt: at ?? t0,
  resyncing: resyncing,
);

List<GrimoireCombatEventKind> kinds(List<GrimoireCombatEvent> events) => [
  for (final event in events) event.kind,
];

/// Combat dévoilé : préparation puis ordre (Aria = le joueur).
GrimoireCombatView revealed({String? current = 'p-gob', int round = 1}) =>
    applyAll([
      gCombatStart(1),
      gOrder(2, grimoireRoster(), current: current, round: round),
    ]).view;

void main() {
  group('combat_start et préparation', () {
    test('annonce sans contenu : préparation, évènement « Combat ! »', () {
      final result = step(const GrimoireCombatView(), gCombatStart(1));
      expect(result.view.status, GrimoireCombatStatus.preparing);
      expect(result.view.combatId, kCombatA);
      expect(result.view.lastSeq, 1);
      expect(result.view.participants, isEmpty);
      expect(result.view.isAlive, isTrue);
      expect(kinds(result.events), [GrimoireCombatEventKind.combatStarted]);
    });

    test('combat_start avec une liste (combat sans héros) : ordre direct', () {
      final result = step(
        const GrimoireCombatView(),
        gCombatStart(1, participants: grimoireRoster(), round: 2),
      );
      expect(result.view.status, GrimoireCombatStatus.active);
      expect(result.view.round, 2);
      expect(kinds(result.events), [GrimoireCombatEventKind.combatStarted]);
    });

    test('state actif sans participants = préparation (tour caché)', () {
      final view = applyAll([gCombatStart(1), gState(2)]).view;
      expect(view.status, GrimoireCombatStatus.preparing);
    });

    test('premier order : dévoilement annoncé, une seule fois', () {
      final prep = applyAll([gCombatStart(1)]).view;
      final first = step(prep, gOrder(2, grimoireRoster(), current: 'p-gob'));
      expect(first.view.status, GrimoireCombatStatus.active);
      expect(kinds(first.events), [GrimoireCombatEventKind.orderRevealed]);
      final second = step(
        first.view,
        gOrder(3, grimoireRoster(), current: 'p-brun'),
      );
      expect(second.events, isEmpty);
    });
  });

  group('règles de seq (contrat §4.1)', () {
    test('seq inférieur ou égal : ignoré mais compté pour l\'expiration', () {
      final view = revealed();
      final later = t0.add(const Duration(seconds: 40));
      final stale = step(
        view,
        gOrder(2, grimoireRoster().reversed.toList(), current: 'p-aria'),
        at: later,
      );
      expect(stale.view.participants.first.id, 'p-aria');
      expect(stale.view.currentParticipantId, 'p-gob');
      expect(stale.view.lastReceivedAt, later);
      expect(stale.requestState, isFalse);
    });

    test('state à seq égal : appliqué', () {
      final view = revealed();
      final result = step(
        view,
        gState(2, participants: grimoireRoster(), current: 'p-brun', round: 2),
      );
      expect(result.view.currentParticipantId, 'p-brun');
      expect(result.view.round, 2);
    });

    test('trou de seq : appliqué et état complet redemandé', () {
      final view = revealed();
      final result = step(view, gTurn(5, 'p-brun', round: 1));
      expect(result.view.currentParticipantId, 'p-brun');
      expect(result.view.lastSeq, 5);
      expect(result.requestState, isTrue);
    });

    test('suite sans trou : aucune demande d\'état', () {
      final view = revealed();
      expect(step(view, gTurn(3, 'p-brun')).requestState, isFalse);
    });

    test('contenu invalide : compté, seq avancé, état redemandé', () {
      final view = revealed();
      final result = step(
        view,
        grimoireMessage('order', seq: 3, extra: {'round': 'x'}),
      );
      expect(result.view.lastSeq, 3);
      expect(result.requestState, isTrue);
    });

    test('type inconnu : compté, aucun trou ensuite', () {
      final view = revealed();
      final unknown = step(view, grimoireMessage('reveal', seq: 3));
      expect(unknown.requestState, isFalse);
      expect(step(unknown.view, gTurn(4, 'p-brun')).requestState, isFalse);
    });
  });

  group('combat_id', () {
    test('message d\'un autre combat (hors annonce/état) : ignoré, état '
        'redemandé, non compté', () {
      final view = revealed();
      final later = t0.add(const Duration(seconds: 50));
      final result = step(view, gTurn(9, 'p-x', combatId: kCombatB), at: later);
      expect(result.view, view);
      expect(result.requestState, isTrue);
    });

    test('combat_start d\'un autre combat : remplace la vue', () {
      final view = revealed();
      final result = step(view, gCombatStart(1, combatId: kCombatB));
      expect(result.view.combatId, kCombatB);
      expect(result.view.status, GrimoireCombatStatus.preparing);
      expect(result.view.participants, isEmpty);
      expect(kinds(result.events), [GrimoireCombatEventKind.combatStarted]);
    });

    test('state d\'un autre combat : remplace la vue, sans annonce', () {
      final view = revealed();
      final result = step(
        view,
        gState(
          7,
          combatId: kCombatB,
          participants: grimoireRoster(),
          current: 'p-aria',
        ),
      );
      expect(result.view.combatId, kCombatB);
      expect(result.view.lastSeq, 7);
      expect(result.events, isEmpty);
      expect(result.view.yourTurn, isFalse);
    });

    test('fin : plus aucun message de ce combat n\'est appliqué', () {
      final ended = applyAll([gCombatStart(1), gEnd(2)]).view;
      expect(ended.status, GrimoireCombatStatus.ended);
      expect(
        step(ended, gState(3, participants: grimoireRoster())).view,
        ended,
      );
      final next = step(ended, gCombatStart(1, combatId: kCombatB));
      expect(next.view.status, GrimoireCombatStatus.preparing);
    });
  });

  group('« À toi de jouer » : turn seulement (contrat §4.2)', () {
    test('turn désignant le pc du joueur : mode, évènement', () {
      final result = step(revealed(), gTurn(3, 'p-aria', round: 2));
      expect(result.view.yourTurn, isTrue);
      expect(kinds(result.events), [GrimoireCombatEventKind.yourTurn]);
    });

    test('repli sur character_id quand user_id est null', () {
      final view = applyAll([
        gCombatStart(1),
        gOrder(2, grimoireRoster(ariaUserId: null), current: 'p-gob'),
      ]).view;
      expect(step(view, gTurn(3, 'p-aria')).view.yourTurn, isTrue);
    });

    test('turn d\'un autre : « Round N. Tour de X. »', () {
      final result = step(revealed(), gTurn(3, 'p-brun', round: 2));
      expect(result.view.yourTurn, isFalse);
      expect(result.events.single, (
        kind: GrimoireCombatEventKind.turn,
        value: null,
        round: 2,
        name: 'Brun',
      ));
    });

    test('jamais sur order, state ni combat_start qui le désignent', () {
      final prep = applyAll([gCombatStart(1)]).view;
      final order = step(prep, gOrder(2, grimoireRoster(), current: 'p-aria'));
      expect(order.view.yourTurn, isFalse);
      expect(
        kinds(order.events),
        isNot(contains(GrimoireCombatEventKind.yourTurn)),
      );
      final state = step(
        order.view,
        gState(3, participants: grimoireRoster(), current: 'p-aria'),
      );
      expect(state.view.yourTurn, isFalse);
      final start = step(
        const GrimoireCombatView(),
        gCombatStart(1, participants: grimoireRoster()),
      );
      expect(start.view.yourTurn, isFalse);
    });

    test('fin du mode : turn, order ou state qui ne le désignent plus', () {
      final mine = step(revealed(), gTurn(3, 'p-aria')).view;
      expect(step(mine, gTurn(4, 'p-brun')).view.yourTurn, isFalse);
      expect(
        step(
          mine,
          gOrder(4, grimoireRoster(), current: 'p-brun'),
        ).view.yourTurn,
        isFalse,
      );
      expect(
        step(
          mine,
          gState(4, participants: grimoireRoster(), current: 'p-gob'),
        ).view.yourTurn,
        isFalse,
      );
      // Un ordre qui garde la surbrillance sur lui ne met pas fin au mode.
      expect(
        step(
          mine,
          gOrder(4, grimoireRoster(), current: 'p-aria'),
        ).view.yourTurn,
        isTrue,
      );
    });

    test('fin du mode : retrait du joueur, fin du combat, expiration', () {
      final mine = step(revealed(), gTurn(3, 'p-aria')).view;
      expect(step(mine, gRemoved(4, 'p-aria')).view.yourTurn, isFalse);
      expect(step(mine, gEnd(4)).view.yourTurn, isFalse);
      final expired = tickGrimoireCombat(
        mine,
        now: t0.add(kGrimoireExpireAfter),
        canJudgeGm: true,
      );
      expect(expired.view.yourTurn, isFalse);
    });

    test('vue figée (tour caché) : state identique, rien ne bouge', () {
      final view = step(revealed(), gTurn(3, 'p-brun', round: 2)).view;
      final frozen = step(
        view,
        gState(4, participants: grimoireRoster(), current: 'p-brun', round: 2),
        at: t0.add(const Duration(seconds: 30)),
      );
      expect(frozen.events, isEmpty);
      expect(frozen.view.currentParticipantId, 'p-brun');
      expect(frozen.view.round, 2);
      expect(frozen.view.participants, view.participants);
    });
  });

  group('participant_removed', () {
    test('la ligne disparaît, l\'ordre restant est conservé', () {
      final result = step(revealed(), gRemoved(3, 'p-gob'));
      expect(result.view.participants.map((p) => p.id), ['p-aria', 'p-brun']);
      expect(result.view.removedFromCombat, isFalse);
    });

    test('le joueur retiré : bandeau, effacé s\'il réapparaît', () {
      final removed = step(revealed(), gRemoved(3, 'p-aria')).view;
      expect(removed.removedFromCombat, isTrue);
      final back = step(removed, gOrder(4, grimoireRoster(), current: 'p-gob'));
      expect(back.view.removedFromCombat, isFalse);
    });
  });

  group('fin', () {
    test('combat_end : résumé, annonce', () {
      final result = step(revealed(), gEnd(3, rounds: 4, count: 5));
      expect(result.view.status, GrimoireCombatStatus.ended);
      expect(result.view.endedRounds, 4);
      expect(result.view.endedParticipantCount, 5);
      expect(result.view.isAlive, isFalse);
      expect(kinds(result.events), [GrimoireCombatEventKind.ended]);
    });

    test('fin à 0 participant (avant le dévoilement)', () {
      final view = applyAll([gCombatStart(1), gEnd(2, rounds: 1, count: 0)])
          .view;
      expect(view.status, GrimoireCombatStatus.ended);
      expect(view.endedParticipantCount, 0);
    });

    test('state none : aucun combat', () {
      final view = step(revealed(), gState(3, status: 'none')).view;
      expect(view.status, GrimoireCombatStatus.none);
      expect(view.isAlive, isFalse);
    });
  });

  group('annonces : jamais au chargement ni sur un state de reprise', () {
    test('state qui charge un combat inconnu : aucun évènement', () {
      final result = step(
        const GrimoireCombatView(),
        gState(
          12,
          participants: grimoireRoster(),
          current: 'p-aria',
          requested: ['c-player'],
        ),
      );
      expect(result.view.status, GrimoireCombatStatus.active);
      expect(result.events, isEmpty);
    });

    test('state de reprise (resyncing) : aucun évènement', () {
      final prep = applyAll([gCombatStart(1)]).view;
      final result = step(
        prep,
        gState(2, participants: grimoireRoster()),
        resyncing: true,
      );
      expect(result.view.status, GrimoireCombatStatus.active);
      expect(result.events, isEmpty);
    });
  });

  group('minuteries (horloge injectée, depuis la réception)', () {
    test('90 s sans message : MJ hors ligne, une seule fois', () {
      final view = revealed();
      final last = view.lastReceivedAt!;
      final before = tickGrimoireCombat(
        view,
        now: last.add(const Duration(seconds: 89)),
        canJudgeGm: true,
      );
      expect(before.view.liveness, GrimoireLiveness.live);
      final after = tickGrimoireCombat(
        view,
        now: last.add(kGrimoireGmOfflineAfter),
        canJudgeGm: true,
      );
      expect(after.view.liveness, GrimoireLiveness.gmOffline);
      expect(kinds(after.events), [GrimoireCombatEventKind.gmOffline]);
      expect(after.view.isAlive, isTrue);
      final again = tickGrimoireCombat(
        after.view,
        now: last.add(const Duration(seconds: 120)),
        canJudgeGm: true,
      );
      expect(again.events, isEmpty);
    });

    test('jamais « MJ hors ligne » sans canal sain (téléphone hors ligne)', () {
      final view = revealed();
      final result = tickGrimoireCombat(
        view,
        now: view.lastReceivedAt!.add(const Duration(seconds: 200)),
        canJudgeGm: false,
      );
      expect(result.view.liveness, GrimoireLiveness.live);
      expect(result.events, isEmpty);
    });

    test('attente de 5 s après un réabonnement', () {
      final view = revealed();
      final now = view.lastReceivedAt!.add(const Duration(seconds: 100));
      final inGrace = tickGrimoireCombat(
        view,
        now: now,
        canJudgeGm: true,
        graceUntil: now.add(const Duration(seconds: 3)),
      );
      expect(inGrace.view.liveness, GrimoireLiveness.live);
      final afterGrace = tickGrimoireCombat(
        view,
        now: now,
        canJudgeGm: true,
        graceUntil: now,
      );
      expect(afterGrace.view.liveness, GrimoireLiveness.gmOffline);
    });

    test(
      '10 min sans message : expiré (bandeaux retirés), même hors ligne',
      () {
        final view = revealed();
        final result = tickGrimoireCombat(
          view,
          now: view.lastReceivedAt!.add(kGrimoireExpireAfter),
          canJudgeGm: false,
        );
        expect(result.view.liveness, GrimoireLiveness.expired);
        expect(result.view.isAlive, isFalse);
        expect(result.view.isExpired, isTrue);
        expect(kinds(result.events), [GrimoireCombatEventKind.expired]);
      },
    );

    test('retour d\'un message : MJ de retour, reprise après expiration', () {
      final view = revealed();
      final offline = tickGrimoireCombat(
        view,
        now: view.lastReceivedAt!.add(kGrimoireGmOfflineAfter),
        canJudgeGm: true,
      ).view;
      final back = step(
        offline,
        gState(3, participants: grimoireRoster(), current: 'p-gob'),
        at: view.lastReceivedAt!.add(const Duration(seconds: 100)),
      );
      expect(back.view.liveness, GrimoireLiveness.live);
      expect(kinds(back.events), [GrimoireCombatEventKind.gmBack]);

      final expired = tickGrimoireCombat(
        view,
        now: view.lastReceivedAt!.add(kGrimoireExpireAfter),
        canJudgeGm: true,
      ).view;
      final resumed = step(
        expired,
        gState(3, participants: grimoireRoster()),
        at: view.lastReceivedAt!.add(const Duration(minutes: 11)),
      );
      expect(resumed.view.isAlive, isTrue);
    });

    test('mesuré à la réception, jamais sur sent_at', () {
      final view = applyAll([
        gCombatStart(1, sentAt: '2020-01-01T00:00:00Z'),
      ], start: t0).view;
      final result = tickGrimoireCombat(
        view,
        now: t0.add(const Duration(seconds: 10)),
        canJudgeGm: true,
      );
      expect(result.view.liveness, GrimoireLiveness.live);
      expect(view.lastSentAt, DateTime.parse('2020-01-01T00:00:00Z'));
    });

    test('prochaine échéance : 90 s, puis 10 min, puis aucune', () {
      final view = revealed();
      final last = view.lastReceivedAt!;
      expect(
        nextGrimoireDeadline(view, now: last),
        last.add(kGrimoireGmOfflineAfter),
      );
      final offline = view.copyWith(liveness: GrimoireLiveness.gmOffline);
      expect(
        nextGrimoireDeadline(offline, now: last.add(kGrimoireGmOfflineAfter)),
        last.add(kGrimoireExpireAfter),
      );
      final expired = view.copyWith(liveness: GrimoireLiveness.expired);
      expect(nextGrimoireDeadline(expired, now: last), isNull);
      expect(
        nextGrimoireDeadline(const GrimoireCombatView(), now: last),
        isNull,
      );
    });
  });

  group('priorités d\'affichage (§7)', () {
    GrimoireCombatSession session(
      GrimoireLiveness liveness, {
      GrimoireLinkStatus link = GrimoireLinkStatus.subscribed,
    }) => GrimoireCombatSession(
      view: revealed().copyWith(liveness: liveness),
      link: link,
      linkSince: t0,
    );

    test('téléphone hors ligne avant MJ hors ligne', () {
      expect(
        session(GrimoireLiveness.gmOffline).displayLiveness(phoneOnline: false),
        GrimoireDisplayLiveness.offline,
      );
    });

    test('canal pas SUBSCRIBED avant MJ hors ligne', () {
      expect(
        session(
          GrimoireLiveness.gmOffline,
          link: GrimoireLinkStatus.down,
        ).displayLiveness(phoneOnline: true),
        GrimoireDisplayLiveness.offline,
      );
    });

    test('MJ hors ligne, puis normal ; ouverture en cours = normal', () {
      expect(
        session(GrimoireLiveness.gmOffline).displayLiveness(phoneOnline: true),
        GrimoireDisplayLiveness.gmOffline,
      );
      expect(
        session(GrimoireLiveness.live).displayLiveness(phoneOnline: true),
        GrimoireDisplayLiveness.normal,
      );
      expect(
        session(
          GrimoireLiveness.live,
          link: GrimoireLinkStatus.connecting,
        ).displayLiveness(phoneOnline: true),
        GrimoireDisplayLiveness.normal,
      );
    });

    test('expiré l\'emporte', () {
      expect(
        session(GrimoireLiveness.expired).displayLiveness(phoneOnline: false),
        GrimoireDisplayLiveness.expired,
      );
    });
  });

  group('initiative (machine d\'états, §3)', () {
    GrimoireCombatView prepRequested() => applyAll([
      gCombatStart(1),
      gInitiativeRequest(2, ['c-player']),
    ]).view;

    test('demandée par initiative_request : carte, annonce', () {
      final result = applyAll([
        gCombatStart(1),
        gInitiativeRequest(2, ['c-player']),
      ]);
      expect(result.view.initiative.status, GrimoireInitiativeStatus.requested);
      expect(result.view.showsInitiativeCard, isTrue);
      expect(
        kinds(result.events),
        contains(GrimoireCombatEventKind.initiativeRequested),
      );
    });

    test('demande d\'un autre personnage : pas concerné', () {
      final view = applyAll([
        gCombatStart(1),
        gInitiativeRequest(2, ['c-brun']),
      ]).view;
      expect(view.initiative.status, GrimoireInitiativeStatus.idle);
      expect(view.showsInitiativeCard, isFalse);
    });

    test(
      'character_ids null : concerné si sa ligne n\'a pas d\'initiative',
      () {
        final prep = applyAll([gCombatStart(1), gInitiativeRequest(2, null)]);
        expect(prep.view.initiative.status, GrimoireInitiativeStatus.requested);
        final withInitiative = applyAll([
          gCombatStart(1, participants: grimoireRoster(ariaInitiative: 12)),
          gInitiativeRequest(2, null),
        ]).view;
        expect(withInitiative.initiative.status, GrimoireInitiativeStatus.idle);
      },
    );

    test('demandée par initiative_requested_for d\'un state', () {
      final result = step(
        applyAll([gCombatStart(1)]).view,
        gState(2, requested: ['c-player']),
      );
      expect(result.view.initiative.status, GrimoireInitiativeStatus.requested);
    });

    test('envoi : en cours, envoyée (valeur gardée), annonce', () {
      final sending = markInitiativeSending(prepRequested());
      expect(sending.initiative.status, GrimoireInitiativeStatus.sending);
      final sent = markInitiativeSent(
        sending,
        combatId: kCombatA,
        value: 15,
        at: t0,
      );
      expect(sent.view.initiative.status, GrimoireInitiativeStatus.sent);
      expect(sent.view.initiative.sentValue, 15);
      expect(sent.events.single, (
        kind: GrimoireCombatEventKind.initiativeSent,
        value: 15,
        round: null,
        name: null,
      ));
    });

    test('envoi d\'un combat remplacé entre-temps : ignoré', () {
      final view = step(
        prepRequested(),
        gCombatStart(1, combatId: kCombatB),
      ).view;
      final sent = markInitiativeSent(
        view,
        combatId: kCombatA,
        value: 15,
        at: t0,
      );
      expect(sent.view.initiative.status, GrimoireInitiativeStatus.idle);
    });

    test('reçue : state où le personnage n\'est plus demandé', () {
      final sent = markInitiativeSent(
        prepRequested(),
        combatId: kCombatA,
        value: 15,
        at: t0,
      ).view;
      final result = step(
        sent,
        gState(3),
        at: t0.add(const Duration(seconds: 2)),
      );
      expect(result.view.initiative.status, GrimoireInitiativeStatus.received);
      expect(result.view.initiative.sentValue, 15);
      expect(result.view.showsInitiativeCard, isTrue);
      expect(
        kinds(result.events),
        contains(GrimoireCombatEventKind.initiativeReceived),
      );
    });

    test('reçue : ordre où la ligne du joueur porte une initiative', () {
      final sent = markInitiativeSent(
        prepRequested(),
        combatId: kCombatA,
        value: 18,
        at: t0,
      ).view;
      final result = step(sent, gOrder(3, grimoireRoster(), current: 'p-gob'));
      expect(result.view.initiative.status, GrimoireInitiativeStatus.received);
      // La ligne du joueur prend le relais : plus de carte une fois dévoilé.
      expect(result.view.showsInitiativeCard, isFalse);
    });

    test(
      'non reçue : state plus de 5 s après l\'envoi qui le liste encore',
      () {
        final sent = markInitiativeSent(
          prepRequested(),
          combatId: kCombatA,
          value: 15,
          at: t0,
        ).view;
        final early = step(
          sent,
          gState(3, requested: ['c-player']),
          at: t0.add(const Duration(seconds: 3)),
        );
        expect(early.view.initiative.status, GrimoireInitiativeStatus.sent);
        final late = step(
          sent,
          gState(3, requested: ['c-player']),
          at: t0.add(const Duration(seconds: 6)),
        );
        expect(
          late.view.initiative.status,
          GrimoireInitiativeStatus.notReceived,
        );
        expect(late.view.initiative.canSend, isTrue);
      },
    );

    test('redemandée après réception', () {
      final received = step(
        markInitiativeSent(
          prepRequested(),
          combatId: kCombatA,
          value: 15,
          at: t0,
        ).view,
        gState(3),
      ).view;
      final result = step(received, gInitiativeRequest(4, ['c-player']));
      expect(
        result.view.initiative.status,
        GrimoireInitiativeStatus.requestedAgain,
      );
      expect(
        kinds(result.events),
        contains(GrimoireCombatEventKind.initiativeRequested),
      );
    });

    test('échec : motif gardé, bouton réactivé', () {
      final failed = markInitiativeFailed(
        markInitiativeSending(prepRequested()),
        combatId: kCombatA,
        failure: const GrimoireFailure(
          GrimoireFailureKind.rateLimited,
          retryAfterSeconds: 30,
        ),
      );
      expect(failed.initiative.status, GrimoireInitiativeStatus.failed);
      expect(failed.initiative.failure?.retryAfterSeconds, 30);
      expect(failed.initiative.canSend, isTrue);
    });

    test('valeur corrigée par le MJ : signalée et annoncée une fois', () {
      final sent = markInitiativeSent(
        prepRequested(),
        combatId: kCombatA,
        value: 15,
        at: t0,
      ).view;
      final result = step(sent, gOrder(3, grimoireRoster(), current: 'p-gob'));
      expect(result.view.correctedFrom(kMe), 15);
      expect(
        result.events.where(
          (e) => e.kind == GrimoireCombatEventKind.initiativeCorrected,
        ),
        [
          (
            kind: GrimoireCombatEventKind.initiativeCorrected,
            value: 18,
            round: null,
            name: null,
          ),
        ],
      );
      final again = step(
        result.view,
        gOrder(4, grimoireRoster(), current: 'p-brun'),
      );
      expect(
        kinds(again.events),
        isNot(contains(GrimoireCombatEventKind.initiativeCorrected)),
      );
    });

    test('valeur envoyée inconnue (app relancée) : rien de corrigé', () {
      expect(revealed().correctedFrom(kMe), isNull);
    });

    test('identité connue après coup : demande réévaluée sans annonce', () {
      const anonymous = (userId: 'player-1', characterId: null);
      final view = applyAll([
        gCombatStart(1),
        gInitiativeRequest(2, ['c-player']),
      ], me: anonymous).view;
      expect(view.initiative.status, GrimoireInitiativeStatus.idle);
      final reconciled = reconcileGrimoireInitiative(view, kMe);
      expect(reconciled.initiative.status, GrimoireInitiativeStatus.requested);
    });
  });

  group('héros mort (décision 58, characters.is_dead)', () {
    GroupMember member(String characterId, {bool? isDead}) => GroupMember(
      userId: 'u-$characterId',
      characterId: characterId,
      role: GroupRole.membre,
      name: characterId,
      isGameMaster: false,
      isDead: isDead,
    );

    test('rapproché par character_id, jamais pour un pnj', () {
      final dead = grimoireDeadCharacterIds([
        member('c-brun', isDead: true),
        member('c-player', isDead: false),
        member('c-x'),
      ]);
      expect(dead, {'c-brun'});
      const brun = GrimoireParticipant(
        id: 'p-brun',
        kind: ParticipantKind.pc,
        name: 'Brun',
        characterId: 'c-brun',
      );
      const npc = GrimoireParticipant(
        id: 'p-npc',
        kind: ParticipantKind.npc,
        name: 'Brun',
        characterId: 'c-brun',
      );
      const unlinked = GrimoireParticipant(
        id: 'p-u',
        kind: ParticipantKind.pc,
        name: 'Inconnu',
      );
      expect(isGrimoireParticipantDead(brun, dead), isTrue);
      expect(isGrimoireParticipantDead(npc, dead), isFalse);
      expect(isGrimoireParticipantDead(unlinked, dead), isFalse);
    });
  });

  group('ordre et progression', () {
    test('tableau tel quel, jamais retrié ; initiatives N/M publiques', () {
      final view = revealed();
      expect(view.participants.map((p) => p.id), ['p-aria', 'p-gob', 'p-brun']);
      expect(view.initiativeProgress, (entered: 2, total: 3));
      expect(view.mine(kMe)?.id, 'p-aria');
    });
  });
}
