// Suivi du combat Grimoire de **tous** les groupes du joueur tant que l'app
// est au premier plan (`docs/combat-grimoire-ui.md` §13, Q2) : un canal par
// groupe partagé avec les écrans, aucun canal ni présence en arrière-plan,
// groupes ajoutés et retirés, changement de compte, identité transmise,
// exclusion ; liste des groupes en mémoire (relecture, échec, appartenance).

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/features/combat/data/grimoire_combat_gateway.dart';
import 'package:personnages/features/combat/domain/combat_notification.dart';
import 'package:personnages/features/combat/domain/grimoire_combat_session.dart';
import 'package:personnages/features/combat/domain/grimoire_combat_view.dart';
import 'package:personnages/features/combat/domain/grimoire_failure.dart';
import 'package:personnages/features/combat/presentation/providers/combat_callout_providers.dart';
import 'package:personnages/features/combat/presentation/providers/combat_providers.dart';
import 'package:personnages/features/combat/presentation/providers/grimoire_combat_providers.dart';
import 'package:personnages/features/combat/presentation/providers/grimoire_groups_providers.dart';

import '../../../../support/fake_connectivity_checker.dart';
import '../../../../support/fake_current_user.dart';
import '../../../../support/fake_grimoire_combat_gateway.dart';
import '../../../../support/fake_group_membership_repository.dart';
import '../../../../support/grimoire_fixtures.dart';

