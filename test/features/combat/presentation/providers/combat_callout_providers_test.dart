// Signal global de combat (`docs/combat-grimoire-ui.md` §5, §6) : variantes,
// priorités, fin du tour, fin et expiration du combat, exclusion,
// dédoublonnage par groupe et par type (60 s) entre notification push et
// canal du groupe, absence sur l'écran Combat du groupe concerné.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/router/app_router.dart';
import 'package:personnages/core/router/route_stack_observer.dart';
import 'package:personnages/features/combat/domain/combat_notification.dart';
import 'package:personnages/features/combat/domain/grimoire_combat_reducer.dart';
import 'package:personnages/features/combat/domain/grimoire_combat_session.dart';
import 'package:personnages/features/combat/domain/grimoire_combat_view.dart';
import 'package:personnages/features/combat/presentation/providers/combat_callout_providers.dart';
import 'package:personnages/features/combat/presentation/providers/combat_providers.dart';

import '../../../../support/grimoire_fixtures.dart';

const _g1 = 'group-1';
const _g2 = 'group-2';

/// Page de test portant le nom et les paramètres que `go_router` pose.
PageRoute<void> _page(String? name, {String? id}) => PageRouteBuilder<void>(
  settings: RouteSettings(name: name, arguments: <String, String>{'id': ?id}),
  pageBuilder: (context, animation, secondaryAnimation) =>
      const SizedBox.shrink(),
);

/// Suit les vues successives d'un groupe comme le suivi réel : chaque
/// message reçu donne un nouvel état de session (évènements + numéro).
class _GroupFeed {
  _GroupFeed(this.container, this.groupId);

  final ProviderContainer container;
  final String groupId;
  GrimoireCombatSession session = const GrimoireCombatSession(
    link: GrimoireLinkStatus.subscribed,
  );
  DateTime at = DateTime(2026, 11, 23, 21);

  /// Applique [messages] un par un et transmet chaque transition au signal.
  void receive(
    List<Map<String, dynamic>> messages, {
    GrimoireIdentity me = kMe,
  }) {
    for (final message in messages) {
      final step = applyGrimoireMessage(
        session.view,
        decoded(message),
        me: me,
        receivedAt: at,
      );
      at = at.add(const Duration(seconds: 1));
      push(
        session.copyWith(
          view: step.view,
          events: step.events.isEmpty ? session.events : step.events,
          eventSerial: step.events.isEmpty
              ? session.eventSerial
              : session.eventSerial + 1,
        ),
        me: me,
      );
    }
  }

  void push(GrimoireCombatSession next, {GrimoireIdentity me = kMe}) {
    final previous = session;
    session = next;
    container
        .read(combatCalloutControllerProvider.notifier)
        .onSession(groupId, previous, next, me: me);
  }
}

