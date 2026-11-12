// P7 PR 2 : ajout d'un objet personnalisé enrichi (type, bonus magique, poids,
// harmonisation, catégorie/portée d'arme) en ligne ET hors ligne (file
// `inventoryItem`), validations à l'enfilage ET au rejeu, ancien payload
// rejouable. Dépôt réel + file drift en mémoire + synchroniseur réel + faux
// serveur PostgREST du harnais (`test/support/`).

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

const _weapon = CustomItemEnrichment(
  kind: CustomItemKinds.weapon,
  magicBonus: 2,
  weight: 1.5,
  requiresAttunement: true,
  weaponCategory: CustomWeaponCategories.martial,
  weaponRange: CustomWeaponRanges.melee,
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
    test('arme enrichie : colonnes custom_* dans l\'INSERT, rien de nul, '
        'harmonisée maintenant -> is_attuned', () async {
      await reopen();

      final outcome = await repository.addCustomInventoryItem(
        characterId: _characterId,
        customName: 'Lame solaire',
        quantity: 1,
        damageDice: '1d8',
        damageType: 'radiant',
        enrichment: const CustomItemEnrichment(
          kind: CustomItemKinds.weapon,
          magicBonus: 2,
          weight: 1.5,
          requiresAttunement: true,
          weaponCategory: CustomWeaponCategories.martial,
          weaponRange: CustomWeaponRanges.melee,
          attuneNow: true,
        ),
      );

      expect(outcome, WriteOutcome.synced);
      final body = inventoryWrites().single.body! as Map;
      expect(body['custom_kind'], 'arme');
      expect(body['custom_magic_bonus'], 2);
      expect(body['custom_weight'], 1.5);
      expect(body['custom_requires_attunement'], isTrue);
      expect(body['custom_weapon_category'], 'guerre');
      expect(body['custom_weapon_range'], 'melee');
      expect(body['is_attuned'], isTrue);
      expect(body.containsKey('custom_ac_base'), isFalse);
      expect(body.containsKey('custom_armor_category'), isFalse);
      expect(body.values.contains(null), isFalse);
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });

    test('« Harmoniser maintenant » sans harmonisation requise : ignoré, bonus '
        'nul et harmonisation non écrits', () async {
      await reopen();

      await repository.addCustomInventoryItem(
        characterId: _characterId,
        customName: 'Cuillère',
        quantity: 1,
        enrichment: const CustomItemEnrichment(
          kind: CustomItemKinds.other,
          attuneNow: true,
        ),
      );

      final body = inventoryWrites().single.body! as Map;
      expect(body['custom_kind'], 'autre');
      expect(body.containsKey('is_attuned'), isFalse);
      expect(body.containsKey('custom_magic_bonus'), isFalse);
      expect(body.containsKey('custom_requires_attunement'), isFalse);
      expect(body.containsKey('custom_weight'), isFalse);
    });
  });

  group('validation à l\'enfilage', () {
    final bad = <String, CustomItemEnrichment>{
      'type inconnu': const CustomItemEnrichment(kind: 'epee'),
      'bonus 4': const CustomItemEnrichment(
        kind: CustomItemKinds.weapon,
        magicBonus: 4,
      ),
      'bonus négatif': const CustomItemEnrichment(
        kind: CustomItemKinds.weapon,
        magicBonus: -1,
      ),
      'bonus sur un objet « autre »': const CustomItemEnrichment(
        kind: CustomItemKinds.other,
        magicBonus: 1,
      ),
      'poids négatif': const CustomItemEnrichment(
        kind: CustomItemKinds.other,
        weight: -0.5,
      ),
      'poids 10000': const CustomItemEnrichment(
        kind: CustomItemKinds.other,
        weight: 10000,
      ),
      'catégorie d\'arme inconnue': const CustomItemEnrichment(
        kind: CustomItemKinds.weapon,
        weaponCategory: 'exotique',
      ),
      'portée inconnue': const CustomItemEnrichment(
        kind: CustomItemKinds.weapon,
        weaponRange: 'portee',
      ),
      'catégorie d\'arme sur un objet « autre »': const CustomItemEnrichment(
        kind: CustomItemKinds.other,
        weaponCategory: CustomWeaponCategories.martial,
      ),
      'portée d\'arme sans type': const CustomItemEnrichment(
        weaponRange: CustomWeaponRanges.melee,
      ),
      'armure sans CA': const CustomItemEnrichment(
        kind: CustomItemKinds.armor,
        armorCategory: CustomArmorCategories.light,
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
    test('payload, superposition dans la fiche (type, bonus, poids, '
        'harmonisation, catégorie, portée) et poids total', () async {
      await reopen();
      goOffline();

      final outcome = await repository.addCustomInventoryItem(
        characterId: _characterId,
        customName: 'Lame solaire',
        quantity: 3,
        damageDice: '1d8',
        damageType: 'radiant',
        enrichment: const CustomItemEnrichment(
          kind: CustomItemKinds.weapon,
          magicBonus: 2,
          weight: 1.5,
          requiresAttunement: true,
          weaponCategory: CustomWeaponCategories.martial,
          weaponRange: CustomWeaponRanges.ranged,
          attuneNow: true,
        ),
      );

      expect(outcome, WriteOutcome.queued);
      final line = (await lines()).single;
      expect(line.payload, {
        'op': 'add',
        'customName': 'Lame solaire',
        'quantity': 3,
        'customDamageDice': '1d8',
        'customDamageType': 'radiant',
        'customKind': 'arme',
        'customMagicBonus': 2,
        'customWeight': 1.5,
        'customRequiresAttunement': true,
        'customWeaponCategory': 'guerre',
        'customWeaponRange': 'distance',
        'attuned': true,
      });
      final item = (await reopen()).inventory.singleWhere(
        (i) => i.id == line.targetId,
      );
      expect(item.customKind, 'arme');
      expect(item.magicBonus, 2);
      expect(item.unitWeight, 1.5);
      expect(item.totalWeight, 4.5);
      expect(item.requiresAttunement, isTrue);
      expect(item.isAttuned, isTrue);
      expect(item.customWeaponCategory, 'guerre');
      expect(item.customWeaponRange, 'distance');
      expect(item.weaponProperties!.damageType, 'radiant');
    });

    test(
      'un réglage d\'état sur l\'ajout en file conserve l\'enrichissement',
      () async {
        goOffline();
        await repository.addCustomInventoryItem(
          characterId: _characterId,
          customName: 'Lame',
          quantity: 1,
          enrichment: _weapon,
        );
        final id = (await lines()).single.targetId;

        await repository.setInventoryItemAttuned(
          characterId: _characterId,
          inventoryId: id,
          attuned: true,
        );

        final payload = (await lines()).single.payload;
        expect(payload['customKind'], 'arme');
        expect(payload['customMagicBonus'], 2);
        expect(payload['attuned'], isTrue);
      },
    );

    test('rejeu : INSERT avec les colonnes custom_* et l\'id client', () async {
      await reopen();
      goOffline();
      await repository.addCustomInventoryItem(
        characterId: _characterId,
        customName: 'Lame',
        quantity: 1,
        enrichment: _weapon,
      );
      final id = (await lines()).single.targetId;
      goOnline();

      expect(await syncer.sync(), {_characterId});

      final body = inventoryWrites().single.body! as Map;
      expect(body['id'], id);
      expect(body['custom_kind'], 'arme');
      expect(body['custom_magic_bonus'], 2);
      expect(body['custom_weight'], 1.5);
      expect(body['custom_requires_attunement'], isTrue);
      expect(body['custom_weapon_category'], 'guerre');
      expect(body['custom_weapon_range'], 'melee');
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });
  });

  group('validation au rejeu', () {
    final bad = <String, Map<String, dynamic>>{
      'type inconnu': {'customKind': 'epee'},
      'type non texte': {'customKind': 3},
      'bonus 4': {'customKind': 'arme', 'customMagicBonus': 4},
      'bonus décimal': {'customKind': 'arme', 'customMagicBonus': 1.5},
      'bonus sur « autre »': {'customKind': 'autre', 'customMagicBonus': 1},
      'poids négatif': {'customWeight': -1},
      'poids 10000': {'customWeight': 10000},
      'poids texte': {'customWeight': '2'},
      'harmonisation non booléenne': {'customRequiresAttunement': 'oui'},
      'catégorie d\'arme inconnue': {'customWeaponCategory': 'exotique'},
      'portée inconnue': {'customWeaponRange': 'portee'},
      'catégorie d\'arme sur un objet « autre »': {
        'customKind': 'autre',
        'customWeaponCategory': 'guerre',
      },
      'portée d\'arme sans type': {'customWeaponRange': 'melee'},
      'CA hors bornes': {'customKind': 'bouclier', 'customAcBase': 31},
      'catégorie d\'armure inconnue': {'customArmorCategory': 'mithril'},
      'armure sans CA ni catégorie': {'customKind': 'armure'},
      'objet du catalogue avec colonnes custom': {
        'itemId': 3,
        'customKind': 'arme',
      },
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
            'customName': 'Lame',
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

    test('ancien payload (sans aucune clé d\'enrichissement) : rejoué sans '
        'erreur, INSERT sans colonne custom_kind', () async {
      await queue.enqueue(
        characterId: _characterId,
        ownerId: _ownerA,
        kind: PendingCharacterWriteKind.inventoryItem,
        targetId: '22222222-2222-4222-8222-222222222222',
        payload: {
          'op': 'add',
          'customName': 'Zanbato',
          'quantity': 2,
          'customDamageDice': '2d6',
          'customDamageType': 'tranchant',
        },
      );

      expect(await syncer.sync(), {_characterId});

      final body = inventoryWrites().single.body! as Map;
      expect(body['custom_name'], 'Zanbato');
      expect(body['custom_damage_dice'], '2d6');
      expect(body.keys.where((k) => k == 'custom_kind'), isEmpty);
      expect(body.keys.where((k) => k == 'custom_weight'), isEmpty);
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });
  });
}
