// T4 (P15) : journal de campagne en file hors ligne (`journalEntry`). Dépôt
// réel + file drift en mémoire + synchroniseur réel + faux serveur PostgREST du
// harnais (`test/support/`, table `character_journal_entries` simulée).

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/cache/app_database.dart'
    hide PendingCharacterWrite;
import 'package:personnages/core/cache/pending_character_write_queue.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/core/cache/sync_alert_store.dart';
import 'package:personnages/core/utils/uuid_v4.dart';
import 'package:personnages/features/characters/data/character_detail_cache.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/data/pending_character_write_syncer.dart';
import 'package:personnages/features/characters/data/sync_alert_recorder.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../support/fake_character_write_server.dart';
import '../../../support/fake_connectivity_checker.dart';

const _characterId = 'char-1';
const _ownerA = 'owner-1';
const _ownerB = 'owner-2';
const _serverEntry1 = '11111111-1111-4111-8111-111111111111';
const _serverEntry2 = '22222222-2222-4222-8222-222222222222';
const _table = 'character_journal_entries';

Map<String, dynamic> _entryRow(String id, String body, String createdAt) => {
  'id': id,
  'character_id': _characterId,
  'body': body,
  'created_at': createdAt,
};

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
  late List<Map<String, dynamic>> journalRows;

  setUp(() async {
    clock = DateTime.utc(2026, 11, 10, 12);
    db = AppDatabase(NativeDatabase.memory());
    queue = PendingCharacterWriteQueue(db, now: () => clock);
    cache = ReferenceDataCache(db);
    connectivity = FakeConnectivityChecker();
    journalRows = [
      _entryRow(_serverEntry1, 'Séance 1', '2026-01-01T10:00:00+00:00'),
      _entryRow(_serverEntry2, 'Séance 2', '2026-02-01T10:00:00+00:00'),
    ];
    server = FakeCharacterWriteServer(
      characterRow: {
        'id': _characterId,
        'owner_id': _ownerA,
        'name': 'Aria',
        'xp': 100,
        'current_hp': 10,
        'max_hp': 12,
        'temporary_hp': 0,
        'character_classes': [
          {
            'class_id': 3,
            'level': 1,
            'is_primary': true,
            'classes': {
              'saving_throw_proficiencies': ['wis', 'cha'],
              'hit_die': 8,
            },
          },
        ],
        'character_ability_scores': [
          {'ability_id': 'wis', 'score': 10},
        ],
        // Même liste que la table simulée : un POST/PATCH/DELETE est visible à
        // la relecture de la fiche.
        _table: journalRows,
      },
    );
    server.tables[_table] = journalRows;
    client = await buildSignedInClient(server, ownerId: _ownerA);
    repository = SupabaseCharacterRepository(
      client,
      cache,
      queue,
      connectivity,
    );
    syncer = PendingCharacterWriteSyncer(client, queue, cache, repository);
  });

  tearDown(() async {
    await connectivity.close();
    await db.close();
  });

  Future<void> openOnline() async {
    final detail = await repository.fetchCharacterDetail(_characterId);
    expect(detail.journalEntries, hasLength(2));
  }

  void goOffline() {
    connectivity.goOffline();
    server.down = true;
  }

  void goOnline() {
    server.down = false;
    connectivity.goOnline();
  }

  Future<List<PendingCharacterWrite>> lines() async => [
    for (final line in await queue.allForOwner(_ownerA))
      if (line.kind == PendingCharacterWriteKind.journalEntry) line,
  ];

  Future<CharacterDetail> reopen() =>
      repository.fetchCharacterDetail(_characterId);

  List<RecordedRequest> journalWrites() => [
    for (final w in server.writes)
      if (w.table == _table) w,
  ];

  Future<String> addOffline(String body) async {
    goOffline();
    final outcome = await repository.addJournalEntry(
      characterId: _characterId,
      body: body,
    );
    expect(outcome, WriteOutcome.queued);
    return (await lines()).last.targetId;
  }

  // ---------------------------------------------------------------------
  group('dépôt : mise en file', () {
    test('ajout hors ligne : queued, UUID client, une ligne, entrée visible '
        'dans la fiche, aucune écriture réseau', () async {
      await openOnline();

      final id = await addOffline('Nouvelle note');

      expect(isUuid(id), isTrue);
      final line = (await lines()).single;
      expect(line.targetId, id);
      expect(line.payload['body'], 'Nouvelle note');
      expect(DateTime.tryParse(line.payload['createdAt'] as String), isNotNull);
      expect(server.writes, isEmpty);
      final detail = await reopen();
      expect(detail.journalEntries.map((e) => e.id).toList(), [
        id,
        _serverEntry2,
        _serverEntry1,
      ]);
      expect(detail.journalEntries.first.body, 'Nouvelle note');
    });

    test('erreur de transport en ligne : queued', () async {
      server.failBefore(1);

      final outcome = await repository.addJournalEntry(
        characterId: _characterId,
        body: 'Note',
      );

      expect(outcome, WriteOutcome.queued);
      final line = (await lines()).single;
      expect(line.payload['body'], 'Note');
      expect(isUuid(line.targetId), isTrue);
    });

    for (final code in ['42501', '23514']) {
      test('refus $code : échec, rien en file', () async {
        server.rejectWith(code);

        await expectLater(
          repository.addJournalEntry(characterId: _characterId, body: 'Note'),
          throwsA(isA<CharacterFailure>()),
        );
        await expectLater(
          repository.updateJournalEntry(
            characterId: _characterId,
            entryId: _serverEntry1,
            body: 'Modifiée',
          ),
          throwsA(isA<CharacterFailure>()),
        );
        await expectLater(
          repository.removeJournalEntry(
            characterId: _characterId,
            entryId: _serverEntry1,
          ),
          throwsA(isA<CharacterFailure>()),
        );
        expect(await queue.allForOwner(_ownerA), isEmpty);
      });
    }

    test('texte vide ou blanc : refusé, rien en file ni en réseau', () async {
      goOffline();

      for (final body in ['', '   \n']) {
        await expectLater(
          repository.addJournalEntry(characterId: _characterId, body: body),
          throwsA(isA<CharacterFailure>()),
        );
        await expectLater(
          repository.updateJournalEntry(
            characterId: _characterId,
            entryId: _serverEntry1,
            body: body,
          ),
          throwsA(isA<CharacterFailure>()),
        );
      }
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });

    test('ajout puis modification hors ligne : une seule ligne, reste un '
        'ajout au contenu final, même date de création', () async {
      final id = await addOffline('Brouillon');
      final createdAt = (await lines()).single.payload['createdAt'];
      clock = clock.add(const Duration(seconds: 5));

      final outcome = await repository.updateJournalEntry(
        characterId: _characterId,
        entryId: id,
        body: 'Version finale',
      );

      expect(outcome, WriteOutcome.queued);
      final line = (await lines()).single;
      expect(line.targetId, id);
      expect(line.payload, {'body': 'Version finale', 'createdAt': createdAt});
    });

    test('ajout puis suppression hors ligne : ligne retirée, file vide, '
        'aucune écriture au retour du réseau', () async {
      final id = await addOffline('Éphémère');

      final outcome = await repository.removeJournalEntry(
        characterId: _characterId,
        entryId: id,
      );

      expect(outcome, WriteOutcome.queued);
      expect(await queue.allForOwner(_ownerA), isEmpty);
      goOnline();
      expect(await syncer.sync(), isEmpty);
      expect(server.writes, isEmpty);
      expect(journalRows, hasLength(2));
    });

    test('suppression d\'une entrée serveur hors ligne : tombstone', () async {
      goOffline();

      final outcome = await repository.removeJournalEntry(
        characterId: _characterId,
        entryId: _serverEntry1,
      );

      expect(outcome, WriteOutcome.queued);
      final line = (await lines()).single;
      expect(line.targetId, _serverEntry1);
      expect(line.payload, {'deleted': true});
    });

    test('modification puis suppression d\'une entrée serveur : tombstone '
        'unique', () async {
      goOffline();
      await repository.updateJournalEntry(
        characterId: _characterId,
        entryId: _serverEntry1,
        body: 'Modifiée',
      );
      expect((await lines()).single.payload, {'body': 'Modifiée'});
      clock = clock.add(const Duration(seconds: 5));

      await repository.removeJournalEntry(
        characterId: _characterId,
        entryId: _serverEntry1,
      );

      expect((await lines()).single.payload, {'deleted': true});
    });

    test('modifier une entrée déjà supprimée en file : échec, tombstone '
        'intact', () async {
      goOffline();
      await repository.removeJournalEntry(
        characterId: _characterId,
        entryId: _serverEntry1,
      );

      await expectLater(
        repository.updateJournalEntry(
          characterId: _characterId,
          entryId: _serverEntry1,
          body: 'Trop tard',
        ),
        throwsA(isA<CharacterFailure>()),
      );
      expect((await lines()).single.payload, {'deleted': true});
    });

    test('en ligne : INSERT avec l\'id client et created_at, cache à jour, '
        'rien en file', () async {
      await openOnline();

      final outcome = await repository.addJournalEntry(
        characterId: _characterId,
        body: 'En ligne',
      );

      expect(outcome, WriteOutcome.synced);
      final post = journalWrites().single;
      expect(post.method, 'POST');
      final body = post.body! as Map;
      expect(isUuid(body['id'] as String), isTrue);
      expect(body['character_id'], _characterId);
      expect(body['body'], 'En ligne');
      expect(body['created_at'], isNotNull);
      expect(await queue.allForOwner(_ownerA), isEmpty);
      final payload = await cache.get(
        CharacterDetailCache.keyFor(
          ownerId: _ownerA,
          characterId: _characterId,
        ),
      );
      final cached = ((payload! as Map)['row'] as Map)[_table] as List;
      expect(cached.map((e) => (e as Map)['id']), contains(body['id']));
    });

    test('en ligne : modification filtrée id + character_id, suppression '
        'filtrée, cache mis à jour', () async {
      await openOnline();

      await repository.updateJournalEntry(
        characterId: _characterId,
        entryId: _serverEntry1,
        body: 'Modifiée',
      );
      await repository.removeJournalEntry(
        characterId: _characterId,
        entryId: _serverEntry2,
      );

      final patch = journalWrites().first;
      expect(patch.method, 'PATCH');
      expect(patch.query['id'], 'eq.$_serverEntry1');
      expect(patch.query['character_id'], 'eq.$_characterId');
      final delete = journalWrites().last;
      expect(delete.method, 'DELETE');
      expect(delete.query['id'], 'eq.$_serverEntry2');
      expect(delete.query['character_id'], 'eq.$_characterId');
      expect(journalRows.map((r) => r['body']), ['Modifiée']);
      goOffline();
      final detail = await reopen();
      expect(detail.journalEntries.map((e) => e.body), ['Modifiée']);
    });

    test('en ligne : modifier une entrée absente du serveur (zéro ligne) : '
        'accessDenied, rien en file', () async {
      await expectLater(
        repository.updateJournalEntry(
          characterId: _characterId,
          entryId: '33333333-3333-4333-8333-333333333333',
          body: 'Fantôme',
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

    test('en ligne avec un ajout resté en file : modification = un seul '
        'INSERT au contenu final, ligne retirée', () async {
      final id = await addOffline('Brouillon');
      goOnline();

      final outcome = await repository.updateJournalEntry(
        characterId: _characterId,
        entryId: id,
        body: 'Final',
      );

      expect(outcome, WriteOutcome.synced);
      final post = journalWrites().single;
      expect(post.method, 'POST');
      expect((post.body! as Map)['id'], id);
      expect((post.body! as Map)['body'], 'Final');
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });

    test('en ligne : une ligne remise en file pendant l\'écriture n\'est pas '
        'retirée (removeIfUnchanged)', () async {
      goOffline();
      await repository.updateJournalEntry(
        characterId: _characterId,
        entryId: _serverEntry1,
        body: 'Hors ligne',
      );
      goOnline();
      server.onWriteApplied = (_) async {
        clock = clock.add(const Duration(seconds: 5));
        await queue.enqueue(
          characterId: _characterId,
          ownerId: _ownerA,
          kind: PendingCharacterWriteKind.journalEntry,
          targetId: _serverEntry1,
          payload: {'body': 'Plus récent'},
        );
      };

      await repository.updateJournalEntry(
        characterId: _characterId,
        entryId: _serverEntry1,
        body: 'En ligne',
      );

      expect((await lines()).single.payload, {'body': 'Plus récent'});
    });
  });

  // ---------------------------------------------------------------------
  group('rejeu', () {
    test('ajout + modification puis retour réseau : un seul INSERT au '
        'contenu final, ligne retirée, cache à jour', () async {
      await openOnline();
      final id = await addOffline('Brouillon');
      await repository.updateJournalEntry(
        characterId: _characterId,
        entryId: id,
        body: 'Final',
      );
      goOnline();

      expect(await syncer.sync(), {_characterId});

      final post = journalWrites().single;
      expect(post.method, 'POST');
      expect((post.body! as Map)['id'], id);
      expect((post.body! as Map)['body'], 'Final');
      expect((post.body! as Map)['character_id'], _characterId);
      expect(journalRows.where((r) => r['id'] == id), hasLength(1));
      expect(await queue.allForOwner(_ownerA), isEmpty);
      goOffline();
      expect((await reopen()).journalEntries.first.body, 'Final');
    });

    test('modification : UPDATE filtré id + character_id', () async {
      goOffline();
      await repository.updateJournalEntry(
        characterId: _characterId,
        entryId: _serverEntry1,
        body: 'Modifiée',
      );
      goOnline();

      expect(await syncer.sync(), {_characterId});

      final patch = journalWrites().single;
      expect(patch.method, 'PATCH');
      expect(patch.body, {'body': 'Modifiée'});
      expect(patch.query['id'], 'eq.$_serverEntry1');
      expect(patch.query['character_id'], 'eq.$_characterId');
      expect(journalRows.first['body'], 'Modifiée');
    });

    test('suppression : DELETE filtré ; entrée déjà supprimée ailleurs '
        '(zéro ligne) = succès', () async {
      goOffline();
      await repository.removeJournalEntry(
        characterId: _characterId,
        entryId: _serverEntry1,
      );
      await repository.removeJournalEntry(
        characterId: _characterId,
        entryId: _serverEntry2,
      );
      journalRows.removeWhere((r) => r['id'] == _serverEntry2);
      goOnline();

      expect(await syncer.sync(), {_characterId});

      final deletes = journalWrites();
      expect(deletes, hasLength(2));
      expect(deletes.first.query['character_id'], 'eq.$_characterId');
      expect(journalRows, isEmpty);
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });

    test('idempotent : réponse perdue après l\'INSERT, le rejeu reçoit 23505 '
        '= succès, même UUID, pas de doublon, texte réaligné', () async {
      final id = await addOffline('Note');
      goOnline();
      server.failAfterApply(1);

      expect(await syncer.sync(), isEmpty);
      expect(journalRows.where((r) => r['id'] == id), hasLength(1));
      expect(await lines(), hasLength(1));

      // Modification entre-temps : l'ajout en attente est mis à jour.
      clock = clock.add(const Duration(seconds: 5));
      await repository.updateJournalEntry(
        characterId: _characterId,
        entryId: id,
        body: 'Note corrigée',
      );
      // La ligne reste un ajout et la modification en ligne passe par un
      // INSERT (23505) puis un UPDATE.
      expect(await queue.allForOwner(_ownerA), isEmpty);
      expect(journalRows.where((r) => r['id'] == id), hasLength(1));
      expect(
        journalRows.singleWhere((r) => r['id'] == id)['body'],
        'Note corrigée',
      );
    });

    test('idempotent : rejeu d\'un ajout déjà présent (23505) = succès, '
        'aucun doublon', () async {
      final id = await addOffline('Note');
      goOnline();
      server.failAfterApply(1);
      expect(await syncer.sync(), isEmpty);

      expect(await syncer.sync(), {_characterId});

      expect(journalRows.where((r) => r['id'] == id), hasLength(1));
      expect(await queue.allForOwner(_ownerA), isEmpty);
      final posts = server.requests.where(
        (r) => r.method == 'POST' && r.table == _table,
      );
      expect(posts, hasLength(2));
      expect(posts.map((r) => r.applied), [true, false]);
    });

    test('modification d\'une entrée supprimée ailleurs : zéro ligne, '
        'abandon au seuil puis alerte persistée « journal »', () async {
      goOffline();
      await repository.updateJournalEntry(
        characterId: _characterId,
        entryId: _serverEntry1,
        body: 'Modifiée',
      );
      journalRows.removeWhere((r) => r['id'] == _serverEntry1);
      goOnline();

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
      expect(consumed.single.kindKey, 'journal_entry');
      expect(consumed.single.message, contains('votre journal'));
    });

    test('refus RLS au rejeu (42501) : compté, pas de doublon', () async {
      final id = await addOffline('Note');
      goOnline();
      server.rejectWith('42501');

      final report = await syncer.syncWithReport();

      expect(report.synced, isEmpty);
      expect((await lines()).single.targetId, id);
      expect(journalRows, hasLength(2));
    });

    const validId = '44444444-4444-4444-8444-444444444444';
    for (final bad in <(String, Map<String, dynamic>)>[
      (validId, {}),
      (validId, {'body': ''}),
      (validId, {'body': '   '}),
      (validId, {'body': 5}),
      (validId, {'body': null}),
      (validId, {'deleted': false}),
      (validId, {'deleted': 'oui'}),
      (validId, {'body': 'x', 'createdAt': 'pas une date'}),
      (validId, {'body': 'x', 'createdAt': 3}),
      ('pas-un-uuid', {'body': 'x', 'createdAt': '2026-11-10T12:00:00Z'}),
      ('', {'deleted': true}),
    ]) {
      test('payload invalide $bad : aucune écriture, ligne supprimée, '
          'compteur à 0, les autres lignes sont rejouées', () async {
        await queue.enqueue(
          characterId: _characterId,
          ownerId: _ownerA,
          kind: PendingCharacterWriteKind.journalEntry,
          targetId: bad.$1,
          payload: bad.$2,
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
        expect(journalWrites(), isEmpty);
        expect(journalRows, hasLength(2));
      });
    }

    test('ordre de rejeu : l\'ajout (plus ancien) part avant la modification '
        'd\'une autre entrée', () async {
      final id = await addOffline('Ajout');
      clock = clock.add(const Duration(seconds: 5));
      await repository.updateJournalEntry(
        characterId: _characterId,
        entryId: _serverEntry1,
        body: 'Modifiée',
      );
      goOnline();

      expect(await syncer.sync(), {_characterId});

      expect(journalWrites().map((w) => w.method).toList(), ['POST', 'PATCH']);
      expect((journalWrites().first.body! as Map)['id'], id);
    });

    test('isolation par ownerId : le rejeu d\'un compte ne touche jamais la '
        'file d\'un autre', () async {
      await queue.enqueue(
        characterId: 'char-autre',
        ownerId: _ownerB,
        kind: PendingCharacterWriteKind.journalEntry,
        targetId: '55555555-5555-4555-8555-555555555555',
        payload: {'deleted': true},
      );
      goOffline();
      await repository.removeJournalEntry(
        characterId: _characterId,
        entryId: _serverEntry1,
      );
      goOnline();

      expect(await syncer.sync(), {_characterId});

      expect(await queue.allForOwner(_ownerB), hasLength(1));
      expect(journalWrites(), hasLength(1));
    });

    test('purge (déconnexion / suppression de compte) : removeAllForOwner '
        'retire le kind journalEntry, pas celui d\'un autre compte', () async {
      goOffline();
      await repository.removeJournalEntry(
        characterId: _characterId,
        entryId: _serverEntry1,
      );
      await queue.enqueue(
        characterId: 'char-autre',
        ownerId: _ownerB,
        kind: PendingCharacterWriteKind.journalEntry,
        targetId: '55555555-5555-4555-8555-555555555555',
        payload: {'deleted': true},
      );

      await queue.removeAllForOwner(_ownerA);

      expect(await queue.allForOwner(_ownerA), isEmpty);
      expect(await queue.allForOwner(_ownerB), hasLength(1));
    });
  });

  // ---------------------------------------------------------------------
  group('superposition de la fiche relue', () {
    test('ajouts triés par date, modifications appliquées, tombstones '
        'masquent, entrées serveur intactes', () async {
      await openOnline();
      goOffline();
      final id = await addOffline('Ajout local');
      await repository.updateJournalEntry(
        characterId: _characterId,
        entryId: _serverEntry1,
        body: 'Séance 1 corrigée',
      );
      await repository.removeJournalEntry(
        characterId: _characterId,
        entryId: _serverEntry2,
      );

      final detail = await reopen();

      expect(detail.journalEntries.map((e) => (e.id, e.body)).toList(), [
        (id, 'Ajout local'),
        (_serverEntry1, 'Séance 1 corrigée'),
      ]);
      expect(
        detail.journalEntries.last.createdAt,
        DateTime.utc(2026, 1, 1, 10),
        reason: 'la date de création serveur est conservée',
      );
    });

    test('payload invalide en file : ignoré par la superposition', () async {
      await openOnline();
      await queue.enqueue(
        characterId: _characterId,
        ownerId: _ownerA,
        kind: PendingCharacterWriteKind.journalEntry,
        targetId: _serverEntry1,
        payload: {'deleted': 'oui'},
      );
      goOffline();

      final detail = await reopen();

      expect(detail.journalEntries, hasLength(2));
    });
  });
}
