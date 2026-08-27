import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/domain/inventory_weight_calculator.dart';

CharacterInventoryItem _item({
  String id = '1',
  double? totalWeight,
  int quantity = 1,
}) {
  return CharacterInventoryItem(
    id: id,
    itemId: 1,
    name: 'Objet',
    category: 'equipement_general',
    quantity: quantity,
    equipped: false,
    totalWeight: totalWeight,
  );
}

void main() {
  group('InventoryWeightCalculator.totalOf', () {
    test('somme les poids connus', () {
      final items = [
        _item(id: '1', totalWeight: 1.5),
        _item(id: '2', totalWeight: 2),
      ];
      expect(InventoryWeightCalculator.totalOf(items), 3.5);
    });

    test('un poids inconnu (null) contribue 0 au total, pas de crash', () {
      final items = [
        _item(id: '1', totalWeight: 5),
        _item(id: '2', totalWeight: null),
      ];
      expect(InventoryWeightCalculator.totalOf(items), 5);
    });

    test('une liste vide retourne 0', () {
      expect(InventoryWeightCalculator.totalOf(const []), 0);
    });

    test('garde-fou défensif : quantity == 0 contribue 0, même si '
        'totalWeight est renseigné (ex. un appelant qui ne passerait pas par '
        'CharacterInventoryRowMapper, qui applique déjà cette règle en '
        'amont)', () {
      final items = [
        _item(id: '1', totalWeight: 5, quantity: 1),
        _item(id: '2', totalWeight: 10, quantity: 0),
      ];
      expect(InventoryWeightCalculator.totalOf(items), 5);
    });

    test('garde-fou défensif : quantity négative contribue 0, jamais un '
        'poids négatif qui fausserait le total', () {
      final items = [
        _item(id: '1', totalWeight: 5, quantity: 1),
        _item(id: '2', totalWeight: -10, quantity: -3),
      ];
      expect(InventoryWeightCalculator.totalOf(items), 5);
    });
  });
}
