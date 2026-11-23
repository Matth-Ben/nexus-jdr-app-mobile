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
    grimoireCombatWatcherProvider(groupId),
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

    grimoireTest('échec group_not_found : lien perdu', (tester) async {
      await requested(tester);
      gateway.failures['initiative'] = const GrimoireFailure(
        GrimoireFailureKind.groupNotFound,
      );
      await notifier().sendInitiative(9);
      expect(
        read().view.initiative.failure?.kind,
        GrimoireFailureKind.groupNotFound,
      );
      expect(read().link, GrimoireLinkStatus.lost);
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
}
