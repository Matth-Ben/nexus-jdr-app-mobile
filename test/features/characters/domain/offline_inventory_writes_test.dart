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

    test('réalignement : nom et état, jamais la quantité', () {
      expect(add.toRealignColumns(), {
        'custom_name': 'Zanbato',
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
}
