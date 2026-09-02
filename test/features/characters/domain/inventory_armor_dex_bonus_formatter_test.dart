import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/inventory_armor_dex_bonus_formatter.dart';

void main() {
  group('InventoryArmorDexBonusFormatter.format', () {
    test('mappe les 3 valeurs contraintes côté base', () {
      expect(InventoryArmorDexBonusFormatter.format('aucun'), 'Aucun');
      expect(InventoryArmorDexBonusFormatter.format('max_2'), '+2 max');
      expect(InventoryArmorDexBonusFormatter.format('illimite'), 'Illimité');
    });

    test('une valeur inattendue retombe sur la valeur brute (ne devrait pas '
        'arriver, contrainte côté base)', () {
      expect(InventoryArmorDexBonusFormatter.format('autre'), 'autre');
    });
  });
}
