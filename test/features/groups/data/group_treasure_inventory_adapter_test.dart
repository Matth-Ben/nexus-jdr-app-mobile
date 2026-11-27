// Tests de `GroupTreasureInventoryAdapter` (décision 91) : une entrée du
// butin vue comme une ligne d'inventaire (carte, fiche, formulaire), et
// recopie complète de ses données à l'attribution.

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/characters/domain/custom_item_edit_rules.dart';
import 'package:personnages/features/characters/domain/custom_item_enrichment.dart';
import 'package:personnages/features/groups/data/group_treasure_inventory_adapter.dart';
import 'package:personnages/features/groups/domain/group_treasure_item.dart';

void main() {
  group('toInventoryItem', () {
    test('entrée ancienne du catalogue : nom figé, non équipée, sans '
        'catégorie', () {
      final item = GroupTreasureInventoryAdapter.toInventoryItem(
        const GroupTreasureItem(itemId: 7, displayName: 'Potion', quantity: 3),
      );
      expect(item.name, 'Potion');
      expect(item.itemId, 7);
      expect(item.isCustom, isFalse);
      expect(item.category, isNull);
      expect(item.quantity, 3);
      expect(item.equipped, isFalse);
      expect(item.isAttuned, isFalse);
      expect(item.description, isNull);
    });

    test(
      'catalogue avec instantané : catégorie et poids total de la carte',
      () {
        final item = GroupTreasureInventoryAdapter.toInventoryItem(
          const GroupTreasureItem.catalog(
            itemId: 9,
            displayName: 'Dague',
            quantity: 2,
            category: 'arme',
            weight: 0.5,
          ),
        );
        expect(item.category, 'arme');
        expect(item.unitWeight, 0.5);
        expect(item.totalWeight, 1.0);
      },
    );

    test(
      'catalogue relu par item_id : ligne items complète et description',
      () {
        final item = GroupTreasureInventoryAdapter.toInventoryItem(
          const GroupTreasureItem.catalog(
            itemId: 9,
            displayName: 'Dague',
            quantity: 1,
          ),
          itemRow: const {
            'category': 'arme',
            'weight': 0.5,
            'cost': {'amount': 2, 'currency': 'gp'},
            'weapon_properties': {
              'damage_dice': '1d4',
              'damage_type': 'perforant',
              'properties': ['finesse', 'légère'],
            },
          },
          description: 'Une lame courte.',
        );
        expect(item.description, 'Une lame courte.');
        expect(item.costAmount, 2);
        expect(item.weaponProperties?.damageDice, '1d4');
        expect(item.weaponProperties?.properties, ['finesse', 'légère']);
      },
    );

    test('objet personnalisé enrichi (armure) : mêmes règles que '
        'l\'inventaire (propriétés d\'armure, poids, harmonisation)', () {
      final item = GroupTreasureInventoryAdapter.toInventoryItem(
        GroupTreasureItem.custom(
          entryId: 'e',
          name: 'Cotte elfique',
          quantity: 1,
          description: 'Légère comme une plume.',
          enrichment: const CustomItemEnrichment(
            kind: CustomItemKinds.armor,
            acBase: 14,
            armorCategory: CustomArmorCategories.medium,
            weight: 9,
            requiresAttunement: true,
            magicBonus: 1,
          ),
        ),
      );
      expect(item.id, 'e');
      expect(item.isCustom, isTrue);
      expect(item.customKind, 'armure');
      expect(item.armorProperties?.acBase, 14);
      expect(item.armorProperties?.acDexBonus, 'max_2');
      expect(item.unitWeight, 9);
      expect(item.requiresAttunement, isTrue);
      expect(item.isAttuned, isFalse);
      expect(item.magicBonus, 1);
      expect(item.description, 'Légère comme une plume.');
    });

    test('valeurs de départ du formulaire : objet sans type -> « Enrichir », '
        'type déduit et quantité', () {
      final initial = customItemInitialValuesOf(
        GroupTreasureInventoryAdapter.toInventoryItem(
          GroupTreasureItem.custom(
            name: 'Lame',
            quantity: 4,
            damageDice: '2d6',
            damageType: 'tranchant',
          ),
        ),
      );
      expect(initial.mode, CustomItemEditMode.enrich);
      expect(initial.kind, 'arme');
      expect(initial.diceCount, 2);
      expect(initial.diceSides, 6);
      expect(initial.equipped, isFalse);
      expect(initial.quantity, 4);
    });

    test('catalogue avec surcharge de prix : lue indépendamment de item_id '
        '(spec du prix d\'un objet modifiable)', () {
      final item = GroupTreasureInventoryAdapter.toInventoryItem(
        const GroupTreasureItem.catalog(
          itemId: 9,
          displayName: 'Dague',
          quantity: 1,
          priceOverrideAmount: 15,
          priceOverrideCurrency: CurrencyKind.silver,
        ),
      );
      expect(item.priceOverrideAmount, 15);
      expect(item.priceOverrideCurrency, CurrencyKind.silver);
      expect(item.priceIsOverridden, isTrue);
    });
  });

  group('toInsertColumns (attribution)', () {
    test('objet personnalisé : recopie complète des données dans '
        'character_inventory', () {
      final columns = GroupTreasureInventoryAdapter.toInsertColumns(
        GroupTreasureItem.custom(
          entryId: 'e',
          name: 'Épée runique',
          quantity: 2,
          description: 'Gravée de runes.',
          damageDice: '1d8',
          damageType: 'tranchant',
          properties: ['polyvalente(1d10)'],
          enrichment: const CustomItemEnrichment(
            kind: CustomItemKinds.weapon,
            magicBonus: 1,
            weight: 1.5,
            requiresAttunement: true,
            weaponCategory: CustomWeaponCategories.martial,
            weaponRange: CustomWeaponRanges.melee,
          ),
        ),
        characterId: 'char-1',
        inventoryId: 'inv-1',
      );
      expect(columns, {
        'id': 'inv-1',
        'character_id': 'char-1',
        'custom_name': 'Épée runique',
        'quantity': 2,
        'custom_description': 'Gravée de runes.',
        'custom_damage_dice': '1d8',
        'custom_damage_type': 'tranchant',
        'custom_properties': ['polyvalente(1d10)'],
        'custom_kind': 'arme',
        'custom_magic_bonus': 1,
        'custom_weight': 1.5,
        'custom_requires_attunement': true,
        'custom_weapon_category': 'guerre',
        'custom_weapon_range': 'melee',
      });
    });

    test('objet du catalogue : seulement item_id (jamais de custom_*)', () {
      final columns = GroupTreasureInventoryAdapter.toInsertColumns(
        const GroupTreasureItem.catalog(
          itemId: 9,
          displayName: 'Dague',
          quantity: 1,
          category: 'arme',
          weight: 0.5,
        ),
        characterId: 'char-1',
        inventoryId: 'inv-1',
      );
      expect(columns, {
        'id': 'inv-1',
        'character_id': 'char-1',
        'item_id': 9,
        'quantity': 1,
      });
    });

    test('entrée ancienne personnalisée : nom et quantité seulement', () {
      final columns = GroupTreasureInventoryAdapter.toInsertColumns(
        const GroupTreasureItem(
          customName: 'Amulette',
          displayName: 'Amulette',
          quantity: 1,
        ),
        characterId: 'char-1',
        inventoryId: 'inv-1',
      );
      expect(columns, {
        'id': 'inv-1',
        'character_id': 'char-1',
        'custom_name': 'Amulette',
        'quantity': 1,
      });
    });

    test('enrichissement incohérent (jsonb modifié à la main) non recopié', () {
      final columns = GroupTreasureInventoryAdapter.toInsertColumns(
        const GroupTreasureItem(
          customName: 'Bizarre',
          displayName: 'Bizarre',
          quantity: 1,
          // Catégorie d'arme sans type « arme » : refusé par la table.
          enrichment: CustomItemEnrichment(
            kind: CustomItemKinds.other,
            weaponCategory: CustomWeaponCategories.common,
          ),
        ),
        characterId: 'char-1',
        inventoryId: 'inv-1',
      );
      expect(columns.containsKey('custom_kind'), isFalse);
      expect(columns.containsKey('custom_weapon_category'), isFalse);
    });

    test('surcharge de prix recopiée à l\'attribution, catalogue comme '
        'personnalisé (spec du prix d\'un objet modifiable)', () {
      final catalogColumns = GroupTreasureInventoryAdapter.toInsertColumns(
        const GroupTreasureItem.catalog(
          itemId: 9,
          displayName: 'Dague',
          quantity: 1,
          priceOverrideAmount: 15,
          priceOverrideCurrency: CurrencyKind.silver,
        ),
        characterId: 'char-1',
        inventoryId: 'inv-1',
      );
      expect(catalogColumns['price_override_amount'], 15);
      expect(catalogColumns['price_override_currency'], 'sp');

      final customColumns = GroupTreasureInventoryAdapter.toInsertColumns(
        GroupTreasureItem.custom(
          name: 'Amulette',
          quantity: 1,
          enrichment: const CustomItemEnrichment(
            kind: CustomItemKinds.other,
            priceOverrideAmount: 250,
            priceOverrideCurrency: CurrencyKind.gold,
          ),
        ),
        characterId: 'char-1',
        inventoryId: 'inv-1',
      );
      expect(customColumns['price_override_amount'], 250);
      expect(customColumns['price_override_currency'], 'gp');
    });

    test('aucune surcharge : les clés de prix ne sont pas écrites', () {
      final columns = GroupTreasureInventoryAdapter.toInsertColumns(
        const GroupTreasureItem.catalog(
          itemId: 9,
          displayName: 'Dague',
          quantity: 1,
        ),
        characterId: 'char-1',
        inventoryId: 'inv-1',
      );
      expect(columns.containsKey('price_override_amount'), isFalse);
      expect(columns.containsKey('price_override_currency'), isFalse);
    });
  });
}
