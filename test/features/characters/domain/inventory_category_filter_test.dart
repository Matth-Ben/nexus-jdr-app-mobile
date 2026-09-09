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
  });
}
