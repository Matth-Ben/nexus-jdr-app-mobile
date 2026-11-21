// Décision n° 37 (20/11/2026) : le dépôt refuse d'équiper une seconde armure
// ou un second bouclier, objets du catalogue comme personnalisés, EN LIGNE et
// HORS LIGNE (file d'attente), sans contournement par une écriture différée :
// la vérification porte sur l'état effectif de la fiche (cache + file), avant
// toute écriture ou mise en file. Dépôt réel + file drift en mémoire +
// synchroniseur réel + faux serveur PostgREST du harnais (`test/support/`).

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

import '../../../support/fake_character_write_server.dart';
import '../../../support/fake_connectivity_checker.dart';

const _characterId = 'char-1';
const _ownerA = 'owner-1';
const _table = 'character_inventory';

/// Objet du catalogue : ligne `character_inventory` + `items` embarqué.
Map<String, dynamic> _catalogRow(
  String id,
  int itemId,
  Map<String, dynamic> items, {
  bool equipped = false,
}) => {
  'id': id,
  'character_id': _characterId,
  'item_id': itemId,
  'quantity': 1,
  'equipped': equipped,
  'weapon_slot': null,
  'is_attuned': false,
  'items': items,
};

Map<String, dynamic> _armorItems(
  String category,
  int acBase,
  String dex, {
  String? slot,
}) => {
  'category': category,
  'requires_attunement': false,
  'armor_properties': {'ac_base': acBase, 'ac_dex_bonus': dex, 'slot': slot},
};

/// Objet personnalisé typé armure/bouclier.
Map<String, dynamic> _customRow(
  String id, {
  required String kind,
  required int acBase,
  String? category,
  bool equipped = false,
}) => {
  'id': id,
  'character_id': _characterId,
  'item_id': null,
  'custom_name': 'Perso $id',
  'quantity': 1,
  'equipped': equipped,
  'weapon_slot': null,
  'is_attuned': false,
  'custom_kind': kind,
  'custom_ac_base': acBase,
  'custom_armor_category': category,
};

Matcher _refused(CharacterErrorCode code) =>
    throwsA(isA<CharacterFailure>().having((f) => f.code, 'code', code));

