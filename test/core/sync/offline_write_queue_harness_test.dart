// Tests du circuit de synchro hors-ligne (file drift + synchroniseur +
// coordinateur) construits sur le harnais de `test/support/` : faux serveur
// à pannes programmables, connectivité pilotable, horloge injectable, drift
// en mémoire. Chantier hors-ligne, tranche 0 : AUCUN changement de
// comportement de production, ces tests figent l'existant (dont deux défauts
// connus, voir les tests de caractérisation « à inverser en tranche T1 »).

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/cache/app_database.dart'
    hide PendingCharacterWrite;
import 'package:personnages/core/cache/cache_providers.dart';
import 'package:personnages/core/cache/pending_character_write_queue.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/core/network/supabase_client_provider.dart';
import 'package:personnages/core/notifications/notification_providers.dart';
import 'package:personnages/features/auth/data/auth_repository.dart';
import 'package:personnages/features/auth/domain/auth_failure.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/data/pending_character_write_syncer.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:personnages/features/characters/presentation/providers/character_detail_provider.dart';
import 'package:personnages/features/characters/presentation/providers/character_providers.dart';
import 'package:personnages/features/characters/presentation/providers/character_write_sync_coordinator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../support/fake_character_write_server.dart';
import '../../support/fake_connectivity_checker.dart';

const _characterId = 'char-1';
const _ownerA = 'owner-1';
const _ownerB = 'owner-2';

/// Tout le décor d'un test : base locale en mémoire, horloge, connectivité,
/// faux serveur, dépôt/synchroniseur réels du compte [_ownerA].
class _Stack {
  _Stack._(
    this.db,
    this.clock,
    this.queue,
    this.cache,
    this.connectivity,
    this.server,
    this.client,
    this.repository,
    this.syncer,
  );

  static Future<_Stack> create() async {
    final db = AppDatabase(NativeDatabase.memory());
    final clock = _Clock();
    final queue = PendingCharacterWriteQueue(db, now: clock.call);
    final cache = ReferenceDataCache(db);
    final connectivity = FakeConnectivityChecker();
    final server = FakeCharacterWriteServer();
    final client = await buildSignedInClient(server, ownerId: _ownerA);
    final repository = SupabaseCharacterRepository(
      client,
      cache,
      queue,
      connectivity,
    );
    final syncer = PendingCharacterWriteSyncer(
      client,
      queue,
      cache,
      repository,
    );
    return _Stack._(
      db,
      clock,
      queue,
      cache,
      connectivity,
      server,
      client,
      repository,
      syncer,
    );
  }

  final AppDatabase db;
  final _Clock clock;
  final PendingCharacterWriteQueue queue;
  final ReferenceDataCache cache;
  final FakeConnectivityChecker connectivity;
  final FakeCharacterWriteServer server;
  final SupabaseClient client;
  final SupabaseCharacterRepository repository;
  final PendingCharacterWriteSyncer syncer;

  Future<void> dispose() async {
    await connectivity.close();
    await db.close();
  }

  Future<int> pendingCount([String owner = _ownerA]) async =>
      (await queue.allForOwner(owner)).length;

  Future<List<_Row>> allRows() async => [
    for (final row in await db.select(db.pendingCharacterWrites).get())
      (
        ownerId: row.ownerId,
        abandoned: row.abandoned,
        failureCount: row.failureCount,
        lastFailureMessage: row.lastFailureMessage,
      ),
  ];
}

typedef _Row = ({
  String ownerId,
  bool abandoned,
  int failureCount,
  String? lastFailureMessage,
});

/// Horloge injectable : avance seulement quand le test le demande.
class _Clock {
  DateTime _now = DateTime.utc(2026, 11, 10, 12);

  DateTime call() => _now;

  void advance(Duration by) => _now = _now.add(by);
}

