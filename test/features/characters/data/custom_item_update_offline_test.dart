// P7 PR 4 : modification / enrichissement d'un objet personnalisé existant
// (`updateCustomInventoryItem`) en ligne ET hors ligne (file `inventoryItem`,
// op `updateCustom`) : colonnes exactes de l'UPDATE (NULL explicites), CA
// recalculée, harmonisation remise à faux, enfilage, remplacement, fusion avec
// un ajout, rejeu, payload invalide supprimé, ligne supprimée (abandon +
// alerte), anciens payloads. Dépôt réel + file drift en mémoire + synchroniseur
// réel + faux serveur PostgREST du harnais.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/cache/app_database.dart'
    hide PendingCharacterWrite;
import 'package:personnages/core/cache/pending_character_write_queue.dart';
import 'package:personnages/core/cache/reference_data_cache.dart';
import 'package:personnages/core/cache/sync_alert_store.dart';
import 'package:personnages/features/characters/data/character_detail_cache.dart';
import 'package:personnages/features/characters/data/character_repository.dart';
import 'package:personnages/features/characters/data/pending_character_write_syncer.dart';
import 'package:personnages/features/characters/data/sync_alert_recorder.dart';
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

const _lightArmor = CustomItemEnrichment(
  kind: CustomItemKinds.armor,
  acBase: 12,
  armorCategory: CustomArmorCategories.light,
);

const _heavyArmor = CustomItemEnrichment(
  kind: CustomItemKinds.armor,
  acBase: 16,
  armorCategory: CustomArmorCategories.heavy,
  magicBonus: 1,
  weight: 20,
);

const _weapon = CustomItemEnrichment(
  kind: CustomItemKinds.weapon,
  weaponCategory: CustomWeaponCategories.martial,
  weaponRange: CustomWeaponRanges.melee,
);

