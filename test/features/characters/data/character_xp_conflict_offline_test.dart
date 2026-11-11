// T8 : détection de conflit F19 sur l'XP (base mémorisée à l'enfilage, comparée
// au serveur au rejeu) + alerte persistée. Dépôt réel + file drift en mémoire
// + synchroniseur réel + faux serveur PostgREST du harnais.

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
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../support/fake_character_write_server.dart';
import '../../../support/fake_connectivity_checker.dart';

const _characterId = 'char-1';
const _ownerA = 'owner-1';

void main() {
  late AppDatabase db;
  late PendingCharacterWriteQueue queue;
  late ReferenceDataCache cache;
  late FakeConnectivityChecker connectivity;
  late FakeCharacterWriteServer server;
  late SupabaseClient client;
  late SupabaseCharacterRepository repository;
  late PendingCharacterWriteSyncer syncer;

  Future<void> seedCache({bool withXp = true}) => cache.put(
    CharacterDetailCache.keyFor(ownerId: _ownerA, characterId: _characterId),
    {
      CharacterDetailCache.rowKey: {'name': 'Aria', if (withXp) 'xp': 100},
    },
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    queue = PendingCharacterWriteQueue(db);
    cache = ReferenceDataCache(db);
    connectivity = FakeConnectivityChecker();
    server = FakeCharacterWriteServer(
      characterRow: {
        'id': _characterId,
        'owner_id': _ownerA,
        'name': 'Aria',
        'xp': 100,
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
    connectivity.goOffline();
  });

  tearDown(() async {
    await connectivity.close();
    await db.close();
  });

  Future<Map<String, dynamic>> xpPayload() async =>
      (await queue.allForOwner(_ownerA)).single.payload;

  test('enfilage : la base serveur est mémorisée, et conservée au second '
      'ajustement', () async {
    await repository.addXp(characterId: _characterId, newXp: 150);
    expect(await xpPayload(), {'newXp': 150, 'baseXp': 100});

    await repository.addXp(characterId: _characterId, newXp: 200);
    expect(await xpPayload(), {'newXp': 200, 'baseXp': 100});
  });

  test('fiche sans XP en cache : pas de base, pas de détection', () async {
    await seedCache(withXp: false);
    await repository.addXp(characterId: _characterId, newXp: 150);
    expect(await xpPayload(), {'newXp': 150});

    server.concurrentChange({'xp': 400});
    connectivity.goOnline();
    final report = await syncer.syncWithReport();

    expect(report.synced, {_characterId});
    expect(report.conflicts, isEmpty);
  });

  test('serveur modifié ailleurs : conflit signalé, écriture envoyée quand '
      'même', () async {
    await repository.addXp(characterId: _characterId, newXp: 150);
    server.concurrentChange({'xp': 400});
    connectivity.goOnline();

    final report = await syncer.syncWithReport();

    expect(server.characterRow['xp'], 150);
    final conflict = report.conflicts.single;
    expect(conflict.kind, PendingCharacterWriteKind.xp);
    expect(conflict.serverValue, {'xp': 400});
    expect(conflict.queuedValue, {'xp': 150});
  });

  test('serveur inchangé ou déjà égal à la valeur en file : aucun '
      'conflit', () async {
    await repository.addXp(characterId: _characterId, newXp: 150);
    connectivity.goOnline();
    expect((await syncer.syncWithReport()).conflicts, isEmpty);

    connectivity.goOffline();
    await repository.addXp(characterId: _characterId, newXp: 300);
    // Réponse perdue : le serveur a déjà la valeur en file.
    server.concurrentChange({'xp': 300});
    connectivity.goOnline();
    expect((await syncer.syncWithReport()).conflicts, isEmpty);
  });

  test('alerte persistée : valeur serveur d\'avant l\'envoi ET valeur '
      'appliquée', () async {
    await repository.addXp(characterId: _characterId, newXp: 150);
    server.concurrentChange({'xp': 400});
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
    expect(alert.dataKind, 'xp');
    expect(alert.serverValue, {'xp': 400, 'queued': 150});
  });
}
