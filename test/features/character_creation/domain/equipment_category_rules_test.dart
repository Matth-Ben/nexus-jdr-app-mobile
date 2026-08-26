import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/equipment_category_rules.dart';

void main() {
  group('labelFor', () {
    test('résout le libellé FR pour chacune des 7 catégories du schéma', () {
      expect(EquipmentCategoryRules.labelFor('arme'), 'Arme');
      expect(EquipmentCategoryRules.labelFor('armure'), 'Armure');
      expect(EquipmentCategoryRules.labelFor('bouclier'), 'Bouclier');
      expect(EquipmentCategoryRules.labelFor('outil'), 'Outil');
      expect(
        EquipmentCategoryRules.labelFor('equipement_general'),
        'Équipement',
      );
      expect(EquipmentCategoryRules.labelFor('objet_magique'), 'Objet magique');
      expect(
        EquipmentCategoryRules.labelFor('monture_vehicule'),
        'Monture/Véhicule',
      );
    });

    test('null (objet non résolu) -> libellé générique neutre "Équipement", '
        'jamais un texte qui révélerait l\'échec de résolution (ex. "Non '
        'répertorié", régression corrigée après revue qa-testeur/'
        'direction-artistique)', () {
      expect(EquipmentCategoryRules.labelFor(null), 'Équipement');
    });

    test('catégorie inconnue -> même libellé générique "Équipement" plutôt '
        'qu\'un crash', () {
      expect(EquipmentCategoryRules.labelFor('inconnue'), 'Équipement');
    });
  });

  group('iconFor', () {
    test('résout une icône Material distincte pour chacune des 7 '
        'catégories', () {
      final icons = EquipmentCategoryRules.shopSectionOrder
          .map(EquipmentCategoryRules.iconFor)
          .toSet();

      expect(icons, hasLength(7));
    });

    test('null (objet non résolu) -> Icons.inventory_2', () {
      expect(EquipmentCategoryRules.iconFor(null), Icons.inventory_2);
    });

    test('catégorie inconnue -> Icons.inventory_2', () {
      expect(EquipmentCategoryRules.iconFor('inconnue'), Icons.inventory_2);
    });
  });

  group('shopSectionOrder', () {
    test(
      'contient exactement les 7 catégories du check `items_category_check`',
      () {
        expect(EquipmentCategoryRules.shopSectionOrder, [
          'arme',
          'armure',
          'bouclier',
          'outil',
          'equipement_general',
          'objet_magique',
          'monture_vehicule',
        ]);
      },
    );
  });
}
