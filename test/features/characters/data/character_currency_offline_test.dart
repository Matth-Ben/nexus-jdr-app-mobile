// T3 (P15) : monnaies en file hors ligne. Dépôt réel + file drift en mémoire +
// synchroniseur réel + faux serveur PostgREST du harnais (`test/support/`).

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/cache/app_database.dart'
    hide PendingCharacterWrite;
import 'package:personnages/core/cache/pending_character_write_queue.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/core/cache/sync_alert_store.dart';
import 'package:personnages/features/characters/data/character_detail_cache.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/data/pending_character_write_syncer.dart';
import 'package:personnages/features/characters/data/sync_alert_recorder.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/characters/domain/reward_item_draft.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../support/fake_character_write_server.dart';
import '../../../support/fake_connectivity_checker.dart';

const _characterId = 'char-1';
const _ownerA = 'owner-1';
const _ownerB = 'owner-2';

void main() {
  var clock = DateTime.utc(2026, 11, 10, 12);
  late AppDatabase db;
  late PendingCharacterWriteQueue queue;
  late ReferenceDataCache cache;
  late FakeConnectivityChecker connectivity;
  late FakeCharacterWriteServer server;
  late SupabaseClient client;
  late SupabaseCharacterRepository repository;
  late PendingCharacterWriteSyncer syncer;

  Future<void> seedCache({int gold = 10, int silver = 4}) => cache.put(
    CharacterDetailCache.keyFor(ownerId: _ownerA, characterId: _characterId),
    {
      CharacterDetailCache.rowKey: {
        'name': 'Aria',
        'currency_gp': gold,
        'currency_pp': 0,
        'currency_ep': 0,
        'currency_sp': silver,
        'currency_cp': 0,
      },
    },
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    queue = PendingCharacterWriteQueue(db, now: () => clock);
    cache = ReferenceDataCache(db);
    connectivity = FakeConnectivityChecker();
    server = FakeCharacterWriteServer(
      characterRow: {
        'id': _characterId,
        'owner_id': _ownerA,
        'name': 'Aria',
        'currency_gp': 10,
        'currency_pp': 0,
        'currency_ep': 0,
        'currency_sp': 4,
        'currency_cp': 0,
      },
    );
    client = await buildSignedInClient(server, ownerId: _ownerA);
    repository = SupabaseCharacterRepository(
      client,
      cache,
      queue,
      connectivity,
    );
    syncer = PendingCharacterWriteSyncer(client, queue, cache, repository);
    await seedCache();
  });

  tearDown(() async {
    await connectivity.close();
    await db.close();
  });

  Future<PendingCharacterWrite> currencyLine() async {
    final rows = await queue.allForOwner(_ownerA);
    return rows.singleWhere(
      (r) => r.kind == PendingCharacterWriteKind.currency,
    );
  }

  Future<WriteOutcome> adjustOffline(CurrencyKind kind, int amount) {
    connectivity.goOffline();
    return repository.adjustCurrency(
      characterId: _characterId,
      currency: kind,
      newAmount: amount,
    );
  }

  group('dépôt : mise en file', () {
    test('hors ligne : queued, une ligne avec totaux et base serveur, '
        'targetId vide', () async {
      expect(await adjustOffline(CurrencyKind.gold, 15), WriteOutcome.queued);

      final line = await currencyLine();
      expect(line.targetId, '');
      expect(line.payload['totals'], {'currency_gp': 15});
      expect(line.payload['bases'], {'currency_gp': 10});
      expect(server.requests, isEmpty, reason: 'aucun réseau tenté');
    });

    test('erreur de transport en ligne : queued', () async {
      server.failBefore(1);

      final outcome = await repository.adjustCurrency(
        characterId: _characterId,
        currency: CurrencyKind.gold,
        newAmount: 15,
      );

      expect(outcome, WriteOutcome.queued);
      expect((await currencyLine()).payload['totals'], {'currency_gp': 15});
    });

    test('refus 42501 : échec, rien en file', () async {
      server.rejectWith('42501');

      await expectLater(
        repository.adjustCurrency(
          characterId: _characterId,
          currency: CurrencyKind.gold,
          newAmount: 15,
        ),
        throwsA(isA<CharacterFailure>()),
      );
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });

    test('zéro ligne affectée (RLS silencieuse) : accessDenied, rien en '
        'file', () async {
      server.concurrentChange({'owner_id': 'autre'});

      await expectLater(
        repository.adjustCurrency(
          characterId: _characterId,
          currency: CurrencyKind.gold,
          newAmount: 15,
        ),
        throwsA(
          isA<CharacterFailure>().having(
            (f) => f.code,
            'code',
            CharacterErrorCode.accessDenied,
          ),
        ),
      );
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });

    test('deux ajustements hors ligne : une seule ligne, totaux chaînés, '
        'base du premier enfilage conservée', () async {
      await adjustOffline(CurrencyKind.gold, 15);
      // Le cache change entre-temps : la base mémorisée ne doit pas bouger.
      await seedCache(gold: 99);
      clock = clock.add(const Duration(seconds: 5));
      await repository.adjustCurrency(
        characterId: _characterId,
        currency: CurrencyKind.gold,
        newAmount: 20,
      );
      await repository.adjustCurrency(
        characterId: _characterId,
        currency: CurrencyKind.silver,
        newAmount: 1,
      );

      final line = await currencyLine();
      expect(await queue.allForOwner(_ownerA), hasLength(1));
      expect(line.payload['totals'], {'currency_gp': 20, 'currency_sp': 1});
      expect(line.payload['bases'], {'currency_gp': 10, 'currency_sp': 4});
    });

    test('conversion hors ligne (addReward sans objet) : queued, deux '
        'monnaies dans une seule ligne', () async {
      connectivity.goOffline();

      final outcome = await repository.addReward(
        characterId: _characterId,
        newCurrencyTotals: const {
          CurrencyKind.gold: 9,
          CurrencyKind.copper: 60,
        },
        items: const [],
      );

      expect(outcome, WriteOutcome.queued);
      expect((await currencyLine()).payload['totals'], {
        'currency_gp': 9,
        'currency_cp': 60,
      });
    });

    test('butin avec objets hors ligne : rejectedOffline, rien en file '
        '(tranche T5)', () async {
      connectivity.goOffline();

      final outcome = await repository.addReward(
        characterId: _characterId,
        newCurrencyTotals: const {CurrencyKind.gold: 50},
        items: const [
          RewardItemDraft(itemId: 5, displayName: 'Dague', quantity: 1),
        ],
      );

      expect(outcome, WriteOutcome.rejectedOffline);
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });

    test('en ligne : écriture immédiate filtrée id + owner_id, cache mis à '
        'jour, rien en file', () async {
      final outcome = await repository.adjustCurrency(
        characterId: _characterId,
        currency: CurrencyKind.gold,
        newAmount: 15,
      );

      expect(outcome, WriteOutcome.synced);
      final patch = server.appliedWrites.single;
      expect(patch.body, {'currency_gp': 15});
      expect(patch.query['id'], 'eq.$_characterId');
      expect(patch.query['owner_id'], 'eq.$_ownerA');
      expect(await queue.allForOwner(_ownerA), isEmpty);
      final row = await CharacterDetailCache(cache)
          .readRow(ownerId: _ownerA, characterId: _characterId);
      expect(row?['currency_gp'], 15);
      expect(row?['currency_sp'], 4);
    });

    test('en ligne avec une entrée périmée en file : fusionnée dans '
        'l\'écriture (aucune monnaie perdue), puis retirée', () async {
      await adjustOffline(CurrencyKind.gold, 15);
      connectivity.goOnline();

      final outcome = await repository.adjustCurrency(
        characterId: _characterId,
        currency: CurrencyKind.silver,
        newAmount: 7,
      );

      expect(outcome, WriteOutcome.synced);
      expect(server.appliedWrites.single.body, {
        'currency_gp': 15,
        'currency_sp': 7,
      });
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });

    test('en ligne : une entrée remise en file pendant l\'écriture n\'est '
        'pas retirée', () async {
      await adjustOffline(CurrencyKind.gold, 15);
      connectivity.goOnline();
      server.onWriteApplied = (_) async {
        clock = clock.add(const Duration(seconds: 5));
        await queue.enqueue(
          characterId: _characterId,
          ownerId: _ownerA,
          kind: PendingCharacterWriteKind.currency,
          targetId: '',
          payload: {
            'totals': {'currency_gp': 77},
            'bases': {'currency_gp': 10},
          },
        );
      };

      await repository.adjustCurrency(
        characterId: _characterId,
        currency: CurrencyKind.gold,
        newAmount: 20,
      );

      expect((await currencyLine()).payload['totals'], {'currency_gp': 77});
    });
  });

  group('rejeu', () {
    test('totaux absolus écrits, filtrés id ET owner_id, ligne retirée, '
        'cache mis à jour', () async {
      await adjustOffline(CurrencyKind.gold, 15);
      connectivity.goOnline();

      expect(await syncer.sync(), {_characterId});

      expect(server.characterRow['currency_gp'], 15);
      final patch = server.appliedWrites.single;
      expect(patch.body, {'currency_gp': 15});
      expect(patch.query['id'], 'eq.$_characterId');
      expect(patch.query['owner_id'], 'eq.$_ownerA');
      expect(await queue.allForOwner(_ownerA), isEmpty);
      final row = await CharacterDetailCache(cache)
          .readRow(ownerId: _ownerA, characterId: _characterId);
      expect(row?['currency_gp'], 15);
    });

    test('idempotent : réponse perdue, le rejeu réécrit les mêmes totaux '
        'absolus', () async {
      await adjustOffline(CurrencyKind.gold, 15);
      connectivity.goOnline();
      server.failAfterApply(1);

      expect(await syncer.sync(), isEmpty);
      expect(await queue.allForOwner(_ownerA), hasLength(1));
      expect(await syncer.sync(), {_characterId});

      expect(server.appliedWrites.map((w) => w.body).toList(), [
        {'currency_gp': 15},
        {'currency_gp': 15},
      ]);
      expect(server.characterRow['currency_gp'], 15);
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });

    test('conflit : serveur modifié entre-temps, l\'écriture part quand '
        'même et un ServerValueConflict est signalé', () async {
      await adjustOffline(CurrencyKind.gold, 15);
      server.concurrentChange({'currency_gp': 50});
      connectivity.goOnline();

      final report = await syncer.syncWithReport();

      expect(report.synced, {_characterId});
      expect(server.characterRow['currency_gp'], 15);
      final conflict = report.conflicts.single;
      expect(conflict.characterId, _characterId);
      expect(conflict.kind, PendingCharacterWriteKind.currency);
      expect(conflict.serverValue, {'currency_gp': 50});
      expect(conflict.queuedValue, {'currency_gp': 15});
    });

    test('serveur inchangé : aucun conflit', () async {
      await adjustOffline(CurrencyKind.gold, 15);
      connectivity.goOnline();

      final report = await syncer.syncWithReport();

      expect(report.conflicts, isEmpty);
    });

    test('pas de faux conflit après une réponse perdue (serveur déjà égal '
        'à la valeur en file)', () async {
      await adjustOffline(CurrencyKind.gold, 15);
      connectivity.goOnline();
      server.failAfterApply(1);
      await syncer.syncWithReport();

      final report = await syncer.syncWithReport();

      expect(report.synced, {_characterId});
      expect(report.conflicts, isEmpty);
    });

    test(
      'conflit enregistré en alerte persistée (dataKind currency)',
      () async {
        await adjustOffline(CurrencyKind.gold, 15);
        server.concurrentChange({'currency_gp': 50});
        connectivity.goOnline();
        final report = await syncer.syncWithReport();
        final recorder = SyncAlertRecorder(
          db,
          queue,
          SyncAlertStore(db),
          CharacterDetailCache(cache),
        );

        await recorder.recordConflict(
          ownerId: _ownerA,
          conflict: report.conflicts.single,
        );

        final alert = (await SyncAlertStore(db).allForOwner(_ownerA)).single;
        expect(alert.kind, SyncAlertKind.conflict);
        expect(alert.dataKind, 'currency');
        expect(alert.serverValue, {'currency_gp': 50});
      },
    );

    for (final bad in <Map<String, dynamic>>[
      {},
      {'totals': 'x'},
      {'totals': null},
      {'totals': <String, dynamic>{}},
      {
        'totals': {'currency_gp': -1},
      },
      {
        'totals': {'currency_gp': 1.5},
      },
      {
        'totals': {'currency_gp': '12'},
      },
      {
        'totals': {'currency_gp': null},
      },
      {
        'totals': {'currency_zz': 3},
      },
      {
        'totals': {'currency_gp': 3, 'currency_sp': -2},
      },
      {
        'totals': [1, 2],
      },
    ]) {
      test('payload invalide $bad : aucune écriture, ligne supprimée, '
          'les autres lignes sont rejouées', () async {
        await queue.enqueue(
          characterId: _characterId,
          ownerId: _ownerA,
          kind: PendingCharacterWriteKind.currency,
          targetId: '',
          payload: bad,
        );
        clock = clock.add(const Duration(seconds: 5));
        await queue.enqueue(
          characterId: _characterId,
          ownerId: _ownerA,
          kind: PendingCharacterWriteKind.xp,
          targetId: '',
          payload: {'newXp': 250},
        );

        expect(await queue.watchPendingCount(_ownerA).first, 2);
        final synced = await syncer.sync();

        expect(synced, {_characterId});
        expect(await queue.allForOwner(_ownerA), isEmpty);
        expect(await queue.watchPendingCount(_ownerA).first, 0);
        expect(server.characterRow['xp'], 250);
        expect(server.characterRow['currency_gp'], 10);
        expect(
          server.writes.where(
            (w) => (w.body as Map).keys.any(
              (k) => (k as String).startsWith('currency'),
            ),
          ),
          isEmpty,
        );
      });
    }

    test('zéro ligne affectée : refus non rejouable, abandon au seuil puis '
        'alerte persistée (dataKind currency)', () async {
      await adjustOffline(CurrencyKind.gold, 15);
      connectivity.goOnline();
      server.concurrentChange({'owner_id': 'autre'});

      final abandoned = <String>{};
      for (
        var i = 0;
        i < PendingCharacterWriteQueue.abandonAfterConsecutiveFailures;
        i++
      ) {
        final report = await syncer.syncWithReport();
        expect(report.synced, isEmpty);
        abandoned.addAll(report.abandonedCharacterIds);
      }

      expect(abandoned, {_characterId});
      expect(await queue.allForOwner(_ownerA), isEmpty);
      expect(server.appliedWrites, isEmpty);
      final recorder = SyncAlertRecorder(
        db,
        queue,
        SyncAlertStore(db),
        CharacterDetailCache(cache),
      );
      final consumed = await recorder.recordAbandoned(_ownerA);
      expect(consumed.single.kindKey, 'currency');
      final alert = (await SyncAlertStore(db).allForOwner(_ownerA)).single;
      expect(alert.kind, SyncAlertKind.abandon);
      expect(alert.dataKind, 'currency');
      expect(alert.characterName, 'Aria');
    });

    test('ordre de rejeu : PV puis monnaies, chacun écrit une fois', () async {
      connectivity.goOffline();
      await repository.updateHp(
        characterId: _characterId,
        currentHp: 3,
        temporaryHp: 0,
      );
      clock = clock.add(const Duration(seconds: 5));
      await repository.adjustCurrency(
        characterId: _characterId,
        currency: CurrencyKind.gold,
        newAmount: 15,
      );
      connectivity.goOnline();

      expect(await syncer.sync(), {_characterId});

      expect(server.appliedWrites, hasLength(2));
      expect((server.appliedWrites.first.body as Map).keys, [
        'current_hp',
        'temporary_hp',
      ]);
      expect((server.appliedWrites.last.body as Map).keys, ['currency_gp']);
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });

    test('isolation par ownerId : le rejeu d\'un compte ne touche jamais la '
        'file d\'un autre', () async {
      await queue.enqueue(
        characterId: 'char-autre',
        ownerId: _ownerB,
        kind: PendingCharacterWriteKind.currency,
        targetId: '',
        payload: {
          'totals': {'currency_gp': 1},
        },
      );
      await adjustOffline(CurrencyKind.gold, 15);
      connectivity.goOnline();

      expect(await syncer.sync(), {_characterId});

      expect(await queue.allForOwner(_ownerB), hasLength(1));
      expect(server.appliedWrites, hasLength(1));
    });

    test('purge (déconnexion / suppression de compte) : removeAllForOwner '
        'retire le kind currency, pas celui d\'un autre compte', () async {
      await adjustOffline(CurrencyKind.gold, 15);
      await queue.enqueue(
        characterId: 'char-autre',
        ownerId: _ownerB,
        kind: PendingCharacterWriteKind.currency,
        targetId: '',
        payload: {
          'totals': {'currency_gp': 1},
        },
      );

      await queue.removeAllForOwner(_ownerA);

      expect(await queue.allForOwner(_ownerA), isEmpty);
      expect(await queue.allForOwner(_ownerB), hasLength(1));
    });
  });
}
