// Tests de l'extension D11 du registre de dette technique (décision chef de
// projet du 09/10/2026, catégorie A « bloque la mise en production ») :
// `castSpell`/`useClassFeature`/`applyRest` rejoignent `updateHp`/`addXp`
// dans une vraie file hors ligne (`PendingCharacterWriteQueue`), au lieu de
// retourner `WriteOutcome.queued` sans jamais rien persister.
//
// Couvre :
// - mise en file réelle hors ligne (payload, kind, targetId) pour chacune
//   des trois méthodes ;
// - écriture en ligne qui supersède une entrée restée en file pour la MÊME
//   cible, sans jamais toucher une entrée d'une AUTRE cible (le point
//   central de l'extension du schéma `targetId`) ;
// - superposition de la fiche relue (`fetchCharacterDetail`) par une entrée
//   `spellSlot`/`innateSpell`/`classFeature` en attente (`_withPendingWrites`,
//   nouveaux cas) ;
// - rejouabilité par `PendingCharacterWriteSyncer.sync` des quatre nouveaux
//   kinds (y compris `rest`, qui délègue à `applyRestOnline`) ;
// - verrou D33 (`runExclusive`) sur une clé `(characterId, kind, targetId)`
//   pour un scénario de concurrence réel (écriture en ligne vs. synchro de
//   la file en vol en même temps), comme celui qui existe déjà pour PV/XP.
//
// Même double `SupabaseClient`/`MockClient` que
// `character_repository_rest_test.dart` (routage par nom de table, session
// factice sans réseau, journal [_Recorded] de chaque requête).

import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:personnages/core/cache/app_database.dart';
import 'package:personnages/core/cache/pending_character_write_queue.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/core/network/connectivity_checker.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/data/pending_character_write_syncer.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/rest_type.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _characterId = 'char-1';
const _ownerId = 'owner-1';

