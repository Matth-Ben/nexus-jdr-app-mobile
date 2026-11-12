// P7 PR 1 : lecture des colonnes `custom_*` enrichies de
// `character_inventory` (type, bonus magique, CA, catégorie, poids,
// harmonisation, catégorie/portée d'arme), poids d'un objet personnalisé,
// non-régression de la CA et tolérance aux anciens payloads.

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/data/armor_class_row_resolver.dart';
import 'package:personnages/features/characters/data/character_inventory_row_mapper.dart';
import 'package:personnages/features/characters/domain/carrying_capacity_calculator.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/domain/inventory_weight_calculator.dart';
import 'package:personnages/features/characters/domain/weapon_slot.dart';

List<CharacterInventoryItem> _map(List<Map<String, dynamic>> rows) =>
    CharacterInventoryRowMapper.toCharacterInventoryItems(
      rows,
      names: const {},
      descriptions: const {},
    );

Map<String, dynamic> _customRow({
  String id = 'c1',
  int quantity = 1,
  Map<String, dynamic> extra = const {},
}) => {
  'id': id,
  'item_id': null,
  'custom_name': 'Objet maison',
  'quantity': quantity,
  'equipped': false,
  ...extra,
};

void main() {
  group('colonnes custom_* enrichies', () {
    test('une ligne avec les 8 colonnes les expose toutes', () {
      final item = _map([
        _customRow(
          extra: {
            'custom_kind': 'armure',
            'custom_magic_bonus': 2,
            'custom_ac_base': 15,
            'custom_armor_category': 'intermediaire',
            'custom_weight': 20.5,
            'custom_requires_attunement': true,
            'custom_weapon_category': 'guerre',
            'custom_weapon_range': 'distance',
          },
        ),
      ]).single;

      expect(item.customKind, 'armure');
      expect(item.resolvedCustomKind, 'armure');
      expect(item.magicBonus, 2);
      expect(item.customAcBase, 15);
      expect(item.customArmorCategory, 'intermediaire');
      expect(item.unitWeight, 20.5);
      expect(item.customRequiresAttunement, isTrue);
      expect(item.customWeaponCategory, 'guerre');
      expect(item.customWeaponRange, 'distance');
      // P7 PR 2 : l'harmonisation d'un objet personnalisé vient de
      // `custom_requires_attunement`.
      expect(item.requiresAttunement, isTrue);
      // P7 PR 3 (changement voulu : l'ancien test figeait « armorProperties
      // nul ») : une armure personnalisée porte ses armorProperties.
      expect(item.armorProperties, isNotNull);
      expect(item.armorProperties!.acBase, 15);
      expect(item.armorProperties!.acDexBonus, 'max_2');
      expect(item.armorProperties!.slot, 'armure');
    });

    test(
      'ancien payload sans aucune de ces clés : lisible, valeurs neutres',
      () {
        final item = _map([_customRow()]).single;

        expect(item.customKind, isNull);
        expect(item.resolvedCustomKind, isNull);
        expect(item.magicBonus, 0);
        expect(item.customAcBase, isNull);
        expect(item.customArmorCategory, isNull);
        expect(item.unitWeight, isNull);
        expect(item.totalWeight, isNull);
        expect(item.customRequiresAttunement, isFalse);
        expect(item.customWeaponCategory, isNull);
        expect(item.customWeaponRange, isNull);
      },
    );

    test('valeurs nulles explicites ou de type inattendu : pas de crash', () {
      final item = _map([
        _customRow(
          extra: {
            'custom_kind': null,
            'custom_magic_bonus': null,
            'custom_ac_base': 'abc',
            'custom_weight': 'lourd',
            'custom_requires_attunement': null,
          },
        ),
      ]).single;

      expect(item.magicBonus, 0);
      expect(item.customAcBase, isNull);
      expect(item.unitWeight, isNull);
      expect(item.customRequiresAttunement, isFalse);
    });

    test('type déduit d\'un ancien objet : arme s\'il a un dé de dégâts', () {
      final armed = _map([
        _customRow(
          extra: {'custom_damage_dice': '1d8', 'custom_damage_type': 'feu'},
        ),
      ]).single;
      final plain = _map([_customRow()]).single;
      final explicit = _map([
        _customRow(
          extra: {'custom_kind': 'autre', 'custom_damage_dice': '1d8'},
        ),
      ]).single;

      expect(armed.customKind, isNull);
      expect(armed.resolvedCustomKind, 'arme');
      expect(plain.resolvedCustomKind, isNull);
      expect(explicit.resolvedCustomKind, 'autre');
    });

    test('un objet du catalogue ignore les colonnes custom_*', () {
      final item = _map([
        {
          'id': 'k1',
          'item_id': 5,
          'quantity': 1,
          'equipped': false,
          'custom_kind': 'armure',
          'custom_magic_bonus': 3,
          'custom_weight': 99,
          'items': {'category': 'equipement_general', 'weight': 2},
        },
      ]).single;

      expect(item.resolvedCustomKind, isNull);
      expect(item.magicBonus, 0);
      expect(item.unitWeight, 2);
    });
  });

  group('poids d\'un objet personnalisé', () {
    test('total = poids unitaire x quantité', () {
      final item = _map([
        _customRow(quantity: 3, extra: {'custom_weight': 1.25}),
      ]).single;

      expect(item.unitWeight, 1.25);
      expect(item.totalWeight, 3.75);
    });

    test('poids absent ou nul en base : null, jamais 0', () {
      expect(_map([_customRow()]).single.totalWeight, isNull);
      expect(
        _map([
          _customRow(extra: {'custom_weight': null}),
        ]).single.unitWeight,
        isNull,
      );
    });

    test('quantité 0 : poids total inconnu, poids unitaire conservé', () {
      final item = _map([
        _customRow(quantity: 0, extra: {'custom_weight': 2}),
      ]).single;

      expect(item.totalWeight, isNull);
      expect(item.unitWeight, 2);
    });

    test('la jauge de charge inclut le poids personnalisé', () {
      final items = _map([
        _customRow(id: 'a', quantity: 2, extra: {'custom_weight': 5}),
        _customRow(id: 'b'),
        {
          'id': 'c',
          'item_id': 1,
          'quantity': 1,
          'equipped': false,
          'items': {'category': 'equipement_general', 'weight': 1.5},
        },
      ]);

      final total = InventoryWeightCalculator.totalOf(items);
      expect(total, 11.5);
      expect(
        CarryingCapacityCalculator.isOverloaded(
          totalWeightKg: total,
          strengthScore: 1,
        ),
        isTrue,
      );
    });
  });

  group('copyWith conserve les champs P7', () {
    const base = CharacterInventoryItem(
      id: 'x',
      name: 'Épée',
      quantity: 2,
      equipped: false,
      unitWeight: 3,
      totalWeight: 6,
      customKind: 'arme',
      magicBonus: 2,
      customAcBase: 12,
      customArmorCategory: 'legere',
      customRequiresAttunement: true,
      customWeaponCategory: 'courante',
      customWeaponRange: 'melee',
    );

    void expectKept(CharacterInventoryItem copy) {
      expect(copy.customKind, 'arme');
      expect(copy.magicBonus, 2);
      expect(copy.customAcBase, 12);
      expect(copy.customArmorCategory, 'legere');
      expect(copy.customRequiresAttunement, isTrue);
      expect(copy.customWeaponCategory, 'courante');
      expect(copy.customWeaponRange, 'melee');
      expect(copy.unitWeight, 3);
    }

    test('copyWithQuantity', () {
      final copy = base.copyWithQuantity(4);
      expectKept(copy);
      expect(copy.quantity, 4);
      expect(copy.totalWeight, 12);
      expect(base.copyWithQuantity(0).totalWeight, isNull);
    });

    test('copyWithPendingState', () {
      final copy = base.copyWithPendingState(
        equipped: true,
        changeWeaponSlot: true,
        weaponSlot: WeaponSlot.principal,
        isAttuned: true,
      );
      expectKept(copy);
      expect(copy.equipped, isTrue);
      expect(copy.isAttuned, isTrue);
      expect(copy.weaponSlot, WeaponSlot.principal);
      expect(copy.totalWeight, 6);
      expect(copy.quantity, 2);
      // Sans changeWeaponSlot, l'emplacement est conservé.
      expect(
        copy.copyWithPendingState(equipped: false).weaponSlot,
        WeaponSlot.principal,
      );
    });
  });

  group('CA et objets personnalisés (PR 1 puis PR 3)', () {
    int ac(List<Map<String, dynamic>> inventory) =>
        ArmorClassRowResolver.fromCharacterRow(
          {
            'character_ability_scores': [
              {'ability_id': 'dex', 'score': 14},
            ],
            'character_inventory': inventory,
          },
          classNames: const {},
          subclassNames: const {},
          classFeatureNames: const {},
        );

    test('anciens objets personnalisés, armes et objets « autre » équipés : '
        'la CA ne change pas (non-régression)', () {
      final without = ac(const []);
      final withOthers = ac([
        _customRow(id: 'old', extra: {'equipped': true}),
        _customRow(
          id: 'arme',
          extra: {
            'equipped': true,
            'custom_kind': 'arme',
            'custom_magic_bonus': 3,
          },
        ),
        _customRow(
          id: 'autre',
          extra: {'equipped': true, 'custom_kind': 'autre'},
        ),
      ]);

      expect(without, 12);
      expect(withOthers, without);
    });

    // P7 PR 3 : ce test figeait « une armure et un bouclier personnalisés
    // équipés ne changent pas la CA » (PR 1) ; ils y entrent désormais.
    test('une armure et un bouclier personnalisés équipés entrent dans la '
        'CA : 18 (lourde) + 3 (magique) + 2 (bouclier, bonus suspendu faute '
        'd\'harmonisation) = 23', () {
      final withCustom = ac([
        _customRow(
          id: 'a',
          extra: {
            'equipped': true,
            'custom_kind': 'armure',
            'custom_ac_base': 18,
            'custom_armor_category': 'lourde',
            'custom_magic_bonus': 3,
          },
        ),
        _customRow(
          id: 'b',
          extra: {
            'equipped': true,
            'custom_kind': 'bouclier',
            'custom_ac_base': 2,
            'custom_requires_attunement': true,
          },
        ),
      ]);

      expect(withCustom, 23);
    });
  });
}
