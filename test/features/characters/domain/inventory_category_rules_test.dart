import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/features/characters/domain/inventory_category_rules.dart';

void main() {
  group('InventoryCategoryRules.labelFor', () {
    test('résout le libellé français par catégorie', () {
      expect(InventoryCategoryRules.labelFor('arme'), 'Arme');
      expect(InventoryCategoryRules.labelFor('outil'), 'Outil');
      expect(InventoryCategoryRules.labelFor('objet_magique'), 'Objet magique');
    });

    test('category null (objet personnalisé) -> "Objet personnalisé"', () {
      expect(InventoryCategoryRules.labelFor(null), 'Objet personnalisé');
    });

    test('une catégorie inconnue retombe sur "Équipement"', () {
      expect(InventoryCategoryRules.labelFor('inconnue'), 'Équipement');
    });
  });

  group('InventoryCategoryRules.iconFor/colorFor', () {
    test('arme -> gavel / brique', () {
      expect(InventoryCategoryRules.iconFor('arme'), Icons.gavel);
      expect(InventoryCategoryRules.colorFor('arme'), AppColors.accentBrick);
    });

    test('outil -> sarcelle', () {
      expect(InventoryCategoryRules.colorFor('outil'), AppColors.accentTeal);
    });

    test('objet_magique -> or (couleur distinctive)', () {
      expect(
        InventoryCategoryRules.colorFor('objet_magique'),
        AppColors.goldEnd,
      );
    });

    test('equipement_general -> bois', () {
      expect(
        InventoryCategoryRules.colorFor('equipement_general'),
        AppColors.woodMedium,
      );
    });

    test('une catégorie inconnue retombe sur une icône/couleur neutres', () {
      expect(InventoryCategoryRules.iconFor('inconnue'), Icons.inventory_2);
      expect(InventoryCategoryRules.colorFor('inconnue'), AppColors.woodMedium);
    });
  });
}
