import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/pending_character_write_queue.dart';
import 'package:personnages/core/cache/sync_alert_store.dart';
import 'package:personnages/core/cache/sync_state_store.dart';

void main() {
  late AppDatabase db;
  late SyncAlertStore alerts;
  late SyncStateStore state;
  late PendingCharacterWriteQueue queue;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    alerts = SyncAlertStore(db);
    state = SyncStateStore(db);
    queue = PendingCharacterWriteQueue(db);
  });

  tearDown(() => db.close());

  Future<void> add(String owner, String name) => alerts.add(
    ownerId: owner,
    kind: SyncAlertKind.abandon,
    characterId: 'c-$name',
    characterName: name,
    dataKind: 'hp',
    serverValue: {'currentHp': 7, 'maxHp': 12},
  );

  group('SyncAlertStore', () {
    test(
      'lecture par compte, la plus ancienne d\'abord (filtre ownerId)',
      () async {
        await add('owner-1', 'Aria');
        await add('owner-2', 'Autre');
        await add('owner-1', 'Borin');

        final owner1 = await alerts.allForOwner('owner-1');
        expect(owner1.map((a) => a.characterName), ['Aria', 'Borin']);
        expect(owner1.first.serverValue, {'currentHp': 7, 'maxHp': 12});
        expect(
          (await alerts.allForOwner('owner-2')).map((a) => a.characterName),
          ['Autre'],
        );
      },
    );

    test(
      'fermer une alerte la supprime, jamais celle d\'un autre compte',
      () async {
        await add('owner-1', 'Aria');
        final id = (await alerts.allForOwner('owner-1')).single.id;

        await alerts.dismiss(ownerId: 'owner-2', id: id);
        expect(await alerts.allForOwner('owner-1'), hasLength(1));

        await alerts.dismiss(ownerId: 'owner-1', id: id);
        expect(await alerts.allForOwner('owner-1'), isEmpty);
      },
    );

    test('watchForOwner émet à chaque ajout et fermeture', () async {
      final emissions = <List<String>>[];
      final sub = alerts
          .watchForOwner('owner-1')
          .listen(
            (list) => emissions.add([for (final a in list) a.characterName]),
          );
      await Future<void>.delayed(Duration.zero);
      await add('owner-1', 'Aria');
      await Future<void>.delayed(Duration.zero);
      await alerts.dismiss(
        ownerId: 'owner-1',
        id: (await alerts.allForOwner('owner-1')).single.id,
      );
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(emissions, [
        <String>[],
        ['Aria'],
        <String>[],
      ]);
    });

    test('persistance à travers un redémarrage (nouvelle instance de base sur '
        'le même fichier)', () async {
      final dir = Directory.systemTemp.createTempSync('nexus_alerts_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/db.sqlite');

      final first = AppDatabase(NativeDatabase(file));
      await SyncAlertStore(first).add(
        ownerId: 'owner-1',
        kind: SyncAlertKind.conflict,
        characterId: 'c1',
        characterName: 'Aria',
        dataKind: 'hp',
        serverValue: {'currentHp': 3, 'maxHp': 9},
      );
      await SyncStateStore(first).markSuccess('owner-1');
      await first.close();

      final second = AppDatabase(NativeDatabase(file));
      final restored = await SyncAlertStore(second).allForOwner('owner-1');
      expect(restored.single.kind, SyncAlertKind.conflict);
      expect(restored.single.serverValue, {'currentHp': 3, 'maxHp': 9});
      expect(await SyncStateStore(second).lastSuccess('owner-1'), isNotNull);
      await second.close();
    });

    test('la table est AUTOINCREMENT : l\'id d\'une alerte supprimée n\'est '
        'jamais réattribué à une nouvelle', () async {
      await add('owner-1', 'Aria');
      await add('owner-1', 'Borin');
      final last = (await alerts.allForOwner('owner-1')).last;
      await alerts.dismiss(ownerId: 'owner-1', id: last.id);

      await add('owner-1', 'Cyrus');
      final cyrus = (await alerts.allForOwner('owner-1')).last;
      expect(cyrus.id, greaterThan(last.id));

      // Le DDL généré le dit aussi explicitement.
      final rows = await db
          .customSelect(
            "SELECT sql FROM sqlite_master WHERE name = 'sync_alerts'",
          )
          .get();
      expect(rows.single.read<String>('sql'), contains('AUTOINCREMENT'));
    });

    test('restore : même id, même createdAt, mêmes champs (annulation d\'un '
        '« Écarter »)', () async {
      final created = DateTime(2026, 11, 10, 8, 30);
      await SyncAlertStore(db, now: () => created).add(
        ownerId: 'owner-1',
        kind: SyncAlertKind.conflict,
        characterId: 'c1',
        characterName: 'Aria',
        dataKind: 'hp',
        serverValue: {'currentHp': 3, 'maxHp': 9},
      );
      await add('owner-1', 'Borin');
      final aria = (await alerts.allForOwner('owner-1'))
          .firstWhere((a) => a.characterName == 'Aria');

      await alerts.dismiss(ownerId: 'owner-1', id: aria.id);
      // Une nouvelle alerte arrive entre-temps : elle ne reprend pas l'id.
      await add('owner-1', 'Cyrus');
      await alerts.restore(aria);

      final back = (await alerts.allForOwner('owner-1'))
          .firstWhere((a) => a.characterName == 'Aria');
      expect(back.id, aria.id);
      expect(back.createdAt, created);
      expect(back.kind, SyncAlertKind.conflict);
      expect(back.characterId, 'c1');
      expect(back.dataKind, 'hp');
      expect(back.serverValue, {'currentHp': 3, 'maxHp': 9});
      expect(back.ownerId, 'owner-1');
      expect(await alerts.allForOwner('owner-1'), hasLength(3));
    });

    test('restore : sans doublon si l\'id existe déjà, et une valeur serveur '
        'absente reste absente', () async {
      await alerts.add(
        ownerId: 'owner-1',
        kind: SyncAlertKind.abandon,
        characterId: 'c1',
        characterName: 'Aria',
        dataKind: 'class_feature',
      );
      final only = (await alerts.allForOwner('owner-1')).single;
      await alerts.restore(only);
      expect(await alerts.allForOwner('owner-1'), hasLength(1));

      await alerts.dismiss(ownerId: 'owner-1', id: only.id);
      await alerts.restore(only);
      expect((await alerts.allForOwner('owner-1')).single.serverValue, isNull);
    });

    test(
      'dismissAll : supprime toutes les alertes du compte et les rend, '
      'sans toucher aux autres comptes ni aux écritures en attente',
      () async {
        await add('owner-1', 'Aria');
        await add('owner-1', 'Borin');
        await add('owner-2', 'Autre');
        await queue.enqueue(
          characterId: 'c1',
          ownerId: 'owner-1',
          kind: PendingCharacterWriteKind.hp,
          targetId: '',
          payload: {'currentHp': 1, 'temporaryHp': 0},
        );

        final removed = await alerts.dismissAll(ownerId: 'owner-1');
        expect(removed.map((a) => a.characterName), ['Aria', 'Borin']);
        expect(await alerts.allForOwner('owner-1'), isEmpty);
        expect(await alerts.allForOwner('owner-2'), hasLength(1));
        expect(await queue.watchPendingCount('owner-1').first, 1);

        for (final alert in removed) {
          await alerts.restore(alert);
        }
        expect(
          (await alerts.allForOwner('owner-1')).map((a) => a.id),
          removed.map((a) => a.id),
        );
      },
    );
  });

  group('SyncStateStore', () {
    test(
      'horloge injectable, par compte, mise à jour à chaque succès',
      () async {
        var now = DateTime.utc(2026, 11, 10, 12);
        final store = SyncStateStore(db, now: () => now);
        expect(await store.lastSuccess('owner-1'), isNull);

        await store.markSuccess('owner-1');
        now = DateTime.utc(2026, 11, 10, 13);
        await store.markSuccess('owner-1');
        await store.markSuccess('owner-2');

        expect(
          (await store.lastSuccess('owner-1'))!.toUtc(),
          DateTime.utc(2026, 11, 10, 13),
        );
        expect(await store.lastSuccess('owner-3'), isNull);
      },
    );
  });

  group('purge à la déconnexion / suppression de compte', () {
    test('removeAllForOwner supprime file, alertes et dernière synchro du '
        'compte, sans toucher à un autre compte', () async {
      for (final owner in ['owner-1', 'owner-2']) {
        await add(owner, 'Aria');
        await state.markSuccess(owner);
        await queue.enqueue(
          characterId: 'c1',
          ownerId: owner,
          kind: PendingCharacterWriteKind.xp,
          targetId: '',
          payload: {'newXp': 10},
        );
      }

      await queue.removeAllForOwner('owner-1');

      expect(await alerts.allForOwner('owner-1'), isEmpty);
      expect(await state.lastSuccess('owner-1'), isNull);
      expect(await queue.allForOwner('owner-1'), isEmpty);
      expect(await alerts.allForOwner('owner-2'), hasLength(1));
      expect(await state.lastSuccess('owner-2'), isNotNull);
      expect(await queue.allForOwner('owner-2'), hasLength(1));
    });
  });

  group('watchPendingCount', () {
    test('total du compte vs un personnage, abandonnées exclues', () async {
      Future<void> enqueue(String owner, String character) => queue.enqueue(
        characterId: character,
        ownerId: owner,
        kind: PendingCharacterWriteKind.hp,
        targetId: '',
        payload: {'currentHp': 1, 'temporaryHp': 0},
      );
      await enqueue('owner-1', 'c1');
      await enqueue('owner-1', 'c2');
      await enqueue('owner-2', 'c1');

      expect(await queue.watchPendingCount('owner-1').first, 2);
      expect(
        await queue.watchPendingCount('owner-1', characterId: 'c1').first,
        1,
      );
      expect(await queue.watchPendingCount('owner-3').first, 0);

      final write = (await queue.forCharacter(
        ownerId: 'owner-1',
        characterId: 'c1',
      )).single;
      for (
        var i = 0;
        i < PendingCharacterWriteQueue.abandonAfterConsecutiveFailures;
        i++
      ) {
        await queue.recordNonRetryableFailure(write: write, reason: 'x');
      }
      expect(await queue.watchPendingCount('owner-1').first, 1);
    });
  });
}