void main() {
  late _Stack stack;

  setUp(() async {
    stack = await _Stack.create();
  });

  tearDown(() async {
    await stack.dispose();
  });

  group('rejeu de la file', () {
    test('après N coupures (requête perdue avant envoi) : une seule écriture '
        'appliquée, aucun doublon d\'effet', () async {
      stack.connectivity.goOffline();
      final outcome = await stack.repository.updateHp(
        characterId: _characterId,
        currentHp: 7,
        temporaryHp: 2,
      );
      expect(outcome, WriteOutcome.queued);
      expect(await stack.pendingCount(), 1);

      stack.connectivity.goOnline();
      stack.server.failBefore(2);

      expect(await stack.syncer.sync(), isEmpty, reason: 'coupure 1');
      expect(await stack.syncer.sync(), isEmpty, reason: 'coupure 2');
      expect(await stack.pendingCount(), 1, reason: 'toujours en file');
      expect(stack.server.appliedWrites, isEmpty);

      expect(await stack.syncer.sync(), {_characterId});

      expect(stack.server.appliedWrites, hasLength(1));
      expect(stack.server.characterRow['current_hp'], 7);
      expect(stack.server.characterRow['temporary_hp'], 2);
      expect(await stack.pendingCount(), 0);
      // Une passe de plus ne renvoie plus rien.
      expect(await stack.syncer.sync(), isEmpty);
      expect(stack.server.appliedWrites, hasLength(1));
    });

    test('réponse perdue après application (cas D184 côté rejeu) : l\'entrée '
        'reste en file, le rejeu réapplique la MÊME valeur absolue '
        '(idempotent), état final inchangé', () async {
      stack.connectivity.goOffline();
      await stack.repository.updateHp(
        characterId: _characterId,
        currentHp: 4,
        temporaryHp: 0,
      );
      stack.connectivity.goOnline();
      stack.server.failAfterApply(1);

      expect(await stack.syncer.sync(), isEmpty);
      expect(stack.server.appliedWrites, hasLength(1));
      expect(await stack.pendingCount(), 1);

      expect(await stack.syncer.sync(), {_characterId});

      final bodies = stack.server.appliedWrites.map((w) => w.body).toList();
      expect(bodies, hasLength(2));
      expect(bodies[0], bodies[1], reason: 'valeur absolue : effet identique');
      expect(stack.server.characterRow['current_hp'], 4);
      expect(await stack.pendingCount(), 0);
    });

    test('ordre de rejeu : celui de la mise en file (parcours de la table '
        'drift, sans ORDER BY explicite)', () async {
      // Caractérisation de l'existant : `allForOwner` n'a pas de ORDER BY ;
      // SQLite parcourt la table dans l'ordre d'insertion, qui coïncide avec
      // l'ordre de mise en file (et NON avec l'ordre de clé primaire
      // characterId/kind/targetId : hp < spellSlot < xp). L'ordre n'est donc
      // pas garanti par le contrat, seulement observé.
      stack.connectivity.goOffline();
      await stack.repository.castSpell(
        characterId: _characterId,
        slotLevel: 1,
        slotsUsed: 1,
      );
      stack.clock.advance(const Duration(minutes: 1));
      await stack.repository.addXp(characterId: _characterId, newXp: 300);
      stack.clock.advance(const Duration(minutes: 1));
      await stack.repository.updateHp(
        characterId: _characterId,
        currentHp: 5,
        temporaryHp: 0,
      );
      stack.connectivity.goOnline();

      await stack.syncer.sync();

      final order = [
        for (final w in stack.server.appliedWrites)
          w.table == 'characters'
              ? (w.body as Map).keys.first as String
              : w.table,
      ];
      expect(order, ['character_spell_slots', 'xp', 'current_hp']);
      expect(await stack.pendingCount(), 0);
    });

    test('horloge injectable : un remplacement dans la même seconde avance '
        'quand même queuedAt d\'au moins une seconde', () async {
      stack.connectivity.goOffline();
      await stack.repository.updateHp(
        characterId: _characterId,
        currentHp: 9,
        temporaryHp: 0,
      );
      final first = (await stack.queue.allForOwner(_ownerA)).single.queuedAt;
      await stack.repository.updateHp(
        characterId: _characterId,
        currentHp: 8,
        temporaryHp: 0,
      );
      final second = (await stack.queue.allForOwner(_ownerA)).single;

      expect(first.toUtc(), DateTime.utc(2026, 11, 10, 12));
      expect(second.queuedAt.difference(first), const Duration(seconds: 1));
      expect(second.payload['currentHp'], 8, reason: 'upsert, pas un ajout');
    });

    test('deux sync() simultanés : une seule écriture envoyée (runExclusive '
        'sérialise, la 2e passe relit la file et la trouve vide)', () async {
      stack.connectivity.goOffline();
      await stack.repository.updateHp(
        characterId: _characterId,
        currentHp: 3,
        temporaryHp: 0,
      );
      stack.connectivity.goOnline();

      await Future.wait([stack.syncer.sync(), stack.syncer.sync()]);

      expect(stack.server.appliedWrites, hasLength(1));
      expect(await stack.pendingCount(), 0);
    });

    test('runExclusive : jamais deux actions simultanées pour une même clé, '
        'FIFO ; deux clés différentes ne s\'attendent pas', () async {
      var running = 0;
      var maxRunning = 0;
      final order = <int>[];

      Future<void> run(int id, {String target = ''}) {
        return stack.queue.runExclusive(
          characterId: _characterId,
          kind: PendingCharacterWriteKind.hp,
          targetId: target,
          action: () async {
            running++;
            if (running > maxRunning) maxRunning = running;
            order.add(id);
            await Future<void>.delayed(const Duration(milliseconds: 20));
            running--;
          },
        );
      }

      await Future.wait([run(1), run(2), run(3)]);
      expect(maxRunning, 1);
      expect(order, [1, 2, 3]);

      running = 0;
      maxRunning = 0;
      await Future.wait([run(4, target: 'a'), run(5, target: 'b')]);
      expect(maxRunning, 2, reason: 'clés distinctes : en parallèle');
    });

    test('un échec dans runExclusive libère le verrou pour l\'appel suivant '
        'et remonte l\'erreur', () async {
      final failing = stack.queue.runExclusive<void>(
        characterId: _characterId,
        kind: PendingCharacterWriteKind.xp,
        targetId: '',
        action: () async => throw StateError('boom'),
      );
      final next = stack.queue.runExclusive(
        characterId: _characterId,
        kind: PendingCharacterWriteKind.xp,
        targetId: '',
        action: () async => 'ok',
      );

      await expectLater(failing, throwsStateError);
      expect(await next, 'ok');
    });
  });

  group('abandon après le seuil (D34) et SQLSTATE non rejouables (D61)', () {
    Future<void> queueOneHpWrite() async {
      stack.connectivity.goOffline();
      await stack.repository.updateHp(
        characterId: _characterId,
        currentHp: 6,
        temporaryHp: 0,
      );
      stack.connectivity.goOnline();
    }

    for (final sqlstate in ['42501', '23503', '22003', '22P02']) {
      test('SQLSTATE $sqlstate : refus non rejouable, abandon à la '
          '${PendingCharacterWriteQueue.abandonAfterConsecutiveFailures}e '
          'tentative, plus aucune requête ensuite', () async {
        await queueOneHpWrite();
        stack.server.rejectWith(sqlstate);

        for (
          var i = 1;
          i < PendingCharacterWriteQueue.abandonAfterConsecutiveFailures;
          i++
        ) {
          expect(await stack.syncer.sync(), isEmpty);
          expect(await stack.pendingCount(), 1, reason: 'tentative $i');
        }
        expect(await stack.syncer.sync(), isEmpty);
        expect(await stack.pendingCount(), 0, reason: 'abandonnée');

        final rows = await stack.allRows();
        expect(rows.single.abandoned, isTrue);
        expect(rows.single.lastFailureMessage, contains('vos PV'));
        expect(
          stack.server.writes,
          hasLength(PendingCharacterWriteQueue.abandonAfterConsecutiveFailures),
        );

        await stack.syncer.sync();
        expect(
          stack.server.writes,
          hasLength(PendingCharacterWriteQueue.abandonAfterConsecutiveFailures),
          reason: 'une entrée abandonnée n\'est plus jamais rejouée',
        );
      });
    }

    test('un code non SQLSTATE (PGRST000 / erreur transitoire) n\'abandonne '
        'jamais : l\'entrée reste en file indéfiniment (D32)', () async {
      await queueOneHpWrite();
      stack.server.rejectWith('PGRST000');

      for (var i = 0; i < 8; i++) {
        await stack.syncer.sync();
      }

      expect(await stack.pendingCount(), 1);
      expect((await stack.allRows()).single.abandoned, isFalse);
    });

    test('une nouvelle valeur mise en file repart avec un budget neuf '
        '(failureCount remis à zéro)', () async {
      await queueOneHpWrite();
      stack.server.rejectWith('42501');
      await stack.syncer.sync();
      await stack.syncer.sync();
      expect((await stack.allRows()).single.failureCount, 2);

      stack.connectivity.goOffline();
      await stack.repository.updateHp(
        characterId: _characterId,
        currentHp: 5,
        temporaryHp: 0,
      );

      final row = (await stack.allRows()).single;
      expect(row.failureCount, 0);
      expect(row.abandoned, isFalse);
    });
  });

  group('coordinateur : signalement des abandons', () {
    /// Abandonne d'abord une entrée directement (5 refus), hors coordinateur.
    Future<void> seedAbandonedHpWrite() async {
      stack.connectivity.goOffline();
      await stack.repository.updateHp(
        characterId: _characterId,
        currentHp: 6,
        temporaryHp: 0,
      );
      stack.connectivity.goOnline();
      stack.server.rejectWith('42501');
      for (
        var i = 0;
        i < PendingCharacterWriteQueue.abandonAfterConsecutiveFailures;
        i++
      ) {
        await stack.syncer.sync();
      }
      stack.server.clearRejection();
      expect((await stack.allRows()).single.abandoned, isTrue);
    }

    List<Override> overrides(
      GlobalKey<ScaffoldMessengerState> key,
      _CountingRepository repository,
    ) => [
      characterRepositoryProvider.overrideWithValue(repository),
      pendingCharacterWriteSyncerProvider.overrideWithValue(stack.syncer),
      pendingCharacterWriteQueueProvider.overrideWithValue(stack.queue),
      connectivityCheckerProvider.overrideWithValue(stack.connectivity),
      supabaseClientProvider.overrideWithValue(stack.client),
      scaffoldMessengerKeyProvider.overrideWithValue(key),
    ];

    test('D62 : messenger == null (clé jamais attachée) -> les messages ne '
        'sont PAS consommés, la ligne abandonnée reste en base', () async {
      await seedAbandonedHpWrite();
      final key = GlobalKey<ScaffoldMessengerState>();
      final container = ProviderContainer(
        overrides: overrides(key, _CountingRepository()),
      );
      addTearDown(container.dispose);

      container.read(characterWriteSyncCoordinatorProvider);
      await pumpEventQueue();
      stack.connectivity.emitRestored();
      await pumpEventQueue();

      final rows = await stack.allRows();
      expect(rows, hasLength(1), reason: 'jamais consommée sans messenger');
      expect(rows.single.abandoned, isTrue);
      expect(rows.single.lastFailureMessage, isNotEmpty);
    });

    testWidgets('message d\'abandon affiché puis consommé une seule fois, au '
        'passage de synchro qui suit l\'abandon', (tester) async {
      final key = GlobalKey<ScaffoldMessengerState>();
      final repository = _CountingRepository();
      await tester.runAsync(() async {
        stack.connectivity.goOffline();
        await stack.repository.updateHp(
          characterId: _characterId,
          currentHp: 6,
          temporaryHp: 0,
        );
        stack.connectivity.goOnline();
        stack.server.rejectWith('42501');
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(key, repository),
          child: MaterialApp(
            scaffoldMessengerKey: key,
            home: Consumer(
              builder: (context, ref, _) {
                ref.watch(characterWriteSyncCoordinatorProvider);
                return const Scaffold(body: SizedBox());
              },
            ),
          ),
        ),
      );

      // Démarrage = tentative 1 ; 4 retours de réseau = tentatives 2 à 5.
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(() async {
          stack.connectivity.emitRestored();
          await Future<void>.delayed(const Duration(milliseconds: 200));
        });
        await tester.pump();
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pump();

      expect(find.textContaining('vos PV'), findsOneWidget);
      expect(await tester.runAsync(stack.allRows), isEmpty);

      await tester.runAsync(() async {
        stack.connectivity.emitRestored();
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();
      expect(
        find.textContaining('vos PV'),
        findsOneWidget,
        reason: 'consommé : jamais ré-empilé par un passage de synchro suivant',
      );
      expect(await tester.runAsync(stack.allRows), isEmpty);

      // Laisse le SnackBar expirer (aucun Timer en attente à la fin).
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 1));
    });

    test('Caractérisation : à l\'abandon, la fiche n\'est PAS invalidée '
        '(seuls les personnages synchronisés avec succès le sont)', () async {
      // Le coordinateur n'invalide `characterDetailProvider` que pour les
      // ids retournés par `sync()` (succès). Un abandon ne l'invalide pas :
      // la fiche affichée garde l'état optimiste jusqu'à sa prochaine
      // lecture. Documenté tel quel, à réévaluer en tranche T1.
      stack.connectivity.goOffline();
      await stack.repository.updateHp(
        characterId: _characterId,
        currentHp: 6,
        temporaryHp: 0,
      );
      stack.connectivity.goOnline();
      stack.server.rejectWith('42501');
      final repository = _CountingRepository();
      final container = ProviderContainer(
        overrides: overrides(GlobalKey<ScaffoldMessengerState>(), repository),
      );
      addTearDown(container.dispose);
      container.listen(
        characterDetailProvider(_characterId),
        (previous, next) {},
        fireImmediately: true,
      );
      await pumpEventQueue();
      expect(repository.fetchCount, 1);

      container.read(characterWriteSyncCoordinatorProvider);
      for (var i = 0; i < 6; i++) {
        stack.connectivity.emitRestored();
        await pumpEventQueue();
      }
      expect((await stack.allRows()).single.abandoned, isTrue);
      expect(repository.fetchCount, 1, reason: 'aucune invalidation');

      // En revanche un succès invalide bien la fiche.
      stack.connectivity.goOffline();
      await stack.repository.updateHp(
        characterId: _characterId,
        currentHp: 5,
        temporaryHp: 0,
      );
      stack.connectivity.goOnline();
      stack.server.clearRejection();
      await pumpEventQueue();
      expect(repository.fetchCount, 2);
    });
  });

  group('isolation par compte (ownerId)', () {
    test(
      'la file du compte A n\'est jamais rejouée sous le compte B',
      () async {
        stack.connectivity.goOffline();
        await stack.repository.updateHp(
          characterId: _characterId,
          currentHp: 2,
          temporaryHp: 0,
        );
        stack.connectivity.goOnline();

        // Changement de compte : même base locale, même serveur, autre session.
        final clientB = await buildSignedInClient(
          stack.server,
          ownerId: _ownerB,
        );
        final repositoryB = SupabaseCharacterRepository(
          clientB,
          stack.cache,
          stack.queue,
          stack.connectivity,
        );
        final syncerB = PendingCharacterWriteSyncer(
          clientB,
          stack.queue,
          stack.cache,
          repositoryB,
        );

        expect(await syncerB.sync(), isEmpty);
        expect(stack.server.requests, isEmpty, reason: 'aucune requête de B');
        expect(await stack.pendingCount(_ownerA), 1, reason: 'intacte');
        expect(await stack.pendingCount(_ownerB), 0);

        // Retour sous A : elle part bien, et sous le bon propriétaire.
        expect(await stack.syncer.sync(), {_characterId});
        expect(stack.server.characterRow['current_hp'], 2);
      },
    );

    test('le compte B ne rejoue que ses propres entrées', () async {
      await stack.db
          .into(stack.db.pendingCharacterWrites)
          .insert(
            PendingCharacterWritesCompanion.insert(
              characterId: 'char-b',
              ownerId: _ownerB,
              kind: 'xp',
              payload: jsonEncode({'newXp': 900}),
              queuedAt: DateTime.utc(2026, 11, 10),
            ),
          );
      stack.connectivity.goOffline();
      await stack.repository.addXp(characterId: _characterId, newXp: 200);

      final clientB = await buildSignedInClient(stack.server, ownerId: _ownerB);
      final syncerB = PendingCharacterWriteSyncer(
        clientB,
        stack.queue,
        stack.cache,
        SupabaseCharacterRepository(
          clientB,
          stack.cache,
          stack.queue,
          stack.connectivity,
        ),
      );

      expect(await syncerB.sync(), {'char-b'});
      expect(stack.server.appliedWrites.map((w) => w.body), [
        {'xp': 900},
      ]);
      expect(await stack.pendingCount(_ownerA), 1);
    });
  });

  group('purge de la file (D31)', () {
    Future<void> seedOtherOwnerRow() => stack.db
        .into(stack.db.pendingCharacterWrites)
        .insert(
          PendingCharacterWritesCompanion.insert(
            characterId: 'char-b',
            ownerId: _ownerB,
            kind: 'xp',
            payload: jsonEncode({'newXp': 1}),
            queuedAt: DateTime.utc(2026, 11, 10),
          ),
        );

    Future<void> seedAbandonedRowOfA() => stack.db
        .into(stack.db.pendingCharacterWrites)
        .insert(
          PendingCharacterWritesCompanion.insert(
            characterId: _characterId,
            ownerId: _ownerA,
            kind: 'hp',
            payload: jsonEncode({'currentHp': 1, 'temporaryHp': 0}),
            queuedAt: DateTime.utc(2026, 11, 10),
            failureCount: const Value(5),
            abandoned: const Value(true),
            lastFailureMessage: const Value('abandonnée'),
          ),
        );

    SupabaseAuthRepository authRepository() => SupabaseAuthRepository(
      stack.client,
      pendingWriteQueue: stack.queue,
      referenceDataCache: stack.cache,
      syncPendingWrites: () async {
        await stack.syncer.sync();
      },
    );

    test('signOut avec une écriture encore en attente (refus serveur) : '
        'bloqué, file intacte', () async {
      stack.connectivity.goOffline();
      await stack.repository.updateHp(
        characterId: _characterId,
        currentHp: 2,
        temporaryHp: 0,
      );
      stack.connectivity.goOnline();
      stack.server.rejectWith('PGRST000');

      await expectLater(
        authRepository().signOut(),
        throwsA(isA<AuthFailure>()),
      );
      expect(await stack.pendingCount(), 1);
    });

    test('signOut : purge toute la file du compte courant (y compris les '
        'entrées abandonnées), jamais celle d\'un autre compte', () async {
      await seedAbandonedRowOfA();
      await seedOtherOwnerRow();

      await authRepository().signOut();

      final rows = await stack.allRows();
      expect(rows.map((r) => r.ownerId), [_ownerB]);
    });

    test('signOut après synchro réussie : file vide', () async {
      stack.connectivity.goOffline();
      await stack.repository.updateHp(
        characterId: _characterId,
        currentHp: 2,
        temporaryHp: 0,
      );
      stack.connectivity.goOnline();

      await authRepository().signOut();

      expect(stack.server.characterRow['current_hp'], 2);
      expect(await stack.allRows(), isEmpty);
    });

    test('deleteAccount : purge la file du compte supprimé, pas celle d\'un '
        'autre compte', () async {
      await seedAbandonedRowOfA();
      await seedOtherOwnerRow();

      await authRepository().deleteAccount();

      final rows = await stack.allRows();
      expect(rows.map((r) => r.ownerId), [_ownerB]);
    });
  });

  group('Caractérisation des défauts connus (à inverser en tranche T1)', () {
    test('D184 : une exception réseau non-Timeout pendant castSpell '
        '(SocketException) n\'est PAS mise en file : CharacterFailure levée '
        '(l\'écran rétablit alors l\'affichage d\'avant)', () async {
      // À INVERSER EN TRANCHE T1 : le comportement voulu est une mise en
      // file (`WriteOutcome.queued`) sans revert. `castSpell` n'attrape que
      // `TimeoutException` ; tout autre échec de transport tombe dans le
      // `catch` générique -> `mapUnknownCharacterError()`. Le revert de
      // l'affichage vient de l'écran, sur `on CharacterFailure` (voir
      // `character_detail_screen.dart::_castSpell`, couvert par
      // `character_detail_screen_test.dart`).
      stack.server.failBefore(1);

      // Connectivité déclarée active (hasConnection() vrai) mais la requête
      // d'écriture n'aboutit pas : la lecture `characters` préalable passe,
      // l'écriture du slot échoue.
      await expectLater(
        stack.repository.castSpell(
          characterId: _characterId,
          slotLevel: 1,
          slotsUsed: 1,
        ),
        throwsA(isA<CharacterFailure>()),
      );

      expect(await stack.pendingCount(), 0, reason: 'rien en file (D184)');
      expect(stack.server.appliedWrites, isEmpty);
    });

    test('D184 (variante réponse perdue) : le sort EST appliqué côté serveur '
        'mais l\'app croit à un échec et ne met rien en file', () async {
      // À INVERSER EN TRANCHE T1 (même défaut, cas critique : l'effet est
      // appliqué, l'affichage revient pourtant à l'état d'avant).
      stack.server.failAfterApply(1);

      await expectLater(
        stack.repository.castSpell(
          characterId: _characterId,
          slotLevel: 1,
          slotsUsed: 1,
        ),
        throwsA(isA<CharacterFailure>()),
      );

      expect(stack.server.appliedWrites, hasLength(1));
      expect(await stack.pendingCount(), 0);
    });

    test('F19/D178 : un PV absolu en file écrase une valeur modifiée entre '
        'temps par un autre client (serveur à 2, file à 5 -> 5)', () async {
      // À INVERSER EN TRANCHE T1 : la file stocke une valeur absolue sans
      // base de comparaison ; le rejeu écrase le changement concurrent au
      // lieu de le détecter/fusionner.
      stack.connectivity.goOffline();
      await stack.repository.updateHp(
        characterId: _characterId,
        currentHp: 5,
        temporaryHp: 0,
      );
      stack.server.concurrentChange({'current_hp': 2});
      stack.connectivity.goOnline();

      expect(stack.server.characterRow['current_hp'], 2);
      expect(await stack.syncer.sync(), {_characterId});

      expect(stack.server.characterRow['current_hp'], 5);
      expect(stack.server.appliedWrites, hasLength(1));
    });
  });
}

/// Double minimal : seule la lecture de la fiche est exercée (compte les
/// appels pour détecter une invalidation suivie d'une relecture).
class _CountingRepository implements CharacterRepository {
  int fetchCount = 0;

  @override
  Future<CharacterDetail> fetchCharacterDetail(String characterId) async {
    fetchCount++;
    throw StateError('fiche factice : seule la relecture est comptée');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
