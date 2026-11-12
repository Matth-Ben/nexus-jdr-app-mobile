// P7 PR 3 : ajout d'une armure ou d'un bouclier personnalisé en ligne ET hors
// ligne (file `inventoryItem`) : colonnes écrites (jamais de catégorie
// d'armure pour un bouclier), validation à l'enfilage et au rejeu,
// superposition dans la fiche (CA calculée), rejeu. Dépôt réel + file drift en
// mémoire + synchroniseur réel + faux serveur PostgREST du harnais.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/cache/app_database.dart'
    hide PendingCharacterWrite;
import 'package:personnages/core/cache/pending_character_write_queue.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/data/pending_character_write_syncer.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_failure.dart';
import 'package:personnages/features/characters/domain/custom_item_enrichment.dart';
import 'package:personnages/features/characters/domain/write_outcome.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../support/fake_character_write_server.dart';
import '../../../support/fake_connectivity_checker.dart';

const _characterId = 'char-1';
const _ownerA = 'owner-1';
const _srv1 = '11111111-1111-4111-8111-111111111111';
const _table = 'character_inventory';

const _heavyArmor = CustomItemEnrichment(
  kind: CustomItemKinds.armor,
  acBase: 16,
  armorCategory: CustomArmorCategories.heavy,
  magicBonus: 2,
  weight: 20,
);

const _shield = CustomItemEnrichment(
  kind: CustomItemKinds.shield,
  acBase: 3,
  magicBonus: 1,
);

