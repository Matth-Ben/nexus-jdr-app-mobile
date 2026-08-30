import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/pending_character_write_queue.dart';

/// `PendingCharacterWriteQueue` (`core/cache/`, table drift
/// `PendingCharacterWrites`) — file d'attente de synchro hors-ligne pour
/// `SupabaseCharacterRepository.updateHp`/`addXp`. Voir la doc de classe de
/// `PendingCharacterWrites` (`app_database.dart`) pour le rationale du
/// coalescing (upsert sur `(characterId, kind)`) et de l'isolation par
/// `ownerId`.
void main() {
  group('PendingCharacterWriteQueue', () {
    late AppDatabase db;
    late PendingCharacterWriteQueue queue;

    setUp(() {
      // Base drift en mémoire, jamais un vrai fichier disque dans les tests
      // (même principe que `reference_data_cache_test.dart`).
      db = AppDatabase(NativeDatabase.memory());
      queue = PendingCharacterWriteQueue(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('allForOwner retourne une liste vide sans aucune écriture en '
        'attente', () async {
      expect(await queue.allForOwner('owner-1'), isEmpty);
    });

    test('coalescing : deux enqueue successifs pour le même personnage/type ne '
        'laissent qu\'une seule ligne, la plus récente', () async {
      await queue.enqueue(
        characterId: 'char-1',
        ownerId: 'owner-1',
        kind: PendingCharacterWriteKind.hp,
        payload: {'currentHp': 5, 'temporaryHp': 0},
      );
      await queue.enqueue(
        characterId: 'char-1',
        ownerId: 'owner-1',
        kind: PendingCharacterWriteKind.hp,
        payload: {'currentHp': 8, 'temporaryHp': 2},
      );

      final pending = await queue.allForOwner('owner-1');

      expect(pending, hasLength(1));
      expect(pending.single.payload, {'currentHp': 8, 'temporaryHp': 2});
    });

    test('un personnage/type distinct ne coalesce jamais avec un autre : '
        'kind différent (hp vs xp) sur le même personnage', () async {
      await queue.enqueue(
        characterId: 'char-1',
        ownerId: 'owner-1',
        kind: PendingCharacterWriteKind.hp,
        payload: {'currentHp': 5, 'temporaryHp': 0},
      );
      await queue.enqueue(
        characterId: 'char-1',
        ownerId: 'owner-1',
        kind: PendingCharacterWriteKind.xp,
        payload: {'newXp': 200},
      );

      final pending = await queue.allForOwner('owner-1');

      expect(pending, hasLength(2));
      expect(
        pending.map((write) => write.kind),
        containsAll([
          PendingCharacterWriteKind.hp,
          PendingCharacterWriteKind.xp,
        ]),
      );
    });

    test('un personnage/type distinct ne coalesce jamais avec un autre : '
        'characterId différent, même kind', () async {
      await queue.enqueue(
        characterId: 'char-1',
        ownerId: 'owner-1',
        kind: PendingCharacterWriteKind.hp,
        payload: {'currentHp': 5, 'temporaryHp': 0},
      );
      await queue.enqueue(
        characterId: 'char-2',
        ownerId: 'owner-1',
        kind: PendingCharacterWriteKind.hp,
        payload: {'currentHp': 12, 'temporaryHp': 0},
      );

      final pending = await queue.allForOwner('owner-1');

      expect(pending, hasLength(2));
    });

    test(
      'remove supprime uniquement l\'entrée (characterId, kind) ciblée',
      (() async {
        await queue.enqueue(
          characterId: 'char-1',
          ownerId: 'owner-1',
          kind: PendingCharacterWriteKind.hp,
          payload: {'currentHp': 5, 'temporaryHp': 0},
        );
        await queue.enqueue(
          characterId: 'char-1',
          ownerId: 'owner-1',
          kind: PendingCharacterWriteKind.xp,
          payload: {'newXp': 200},
        );

        await queue.remove(
          characterId: 'char-1',
          kind: PendingCharacterWriteKind.hp,
        );

        final pending = await queue.allForOwner('owner-1');
        expect(pending, hasLength(1));
        expect(pending.single.kind, PendingCharacterWriteKind.xp);
      }),
    );

    test(
      'remove sur une clé inexistante ne fait rien (pas d\'exception)',
      () async {
        await queue.remove(
          characterId: 'char-inconnu',
          kind: PendingCharacterWriteKind.hp,
        );

        expect(await queue.allForOwner('owner-1'), isEmpty);
      },
    );

    test('isolation par utilisateur : allForOwner ne retourne jamais les '
        'écritures en attente d\'un autre compte, même sur le même appareil '
        '(deux personnages distincts, un par compte, comme en pratique — un '
        'characterId n\'appartient jamais qu\'à un seul owner_id, voir la RLS '
        'de la table characters)', () async {
      await queue.enqueue(
        characterId: 'char-1',
        ownerId: 'owner-1',
        kind: PendingCharacterWriteKind.hp,
        payload: {'currentHp': 5, 'temporaryHp': 0},
      );
      await queue.enqueue(
        characterId: 'char-2',
        ownerId: 'owner-2',
        kind: PendingCharacterWriteKind.hp,
        payload: {'currentHp': 30, 'temporaryHp': 0},
      );

      final ownerOnePending = await queue.allForOwner('owner-1');
      final ownerTwoPending = await queue.allForOwner('owner-2');

      expect(ownerOnePending, hasLength(1));
      expect(ownerOnePending.single.characterId, 'char-1');
      expect(ownerOnePending.single.payload, {
        'currentHp': 5,
        'temporaryHp': 0,
      });
      expect(ownerTwoPending, hasLength(1));
      expect(ownerTwoPending.single.characterId, 'char-2');
      expect(ownerTwoPending.single.payload, {
        'currentHp': 30,
        'temporaryHp': 0,
      });
    });
  });
}
