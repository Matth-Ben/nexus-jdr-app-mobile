import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/data/character_inventory_row_mapper.dart';

void main() {
  group('CharacterInventoryRowMapper.rowsOf', () {
    test('extrait la liste character_inventory embarquée', () {
      final row = {
        'character_inventory': [
          {'id': 'a'},
        ],
      };
      expect(CharacterInventoryRowMapper.rowsOf(row), hasLength(1));
    });

    test('retombe sur une liste vide quand absent/nul', () {
      expect(CharacterInventoryRowMapper.rowsOf({}), isEmpty);
    });
  });

  group('CharacterInventoryRowMapper.collectItemIds', () {
    test('collecte les item_id non nuls en Set<String>', () {
      final rows = [
        {'item_id': 1},
        {'item_id': 2},
        {'item_id': null, 'custom_name': 'Petit sac de sable'},
      ];
      expect(CharacterInventoryRowMapper.collectItemIds(rows), {'1', '2'});
    });
  });

  group('CharacterInventoryRowMapper.parseUnitWeight', () {
    test('extrait items.weight en double', () {
      expect(CharacterInventoryRowMapper.parseUnitWeight({'weight': 1.5}), 1.5);
    });

    test('null/type inattendu retombe sur null', () {
      expect(CharacterInventoryRowMapper.parseUnitWeight(null), isNull);
      expect(
        CharacterInventoryRowMapper.parseUnitWeight({'weight': null}),
        isNull,
      );
    });
  });

  group('CharacterInventoryRowMapper.parseCostAmount', () {
    test('extrait items.cost->>amount en double', () {
      expect(
        CharacterInventoryRowMapper.parseCostAmount({
          'amount': 2.5,
          'currency': 'gp',
        }),
        2.5,
      );
    });

    test('null/type inattendu retombe sur null (jamais 0)', () {
      expect(CharacterInventoryRowMapper.parseCostAmount(null), isNull);
      expect(CharacterInventoryRowMapper.parseCostAmount({}), isNull);
    });
  });

  group('CharacterInventoryRowMapper.parseWeaponProperties', () {
    test('résout damage_dice/damage_type/properties/range', () {
      final result = CharacterInventoryRowMapper.parseWeaponProperties({
        'weapon_properties': {
          'damage_dice': '1d8',
          'damage_type': 'tranchant',
          'properties': ['légère', 'finesse'],
          'range': {'normal': 6, 'max': 18},
        },
      });

      expect(result, isNotNull);
      expect(result!.damageDice, '1d8');
      expect(result.damageType, 'tranchant');
      expect(result.properties, ['légère', 'finesse']);
      expect(result.rangeNormal, 6);
      expect(result.rangeMax, 18);
    });

    test('accepte weapon_properties renvoyée en liste à un élément '
        '(défensif, format PostgREST alternatif)', () {
      final result = CharacterInventoryRowMapper.parseWeaponProperties({
        'weapon_properties': [
          {
            'damage_dice': '1d4',
            'damage_type': 'perforant',
            'properties': <String>[],
            'range': null,
          },
        ],
      });

      expect(result, isNotNull);
      expect(result!.damageDice, '1d4');
      expect(result.rangeNormal, isNull);
    });

    test('null pour un objet personnalisé ou une catégorie différente '
        "d'arme (weapon_properties absente)", () {
      expect(CharacterInventoryRowMapper.parseWeaponProperties(null), isNull);
      expect(
        CharacterInventoryRowMapper.parseWeaponProperties({'category': 'outil'}),
        isNull,
      );
    });
  });

  group('CharacterInventoryRowMapper.parseArmorProperties', () {
    test('résout ac_base/ac_dex_bonus/strength_requirement/'
        'stealth_disadvantage', () {
      final result = CharacterInventoryRowMapper.parseArmorProperties({
        'armor_properties': {
          'ac_base': 14,
          'ac_dex_bonus': 'max_2',
          'strength_requirement': 13,
          'stealth_disadvantage': true,
        },
      });

      expect(result, isNotNull);
      expect(result!.acBase, 14);
      expect(result.acDexBonus, 'max_2');
      expect(result.strengthRequirement, 13);
      expect(result.stealthDisadvantage, isTrue);
    });

    test('strength_requirement nul reste nul (aucune force minimale '
        'requise)', () {
      final result = CharacterInventoryRowMapper.parseArmorProperties({
        'armor_properties': {
          'ac_base': 11,
          'ac_dex_bonus': 'illimite',
          'strength_requirement': null,
          'stealth_disadvantage': false,
        },
      });

      expect(result!.strengthRequirement, isNull);
    });

    test('null si armor_properties absente ou ac_base manquant', () {
      expect(CharacterInventoryRowMapper.parseArmorProperties(null), isNull);
      expect(
        CharacterInventoryRowMapper.parseArmorProperties({
          'armor_properties': {'ac_dex_bonus': 'aucun'},
        }),
        isNull,
      );
    });
  });

  group('CharacterInventoryRowMapper.toCharacterInventoryItems', () {
    test('résout un objet du catalogue : nom via translations, poids = '
        'poids unitaire × quantité', () {
      final rows = [
        {
          'id': 'inv-1',
          'item_id': 1,
          'custom_name': null,
          'quantity': 2,
          'equipped': false,
          'items': {'category': 'arme', 'weight': 0.5},
        },
      ];

      final result = CharacterInventoryRowMapper.toCharacterInventoryItems(
        rows,
        names: const {'1': 'Dague'},
        descriptions: const {},
      );

      expect(result, hasLength(1));
      expect(result.single.id, 'inv-1');
      expect(result.single.itemId, 1);
      expect(result.single.name, 'Dague');
      expect(result.single.category, 'arme');
      expect(result.single.quantity, 2);
      expect(result.single.equipped, isFalse);
      expect(result.single.totalWeight, 1.0);
      expect(result.single.unitWeight, 0.5);
      expect(result.single.isCustom, isFalse);
    });

    test('un item_id sans traduction résolue retombe sur un libellé '
        'générique', () {
      final rows = [
        {
          'id': 'inv-1',
          'item_id': 99,
          'quantity': 1,
          'equipped': false,
          'items': {'category': 'outil', 'weight': null},
        },
      ];

      final result = CharacterInventoryRowMapper.toCharacterInventoryItems(
        rows,
        names: const {},
        descriptions: const {},
      );

      expect(result.single.name, 'Objet #99');
      // items.weight nul en base -> poids total inconnu, pas 0.
      expect(result.single.totalWeight, isNull);
    });

    test('un objet personnalisé (item_id nul) affiche custom_name, catégorie '
        'et poids inconnus (aucune ligne items à résoudre)', () {
      final rows = [
        {
          'id': 'inv-2',
          'item_id': null,
          'custom_name': 'Petit sac de sable',
          'quantity': 1,
          'equipped': false,
          'notes': 'Un cadeau de mamie.',
        },
      ];

      final result = CharacterInventoryRowMapper.toCharacterInventoryItems(
        rows,
        names: const {},
        descriptions: const {},
      );

      expect(result.single.name, 'Petit sac de sable');
      expect(result.single.category, isNull);
      expect(result.single.totalWeight, isNull);
      expect(result.single.isCustom, isTrue);
      // `notes` existe même pour un objet personnalisé (colonne directe sur
      // `character_inventory`, pas sur `items`).
      expect(result.single.notes, 'Un cadeau de mamie.');
      // Aucun de ces champs n'a de sens pour un objet personnalisé (aucune
      // ligne `items`) : jamais résolus, quels que soient `names`/
      // `descriptions`.
      expect(result.single.costAmount, isNull);
      expect(result.single.description, isNull);
      expect(result.single.rarity, isNull);
      expect(result.single.requiresAttunement, isFalse);
      expect(result.single.consumable, isFalse);
      expect(result.single.weaponProperties, isNull);
      expect(result.single.armorProperties, isNull);
    });

    test('equipped == true est reflété tel quel', () {
      final rows = [
        {
          'id': 'inv-3',
          'item_id': 1,
          'quantity': 1,
          'equipped': true,
          'items': {'category': 'objet_magique', 'weight': null},
        },
      ];

      final result = CharacterInventoryRowMapper.toCharacterInventoryItems(
        rows,
        names: const {'1': 'Grimoire'},
        descriptions: const {},
      );

      expect(result.single.equipped, isTrue);
    });

    test('quantity == 0 -> poids de ligne inconnu (null), pas "0 kg" '
        'trompeur (character_inventory.quantity n\'a aucune contrainte '
        'CHECK côté base)', () {
      final rows = [
        {
          'id': 'inv-4',
          'item_id': 1,
          'quantity': 0,
          'equipped': false,
          'items': {'category': 'arme', 'weight': 0.5},
        },
      ];

      final result = CharacterInventoryRowMapper.toCharacterInventoryItems(
        rows,
        names: const {'1': 'Dague'},
        descriptions: const {},
      );

      expect(result.single.quantity, 0);
      expect(result.single.totalWeight, isNull);
      // Contrairement à `totalWeight`, le poids unitaire brut reste
      // significatif même pour une quantité nulle.
      expect(result.single.unitWeight, 0.5);
    });

    test('quantity négative -> poids de ligne inconnu (null), jamais un '
        'poids négatif qui fausserait le total agrégé', () {
      final rows = [
        {
          'id': 'inv-5',
          'item_id': 1,
          'quantity': -3,
          'equipped': false,
          'items': {'category': 'arme', 'weight': 0.5},
        },
      ];

      final result = CharacterInventoryRowMapper.toCharacterInventoryItems(
        rows,
        names: const {'1': 'Dague'},
        descriptions: const {},
      );

      expect(result.single.quantity, -3);
      expect(result.single.totalWeight, isNull);
    });

    test('une ligne sans id exploitable est ignorée', () {
      final rows = [
        {'id': null, 'item_id': 1, 'quantity': 1, 'equipped': false},
      ];
      expect(
        CharacterInventoryRowMapper.toCharacterInventoryItems(
          rows,
          names: const {},
          descriptions: const {},
        ),
        isEmpty,
      );
    });

    test('résout cost/rarity/requires_attunement/consumable/description '
        "d'un objet du catalogue", () {
      final rows = [
        {
          'id': 'inv-6',
          'item_id': 7,
          'quantity': 1,
          'equipped': false,
          'items': {
            'category': 'objet_magique',
            'weight': 1.0,
            'cost': {'amount': 500, 'currency': 'gp'},
            'rarity': 'rare',
            'requires_attunement': true,
            'consumable': false,
          },
        },
      ];

      final result = CharacterInventoryRowMapper.toCharacterInventoryItems(
        rows,
        names: const {'7': 'Amulette de vitalité'},
        descriptions: const {'7': 'Une amulette protectrice.'},
      );

      expect(result.single.costAmount, 500);
      expect(result.single.rarity, 'rare');
      expect(result.single.requiresAttunement, isTrue);
      expect(result.single.consumable, isFalse);
      expect(result.single.description, 'Une amulette protectrice.');
    });

    test('résout weapon_properties/armor_properties embarquées sous items', () {
      final rows = [
        {
          'id': 'inv-7',
          'item_id': 10,
          'quantity': 1,
          'equipped': false,
          'items': {
            'category': 'arme',
            'weight': 1.5,
            'weapon_properties': {
              'damage_dice': '1d8',
              'damage_type': 'tranchant',
              'properties': ['polyvalente(1d10)'],
              'range': null,
            },
          },
        },
        {
          'id': 'inv-8',
          'item_id': 11,
          'quantity': 1,
          'equipped': true,
          'items': {
            'category': 'armure',
            'weight': 9.0,
            'armor_properties': {
              'ac_base': 16,
              'ac_dex_bonus': 'max_2',
              'strength_requirement': null,
              'stealth_disadvantage': false,
            },
          },
        },
      ];

      final result = CharacterInventoryRowMapper.toCharacterInventoryItems(
        rows,
        names: const {'10': 'Épée longue', '11': 'Chemise de mailles'},
        descriptions: const {},
      );

      expect(result[0].weaponProperties?.damageDice, '1d8');
      expect(result[0].armorProperties, isNull);
      expect(result[1].armorProperties?.acBase, 16);
      expect(result[1].weaponProperties, isNull);
    });
  });
}
