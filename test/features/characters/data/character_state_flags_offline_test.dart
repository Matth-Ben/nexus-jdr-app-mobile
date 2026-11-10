// T5a (P15) : réglages d'état absolus en file hors ligne — sorts préparés/
// favoris (`spellState`), objets équipés/harmonisés (`inventoryState`),
// inspiration et bonus de CA (`characterFlags`). Dépôt réel + file drift en
// mémoire + synchroniseur réel + faux serveur PostgREST du harnais
// (`test/support/`, tables enfants simulées).

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/cache/app_database.dart'
    hide PendingCharacterWrite;
import 'package:personnages/core/cache/pending_character_write_queue.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/core/cache/sync_alert_store.dart';
import 'package:personnages/core/rules/spell_status.dart';
import 'package:personnages/features/characters/data/character_detail_cache.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/data/pending_character_write_syncer.dart';
import 'package:personnages/features/characters/data/sync_alert_recorder.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/weapon_slot.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../support/fake_character_write_server.dart';
import '../../../support/fake_connectivity_checker.dart';

const _characterId = 'char-1';
const _ownerA = 'owner-1';
const _ownerB = 'owner-2';

Map<String, dynamic> _spellRow(int id, String status) => {
  'id': 'cs-$id',
  'character_id': _characterId,
  'spell_id': id,
  'status': status,
  'is_favorite': false,
  'source_class_id': 3,
  'innate_uses_spent': 0,
};

