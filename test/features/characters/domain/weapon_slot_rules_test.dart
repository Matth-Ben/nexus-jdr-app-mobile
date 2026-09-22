import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/domain/weapon_slot.dart';
import 'package:personnages/features/characters/domain/weapon_slot_rules.dart';

CharacterInventoryWeaponProperties _oneHanded({
  List<String> properties = const [],
}) => CharacterInventoryWeaponProperties(
  damageDice: '1d6',
  damageType: 'tranchant',
  properties: properties,
);

const _twoHandedProperties = CharacterInventoryWeaponProperties(
  damageDice: '2d6',
  damageType: 'tranchant',
  properties: ['à deux mains'],
);

CharacterInventoryItem _weapon({
  required String id,
  required String name,
  bool equipped = true,
  WeaponSlot? slot,
  CharacterInventoryWeaponProperties? weaponProperties,
}) => CharacterInventoryItem(
  id: id,
  itemId: int.parse(id.split('-').last),
  name: name,
  category: 'arme',
  quantity: 1,
  equipped: equipped,
  weaponSlot: slot,
  weaponProperties: weaponProperties,
);

void main() {
  group('WeaponSlotRules.isTwoHanded', () {
    test('reconnaît "à deux mains" (accents/casse, voir PactWeaponRules)', () {
      expect(WeaponSlotRules.isTwoHanded(['à deux mains']), isTrue);
      expect(WeaponSlotRules.isTwoHanded(['À DEUX MAINS']), isTrue);
      expect(WeaponSlotRules.isTwoHanded(['a deux mains']), isTrue);
    });

    test('propriétés sans "à deux mains" : false', () {
      expect(WeaponSlotRules.isTwoHanded([]), isFalse);
      expect(WeaponSlotRules.isTwoHanded(['légère', 'finesse']), isFalse);
      // Contient la sous-chaîne mais n'est pas exactement égale une fois
      // normalisée -> ne doit pas matcher (même rigueur que
      // PactWeaponRules.isEligible sur "munitions").
      expect(
        WeaponSlotRules.isTwoHanded(['polyvalente (à deux mains)']),
        isFalse,
      );
    });
  });

  group('WeaponSlotRules.handCost', () {
    test('arme à deux mains : coût 2', () {
      expect(WeaponSlotRules.handCost(_twoHandedProperties), 2);
    });

    test('arme à une main : coût 1', () {
      expect(WeaponSlotRules.handCost(_oneHanded()), 1);
      expect(WeaponSlotRules.handCost(_oneHanded(properties: ['légère'])), 1);
    });

    test('weaponProperties nul : coût 1 (traité comme une main)', () {
      expect(WeaponSlotRules.handCost(null), 1);
    });
  });

  group('WeaponSlotRules.itemsToAutoUnequip', () {
    test('slot vide + nouvelle arme 1 main : rien à déséquiper', () {
      final candidate = _weapon(id: 'inv-1', name: 'Dague', equipped: false);
      final result = WeaponSlotRules.itemsToAutoUnequip(
        inventory: [candidate],
        slot: WeaponSlot.principal,
        candidate: candidate,
      );
      expect(result, isEmpty);
    });

    test('slot avec 1 arme 1 main + nouvelle arme 1 main : rien à déséquiper '
        '(les deux coexistent)', () {
      final existing = _weapon(
        id: 'inv-1',
        name: 'Dague',
        slot: WeaponSlot.principal,
      );
      final candidate = _weapon(id: 'inv-2', name: 'Rapière', equipped: false);
      final result = WeaponSlotRules.itemsToAutoUnequip(
        inventory: [existing, candidate],
        slot: WeaponSlot.principal,
        candidate: candidate,
      );
      expect(result, isEmpty);
    });

    test('slot avec 2 armes 1 main (plein) + nouvelle arme 1 main : déséquipe '
        'seulement la 1ère de la liste', () {
      final first = _weapon(
        id: 'inv-1',
        name: 'Dague',
        slot: WeaponSlot.principal,
      );
      final second = _weapon(
        id: 'inv-2',
        name: 'Rapière',
        slot: WeaponSlot.principal,
      );
      final candidate = _weapon(id: 'inv-3', name: 'Hachette', equipped: false);
      final result = WeaponSlotRules.itemsToAutoUnequip(
        inventory: [first, second, candidate],
        slot: WeaponSlot.principal,
        candidate: candidate,
      );
      expect(result, [first]);
    });

    test('slot avec 1 arme 2 mains + nouvelle arme 1 main : déséquipe l\'arme '
        '2 mains', () {
      final greatsword = _weapon(
        id: 'inv-1',
        name: 'Épée à deux mains',
        slot: WeaponSlot.principal,
        weaponProperties: _twoHandedProperties,
      );
      final candidate = _weapon(id: 'inv-2', name: 'Dague', equipped: false);
      final result = WeaponSlotRules.itemsToAutoUnequip(
        inventory: [greatsword, candidate],
        slot: WeaponSlot.principal,
        candidate: candidate,
      );
      expect(result, [greatsword]);
    });

    test(
      'slot avec 2 armes 1 main + nouvelle arme 2 mains : déséquipe les deux',
      () {
        final first = _weapon(
          id: 'inv-1',
          name: 'Dague',
          slot: WeaponSlot.principal,
        );
        final second = _weapon(
          id: 'inv-2',
          name: 'Rapière',
          slot: WeaponSlot.principal,
        );
        final candidate = _weapon(
          id: 'inv-3',
          name: 'Épée à deux mains',
          equipped: false,
          weaponProperties: _twoHandedProperties,
        );
        final result = WeaponSlotRules.itemsToAutoUnequip(
          inventory: [first, second, candidate],
          slot: WeaponSlot.principal,
          candidate: candidate,
        );
        expect(result, [first, second]);
      },
    );

    test('slot vide + nouvelle arme 2 mains : rien à déséquiper', () {
      final candidate = _weapon(
        id: 'inv-1',
        name: 'Épée à deux mains',
        equipped: false,
        weaponProperties: _twoHandedProperties,
      );
      final result = WeaponSlotRules.itemsToAutoUnequip(
        inventory: [candidate],
        slot: WeaponSlot.principal,
        candidate: candidate,
      );
      expect(result, isEmpty);
    });

    test('ne touche jamais l\'autre set', () {
      final secondaryWeapon = _weapon(
        id: 'inv-1',
        name: 'Dague',
        slot: WeaponSlot.secondary,
      );
      final candidate = _weapon(id: 'inv-2', name: 'Rapière', equipped: false);
      final result = WeaponSlotRules.itemsToAutoUnequip(
        inventory: [secondaryWeapon, candidate],
        slot: WeaponSlot.principal,
        candidate: candidate,
      );
      expect(result, isEmpty);
    });

    test('ignore les armes non équipées et les autres catégories', () {
      final unequippedWeapon = _weapon(
        id: 'inv-1',
        name: 'Dague',
        equipped: false,
        slot: WeaponSlot.principal,
      );
      const armor = CharacterInventoryItem(
        id: 'inv-2',
        itemId: 2,
        name: 'Armure',
        category: 'armure',
        quantity: 1,
        equipped: true,
      );
      final candidate = _weapon(id: 'inv-3', name: 'Rapière', equipped: false);
      final result = WeaponSlotRules.itemsToAutoUnequip(
        inventory: [unequippedWeapon, armor, candidate],
        slot: WeaponSlot.principal,
        candidate: candidate,
      );
      expect(result, isEmpty);
    });
  });
}
