// Client du canal Grimoire : lecture des sujets, abonnement privé au sujet
// `:gm`, présence au premier plan seulement, `state_request`, réabonnements,
// envoi d'initiative et ses erreurs, minuteries (horloge injectée).

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/features/combat/data/grimoire_combat_gateway.dart';
import 'package:personnages/features/combat/domain/grimoire_combat_reducer.dart';
import 'package:personnages/features/combat/domain/grimoire_combat_session.dart';
import 'package:personnages/features/combat/domain/grimoire_combat_view.dart';
import 'package:personnages/features/combat/domain/grimoire_failure.dart';
import 'package:personnages/features/combat/presentation/providers/combat_providers.dart';
import 'package:personnages/features/combat/presentation/providers/grimoire_banner_provider.dart';
import 'package:personnages/features/combat/presentation/providers/grimoire_combat_providers.dart';
import 'package:personnages/features/combat/presentation/widgets/combat_banner_mode.dart';

import '../../../../support/fake_connectivity_checker.dart';
import '../../../../support/fake_current_user.dart';
import '../../../../support/fake_grimoire_combat_gateway.dart';
import '../../../../support/grimoire_fixtures.dart';

const groupId = 'group-1';

void main() {
  late FakeGrimoireCombatGateway gateway;
  late FakeConnectivityChecker connectivity;
  late ProviderContainer container;
  late DateTime now;

  setUp(() {
    gateway = FakeGrimoireCombatGateway();
    connectivity = FakeConnectivityChecker();
    now = DateTime(2026, 11, 23, 21);
    container = ProviderContainer(
      overrides: [
        currentUserFromTestOverride,
        grimoireCombatGatewayProvider.overrideWithValue(gateway),
        connectivityCheckerProvider.overrideWithValue(connectivity),
        combatClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(connectivity.close);
  });

  /// Test à minuteries simulées ; le conteneur est libéré à la fin du corps
  /// (le planificateur de Riverpod n'a plus de minuterie en attente).
  void grimoireTest(
    String description,
    Future<void> Function(WidgetTester tester) body,
  ) {
    testWidgets(description, (tester) async {
      await body(tester);
      container.dispose();
    });
  }

  GrimoireCombatSession read() =>
      container.read(grimoireCombatProvider(groupId));

  GrimoireCombatNotifier notifier() =>
      container.read(grimoireCombatProvider(groupId).notifier);

  /// Garde le client vivant, comme un écran qui l'observe.
  ProviderSubscription<void> watch() => container.listen(
    grimoireCombatFocusProvider(groupId),
    (_, _) {},
    fireImmediately: true,
  );

  /// Laisse passer [duration] (minuteries simulées) en avançant l'horloge.
  Future<void> elapse(WidgetTester tester, Duration duration) async {
    now = now.add(duration);
    await tester.pump(duration);
  }

  Future<void> connect(WidgetTester tester) async {
    watch();
    await tester.pump();
    await tester.pump();
    notifier().setIdentity(kMe);
  }

  group('abonnement', () {
    grimoireTest('sujets lus par group_live_channels, canal :gm, présence puis '
        'state_request après SUBSCRIBED', (tester) async {
      await connect(tester);
      expect(gateway.topicsReads, 1);
      expect(gateway.links, hasLength(1));
      expect(gateway.lastLink.topic, 'grimoire:v1:group:group-1:e1:gm');
      expect(gateway.lastLink.presenceKey, 'user-1');
      expect(gateway.lastLink.tracks, 1);
      expect(read().link, GrimoireLinkStatus.subscribed);
      expect(gateway.stateRequests, hasLength(1));
      // Jamais de `combat_id` : Grimoire répond avec son combat en cours.
      expect(gateway.stateRequests.single.payload, isEmpty);
      expect(gateway.stateRequests.single.groupId, groupId);
    });

    grimoireTest('suivi de fond sans écran : SUBSCRIBED sans state_request ; '
        "un écran qui s'ouvre ensuite le demande une fois", (tester) async {
      container.listen(
        grimoireCombatWatcherProvider(groupId),
        (_, _) {},
        fireImmediately: true,
      );
      await tester.pump();
      await tester.pump();
      expect(read().link, GrimoireLinkStatus.subscribed);
      expect(gateway.lastLink.tracks, 1);
      expect(gateway.stateRequests, isEmpty);

      final screen = watch();
      await tester.pump();
      await tester.pump();
      expect(gateway.links, hasLength(1));
      expect(gateway.stateRequests, hasLength(1));

      // Un état reçu : un écran rouvert plus tard ne redemande rien.
      gateway.lastLink.emit(gState(1, participants: grimoireRoster()));
      screen.close();
      await tester.pump(const Duration(milliseconds: 1));
      now = now.add(const Duration(seconds: 5));
      watch();
      await tester.pump();
      await tester.pump();
      expect(gateway.stateRequests, hasLength(1));
    });

    grimoireTest('meneur : is_leader retenu', (tester) async {
      gateway.topics = (
        epoch: 4,
        gmTopic: 'grimoire:v1:group:g:e4:gm',
        isLeader: true,
      );
      await connect(tester);
      expect(read().isLeader, isTrue);
    });

    grimoireTest('arrière-plan : canal quitté (présence retirée), retour : '
        'réabonnement et state_request', (tester) async {
      final binding = tester.binding;
      addTearDown(
        () => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed),
      );
      await connect(tester);
      final first = gateway.lastLink;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(first.closed, isTrue);
      expect(read().link, GrimoireLinkStatus.idle);

      // `inactive` (centre de notifications) ne change rien.
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(gateway.links, hasLength(1));

      await elapse(tester, const Duration(seconds: 3));
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump();
      expect(gateway.links, hasLength(2));
      expect(gateway.topicsReads, 2);
      expect(gateway.lastLink.tracks, 1);
      expect(gateway.stateRequests, hasLength(2));
    });

    grimoireTest('channel_rotated : ancien canal retiré, sujets relus', (
      tester,
    ) async {
      await connect(tester);
      final first = gateway.lastLink;
      gateway.topics = (
        epoch: 2,
        gmTopic: 'grimoire:v1:group:group-1:e2:gm',
        isLeader: false,
      );
      first.emit(gRotated());
      await tester.pump();
      await tester.pump();
      expect(first.closed, isTrue);
      expect(gateway.topicsReads, 2);
      expect(gateway.lastLink.topic, 'grimoire:v1:group:group-1:e2:gm');
      // `channel_rotated` n'est jamais un message du MJ.
      expect(read().view.lastReceivedAt, isNull);
    });

    grimoireTest('CHANNEL_ERROR : canal retiré, nouvel essai différé', (
      tester,
    ) async {
      await connect(tester);
      final first = gateway.lastLink;
      first.signal(GrimoireChannelSignal.error);
      await tester.pump();
      expect(first.closed, isTrue);
      expect(read().link, GrimoireLinkStatus.down);
      expect(gateway.links, hasLength(1));
      await elapse(tester, kGrimoireRetryDelays.first);
      await tester.pump();
      expect(gateway.topicsReads, 2);
      expect(gateway.links, hasLength(2));
      expect(read().link, GrimoireLinkStatus.subscribed);
    });

    grimoireTest('group_not_found : plus aucun essai', (tester) async {
      gateway.topicsFailure = const GrimoireFailure(
        GrimoireFailureKind.groupNotFound,
      );
      await connect(tester);
      expect(read().link, GrimoireLinkStatus.lost);
      await elapse(tester, const Duration(minutes: 1));
      expect(gateway.topicsReads, 1);
      expect(gateway.links, isEmpty);
    });

    grimoireTest('écran fermé : canal quitté, minuteries arrêtées', (
      tester,
    ) async {
      final subscription = watch();
      await tester.pump();
      await tester.pump();
      notifier().setIdentity(kMe);
      gateway.lastLink.emit(gCombatStart(1));
      subscription.close();
      // Libération `autoDispose` par le planificateur de Riverpod.
      await tester.pump(const Duration(milliseconds: 1));
      expect(gateway.lastLink.closed, isTrue);
      await elapse(tester, const Duration(minutes: 20));
      // Personne n'écoute : aucune conclusion sur le silence du MJ.
      expect(read().view.liveness, GrimoireLiveness.live);
    });
  });

  group('messages et minuteries', () {
    grimoireTest('state de reprise sans annonce ; combat_start annoncé', (
      tester,
    ) async {
      await connect(tester);
      gateway.lastLink.emit(gState(4, participants: grimoireRoster()));
      expect(read().view.status, GrimoireCombatStatus.active);
      expect(read().eventSerial, 0);
      gateway.lastLink.emit(gCombatStart(1, combatId: kCombatB));
      expect(read().events.single.kind, GrimoireCombatEventKind.combatStarted);
    });

    grimoireTest('trou de seq : state_request', (tester) async {
      await connect(tester);
      gateway.lastLink.emit(gCombatStart(1));
      await elapse(tester, kGrimoireStateRequestGap);
      gateway.lastLink.emit(gTurn(4, 'p-x'));
      expect(gateway.stateRequests, hasLength(2));
    });

    grimoireTest('90 s puis 10 min sans message ; retour du MJ', (
      tester,
    ) async {
      await connect(tester);
      gateway.lastLink.emit(gCombatStart(1));
      await elapse(tester, const Duration(seconds: 89));
      expect(read().view.liveness, GrimoireLiveness.live);
      await elapse(tester, const Duration(seconds: 1));
      expect(read().view.liveness, GrimoireLiveness.gmOffline);
      expect(read().events.single.kind, GrimoireCombatEventKind.gmOffline);
      expect(
        read().displayLiveness(phoneOnline: true),
        GrimoireDisplayLiveness.gmOffline,
      );
      gateway.lastLink.emit(gState(2));
      expect(read().view.liveness, GrimoireLiveness.live);
      expect(read().events.single.kind, GrimoireCombatEventKind.gmBack);
      await elapse(tester, kGrimoireExpireAfter);
      expect(read().view.liveness, GrimoireLiveness.expired);
      expect(read().view.isAlive, isFalse);
    });

    grimoireTest('téléphone hors ligne : jamais « MJ hors ligne »', (
      tester,
    ) async {
      await connect(tester);
      gateway.lastLink.emit(gCombatStart(1));
      connectivity.goOffline();
      await tester.pump();
      await elapse(tester, const Duration(seconds: 120));
      expect(read().view.liveness, GrimoireLiveness.live);
      expect(
        read().displayLiveness(phoneOnline: false),
        GrimoireDisplayLiveness.offline,
      );
    });
  });

  group('envoi d\'initiative', () {
    Future<void> requested(WidgetTester tester) async {
      await connect(tester);
      gateway.lastLink
        ..emit(gCombatStart(1))
        ..emit(gInitiativeRequest(2, ['c-player']));
      expect(read().view.initiative.status, GrimoireInitiativeStatus.requested);
    }

    grimoireTest('send_to_group_leader, puis state_request 2 s après', (
      tester,
    ) async {
      await requested(tester);
      await elapse(tester, const Duration(seconds: 5));
      final before = gateway.stateRequests.length;
      await notifier().sendInitiative(17);
      expect(gateway.initiatives.single.payload, {
        'combat_id': kCombatA,
        'initiative': 17,
      });
      expect(read().view.initiative.status, GrimoireInitiativeStatus.sent);
      expect(read().view.initiative.sentValue, 17);
      expect(read().events.single.kind, GrimoireCombatEventKind.initiativeSent);
      await elapse(tester, const Duration(milliseconds: 1999));
      expect(gateway.stateRequests.length, before);
      await elapse(tester, const Duration(milliseconds: 1));
      expect(gateway.stateRequests.length, before + 1);
    });

    grimoireTest('envoi en cours : état « sending »', (tester) async {
      await requested(tester);
      gateway.sendGate = Completer<void>();
      final future = notifier().sendInitiative(12);
      expect(read().view.initiative.status, GrimoireInitiativeStatus.sending);
      gateway.sendGate!.complete();
      await future;
      expect(read().view.initiative.status, GrimoireInitiativeStatus.sent);
    });

    for (final entry in {
      'rate_limited': const GrimoireFailure(
        GrimoireFailureKind.rateLimited,
        retryAfterSeconds: 42,
      ),
      'no_character': const GrimoireFailure(GrimoireFailureKind.noCharacter),
      'autre': const GrimoireFailure(GrimoireFailureKind.other),
    }.entries) {
      grimoireTest('échec ${entry.key} : motif gardé, nouvel envoi possible', (
        tester,
      ) async {
        await requested(tester);
        gateway.failures['initiative'] = entry.value;
        await notifier().sendInitiative(9);
        final initiative = read().view.initiative;
        expect(initiative.status, GrimoireInitiativeStatus.failed);
        expect(initiative.failure, entry.value);
        expect(initiative.canSend, isTrue);
        expect(read().link, GrimoireLinkStatus.subscribed);
      });
    }
  });

  group('joueur exclu : group_not_found (décision 50)', () {
    /// Combat dévoilé et vivant, bandeau affiché.
    Future<void> running(WidgetTester tester) async {
      await connect(tester);
      gateway.lastLink
        ..emit(gCombatStart(1))
        ..emit(gInitiativeRequest(2, ['c-player']))
        ..emit(gOrder(3, grimoireRoster(), current: 'p-gob'));
      expect(container.read(grimoireBannerProvider(groupId)), isNotNull);
    }

    void expectExcluded() {
      expect(read().isExcluded, isTrue);
      expect(read().view, const GrimoireCombatView());
      expect(gateway.lastLink.closeRequested, isTrue);
      expect(gateway.lastLink.presenceActive, isFalse);
      expect(container.read(grimoireBannerProvider(groupId)), isNull);
      expect(container.read(grimoireCombatAliveProvider(groupId)), isFalse);
    }

    grimoireTest('à l\'envoi d\'initiative : canal fermé, vue effacée', (
      tester,
    ) async {
      await running(tester);
      gateway.failures['initiative'] = const GrimoireFailure(
        GrimoireFailureKind.groupNotFound,
      );
      await notifier().sendInitiative(9);
      await tester.pump(const Duration(milliseconds: 10));
      expectExcluded();
      // Plus aucun message appliqué, plus aucun essai.
      gateway.lastLink.emit(gState(9, participants: grimoireRoster()));
      expect(read().view, const GrimoireCombatView());
      await elapse(tester, const Duration(minutes: 1));
      expect(gateway.links, hasLength(1));
      expect(gateway.topicsReads, 1);
    });

    grimoireTest('en réponse à state_request : canal fermé, vue effacée', (
      tester,
    ) async {
      await running(tester);
      gateway.failures['state_request'] = const GrimoireFailure(
        GrimoireFailureKind.groupNotFound,
      );
      await elapse(tester, kGrimoireStateRequestGap);
      gateway.lastLink.emit(gTurn(9, 'p-brun'));
      await tester.pump(const Duration(milliseconds: 10));
      expectExcluded();
    });

    grimoireTest('à la lecture des sujets (réabonnement)', (tester) async {
      await running(tester);
      gateway.topicsFailure = const GrimoireFailure(
        GrimoireFailureKind.groupNotFound,
      );
      gateway.lastLink.emit(gRotated());
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump(const Duration(milliseconds: 10));
      expectExcluded();
      expect(gateway.links, hasLength(1));
    });
  });

  group('bandeau', () {
    grimoireTest('préparation avec initiative demandée, puis envoyée', (
      tester,
    ) async {
      await connect(tester);
      gateway.lastLink
        ..emit(gCombatStart(1))
        ..emit(gInitiativeRequest(2, ['c-player']));
      var banner = container.read(grimoireBannerProvider(groupId))!;
      expect(banner.mode, CombatBannerMode.preparing);
      expect(banner.initiativeHint, CombatBannerInitiativeHint.send);
      await notifier().sendInitiative(11);
      banner = container.read(grimoireBannerProvider(groupId))!;
      expect(banner.initiativeHint, CombatBannerInitiativeHint.sent);
    });

    grimoireTest('à toi de jouer ; MJ hors ligne ; retiré à l\'expiration', (
      tester,
    ) async {
      await connect(tester);
      gateway.lastLink
        ..emit(gCombatStart(1))
        ..emit(gOrder(2, grimoireRoster(), current: 'p-gob'))
        ..emit(gTurn(3, 'p-aria', round: 2));
      var banner = container.read(grimoireBannerProvider(groupId))!;
      expect(banner.mode, CombatBannerMode.yourTurn);
      expect(banner.round, 2);
      await elapse(tester, kGrimoireGmOfflineAfter);
      banner = container.read(grimoireBannerProvider(groupId))!;
      expect(banner.gmOfflineSince, DateTime.parse(kSentAt));
      await elapse(tester, kGrimoireExpireAfter);
      expect(container.read(grimoireBannerProvider(groupId)), isNull);
      expect(container.read(grimoireCombatAliveProvider(groupId)), isFalse);
    });
  });

  group('arrière-plan et retour (défaut B de la QA)', () {
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
    }

    grimoireTest('arrière-plan 11 min puis retour : aucun état expiré '
        'intermédiaire', (tester) async {
      final binding = tester.binding;
      addTearDown(
        () => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed),
      );
      await connect(tester);
      gateway.lastLink
        ..emit(gCombatStart(1))
        ..emit(gOrder(2, grimoireRoster(), current: 'p-gob'));
      final seen = <GrimoireCombatSession>[];
      container.listen(
        grimoireCombatProvider(groupId),
        (_, next) => seen.add(next),
      );
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await settle(tester);
      expect(gateway.lastLink.closeRequested, isTrue);
      await elapse(tester, const Duration(minutes: 11));
      expect(read().view.liveness, GrimoireLiveness.live);

      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);
      await elapse(tester, const Duration(seconds: 1));
      expect(read().view.isAlive, isTrue);
      // Réponse au `state_request` du réabonnement.
      gateway.lastLink.emit(
        gState(3, participants: grimoireRoster(), current: 'p-gob'),
      );
      await elapse(tester, const Duration(seconds: 10));
      expect(seen, isNotEmpty);
      expect(
        seen.map((session) => session.view.liveness),
        isNot(contains(GrimoireLiveness.expired)),
      );
      expect(seen.every((session) => session.view.isAlive), isTrue);
      expect(
        seen.map((session) => container.read(grimoireBannerProvider(groupId))),
        everyElement(isNotNull),
      );
    });

    grimoireTest('retour sans réponse : expiré seulement après l\'attente de '
        '5 s', (tester) async {
      final binding = tester.binding;
      addTearDown(
        () => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed),
      );
      await connect(tester);
      gateway.lastLink.emit(gCombatStart(1));
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await settle(tester);
      await elapse(tester, const Duration(minutes: 11));
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);
      await elapse(tester, const Duration(seconds: 4));
      expect(read().view.liveness, GrimoireLiveness.live);
      await elapse(tester, const Duration(seconds: 2));
      expect(read().view.liveness, GrimoireLiveness.expired);
    });

    grimoireTest('un seul state_request au retour : le state reçu après un '
        'trou de seq comble le trou', (tester) async {
      final binding = tester.binding;
      addTearDown(
        () => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed),
      );
      await connect(tester);
      gateway.lastLink.emit(gCombatStart(1));
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await settle(tester);
      await elapse(tester, const Duration(seconds: 30));
      final before = gateway.stateRequests.length;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);
      expect(gateway.stateRequests.length, before + 1);
      gateway.lastLink.emit(gState(14, participants: grimoireRoster()));
      await elapse(tester, const Duration(seconds: 5));
      expect(gateway.stateRequests.length, before + 1);
    });
  });

  group('course à la reconnexion (défaut B de la QA)', () {
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
    }

    grimoireTest('rotation, fermeture lente, volet de notifications : une '
        'seule reconnexion ; arrière-plan : plus aucun canal ni présence', (
      tester,
    ) async {
      final binding = tester.binding;
      addTearDown(
        () => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed),
      );
      final slow = Completer<void>();
      gateway.closeGate = slow;
      await connect(tester);
      final first = gateway.lastLink;
      expect(first.tracks, 1);
      first.emit(gRotated());
      await settle(tester);
      expect(first.closeRequested, isTrue);
      // Volet de notifications pendant la fermeture lente.
      binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);
      // Rien n'est ouvert tant que l'ancien canal n'est pas fermé.
      expect(gateway.links, hasLength(1));
      slow.complete();
      await settle(tester);
      expect(gateway.links, hasLength(2));
      expect(gateway.topicsReads, 2);
      expect(gateway.lastLink.tracks, 1);

      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await settle(tester);
      expect(gateway.links.every((link) => link.closeRequested), isTrue);
      expect(gateway.links.any((link) => link.presenceActive), isFalse);
      await elapse(tester, const Duration(minutes: 1));
      expect(gateway.links, hasLength(2));
    });

    grimoireTest('arrière-plan pendant une fermeture lente : aucun canal '
        'rouvert ; retour : un seul canal', (tester) async {
      final binding = tester.binding;
      addTearDown(
        () => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed),
      );
      final slow = Completer<void>();
      gateway.closeGate = slow;
      await connect(tester);
      gateway.lastLink.emit(gRotated());
      await settle(tester);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      slow.complete();
      await settle(tester);
      expect(gateway.links, hasLength(1));
      expect(gateway.links.any((link) => link.presenceActive), isFalse);
      expect(read().link, GrimoireLinkStatus.idle);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);
      expect(gateway.links, hasLength(2));
      expect(gateway.links.where((link) => !link.closeRequested), hasLength(1));
    });

    grimoireTest('arrière-plan pendant la lecture des sujets : aucun canal '
        'ouvert', (tester) async {
      final binding = tester.binding;
      addTearDown(
        () => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed),
      );
      final slow = Completer<void>();
      gateway.topicsGate = slow;
      watch();
      await settle(tester);
      expect(gateway.topicsReads, 1);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      slow.complete();
      await settle(tester);
      expect(gateway.links, isEmpty);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);
      expect(gateway.links, hasLength(1));
      expect(gateway.lastLink.tracks, 1);
    });
  });

  group('compte et groupes', () {
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
    }

    grimoireTest('changement de compte : état purgé, ancien canal fermé, '
        'présence du nouveau compte', (tester) async {
      await connect(tester);
      gateway.lastLink
        ..emit(gCombatStart(1))
        ..emit(gOrder(2, grimoireRoster(), current: 'p-gob'));
      expect(read().view.isRunning, isTrue);
      final first = gateway.lastLink;
      container.read(testUserIdProvider.notifier).set('user-2');
      await settle(tester);
      expect(read().view, const GrimoireCombatView());
      expect(first.closeRequested, isTrue);
      expect(first.presenceActive, isFalse);
      expect(gateway.links, hasLength(2));
      expect(gateway.lastLink.presenceKey, 'user-2');
      expect(gateway.lastLink.tracks, 1);
      expect(container.read(grimoireBannerProvider(groupId)), isNull);
    });

    grimoireTest('déconnexion : état purgé, canal fermé, aucun nouveau canal', (
      tester,
    ) async {
      await connect(tester);
      gateway.lastLink.emit(gCombatStart(1));
      final first = gateway.lastLink;
      container.read(testUserIdProvider.notifier).set(null);
      await settle(tester);
      expect(read().view, const GrimoireCombatView());
      expect(first.closeRequested, isTrue);
      expect(first.presenceActive, isFalse);
      expect(gateway.links, hasLength(1));
      // Un message tardif de l'ancien canal n'est plus appliqué.
      first.emit(gState(5, participants: grimoireRoster()));
      expect(read().view, const GrimoireCombatView());
    });

    grimoireTest('deux groupes ouverts : canaux et vues indépendants', (
      tester,
    ) async {
      await connect(tester);
      container.listen(
        grimoireCombatFocusProvider('group-2'),
        (_, _) {},
        fireImmediately: true,
      );
      await settle(tester);
      container
          .read(grimoireCombatProvider('group-2').notifier)
          .setIdentity(kMe);
      expect(gateway.links, hasLength(2));
      GrimoireCombatSession other() =>
          container.read(grimoireCombatProvider('group-2'));

      gateway.linkFor(groupId).emit(gCombatStart(1));
      expect(read().view.isRunning, isTrue);
      expect(other().view.isRunning, isFalse);

      gateway.linkFor('group-2')
        ..emit(gCombatStart(1, combatId: kCombatB))
        ..emit(gInitiativeRequest(2, ['c-player'], combatId: kCombatB));
      expect(other().view.combatId, kCombatB);
      expect(
        other().view.initiative.status,
        GrimoireInitiativeStatus.requested,
      );
      expect(read().view.initiative.status, GrimoireInitiativeStatus.idle);

      gateway.linkFor(groupId).emit(gEnd(2));
      expect(read().view.isAlive, isFalse);
      expect(other().view.isAlive, isTrue);
      expect(gateway.stateRequests.map((message) => message.groupId).toSet(), {
        groupId,
        'group-2',
      });
    });
  });

  group('relecture du code', () {
    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
    }

    grimoireTest('écran fermé puis changement de réseau : aucune conclusion ; '
        'réouverture : pas de « MJ hors ligne » pendant l\'attente', (
      tester,
    ) async {
      final subscription = watch();
      await settle(tester);
      notifier().setIdentity(kMe);
      gateway.lastLink.emit(gCombatStart(1));
      // Un autre observateur garde le suivi vivant, mais plus aucun écran
      // n'écoute le canal.
      container.listen(grimoireCombatProvider(groupId), (_, _) {});
      subscription.close();
      await tester.pump(const Duration(milliseconds: 1));
      await elapse(tester, const Duration(seconds: 100));
      connectivity.goOffline();
      await settle(tester);
      connectivity.goOnline();
      await settle(tester);
      expect(read().view.liveness, GrimoireLiveness.live);

      watch();
      await settle(tester);
      expect(
        read().displayLiveness(phoneOnline: true),
        GrimoireDisplayLiveness.normal,
      );
      await elapse(tester, const Duration(seconds: 3));
      expect(read().view.liveness, GrimoireLiveness.live);
    });

    grimoireTest('arrière-plan : la demande d\'état en attente ne part pas', (
      tester,
    ) async {
      final binding = tester.binding;
      addTearDown(
        () => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed),
      );
      await connect(tester);
      final before = gateway.stateRequests.length;
      // Trou de seq moins de 2 s après le premier `state_request` : demande
      // différée.
      gateway.lastLink
        ..emit(gCombatStart(1))
        ..emit(gTurn(5, 'p-x'));
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await elapse(tester, const Duration(seconds: 3));
      expect(gateway.stateRequests.length, before);
    });

    grimoireTest(
      'rate_limited sur state_request : pause de retryAfterSeconds',
      (tester) async {
        gateway.failures['state_request'] = const GrimoireFailure(
          GrimoireFailureKind.rateLimited,
          retryAfterSeconds: 20,
        );
        await connect(tester);
        await settle(tester);
        gateway.failures.remove('state_request');
        final before = gateway.stateRequests.length;
        await elapse(tester, const Duration(seconds: 5));
        gateway.lastLink
          ..emit(gCombatStart(1))
          ..emit(gTurn(5, 'p-x'));
        await elapse(tester, const Duration(seconds: 3));
        expect(gateway.stateRequests.length, before);
        await elapse(tester, const Duration(seconds: 15));
        gateway.lastLink.emit(gTurn(9, 'p-y'));
        expect(gateway.stateRequests.length, before + 1);
      },
    );

    grimoireTest('rate_limited sur l\'initiative : les state_request attendent '
        'aussi (limite partagée)', (tester) async {
      await connect(tester);
      gateway.lastLink
        ..emit(gCombatStart(1))
        ..emit(gInitiativeRequest(2, ['c-player']));
      await elapse(tester, const Duration(seconds: 3));
      gateway.failures['initiative'] = const GrimoireFailure(
        GrimoireFailureKind.rateLimited,
        retryAfterSeconds: 30,
      );
      await notifier().sendInitiative(7);
      final before = gateway.stateRequests.length;
      await elapse(tester, const Duration(seconds: 3));
      gateway.lastLink.emit(gTurn(6, 'p-x'));
      await elapse(tester, const Duration(seconds: 3));
      expect(gateway.stateRequests.length, before);
    });

    grimoireTest('canal qui retombe aussitôt : essais espacés ; abonnement '
        'stable ou message reçu : premier délai', (tester) async {
      await connect(tester);
      gateway.lastLink.signal(GrimoireChannelSignal.error);
      await settle(tester);
      await elapse(tester, kGrimoireRetryDelays[0]);
      expect(gateway.links, hasLength(2));
      // Retombe aussitôt : le délai suivant s'applique.
      gateway.lastLink.signal(GrimoireChannelSignal.error);
      await settle(tester);
      await elapse(tester, kGrimoireRetryDelays[0]);
      expect(gateway.links, hasLength(2));
      await elapse(tester, kGrimoireRetryDelays[1] - kGrimoireRetryDelays[0]);
      expect(gateway.links, hasLength(3));
      // Abonnement stable : retour au premier délai.
      await elapse(tester, kGrimoireStableSubscription);
      gateway.lastLink.signal(GrimoireChannelSignal.error);
      await settle(tester);
      await elapse(tester, kGrimoireRetryDelays[0]);
      expect(gateway.links, hasLength(4));
      // Un message reçu prouve que le canal fonctionne : premier délai aussi.
      gateway.lastLink
        ..emit(gCombatStart(1))
        ..signal(GrimoireChannelSignal.error);
      await settle(tester);
      await elapse(tester, kGrimoireRetryDelays[0]);
      expect(gateway.links, hasLength(5));
    });

    grimoireTest('API absente (PGRST106) : plus aucun essai, aucun combat', (
      tester,
    ) async {
      gateway.topicsFailure = const GrimoireFailure(
        GrimoireFailureKind.unavailable,
        rawMessage: 'PGRST106',
      );
      await connect(tester);
      expect(read().link, GrimoireLinkStatus.unavailable);
      await elapse(tester, const Duration(minutes: 2));
      expect(gateway.topicsReads, 1);
      expect(gateway.links, isEmpty);
      expect(read().view.isAlive, isFalse);
      expect(container.read(grimoireBannerProvider(groupId)), isNull);
    });
  });
}