void main() {
  var clock = DateTime.utc(2026, 11, 12, 12);
  late AppDatabase db;
  late PendingCharacterWriteQueue queue;
  late ReferenceDataCache cache;
  late FakeConnectivityChecker connectivity;
  late FakeCharacterWriteServer server;
  late SupabaseClient client;
  late SupabaseCharacterRepository repository;
  late PendingCharacterWriteSyncer syncer;
  late List<Map<String, dynamic>> rows;

  setUp(() async {
    clock = DateTime.utc(2026, 11, 12, 12);
    db = AppDatabase(NativeDatabase.memory());
    queue = PendingCharacterWriteQueue(db, now: () => clock);
    cache = ReferenceDataCache(db);
    connectivity = FakeConnectivityChecker();
    rows = [
      {
        'id': _srv1,
        'character_id': _characterId,
        'item_id': null,
        'custom_name': 'Dague',
        'quantity': 1,
        'equipped': false,
        'weapon_slot': null,
        'is_attuned': false,
      },
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
          {'ability_id': 'dex', 'score': 10},
        ],
        _table: rows,
      },
    );
    server.tables[_table] = rows;
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
      if (line.kind == PendingCharacterWriteKind.inventoryItem) line,
  ];

  List<RecordedRequest> inventoryWrites() => [
    for (final w in server.writes)
      if (w.table == _table) w,
  ];

  Future<CharacterDetail> reopen() =>
      repository.fetchCharacterDetail(_characterId);

  group('ajout en ligne', () {
    test(
      'armure : custom_kind, CA, catégorie, bonus, poids ; rien de nul',
      () async {
        await reopen();

        final outcome = await repository.addCustomInventoryItem(
          characterId: _characterId,
          customName: 'Plate runique',
          quantity: 1,
          enrichment: _heavyArmor,
        );

        expect(outcome, WriteOutcome.synced);
        final body = inventoryWrites().single.body! as Map;
        expect(body['custom_kind'], 'armure');
        expect(body['custom_ac_base'], 16);
        expect(body['custom_armor_category'], 'lourde');
        expect(body['custom_magic_bonus'], 2);
        expect(body['custom_weight'], 20);
        expect(body.values.contains(null), isFalse);
        expect(await queue.allForOwner(_ownerA), isEmpty);
      },
    );

    test(
      'bouclier : custom_kind et CA, JAMAIS custom_armor_category',
      () async {
        await reopen();

        await repository.addCustomInventoryItem(
          characterId: _characterId,
          customName: 'Égide',
          quantity: 1,
          enrichment: _shield,
        );

        final body = inventoryWrites().single.body! as Map;
        expect(body['custom_kind'], 'bouclier');
        expect(body['custom_ac_base'], 3);
        expect(body['custom_magic_bonus'], 1);
        expect(body.containsKey('custom_armor_category'), isFalse);
        expect(body.values.contains(null), isFalse);
      },
    );
  });

  group('validation à l\'enfilage', () {
    final bad = <String, CustomItemEnrichment>{
      'armure sans CA': const CustomItemEnrichment(
        kind: CustomItemKinds.armor,
        armorCategory: CustomArmorCategories.light,
      ),
      'armure sans catégorie': const CustomItemEnrichment(
        kind: CustomItemKinds.armor,
        acBase: 12,
      ),
      'bouclier sans CA': const CustomItemEnrichment(
        kind: CustomItemKinds.shield,
      ),
      'bouclier avec une catégorie d\'armure': const CustomItemEnrichment(
        kind: CustomItemKinds.shield,
        acBase: 2,
        armorCategory: CustomArmorCategories.heavy,
      ),
      'CA 31': const CustomItemEnrichment(
        kind: CustomItemKinds.armor,
        acBase: 31,
        armorCategory: CustomArmorCategories.heavy,
      ),
      'bonus magique 4': const CustomItemEnrichment(
        kind: CustomItemKinds.shield,
        acBase: 2,
        magicBonus: 4,
      ),
    };
    for (final entry in bad.entries) {
      test(
        '${entry.key} : refusé hors ligne, rien en file ni en réseau',
        () async {
          goOffline();

          await expectLater(
            repository.addCustomInventoryItem(
              characterId: _characterId,
              customName: 'Objet',
              quantity: 1,
              enrichment: entry.value,
            ),
            throwsA(isA<CharacterFailure>()),
          );

          expect(await queue.allForOwner(_ownerA), isEmpty);
          expect(server.writes, isEmpty);
        },
      );
    }
  });

  group('ajout hors ligne', () {
    test('payload d\'armure, superposition (armorProperties) et CA calculée '
        'une fois équipée : 16 + 2 magique = 18', () async {
      await reopen();
      goOffline();

      final outcome = await repository.addCustomInventoryItem(
        characterId: _characterId,
        customName: 'Plate runique',
        quantity: 1,
        enrichment: _heavyArmor,
      );

      expect(outcome, WriteOutcome.queued);
      final line = (await lines()).single;
      expect(line.payload, {
        'op': 'add',
        'customName': 'Plate runique',
        'quantity': 1,
        'customKind': 'armure',
        'customMagicBonus': 2,
        'customWeight': 20,
        'customAcBase': 16,
        'customArmorCategory': 'lourde',
      });
      final item = (await reopen()).inventory.singleWhere(
        (i) => i.id == line.targetId,
      );
      expect(item.customKind, 'armure');
      expect(item.armorProperties!.acBase, 16);
      expect(item.armorProperties!.acDexBonus, 'aucun');
      expect(item.armorProperties!.slot, 'armure');
      expect(item.magicBonus, 2);
      expect(item.unitWeight, 20);

      // Non équipée : CA de base 10 + Dex 0.
      expect((await reopen()).armorClass, 10);
      await repository.setInventoryItemEquipped(
        characterId: _characterId,
        inventoryId: line.targetId,
        equipped: true,
      );
      expect((await reopen()).armorClass, 18);
    });

    test('payload de bouclier : pas de customArmorCategory ; équipé, +3 +1 '
        '= 14', () async {
      await reopen();
      goOffline();

      await repository.addCustomInventoryItem(
        characterId: _characterId,
        customName: 'Égide',
        quantity: 1,
        enrichment: _shield,
      );

      final line = (await lines()).single;
      expect(line.payload, {
        'op': 'add',
        'customName': 'Égide',
        'quantity': 1,
        'customKind': 'bouclier',
        'customMagicBonus': 1,
        'customAcBase': 3,
      });
      await repository.setInventoryItemEquipped(
        characterId: _characterId,
        inventoryId: line.targetId,
        equipped: true,
      );
      expect((await reopen()).armorClass, 14);
    });

    test('rejeu : INSERT avec CA et catégorie, puis la fiche serveur '
        'recalcule la même CA', () async {
      await reopen();
      goOffline();
      await repository.addCustomInventoryItem(
        characterId: _characterId,
        customName: 'Plate runique',
        quantity: 1,
        enrichment: _heavyArmor,
      );
      final id = (await lines()).single.targetId;
      goOnline();

      expect(await syncer.sync(), {_characterId});

      final body = inventoryWrites().single.body! as Map;
      expect(body['id'], id);
      expect(body['custom_kind'], 'armure');
      expect(body['custom_ac_base'], 16);
      expect(body['custom_armor_category'], 'lourde');
      expect(body['custom_magic_bonus'], 2);
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });

    test('rejeu d\'un bouclier : aucune catégorie d\'armure écrite', () async {
      await reopen();
      goOffline();
      await repository.addCustomInventoryItem(
        characterId: _characterId,
        customName: 'Égide',
        quantity: 1,
        enrichment: _shield,
      );
      goOnline();

      expect(await syncer.sync(), {_characterId});

      final body = inventoryWrites().single.body! as Map;
      expect(body['custom_kind'], 'bouclier');
      expect(body['custom_ac_base'], 3);
      expect(body.containsKey('custom_armor_category'), isFalse);
    });
  });

  group('validation au rejeu', () {
    final bad = <String, Map<String, dynamic>>{
      'bouclier avec catégorie d\'armure': {
        'customKind': 'bouclier',
        'customAcBase': 2,
        'customArmorCategory': 'lourde',
      },
      'armure sans catégorie': {'customKind': 'armure', 'customAcBase': 12},
      'armure sans CA': {
        'customKind': 'armure',
        'customArmorCategory': 'legere',
      },
      'bouclier sans CA': {'customKind': 'bouclier'},
      'CA négative': {
        'customKind': 'armure',
        'customAcBase': -1,
        'customArmorCategory': 'legere',
      },
      'CA texte': {'customKind': 'bouclier', 'customAcBase': '2'},
    };
    for (final entry in bad.entries) {
      test('${entry.key} : aucune écriture, ligne supprimée, les autres '
          'lignes sont rejouées', () async {
        await queue.enqueue(
          characterId: _characterId,
          ownerId: _ownerA,
          kind: PendingCharacterWriteKind.inventoryItem,
          targetId: _srv1.replaceFirst('1111', '2222'),
          payload: {
            'op': 'add',
            'customName': 'Objet',
            'quantity': 1,
            ...entry.value,
          },
        );
        clock = clock.add(const Duration(seconds: 5));
        await queue.enqueue(
          characterId: _characterId,
          ownerId: _ownerA,
          kind: PendingCharacterWriteKind.xp,
          targetId: '',
          payload: {'newXp': 250},
        );

        final synced = await syncer.sync();

        expect(synced, {_characterId});
        expect(await queue.allForOwner(_ownerA), isEmpty);
        expect(server.characterRow['xp'], 250);
        expect(inventoryWrites(), isEmpty);
        expect(rows, hasLength(1));
      });
    }

    test('payload valide d\'armure : rejoué tel quel', () async {
      await queue.enqueue(
        characterId: _characterId,
        ownerId: _ownerA,
        kind: PendingCharacterWriteKind.inventoryItem,
        targetId: '22222222-2222-4222-8222-222222222222',
        payload: {
          'op': 'add',
          'customName': 'Cuir clouté',
          'quantity': 1,
          'customKind': 'armure',
          'customAcBase': 12,
          'customArmorCategory': 'legere',
        },
      );

      expect(await syncer.sync(), {_characterId});

      final body = inventoryWrites().single.body! as Map;
      expect(body['custom_ac_base'], 12);
      expect(body['custom_armor_category'], 'legere');
    });
  });
}
