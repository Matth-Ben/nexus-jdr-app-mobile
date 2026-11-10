// P6b : rejeu hors-ligne des conditions. Dépôt réel + file drift en mémoire +
// synchroniseur réel + faux serveur PostgREST du harnais (`test/support/`).

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/cache/app_database.dart'
    hide PendingCharacterWrite;
import 'package:personnages/core/cache/pending_character_write_queue.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/core/cache/sync_alert_store.dart';
import 'package:personnages/features/characters/data/character_conditions_repository.dart';
import 'package:personnages/features/characters/data/character_detail_cache.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/data/pending_character_write_syncer.dart';
import 'package:personnages/features/characters/data/sync_alert_recorder.dart';
import 'package:personnages/features/characters/domain/condition_type.dart';
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
  late SupabaseCharacterConditionsRepository conditions;
  late PendingCharacterWriteSyncer syncer;

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
        'conditions': ['poisoned'],
      },
    );
    client = await buildSignedInClient(server, ownerId: _ownerA);
    conditions = SupabaseCharacterConditionsRepository(
      client,
      connectivity,
      queue,
      cache,
    );
    syncer = PendingCharacterWriteSyncer(
      client,
      queue,
      cache,
      SupabaseCharacterRepository(client, cache, queue, connectivity),
    );
  });

  tearDown(() async {
    await connectivity.close();
    await db.close();
  });

  Future<WriteOutcome> setOffline(
    List<ConditionType> selection, {
    List<String> unknownKeys = const [],
  }) async {
    connectivity.goOffline();
    return conditions.setConditions(
      characterId: _characterId,
      conditions: selection,
      unknownKeys: unknownKeys,
    );
  }

  test('rejeu : le tableau complet (clés inconnues comprises) remplace la '
      'valeur serveur, filtré id ET owner_id, ligne retirée', () async {
    expect(
      await setOffline(
        [ConditionType.prone, ConditionType.blinded],
        unknownKeys: ['futur_etat'],
      ),
      WriteOutcome.queued,
    );
    connectivity.goOnline();

    expect(await syncer.sync(), {_characterId});

    expect(server.characterRow['conditions'], [
      'blinded',
      'prone',
      'futur_etat',
    ]);
    final patch = server.appliedWrites.single;
    expect(patch.query['id'], 'eq.$_characterId');
    expect(patch.query['owner_id'], 'eq.$_ownerA');
    expect(await queue.allForOwner(_ownerA), isEmpty);
  });

  test('rejeu idempotent : réponse perdue après application, le rejeu '
      'réécrit le même tableau absolu', () async {
    await setOffline([ConditionType.prone]);
    connectivity.goOnline();
    server.failAfterApply(1);

    expect(await syncer.sync(), isEmpty);
    expect(await queue.allForOwner(_ownerA), hasLength(1));
    expect(await syncer.sync(), {_characterId});

    expect(server.appliedWrites, hasLength(2));
    expect(
      server.appliedWrites.map((w) => (w.body as Map)['conditions']).toList(),
      [
        ['prone'],
        ['prone'],
      ],
    );
    expect(server.characterRow['conditions'], ['prone']);
    expect(await queue.allForOwner(_ownerA), isEmpty);
  });

  test('conflit : le serveur a changé entre-temps, le rejeu remplace quand '
      'même (dernier gagnant), sans signal de conflit', () async {
    await setOffline([ConditionType.prone]);
    server.concurrentChange({
      'conditions': ['stunned', 'charmed'],
    });
    connectivity.goOnline();

    final report = await syncer.syncWithReport();

    expect(report.synced, {_characterId});
    expect(report.conflicts, isEmpty);
    expect(server.characterRow['conditions'], ['prone']);
  });

  test(
    'coupure pendant le rejeu : l\'entrée reste, jamais abandonnée',
    () async {
      await setOffline([ConditionType.prone]);
      connectivity.goOnline();
      server.failBefore(1);

      expect(await syncer.sync(), isEmpty);
      expect(await queue.allForOwner(_ownerA), hasLength(1));
      expect(server.characterRow['conditions'], ['poisoned']);
    },
  );

  test('zéro ligne affectée (RLS silencieuse / personnage disparu) : refus '
      'non rejouable, abandon au seuil puis alerte persistée', () async {
    await setOffline([ConditionType.prone]);
    connectivity.goOnline();
    // Le personnage n'appartient plus à ce compte côté serveur.
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
    expect(await queue.allForOwner(_ownerA), isEmpty, reason: 'abandonnée');
    expect(server.appliedWrites, isEmpty);

    await cache.put(
      CharacterDetailCache.keyFor(ownerId: _ownerA, characterId: _characterId),
      {
        CharacterDetailCache.rowKey: {'name': 'Aria'},
      },
    );
    final recorder = SyncAlertRecorder(
      db,
      queue,
      SyncAlertStore(db),
      CharacterDetailCache(cache),
    );
    final consumed = await recorder.recordAbandoned(_ownerA);
    expect(consumed.single.kindKey, 'conditions');
    final alerts = await SyncAlertStore(db).allForOwner(_ownerA);
    expect(alerts, hasLength(1));
    expect(alerts.single.kind, SyncAlertKind.abandon);
    expect(alerts.single.dataKind, 'conditions');
    expect(alerts.single.characterName, 'Aria');
  });

  test('refus 42501 au rejeu : abandon, valeur serveur intacte', () async {
    await setOffline([ConditionType.prone]);
    connectivity.goOnline();
    server.rejectWith('42501');

    for (
      var i = 0;
      i < PendingCharacterWriteQueue.abandonAfterConsecutiveFailures;
      i++
    ) {
      await syncer.sync();
    }

    expect(await queue.allForOwner(_ownerA), isEmpty);
    expect(server.characterRow['conditions'], ['poisoned']);
  });

  test('ordre de rejeu : PV puis conditions de la même file, chacun écrit '
      'une fois', () async {
    connectivity.goOffline();
    final repository = SupabaseCharacterRepository(
      client,
      cache,
      queue,
      connectivity,
    );
    await repository.updateHp(
      characterId: _characterId,
      currentHp: 3,
      temporaryHp: 0,
    );
    clock = clock.add(const Duration(seconds: 5));
    await conditions.setConditions(
      characterId: _characterId,
      conditions: [ConditionType.prone],
    );
    connectivity.goOnline();

    expect(await syncer.sync(), {_characterId});

    expect(server.appliedWrites, hasLength(2));
    expect((server.appliedWrites.first.body as Map).keys, [
      'current_hp',
      'temporary_hp',
    ]);
    expect((server.appliedWrites.last.body as Map).keys, ['conditions']);
    expect(server.characterRow['current_hp'], 3);
    expect(server.characterRow['conditions'], ['prone']);
    expect(await queue.allForOwner(_ownerA), isEmpty);
  });

  test('isolation par ownerId : le rejeu d\'un compte ne touche jamais la '
      'file d\'un autre', () async {
    await queue.enqueue(
      characterId: 'char-autre',
      ownerId: _ownerB,
      kind: PendingCharacterWriteKind.conditions,
      targetId: '',
      payload: {
        'conditions': ['blinded'],
      },
    );
    await setOffline([ConditionType.prone]);
    connectivity.goOnline();

    expect(await syncer.sync(), {_characterId});

    expect(await queue.allForOwner(_ownerB), hasLength(1));
    expect(server.appliedWrites, hasLength(1));
    expect(server.characterRow['conditions'], ['prone']);
  });

  test('purge (déconnexion / suppression de compte) : removeAllForOwner '
      'retire le kind conditions, pas celui d\'un autre compte', () async {
    await setOffline([ConditionType.prone]);
    await queue.enqueue(
      characterId: 'char-autre',
      ownerId: _ownerB,
      kind: PendingCharacterWriteKind.conditions,
      targetId: '',
      payload: {
        'conditions': ['blinded'],
      },
    );

    await queue.removeAllForOwner(_ownerA);

    expect(await queue.allForOwner(_ownerA), isEmpty);
    expect(await queue.allForOwner(_ownerB), hasLength(1));
  });
}