void main() {
  var clock = DateTime.utc(2026, 11, 21, 12);
  late AppDatabase db;
  late PendingCharacterWriteQueue queue;
  late ReferenceDataCache cache;
  late FakeConnectivityChecker connectivity;
  late FakeCharacterWriteServer server;
  late SupabaseCharacterRepository repository;
  late PendingCharacterWriteSyncer syncer;
  late List<Map<String, dynamic>> rows;

  /// Inventaire : cotte de mailles (16) ÉQUIPÉE, armure de cuir (11),
  /// bouclier (2), Bouclier +2 magique (4), armure personnalisée lourde 18,
  /// bouclier personnalisé 3, anneau (sans propriétés d'armure).
  List<Map<String, dynamic>> inventory({bool chainMailEquipped = true}) => [
    _catalogRow(
      'inv-cotte',
      104,
      _armorItems('armure', 16, 'aucun'),
      equipped: chainMailEquipped,
    ),
    _catalogRow('inv-cuir', 101, _armorItems('armure', 11, 'illimite')),
    _catalogRow('inv-bouclier', 106, _armorItems('bouclier', 2, 'illimite')),
    _catalogRow(
      'inv-bouclier2',
      107,
      _armorItems('objet_magique', 4, 'illimite', slot: 'bouclier'),
    ),
    _customRow(
      'inv-plate',
      kind: CustomItemKinds.armor,
      acBase: 18,
      category: CustomArmorCategories.heavy,
    ),
    _customRow('inv-egide', kind: CustomItemKinds.shield, acBase: 3),
    _catalogRow('inv-anneau', 110, {
      'category': 'objet_magique',
      'requires_attunement': false,
      'ac_bonus': 1,
      'ac_bonus_kind': 'toujours',
    }),
  ];

  Future<void> setUpServer({bool chainMailEquipped = true}) async {
    rows = inventory(chainMailEquipped: chainMailEquipped);
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
          {'ability_id': 'dex', 'score': 14},
        ],
        _table: rows,
      },
    );
    server.tables[_table] = rows;
    final client = await buildSignedInClient(server, ownerId: _ownerA);
    repository = SupabaseCharacterRepository(
      client,
      cache,
      queue,
      connectivity,
    );
    syncer = PendingCharacterWriteSyncer(client, queue, cache, repository);
  }

  setUp(() async {
    clock = DateTime.utc(2026, 11, 21, 12);
    db = AppDatabase(NativeDatabase.memory());
    queue = PendingCharacterWriteQueue(db, now: () => clock);
    cache = ReferenceDataCache(db);
    connectivity = FakeConnectivityChecker();
    await setUpServer();
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

  Future<CharacterDetail> reopen() =>
      repository.fetchCharacterDetail(_characterId);

  Map<String, dynamic> row(String id) => rows.singleWhere((r) => r['id'] == id);

  List<RecordedRequest> inventoryWrites() => [
    for (final w in server.writes)
      if (w.table == _table) w,
  ];

  Future<WriteOutcome> equip(String id, {bool equipped = true}) =>
      repository.setInventoryItemEquipped(
        characterId: _characterId,
        inventoryId: id,
        equipped: equipped,
      );

  Future<List<PendingCharacterWrite>> queued(
    PendingCharacterWriteKind kind,
  ) async => [
    for (final line in await queue.allForOwner(_ownerA))
      if (line.kind == kind) line,
  ];

  group('en ligne', () {
    test('seconde armure du catalogue : refus, aucune écriture, rien en '
        'file', () async {
      await reopen();

      await expectLater(
        equip('inv-cuir'),
        _refused(CharacterErrorCode.armorAlreadyEquipped),
      );

      expect(inventoryWrites(), isEmpty);
      expect(await queue.allForOwner(_ownerA), isEmpty);
      expect(row('inv-cuir')['equipped'], false);
      expect((await reopen()).armorClass, 16);
    });

    test('armure PERSONNALISÉE face à une armure du catalogue équipée : '
        'refus', () async {
      await reopen();

      await expectLater(
        equip('inv-plate'),
        _refused(CharacterErrorCode.armorAlreadyEquipped),
      );
      expect(inventoryWrites(), isEmpty);
    });

    test('second bouclier, personnalisé ou magique, face à un bouclier '
        'équipé : refus', () async {
      row('inv-bouclier')['equipped'] = true;
      await reopen();

      for (final id in ['inv-egide', 'inv-bouclier2']) {
        await expectLater(
          equip(id),
          _refused(CharacterErrorCode.shieldAlreadyEquipped),
          reason: id,
        );
      }
      expect(inventoryWrites(), isEmpty);
    });

    test('bouclier du catalogue face à un bouclier PERSONNALISÉ équipé : '
        'refus', () async {
      row('inv-egide')['equipped'] = true;
      await reopen();

      await expectLater(
        equip('inv-bouclier'),
        _refused(CharacterErrorCode.shieldAlreadyEquipped),
      );
      expect(inventoryWrites(), isEmpty);
    });

    test('erreur de transport : le refus précède tout envoi, jamais de mise '
        'en file qui contournerait la règle', () async {
      await reopen();
      server.failBefore(1);

      await expectLater(
        equip('inv-cuir'),
        _refused(CharacterErrorCode.armorAlreadyEquipped),
      );
      expect(server.writes, isEmpty);
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });

    test('une armure et un bouclier ensemble : permis', () async {
      await reopen();

      expect(await equip('inv-egide'), WriteOutcome.synced);

      expect(row('inv-egide')['equipped'], true);
      expect((await reopen()).armorClass, 16 + 3);
    });

    test('objet hors emplacement (anneau) : jamais concerné', () async {
      row('inv-bouclier')['equipped'] = true;
      await reopen();

      expect(await equip('inv-anneau'), WriteOutcome.synced);
      expect(row('inv-anneau')['equipped'], true);
    });

    test('déséquiper puis équiper l\'autre : permis', () async {
      await reopen();

      expect(await equip('inv-cotte', equipped: false), WriteOutcome.synced);
      expect(await equip('inv-plate'), WriteOutcome.synced);

      expect(row('inv-cotte')['equipped'], false);
      expect(row('inv-plate')['equipped'], true);
      expect((await reopen()).armorClass, 18);
    });

    test('rééquiper l\'armure déjà équipée : jamais refusé', () async {
      await reopen();

      expect(await equip('inv-cotte'), WriteOutcome.synced);
    });
  });

  group('hors ligne (file d\'attente)', () {
    test('seconde armure : refus, rien en file', () async {
      await reopen();
      goOffline();

      await expectLater(
        equip('inv-cuir'),
        _refused(CharacterErrorCode.armorAlreadyEquipped),
      );
      await expectLater(
        equip('inv-plate'),
        _refused(CharacterErrorCode.armorAlreadyEquipped),
      );
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });

    test('une armure équipée HORS LIGNE (encore en file) bloque la suivante ; '
        'même chose pour les boucliers', () async {
      await setUpServer(chainMailEquipped: false);
      await reopen();
      goOffline();

      expect(await equip('inv-plate'), WriteOutcome.queued);
      await expectLater(
        equip('inv-cotte'),
        _refused(CharacterErrorCode.armorAlreadyEquipped),
      );
      expect(await equip('inv-bouclier'), WriteOutcome.queued);
      await expectLater(
        equip('inv-egide'),
        _refused(CharacterErrorCode.shieldAlreadyEquipped),
      );

      final lines = await queued(PendingCharacterWriteKind.inventoryState);
      expect(lines.map((l) => l.targetId).toSet(), {
        'inv-plate',
        'inv-bouclier',
      });
      expect((await reopen()).armorClass, 18 + 2);
    });

    test('déséquiper hors ligne puis équiper l\'autre : permis, état '
        'effectif cohérent, rejeu des deux', () async {
      await reopen();
      goOffline();

      expect(await equip('inv-cotte', equipped: false), WriteOutcome.queued);
      expect(await equip('inv-plate'), WriteOutcome.queued);

      final detail = await reopen();
      expect(
        detail.inventory.singleWhere((i) => i.id == 'inv-cotte').equipped,
        isFalse,
      );
      expect(
        detail.inventory.singleWhere((i) => i.id == 'inv-plate').equipped,
        isTrue,
      );
      expect(detail.armorClass, 18);

      goOnline();
      expect(await syncer.sync(), {_characterId});
      expect(row('inv-cotte')['equipped'], false);
      expect(row('inv-plate')['equipped'], true);
      expect(await queue.allForOwner(_ownerA), isEmpty);
    });

    test('équiper un objet dont l\'AJOUT est encore en file : refusé si une '
        'armure est déjà équipée, fusionné dans l\'ajout sinon', () async {
      await reopen();
      goOffline();
      await repository.addCustomInventoryItem(
        characterId: _characterId,
        customName: 'Plate runique',
        quantity: 1,
        enrichment: const CustomItemEnrichment(
          kind: CustomItemKinds.armor,
          acBase: 17,
          armorCategory: CustomArmorCategories.heavy,
        ),
      );
      final add = (await queued(PendingCharacterWriteKind.inventoryItem))
          .single;

      await expectLater(
        equip(add.targetId),
        _refused(CharacterErrorCode.armorAlreadyEquipped),
      );
      final unchanged = (await queued(PendingCharacterWriteKind.inventoryItem))
          .single;
      expect(unchanged.payload.containsKey('equipped'), isFalse);

      expect(await equip('inv-cotte', equipped: false), WriteOutcome.queued);
      expect(await equip(add.targetId), WriteOutcome.queued);
      final merged = (await queued(PendingCharacterWriteKind.inventoryItem))
          .single;
      expect(merged.payload['equipped'], true);
      expect((await reopen()).armorClass, 17);
    });

    test('LIMITE documentée : fiche jamais ouverte sur l\'appareil (aucun '
        'cache), rien à vérifier (fail-open, comme le plafond '
        'd\'harmonisation) ; cette fiche n\'est de toute façon pas affichable '
        'hors ligne', () async {
      goOffline();

      expect(await equip('inv-cuir'), WriteOutcome.queued);
    });
  });
}