void main() {
  late FakeGrimoireCombatGateway gateway;
  late FakeConnectivityChecker connectivity;
  late FakeGroupMembershipRepository memberships;
  late ProviderContainer container;
  late DateTime now;

  setUp(() {
    gateway = FakeGrimoireCombatGateway();
    connectivity = FakeConnectivityChecker();
    memberships = FakeGroupMembershipRepository([
      membership('g1', name: 'Les Braves'),
      membership('g2', name: 'La Compagnie', characterId: 'c-other'),
    ]);
    now = DateTime(2026, 11, 23, 21);
    container = ProviderContainer(
      overrides: [
        currentUserFromTestOverride,
        grimoireCombatGatewayProvider.overrideWithValue(gateway),
        connectivityCheckerProvider.overrideWithValue(connectivity),
        combatClockProvider.overrideWithValue(() => now),
        groupMembershipRepositoryProvider.overrideWithValue(memberships),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(connectivity.close);
  });

  /// Test à minuteries simulées ; le conteneur est libéré à la fin du corps.
  void followerTest(
    String description,
    Future<void> Function(WidgetTester tester) body,
  ) {
    testWidgets(description, (tester) async {
      final binding = tester.binding;
      addTearDown(
        () => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed),
      );
      try {
        await body(tester);
      } finally {
        // Toujours libéré, même sur un échec : sinon la fermeture des faux
        // flux de connectivité attendrait des abonnés encore actifs.
        container.dispose();
      }
    });
  }

  /// Laisse se dérouler lecture des groupes, reconstructions (Riverpod les
  /// planifie par une minuterie nulle), lecture des sujets, ouverture et
  /// `SUBSCRIBED`.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(Duration.zero);
    }
  }

  Future<void> follow(WidgetTester tester) async {
    container.listen(
      grimoireGroupsFollowerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    await settle(tester);
  }

  /// Canaux encore ouverts côté client.
  Iterable<FakeGrimoireGmLink> open() =>
      gateway.links.where((link) => !link.closeRequested);

  Set<String> openGroups() => {
    for (final link in open()) link.topic.split(':')[3],
  };

  group('abonnement à tous les groupes', () {
    followerTest('premier plan : un canal par groupe, présence et '
        'state_request ; le canal est partagé avec un écran', (tester) async {
      await follow(tester);
      expect(openGroups(), {'g1', 'g2'});
      expect(gateway.links, hasLength(2));
      for (final link in gateway.links) {
        expect(link.tracks, 1);
        expect(link.presenceKey, 'user-1');
      }
      expect(gateway.stateRequests.map((m) => m.groupId).toSet(), {'g1', 'g2'});
      expect(
        container.read(grimoireCombatProvider('g1')).link,
        GrimoireLinkStatus.subscribed,
      );

      // L'écran Groupe de g1 s'ouvre : même canal, aucun autre.
      final screen = container.listen(
        grimoireCombatWatcherProvider('g1'),
        (_, _) {},
        fireImmediately: true,
      );
      await settle(tester);
      expect(gateway.links, hasLength(2));
      screen.close();
      await settle(tester);
      // L'écran fermé : le suivi global garde le canal.
      expect(openGroups(), {'g1', 'g2'});
    });

    followerTest('arrière-plan : aucun canal, aucune présence ; retour : '
        'réabonnement et state_request pour chaque groupe', (tester) async {
      await follow(tester);
      final first = gateway.links.toList();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await settle(tester);
      expect(open(), isEmpty);
      for (final link in first) {
        expect(link.presenceActive, isFalse);
        expect(link.closed, isTrue);
      }
      expect(
        container.read(grimoireCombatProvider('g1')).link,
        GrimoireLinkStatus.idle,
      );
      final requestsBefore = gateway.stateRequests.length;
      final readsBefore = memberships.reads;

      // Au-delà de l'écart minimal entre deux `state_request`.
      now = now.add(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 3));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);
      expect(openGroups(), {'g1', 'g2'});
      expect(gateway.links, hasLength(4));
      expect(gateway.stateRequests.length, requestsBefore + 2);
      for (final link in open()) {
        expect(link.tracks, 1);
      }
      // La liste des groupes est relue au retour.
      expect(memberships.reads, readsBefore + 1);
    });

    followerTest('groupe ajouté puis retiré : canal ouvert puis fermé', (
      tester,
    ) async {
      memberships.memberships = [membership('g1')];
      await follow(tester);
      expect(openGroups(), {'g1'});

      memberships.memberships = [membership('g1'), membership('g2')];
      await container.read(myGroupMembershipsProvider.notifier).refresh();
      await settle(tester);
      expect(openGroups(), {'g1', 'g2'});

      memberships.memberships = [membership('g2')];
      await container.read(myGroupMembershipsProvider.notifier).refresh();
      await settle(tester);
      expect(openGroups(), {'g2'});
      expect(gateway.linkFor('g1').closed, isTrue);
    });

    followerTest('changement de compte : canaux du compte précédent fermés, '
        'groupes du nouveau compte suivis, signal effacé', (tester) async {
      await follow(tester);
      container.read(combatCalloutControllerProvider.notifier).showFromPush((
        type: CombatNotificationType.combatStart,
        groupId: 'g1',
      ));
      expect(container.read(combatCalloutControllerProvider), isNotNull);

      memberships.memberships = [membership('g3')];
      container.read(testUserIdProvider.notifier).set('user-2');
      await settle(tester);
      expect(openGroups(), {'g3'});
      expect(gateway.linkFor('g3').presenceKey, 'user-2');
      expect(container.read(combatCalloutControllerProvider), isNull);

      // Déconnexion : plus aucun canal.
      container.read(testUserIdProvider.notifier).set(null);
      await settle(tester);
      expect(open(), isEmpty);
    });

    followerTest('identité transmise : la demande d\'initiative est reconnue '
        'sans écran, et le signal « Combat ! » apparaît', (tester) async {
      await follow(tester);
      gateway.linkFor('g1')
        ..emit(gCombatStart(1))
        ..emit(gInitiativeRequest(2, ['c-player']));
      await settle(tester);
      final view = container.read(grimoireCombatProvider('g1')).view;
      expect(view.initiative.status, GrimoireInitiativeStatus.requested);
      final callout = container.read(combatCalloutControllerProvider)!;
      expect(callout.groupId, 'g1');
      expect(callout.kind, CombatCalloutKind.combatStart);

      // g2 : autre personnage, la même demande ne le concerne pas.
      gateway.linkFor('g2')
        ..emit(gCombatStart(1))
        ..emit(gInitiativeRequest(2, ['c-player']));
      await settle(tester);
      expect(
        container.read(grimoireCombatProvider('g2')).view.initiative.status,
        GrimoireInitiativeStatus.idle,
      );
    });

    followerTest('exclusion (group_not_found) : groupe retiré de la liste, '
        'canal fermé, plus aucun essai', (tester) async {
      await follow(tester);
      gateway.topicsFailure = const GrimoireFailure(
        GrimoireFailureKind.groupNotFound,
      );
      gateway.linkFor('g1').signal(GrimoireChannelSignal.error);
      now = now.add(kGrimoireRetryDelays.first);
      await tester.pump(kGrimoireRetryDelays.first);
      await settle(tester);
      expect(
        container.read(myGroupMembershipsProvider)!.map((m) => m.groupId),
        ['g2'],
      );
      expect(gateway.linkFor('g1').closed, isTrue);
      expect(openGroups(), {'g2'});
    });
  });

  group('liste des groupes (mémoire)', () {
    followerTest('échec de relecture : la dernière liste est gardée', (
      tester,
    ) async {
      await follow(tester);
      memberships.error = Exception('hors ligne');
      final ok = await container
          .read(myGroupMembershipsProvider.notifier)
          .refresh();
      expect(ok, isFalse);
      expect(container.read(myGroupMembershipsProvider), hasLength(2));
    });

    followerTest('appartenance : vraie, fausse, inconnue hors ligne', (
      tester,
    ) async {
      await follow(tester);
      final notifier = container.read(myGroupMembershipsProvider.notifier);
      expect(await notifier.isMember('g1'), isTrue);
      expect(await notifier.isMember('g9'), isFalse);
      memberships.error = Exception('hors ligne');
      expect(await notifier.isMember('g9'), isNull);
    });

    followerTest('groupe vu par un écran et absent de la liste : relu (au '
        'plus toutes les 30 s par groupe)', (tester) async {
      await follow(tester);
      final notifier = container.read(myGroupMembershipsProvider.notifier);
      final reads = memberships.reads;
      notifier.noteGroupSeen('g1', characterId: 'c-player');
      expect(memberships.reads, reads);
      memberships.memberships = [...memberships.memberships, membership('g4')];
      notifier.noteGroupSeen('g4', characterId: 'c-player');
      await settle(tester);
      expect(memberships.reads, reads + 1);
      expect(openGroups(), containsAll(['g1', 'g2', 'g4']));
      // Autre personnage dans g1 : relu, une seule fois par 30 s.
      notifier
        ..noteGroupSeen('g1', characterId: 'c-new')
        ..noteGroupSeen('g1', characterId: 'c-new');
      await settle(tester);
      expect(memberships.reads, reads + 2);
    });
  });
}
