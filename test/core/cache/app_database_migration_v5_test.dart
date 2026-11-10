import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/pending_character_write_queue.dart';

/// Migration v4 -> v5 d'`AppDatabase` (chantier hors-ligne T1, constat c de la
/// relecture de la PR #248) : `ownerId` entre dans la clé primaire de
/// `PendingCharacterWrites`. Même technique et mêmes précautions que
/// `app_database_migration_test.dart` (vrai fichier SQLite fermé puis
/// rouvert pour déclencher `onUpgrade`).
void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('nexus_jdr_migration_v5_');
    dbFile = File('${tempDir.path}/nexus_jdr_cache.sqlite');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// Fichier au schéma v4 exact : clé primaire `(character_id, kind,
  /// target_id)`, sans `owner_id`.
  Future<void> seedV4File(List<List<Object?>> rows) async {
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
        PRIMARY KEY ("character_id", "kind", "target_id")
      )
    ''', const []);
    for (final row in rows) {
      await setup.runInsert(
        'INSERT INTO pending_character_writes '
        '(character_id, owner_id, kind, target_id, payload, queued_at, '
        'failure_count, abandoned, last_failure_message) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        row,
      );
    }
    await setup.runCustom('PRAGMA user_version = 4', const []);
    await setup.close();
  }

  test('v4 -> v5 : toutes les lignes sont conservées (clés, payload, '
      'compteurs, état abandonné)', () async {
    await seedV4File([
      [
        'char-1',
        'owner-1',
        'hp',
        '',
        '{"currentHp":5,"temporaryHp":0}',
        1700000000,
        2,
        0,
        null,
      ],
      [
        'char-1',
        'owner-1',
        'spell_slot',
        'std_3',
        '{"slotLevel":3,"slotsUsed":1,"isPactSlot":false}',
        1700000100,
        0,
        0,
        null,
      ],
      [
        'char-2',
        'owner-2',
        'xp',
        '',
        '{"newXp":900}',
        1700000200,
        5,
        1,
        'abandonnée',
      ],
    ]);

    final db = AppDatabase(NativeDatabase(dbFile));
    final queue = PendingCharacterWriteQueue(db);

    final owner1 = await queue.allForOwner('owner-1');
    expect(owner1.map((w) => (w.kind, w.targetId)), [
      (PendingCharacterWriteKind.hp, ''),
      (PendingCharacterWriteKind.spellSlot, 'std_3'),
    ]);
    expect(owner1.first.payload, {'currentHp': 5, 'temporaryHp': 0});

    final rows = await db.select(db.pendingCharacterWrites).get();
    expect(rows, hasLength(3));
    final hp = rows.singleWhere((r) => r.kind == 'hp');
    expect(hp.failureCount, 2);
    final xp = rows.singleWhere((r) => r.kind == 'xp');
    expect(xp.abandoned, isTrue);
    expect(xp.lastFailureMessage, 'abandonnée');
    expect(xp.failureCount, 5);

    await db.close();
  });

  test('v4 -> v5 : la clé primaire inclut bien owner_id (deux comptes, même '
      'personnage/kind/cible, coexistent ; impossible en v4)', () async {
    await seedV4File(const []);

    final db = AppDatabase(NativeDatabase(dbFile));
    final queue = PendingCharacterWriteQueue(db);

    for (final owner in ['owner-1', 'owner-2']) {
      await queue.enqueue(
        characterId: 'char-1',
        ownerId: owner,
        kind: PendingCharacterWriteKind.hp,
        targetId: '',
        payload: {'currentHp': owner == 'owner-1' ? 4 : 9, 'temporaryHp': 0},
      );
    }

    expect((await queue.allForOwner('owner-1')).single.payload['currentHp'], 4);
    expect((await queue.allForOwner('owner-2')).single.payload['currentHp'], 9);

    // Le remplacement d'un compte ne touche jamais l'entrée de l'autre.
    await queue.enqueue(
      characterId: 'char-1',
      ownerId: 'owner-1',
      kind: PendingCharacterWriteKind.hp,
      targetId: '',
      payload: {'currentHp': 1, 'temporaryHp': 0},
    );
    expect((await queue.allForOwner('owner-1')).single.payload['currentHp'], 1);
    expect((await queue.allForOwner('owner-2')).single.payload['currentHp'], 9);

    final info = await db
        .customSelect('PRAGMA table_info(pending_character_writes)')
        .get();
    final primaryKeyColumns = {
      for (final column in info)
        if (column.read<int>('pk') > 0) column.read<String>('name'),
    };
    expect(primaryKeyColumns, {
      'owner_id',
      'character_id',
      'kind',
      'target_id',
    });

    await db.close();
  });

  test('base neuve (v5) : même clé primaire à 4 colonnes', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final info = await db
        .customSelect('PRAGMA table_info(pending_character_writes)')
        .get();
    final primaryKeyColumns = {
      for (final column in info)
        if (column.read<int>('pk') > 0) column.read<String>('name'),
    };
    expect(primaryKeyColumns, {
      'owner_id',
      'character_id',
      'kind',
      'target_id',
    });
    expect(db.schemaVersion, 6);
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