Map<String, dynamic> _itemRow(
  String id, {
  bool equipped = false,
  bool attuned = false,
  String? weaponSlot,
}) => {
  'id': id,
  'character_id': _characterId,
  'item_id': null,
  'custom_name': 'Objet $id',
  'quantity': 1,
  'equipped': equipped,
  'weapon_slot': weaponSlot,
  'is_attuned': attuned,
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
  late List<Map<String, dynamic>> spellRows;
  late List<Map<String, dynamic>> inventoryRows;

  setUp(() async {
    clock = DateTime.utc(2026, 11, 10, 12);
    db = AppDatabase(NativeDatabase.memory());
    queue = PendingCharacterWriteQueue(db, now: () => clock);
    cache = ReferenceDataCache(db);
    connectivity = FakeConnectivityChecker();
    // Clerc niveau 1, Sagesse 10 : limite de sorts préparés = 1 (RAW,
    // max(1, niveau + mod)).
    spellRows = [
      _spellRow(11, 'connu'),
      _spellRow(12, 'connu'),
      _spellRow(13, 'inné'),
    ];
    inventoryRows = [
      _itemRow('inv-1'),
      _itemRow('inv-2'),
      _itemRow('inv-3'),
      _itemRow('inv-4'),
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
        'inspiration': false,
        'armor_class_bonus': 0,
        'currency_gp': 5,
        'currency_pp': 0,
        'currency_ep': 0,
        'currency_sp': 0,
        'currency_cp': 0,
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
          {'ability_id': 'dex', 'score': 10},
        ],
        // Mêmes objets que les tables simulées : un PATCH est visible à la
        // relecture de la fiche.
        'character_spells': spellRows,
        'character_inventory': inventoryRows,
      },
    );
    server.tables['character_spells'] = spellRows;
    server.tables['character_inventory'] = inventoryRows;
    server.tables['spells'] = [
      for (final id in [11, 12, 13])
        {
          'id': id,
          'level': 1,
          'school': 'Évocation',
          'casting_time': '1 action',
          'range': '9 m',
          'components': <String, dynamic>{},
          'duration': 'Instantanée',
          'concentration': false,
        },
    ];
    // Nom français de la classe (résolu via `translations`).
    server.tables['translations'] = [
      {
        'entity_type': 'class',
        'field_name': 'name',
        'locale': 'fr',
        'entity_id': '3',
        'value': 'Clerc',
      },
    ];
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
    expect(detail.spells.where((s) => s.id == 11), hasLength(1));
  }

  void goOffline() {
    connectivity.goOffline();
    server.down = true;
  }

  void goOnline() {
    server.down = false;
    connectivity.goOnline();
  }

  Future<List<PendingCharacterWrite>> lines(
    PendingCharacterWriteKind kind,
  ) async => [
    for (final line in await queue.allForOwner(_ownerA))
      if (line.kind == kind) line,
  ];

  Future<PendingCharacterWrite> line(
    PendingCharacterWriteKind kind, {
    String targetId = '',
  }) async => (await lines(kind)).singleWhere((l) => l.targetId == targetId);

  Future<List<Map<dynamic, dynamic>>> cachedRelation(String relation) async {
    final payload = await cache.get(
      CharacterDetailCache.keyFor(ownerId: _ownerA, characterId: _characterId),
    );
    final row = (payload! as Map)['row'] as Map;
    return (row[relation] as List).cast<Map<dynamic, dynamic>>();
  }

  Future<CharacterDetail> reopen() =>
      repository.fetchCharacterDetail(_characterId);

  Map<String, dynamic> spell(int id) => spellRows.singleWhere(
    (r) => r['spell_id'] == id && r['character_id'] == _characterId,
  );
  Map<String, dynamic> item(String id) =>
      inventoryRows.singleWhere((r) => r['id'] == id);

  // ---------------------------------------------------------------------
  group('characterFlags (inspiration, bonus de CA)', () {
    test(
      'hors ligne : queued, une ligne, targetId vide, aucun réseau',
      () async {
        connectivity.goOffline();

        expect(
          await repository.setInspiration(
            characterId: _characterId,
            inspiration: true,
          ),
          WriteOutcome.queued,
        );
        expect(
          await repository.setArmorClassBonus(
            characterId: _characterId,
            bonus: -2,
          ),
          WriteOutcome.queued,
        );

        final all = await lines(PendingCharacterWriteKind.characterFlags);
        expect(all, hasLength(1), reason: 'fusion champ par champ, une ligne');
        expect(all.single.targetId, '');
        expect(all.single.payload, {
          'inspiration': true,
          'armorClassBonus': -2,
        });
        expect(server.requests, isEmpty);
      },
    );

    test('erreur de transport en ligne : queued', () async {
      server.failBefore(1);

      final outcome = await repository.setInspiration(
        characterId: _characterId,
        inspiration: true,
      );

      expect(outcome, WriteOutcome.queued);
      expect((await line(PendingCharacterWriteKind.characterFlags)).payload, {
        'inspiration': true,
      });
    });

    test('refus 42501 : échec, rien en file', () async {
      server.rejectWith('42501');

      await expectLater(
        repository.setArmorClassBonus(characterId: _characterId, bonus: 2),
        throwsA(isA<CharacterFailure>()),
      );
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });

    test('zéro ligne affectée : accessDenied, rien en file', () async {
      server.concurrentChange({'owner_id': 'autre'});

      await expectLater(
        repository.setInspiration(characterId: _characterId, inspiration: true),
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

    test(
      'deux changements du même réglage : la dernière valeur gagne',
      () async {
        connectivity.goOffline();
        await repository.setInspiration(
          characterId: _characterId,
          inspiration: true,
        );
        clock = clock.add(const Duration(seconds: 5));
        await repository.setInspiration(
          characterId: _characterId,
          inspiration: false,
        );

        expect((await line(PendingCharacterWriteKind.characterFlags)).payload, {
          'inspiration': false,
        });
      },
    );

    for (final bonus in [100, -100, 2147483647]) {
      test(
        'bonus de CA $bonus : accepté hors ligne et rejoué tel quel',
        () async {
          connectivity.goOffline();
          expect(
            await repository.setArmorClassBonus(
              characterId: _characterId,
              bonus: bonus,
            ),
            WriteOutcome.queued,
          );
          goOnline();

          expect(await syncer.sync(), {_characterId});

          expect(server.characterRow['armor_class_bonus'], bonus);
          expect(await queue.allForOwner(_ownerA), isEmpty);
        },
      );
    }

    test('bonus de CA hors plage integer : refusé à l’enfilage, rien en '
        'file', () async {
      for (final offline in [true, false]) {
        if (offline) connectivity.goOffline();
        await expectLater(
          repository.setArmorClassBonus(
            characterId: _characterId,
            bonus: 2147483648,
          ),
          throwsA(isA<CharacterFailure>()),
        );
      }
      expect(await queue.allForOwner(_ownerA), isEmpty);
      expect(server.writes, isEmpty);
    });

    test('en ligne : écriture filtrée id + owner_id, cache mis à jour, '
        'entrée périmée fusionnée puis retirée', () async {
      await openOnline();
      connectivity.goOffline();
      await repository.setInspiration(
        characterId: _characterId,
        inspiration: true,
      );
      connectivity.goOnline();

      final outcome = await repository.setArmorClassBonus(
        characterId: _characterId,
        bonus: 2,
      );

      expect(outcome, WriteOutcome.synced);
      final patch = server.appliedWrites.single;
      expect(patch.body, {'inspiration': true, 'armor_class_bonus': 2});
      expect(patch.query['id'], 'eq.$_characterId');
      expect(patch.query['owner_id'], 'eq.$_ownerA');
      expect(await queue.allForOwner(_ownerA), isEmpty);
      final row = await CharacterDetailCache(cache)
          .readRow(ownerId: _ownerA, characterId: _characterId);
      expect(row?['inspiration'], true);
      expect(row?['armor_class_bonus'], 2);
    });

    test('en ligne : une entrée remise en file pendant l\'écriture n\'est '
        'pas retirée', () async {
      connectivity.goOffline();
      await repository.setInspiration(
        characterId: _characterId,
        inspiration: true,
      );
      connectivity.goOnline();
      server.onWriteApplied = (_) async {
        clock = clock.add(const Duration(seconds: 5));
        await queue.enqueue(
          characterId: _characterId,
          ownerId: _ownerA,
          kind: PendingCharacterWriteKind.characterFlags,
          targetId: '',
          payload: {'inspiration': false},
        );
      };

      await repository.setInspiration(
        characterId: _characterId,
        inspiration: true,
      );

      expect((await line(PendingCharacterWriteKind.characterFlags)).payload, {
        'inspiration': false,
      });
    });

    test('superposition : la fiche relue hors ligne affiche l\'état '
        'effectif (inspiration, bonus, CA dérivée)', () async {
      await openOnline();
      final baseAc = (await reopen()).armorClass;
      goOffline();
      await repository.setInspiration(
        characterId: _characterId,
        inspiration: true,
      );
      await repository.setArmorClassBonus(characterId: _characterId, bonus: 3);

      final detail = await reopen();

      expect(detail.inspiration, isTrue);
      expect(detail.armorClassBonus, 3);
      expect(detail.armorClass, baseAc, reason: 'CA de base inchangée');
    });

    test('rejeu : écrit les colonnes absolues filtrées id + owner_id, ligne '
        'retirée, cache mis à jour', () async {
      await openOnline();
      connectivity.goOffline();
      await repository.setInspiration(
        characterId: _characterId,
        inspiration: true,
      );
      await repository.setArmorClassBonus(characterId: _characterId, bonus: 4);
      goOnline();

      expect(await syncer.sync(), {_characterId});

      final patch = server.appliedWrites.single;
      expect(patch.body, {'inspiration': true, 'armor_class_bonus': 4});
      expect(patch.query['id'], 'eq.$_characterId');
      expect(patch.query['owner_id'], 'eq.$_ownerA');
      expect(server.characterRow['armor_class_bonus'], 4);
      expect(await queue.allForOwner(_ownerA), isEmpty);
      final row = await CharacterDetailCache(cache)
          .readRow(ownerId: _ownerA, characterId: _characterId);
      expect(row?['armor_class_bonus'], 4);
    });

    test('rejeu idempotent : réponse perdue, mêmes valeurs absolues '
        'réécrites', () async {
      connectivity.goOffline();
      await repository.setInspiration(
        characterId: _characterId,
        inspiration: true,
      );
      goOnline();
      server.failAfterApply(1);

      expect(await syncer.sync(), isEmpty);
      expect(await queue.allForOwner(_ownerA), hasLength(1));
      expect(await syncer.sync(), {_characterId});

      expect(server.appliedWrites.map((w) => w.body).toList(), [
        {'inspiration': true},
        {'inspiration': true},
      ]);
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });

    test('zéro ligne au rejeu : abandon au seuil puis alerte persistée '
        '(dataKind character_flags)', () async {
      await openOnline();
      connectivity.goOffline();
      await repository.setInspiration(
        characterId: _characterId,
        inspiration: true,
      );
      goOnline();
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
      expect(server.appliedWrites, isEmpty);
      expect(await queue.allForOwner(_ownerA), isEmpty);
      final recorder = SyncAlertRecorder(
        db,
        queue,
        SyncAlertStore(db),
        CharacterDetailCache(cache),
      );
      final consumed = await recorder.recordAbandoned(_ownerA);
      expect(consumed.single.kindKey, 'character_flags');
      expect(consumed.single.message, contains('vos réglages de personnage'));
    });

    for (final bad in <Map<String, dynamic>>[
      {},
      {'inspiration': 'oui'},
      {'inspiration': 1},
      {'armorClassBonus': 2.5},
      {'armorClassBonus': '2'},
      {'armorClassBonus': 2147483648},
      {'armorClassBonus': -2147483649},
      {'inspiration': true, 'armorClassBonus': null},
    ]) {
      test('payload invalide $bad : aucune écriture, ligne supprimée, les '
          'autres lignes rejouées, compteur à 0', () async {
        await queue.enqueue(
          characterId: _characterId,
          ownerId: _ownerA,
          kind: PendingCharacterWriteKind.characterFlags,
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
        expect(server.characterRow['inspiration'], false);
        expect(server.characterRow['armor_class_bonus'], 0);
        expect(
          server.writes.where(
            (w) =>
                (w.body as Map).containsKey('inspiration') ||
                (w.body as Map).containsKey('armor_class_bonus'),
          ),
          isEmpty,
        );
      });
    }

    test('ordre de rejeu : PV puis réglages, chacun écrit une fois', () async {
      connectivity.goOffline();
      await repository.updateHp(
        characterId: _characterId,
        currentHp: 3,
        temporaryHp: 0,
      );
      clock = clock.add(const Duration(seconds: 5));
      await repository.setInspiration(
        characterId: _characterId,
        inspiration: true,
      );
      goOnline();

      expect(await syncer.sync(), {_characterId});

      expect(server.appliedWrites, hasLength(2));
      expect((server.appliedWrites.first.body as Map).keys, [
        'current_hp',
        'temporary_hp',
      ]);
      expect((server.appliedWrites.last.body as Map).keys, ['inspiration']);
    });

    test('isolation par ownerId : le rejeu ne touche jamais la file d\'un '
        'autre compte ; purge par compte', () async {
      await queue.enqueue(
        characterId: 'char-autre',
        ownerId: _ownerB,
        kind: PendingCharacterWriteKind.characterFlags,
        targetId: '',
        payload: {'inspiration': true},
      );
      connectivity.goOffline();
      await repository.setInspiration(
        characterId: _characterId,
        inspiration: true,
      );
      goOnline();

      expect(await syncer.sync(), {_characterId});
      expect(await queue.allForOwner(_ownerB), hasLength(1));
      expect(server.appliedWrites, hasLength(1));

      await queue.removeAllForOwner(_ownerB);
      expect(await queue.allForOwner(_ownerB), isEmpty);
    });

    test('purge : removeAllForOwner retire les trois nouveaux kinds', () async {
      connectivity.goOffline();
      await repository.setInspiration(
        characterId: _characterId,
        inspiration: true,
      );
      await repository.setSpellFavorite(
        characterId: _characterId,
        spellId: 11,
        isFavorite: true,
      );
      await repository.setInventoryItemAttuned(
        characterId: _characterId,
        inventoryId: 'inv-1',
        attuned: true,
      );
      expect(await queue.watchPendingCount(_ownerA).first, 3);

      await queue.removeAllForOwner(_ownerA);

      expect(await queue.allForOwner(_ownerA), isEmpty);
      expect(await queue.watchPendingCount(_ownerA).first, 0);
    });
  });

  // ---------------------------------------------------------------------
  group('spellState (préparé, favori)', () {
    test(
      'hors ligne : queued, ligne par sort, préparé et favori fusionnés',
      () async {
        await openOnline();
        goOffline();

        expect(
          await repository.setSpellPrepared(
            characterId: _characterId,
            spellId: 11,
            prepared: true,
          ),
          WriteOutcome.queued,
        );
        expect(
          await repository.setSpellFavorite(
            characterId: _characterId,
            spellId: 11,
            isFavorite: true,
          ),
          WriteOutcome.queued,
        );

        final l = await line(
          PendingCharacterWriteKind.spellState,
          targetId: '11',
        );
        expect(l.payload, {'prepared': true, 'favorite': true});
        expect(await lines(PendingCharacterWriteKind.spellState), hasLength(1));
        expect(
          server.requests.where((r) => r.isWrite),
          isEmpty,
          reason: 'aucune écriture réseau hors ligne',
        );
      },
    );

    test('erreur de transport en ligne : queued', () async {
      await openOnline();
      server.failBefore(1);

      final outcome = await repository.setSpellFavorite(
        characterId: _characterId,
        spellId: 11,
        isFavorite: true,
      );

      expect(outcome, WriteOutcome.queued);
      expect(
        (await line(
          PendingCharacterWriteKind.spellState,
          targetId: '11',
        )).payload,
        {'favorite': true},
      );
    });

    test('refus 42501 : échec, rien en file', () async {
      await openOnline();
      server.rejectWith('42501');

      await expectLater(
        repository.setSpellFavorite(
          characterId: _characterId,
          spellId: 11,
          isFavorite: true,
        ),
        throwsA(isA<CharacterFailure>()),
      );
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });

    test('zéro ligne affectée en ligne (favori d\'un sort sans ligne) : '
        'accessDenied, rien en file', () async {
      await openOnline();
      spellRows.clear();

      await expectLater(
        repository.setSpellFavorite(
          characterId: _characterId,
          spellId: 11,
          isFavorite: true,
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

    test('même sort : la dernière valeur gagne ; sorts différents : lignes '
        'distinctes', () async {
      await openOnline();
      goOffline();
      await repository.setSpellPrepared(
        characterId: _characterId,
        spellId: 11,
        prepared: true,
      );
      clock = clock.add(const Duration(seconds: 5));
      await repository.setSpellPrepared(
        characterId: _characterId,
        spellId: 11,
        prepared: false,
      );
      await repository.setSpellFavorite(
        characterId: _characterId,
        spellId: 12,
        isFavorite: true,
      );

      expect(
        (await line(
          PendingCharacterWriteKind.spellState,
          targetId: '11',
        )).payload,
        {'prepared': false},
      );
      expect(
        (await line(
          PendingCharacterWriteKind.spellState,
          targetId: '12',
        )).payload,
        {'favorite': true},
      );
    });

    test('quota : plusieurs préparations cumulées hors ligne ne dépassent pas '
        'la limite de la classe (état effectif)', () async {
      await openOnline();
      goOffline();
      expect(
        await repository.setSpellPrepared(
          characterId: _characterId,
          spellId: 11,
          prepared: true,
        ),
        WriteOutcome.queued,
      );

      await expectLater(
        repository.setSpellPrepared(
          characterId: _characterId,
          spellId: 12,
          prepared: true,
        ),
        throwsA(
          isA<CharacterFailure>().having(
            (f) => f.message,
            'message',
            contains('Limite de sorts préparés atteinte'),
          ),
        ),
      );
      expect(await lines(PendingCharacterWriteKind.spellState), hasLength(1));

      // Dé-préparer libère la place : on peut alors préparer l'autre sort.
      await repository.setSpellPrepared(
        characterId: _characterId,
        spellId: 11,
        prepared: false,
      );
      expect(
        await repository.setSpellPrepared(
          characterId: _characterId,
          spellId: 12,
          prepared: true,
        ),
        WriteOutcome.queued,
      );
    });

    test('superposition : état effectif (préparé, favori, décompte)', () async {
      await openOnline();
      goOffline();
      await repository.setSpellPrepared(
        characterId: _characterId,
        spellId: 11,
        prepared: true,
      );
      await repository.setSpellFavorite(
        characterId: _characterId,
        spellId: 12,
        isFavorite: true,
      );

      final detail = await reopen();

      final s11 = detail.spells.singleWhere((s) => s.id == 11);
      final s12 = detail.spells.singleWhere((s) => s.id == 12);
      expect(s11.status, SpellStatus.prepared);
      expect(s12.status, SpellStatus.known);
      expect(s12.isFavorite, isTrue);
      expect(detail.preparedSpellCount, 1);
      expect(detail.preparedSpellsByClass.single.isAtLimit, isTrue);
    });

    test('superposition : un sort inné n\'est jamais modifié par une '
        'préparation en file', () async {
      await queue.enqueue(
        characterId: _characterId,
        ownerId: _ownerA,
        kind: PendingCharacterWriteKind.spellState,
        targetId: '13',
        payload: {'prepared': true},
      );
      await openOnline();

      final detail = await reopen();

      expect(
        detail.spells.singleWhere((s) => s.id == 13).status,
        SpellStatus.innate,
      );
    });

    test('en ligne : écriture filtrée, cache mis à jour, entrée périmée '
        'fusionnée puis retirée', () async {
      await openOnline();
      connectivity.goOffline();
      await repository.setSpellFavorite(
        characterId: _characterId,
        spellId: 11,
        isFavorite: true,
      );
      connectivity.goOnline();

      final outcome = await repository.setSpellPrepared(
        characterId: _characterId,
        spellId: 11,
        prepared: true,
      );

      expect(outcome, WriteOutcome.synced);
      expect(spell(11)['status'], 'préparé');
      expect(spell(11)['is_favorite'], true, reason: 'favori fusionné');
      expect(await queue.allForOwner(_ownerA), isEmpty);
      final cachedRows = await cachedRelation('character_spells');
      final cached11 = cachedRows.singleWhere((r) => r['spell_id'] == 11);
      expect(cached11['status'], 'préparé');
      expect(cached11['is_favorite'], true);
    });

    test('rejeu : écrit le statut/favori filtrés par sort ET personnage, '
        'jamais une ligne inné, ligne retirée, cache mis à jour', () async {
      await openOnline();
      goOffline();
      await repository.setSpellPrepared(
        characterId: _characterId,
        spellId: 11,
        prepared: true,
      );
      await repository.setSpellFavorite(
        characterId: _characterId,
        spellId: 11,
        isFavorite: true,
      );
      goOnline();

      expect(await syncer.sync(), {_characterId});

      expect(spell(11)['status'], 'préparé');
      expect(spell(11)['is_favorite'], true);
      expect(spell(12)['status'], 'connu');
      expect(spell(13)['status'], 'inné');
      final statusPatch = server.appliedWrites.firstWhere(
        (w) => w.table == 'character_spells',
      );
      expect(statusPatch.query['character_id'], 'eq.$_characterId');
      expect(statusPatch.query['spell_id'], 'eq.11');
      expect(statusPatch.query['status'], 'neq.inné');
      expect(await queue.allForOwner(_ownerA), isEmpty);
      final cachedRows = await cachedRelation('character_spells');
      expect(
        cachedRows.singleWhere((r) => r['spell_id'] == 11)['status'],
        'préparé',
      );
    });

    test('rejeu favori : filtré par personnage, la ligne du même sort '
        'd’un autre personnage n’est jamais touchée', () async {
      await openOnline();
      final foreign = {
        ..._spellRow(11, 'connu'),
        'id': 'cs-autre',
        'character_id': 'char-autre',
      };
      spellRows.add(foreign);
      goOffline();
      await repository.setSpellFavorite(
        characterId: _characterId,
        spellId: 11,
        isFavorite: true,
      );
      goOnline();

      expect(await syncer.sync(), {_characterId});

      expect(foreign['is_favorite'], false);
      expect(spell(11)['is_favorite'], true);
      final patch = server.appliedWrites.single;
      expect(patch.query['character_id'], 'eq.$_characterId');
      expect(patch.query['spell_id'], 'eq.11');
    });

    test('contraste : dé-préparer un sort sans aucune ligne est un succès '
        'sans écriture (favori sans ligne = refus, voir plus haut)', () async {
      await openOnline();
      spellRows.clear();
      goOffline();
      expect(
        await repository.setSpellPrepared(
          characterId: _characterId,
          spellId: 11,
          prepared: false,
        ),
        WriteOutcome.queued,
      );
      goOnline();

      expect(await syncer.sync(), {_characterId});

      expect(await queue.allForOwner(_ownerA), isEmpty);
      expect(server.appliedWrites, isEmpty);
    });

    test('rejeu : préparer un sort sans aucune ligne la crée', () async {
      await openOnline();
      spellRows.removeWhere((r) => r['spell_id'] == 12);
      goOffline();
      await queue.enqueue(
        characterId: _characterId,
        ownerId: _ownerA,
        kind: PendingCharacterWriteKind.spellState,
        targetId: '12',
        payload: {'prepared': true},
      );
      goOnline();

      expect(await syncer.sync(), {_characterId});

      final created = spellRows.singleWhere((r) => r['spell_id'] == 12);
      expect(created['status'], 'préparé');
      expect(created['character_id'], _characterId);
    });

    test(
      'rejeu idempotent : réponse perdue, mêmes valeurs réécrites',
      () async {
        await openOnline();
        goOffline();
        await repository.setSpellFavorite(
          characterId: _characterId,
          spellId: 11,
          isFavorite: true,
        );
        goOnline();
        server.failAfterApply(1);

        expect(await syncer.sync(), isEmpty);
        expect(await queue.allForOwner(_ownerA), hasLength(1));
        expect(await syncer.sync(), {_characterId});

        expect(spell(11)['is_favorite'], true);
        expect(
          server.appliedWrites.where((w) => w.table == 'character_spells'),
          hasLength(2),
        );
        expect(await queue.allForOwner(_ownerA), isEmpty);
      },
    );

    test('zéro ligne au rejeu (sort disparu) : abandon au seuil puis alerte '
        'persistée', () async {
      await openOnline();
      goOffline();
      await repository.setSpellFavorite(
        characterId: _characterId,
        spellId: 11,
        isFavorite: true,
      );
      goOnline();
      spellRows.clear();

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
      final recorder = SyncAlertRecorder(
        db,
        queue,
        SyncAlertStore(db),
        CharacterDetailCache(cache),
      );
      final consumed = await recorder.recordAbandoned(_ownerA);
      expect(consumed.single.kindKey, 'spell_state');
      expect(consumed.single.targetId, '11');
    });

    for (final bad in <({String target, Map<String, dynamic> payload})>[
      (target: '11', payload: {}),
      (target: '11', payload: {'prepared': 'oui'}),
      (target: '11', payload: {'favorite': 1}),
      (target: '11', payload: {'prepared': true, 'favorite': null}),
      (target: '', payload: {'prepared': true}),
      (target: 'abc', payload: {'prepared': true}),
      (target: '0', payload: {'prepared': true}),
      (target: '-4', payload: {'prepared': true}),
      (target: '011', payload: {'prepared': true}),
    ]) {
      test('payload/cible invalide ($bad) : aucune écriture, ligne supprimée, '
          'autres lignes rejouées, compteur à 0', () async {
        await queue.enqueue(
          characterId: _characterId,
          ownerId: _ownerA,
          kind: PendingCharacterWriteKind.spellState,
          targetId: bad.target,
          payload: bad.payload,
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
        expect(
          server.writes.where((w) => w.table == 'character_spells'),
          isEmpty,
        );
        expect(spell(11)['status'], 'connu');
      });
    }

    test(
      'isolation par ownerId : la ligne d\'un autre compte reste en file',
      () async {
        await queue.enqueue(
          characterId: 'char-autre',
          ownerId: _ownerB,
          kind: PendingCharacterWriteKind.spellState,
          targetId: '11',
          payload: {'favorite': true},
        );
        await openOnline();
        goOffline();
        await repository.setSpellFavorite(
          characterId: _characterId,
          spellId: 11,
          isFavorite: true,
        );
        goOnline();

        expect(await syncer.sync(), {_characterId});

        expect(await queue.allForOwner(_ownerB), hasLength(1));
        expect(
          server.appliedWrites.where((w) => w.table == 'character_spells'),
          hasLength(1),
        );
      },
    );

    test('ordre de rejeu avec un autre kind : PV puis sort', () async {
      await openOnline();
      goOffline();
      await repository.updateHp(
        characterId: _characterId,
        currentHp: 3,
        temporaryHp: 0,
      );
      clock = clock.add(const Duration(seconds: 5));
      await repository.setSpellFavorite(
        characterId: _characterId,
        spellId: 11,
        isFavorite: true,
      );
      goOnline();

      expect(await syncer.sync(), {_characterId});

      expect(server.appliedWrites.map((w) => w.table).toList(), [
        'characters',
        'character_spells',
      ]);
    });
  });

  // ---------------------------------------------------------------------
  group('inventoryState (équipé, set d\'arme, harmonisé)', () {
    test(
      'hors ligne : queued, une ligne par objet, champs fusionnés',
      () async {
        await openOnline();
        goOffline();

        expect(
          await repository.equipWeaponToSlot(
            characterId: _characterId,
            inventoryId: 'inv-1',
            slot: WeaponSlot.principal,
          ),
          WriteOutcome.queued,
        );
        expect(
          await repository.setInventoryItemAttuned(
            characterId: _characterId,
            inventoryId: 'inv-1',
            attuned: true,
          ),
          WriteOutcome.queued,
        );

        final l = await line(
          PendingCharacterWriteKind.inventoryState,
          targetId: 'inv-1',
        );
        expect(l.payload, {
          'equipped': true,
          'weaponSlot': 'principal',
          'attuned': true,
        });
        expect(server.requests.where((r) => r.isWrite), isEmpty);
      },
    );

    test('erreur de transport en ligne : queued', () async {
      await openOnline();
      server.failBefore(1);

      final outcome = await repository.setInventoryItemEquipped(
        characterId: _characterId,
        inventoryId: 'inv-1',
        equipped: true,
      );

      expect(outcome, WriteOutcome.queued);
      expect(
        (await line(
          PendingCharacterWriteKind.inventoryState,
          targetId: 'inv-1',
        )).payload,
        {'equipped': true},
      );
    });

    test('refus 42501 : échec, rien en file', () async {
      await openOnline();
      server.rejectWith('42501');

      await expectLater(
        repository.setInventoryItemEquipped(
          characterId: _characterId,
          inventoryId: 'inv-1',
          equipped: true,
        ),
        throwsA(isA<CharacterFailure>()),
      );
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });

    test('zéro ligne affectée en ligne : accessDenied, rien en file', () async {
      await openOnline();
      inventoryRows.clear();

      await expectLater(
        repository.setInventoryItemAttuned(
          characterId: _characterId,
          inventoryId: 'inv-1',
          attuned: true,
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

    test(
      'déséquiper efface aussi le set d\'arme ; dernière valeur gagnante',
      () async {
        await openOnline();
        goOffline();
        await repository.equipWeaponToSlot(
          characterId: _characterId,
          inventoryId: 'inv-1',
          slot: WeaponSlot.principal,
        );
        clock = clock.add(const Duration(seconds: 5));
        await repository.setInventoryItemEquipped(
          characterId: _characterId,
          inventoryId: 'inv-1',
          equipped: false,
        );

        expect(
          (await line(
            PendingCharacterWriteKind.inventoryState,
            targetId: 'inv-1',
          )).payload,
          {'equipped': false, 'weaponSlot': null},
        );
      },
    );

    test('échange d\'armes hors ligne : une ligne par objet, état effectif '
        'cohérent, rejeu des deux', () async {
      inventoryRows[0] = _itemRow(
        'inv-1',
        equipped: true,
        weaponSlot: 'principal',
      );
      server.characterRow['character_inventory'] = inventoryRows;
      server.tables['character_inventory'] = inventoryRows;
      await openOnline();
      goOffline();

      await repository.setInventoryItemEquipped(
        characterId: _characterId,
        inventoryId: 'inv-1',
        equipped: false,
      );
      await repository.equipWeaponToSlot(
        characterId: _characterId,
        inventoryId: 'inv-2',
        slot: WeaponSlot.principal,
      );

      expect(
        await lines(PendingCharacterWriteKind.inventoryState),
        hasLength(2),
      );
      final detail = await reopen();
      final i1 = detail.inventory.singleWhere((i) => i.id == 'inv-1');
      final i2 = detail.inventory.singleWhere((i) => i.id == 'inv-2');
      expect(i1.equipped, isFalse);
      expect(i1.weaponSlot, isNull);
      expect(i2.equipped, isTrue);
      expect(i2.weaponSlot, WeaponSlot.principal);

      goOnline();
      expect(await syncer.sync(), {_characterId});
      expect(item('inv-1')['equipped'], false);
      expect(item('inv-1')['weapon_slot'], isNull);
      expect(item('inv-2')['equipped'], true);
      expect(item('inv-2')['weapon_slot'], 'principal');
    });

    test('plafond d\'harmonisation : 3 objets au plus, calculé sur l\'état '
        'effectif (cache + changements cumulés hors ligne)', () async {
      inventoryRows[0] = _itemRow('inv-1', attuned: true);
      await openOnline();
      goOffline();

      for (final id in ['inv-2', 'inv-3']) {
        expect(
          await repository.setInventoryItemAttuned(
            characterId: _characterId,
            inventoryId: id,
            attuned: true,
          ),
          WriteOutcome.queued,
        );
      }
      await expectLater(
        repository.setInventoryItemAttuned(
          characterId: _characterId,
          inventoryId: 'inv-4',
          attuned: true,
        ),
        throwsA(isA<CharacterFailure>()),
      );
      expect(
        await lines(PendingCharacterWriteKind.inventoryState),
        hasLength(2),
      );
      expect((await reopen()).attunedItemCount, 3);

      // Ne plus harmoniser un objet libère une place.
      await repository.setInventoryItemAttuned(
        characterId: _characterId,
        inventoryId: 'inv-1',
        attuned: false,
      );
      expect(
        await repository.setInventoryItemAttuned(
          characterId: _characterId,
          inventoryId: 'inv-4',
          attuned: true,
        ),
        WriteOutcome.queued,
      );
      expect((await reopen()).attunedItemCount, 3);
    });

    test('en ligne : écriture filtrée, cache mis à jour, entrée périmée '
        'fusionnée puis retirée', () async {
      await openOnline();
      connectivity.goOffline();
      await repository.setInventoryItemAttuned(
        characterId: _characterId,
        inventoryId: 'inv-1',
        attuned: true,
      );
      connectivity.goOnline();

      final outcome = await repository.setInventoryItemEquipped(
        characterId: _characterId,
        inventoryId: 'inv-1',
        equipped: true,
      );

      expect(outcome, WriteOutcome.synced);
      expect(item('inv-1')['equipped'], true);
      expect(item('inv-1')['is_attuned'], true, reason: 'harmonisé fusionné');
      final patch = server.appliedWrites.single;
      expect(patch.query['id'], 'eq.inv-1');
      expect(patch.query['character_id'], 'eq.$_characterId');
      expect(await queue.allForOwner(_ownerA), isEmpty);
      final cachedRows = await cachedRelation('character_inventory');
      final cached = cachedRows.singleWhere((r) => r['id'] == 'inv-1');
      expect(cached['equipped'], true);
      expect(cached['is_attuned'], true);
    });

    test('rejeu : colonnes absolues, filtré par objet ET personnage, cache '
        'mis à jour', () async {
      await openOnline();
      goOffline();
      await repository.equipWeaponToSlot(
        characterId: _characterId,
        inventoryId: 'inv-2',
        slot: WeaponSlot.secondary,
      );
      goOnline();

      expect(await syncer.sync(), {_characterId});

      final patch = server.appliedWrites.single;
      expect(patch.body, {'equipped': true, 'weapon_slot': 'secondaire'});
      expect(patch.query['id'], 'eq.inv-2');
      expect(patch.query['character_id'], 'eq.$_characterId');
      expect(item('inv-1')['equipped'], false);
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });

    test('rejeu idempotent : réponse perdue', () async {
      await openOnline();
      goOffline();
      await repository.setInventoryItemAttuned(
        characterId: _characterId,
        inventoryId: 'inv-1',
        attuned: true,
      );
      goOnline();
      server.failAfterApply(1);

      expect(await syncer.sync(), isEmpty);
      expect(await syncer.sync(), {_characterId});

      expect(item('inv-1')['is_attuned'], true);
      expect(server.appliedWrites, hasLength(2));
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });

    test('zéro ligne au rejeu (objet disparu) : abandon au seuil puis alerte '
        'persistée', () async {
      await openOnline();
      goOffline();
      await repository.setInventoryItemAttuned(
        characterId: _characterId,
        inventoryId: 'inv-1',
        attuned: true,
      );
      goOnline();
      inventoryRows.clear();

      final abandoned = <String>{};
      for (
        var i = 0;
        i < PendingCharacterWriteQueue.abandonAfterConsecutiveFailures;
        i++
      ) {
        abandoned.addAll((await syncer.syncWithReport()).abandonedCharacterIds);
      }

      expect(abandoned, {_characterId});
      expect(await queue.allForOwner(_ownerA), isEmpty);
      final recorder = SyncAlertRecorder(
        db,
        queue,
        SyncAlertStore(db),
        CharacterDetailCache(cache),
      );
      final consumed = await recorder.recordAbandoned(_ownerA);
      expect(consumed.single.kindKey, 'inventory_state');
    });

    for (final bad in <({String target, Map<String, dynamic> payload})>[
      (target: 'inv-1', payload: {}),
      (target: 'inv-1', payload: {'equipped': 'oui'}),
      (target: 'inv-1', payload: {'attuned': 1}),
      (target: 'inv-1', payload: {'weaponSlot': 'main'}),
      (target: 'inv-1', payload: {'weaponSlot': 3}),
      (
        target: 'inv-1',
        payload: {'equipped': false, 'weaponSlot': 'principal'},
      ),
      (target: '', payload: {'equipped': true}),
      (target: '  ', payload: {'equipped': true}),
    ]) {
      test('payload/cible invalide ($bad) : aucune écriture, ligne supprimée, '
          'autres lignes rejouées, compteur à 0', () async {
        await queue.enqueue(
          characterId: _characterId,
          ownerId: _ownerA,
          kind: PendingCharacterWriteKind.inventoryState,
          targetId: bad.target,
          payload: bad.payload,
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
        expect(
          server.writes.where((w) => w.table == 'character_inventory'),
          isEmpty,
        );
      });
    }

    test(
      'isolation par ownerId : la ligne d\'un autre compte reste en file',
      () async {
        await queue.enqueue(
          characterId: 'char-autre',
          ownerId: _ownerB,
          kind: PendingCharacterWriteKind.inventoryState,
          targetId: 'inv-1',
          payload: {'equipped': true},
        );
        await openOnline();
        goOffline();
        await repository.setInventoryItemAttuned(
          characterId: _characterId,
          inventoryId: 'inv-1',
          attuned: true,
        );
        goOnline();

        expect(await syncer.sync(), {_characterId});

        expect(await queue.allForOwner(_ownerB), hasLength(1));
        expect(server.appliedWrites, hasLength(1));
      },
    );
  });
}
