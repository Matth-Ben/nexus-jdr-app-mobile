import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/domain/inventory_category_filter.dart';

CharacterInventoryItem _item(
  String id,
  String name, {
  String? category,
  bool consumable = false,
}) => CharacterInventoryItem(
  id: id,
  name: name,
  category: category,
  quantity: 1,
  equipped: false,
  consumable: consumable,
);

void main() {
  group('InventoryCategoryFilter', () {
    final sword = _item('1', 'Épée longue', category: 'arme');
    final potion = _item('2', 'Potion de soin', category: 'objet_magique', consumable: true);
    final backpack = _item('3', "Sac à dos d'érudit", category: 'equipement_general');
    final armor = _item('5', 'Chemise de mailles', category: 'armure');
    final shield = _item('6', 'Bouclier', category: 'bouclier');
    final items = [sword, potion, backpack];

    test('all.matches renvoie toujours vrai, quel que soit l\'objet', () {
      for (final item in items) {
        expect(InventoryCategoryFilter.all.matches(item), isTrue);
      }
    });

    test('weapons.matches ne retient que category == "arme"', () {
      expect(InventoryCategoryFilter.weapons.matches(sword), isTrue);
      expect(InventoryCategoryFilter.weapons.matches(potion), isFalse);
      expect(InventoryCategoryFilter.weapons.matches(backpack), isFalse);
    });

    test('consumables.matches ne retient que consumable == true, quelle que '
        'soit la catégorie', () {
      expect(InventoryCategoryFilter.consumables.matches(potion), isTrue);
      expect(InventoryCategoryFilter.consumables.matches(sword), isFalse);
      expect(InventoryCategoryFilter.consumables.matches(backpack), isFalse);
    });

    test('apply(all) renvoie la liste complète telle quelle', () {
      expect(
        InventoryCategoryFilter.apply(items, InventoryCategoryFilter.all),
        items,
      );
    });

    test('apply(weapons) ne garde que les armes', () {
      expect(
        InventoryCategoryFilter.apply(items, InventoryCategoryFilter.weapons),
        [sword],
      );
    });

    test('apply(consumables) ne garde que les consommables', () {
      expect(
        InventoryCategoryFilter.apply(
          items,
          InventoryCategoryFilter.consumables,
        ),
        [potion],
      );
    });

    test('un objet personnalisé (category null, non consommable) ne '
        'correspond ni à weapons ni à consumables', () {
      final custom = _item('4', 'Petit sac de sable');
      expect(InventoryCategoryFilter.weapons.matches(custom), isFalse);
      expect(InventoryCategoryFilter.consumables.matches(custom), isFalse);
      expect(InventoryCategoryFilter.all.matches(custom), isTrue);
    });

    test('armor.matches ne retient que category ∈ {"armure", "bouclier"}', () {
      expect(InventoryCategoryFilter.armor.matches(armor), isTrue);
      expect(InventoryCategoryFilter.armor.matches(shield), isTrue);
      expect(InventoryCategoryFilter.armor.matches(sword), isFalse);
      expect(InventoryCategoryFilter.armor.matches(backpack), isFalse);
    });

    test('misc.matches ne retient que ce qui n\'est ni arme, ni armure/'
        'bouclier, ni consommable — y compris un objet personnalisé', () {
      final custom = _item('4', 'Petit sac de sable');
      expect(InventoryCategoryFilter.misc.matches(backpack), isTrue);
      expect(InventoryCategoryFilter.misc.matches(custom), isTrue);
      expect(InventoryCategoryFilter.misc.matches(sword), isFalse);
      expect(InventoryCategoryFilter.misc.matches(armor), isFalse);
      expect(InventoryCategoryFilter.misc.matches(shield), isFalse);
      expect(InventoryCategoryFilter.misc.matches(potion), isFalse);
    });

    test('apply(armor) ne garde que armure/bouclier', () {
      expect(
        InventoryCategoryFilter.apply(
          [...items, armor, shield],
          InventoryCategoryFilter.armor,
        ),
        [armor, shield],
      );
    });

    test('apply(misc) ne garde que ce qui n\'est ni arme/armure/bouclier ni '
        'consommable', () {
      expect(
        InventoryCategoryFilter.apply(
          [...items, armor, shield],
          InventoryCategoryFilter.misc,
        ),
        [backpack],
      );
    });
  });
}
