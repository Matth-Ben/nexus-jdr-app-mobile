import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/offline_inventory_writes.dart';
import 'package:personnages/features/characters/domain/offline_state_writes.dart';
import 'package:personnages/features/characters/domain/weapon_slot.dart';

const _uuid = '11111111-1111-4111-8111-111111111111';

void main() {
  group('parseInventoryItemPayload', () {
    test('ajout minimal : nom et quantité', () {
      final write = parseInventoryItemPayload({
        'op': 'add',
        'customName': 'Amulette',
        'quantity': 2,
      });

      expect(write!.op, InventoryItemOp.add);
      expect(write.customName, 'Amulette');
      expect(write.quantity, 2);
      expect(write.state, isNull);
      expect(write.customProperties, isEmpty);
    });

    test('ajout complet : champs personnalisés et état initial', () {
      final write = parseInventoryItemPayload({
        'op': 'add',
        'customName': 'Zanbato',
        'quantity': 1,
        'customDescription': 'Une lame',
        'customDamageDice': '2d6',
        'customDamageType': 'tranchant',
        'customProperties': ['lourde', 'deux mains'],
        'equipped': true,
        'weaponSlot': 'principal',
        'attuned': true,
      });

      expect(write!.customDescription, 'Une lame');
      expect(write.customDamageDice, '2d6');
      expect(write.customDamageType, 'tranchant');
      expect(write.customProperties, ['lourde', 'deux mains']);
      expect(write.state!.equipped, isTrue);
      expect(write.state!.weaponSlot, WeaponSlot.principal);
      expect(write.state!.attuned, isTrue);
    });

    test('retrait : tombstone', () {
      expect(
        parseInventoryItemPayload({'op': 'delete'})!.op,
        InventoryItemOp.delete,
      );
    });

    test('aller-retour payload -> parse -> payload identique', () {
      final payload = {
        'op': 'add',
        'customName': 'Zanbato',
        'quantity': 3,
        'customDescription': 'Une lame',
        'customDamageDice': '2d6',
        'customDamageType': 'tranchant',
        'customProperties': ['lourde'],
        'equipped': true,
        'weaponSlot': 'secondaire',
        'attuned': false,
      };

      expect(parseInventoryItemPayload(payload)!.toPayload(), payload);
    });

    final tooLong = 'x' * (inventoryCustomNameMaxLength + 1);
    final invalid = <String, Object?>{
      'pas un objet': 'add',
      'vide': <String, dynamic>{},
      'op absente': {'customName': 'A', 'quantity': 1},
      'op inconnue': {'op': 'update', 'customName': 'A', 'quantity': 1},
      'nom absent': {'op': 'add', 'quantity': 1},
      'nom vide': {'op': 'add', 'customName': '', 'quantity': 1},
      'nom blanc': {'op': 'add', 'customName': '   ', 'quantity': 1},
      'nom non texte': {'op': 'add', 'customName': 5, 'quantity': 1},
      'nom trop long': {'op': 'add', 'customName': tooLong, 'quantity': 1},
      'quantité absente': {'op': 'add', 'customName': 'A'},
      'quantité 0': {'op': 'add', 'customName': 'A', 'quantity': 0},
      'quantité négative': {'op': 'add', 'customName': 'A', 'quantity': -3},
      'quantité flottante': {'op': 'add', 'customName': 'A', 'quantity': 1.5},
      'quantité texte': {'op': 'add', 'customName': 'A', 'quantity': '2'},
      'quantité hors plage': {
        'op': 'add',
        'customName': 'A',
        'quantity': postgresIntMax + 1,
      },
      'description vide': {
        'op': 'add',
        'customName': 'A',
        'quantity': 1,
        'customDescription': '',
      },
      'dés non texte': {
        'op': 'add',
        'customName': 'A',
        'quantity': 1,
        'customDamageDice': 6,
      },
      'type null': {
        'op': 'add',
        'customName': 'A',
        'quantity': 1,
        'customDamageType': null,
      },
      'propriétés objet': {
        'op': 'add',
        'customName': 'A',
        'quantity': 1,
        'customProperties': {'a': 1},
      },
      'propriétés mixtes': {
        'op': 'add',
        'customName': 'A',
        'quantity': 1,
        'customProperties': ['a', 2],
      },
      'équipé non booléen': {
        'op': 'add',
        'customName': 'A',
        'quantity': 1,
        'equipped': 1,
      },
      'harmonisé non booléen': {
        'op': 'add',
        'customName': 'A',
        'quantity': 1,
        'attuned': 'oui',
      },
      'set inconnu': {
        'op': 'add',
        'customName': 'A',
        'quantity': 1,
        'weaponSlot': 'tertiaire',
      },
      'set nul': {
        'op': 'add',
        'customName': 'A',
        'quantity': 1,
        'weaponSlot': null,
      },
      'set pour un objet non équipé': {
        'op': 'add',
        'customName': 'A',
        'quantity': 1,
        'equipped': false,
        'weaponSlot': 'principal',
      },
    };
    for (final entry in invalid.entries) {
      test('payload invalide : ${entry.key}', () {
        expect(parseInventoryItemPayload(entry.value), isNull);
      });
    }

    test('clés inconnues ignorées', () {
      expect(
        parseInventoryItemPayload({
          'op': 'add',
          'customName': 'A',
          'quantity': 1,
          'futur': true,
        }),
        isNotNull,
      );
    });
  });

  group('validations', () {
    test('quantité : 1 à la plage int Postgres', () {
      expect(isValidInventoryQuantity(1), isTrue);
      expect(isValidInventoryQuantity(postgresIntMax), isTrue);
      expect(isValidInventoryQuantity(0), isFalse);
      expect(isValidInventoryQuantity(postgresIntMax + 1), isFalse);
      expect(isValidInventoryQuantity(2.0), isFalse);
    });

    test('targetId : UUID uniquement', () {
      expect(isValidInventoryItemTargetId(_uuid), isTrue);
      expect(isValidInventoryItemTargetId('inv-1'), isFalse);
      expect(isValidInventoryItemTargetId(''), isFalse);
    });
  });

  group('colonnes et ligne brute', () {
    const add = InventoryItemWrite.add(
      customName: 'Zanbato',
      quantity: 2,
      customDescription: 'Une lame',
      customDamageDice: '2d6',
      customDamageType: 'tranchant',
      customProperties: ['lourde'],
      state: InventoryStatePatch(
        equipped: true,
        hasWeaponSlot: true,
        weaponSlot: WeaponSlot.principal,
        attuned: true,
      ),
    );

    test('INSERT : id client, personnage, champs non vides, état', () {
      expect(add.toInsertColumns(inventoryId: _uuid, characterId: 'c1'), {
        'id': _uuid,
        'character_id': 'c1',
        'custom_name': 'Zanbato',
        'quantity': 2,
        'custom_description': 'Une lame',
        'custom_damage_dice': '2d6',
        'custom_damage_type': 'tranchant',
        'custom_properties': ['lourde'],
        'equipped': true,
        'weapon_slot': 'principal',
        'is_attuned': true,
      });
    });

    test('INSERT minimal : aucune colonne nulle explicite', () {
      const bare = InventoryItemWrite.add(customName: 'A', quantity: 1);

      expect(bare.toInsertColumns(inventoryId: _uuid, characterId: 'c1'), {
        'id': _uuid,
        'character_id': 'c1',
        'custom_name': 'A',
        'quantity': 1,
      });
    });

    test('réalignement : nom, quantité effective (T5b-3) et état', () {
      expect(add.toRealignColumns(), {
        'custom_name': 'Zanbato',
        'quantity': 2,
        'equipped': true,
        'weapon_slot': 'principal',
        'is_attuned': true,
      });
    });

    test('ligne brute : forme PostgREST d\'un objet personnalisé', () {
      final row = add.toRow(inventoryId: _uuid, characterId: 'c1');

      expect(row['id'], _uuid);
      expect(row['item_id'], isNull);
      expect(row['custom_name'], 'Zanbato');
      expect(row['equipped'], isTrue);
      expect(row['is_attuned'], isTrue);
      expect(row['weapon_slot'], 'principal');
      expect(row['custom_properties'], ['lourde']);
    });
  });

  group('mergeStateIntoPendingAdd', () {
    const add = InventoryItemWrite.add(customName: 'A', quantity: 1);

    test('équiper puis harmoniser : état cumulé, ajout inchangé', () {
      final merged = mergeStateIntoPendingAdd(
        mergeStateIntoPendingAdd(
          add,
          const InventoryStatePatch(equipped: true),
        ),
        const InventoryStatePatch(attuned: true),
      );

      expect(merged.op, InventoryItemOp.add);
      expect(merged.customName, 'A');
      expect(merged.quantity, 1);
      expect(merged.state!.equipped, isTrue);
      expect(merged.state!.attuned, isTrue);
    });

    test('dernière valeur gagnante : déséquiper efface le set d\'arme', () {
      final equipped = mergeStateIntoPendingAdd(
        add,
        const InventoryStatePatch(
          equipped: true,
          hasWeaponSlot: true,
          weaponSlot: WeaponSlot.secondary,
        ),
      );
      final unequipped = mergeStateIntoPendingAdd(
        equipped,
        const InventoryStatePatch(equipped: false, hasWeaponSlot: true),
      );

      expect(unequipped.state!.equipped, isFalse);
      expect(unequipped.state!.weaponSlot, isNull);
      expect(unequipped.toPayload().containsKey('weaponSlot'), isFalse);
      expect(parseInventoryItemPayload(unequipped.toPayload()), isNotNull);
    });
  });

  group('planInventoryRemoval', () {
    test('sans écriture en file : tombstone à enfiler', () {
      expect(planInventoryRemoval(pending: null).alreadyRemoved, isFalse);
    });

    test('ajout en attente : tombstone (jamais un simple retrait de la '
        'file : une tentative a pu atteindre le serveur)', () {
      expect(
        planInventoryRemoval(
          pending: const InventoryItemWrite.add(customName: 'A', quantity: 1),
        ).alreadyRemoved,
        isFalse,
      );
    });

    test('tombstone déjà en file : idempotent', () {
      expect(
        planInventoryRemoval(pending: const InventoryItemWrite.delete())
            .alreadyRemoved,
        isTrue,
      );
    });
  });

  group('objet du catalogue (T5b-2)', () {
    test('ajout du catalogue : itemId et quantité, sans nom', () {
      final write = parseInventoryItemPayload({
        'op': 'add',
        'itemId': 11,
        'quantity': 2,
      });

      expect(write!.itemId, 11);
      expect(write.customName, isNull);
      expect(write.quantity, 2);
    });

    test('aller-retour payload -> parse -> payload, état initial compris', () {
      final payload = {
        'op': 'add',
        'itemId': 11,
        'quantity': 3,
        'equipped': true,
        'weaponSlot': 'principal',
        'attuned': true,
      };

      expect(parseInventoryItemPayload(payload)!.toPayload(), payload);
    });

    test(
      'itemId ET customName acceptés ensemble (CHECK : l\'un OU l\'autre)',
      () {
        final write = parseInventoryItemPayload({
          'op': 'add',
          'itemId': 11,
          'customName': 'Dague',
          'quantity': 1,
        });

        expect(write!.itemId, 11);
        expect(write.customName, 'Dague');
      },
    );

    for (final bad in <Map<String, dynamic>>[
      {'op': 'add', 'quantity': 1},
      {'op': 'add', 'itemId': null, 'quantity': 1},
      {'op': 'add', 'itemId': 0, 'quantity': 1},
      {'op': 'add', 'itemId': -1, 'quantity': 1},
      {'op': 'add', 'itemId': 1.5, 'quantity': 1},
      {'op': 'add', 'itemId': 3.0, 'quantity': 1},
      {'op': 'add', 'itemId': '3', 'quantity': 1},
      {'op': 'add', 'itemId': true, 'quantity': 1},
      {'op': 'add', 'itemId': 2147483648, 'quantity': 1},
      {'op': 'add', 'itemId': 11},
      {'op': 'add', 'itemId': 11, 'quantity': 0},
      {'op': 'add', 'itemId': 11, 'quantity': 2.5},
      {'op': 'add', 'itemId': 11, 'quantity': 1, 'customName': ''},
      {'op': 'add', 'itemId': 11, 'quantity': 1, 'customName': 3},
    ]) {
      test('payload invalide $bad', () {
        expect(parseInventoryItemPayload(bad), isNull);
      });
    }

    test('isValidInventoryItemId : bornes', () {
      expect(isValidInventoryItemId(1), isTrue);
      expect(isValidInventoryItemId(postgresIntMax), isTrue);
      expect(isValidInventoryItemId(postgresIntMax + 1), isFalse);
      expect(isValidInventoryItemId(0), isFalse);
      expect(isValidInventoryItemId(2.0), isFalse);
      expect(isValidInventoryItemId(null), isFalse);
    });

    test('mergeStateIntoPendingAdd conserve l\'itemId', () {
      final merged = mergeStateIntoPendingAdd(
        const InventoryItemWrite.add(itemId: 11, quantity: 2),
        const InventoryStatePatch(equipped: true),
      );

      expect(merged.itemId, 11);
      expect(merged.customName, isNull);
      expect(merged.state!.equipped, isTrue);
      expect(merged.toPayload(), {
        'op': 'add',
        'itemId': 11,
        'quantity': 2,
        'equipped': true,
      });
    });

    test('colonnes d\'INSERT : item_id sans custom_name', () {
      final columns = const InventoryItemWrite.add(
        itemId: 11,
        quantity: 2,
      ).toInsertColumns(inventoryId: _uuid, characterId: 'c1');

      expect(columns, {
        'id': _uuid,
        'character_id': 'c1',
        'item_id': 11,
        'quantity': 2,
      });
    });

    test('réalignement : jamais un corps vide pour un objet du catalogue', () {
      expect(
        const InventoryItemWrite.add(
          itemId: 11,
          quantity: 1,
        ).toRealignColumns(),
        {'quantity': 1, 'item_id': 11},
      );
      expect(
        const InventoryItemWrite.add(
          itemId: 11,
          quantity: 1,
          state: InventoryStatePatch(attuned: true),
        ).toRealignColumns(),
        {'quantity': 1, 'item_id': 11, 'is_attuned': true},
      );
    });

    test('toRow : item_id, ligne items embarquée si fournie', () {
      final row = const InventoryItemWrite.add(itemId: 11, quantity: 1).toRow(
        inventoryId: _uuid,
        characterId: 'c1',
        itemRow: {'category': 'arme', 'weight': 0.5},
      );

      expect(row['item_id'], 11);
      expect(row['custom_name'], isNull);
      expect(row['items'], {'category': 'arme', 'weight': 0.5});
      expect(
        const InventoryItemWrite.add(
          itemId: 11,
          quantity: 1,
        ).toRow(inventoryId: _uuid, characterId: 'c1').containsKey('items'),
        isFalse,
      );
    });
  });

  group("usage d'un objet : quantity (T5b-3)", () {
    test('parse : quantité absolue et base', () {
      final write = parseInventoryItemPayload({
        'op': 'quantity',
        'quantity': 2,
        'base': 3,
      });

      expect(write!.op, InventoryItemOp.quantity);
      expect(write.quantity, 2);
      expect(write.base, 3);
      expect(write.toPayload(), {'op': 'quantity', 'quantity': 2, 'base': 3});
    });

    test('parse : quantité 0 et 2147483647 valides, base absente = null', () {
      expect(
        parseInventoryItemPayload({'op': 'quantity', 'quantity': 0})!.quantity,
        0,
      );
      final max = parseInventoryItemPayload({
        'op': 'quantity',
        'quantity': 2147483647,
      });
      expect(max!.quantity, 2147483647);
      expect(max.base, isNull);
      expect(max.toPayload(), {'op': 'quantity', 'quantity': 2147483647});
    });

    test('parse : base invalide ignorée (pas un payload invalide)', () {
      for (final base in <Object?>[-1, 1.5, 'x', null, 2147483648]) {
        final write = parseInventoryItemPayload({
          'op': 'quantity',
          'quantity': 2,
          'base': base,
        });
        expect(write, isNotNull, reason: '$base');
        expect(write!.base, isNull, reason: '$base');
      }
    });

    test('parse : quantité invalide ou op inconnue = payload invalide', () {
      for (final payload in <Object?>[
        {'op': 'quantity'},
        {'op': 'quantity', 'quantity': -1},
        {'op': 'quantity', 'quantity': 1.5},
        {'op': 'quantity', 'quantity': '2'},
        {'op': 'quantity', 'quantity': null},
        {'op': 'quantity', 'quantity': 2147483648},
        {'op': 'inconnue', 'quantity': 2},
        'quantity',
        null,
      ]) {
        expect(parseInventoryItemPayload(payload), isNull, reason: '$payload');
      }
    });

    test('planInventoryUse : tombstone en file = refus', () {
      final plan = planInventoryUse(
        pending: const InventoryItemWrite.delete(),
        newQuantity: 2,
      );

      expect(plan.isRejected, isTrue);
      expect(plan.write, isNull);
    });

    test(
      'planInventoryUse : ligne serveur, base = quantité serveur connue',
      () {
        final plan = planInventoryUse(
          pending: null,
          newQuantity: 2,
          serverQuantity: 3,
        );

        expect(plan.write!.toPayload(), {
          'op': 'quantity',
          'quantity': 2,
          'base': 3,
        });
        expect(plan.mergedIntoPendingAdd, isFalse);
      },
    );

    test('planInventoryUse : usage en file, base du premier enfilage '
        'conservée (même si la quantité serveur connue a changé)', () {
      final plan = planInventoryUse(
        pending: const InventoryItemWrite.quantity(quantity: 2, base: 3),
        newQuantity: 1,
        serverQuantity: 9,
      );

      expect(plan.write!.toPayload(), {
        'op': 'quantity',
        'quantity': 1,
        'base': 3,
      });
    });

    test('planInventoryUse : à 0 ou moins, tombstone (remplace tout)', () {
      for (final pending in <InventoryItemWrite?>[
        null,
        const InventoryItemWrite.quantity(quantity: 2, base: 3),
        const InventoryItemWrite.add(customName: 'A', quantity: 2),
      ]) {
        for (final quantity in [0, -1]) {
          final plan = planInventoryUse(
            pending: pending,
            newQuantity: quantity,
            serverQuantity: 3,
          );
          expect(plan.write!.toPayload(), {'op': 'delete'});
          expect(plan.mergedIntoPendingAdd, pending?.op == InventoryItemOp.add);
        }
      }
    });

    test("planInventoryUse : ajout en file, la quantité de l'ajout est "
        'modifiée, le reste (champs, état) est conservé', () {
      final plan = planInventoryUse(
        pending: const InventoryItemWrite.add(
          itemId: 5,
          quantity: 3,
          state: InventoryStatePatch(attuned: true),
        ),
        newQuantity: 2,
        serverQuantity: 9,
      );

      expect(plan.mergedIntoPendingAdd, isTrue);
      expect(plan.write!.toPayload(), {
        'op': 'add',
        'itemId': 5,
        'quantity': 2,
        'attuned': true,
      });
    });

    test("réalignement : la quantité effective de l'ajout est réalignée", () {
      const add = InventoryItemWrite.add(customName: 'A', quantity: 4);

      expect(add.toRealignColumns(), {'custom_name': 'A', 'quantity': 4});
    });
  });
}
