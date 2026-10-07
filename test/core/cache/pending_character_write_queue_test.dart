import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/cache/app_database.dart'
    hide PendingCharacterWrite;
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

    test('removeIfUnchanged supprime uniquement l\'entrée lue (characterId, '
        'kind) et retourne true', () async {
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
      final hp = (await queue.allForOwner('owner-1'))
          .singleWhere((write) => write.kind == PendingCharacterWriteKind.hp);

      expect(await queue.removeIfUnchanged(hp), isTrue);

      final pending = await queue.allForOwner('owner-1');
      expect(pending, hasLength(1));
      expect(pending.single.kind, PendingCharacterWriteKind.xp);
    });

    test('removeIfUnchanged sur une entrée déjà retirée ne fait rien et '
        'retourne false (pas d\'exception)', () async {
      await queue.enqueue(
        characterId: 'char-1',
        ownerId: 'owner-1',
        kind: PendingCharacterWriteKind.hp,
        payload: {'currentHp': 5, 'temporaryHp': 0},
      );
      final read = (await queue.allForOwner('owner-1')).single;
      expect(await queue.removeIfUnchanged(read), isTrue);

      expect(await queue.removeIfUnchanged(read), isFalse);
      expect(await queue.allForOwner('owner-1'), isEmpty);
    });

    test('removeIfUnchanged ne retire pas une entrée remplacée depuis sa '
        'lecture par une autre valeur', () async {
      await queue.enqueue(
        characterId: 'char-1',
        ownerId: 'owner-1',
        kind: PendingCharacterWriteKind.hp,
        payload: {'currentHp': 7, 'temporaryHp': 0},
      );
      final read = (await queue.allForOwner('owner-1')).single;
      await queue.enqueue(
        characterId: 'char-1',
        ownerId: 'owner-1',
        kind: PendingCharacterWriteKind.hp,
        payload: {'currentHp': 5, 'temporaryHp': 0},
      );

      expect(await queue.removeIfUnchanged(read), isFalse);

      expect((await queue.allForOwner('owner-1')).single.payload, {
        'currentHp': 5,
        'temporaryHp': 0,
      });
    });

    test('removeIfUnchanged ne retire pas une entrée remplacée depuis sa '
        'lecture par le MÊME contenu, même dans la même seconde (queuedAt, '
        'stocké à la seconde, avance à chaque remplacement)', () async {
      await queue.enqueue(
        characterId: 'char-1',
        ownerId: 'owner-1',
        kind: PendingCharacterWriteKind.hp,
        payload: {'currentHp': 7, 'temporaryHp': 0},
      );
      final read = (await queue.allForOwner('owner-1')).single;
      // Trois remplacements immédiats à l'identique.
      for (var i = 0; i < 3; i++) {
        await queue.enqueue(
          characterId: 'char-1',
          ownerId: 'owner-1',
          kind: PendingCharacterWriteKind.hp,
          payload: {'currentHp': 7, 'temporaryHp': 0},
        );
      }
      final latest = (await queue.allForOwner('owner-1')).single;

      expect(latest.queuedAt.isAfter(read.queuedAt), isTrue);
      expect(
        latest.queuedAt.difference(read.queuedAt),
        greaterThanOrEqualTo(const Duration(seconds: 3)),
      );
      expect(await queue.removeIfUnchanged(read), isFalse);
      expect(await queue.allForOwner('owner-1'), hasLength(1));
      expect(await queue.removeIfUnchanged(latest), isTrue);
    });

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

    test(
      "removeIfUnchanged ne retire jamais l'entrée d'un autre compte, "
      'même pour le même personnage, le même type et le même contenu',
      () async {
        await queue.enqueue(
          characterId: 'char-1',
          ownerId: 'owner-2',
          kind: PendingCharacterWriteKind.hp,
          payload: {'currentHp': 30, 'temporaryHp': 0},
        );
        final read = (await queue.allForOwner('owner-2')).single;

        final removed = await queue.removeIfUnchanged(
          PendingCharacterWrite(
            characterId: read.characterId,
            ownerId: 'owner-1',
            kind: read.kind,
            payload: read.payload,
            rawPayload: read.rawPayload,
            queuedAt: read.queuedAt,
          ),
        );

        expect(removed, isFalse);
        expect(await queue.allForOwner('owner-2'), hasLength(1));
      },
    );

    // Ajout QA (mutation survivante) : le contenu fait partie de la
    // condition, indépendamment de l'horodatage.
    test('removeIfUnchanged ne retire pas une entrée de même horodatage mais '
        'de contenu différent', () async {
      await queue.enqueue(
        characterId: 'char-1',
        ownerId: 'owner-1',
        kind: PendingCharacterWriteKind.hp,
        payload: {'currentHp': 5, 'temporaryHp': 0},
      );
      final read = (await queue.allForOwner('owner-1')).single;

      final removed = await queue.removeIfUnchanged(
        PendingCharacterWrite(
          characterId: read.characterId,
          ownerId: read.ownerId,
          kind: read.kind,
          payload: const {'currentHp': 9, 'temporaryHp': 0},
          rawPayload: '{"currentHp":9,"temporaryHp":0}',
          queuedAt: read.queuedAt,
        ),
      );

      expect(removed, isFalse);
      expect(await queue.allForOwner('owner-1'), hasLength(1));
    });

    test('forCharacter ne retourne que les écritures du personnage et du '
        'compte demandés', () async {
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
      await queue.enqueue(
        characterId: 'char-2',
        ownerId: 'owner-1',
        kind: PendingCharacterWriteKind.hp,
        payload: {'currentHp': 1, 'temporaryHp': 0},
      );
      await queue.enqueue(
        characterId: 'char-3',
        ownerId: 'owner-2',
        kind: PendingCharacterWriteKind.hp,
        payload: {'currentHp': 30, 'temporaryHp': 0},
      );

      final pending = await queue.forCharacter(
        ownerId: 'owner-1',
        characterId: 'char-1',
      );

      expect(pending.map((write) => write.kind).toSet(), {
        PendingCharacterWriteKind.hp,
        PendingCharacterWriteKind.xp,
      });
      expect(pending.every((write) => write.characterId == 'char-1'), isTrue);
      expect(
        await queue.forCharacter(ownerId: 'owner-2', characterId: 'char-1'),
        isEmpty,
      );
      expect(
        await queue.forCharacter(ownerId: 'owner-1', characterId: 'char-3'),
        isEmpty,
      );
    });

    test(
      'une ligne abandonnee est exclue de allForOwner/forCharacter (D34)',
      () async {
        await queue.enqueue(
          characterId: 'char-1',
          ownerId: 'owner-1',
          kind: PendingCharacterWriteKind.hp,
          payload: {'currentHp': 5, 'temporaryHp': 0},
        );
        final write = (await queue.allForOwner('owner-1')).single;
        for (
          var i = 0;
          i < PendingCharacterWriteQueue.abandonAfterConsecutiveFailures;
          i++
        ) {
          await queue.recordNonRetryableFailure(
            write: write,
            reason: 'Raison de test',
          );
        }

        expect(await queue.allForOwner('owner-1'), isEmpty);
        expect(
          await queue.forCharacter(ownerId: 'owner-1', characterId: 'char-1'),
          isEmpty,
        );
      },
    );

    test('forCharacter ignore une ligne de type inconnu au lieu de lever une '
        'erreur', () async {
      await db
          .into(db.pendingCharacterWrites)
          .insert(
            PendingCharacterWritesCompanion.insert(
              characterId: 'char-1',
              ownerId: 'owner-1',
              kind: 'type_futur',
              payload: '{}',
              queuedAt: DateTime.now(),
            ),
          );
      await queue.enqueue(
        characterId: 'char-1',
        ownerId: 'owner-1',
        kind: PendingCharacterWriteKind.xp,
        payload: {'newXp': 200},
      );

      final pending = await queue.forCharacter(
        ownerId: 'owner-1',
        characterId: 'char-1',
      );

      expect(pending.single.kind, PendingCharacterWriteKind.xp);
    });
  });

  // D33 : verrou en mémoire par (characterId, kind) partagé entre le dépôt
  // et le synchroniseur.
  group('PendingCharacterWriteQueue.runExclusive (D33)', () {
    late AppDatabase db;
    late PendingCharacterWriteQueue queue;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      queue = PendingCharacterWriteQueue(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('deux appels concurrents pour la MÊME clé sont sérialisés : le '
        'second ne démarre qu\'une fois le premier terminé', () async {
      final events = <String>[];
      final gate = Completer<void>();

      final first = queue.runExclusive(
        characterId: 'char-1',
        kind: PendingCharacterWriteKind.hp,
        action: () async {
          events.add('premier: debut');
          await gate.future;
          events.add('premier: fin');
        },
      );
      await pumpEventQueue();
      expect(events, ['premier: debut']);

      final second = queue.runExclusive(
        characterId: 'char-1',
        kind: PendingCharacterWriteKind.hp,
        action: () async {
          events.add('second: debut');
        },
      );
      await pumpEventQueue();
      expect(
        events,
        ['premier: debut'],
        reason:
            'le second appel ne doit pas démarrer son action tant que le '
            'premier (même clé) n\'est pas terminé',
      );

      gate.complete();
      await first;
      await second;

      expect(events, ['premier: debut', 'premier: fin', 'second: debut']);
    });

    test('deux appels concurrents pour des clés DIFFÉRENTES ne s\'attendent '
        'jamais entre eux (personnage différent)', () async {
      final events = <String>[];
      final gate = Completer<void>();

      final first = queue.runExclusive(
        characterId: 'char-1',
        kind: PendingCharacterWriteKind.hp,
        action: () async {
          events.add('char-1: debut');
          await gate.future;
        },
      );
      await pumpEventQueue();

      await queue.runExclusive(
        characterId: 'char-2',
        kind: PendingCharacterWriteKind.hp,
        action: () async => events.add('char-2'),
      );

      expect(events, [
        'char-1: debut',
        'char-2',
      ], reason: 'une clé différente ne doit jamais attendre char-1');

      gate.complete();
      await first;
    });

    test('deux appels concurrents pour des clés DIFFÉRENTES ne s\'attendent '
        'jamais entre eux (type différent, même personnage)', () async {
      final events = <String>[];
      final gate = Completer<void>();

      final first = queue.runExclusive(
        characterId: 'char-1',
        kind: PendingCharacterWriteKind.hp,
        action: () async {
          events.add('hp: debut');
          await gate.future;
        },
      );
      await pumpEventQueue();

      await queue.runExclusive(
        characterId: 'char-1',
        kind: PendingCharacterWriteKind.xp,
        action: () async => events.add('xp'),
      );

      expect(events, ['hp: debut', 'xp']);

      gate.complete();
      await first;
    });

    test('un appel qui échoue libère quand même le verrou pour le suivant, et '
        'son erreur continue de remonter à l\'appelant', () async {
      await expectLater(
        queue.runExclusive(
          characterId: 'char-1',
          kind: PendingCharacterWriteKind.hp,
          action: () async => throw Exception('échec de test'),
        ),
        throwsA(isA<Exception>()),
      );

      final events = <String>[];
      await queue.runExclusive(
        characterId: 'char-1',
        kind: PendingCharacterWriteKind.hp,
        action: () async => events.add('suivant'),
      );

      expect(events, ['suivant']);
    });

    test('trois appels concurrents pour la même clé sont traités dans l\'ordre '
        'd\'appel (FIFO)', () async {
      final order = <int>[];
      final gate = Completer<void>();

      final first = queue.runExclusive(
        characterId: 'char-1',
        kind: PendingCharacterWriteKind.hp,
        action: () async {
          await gate.future;
          order.add(1);
        },
      );
      await pumpEventQueue();
      final second = queue.runExclusive(
        characterId: 'char-1',
        kind: PendingCharacterWriteKind.hp,
        action: () async => order.add(2),
      );
      final third = queue.runExclusive(
        characterId: 'char-1',
        kind: PendingCharacterWriteKind.hp,
        action: () async => order.add(3),
      );

      gate.complete();
      await Future.wait([first, second, third]);

      expect(order, [1, 2, 3]);
    });
  });

  // D34 : compteur d'échecs, seuil d'abandon, consommation des messages.
  group('PendingCharacterWriteQueue.recordNonRetryableFailure/'
      'consumeAbandonedMessages (D34)', () {
    late AppDatabase db;
    late PendingCharacterWriteQueue queue;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      queue = PendingCharacterWriteQueue(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('un refus isolé (sous le seuil) incrémente le compteur sans '
        'abandonner ni retirer l\'entrée', () async {
      await queue.enqueue(
        characterId: 'char-1',
        ownerId: 'owner-1',
        kind: PendingCharacterWriteKind.hp,
        payload: {'currentHp': 5, 'temporaryHp': 0},
      );
      final write = (await queue.allForOwner('owner-1')).single;

      final abandoned = await queue.recordNonRetryableFailure(
        write: write,
        reason: 'Raison de test',
      );

      expect(abandoned, isFalse);
      expect(await queue.allForOwner('owner-1'), hasLength(1));
      expect(await queue.consumeAbandonedMessages(ownerId: 'owner-1'), isEmpty);
    });

    test('après abandonAfterConsecutiveFailures refus consécutifs, l\'entrée '
        'est abandonnée et son message devient consommable exactement une '
        'fois', () async {
      await queue.enqueue(
        characterId: 'char-1',
        ownerId: 'owner-1',
        kind: PendingCharacterWriteKind.hp,
        payload: {'currentHp': 5, 'temporaryHp': 0},
      );
      final write = (await queue.allForOwner('owner-1')).single;

      bool? lastResult;
      for (
        var i = 0;
        i < PendingCharacterWriteQueue.abandonAfterConsecutiveFailures;
        i++
      ) {
        lastResult = await queue.recordNonRetryableFailure(
          write: write,
          reason: 'PV refusés définitivement',
        );
      }

      expect(lastResult, isTrue);
      expect(await queue.allForOwner('owner-1'), isEmpty);

      final messages = await queue.consumeAbandonedMessages(ownerId: 'owner-1');
      expect(messages, ['PV refusés définitivement']);
      expect(
        await queue.consumeAbandonedMessages(ownerId: 'owner-1'),
        isEmpty,
        reason: 'consommé une fois : ne doit plus jamais être signalé',
      );
    });

    test(
      'un refus pour une version déjà remplacée (queuedAt/payload '
      'différents) ne compte pas et ne touche pas la nouvelle entrée',
      () async {
        await queue.enqueue(
          characterId: 'char-1',
          ownerId: 'owner-1',
          kind: PendingCharacterWriteKind.hp,
          payload: {'currentHp': 5, 'temporaryHp': 0},
        );
        final staleWrite = (await queue.allForOwner('owner-1')).single;
        await queue.enqueue(
          characterId: 'char-1',
          ownerId: 'owner-1',
          kind: PendingCharacterWriteKind.hp,
          payload: {'currentHp': 9, 'temporaryHp': 0},
        );

        final abandoned = await queue.recordNonRetryableFailure(
          write: staleWrite,
          reason: 'Ne doit jamais apparaître',
        );

        expect(abandoned, isFalse);
        final remaining = (await queue.allForOwner('owner-1')).single;
        expect(remaining.payload, {'currentHp': 9, 'temporaryHp': 0});
      },
    );

    test('consumeAbandonedMessages ne consomme que les entrées de owner-1, '
        'jamais celles d\'un autre compte', () async {
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
        payload: {'currentHp': 1, 'temporaryHp': 0},
      );
      final writeOwner1 = (await queue.forCharacter(
        ownerId: 'owner-1',
        characterId: 'char-1',
      )).single;
      final writeOwner2 = (await queue.forCharacter(
        ownerId: 'owner-2',
        characterId: 'char-2',
      )).single;
      for (
        var i = 0;
        i < PendingCharacterWriteQueue.abandonAfterConsecutiveFailures;
        i++
      ) {
        await queue.recordNonRetryableFailure(
          write: writeOwner1,
          reason: 'owner-1',
        );
        await queue.recordNonRetryableFailure(
          write: writeOwner2,
          reason: 'owner-2',
        );
      }

      expect(await queue.consumeAbandonedMessages(ownerId: 'owner-1'), [
        'owner-1',
      ]);
      expect(
        await queue.consumeAbandonedMessages(ownerId: 'owner-2'),
        ['owner-2'],
        reason:
            'reste consommable séparément, jamais retiré par erreur '
            'par la consommation du premier compte',
      );
    });

    test('enqueue remet à zéro le compteur et lève l\'abandon : une entrée '
        'abandonnée reprend un budget de tentatives neuf dès que le joueur '
        'saisit une nouvelle valeur', () async {
      await queue.enqueue(
        characterId: 'char-1',
        ownerId: 'owner-1',
        kind: PendingCharacterWriteKind.hp,
        payload: {'currentHp': 5, 'temporaryHp': 0},
      );
      final write = (await queue.allForOwner('owner-1')).single;
      for (
        var i = 0;
        i < PendingCharacterWriteQueue.abandonAfterConsecutiveFailures;
        i++
      ) {
        await queue.recordNonRetryableFailure(
          write: write,
          reason: 'Abandon initial',
        );
      }
      expect(await queue.allForOwner('owner-1'), isEmpty);

      // Le joueur ajuste à nouveau ses PV (nouvelle saisie, même clé
      // characterId/kind que l'entrée abandonnée).
      await queue.enqueue(
        characterId: 'char-1',
        ownerId: 'owner-1',
        kind: PendingCharacterWriteKind.hp,
        payload: {'currentHp': 11, 'temporaryHp': 0},
      );

      final revived = (await queue.allForOwner('owner-1')).single;
      expect(revived.payload, {'currentHp': 11, 'temporaryHp': 0});
      expect(
        await queue.consumeAbandonedMessages(ownerId: 'owner-1'),
        isEmpty,
        reason: 'la ligne a été relancée : plus rien à signaler',
      );
    });
  });
}
