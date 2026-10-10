import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/pending_character_write_queue.dart';

/// Migration v3 -> v4 d'`AppDatabase` (D11 du registre de dette technique,
/// 09/10/2026) : ajout de `PendingCharacterWrites.targetId` à la clé
/// primaire, qui ne peut pas être fait par un simple `ALTER TABLE` (SQLite ne
/// permet pas de modifier une contrainte `PRIMARY KEY` existante) — la
/// migration recrée donc la table entière (voir `AppDatabase.migration`).
///
/// Ce test ouvre un vrai fichier SQLite (pas `NativeDatabase.memory()`,
/// contrairement au reste des tests de ce dépôt) : il doit être fermé et
/// réouvert pour que la migration se déclenche réellement au second
/// ouverture, ce qu'une base en mémoire ne permet pas de façon fiable d'un
/// bout à l'autre du test (chaque `NativeDatabase.memory()` est une instance
/// isolée, jamais partagée entre deux `AppDatabase`).
void main() {
  group('AppDatabase migration v3 -> v4 (D11)', () {
    late Directory tempDir;
    late File dbFile;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync(
        'nexus_jdr_migration_test_',
      );
      dbFile = File('${tempDir.path}/nexus_jdr_cache.sqlite');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test(
      'une entrée hp/xp écrite en schéma v3 (sans target_id) survit à la '
      "migration avec target_id = '' et reste lisible/retirable normalement",
      () async {
        // 1. Prépare manuellement un fichier SQLite au schéma v3 exact (DDL
        // relevé sur une base v4 fraîche, `target_id`/sa place dans la clé
        // primaire retirés) — jamais une vraie migration drift depuis une
        // vieille version du code (non disponible ici), mais la même chose
        // du point de vue du fichier SQLite résultant : c'est uniquement le
        // contenu du fichier, pas le chemin de code qui l'a produit, qui
        // importe pour `AppDatabase.migration`.
        final setup = NativeDatabase(dbFile);
        await setup.ensureOpen(_NoopUser());
        await setup.runCustom('''
          CREATE TABLE "pending_character_writes" (
            "character_id" TEXT NOT NULL,
            "owner_id" TEXT NOT NULL,
            "kind" TEXT NOT NULL,
            "payload" TEXT NOT NULL,
            "queued_at" INTEGER NOT NULL,
            "failure_count" INTEGER NOT NULL DEFAULT 0,
            "abandoned" INTEGER NOT NULL DEFAULT 0 CHECK ("abandoned" IN (0, 1)),
            "last_failure_message" TEXT NULL,
            PRIMARY KEY ("character_id", "kind")
          )
        ''', const []);
        await setup.runInsert(
          'INSERT INTO pending_character_writes '
          '(character_id, owner_id, kind, payload, queued_at, failure_count, '
          'abandoned, last_failure_message) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
          [
            'char-1',
            'owner-1',
            'hp',
            '{"currentHp":5,"temporaryHp":0}',
            1700000000,
            0,
            0,
            null,
          ],
        );
        await setup.runCustom('PRAGMA user_version = 3', const []);
        await setup.close();

        // 2. Rouvre avec le code actuel (schéma v4) : déclenche
        // `AppDatabase.migration`'s `onUpgrade` de 3 vers 4.
        final db = AppDatabase(NativeDatabase(dbFile));
        final queue = PendingCharacterWriteQueue(db);

        final pending = await queue.allForOwner('owner-1');

        expect(pending, hasLength(1));
        expect(pending.single.characterId, 'char-1');
        expect(pending.single.kind, PendingCharacterWriteKind.hp);
        expect(
          pending.single.targetId,
          '',
          reason:
              'une entrée hp/xp pré-existante au schéma v3 (sans target_id) '
              'doit se retrouver avec target_id vide après migration — même '
              'comportement que si elle avait toujours été mise en file par '
              'le code actuel',
        );
        expect(pending.single.payload, {'currentHp': 5, 'temporaryHp': 0});

        // 3. Vérifie que l'entrée migrée se comporte normalement avec le
        // reste de l'API (pas seulement lisible, mais aussi manipulable) :
        // un nouvel `enqueue` du même personnage/type coalesce toujours
        // dessus (même primary key logique qu'avant la migration), et
        // `removeIfUnchanged` fonctionne.
        await queue.enqueue(
          characterId: 'char-1',
          ownerId: 'owner-1',
          kind: PendingCharacterWriteKind.hp,
          targetId: '',
          payload: {'currentHp': 8, 'temporaryHp': 1},
        );
        final afterCoalesce = await queue.allForOwner('owner-1');
        expect(afterCoalesce, hasLength(1));
        expect(afterCoalesce.single.payload, {
          'currentHp': 8,
          'temporaryHp': 1,
        });

        expect(await queue.removeIfUnchanged(afterCoalesce.single), isTrue);
        expect(await queue.allForOwner('owner-1'), isEmpty);

        await db.close();
      },
    );

    test('la migration recrée bien la table avec la nouvelle clé primaire : '
        'deux targetId différents du même personnage/kind peuvent désormais '
        'coexister (impossible au schéma v3)', () async {
      final setup = NativeDatabase(dbFile);
      await setup.ensureOpen(_NoopUser());
      await setup.runCustom('''
          CREATE TABLE "pending_character_writes" (
            "character_id" TEXT NOT NULL,
            "owner_id" TEXT NOT NULL,
            "kind" TEXT NOT NULL,
            "payload" TEXT NOT NULL,
            "queued_at" INTEGER NOT NULL,
            "failure_count" INTEGER NOT NULL DEFAULT 0,
            "abandoned" INTEGER NOT NULL DEFAULT 0 CHECK ("abandoned" IN (0, 1)),
            "last_failure_message" TEXT NULL,
            PRIMARY KEY ("character_id", "kind")
          )
        ''', const []);
      await setup.runCustom('PRAGMA user_version = 3', const []);
      await setup.close();

      final db = AppDatabase(NativeDatabase(dbFile));
      final queue = PendingCharacterWriteQueue(db);

      await queue.enqueue(
        characterId: 'char-1',
        ownerId: 'owner-1',
        kind: PendingCharacterWriteKind.spellSlot,
        targetId: 'std_1',
        payload: {'slotLevel': 1, 'slotsUsed': 1, 'isPactSlot': false},
      );
      await queue.enqueue(
        characterId: 'char-1',
        ownerId: 'owner-1',
        kind: PendingCharacterWriteKind.spellSlot,
        targetId: 'std_2',
        payload: {'slotLevel': 2, 'slotsUsed': 1, 'isPactSlot': false},
      );

      final pending = await queue.allForOwner('owner-1');
      expect(pending, hasLength(2));

      await db.close();
    });
  });
}

/// `QueryExecutorUser` minimal exigé par `NativeDatabase.ensureOpen` pour une
/// ouverture manuelle hors du cycle de vie habituel d'`AppDatabase` (setup du
/// fichier v3 avant la vraie migration, voir la documentation de ce fichier).
class _NoopUser implements QueryExecutorUser {
  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
