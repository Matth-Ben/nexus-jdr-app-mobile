// Groupe d'un personnage (cache mémoire, hors ligne, plusieurs groupes) et
// bandeau de combat de sa fiche. Voir `character_combat_provider.dart`.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/features/combat/presentation/providers/character_combat_provider.dart';
import 'package:personnages/features/combat/presentation/providers/combat_providers.dart';
import 'package:personnages/features/groups/presentation/providers/group_providers.dart';

import '../../../../support/combat_fixtures.dart';
import '../../../../support/fake_combat_repository.dart';
import '../../../../support/fake_connectivity_checker.dart';
import '../../../../support/fake_current_user.dart';
import '../../../../support/fake_group_character_lookup.dart';

const _character = 'c-1';

Future<void> _settle([Duration wait = const Duration(milliseconds: 80)]) async {
  await Future<void>.delayed(wait);
  await pumpEventQueue();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeCombatRepository combats;
  late FakeGroupCharacterLookup groups;
  late FakeConnectivityChecker connectivity;
  late ProviderContainer container;
  late DateTime now;

  setUp(() {
    combats = FakeCombatRepository();
    groups = FakeGroupCharacterLookup()..groupsByCharacter[_character] = ['g1'];
    connectivity = FakeConnectivityChecker();
    now = DateTime.utc(2026, 11, 14, 12);
    container = ProviderContainer(
      overrides: [
        currentUserFromTestOverride,
        combatRepositoryProvider.overrideWithValue(combats),
        groupRepositoryProvider.overrideWithValue(groups),
        connectivityCheckerProvider.overrideWithValue(connectivity),
        combatRefetchDebounceProvider.overrideWithValue(
          const Duration(milliseconds: 20),
        ),
        combatClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(connectivity.close);
    addTearDown(container.dispose);
  });

  List<String>? ids() => container.read(characterGroupIdsProvider(_character));

  group('characterGroupIdsProvider (cache mémoire)', () {
    test(
      'une seule requête au premier accès, aucune par lecture suivante',
      () async {
        container.listen(
          characterGroupIdsProvider(_character),
          (_, _) {},
          fireImmediately: true,
        );
        await _settle();
        expect(ids(), ['g1']);
        expect(groups.calls, 1);
        for (var i = 0; i < 10; i++) {
          ids();
        }
        await _settle();
        expect(groups.calls, 1);
        expect(groups.requested, [_character]);
      },
    );

    test('ensureFresh : rien avant 5 min, relecture après', () async {
      container.listen(characterGroupIdsProvider(_character), (_, _) {});
      await _settle();
      final notifier = container.read(
        characterGroupIdsProvider(_character).notifier,
      );
      now = now.add(const Duration(minutes: 4));
      await notifier.ensureFresh();
      expect(groups.calls, 1);
      groups.groupsByCharacter[_character] = ['g1', 'g2'];
      now = now.add(const Duration(minutes: 2));
      await notifier.ensureFresh();
      expect(groups.calls, 2);
      expect(ids(), ['g1', 'g2']);
    });

    test('hors ligne : le dernier groupe connu est conservé', () async {
      container.listen(characterGroupIdsProvider(_character), (_, _) {});
      await _settle();
      groups.failure = StateError('hors ligne');
      await container
          .read(characterGroupIdsProvider(_character).notifier)
          .refresh();
      expect(ids(), ['g1']);
    });

    test('premier accès hors ligne : aucun groupe connu (null)', () async {
      groups.failure = StateError('hors ligne');
      container.listen(characterGroupIdsProvider(_character), (_, _) {});
      await _settle();
      expect(ids(), isNull);
    });

    test('retour du réseau : relecture', () async {
      container.listen(characterGroupIdsProvider(_character), (_, _) {});
      container.listen(connectivityStatusProvider, (_, _) {});
      await _settle();
      connectivity.goOffline();
      await _settle();
      final before = groups.calls;
      groups.groupsByCharacter[_character] = ['g9'];
      connectivity.goOnline();
      await _settle();
      expect(groups.calls, greaterThan(before));
      expect(ids(), ['g9']);
    });

    test('changement d\'utilisateur : cache purgé puis relu', () async {
      container.listen(characterGroupIdsProvider(_character), (_, _) {});
      await _settle();
      groups.groupsByCharacter[_character] = ['autre'];
      container.read(testUserIdProvider.notifier).set('user-2');
      await _settle();
      expect(ids(), ['autre']);
      expect(groups.calls, 2);
    });

    test(
      'personnage dans aucun groupe : liste vide, jamais de bandeau',
      () async {
        groups.groupsByCharacter[_character] = [];
        container.listen(characterCombatBannerProvider(_character), (_, _) {});
        await _settle();
        expect(ids(), isEmpty);
        expect(
          container.read(characterCombatBannerProvider(_character)),
          isNull,
        );
      },
    );
  });

  group('characterCombatBannerProvider', () {
    void listen() => container.listen(
      characterCombatBannerProvider(_character),
      (_, _) {},
      fireImmediately: true,
    );

    CharacterCombatBanner? banner() =>
        container.read(characterCombatBannerProvider(_character));

    test('aucun combat actif : pas de bandeau', () async {
      combats.snapshotsByGroup['g1'] = null;
      listen();
      await _settle();
      expect(banner(), isNull);
    });

    test('combat actif du groupe du personnage', () async {
      combats.snapshotsByGroup['g1'] = fakeSnapshot(
        combat: fakeCombat(groupId: 'g1', round: 4),
      );
      listen();
      await _settle();
      expect(banner(), (groupId: 'g1', round: 4, isStale: false));
    });

    test('plusieurs groupes : celui qui a un combat actif', () async {
      groups.groupsByCharacter[_character] = ['g1', 'g2'];
      combats.snapshotsByGroup['g1'] = null;
      combats.snapshotsByGroup['g2'] = fakeSnapshot(
        combat: fakeCombat(groupId: 'g2', round: 2),
      );
      listen();
      await _settle();
      expect(banner()?.groupId, 'g2');
    });

    test('plusieurs combats actifs : le plus récent', () async {
      groups.groupsByCharacter[_character] = ['g1', 'g2', 'g3'];
      combats.snapshotsByGroup['g1'] = fakeSnapshot(
        combat: fakeCombat(
          id: 'c1',
          groupId: 'g1',
        ).copyWith(createdAt: DateTime.utc(2026, 11, 14, 10)),
      );
      combats.snapshotsByGroup['g2'] = fakeSnapshot(
        combat: fakeCombat(
          id: 'c2',
          groupId: 'g2',
        ).copyWith(createdAt: DateTime.utc(2026, 11, 14, 11)),
      );
      combats.snapshotsByGroup['g3'] = fakeSnapshot(
        combat: fakeCombat(
          id: 'c3',
          groupId: 'g3',
        ).copyWith(createdAt: DateTime.utc(2026, 11, 14, 9)),
      );
      listen();
      await _settle();
      expect(banner()?.groupId, 'g2');
    });

    test('un combat sans date compte comme le plus ancien', () async {
      groups.groupsByCharacter[_character] = ['g1', 'g2'];
      combats.snapshotsByGroup['g1'] = fakeSnapshot(
        combat: fakeCombat(id: 'c1', groupId: 'g1'),
      );
      combats.snapshotsByGroup['g2'] = fakeSnapshot(
        combat: fakeCombat(
          id: 'c2',
          groupId: 'g2',
        ).copyWith(createdAt: DateTime.utc(2026, 11, 14, 11)),
      );
      listen();
      await _settle();
      expect(banner()?.groupId, 'g2');
    });

    test('un abonnement Realtime par groupe, libérés à la fermeture', () async {
      groups.groupsByCharacter[_character] = ['g1', 'g2'];
      combats.snapshotsByGroup['g1'] = null;
      combats.snapshotsByGroup['g2'] = null;
      final sub = container.listen(
        characterCombatBannerProvider(_character),
        (_, _) {},
      );
      await _settle();
      expect(combats.channels.map((c) => c.groupId).toSet(), {'g1', 'g2'});
      sub.close();
      await _settle();
      expect(combats.channels.every((c) => c.cancelled), isTrue);
    });

    test('évènement sans rapport : aucun rebuild du bandeau ; changement de '
        'round : un rebuild', () async {
      combats.snapshotsByGroup['g1'] = fakeSnapshot(
        combat: fakeCombat(groupId: 'g1'),
        participants: [fakeParticipant('a', initiative: 5)],
      );
      var builds = 0;
      container.listen(characterCombatBannerProvider(_character), (_, _) {
        builds++;
      });
      await _settle();
      final initial = builds;
      combats.snapshotsByGroup['g1'] = fakeSnapshot(
        combat: fakeCombat(groupId: 'g1'),
        participants: [fakeParticipant('a', initiative: 19)],
      );
      combats.lastChannel.emitChange();
      await _settle();
      expect(builds, initial);
      combats.snapshotsByGroup['g1'] = fakeSnapshot(
        combat: fakeCombat(groupId: 'g1', round: 2),
      );
      combats.lastChannel.emitChange();
      await _settle();
      expect(builds, initial + 1);
    });

    test(
      'hors ligne après un combat connu : le bandeau reste (périmé)',
      () async {
        combats.snapshotsByGroup['g1'] = fakeSnapshot(
          combat: fakeCombat(groupId: 'g1'),
        );
        listen();
        await _settle();
        combats.fetchFailure = null;
        groups.failure = StateError('hors ligne');
        await container
            .read(characterGroupIdsProvider(_character).notifier)
            .refresh();
        expect(banner()?.groupId, 'g1');
      },
    );
  });
}
