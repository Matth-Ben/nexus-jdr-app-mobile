// Tests unitaires de la résolution de l'équipement de départ ET de la
// devise selon l'onglet retenu à l'étape 7/9, à l'étape 9/9 "Récapitulatif"
// (`lib/features/character_creation/domain/character_creation_equipment_resolver.dart`).

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/background_option.dart';
import 'package:personnages/features/character_creation/domain/character_creation_equipment_resolver.dart';
import 'package:personnages/features/character_creation/domain/equipment_choice_tab.dart';
import 'package:personnages/features/character_creation/domain/item_catalog.dart';
import 'package:personnages/features/character_creation/domain/item_option.dart';

void main() {
  const dague = ItemOption(
    id: 1,
    name: 'Dague',
    category: 'arme',
    costAmount: 2,
  );
  const sacADos = ItemOption(
    id: 2,
    name: 'Sac à dos',
    category: 'equipement_general',
    costAmount: 2,
  );

  final catalog = const ItemCatalog(items: [dague, sacADos]);

  const acolyte = BackgroundOption(
    id: 1,
    name: 'Acolyte',
    skillProficiencies: [],
    featureName: '',
    featureDescription: '',
    equipment: ['Symbole sacré', 'Dague', 'Bourse (15 po)'],
  );

  group('onglet Historique', () {
    test('une ligne character_inventory par entrée résolue, quantity 1, '
        'currency_gp = la Bourse extraite', () {
      final result = CharacterCreationEquipmentResolver.resolve(
        tab: EquipmentChoiceTab.background,
        backgroundOption: acolyte,
        purchasedEquipment: const {},
        itemCatalog: catalog,
      );

      expect(result.currencyGp, 15);
      expect(result.inventory, hasLength(2));

      final dagueLine = result.inventory.firstWhere(
        (line) => line.itemId == dague.id,
      );
      expect(dagueLine.customName, isNull);
      expect(dagueLine.quantity, 1);

      final symboleLine = result.inventory.firstWhere(
        (line) => line.itemId == null,
      );
      expect(symboleLine.customName, 'Symbole sacré');
      expect(symboleLine.quantity, 1);
    });

    test('historique sans ligne "Bourse" -> currency_gp = 0', () {
      const sansOr = BackgroundOption(
        id: 2,
        name: 'Sans or',
        skillProficiencies: [],
        featureName: '',
        featureDescription: '',
        equipment: ['Dague'],
      );

      final result = CharacterCreationEquipmentResolver.resolve(
        tab: EquipmentChoiceTab.background,
        backgroundOption: sansOr,
        purchasedEquipment: const {},
        itemCatalog: catalog,
      );

      expect(result.currencyGp, 0);
    });
  });

  group('onglet Acheter', () {
    test('une ligne character_inventory par entrée du panier, currency_gp = '
        'bourse - coût total', () {
      final result = CharacterCreationEquipmentResolver.resolve(
        tab: EquipmentChoiceTab.purchase,
        backgroundOption: acolyte,
        purchasedEquipment: const {'Dague': 2, 'Sac à dos': 1},
        itemCatalog: catalog,
      );

      // Bourse (15) - (2 * 2 + 1 * 2) = 9.
      expect(result.currencyGp, 9);
      expect(result.inventory, hasLength(2));

      final dagueLine = result.inventory.firstWhere(
        (line) => line.itemId == dague.id,
      );
      expect(dagueLine.quantity, 2);
      expect(dagueLine.customName, isNull);
    });

    test('arrondit currency_gp à l\'entier le plus proche', () {
      const fractionalItem = ItemOption(
        id: 3,
        name: 'Flèche',
        category: 'equipement_general',
        costAmount: 0.3,
      );
      final catalogWithFractional = ItemCatalog(
        items: [...catalog.items, fractionalItem],
      );

      final result = CharacterCreationEquipmentResolver.resolve(
        tab: EquipmentChoiceTab.purchase,
        backgroundOption: acolyte,
        purchasedEquipment: const {'Flèche': 1},
        itemCatalog: catalogWithFractional,
      );

      // 15 - 0.3 = 14.7 -> arrondi à 15.
      expect(result.currencyGp, 15);
    });

    test("arrondit un cas exactement à mi-chemin (.5) à l'entier supérieur "
        '(arrondi "away from zero" de `double.round()`, pas un arrondi '
        'bancaire) — ex. de la revue QA de l\'étape 9/9 : Bourse 15 po, panier '
        '12,5 po dépensés -> currency_gp doit être 3, ni 2 ni 4', () {
      const halfCostItem = ItemOption(
        id: 4,
        name: 'Potion à moitié prix',
        category: 'equipement_general',
        costAmount: 12.5,
      );
      final catalogWithHalfCost = ItemCatalog(
        items: [...catalog.items, halfCostItem],
      );

      final result = CharacterCreationEquipmentResolver.resolve(
        tab: EquipmentChoiceTab.purchase,
        backgroundOption: acolyte,
        purchasedEquipment: const {'Potion à moitié prix': 1},
        itemCatalog: catalogWithHalfCost,
      );

      // 15 - 12.5 = 2.5 -> arrondi à 3 (pas 2, pas 4).
      expect(result.currencyGp, 3);
    });

    test('une entrée du panier sans correspondance dans le catalogue est '
        'ignorée plutôt que de crasher', () {
      final result = CharacterCreationEquipmentResolver.resolve(
        tab: EquipmentChoiceTab.purchase,
        backgroundOption: acolyte,
        purchasedEquipment: const {'Objet inconnu': 1},
        itemCatalog: catalog,
      );

      expect(result.inventory, isEmpty);
      expect(result.currencyGp, 15);
    });

    test('panier vide -> aucune ligne, currency_gp = la Bourse entière', () {
      final result = CharacterCreationEquipmentResolver.resolve(
        tab: EquipmentChoiceTab.purchase,
        backgroundOption: acolyte,
        purchasedEquipment: const {},
        itemCatalog: catalog,
      );

      expect(result.inventory, isEmpty);
      expect(result.currencyGp, 15);
    });
  });
}
