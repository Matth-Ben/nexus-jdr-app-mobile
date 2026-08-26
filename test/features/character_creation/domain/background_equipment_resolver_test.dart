import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/background_equipment_resolver.dart';
import 'package:personnages/features/character_creation/domain/item_catalog.dart';
import 'package:personnages/features/character_creation/domain/item_option.dart';

const _dague = ItemOption(
  id: 2,
  name: 'Dague',
  category: 'arme',
  costAmount: 2,
);
const _gourdin = ItemOption(
  id: 1,
  name: 'Gourdin',
  category: 'arme',
  costAmount: 0.1,
);

void main() {
  group('resolve', () {
    test('résout une chaîne dont le nom correspond exactement à un objet du '
        'catalogue', () {
      final entries = BackgroundEquipmentResolver.resolve(
        equipmentLines: ['Dague'],
        catalog: const ItemCatalog(items: [_dague, _gourdin]),
      );

      expect(entries, hasLength(1));
      expect(entries.single.itemId, 2);
      expect(entries.single.name, 'Dague');
      expect(entries.single.category, 'arme');
    });

    test('une chaîne sans correspondance devient un objet non résolu : '
        'itemId/category null, name = la chaîne brute telle quelle', () {
      final entries = BackgroundEquipmentResolver.resolve(
        equipmentLines: ['Symbole sacré'],
        catalog: const ItemCatalog(items: [_dague]),
      );

      expect(entries, hasLength(1));
      expect(entries.single.itemId, isNull);
      expect(entries.single.category, isNull);
      expect(entries.single.name, 'Symbole sacré');
    });

    test('conserve l\'ordre et la longueur de la liste, mélange résolu/non '
        'résolu', () {
      final entries = BackgroundEquipmentResolver.resolve(
        equipmentLines: ['Symbole sacré', 'Dague', 'Habits communs'],
        catalog: const ItemCatalog(items: [_dague, _gourdin]),
      );

      expect(entries, hasLength(3));
      expect(entries[0].name, 'Symbole sacré');
      expect(entries[0].itemId, isNull);
      expect(entries[1].name, 'Dague');
      expect(entries[1].itemId, 2);
      expect(entries[2].name, 'Habits communs');
      expect(entries[2].itemId, isNull);
    });

    test('liste vide -> liste vide', () {
      expect(
        BackgroundEquipmentResolver.resolve(
          equipmentLines: [],
          catalog: const ItemCatalog(items: [_dague]),
        ),
        isEmpty,
      );
    });

    test('catalogue vide -> tout est non résolu', () {
      final entries = BackgroundEquipmentResolver.resolve(
        equipmentLines: ['Dague'],
        catalog: const ItemCatalog(items: []),
      );

      expect(entries.single.itemId, isNull);
      expect(entries.single.name, 'Dague');
    });
  });
}