void main() {
  late AppDatabase db;
  late ReferenceDataCache cache;
  late PendingCharacterWriteQueue pendingWrites;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    cache = ReferenceDataCache(db);
    pendingWrites = PendingCharacterWriteQueue(db);
  });

  tearDown(() async {
    await db.close();
  });

  /// Ligne `characters` minimale pour satisfaire le `maybeSingle()`
  /// d'appartenance de `castSpell`/`useClassFeature`/`applyRestOnline` —
  /// sans aucune classe (chemin le plus simple d'`applyRest`, déjà couvert
  /// par `character_repository_rest_test.dart` : « personnage sans aucune
  /// classe : repos appliqué sans erreur »). `max_hp`/`current_hp`/
  /// `temporary_hp` : nécessaires au chemin repos LONG (relecture de
  /// `max_hp` avant `current_hp = max_hp`, voir le scénario de
  /// non-régression du deadlock D35/D11 ci-dessous) — sans effet sur les
  /// autres tests de ce fichier, qui ne les lisent jamais.
  Map<String, List<Map<String, dynamic>>> baseRows() => {
    'characters': [
      {'id': _characterId, 'max_hp': 10, 'current_hp': 7, 'temporary_hp': 0},
    ],
    'character_classes': [],
  };

  group('castSpell (mode hors-ligne, D11)', () {
    test('connectivité absente -> met en file (kind spellSlot, targetId '
        "'std_3') sans tenter le réseau, retourne queued", () async {
      final recorded = <_Recorded>[];
      final client = await _buildSignedInFakeSupabaseClient(
        ownerId: _ownerId,
        recorded: recorded,
      );
      final repository = SupabaseCharacterRepository(
        client,
        cache,
        pendingWrites,
        _FakeConnectivityChecker(connected: false),
      );

      final outcome = await repository.castSpell(
        characterId: _characterId,
        slotLevel: 3,
        slotsUsed: 1,
      );

      expect(outcome, WriteOutcome.queued);
      expect(recorded, isEmpty);
      final pending = await pendingWrites.allForOwner(_ownerId);
      expect(pending, hasLength(1));
      expect(pending.single.kind, PendingCharacterWriteKind.spellSlot);
      expect(pending.single.targetId, 'std_3');
      expect(pending.single.payload, {
        'slotLevel': 3,
        'slotsUsed': 1,
        'isPactSlot': false,
      });
    });

    test('un emplacement de pacte reçoit un targetId distinct '
        "(pact_2) d'un emplacement classique de même niveau (std_2)", () async {
      final recorded = <_Recorded>[];
      final client = await _buildSignedInFakeSupabaseClient(
        ownerId: _ownerId,
        recorded: recorded,
      );
      final repository = SupabaseCharacterRepository(
        client,
        cache,
        pendingWrites,
        _FakeConnectivityChecker(connected: false),
      );

      await repository.castSpell(
        characterId: _characterId,
        slotLevel: 2,
        slotsUsed: 1,
      );
      await repository.castSpell(
        characterId: _characterId,
        slotLevel: 2,
        slotsUsed: 1,
        isPactSlot: true,
      );

      final pending = await pendingWrites.allForOwner(_ownerId);
      expect(pending, hasLength(2));
      expect(pending.map((w) => w.targetId).toSet(), {'std_2', 'pact_2'});
    });

    test('connectivité présente, écriture réussie -> synced, PATCH envoyé sur '
        'character_spell_slots', () async {
      final recorded = <_Recorded>[];
      final client = await _buildSignedInFakeSupabaseClient(
        ownerId: _ownerId,
        recorded: recorded,
        tableRows: baseRows(),
      );
      final repository = SupabaseCharacterRepository(
        client,
        cache,
        pendingWrites,
        _FakeConnectivityChecker(connected: true),
      );

      final outcome = await repository.castSpell(
        characterId: _characterId,
        slotLevel: 3,
        slotsUsed: 2,
      );

      expect(outcome, WriteOutcome.synced);
      final patch = recorded.singleWhere(
        (r) => r.method == 'PATCH' && r.table == 'character_spell_slots',
      );
      expect(patch.body, {'slots_used': 2});
      expect(await pendingWrites.allForOwner(_ownerId), isEmpty);
    });

    test('écriture en ligne réussie : supersède une entrée en file de la MÊME '
        'cible, mais jamais une entrée de niveau différent', () async {
      // Un lancer niveau 3 est resté en file (hors ligne précédente, pas
      // encore synchronisé) — un lancer niveau 1 aussi, cible différente.
      await pendingWrites.enqueue(
        characterId: _characterId,
        ownerId: _ownerId,
        kind: PendingCharacterWriteKind.spellSlot,
        targetId: 'std_3',
        payload: {'slotLevel': 3, 'slotsUsed': 1, 'isPactSlot': false},
      );
      await pendingWrites.enqueue(
        characterId: _characterId,
        ownerId: _ownerId,
        kind: PendingCharacterWriteKind.spellSlot,
        targetId: 'std_1',
        payload: {'slotLevel': 1, 'slotsUsed': 1, 'isPactSlot': false},
      );
      final recorded = <_Recorded>[];
      final client = await _buildSignedInFakeSupabaseClient(
        ownerId: _ownerId,
        recorded: recorded,
        tableRows: baseRows(),
      );
      final repository = SupabaseCharacterRepository(
        client,
        cache,
        pendingWrites,
        _FakeConnectivityChecker(connected: true),
      );

      // Réseau revenu : le joueur relance directement niveau 3 en ligne
      // (nouvelle valeur calculée à partir d'une lecture fraîche).
      await repository.castSpell(
        characterId: _characterId,
        slotLevel: 3,
        slotsUsed: 2,
      );

      final pending = await pendingWrites.allForOwner(_ownerId);
      expect(
        pending,
        hasLength(1),
        reason: "l'entrée niveau 1 doit rester, jamais retirée par erreur",
      );
      expect(pending.single.targetId, 'std_1');
    });

    test('connectivité présente mais requête qui expire (D12) -> met en file '
        'comme une absence de connectivité', () async {
      final client = await _buildSignedInTimeoutClient(ownerId: _ownerId);
      final repository = SupabaseCharacterRepository(
        client,
        cache,
        pendingWrites,
        _FakeConnectivityChecker(connected: true),
      );

      final outcome = await repository.castSpell(
        characterId: _characterId,
        slotLevel: 3,
        slotsUsed: 1,
      );

      expect(outcome, WriteOutcome.queued);
      final pending = await pendingWrites.allForOwner(_ownerId);
      expect(pending, hasLength(1));
      expect(pending.single.kind, PendingCharacterWriteKind.spellSlot);
      expect(pending.single.targetId, 'std_3');
    });
  });

  group('useClassFeature (mode hors-ligne, D11)', () {
    test('connectivité absente -> met en file (kind classFeature, targetId '
        "'50') sans tenter le réseau, retourne queued", () async {
      final recorded = <_Recorded>[];
      final client = await _buildSignedInFakeSupabaseClient(
        ownerId: _ownerId,
        recorded: recorded,
      );
      final repository = SupabaseCharacterRepository(
        client,
        cache,
        pendingWrites,
        _FakeConnectivityChecker(connected: false),
      );

      final outcome = await repository.useClassFeature(
        characterId: _characterId,
        classFeatureId: 50,
        usesRemaining: 1,
      );

      expect(outcome, WriteOutcome.queued);
      expect(recorded, isEmpty);
      final pending = await pendingWrites.allForOwner(_ownerId);
      expect(pending, hasLength(1));
      expect(pending.single.kind, PendingCharacterWriteKind.classFeature);
      expect(pending.single.targetId, '50');
      expect(pending.single.payload, {
        'classFeatureId': 50,
        'usesRemaining': 1,
      });
    });

    test('connectivité présente, écriture réussie -> synced, upsert envoyé sur '
        'character_feature_uses', () async {
      final recorded = <_Recorded>[];
      final client = await _buildSignedInFakeSupabaseClient(
        ownerId: _ownerId,
        recorded: recorded,
        tableRows: baseRows(),
      );
      final repository = SupabaseCharacterRepository(
        client,
        cache,
        pendingWrites,
        _FakeConnectivityChecker(connected: true),
      );

      final outcome = await repository.useClassFeature(
        characterId: _characterId,
        classFeatureId: 50,
        usesRemaining: 1,
      );

      expect(outcome, WriteOutcome.synced);
      final upsert = recorded.singleWhere(
        (r) => r.table == 'character_feature_uses',
      );
      expect(upsert.body, {
        'character_id': _characterId,
        'class_feature_id': 50,
        'uses_remaining': 1,
      });
      expect(await pendingWrites.allForOwner(_ownerId), isEmpty);
    });

    test('deux aptitudes différentes du même personnage ne coalescent jamais '
        'et ne se verrouillent jamais mutuellement', () async {
      await pendingWrites.enqueue(
        characterId: _characterId,
        ownerId: _ownerId,
        kind: PendingCharacterWriteKind.classFeature,
        targetId: '50',
        payload: {'classFeatureId': 50, 'usesRemaining': 1},
      );
      await pendingWrites.enqueue(
        characterId: _characterId,
        ownerId: _ownerId,
        kind: PendingCharacterWriteKind.classFeature,
        targetId: '51',
        payload: {'classFeatureId': 51, 'usesRemaining': 0},
      );

      final pending = await pendingWrites.allForOwner(_ownerId);
      expect(pending, hasLength(2));
    });
  });

  group('applyRest (mode hors-ligne, D11)', () {
    test(
      'connectivité absente -> met en file (kind rest, targetId vide) sans '
      "tenter le réseau (y compris le garde-fou D35), retourne queued",
      () async {
        final recorded = <_Recorded>[];
        final client = await _buildSignedInFakeSupabaseClient(
          ownerId: _ownerId,
          recorded: recorded,
        );
        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          _FakeConnectivityChecker(connected: false),
        );

        final outcome = await repository.applyRest(
          characterId: _characterId,
          type: RestType.long,
          className: 'Guerrier',
          diceSpent: 0,
          appliedGain: 0,
        );

        expect(outcome, WriteOutcome.queued);
        expect(
          recorded,
          isEmpty,
          reason:
              'aucune lecture/écriture serveur ne doit être tentée hors '
              'ligne, y compris la synchro best-effort de D35',
        );
        final pending = await pendingWrites.allForOwner(_ownerId);
        expect(pending, hasLength(1));
        expect(pending.single.kind, PendingCharacterWriteKind.rest);
        expect(pending.single.targetId, '');
        expect(pending.single.payload, {
          'type': 'long',
          'className': 'Guerrier',
          'diceSpent': 0,
          'appliedGain': 0,
        });
      },
    );

    test('repos court avec diceSpent/appliedGain nuls : payload fidèle, type '
        "'short'", () async {
      final client = await _buildSignedInFakeSupabaseClient(
        ownerId: _ownerId,
        recorded: [],
      );
      final repository = SupabaseCharacterRepository(
        client,
        cache,
        pendingWrites,
        _FakeConnectivityChecker(connected: false),
      );

      await repository.applyRest(
        characterId: _characterId,
        type: RestType.short,
        className: '',
      );

      final pending = (await pendingWrites.allForOwner(_ownerId)).single;
      expect(pending.payload, {
        'type': 'short',
        'className': '',
        'diceSpent': 0,
        'appliedGain': 0,
      });
    });

    test('écriture en ligne réussie : supersède une entrée de repos restée en '
        'file (jamais rejouée une seconde fois par la synchro)', () async {
      await pendingWrites.enqueue(
        characterId: _characterId,
        ownerId: _ownerId,
        kind: PendingCharacterWriteKind.rest,
        targetId: '',
        payload: {
          'type': 'short',
          'className': '',
          'diceSpent': 0,
          'appliedGain': 0,
        },
      );
      final client = await _buildSignedInFakeSupabaseClient(
        ownerId: _ownerId,
        recorded: [],
        tableRows: baseRows(),
      );
      final repository = SupabaseCharacterRepository(
        client,
        cache,
        pendingWrites,
        _FakeConnectivityChecker(connected: true),
      );

      final outcome = await repository.applyRest(
        characterId: _characterId,
        type: RestType.short,
        className: '',
      );

      expect(outcome, WriteOutcome.synced);
      expect(await pendingWrites.allForOwner(_ownerId), isEmpty);
    });

    test(
      'personnage introuvable (supprimé entre la mise en file et la '
      'synchronisation) : CharacterFailure, jamais un succès silencieux',
      () async {
        final client = await _buildSignedInFakeSupabaseClient(
          ownerId: _ownerId,
          recorded: [],
          tableRows: const {'characters': [], 'character_classes': []},
        );
        final repository = SupabaseCharacterRepository(
          client,
          cache,
          pendingWrites,
          _FakeConnectivityChecker(connected: true),
        );

        await expectLater(
          repository.applyRest(
            characterId: _characterId,
            type: RestType.short,
            className: '',
          ),
          throwsA(isA<CharacterFailure>()),
        );
      },
    );

    // Non-régression (défaut trouvé en revue QA, même cause racine que le
    // deadlock ci-dessus) : avant la correction, `_blockIfPendingHpOrXpWrites`
    // ne filtrait pas par kind — une entrée `classFeature` (ou tout autre
    // kind non hp/xp) encore en file pour ce personnage faisait échouer un
    // repos LONG (qui déclenche D35) avec le message « Des ajustements de
    // PV/XP sont encore en attente... », même si aucun PV/XP n'était en
    // cause. Le repos doit réussir normalement, et l'entrée `classFeature`
    // (hors du périmètre de D35) doit rester intacte, jamais touchée par ce
    // garde-fou.
    test("une entrée classFeature encore en file n'est jamais confondue avec "
        'un ajustement PV/XP par le garde-fou D35 (repos long réussit '
        'normalement)', () async {
      await pendingWrites.enqueue(
        characterId: _characterId,
        ownerId: _ownerId,
        kind: PendingCharacterWriteKind.classFeature,
        targetId: '50',
        payload: {'classFeatureId': 50, 'usesRemaining': 1},
      );
      final client = await _buildSignedInFakeSupabaseClient(
        ownerId: _ownerId,
        recorded: [],
        tableRows: baseRows(),
      );
      final repository = SupabaseCharacterRepository(
        client,
        cache,
        pendingWrites,
        _FakeConnectivityChecker(connected: true),
      );

      final outcome = await repository.applyRest(
        characterId: _characterId,
        type: RestType.long,
        className: '',
      );

      expect(outcome, WriteOutcome.synced);
      final pending = await pendingWrites.allForOwner(_ownerId);
      expect(
        pending,
        hasLength(1),
        reason:
            "l'entrée classFeature n'a aucun rapport avec D35 : ni "
            'synchronisée (filtrée hors de `sync(onlyKinds: {hp, xp})`), '
            'ni la cause d\'un blocage',
      );
      expect(pending.single.kind, PendingCharacterWriteKind.classFeature);
    });
  });

  group('fetchCharacterDetail : superposition des écritures en attente '
      '(_withPendingWrites, D11)', () {
    Map<String, List<Map<String, dynamic>>> detailRows() => {
      'characters': [
        {
          'id': _characterId,
          'name': 'Lia',
          'xp': 0,
          'current_hp': 10,
          'max_hp': 10,
          'temporary_hp': 0,
          'character_classes': [
            {
              'class_id': 2,
              'subclass_id': null,
              'level': 5,
              'is_primary': true,
              'hit_dice_spent': 0,
              'classes': {
                'saving_throw_proficiencies': <String>[],
                'hit_die': 10,
              },
            },
          ],
          'character_spells': [
            {
              'spell_id': 30,
              'status': 'inné',
              'is_favorite': false,
              'source_class_id': null,
              'innate_uses_spent': 0,
            },
          ],
          'character_spell_slots': [
            {'slot_level': 1, 'slots_total': 4, 'slots_used': 1},
          ],
          'character_feature_uses': [
            {'class_feature_id': 50, 'uses_remaining': 2},
          ],
        },
      ],
      'translations': [
        {'entity_id': '30', 'value': 'Lumières dansantes'},
        {'entity_id': '50', 'value': 'Deuxième souffle'},
      ],
      'spells': [
        {'id': 30, 'level': 1, 'school': 'évocation'},
      ],
      'class_features': [
        {'id': 50, 'class_id': 2, 'level': 3},
      ],
    };

    test('une entrée spellSlot en file remplace slots_used du niveau '
        "concerné, jamais un autre niveau", () async {
      await pendingWrites.enqueue(
        characterId: _characterId,
        ownerId: _ownerId,
        kind: PendingCharacterWriteKind.spellSlot,
        targetId: 'std_1',
        payload: {'slotLevel': 1, 'slotsUsed': 3, 'isPactSlot': false},
      );
      final client = await _buildSignedInFakeSupabaseClient(
        ownerId: _ownerId,
        recorded: [],
        tableRows: detailRows(),
      );
      final repository = SupabaseCharacterRepository(
        client,
        cache,
        pendingWrites,
        _FakeConnectivityChecker(connected: true),
      );

      final detail = await repository.fetchCharacterDetail(_characterId);

      expect(detail.spellSlots.single.used, 3);
      expect(
        detail.spellSlots.single.total,
        4,
        reason: 'le total ne vient jamais de la file, seul used change',
      );
    });

    test('une entrée innateSpell en file remplace innateUsesSpent du sort '
        'concerné', () async {
      await pendingWrites.enqueue(
        characterId: _characterId,
        ownerId: _ownerId,
        kind: PendingCharacterWriteKind.innateSpell,
        targetId: '30',
        payload: {'spellId': 30, 'usesSpent': 1},
      );
      final client = await _buildSignedInFakeSupabaseClient(
        ownerId: _ownerId,
        recorded: [],
        tableRows: detailRows(),
      );
      final repository = SupabaseCharacterRepository(
        client,
        cache,
        pendingWrites,
        _FakeConnectivityChecker(connected: true),
      );

      final detail = await repository.fetchCharacterDetail(_characterId);

      expect(detail.spells.single.innateUsesSpent, 1);
    });

    test('une entrée classFeature en file remplace usesRemaining de '
        "l'aptitude concernée", () async {
      await pendingWrites.enqueue(
        characterId: _characterId,
        ownerId: _ownerId,
        kind: PendingCharacterWriteKind.classFeature,
        targetId: '50',
        payload: {'classFeatureId': 50, 'usesRemaining': 0},
      );
      final client = await _buildSignedInFakeSupabaseClient(
        ownerId: _ownerId,
        recorded: [],
        tableRows: detailRows(),
      );
      final repository = SupabaseCharacterRepository(
        client,
        cache,
        pendingWrites,
        _FakeConnectivityChecker(connected: true),
      );

      final detail = await repository.fetchCharacterDetail(_characterId);

      expect(detail.classFeatures.single.usesRemaining, 0);
    });

    test('une entrée rest en file n\'est JAMAIS superposée (limite assumée, '
        'voir la doc de PendingCharacterWriteQueue.forCharacter)', () async {
      await pendingWrites.enqueue(
        characterId: _characterId,
        ownerId: _ownerId,
        kind: PendingCharacterWriteKind.rest,
        targetId: '',
        payload: {
          'type': 'long',
          'className': '',
          'diceSpent': 0,
          'appliedGain': 0,
        },
      );
      final client = await _buildSignedInFakeSupabaseClient(
        ownerId: _ownerId,
        recorded: [],
        tableRows: detailRows(),
      );
      final repository = SupabaseCharacterRepository(
        client,
        cache,
        pendingWrites,
        _FakeConnectivityChecker(connected: true),
      );

      final detail = await repository.fetchCharacterDetail(_characterId);

      expect(
        detail.currentHp,
        10,
        reason:
            'valeur serveur inchangée : un repos en file ne simule '
            'jamais côté client ce qu\'il recalculerait sur le serveur',
      );
    });
  });

  group('PendingCharacterWriteSyncer.sync (nouveaux kinds, D11)', () {
    test('spellSlot : rejoue le PATCH sur character_spell_slots et retire '
        "l'entrée", () async {
      await pendingWrites.enqueue(
        characterId: _characterId,
        ownerId: _ownerId,
        kind: PendingCharacterWriteKind.spellSlot,
        targetId: 'std_2',
        payload: {'slotLevel': 2, 'slotsUsed': 1, 'isPactSlot': false},
      );
      final recorded = <_Recorded>[];
      final client = await _buildSignedInFakeSupabaseClient(
        ownerId: _ownerId,
        recorded: recorded,
        tableRows: baseRows(),
      );
      final repository = SupabaseCharacterRepository(
        client,
        cache,
        pendingWrites,
        _FakeConnectivityChecker(connected: true),
      );
      final syncer = PendingCharacterWriteSyncer(
        client,
        pendingWrites,
        cache,
        repository,
      );

      final synced = await syncer.sync();

      expect(synced, {_characterId});
      final patch = recorded.singleWhere(
        (r) => r.method == 'PATCH' && r.table == 'character_spell_slots',
      );
      expect(patch.body, {'slots_used': 1});
      expect(await pendingWrites.allForOwner(_ownerId), isEmpty);
    });

    test('classFeature : rejoue l\'upsert sur character_feature_uses et '
        "retire l'entrée", () async {
      await pendingWrites.enqueue(
        characterId: _characterId,
        ownerId: _ownerId,
        kind: PendingCharacterWriteKind.classFeature,
        targetId: '50',
        payload: {'classFeatureId': 50, 'usesRemaining': 1},
      );
      final recorded = <_Recorded>[];
      final client = await _buildSignedInFakeSupabaseClient(
        ownerId: _ownerId,
        recorded: recorded,
        tableRows: baseRows(),
      );
      final repository = SupabaseCharacterRepository(
        client,
        cache,
        pendingWrites,
        _FakeConnectivityChecker(connected: true),
      );
      final syncer = PendingCharacterWriteSyncer(
        client,
        pendingWrites,
        cache,
        repository,
      );

      await syncer.sync();

      final upsert = recorded.singleWhere(
        (r) => r.table == 'character_feature_uses',
      );
      expect(upsert.body, {
        'character_id': _characterId,
        'class_feature_id': 50,
        'uses_remaining': 1,
      });
      expect(await pendingWrites.allForOwner(_ownerId), isEmpty);
    });

    test('rest : délègue à applyRestOnline (personnage sans classe, chemin le '
        "plus simple) et retire l'entrée", () async {
      await pendingWrites.enqueue(
        characterId: _characterId,
        ownerId: _ownerId,
        kind: PendingCharacterWriteKind.rest,
        targetId: '',
        payload: {
          'type': 'short',
          'className': '',
          'diceSpent': 0,
          'appliedGain': 0,
        },
      );
      final recorded = <_Recorded>[];
      final client = await _buildSignedInFakeSupabaseClient(
        ownerId: _ownerId,
        recorded: recorded,
        tableRows: baseRows(),
      );
      final repository = SupabaseCharacterRepository(
        client,
        cache,
        pendingWrites,
        _FakeConnectivityChecker(connected: true),
      );
      final syncer = PendingCharacterWriteSyncer(
        client,
        pendingWrites,
        cache,
        repository,
      );

      final synced = await syncer.sync();

      expect(synced, {_characterId});
      expect(await pendingWrites.allForOwner(_ownerId), isEmpty);
    });

    // Non-régression (bug bloquant trouvé en revue QA) : un repos LONG mis
    // en file (ou un repos court avec `appliedGain > 0`) déclenche, une fois
    // synchronisé, le garde-fou D35 (`_blockIfPendingHpOrXpWrites`) à
    // l'intérieur même d'`applyRestOnline` — qui appelait auparavant un
    // `PendingCharacterWriteSyncer.sync()` NON filtré. Puisque l'entrée
    // `rest` en cours de rejeu est toujours en file à ce stade (retirée
    // seulement après le succès d'`applyRestOnline`), ce `sync()` imbriqué
    // retentait `PendingCharacterWriteQueue.runExclusive` pour la MÊME clé
    // `(characterId, rest, '')` déjà tenue par l'appel englobant —
    // attente circulaire sur le verrou en mémoire, jamais résolue
    // (`sync()` ne se serait jamais terminé). `.timeout(...)` ci-dessous
    // transforme un deadlock en échec de test explicite et rapide plutôt
    // qu'un test qui pendrait silencieusement.
    test('rest LONG mis en file -> synchronisé avec succès sans jamais '
        'bloquer (deadlock D35/D11 corrigé)', () async {
      await pendingWrites.enqueue(
        characterId: _characterId,
        ownerId: _ownerId,
        kind: PendingCharacterWriteKind.rest,
        targetId: '',
        payload: {
          'type': 'long',
          'className': '',
          'diceSpent': 0,
          'appliedGain': 0,
        },
      );
      final recorded = <_Recorded>[];
      final client = await _buildSignedInFakeSupabaseClient(
        ownerId: _ownerId,
        recorded: recorded,
        tableRows: baseRows(),
      );
      final repository = SupabaseCharacterRepository(
        client,
        cache,
        pendingWrites,
        _FakeConnectivityChecker(connected: true),
      );
      final syncer = PendingCharacterWriteSyncer(
        client,
        pendingWrites,
        cache,
        repository,
      );

      final synced = await syncer.sync().timeout(
        const Duration(seconds: 5),
        onTimeout: () => fail(
          'sync() ne doit jamais bloquer indéfiniment sur un repos long '
          'mis en file — deadlock D35/D11',
        ),
      );

      expect(synced, {_characterId});
      expect(await pendingWrites.allForOwner(_ownerId), isEmpty);
      // Le verrou `(characterId, rest, '')` doit être réellement libéré :
      // un nouveau repos EN LIGNE pour ce même personnage ne doit pas non
      // plus se bloquer derrière lui (c'est précisément l'autre symptôme
      // observé du deadlock).
      final secondAttempt = await repository
          .applyRest(
            characterId: _characterId,
            type: RestType.short,
            className: '',
          )
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => fail(
              'le verrou (characterId, rest, \'\') est resté tenu après '
              'la synchro : un nouveau repos en ligne se bloque aussi',
            ),
          );
      expect(secondAttempt, WriteOutcome.synced);
    });

    test('rest : refus non rejouable (RLS) -> compte comme un échec D34 sur '
        "l'entrée entière", () async {
      await pendingWrites.enqueue(
        characterId: _characterId,
        ownerId: _ownerId,
        kind: PendingCharacterWriteKind.rest,
        targetId: '',
        payload: {
          'type': 'short',
          'className': '',
          'diceSpent': 0,
          'appliedGain': 0,
        },
      );
      // Échoue sur `character_classes` (un simple `select`), jamais sur
      // `characters` (interrogée via `.maybeSingle()`) : une bizarrerie
      // vérifiée de `postgrest` 2.9.1 fait perdre le code JSON réel d'une
      // erreur `.maybeSingle()` au profit du seul code HTTP
      // (`_handleMaybeSingleError` rethrow, avalé par le `catch` générique
      // englobant — voir le probe qui a confirmé ce comportement), ce qui
      // rendrait ce test incapable de produire un code '42501' exploitable
      // par `_isNonRetryable`.
      final client = await _buildSignedInFakeSupabaseClient(
        ownerId: _ownerId,
        recorded: [],
        tableRows: baseRows(),
        failOn: (method, table) =>
            table == 'character_classes' && method == 'GET',
        failureCode: '42501',
      );
      final repository = SupabaseCharacterRepository(
        client,
        cache,
        pendingWrites,
        _FakeConnectivityChecker(connected: true),
      );
      final syncer = PendingCharacterWriteSyncer(
        client,
        pendingWrites,
        cache,
        repository,
      );

      for (
        var i = 0;
        i < PendingCharacterWriteQueue.abandonAfterConsecutiveFailures;
        i++
      ) {
        await syncer.sync();
      }

      expect(
        await pendingWrites.allForOwner(_ownerId),
        isEmpty,
        reason: 'abandonnée au-delà du seuil, plus jamais retentée',
      );
      expect(
        await pendingWrites.consumeAbandonedMessages(ownerId: _ownerId),
        hasLength(1),
      );
    });
  });

  group('Concurrence réelle D33 (targetId dans la clé du verrou)', () {
    test('un lancer de sort EN LIGNE pour un niveau démarré PENDANT que la '
        "synchro de la file traite UN AUTRE niveau n'attend jamais : les deux "
        'écritures réseau partent sans se bloquer', () async {
      await pendingWrites.enqueue(
        characterId: _characterId,
        ownerId: _ownerId,
        kind: PendingCharacterWriteKind.spellSlot,
        targetId: 'std_1',
        payload: {'slotLevel': 1, 'slotsUsed': 1, 'isPactSlot': false},
      );

      final syncGate = Completer<void>();
      final events = <String>[];
      final recorded = <_Recorded>[];
      final client = await _buildSignedInFakeSupabaseClient(
        ownerId: _ownerId,
        recorded: recorded,
        tableRows: baseRows(),
        onRequest: (request) async {
          if (request.url.pathSegments.last == 'character_spell_slots' &&
              request.method == 'PATCH') {
            final body = jsonDecode(request.body) as Map;
            if (body['slots_used'] == 9) {
              // La requête de synchro (niveau 1, voir le payload en file
              // ci-dessus) : bloquée jusqu'à ce que l'écriture en ligne
              // (niveau 2) ait eu l'occasion de démarrer.
              events.add('sync niveau 1 : début');
              await syncGate.future;
              events.add('sync niveau 1 : fin');
            } else {
              events.add('en ligne niveau 2');
            }
          }
        },
      );
      final repository = SupabaseCharacterRepository(
        client,
        cache,
        pendingWrites,
        _FakeConnectivityChecker(connected: true),
      );
      final syncer = PendingCharacterWriteSyncer(
        client,
        pendingWrites,
        cache,
        repository,
      );

      // La valeur réellement en file est 1 ; forcée ici à 9 pour la
      // distinguer sans ambiguïté de l'écriture en ligne (niveau 2,
      // valeur 1) dans le corps de la requête interceptée ci-dessus —
      // réécrite directement dans la file pour ne pas changer son
      // `targetId`.
      final staleWrite = (await pendingWrites.allForOwner(_ownerId)).single;
      await pendingWrites.enqueue(
        characterId: _characterId,
        ownerId: _ownerId,
        kind: PendingCharacterWriteKind.spellSlot,
        targetId: 'std_1',
        payload: {'slotLevel': 1, 'slotsUsed': 9, 'isPactSlot': false},
      );
      expect(staleWrite.targetId, 'std_1');

      final syncFuture = syncer.sync();
      await pumpEventQueue();
      expect(events, ['sync niveau 1 : début']);

      final onlineFuture = repository.castSpell(
        characterId: _characterId,
        slotLevel: 2,
        slotsUsed: 1,
      );
      await pumpEventQueue();

      expect(
        events,
        ['sync niveau 1 : début', 'en ligne niveau 2'],
        reason:
            'targetId différent (std_1 vs std_2) : aucune attente, '
            'contrairement à PV/XP sur une MÊME clé',
      );

      syncGate.complete();
      await Future.wait([syncFuture, onlineFuture]);
      expect(events, [
        'sync niveau 1 : début',
        'en ligne niveau 2',
        'sync niveau 1 : fin',
      ]);
    });
  });
}

