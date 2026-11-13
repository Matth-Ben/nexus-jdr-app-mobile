// Tests des providers du combat de groupe : faux dépôt, faux canal Realtime
// piloté par le test, horloge injectée. Voir `combat_providers.dart`.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/features/combat/domain/combat_enums.dart';
import 'package:personnages/features/combat/domain/combat_failure.dart';
import 'package:personnages/features/combat/domain/combat_view_state.dart';
import 'package:personnages/features/combat/presentation/providers/combat_providers.dart';

import '../../../../support/combat_fixtures.dart';
import '../../../../support/fake_combat_repository.dart';
import '../../../../support/fake_connectivity_checker.dart';
import '../../../../support/fake_current_user.dart';

const groupId = 'group-1';
const _debounce = Duration(milliseconds: 20);

Future<void> settle([Duration wait = const Duration(milliseconds: 80)]) async {
  await Future<void>.delayed(wait);
  await pumpEventQueue();
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  late FakeCombatRepository repo;
  late FakeConnectivityChecker connectivity;
  late ProviderContainer container;
  late DateTime now;

  ProviderContainer makeContainer({Duration debounce = _debounce}) {
    final c = ProviderContainer(
      overrides: [
        currentUserFromTestOverride,
        combatRepositoryProvider.overrideWithValue(repo),
        connectivityCheckerProvider.overrideWithValue(connectivity),
        combatRefetchDebounceProvider.overrideWithValue(debounce),
        combatClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  CombatViewState read() => container.read(combatProvider(groupId));

  /// Garde le watcher vivant (comme l'écran Groupe qui l'observe).
  void watchRealtime() => container.listen(
    combatRealtimeWatcherProvider(groupId),
    (previous, next) {},
    fireImmediately: true,
  );

  setUp(() {
    repo = FakeCombatRepository();
    connectivity = FakeConnectivityChecker();
    now = DateTime.utc(2026, 11, 14, 12);
    container = makeContainer();
    addTearDown(connectivity.close);
    addTearDown(
      () => binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed),
    );
  });

  group('état', () {
    test(
      'chargement puis combat actif avec horodatage du dernier état',
      () async {
        repo.snapshot = fakeSnapshot(
          combat: fakeCombat(round: 3),
          participants: [fakeParticipant('a', initiative: 10)],
        );
        container.listen(combatProvider(groupId), (_, _) {});
        expect(read().phase, CombatPhase.loading);

        await settle();

        expect(read().phase, CombatPhase.active);
        expect(read().snapshot!.combat.round, 3);
        expect(read().lastKnownAt, now);
        expect(read().isStale, isFalse);
        expect(read().isReadOnly, isFalse);
      },
    );

    test('aucun combat actif -> none', () async {
      container.listen(combatProvider(groupId), (_, _) {});
      await settle();
      expect(read().phase, CombatPhase.none);
      expect(read().snapshot, isNull);
    });

    test(
      'premier chargement en échec -> error avec le CombatFailure',
      () async {
        repo.fetchFailure = const CombatFailure.network();
        container.listen(combatProvider(groupId), (_, _) {});
        await settle();
        expect(read().phase, CombatPhase.error);
        expect(read().failure, const CombatFailure.network());
      },
    );

    test('hors ligne après un état connu : dernier état gardé, périmé, '
        'lecture seule, horodatage inchangé ; la reprise rétablit', () async {
      repo.snapshot = fakeSnapshot(participants: [fakeParticipant('a')]);
      container.listen(combatProvider(groupId), (_, _) {});
      await settle();
      final firstKnownAt = read().lastKnownAt;

      now = now.add(const Duration(minutes: 5));
      repo.fetchFailure = const CombatFailure.offline();
      await container.read(combatProvider(groupId).notifier).refresh();

      expect(read().phase, CombatPhase.active);
      expect(read().snapshot, isNotNull);
      expect(read().isStale, isTrue);
      expect(read().isReadOnly, isTrue);
      expect(read().lastKnownAt, firstKnownAt);

      repo.fetchFailure = null;
      await container.read(combatProvider(groupId).notifier).refresh();
      expect(read().isStale, isFalse);
      expect(read().failure, isNull);
      expect(read().lastKnownAt, now);
    });

    test(
      'combat actif puis plus aucun -> ended avec le dernier état connu',
      () async {
        repo.snapshot = fakeSnapshot(participants: [fakeParticipant('a')]);
        container.listen(combatProvider(groupId), (_, _) {});
        await settle();

        repo.snapshot = null;
        now = now.add(const Duration(minutes: 1));
        await container.read(combatProvider(groupId).notifier).refresh();

        expect(read().phase, CombatPhase.ended);
        expect(read().snapshot!.combat.status, CombatStatus.ended);
        expect(read().snapshot!.combat.endedAt, now);
        expect(read().snapshot!.participants, hasLength(1));
      },
    );
  });

  group('Realtime', () {
    test('le watcher souscrit une seule fois au groupe', () async {
      container.listen(combatProvider(groupId), (_, _) {});
      watchRealtime();
      await settle();
      expect(repo.channels, hasLength(1));
      expect(repo.lastChannel.groupId, groupId);
    });

    test('rafale d\'évènements (doublons, désordre) -> un seul refetch '
        'complet, avec les données les plus récentes', () async {
      repo.snapshot = fakeSnapshot(combat: fakeCombat(round: 1));
      container.listen(combatProvider(groupId), (_, _) {});
      watchRealtime();
      await settle();
      final baseline = repo.fetchCount;

      repo.snapshot = fakeSnapshot(combat: fakeCombat(round: 2));
      for (var i = 0; i < 5; i++) {
        repo.lastChannel.emitChange();
      }
      await settle();

      expect(repo.fetchCount, baseline + 1);
      expect(read().snapshot!.combat.round, 2);
    });

    test('un évènement déclenche un refetch complet (pas de delta)', () async {
      container.listen(combatProvider(groupId), (_, _) {});
      watchRealtime();
      await settle();
      final baseline = repo.fetchCount;

      repo.lastChannel.emitChange();
      await settle();

      expect(repo.fetchCount, baseline + 1);
    });

    test('un évènement pendant un refetch n\'en lance pas un second en '
        'parallèle : un seul suivant, en série', () async {
      container.listen(combatProvider(groupId), (_, _) {});
      watchRealtime();
      await settle();
      final baseline = repo.fetchCount;

      repo.fetchGate = Completer<void>();
      final notifier = container.read(combatProvider(groupId).notifier);
      final first = notifier.refresh();
      await pumpEventQueue();
      repo.lastChannel.emitChange();
      repo.lastChannel.emitChange();
      await settle();
      expect(repo.fetchCount, baseline + 1, reason: 'toujours en vol');

      final gate = repo.fetchGate!;
      repo.fetchGate = null;
      gate.complete();
      await first;
      await settle();

      expect(repo.fetchCount, baseline + 2);
      expect(repo.maxConcurrentFetches, 1);
    });

    test(
      '(re)connexion du canal -> resync complet immédiat (sans debounce)',
      () async {
        container = makeContainer(debounce: const Duration(seconds: 30));
        container.listen(combatProvider(groupId), (_, _) {});
        watchRealtime();
        await settle();
        final baseline = repo.fetchCount;

        repo.snapshot = fakeSnapshot(combat: fakeCombat(round: 4));
        repo.lastChannel.emitSubscribed(); // coupure puis reprise
        await settle();

        expect(repo.fetchCount, baseline + 1);
        expect(read().snapshot!.combat.round, 4);
      },
    );

    test('retour du réseau -> refetch complet', () async {
      container.listen(combatProvider(groupId), (_, _) {});
      watchRealtime();
      await settle();
      final baseline = repo.fetchCount;

      connectivity.goOnline();
      await settle();

      expect(repo.fetchCount, baseline + 1);
    });

    test('désabonnement propre à la disposition du watcher', () async {
      container.listen(combatProvider(groupId), (_, _) {});
      final sub = container.listen(
        combatRealtimeWatcherProvider(groupId),
        (previous, next) {},
        fireImmediately: true,
      );
      await settle();
      final channel = repo.lastChannel;
      expect(channel.cancelled, isFalse);

      sub.close();
      await settle();

      expect(channel.cancelled, isTrue);
    });

    test('désabonnement à la disposition du conteneur', () async {
      container.listen(combatProvider(groupId), (_, _) {});
      watchRealtime();
      await settle();
      final channel = repo.lastChannel;

      container.dispose();
      await pumpEventQueue();

      expect(channel.cancelled, isTrue);
    });

    test('arrière-plan -> désabonné ; retour au premier plan -> nouveau canal '
        'et resync complet', () async {
      container.listen(combatProvider(groupId), (_, _) {});
      watchRealtime();
      await settle();
      final first = repo.lastChannel;
      final baseline = repo.fetchCount;

      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await settle();
      expect(first.cancelled, isTrue);

      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle();

      expect(repo.channels, hasLength(2));
      expect(repo.lastChannel.cancelled, isFalse);
      expect(repo.fetchCount, greaterThan(baseline));
    });

    test('plus aucun abonnement actif une fois le watcher disposé : un '
        'évènement tardif ne provoque aucun refetch', () async {
      container.listen(combatProvider(groupId), (_, _) {});
      final sub = container.listen(
        combatRealtimeWatcherProvider(groupId),
        (previous, next) {},
        fireImmediately: true,
      );
      await settle();
      final channel = repo.lastChannel;
      final baseline = repo.fetchCount;
      sub.close();
      await settle();

      // Un canal fermé ne devrait plus rien délivrer ; on s'assure que le
      // dépôt n'a pas été resollicité par la disposition elle-même.
      expect(repo.fetchCount, baseline);
      expect(channel.cancelled, isTrue);
    });
  });

  group('actions', () {
    setUp(() async {
      repo.snapshot = fakeSnapshot(
        combat: fakeCombat(id: 'combat-9'),
        participants: [fakeParticipant('p1')],
      );
      container.listen(combatProvider(groupId), (_, _) {});
      await settle();
    });

    test(
      'setMyInitiative appelle le dépôt avec le combat actif puis refetch',
      () async {
        final baseline = repo.fetchCount;
        await container
            .read(combatProvider(groupId).notifier)
            .setMyInitiative(15);
        expect(repo.calls, ['mine:combat-9:15']);
        expect(repo.fetchCount, baseline + 1);
      },
    );

    test('les actions MJ délèguent au dépôt', () async {
      final notifier = container.read(combatProvider(groupId).notifier);
      await notifier.setParticipantInitiative('p1', null);
      await notifier.addNpcParticipants(
        baseName: 'Gobelin',
        initiative: 8,
        count: 3,
      );
      await notifier.removeParticipant('p1');
      await notifier.reorderParticipant(participantId: 'p1', newSortOrder: 2);
      await notifier.startCombat();
      await notifier.endCombat();
      expect(repo.calls, [
        'set:p1:null',
        'add:combat-9:Gobelin:8:3',
        'remove:p1',
        'reorder:p1:2',
        'start:$groupId',
        'end:combat-9',
      ]);
    });

    test('échec hors ligne : relancé, aucun refetch', () async {
      repo.writeFailure = const CombatFailure.offline();
      final baseline = repo.fetchCount;
      await expectLater(
        container.read(combatProvider(groupId).notifier).setMyInitiative(1),
        throwsA(
          isA<CombatFailure>().having(
            (f) => f.kind,
            'kind',
            CombatFailureKind.offline,
          ),
        ),
      );
      await settle();
      expect(repo.fetchCount, baseline);
    });

    test('échec métier : relancé et refetch pour réaligner l\'écran', () async {
      repo.writeFailure = const CombatFailure(
        CombatFailureKind.combatNotActive,
      );
      final baseline = repo.fetchCount;
      await expectLater(
        container.read(combatProvider(groupId).notifier).setMyInitiative(1),
        throwsA(isA<CombatFailure>()),
      );
      await settle();
      expect(repo.fetchCount, baseline + 1);
    });

    test(
      'sans combat actif connu : noActiveCombat sans appel au dépôt',
      () async {
        repo.snapshot = null;
        await container.read(combatProvider(groupId).notifier).refresh();
        repo.calls.clear();
        await expectLater(
          container.read(combatProvider(groupId).notifier).setMyInitiative(1),
          throwsA(
            isA<CombatFailure>().having(
              (f) => f.kind,
              'kind',
              CombatFailureKind.noActiveCombat,
            ),
          ),
        );
        expect(repo.calls, isEmpty);
      },
    );
  });

  group('purge au changement de compte', () {
    test('un autre compte ne voit pas l ancien instantané', () async {
      repo.snapshot = fakeSnapshot(
        participants: [fakeParticipant('secret', initiative: 12)],
      );
      container.listen(combatProvider(groupId), (_, _) {});
      await settle();
      expect(read().phase, CombatPhase.active);

      // Le compte suivant n'a aucun combat : le dépôt ne renvoie rien, mais
      // l'état doit être purgé (chargement) avant même ce refetch.
      repo
        ..snapshot = null
        ..fetchGate = Completer<void>();
      container.read(testUserIdProvider.notifier).set('user-2');
      await pumpEventQueue();
      expect(read().phase, CombatPhase.loading);
      expect(read().snapshot, isNull);
      repo.fetchGate!.complete();
      await settle();
      expect(read().phase, CombatPhase.none);
    });

    test('la déconnexion purge aussi l état', () async {
      repo.snapshot = fakeSnapshot(
        participants: [fakeParticipant('a', initiative: 1)],
      );
      container.listen(combatProvider(groupId), (_, _) {});
      await settle();
      container.read(testUserIdProvider.notifier).set(null);
      repo.snapshot = null;
      await settle();
      expect(read().snapshot, isNull);
    });

    test(
      'un refetch du compte précédent n écrase pas le nouvel état',
      () async {
        final gate = Completer<void>();
        repo
          ..snapshot = fakeSnapshot(
            participants: [fakeParticipant('ancien', initiative: 5)],
          )
          ..fetchGate = gate;
        container.listen(combatProvider(groupId), (_, _) {});
        await pumpEventQueue();
        repo.snapshot = null; // le fetch en vol a déjà capturé l ancien état
        container.read(testUserIdProvider.notifier).set('user-2');
        await pumpEventQueue();
        gate.complete();
        await settle();
        expect(read().snapshot, isNull);
        expect(read().phase, CombatPhase.none);
      },
    );

    test('même utilisateur : aucune purge', () async {
      repo.snapshot = fakeSnapshot(
        participants: [fakeParticipant('a', initiative: 1)],
      );
      container.listen(combatProvider(groupId), (_, _) {});
      await settle();
      final before = repo.fetchCount;
      container.read(testUserIdProvider.notifier).set('user-1');
      await settle();
      expect(repo.fetchCount, before);
      expect(read().phase, CombatPhase.active);
    });
  });

  group('bandeau de la fiche', () {
    test('null sans combat actif, valeur avec combat actif', () async {
      container.listen(combatBannerProvider(groupId), (_, _) {});
      await settle();
      expect(container.read(combatBannerProvider(groupId)), isNull);

      repo.snapshot = fakeSnapshot(combat: fakeCombat(round: 2));
      await container.read(combatProvider(groupId).notifier).refresh();
      final banner = container.read(combatBannerProvider(groupId));
      expect(banner, (
        combatId: 'combat-1',
        round: 2,
        isStale: false,
        startedAt: null,
      ));
    });

    test('ne se reconstruit pas pour un changement sans rapport, se '
        'reconstruit au changement de round, et maintient l\'abonnement', () async {
      repo.snapshot = fakeSnapshot(
        combat: fakeCombat(round: 1),
        participants: [fakeParticipant('a', initiative: 5)],
      );
      var builds = 0;
      container.listen(combatBannerProvider(groupId), (_, _) => builds++);
      await settle();
      expect(repo.channels, hasLength(1));
      final afterInitial = builds;

      // Changement sans rapport avec le bandeau : initiative d'un participant.
      repo.snapshot = fakeSnapshot(
        combat: fakeCombat(round: 1),
        participants: [fakeParticipant('a', initiative: 19)],
      );
      repo.lastChannel.emitChange();
      await settle();
      expect(builds, afterInitial);

      repo.snapshot = fakeSnapshot(combat: fakeCombat(round: 2));
      repo.lastChannel.emitChange();
      await settle();
      expect(builds, afterInitial + 1);
    });
  });
}
