import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/pending_character_write_queue.dart';
import 'package:personnages/core/cache/sync_alert_store.dart';
import 'package:personnages/core/cache/sync_state_store.dart';

/// Migration v5 -> v6 d'`AppDatabase` (chantier hors-ligne T2) : ajout des
/// tables `sync_alerts` et `sync_states`, sans toucher à la file existante.
/// Vrai fichier SQLite fermé puis rouvert pour déclencher `onUpgrade`.
void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('nexus_jdr_migration_v6_');
    dbFile = File('${tempDir.path}/nexus_jdr_cache.sqlite');
  });

  tearDown(() {
    try {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    } on FileSystemException {
      // Fichier encore tenu par la connexion qui a échoué à migrer (Windows).
    }
  });

  /// Fichier au schéma v5 exact (clé primaire à 4 colonnes, aucune des deux
  /// nouvelles tables), avec de vraies lignes de file.
  Future<void> seedV5File() async {
    final setup = NativeDatabase(dbFile);
    await setup.ensureOpen(_NoopUser());
    await setup.runCustom('''
      CREATE TABLE "pending_character_writes" (
        "character_id" TEXT NOT NULL,
        "owner_id" TEXT NOT NULL,
        "kind" TEXT NOT NULL,
        "target_id" TEXT NOT NULL DEFAULT '',
        "payload" TEXT NOT NULL,
        "queued_at" INTEGER NOT NULL,
        "failure_count" INTEGER NOT NULL DEFAULT 0,
        "abandoned" INTEGER NOT NULL DEFAULT 0 CHECK ("abandoned" IN (0, 1)),
        "last_failure_message" TEXT NULL,
        PRIMARY KEY ("owner_id", "character_id", "kind", "target_id")
      )
    ''', const []);
    await setup.runCustom('''
      CREATE TABLE "cached_reference_entries" (
        "key" TEXT NOT NULL,
        "payload" TEXT NOT NULL,
        "cached_at" INTEGER NOT NULL,
        PRIMARY KEY ("key")
      )
    ''', const []);
    const insert =
        'INSERT INTO pending_character_writes '
        '(character_id, owner_id, kind, target_id, payload, queued_at, '
        'failure_count, abandoned, last_failure_message) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)';
    await setup.runInsert(insert, [
      'char-1',
      'owner-1',
      'hp',
      '',
      '{"currentHp":5,"temporaryHp":0}',
      1700000000,
      2,
      0,
      null,
    ]);
    await setup.runInsert(insert, [
      'char-2',
      'owner-2',
      'xp',
      '',
      '{"newXp":900}',
      1700000200,
      5,
      1,
      'abandonnée',
    ]);
    await setup.runCustom('PRAGMA user_version = 5', const []);
    await setup.close();
  }

  test('v5 -> v6 : les lignes de la file sont conservées, les deux nouvelles '
      'tables existent, vides et utilisables', () async {
    await seedV5File();

    final db = AppDatabase(NativeDatabase(dbFile));
    final queue = PendingCharacterWriteQueue(db);

    final owner1 = await queue.allForOwner('owner-1');
    expect(owner1.single.kind, PendingCharacterWriteKind.hp);
    expect(owner1.single.payload, {'currentHp': 5, 'temporaryHp': 0});
    final rows = await db.select(db.pendingCharacterWrites).get();
    expect(rows, hasLength(2));
    expect(rows.singleWhere((r) => r.kind == 'xp').abandoned, isTrue);

    expect(await db.select(db.syncAlerts).get(), isEmpty);
    expect(await db.select(db.syncStates).get(), isEmpty);

    final alerts = SyncAlertStore(db);
    await alerts.add(
      ownerId: 'owner-1',
      kind: SyncAlertKind.abandon,
      characterId: 'char-1',
      characterName: 'Aria',
      dataKind: 'hp',
      serverValue: {'currentHp': 7, 'maxHp': 12},
    );
    expect((await alerts.allForOwner('owner-1')).single.characterName, 'Aria');

    final state = SyncStateStore(db);
    await state.markSuccess('owner-1');
    expect(await state.lastSuccess('owner-1'), isNotNull);

    await db.close();
  });

  test('v5 -> v6 atomique : si la 2e table ne peut pas être créée, la 1re est '
      'annulée (rollback complet)', () async {
    await seedV5File();
    // Un index « sync_states » existe déjà : le 2e `createTable` échoue, tout
    // doit être annulé (la 1re table aussi).
    final setup = NativeDatabase(dbFile);
    await setup.ensureOpen(_NoopUser());
    await setup.runCustom(
      'CREATE INDEX "sync_states" ON cached_reference_entries (key)',
      const [],
    );
    await setup.runCustom('PRAGMA user_version = 5', const []);
    await setup.close();

    final db = AppDatabase(NativeDatabase(dbFile));
    await expectLater(
      db.select(db.pendingCharacterWrites).get(),
      throwsA(anything),
    );
    await db.close();

    final check = NativeDatabase(dbFile);
    await check.ensureOpen(_NoopUser());
    final rows = await check.runSelect(
      "SELECT name FROM sqlite_master WHERE name = 'sync_alerts'",
      const [],
    );
    expect(rows, isEmpty, reason: 'createTable(syncAlerts) annulé');
    await check.close();
  });

  test('base neuve (v6) : même schéma que la migration', () async {
    final db = AppDatabase(NativeDatabase.memory());
    expect(db.schemaVersion, 6);
    final tables = {
      for (final row
          in await db
              .customSelect("SELECT name FROM sqlite_master WHERE type='table'")
              .get())
        row.read<String>('name'),
    };
    expect(tables, containsAll(['sync_alerts', 'sync_states']));
    await db.close();
  });
}

class _NoopUser implements QueryExecutorUser {
  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