class _Recorded {
  _Recorded({
    required this.method,
    required this.table,
    required this.query,
    required this.body,
  });

  final String method;
  final String table;
  final Map<String, String> query;
  final Object? body;

  @override
  String toString() => '$method $table $query $body';
}

class _FakeConnectivityChecker implements ConnectivityChecker {
  _FakeConnectivityChecker({required this.connected});

  final bool connected;

  @override
  Future<bool> hasConnection() async => connected;

  @override
  Stream<bool> get onConnectivityRestored => const Stream.empty();
}

/// Même principe que `_buildSignedInFakeSupabaseClient` de
/// `character_repository_rest_test.dart` : routage par nom de table,
/// session factice sans réseau, journal [recorded] de chaque requête.
/// [onRequest] (best-effort, jamais bloquant pour le test si absent) permet
/// d'observer/retarder une requête précise avant sa réponse — voir le
/// scénario de concurrence D33 ci-dessus.
Future<SupabaseClient> _buildSignedInFakeSupabaseClient({
  required String ownerId,
  required List<_Recorded> recorded,
  Map<String, List<Map<String, dynamic>>> tableRows = const {},
  bool Function(String method, String table)? failOn,
  String failureCode = 'XX000',
  Future<void> Function(http.Request request)? onRequest,
}) async {
  Future<http.Response> handler(http.Request request) async {
    final table = request.url.pathSegments.last;
    recorded.add(
      _Recorded(
        method: request.method,
        table: table,
        query: request.url.queryParameters,
        body: request.body.isEmpty ? null : jsonDecode(request.body),
      ),
    );
    await onRequest?.call(request);
    if (failOn != null && failOn(request.method, table)) {
      return http.Response(
        jsonEncode({'message': 'erreur simulée', 'code': failureCode}),
        failureCode == 'XX000' ? 500 : 403,
        request: request,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
    final rows = tableRows[table] ?? const <Map<String, dynamic>>[];
    return http.Response(
      jsonEncode(request.method == 'GET' ? rows : const <Object>[]),
      200,
      request: request,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  final client = SupabaseClient(
    'https://fake.supabase.test',
    'fake-anon-key',
    httpClient: MockClient(handler),
    postgrestOptions: const PostgrestClientOptions(retryEnabled: false),
    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
  );

  await client.auth.recoverSession(
    jsonEncode({
      'access_token': 'fake-access-token-$ownerId',
      'token_type': 'bearer',
      'user': {'id': ownerId},
    }),
  );

  return client;
}

/// Client dont chaque requête lève une [TimeoutException] — simule le
/// scénario D12 (`TimeoutHttpClient`), même principe que
/// `_buildSignedInFakeSupabaseClient(throwTimeoutOnRequest: true)` de
/// `character_repository_test.dart`.
Future<SupabaseClient> _buildSignedInTimeoutClient({
  required String ownerId,
}) async {
  Future<http.Response> handler(http.Request request) async {
    throw TimeoutException('Requête expirée (double de test).');
  }

  final client = SupabaseClient(
    'https://fake.supabase.test',
    'fake-anon-key',
    httpClient: MockClient(handler),
    postgrestOptions: const PostgrestClientOptions(retryEnabled: false),
    authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
  );

  await client.auth.recoverSession(
    jsonEncode({
      'access_token': 'fake-access-token-$ownerId',
      'token_type': 'bearer',
      'user': {'id': ownerId},
    }),
  );

  return client;
}
