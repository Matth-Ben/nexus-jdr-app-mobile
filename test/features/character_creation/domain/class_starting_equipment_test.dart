// Tests de l'équipement de départ de classe
// (`lib/features/character_creation/domain/class_starting_equipment.dart`) et
// de sa prise en compte par `CharacterCreationEquipmentResolver`.

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/background_option.dart';
import 'package:personnages/features/character_creation/domain/character_creation_equipment_resolver.dart';
import 'package:personnages/features/character_creation/domain/class_starting_equipment.dart';
import 'package:personnages/features/character_creation/domain/equipment_choice_tab.dart';
import 'package:personnages/features/character_creation/domain/item_catalog.dart';
import 'package:personnages/features/character_creation/domain/item_option.dart';

void main() {
  const paladinJson = {
    'options': [
      {
        'label': 'A',
        'gold': 9,
        'items': [
          {'item': 'Cotte de mailles', 'quantity': 1},
          {'item': 'Bouclier', 'quantity': 1},
          {'item': 'Javeline', 'quantity': 6},
          {'item': "Paquetage d'ecclésiastique", 'quantity': 1},
        ],
      },
      {'label': 'B', 'gold': 150, 'items': <Object>[]},
    ],
  };

  group('ClassEquipmentOption', () {
    test('parse les options, objets et or', () {
      final options = ClassEquipmentOption.parse(paladinJson);
      expect(options.map((option) => option.label), ['A', 'B']);
      expect(options.first.gold, 9);
      expect(options.first.items, hasLength(4));
      expect(options.first.items[2], (name: 'Javeline', quantity: 6));
      expect(options.last.items, isEmpty);
    });

    test('colonne absente ou mal formée -> aucune option', () {
      expect(ClassEquipmentOption.parse(null), isEmpty);
      expect(ClassEquipmentOption.parse(const {'options': 'x'}), isEmpty);
    });

    test('résumé lisible', () {
      final options = ClassEquipmentOption.parse(paladinJson);
      expect(
        options.first.summary,
        "Cotte de mailles, Bouclier, 6 × Javeline, Paquetage d'ecclésiastique + 9 po",
      );
      expect(options.last.summary, '150 po');
    });

    test('select : option demandée, sinon la première, null si aucune', () {
      final options = ClassEquipmentOption.parse(paladinJson);
      expect(ClassEquipmentOption.select(options, 'B')?.label, 'B');
      expect(ClassEquipmentOption.select(options, null)?.label, 'A');
      expect(ClassEquipmentOption.select(const [], 'A'), isNull);
    });
  });

  group('CharacterCreationEquipmentResolver avec équipement de classe', () {
    const cotte = ItemOption(
      id: 1,
      name: 'Cotte de mailles',
      category: 'armure',
      costAmount: 75,
    );
    const bouclier = ItemOption(
      id: 2,
      name: 'Bouclier',
      category: 'bouclier',
      costAmount: 10,
    );
    const javeline = ItemOption(
      id: 3,
      name: 'Javeline',
      category: 'arme',
      costAmount: 0.5,
    );
    const catalog = ItemCatalog(items: [cotte, bouclier, javeline]);
    const acolyte = BackgroundOption(
      id: 1,
      name: 'Acolyte',
      skillProficiencies: [],
      featureName: '',
      featureDescription: '',
      equipment: ['Bourse (15 po)'],
    );

    test('option A : objets de classe équipés, paquetage en ligne libre, or '
        'cumulé', () {
      final optionA = ClassEquipmentOption.parse(paladinJson).first;
      final result = CharacterCreationEquipmentResolver.resolve(
        tab: EquipmentChoiceTab.background,
        backgroundOption: acolyte,
        purchasedEquipment: const {},
        itemCatalog: catalog,
        className: 'Paladin',
        classEquipment: optionA,
      );

      expect(result.currencyGp, 15 + 9);
      final byId = {
        for (final line in result.inventory)
          if (line.itemId != null) line.itemId!: line,
      };
      expect(byId[cotte.id]!.equipped, isTrue);
      expect(byId[bouclier.id]!.equipped, isTrue);
      expect(byId[javeline.id]!.quantity, 6);
      expect(
        result.inventory.where((line) => line.itemId == null).single.customName,
        "Paquetage d'ecclésiastique",
      );
    });

    test('option B (or seul) : budget d\'achat augmenté', () {
      final optionB = ClassEquipmentOption.parse(paladinJson).last;
      final result = CharacterCreationEquipmentResolver.resolve(
        tab: EquipmentChoiceTab.purchase,
        backgroundOption: acolyte,
        purchasedEquipment: const {'Cotte de mailles': 1},
        itemCatalog: catalog,
        className: 'Paladin',
        classEquipment: optionB,
      );

      expect(result.currencyGp, 15 + 150 - 75);
      expect(result.inventory.single.itemId, cotte.id);
      expect(result.inventory.single.equipped, isTrue);
    });
  });
}