void main() {
  late ProviderContainer container;
  late DateTime now;

  setUp(() {
    now = DateTime(2026, 11, 23, 21);
    container = ProviderContainer(
      overrides: [combatClockProvider.overrideWithValue(() => now)],
    );
    addTearDown(container.dispose);
  });

  CombatCallout? callout() => container.read(combatCalloutControllerProvider);
  CombatCalloutController controller() =>
      container.read(combatCalloutControllerProvider.notifier);

  group('variantes', () {
    test('combat_start reçu : « Combat ! » ; la demande d\'initiative qui '
        'suit garde le même signal', () {
      final feed = _GroupFeed(container, _g1)..receive([gCombatStart(1)]);
      final shown = callout()!;
      expect(shown.groupId, _g1);
      expect(shown.kind, CombatCalloutKind.combatStart);
      expect(shown.isTurn, isFalse);
      feed.receive([
        gInitiativeRequest(2, ['c-player']),
      ]);
      expect(callout(), shown);
    });

    test('demande d\'initiative seule (redemandée) : « Initiative '
        'demandée »', () {
      final feed = _GroupFeed(container, _g1)..receive([gCombatStart(1)]);
      controller().dismiss(callout()!.id);
      feed.receive([
        gInitiativeRequest(2, ['c-player']),
      ]);
      expect(callout()!.kind, CombatCalloutKind.initiativeRequested);
    });

    test('demande qui ne concerne pas le joueur : aucun signal', () {
      final feed = _GroupFeed(container, _g1)..receive([gCombatStart(1)]);
      controller().dismiss(callout()!.id);
      feed.receive([
        gInitiativeRequest(2, ['c-brun']),
      ]);
      expect(callout(), isNull);
    });

    test('turn qui désigne le joueur : variante tour ; jamais sur order ni '
        'state', () {
      final feed = _GroupFeed(container, _g1)
        ..receive([
          gCombatStart(1),
          gOrder(2, grimoireRoster(), current: 'p-aria'),
        ]);
      controller().dismiss(callout()!.id);
      feed.receive([
        gState(3, participants: grimoireRoster(), current: 'p-aria'),
      ]);
      expect(callout(), isNull);
      feed.receive([gTurn(4, 'p-gob'), gTurn(5, 'p-aria', round: 2)]);
      expect(callout()!.kind, CombatCalloutKind.yourTurn);
      expect(callout()!.isTurn, isTrue);
    });

    test('un seul signal : le tour remplace une annonce ; une annonce '
        'n\'efface jamais le tour', () {
      final first = _GroupFeed(container, _g1)
        ..receive([
          gCombatStart(1),
          gOrder(2, grimoireRoster(), current: 'p-gob'),
        ]);
      expect(callout()!.kind, CombatCalloutKind.combatStart);
      first.receive([gTurn(3, 'p-aria')]);
      expect(callout()!.kind, CombatCalloutKind.yourTurn);
      _GroupFeed(container, _g2).receive([gCombatStart(1)]);
      expect(callout()!.groupId, _g1);
      expect(callout()!.kind, CombatCalloutKind.yourTurn);
    });
  });

  group('disparition', () {
    _GroupFeed myTurn() => _GroupFeed(container, _g1)
      ..receive([
        gCombatStart(1),
        gOrder(2, grimoireRoster(), current: 'p-gob'),
        gTurn(3, 'p-aria'),
      ]);

    test('fin du tour (turn suivant) : le signal tour disparaît', () {
      final feed = myTurn();
      expect(callout()!.isTurn, isTrue);
      feed.receive([gTurn(4, 'p-brun')]);
      expect(callout(), isNull);
    });

    test('order ou state qui déplace le tour : disparu', () {
      final feed = myTurn();
      feed.receive([gOrder(4, grimoireRoster(), current: 'p-gob')]);
      expect(callout(), isNull);
      final again = _myTurnAgain(feed);
      expect(again, isTrue);
      feed.receive([
        gState(7, participants: grimoireRoster(), current: 'p-brun'),
      ]);
      expect(callout(), isNull);
    });

    test('retrait du joueur, fin du combat, expiration, exclusion', () {
      var feed = myTurn();
      feed.receive([gRemoved(4, 'p-aria')]);
      expect(callout(), isNull);

      container.invalidate(combatCalloutControllerProvider);
      feed = myTurn();
      feed.receive([gEnd(4)]);
      expect(callout(), isNull);

      container.invalidate(combatCalloutControllerProvider);
      feed = _GroupFeed(container, _g1)..receive([gCombatStart(1)]);
      final step = tickGrimoireCombat(
        feed.session.view,
        now: feed.at.add(kGrimoireExpireAfter),
        canJudgeGm: true,
      );
      feed.push(
        feed.session.copyWith(
          view: step.view,
          events: step.events,
          eventSerial: feed.session.eventSerial + 1,
        ),
      );
      expect(callout(), isNull);

      container.invalidate(combatCalloutControllerProvider);
      feed = _GroupFeed(container, _g1)..receive([gCombatStart(1)]);
      feed.push(
        GrimoireCombatSession(
          link: GrimoireLinkStatus.lost,
          eventSerial: feed.session.eventSerial,
        ),
      );
      expect(callout(), isNull);
    });

    test('groupe quitté et changement de compte : plus de signal', () {
      _GroupFeed(container, _g1).receive([gCombatStart(1)]);
      controller().groupGone(_g2);
      expect(callout(), isNotNull);
      controller().groupGone(_g1);
      expect(callout(), isNull);
      _GroupFeed(container, _g2).receive([gCombatStart(1)]);
      controller().reset();
      expect(callout(), isNull);
    });
  });

  group('notification push reçue app ouverte', () {
    const start = (type: CombatNotificationType.combatStart, groupId: _g1);
    const turn = (type: CombatNotificationType.yourTurn, groupId: _g1);

    test('signal correspondant ; push en double pendant qu\'il est affiché : '
        'ignoré ; aucune fenêtre de temps après sa fermeture', () {
      controller().showFromPush(start);
      final shown = callout()!;
      expect(shown.kind, CombatCalloutKind.combatStart);
      controller().showFromPush(start);
      expect(callout(), shown);
      controller()
        ..dismiss(shown.id)
        ..showFromPush(start);
      expect(callout()!.kind, CombatCalloutKind.combatStart);
      expect(callout()!.id, isNot(shown.id));
    });

    test('push « À toi de jouer » quand le canal montre déjà ce tour : '
        'ignoré, même signal fermé', () {
      _GroupFeed(container, _g1).receive([
        gCombatStart(1),
        gOrder(2, grimoireRoster(), current: 'p-gob'),
        gTurn(3, 'p-aria'),
      ]);
      controller()
        ..dismiss(callout()!.id)
        ..showFromPush(turn);
      expect(callout(), isNull);
    });

    test('canal puis push du même évènement : un seul signal', () {
      _GroupFeed(container, _g1).receive([gCombatStart(1)]);
      final shown = callout()!;
      controller()
        ..dismiss(shown.id)
        ..showFromPush(start);
      expect(callout(), isNull);
    });

    test('push puis canal du même tour : pas de second signal (ni haptique '
        'ni annonce répétées)', () {
      final feed = _GroupFeed(container, _g1)
        ..receive([
          gCombatStart(1),
          gOrder(2, grimoireRoster(), current: 'p-gob'),
        ]);
      controller()
        ..dismiss(callout()!.id)
        ..showFromPush(turn);
      final shown = callout()!;
      expect(shown.isTurn, isTrue);
      feed.receive([gTurn(3, 'p-aria')]);
      expect(callout()!.id, shown.id);
      // Fermé par le joueur : le même tour reçu de nouveau sur le canal ne le
      // rouvre pas.
      controller().dismiss(shown.id);
      feed.receive([
        gState(4, participants: grimoireRoster(), current: 'p-aria'),
      ]);
      expect(callout(), isNull);
    });

    test('Q5 : tour annoncé par push, puis un vrai nouveau tour du même '
        'joueur moins de 60 s après : affiché', () {
      final feed = _GroupFeed(container, _g1)
        ..receive([
          gCombatStart(1),
          gOrder(2, grimoireRoster(), current: 'p-gob'),
        ]);
      controller()
        ..dismiss(callout()!.id)
        ..showFromPush(turn);
      final pushed = callout()!;
      // Le même tour arrive sur le canal : un seul signal.
      feed.receive([gTurn(3, 'p-aria')]);
      expect(callout()!.id, pushed.id);
      now = now.add(const Duration(seconds: 20));
      // Tour suivant, puis de nouveau le joueur (round 2) : nouveau tour.
      feed.receive([gTurn(4, 'p-brun')]);
      expect(callout(), isNull);
      now = now.add(const Duration(seconds: 20));
      feed.receive([gTurn(5, 'p-aria', round: 2)]);
      expect(callout()!.isTurn, isTrue);
      expect(callout()!.id, isNot(pushed.id));
    });

    test('deux tours reçus sur le canal : deux signaux (évènements '
        'distincts)', () {
      final feed = _GroupFeed(container, _g1)
        ..receive([
          gCombatStart(1),
          gOrder(2, grimoireRoster(), current: 'p-gob'),
          gTurn(3, 'p-aria'),
        ]);
      final first = callout()!.id;
      feed.receive([gTurn(4, 'p-brun'), gTurn(5, 'p-aria', round: 2)]);
      expect(callout()!.isTurn, isTrue);
      expect(callout()!.id, isNot(first));
    });

    test('tour annoncé par push avant tout état : gardé tant que l\'état ne '
        'dit pas que le tour est passé', () {
      controller().showFromPush(turn);
      final feed = _GroupFeed(container, _g1)
        ..push(
          GrimoireCombatSession(
            link: GrimoireLinkStatus.subscribed,
            view: applyAll([
              gState(1, participants: grimoireRoster(), current: 'p-aria'),
            ]).view,
          ),
        );
      expect(callout()!.isTurn, isTrue);
      feed.receive([gTurn(2, 'p-gob')]);
      expect(callout(), isNull);
    });
  });

  group('meneur du groupe (is_leader)', () {
    test('aucun signal, ni annonce ni tour ; un signal déjà affiché est '
        'retiré', () {
      final feed = _GroupFeed(container, _g1)..receive([gCombatStart(1)]);
      expect(callout(), isNotNull);
      feed
        ..push(feed.session.copyWith(isLeader: true))
        ..session = feed.session.copyWith(isLeader: true);
      expect(callout(), isNull);
      final leader = _GroupFeed(container, _g2)
        ..session = const GrimoireCombatSession(
          link: GrimoireLinkStatus.subscribed,
          isLeader: true,
        )
        ..receive([
          gCombatStart(1),
          gInitiativeRequest(2, ['c-player']),
          gOrder(3, grimoireRoster(), current: 'p-gob'),
          gTurn(4, 'p-aria'),
        ]);
      expect(leader.session.isLeader, isTrue);
      expect(callout(), isNull);
    });
  });

  group('écran Combat du groupe', () {
    test('affiché : aucun signal pour ce groupe (l\'écran signale lui-même), '
        'signal des autres groupes', () async {
      container.read(routeStackObserverProvider)
        ..didPush(_page('group-detail', id: _g1), null)
        ..didPush(_page(kGroupCombatRouteName, id: _g1), null);
      await pumpEventQueue();
      _GroupFeed(container, _g1).receive([gCombatStart(1)]);
      expect(callout(), isNull);
      _GroupFeed(container, _g2).receive([gCombatStart(1)]);
      expect(callout()!.groupId, _g2);
    });

    test('ouvert pendant que le signal est affiché : signal retiré', () async {
      _GroupFeed(container, _g1).receive([gCombatStart(1)]);
      expect(callout(), isNotNull);
      final routes = container.read(routeStackObserverProvider)
        ..didPush(_page(kGroupCombatRouteName, id: _g2), null);
      await pumpEventQueue();
      expect(callout(), isNotNull);
      routes.didPush(_page(kGroupCombatRouteName, id: _g1), null);
      await pumpEventQueue();
      expect(callout(), isNull);
    });
  });
}

/// Rend le tour au joueur après un déplacement (utilitaire des tests de
/// disparition) : `true` si le signal tour est revenu.
bool _myTurnAgain(_GroupFeed feed) {
  feed.receive([gTurn(5, 'p-aria', round: 2)]);
  return feed.container.read(combatCalloutControllerProvider)?.isTurn ?? false;
}