Map<String, dynamic> _armorRow({bool attuned = false, bool requires = false}) =>
    {
      'id': _srv1,
      'character_id': _characterId,
      'item_id': null,
      'custom_name': 'Cuir clouté',
      'quantity': 1,
      'equipped': true,
      'weapon_slot': null,
      'is_attuned': attuned,
      'custom_kind': 'armure',
      'custom_ac_base': 12,
      'custom_armor_category': 'legere',
      'custom_requires_attunement': requires,
    };

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
    rows = [_armorRow()];
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

  Future<WriteOutcome> update(
    CustomItemEnrichment enrichment, {
    String name = 'Cuir clouté',
    String? description,
    String? damageDice,
    String? damageType,
    List<String> properties = const [],
    String id = _srv1,
  }) => repository.updateCustomInventoryItem(
    characterId: _characterId,
    inventoryId: id,
    customName: name,
    enrichment: enrichment,
    description: description,
    damageDice: damageDice,
    damageType: damageType,
    properties: properties,
  );

  group('écriture en ligne', () {
    test('un seul UPDATE filtré id + personnage avec TOUTES les colonnes '
        'custom_*, quantité non touchée', () async {
      await reopen();

      final outcome = await update(
        _heavyArmor,
        name: 'Plate runique',
        description: 'Gravée',
      );

      expect(outcome, WriteOutcome.synced);
      final write = inventoryWrites().single;
      expect(write.method, 'PATCH');
      expect(write.query['id'], 'eq.$_srv1');
      expect(write.query['character_id'], 'eq.$_characterId');
      expect(write.body, {
        'custom_name': 'Plate runique',
        'custom_description': 'Gravée',
        'custom_damage_dice': null,
        'custom_damage_type': null,
        'custom_properties': null,
        'custom_kind': 'armure',
        'custom_magic_bonus': 1,
        'custom_weight': 20,
        'custom_requires_attunement': false,
        'custom_weapon_category': null,
        'custom_weapon_range': null,
        'custom_ac_base': 16,
        'custom_armor_category': 'lourde',
        'is_attuned': false,
      });
      expect((write.body! as Map).containsKey('quantity'), isFalse);
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });

    test('armure -> arme : custom_ac_base et custom_armor_category '
        'envoyés à NULL (jamais omis)', () async {
      await reopen();

      await update(
        _weapon,
        name: 'Lame',
        damageDice: '1d8',
        damageType: 'tranchant',
        properties: const ['finesse'],
      );

      final body = inventoryWrites().single.body! as Map;
      expect(body.containsKey('custom_ac_base'), isTrue);
      expect(body['custom_ac_base'], isNull);
      expect(body.containsKey('custom_armor_category'), isTrue);
      expect(body['custom_armor_category'], isNull);
      expect(body['custom_kind'], 'arme');
      expect(body['custom_weapon_category'], 'guerre');
      expect(body['custom_damage_dice'], '1d8');
      expect(body['custom_damage_type'], 'tranchant');
      expect(body['custom_properties'], ['finesse']);
      // La ligne du serveur est bien cohérente avec les CHECK.
      expect(rows.single['custom_ac_base'], isNull);
      expect(rows.single['custom_armor_category'], isNull);
    });

    test('un objet qui n\'est pas une arme perd dés, dégâts et propriétés '
        'même si l\'appelant les passe', () async {
      await reopen();

      await update(
        _lightArmor,
        damageDice: '1d6',
        damageType: 'feu',
        properties: const ['légère'],
      );

      final body = inventoryWrites().single.body! as Map;
      expect(body['custom_damage_dice'], isNull);
      expect(body['custom_damage_type'], isNull);
      expect(body['custom_properties'], isNull);
    });

    test('la CA calculée suit l\'édition d\'une armure équipée : 12 -> 17 '
        '(16 + 1 magique)', () async {
      expect((await reopen()).armorClass, 12);

      await update(_heavyArmor);

      expect((await reopen()).armorClass, 17);
    });

    test('ne requiert plus l\'harmonisation : is_attuned remis à faux dans '
        'la même requête', () async {
      rows
        ..clear()
        ..add(_armorRow(attuned: true, requires: true));
      await reopen();

      await update(_lightArmor);

      final body = inventoryWrites().single.body! as Map;
      expect(body['custom_requires_attunement'], false);
      expect(body['is_attuned'], false);
      expect(rows.single['is_attuned'], false);
    });

    test('requiert l\'harmonisation : l\'objet reste non harmonisé, '
        'is_attuned n\'est pas écrit', () async {
      await reopen();

      await update(
        const CustomItemEnrichment(
          kind: CustomItemKinds.armor,
          acBase: 12,
          armorCategory: CustomArmorCategories.light,
          requiresAttunement: true,
        ),
      );

      final body = inventoryWrites().single.body! as Map;
      expect(body['custom_requires_attunement'], true);
      expect(body.containsKey('is_attuned'), isFalse);
      expect(rows.single['is_attuned'], false);
    });

    test('validations : nom vide, enrichissement incohérent -> '
        'CharacterFailure, rien écrit ni en file', () async {
      await reopen();

      await expectLater(
        update(_lightArmor, name: '  '),
        throwsA(isA<CharacterFailure>()),
      );
      await expectLater(
        update(const CustomItemEnrichment(kind: CustomItemKinds.armor)),
        throwsA(isA<CharacterFailure>()),
      );
      await expectLater(
        update(_lightArmor, name: 'a' * 201),
        throwsA(isA<CharacterFailure>()),
      );
      expect(server.writes, isEmpty);
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });

    test('refus du serveur (42501) : échec, rien en file', () async {
      await reopen();
      rows.clear();

      await expectLater(update(_lightArmor), throwsA(isA<CharacterFailure>()));

      expect(await queue.allForOwner(_ownerA), isEmpty);
    });
  });

  group('hors ligne', () {
    test('enfilage : payload instantané, superposition immédiate, CA '
        'recalculée localement', () async {
      await reopen();
      goOffline();

      final outcome = await update(_heavyArmor, name: 'Plate runique');

      expect(outcome, WriteOutcome.queued);
      final line = (await lines()).single;
      expect(line.targetId, _srv1);
      expect(line.payload, {
        'op': 'updateCustom',
        'customName': 'Plate runique',
        'customKind': 'armure',
        'customMagicBonus': 1,
        'customWeight': 20,
        'customAcBase': 16,
        'customArmorCategory': 'lourde',
      });
      final detail = await reopen();
      final item = detail.inventory.single;
      expect(item.name, 'Plate runique');
      expect(item.armorProperties!.acBase, 16);
      expect(item.magicBonus, 1);
      expect(item.unitWeight, 20);
      expect(item.equipped, isTrue);
      expect(detail.armorClass, 17);
    });

    test(
      'hors ligne, armure -> arme : la superposition n\'a plus de CA',
      () async {
        await reopen();
        goOffline();

        await update(
          _weapon,
          name: 'Lame',
          damageDice: '1d8',
          damageType: 'feu',
        );

        final item = (await reopen()).inventory.single;
        expect(item.customKind, 'arme');
        expect(item.armorProperties, isNull);
        expect(item.customAcBase, isNull);
        expect(item.weaponProperties!.damageDice, '1d8');
      },
    );

    test('une 2e modification REMPLACE la 1re : une seule ligne en file, '
        'une seule requête au rejeu, dernière écriture gagnante', () async {
      await reopen();
      goOffline();
      await update(_heavyArmor, name: 'Première');
      clock = clock.add(const Duration(seconds: 5));
      await update(
        _weapon,
        name: 'Seconde',
        damageDice: '1d6',
        damageType: 'feu',
      );

      final queued = await lines();
      expect(queued, hasLength(1));
      expect(queued.single.payload['customName'], 'Seconde');
      expect(queued.single.payload['customKind'], 'arme');
      goOnline();

      expect(await syncer.sync(), {_characterId});

      final write = inventoryWrites().single;
      expect((write.body! as Map)['custom_name'], 'Seconde');
      expect((write.body! as Map)['custom_ac_base'], isNull);
      expect(await queue.allForOwner(_ownerA), isEmpty);
      expect(rows.single['custom_name'], 'Seconde');
      expect(rows.single['custom_kind'], 'arme');
    });

    test(
      'rejeu : UPDATE avec NULL explicites, cache de la fiche à jour',
      () async {
        await reopen();
        goOffline();
        await update(
          _weapon,
          name: 'Lame',
          damageDice: '1d8',
          damageType: 'feu',
        );
        goOnline();

        expect(await syncer.sync(), {_characterId});

        final body = inventoryWrites().single.body! as Map;
        expect(body['custom_ac_base'], isNull);
        expect(body.containsKey('custom_armor_category'), isTrue);
        expect(body['custom_kind'], 'arme');
        expect(await queue.allForOwner(_ownerA), isEmpty);
        final cached = await CharacterDetailCache(cache)
            .readRow(ownerId: _ownerA, characterId: _characterId);
        final cachedLine =
            (cached!['character_inventory'] as List).single as Map;
        expect(cachedLine['custom_kind'], 'arme');
        expect(cachedLine['custom_ac_base'], isNull);
      },
    );

    test('hors ligne : ne requiert plus l\'harmonisation -> l\'objet n\'est '
        'plus harmonisé (superposition et rejeu)', () async {
      rows
        ..clear()
        ..add(_armorRow(attuned: true, requires: true));
      await reopen();
      goOffline();

      await update(_lightArmor);

      final item = (await reopen()).inventory.single;
      expect(item.isAttuned, isFalse);
      expect(item.requiresAttunement, isFalse);
      goOnline();
      await syncer.sync();
      expect(rows.single['is_attuned'], false);
    });

    test(
      'un réglage d\'harmonisation en file est lui aussi remis à faux',
      () async {
        rows
          ..clear()
          ..add(_armorRow(requires: true));
        await reopen();
        goOffline();
        await repository.setInventoryItemAttuned(
          characterId: _characterId,
          inventoryId: _srv1,
          attuned: true,
        );

        await update(_lightArmor);
        goOnline();
        await syncer.sync();

        expect(rows.single['is_attuned'], false);
        expect(await queue.allForOwner(_ownerA), isEmpty);
      },
    );

    test('un usage en file est conservé : quantité fusionnée dans la '
        'modification, une seule ligne', () async {
      rows.single['quantity'] = 3;
      await reopen();
      goOffline();
      await repository.useInventoryItem(
        characterId: _characterId,
        inventoryId: _srv1,
        newQuantity: 2,
      );

      await update(_heavyArmor, name: 'Plate');

      final line = (await lines()).single;
      expect(line.payload['op'], 'updateCustom');
      expect(line.payload['quantity'], 2);
      expect(line.payload['base'], 3);
      expect((await reopen()).inventory.single.quantity, 2);
      goOnline();
      await syncer.sync();
      expect(rows.single['quantity'], 2);
      expect(rows.single['custom_name'], 'Plate');
    });

    test('un usage APRÈS la modification en file : fusionné aussi', () async {
      rows.single['quantity'] = 3;
      await reopen();
      goOffline();
      await update(_heavyArmor, name: 'Plate');

      await repository.useInventoryItem(
        characterId: _characterId,
        inventoryId: _srv1,
        newQuantity: 1,
      );

      final line = (await lines()).single;
      expect(line.payload['op'], 'updateCustom');
      expect(line.payload['quantity'], 1);
      goOnline();
      await syncer.sync();
      expect(rows.single['quantity'], 1);
      expect(rows.single['custom_name'], 'Plate');
    });

    test('équiper une ligne dont la modification est en file : réglage '
        'd\'état indépendant, les deux sont rejoués', () async {
      rows.single['equipped'] = false;
      await reopen();
      goOffline();
      await update(_heavyArmor, name: 'Plate');

      await repository.setInventoryItemEquipped(
        characterId: _characterId,
        inventoryId: _srv1,
        equipped: true,
      );

      expect((await lines()).single.payload['op'], 'updateCustom');
      expect(await queue.allForOwner(_ownerA), hasLength(2));
      goOnline();
      await syncer.sync();
      expect(rows.single['equipped'], true);
      expect(rows.single['custom_name'], 'Plate');
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });

    test('modification d\'une ligne dont l\'AJOUT est en file : fusionnée '
        'dans l\'ajout (un seul INSERT, aucun UPDATE)', () async {
      await reopen();
      goOffline();
      await repository.addCustomInventoryItem(
        characterId: _characterId,
        customName: 'Dague',
        quantity: 2,
        damageDice: '1d4',
        damageType: 'perforant',
        enrichment: _weapon,
      );
      final id = (await lines()).single.targetId;
      clock = clock.add(const Duration(seconds: 5));

      final outcome = await update(_heavyArmor, name: 'Plate', id: id);

      expect(outcome, WriteOutcome.queued);
      final line = (await lines()).single;
      expect(line.payload['op'], 'add');
      expect(line.payload['customName'], 'Plate');
      expect(line.payload['quantity'], 2);
      expect(line.payload['customKind'], 'armure');
      expect(line.payload.containsKey('customDamageDice'), isFalse);
      // Réseau revenu : l'INSERT part (jamais un UPDATE sur zéro ligne).
      goOnline();
      await syncer.sync();
      final writes = inventoryWrites();
      expect(writes.single.method, 'POST');
      expect((writes.single.body! as Map)['custom_name'], 'Plate');
      expect((writes.single.body! as Map)['custom_ac_base'], 16);
    });

    test(
      'modification d\'une ligne dont le retrait est en file : refus',
      () async {
        await reopen();
        goOffline();
        await repository.removeInventoryItem(
          characterId: _characterId,
          inventoryId: _srv1,
        );

        await expectLater(
          update(_heavyArmor),
          throwsA(isA<CharacterFailure>()),
        );

        expect((await lines()).single.payload['op'], 'delete');
      },
    );

    test('erreur de transport en ligne : mise en file', () async {
      await reopen();
      server.failBefore(1);
      final outcome = await update(_heavyArmor);

      expect(outcome, WriteOutcome.queued);
      expect((await lines()).single.payload['op'], 'updateCustom');
    });
  });

  group('rejeu : validation et ligne supprimée', () {
    Future<void> enqueueRaw(Map<String, dynamic> payload) => queue.enqueue(
      characterId: _characterId,
      ownerId: _ownerA,
      kind: PendingCharacterWriteKind.inventoryItem,
      targetId: _srv1,
      payload: payload,
    );

    final invalid = <String, Map<String, dynamic>>{
      'armure sans CA': {
        'op': 'updateCustom',
        'customName': 'X',
        'customKind': 'armure',
        'customArmorCategory': 'legere',
      },
      'nom vide': {'op': 'updateCustom', 'customName': ''},
      'nom trop long': {'op': 'updateCustom', 'customName': 'a' * 201},
      'bonus magique sur un autre objet': {
        'op': 'updateCustom',
        'customName': 'X',
        'customKind': 'autre',
        'customMagicBonus': 2,
      },
      'kind inconnu': {
        'op': 'updateCustom',
        'customName': 'X',
        'customKind': 'potion',
      },
    };
    for (final entry in invalid.entries) {
      test('payload invalide (${entry.key}) : SUPPRIMÉ, aucune écriture, '
          'les autres lignes rejouées', () async {
        await enqueueRaw(entry.value);
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
        expect(rows.single['custom_name'], 'Cuir clouté');
      });
    }

    test('ligne supprimée entre-temps : no-op remonté, abandon au seuil puis '
        'alerte « votre inventaire »', () async {
      await reopen();
      goOffline();
      await update(_heavyArmor);
      rows.clear();
      goOnline();

      for (
        var i = 0;
        i < PendingCharacterWriteQueue.abandonAfterConsecutiveFailures;
        i++
      ) {
        await syncer.syncWithReport();
      }

      expect(await queue.allForOwner(_ownerA), isEmpty);
      expect(rows, isEmpty);
      final recorder = SyncAlertRecorder(
        db,
        queue,
        SyncAlertStore(db),
        CharacterDetailCache(cache),
      );
      final alerts = await recorder.recordAbandoned(_ownerA);
      expect(alerts.single.kindKey, 'inventory_item');
      expect(alerts.single.message, contains('votre inventaire'));
    });

    test(
      'ancien payload add (sans enrichissement) : toujours rejoué',
      () async {
        await queue.enqueue(
          characterId: _characterId,
          ownerId: _ownerA,
          kind: PendingCharacterWriteKind.inventoryItem,
          targetId: '22222222-2222-4222-8222-222222222222',
          payload: {'op': 'add', 'customName': 'Dague', 'quantity': 1},
        );

        expect(await syncer.sync(), {_characterId});

        final body = inventoryWrites().single.body! as Map;
        expect(body['custom_name'], 'Dague');
        expect(body.containsKey('custom_kind'), isFalse);
      },
    );

    test('payload valide minimal (aucune clé d\'enrichissement) : toutes '
        'les colonnes custom_* remises à NULL', () async {
      await enqueueRaw({'op': 'updateCustom', 'customName': 'Caillou'});

      expect(await syncer.sync(), {_characterId});

      final body = inventoryWrites().single.body! as Map;
      expect(body['custom_name'], 'Caillou');
      expect(body['custom_kind'], isNull);
      expect(body['custom_ac_base'], isNull);
      expect(body['custom_armor_category'], isNull);
    });
  });
}
