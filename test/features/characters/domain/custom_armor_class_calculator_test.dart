// Calcul de la CA avec des armures et boucliers PERSONNALISÉS (P7, PR 3) :
// valeurs attendues explicites. Les objets sont construits comme le fait le
// mapper (`customArmorPropertiesOf`) ; le chemin ligne brute -> CA est couvert
// par `custom_armor_class_parity_test.dart`.

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/armor_class_calculator.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/domain/custom_armor_properties.dart';
import 'package:personnages/features/characters/domain/custom_item_enrichment.dart';

CharacterInventoryItem _custom({
  required String id,
  required String kind,
  int? acBase,
  String? category,
  int magic = 0,
  bool equipped = true,
  bool requiresAttunement = false,
  bool isAttuned = false,
}) => CharacterInventoryItem(
  id: id,
  name: id,
  quantity: 1,
  equipped: equipped,
  requiresAttunement: requiresAttunement,
  isAttuned: isAttuned,
  customKind: kind,
  magicBonus: magic,
  customAcBase: acBase,
  customArmorCategory: category,
  customRequiresAttunement: requiresAttunement,
  armorProperties: customArmorPropertiesOf(
    kind: kind,
    acBase: acBase,
    armorCategory: category,
  ),
);

CharacterInventoryItem _armor(
  String category,
  int base, {
  String id = 'armure',
  int magic = 0,
  bool equipped = true,
  bool requiresAttunement = false,
  bool isAttuned = false,
}) => _custom(
  id: id,
  kind: CustomItemKinds.armor,
  acBase: base,
  category: category,
  magic: magic,
  equipped: equipped,
  requiresAttunement: requiresAttunement,
  isAttuned: isAttuned,
);

CharacterInventoryItem _shield({
  int bonus = 2,
  int magic = 0,
  bool equipped = true,
  bool requiresAttunement = false,
  bool isAttuned = false,
}) => _custom(
  id: 'bouclier',
  kind: CustomItemKinds.shield,
  acBase: bonus,
  magic: magic,
  equipped: equipped,
  requiresAttunement: requiresAttunement,
  isAttuned: isAttuned,
);

CharacterInventoryItem _catalogArmor(
  String dex,
  int base, {
  String category = 'armure',
}) => CharacterInventoryItem(
  id: 'cat-$category',
  itemId: category.hashCode,
  name: 'catalogue',
  category: category,
  quantity: 1,
  equipped: true,
  armorProperties: CharacterInventoryArmorProperties(
    acBase: base,
    acDexBonus: dex,
    stealthDisadvantage: false,
  ),
);

int _ac(List<CharacterInventoryItem> inventory, {int dex = 16}) =>
    ArmorClassCalculator.compute(
      abilityScores: {'dex': dex},
      inventory: inventory,
    );

void main() {
  group('armure personnalisée : base + Dex selon la catégorie', () {
    test('légère 11 + Dex +3 = 14', () {
      expect(_ac([_armor(CustomArmorCategories.light, 11)]), 14);
    });

    test('légère, Dex négative (-2) : 11 - 2 = 9', () {
      expect(_ac([_armor(CustomArmorCategories.light, 11)], dex: 6), 9);
    });

    test('intermédiaire 14 : Dex +3 plafonnée à +2 = 16', () {
      expect(_ac([_armor(CustomArmorCategories.medium, 14)]), 16);
    });

    test('intermédiaire 14 : Dex +1 non plafonnée = 15, Dex -1 = 13', () {
      expect(_ac([_armor(CustomArmorCategories.medium, 14)], dex: 12), 15);
      expect(_ac([_armor(CustomArmorCategories.medium, 14)], dex: 8), 13);
    });

    test('lourde 16 : la Dex est ignorée (16 avec Dex +3 comme -2)', () {
      expect(_ac([_armor(CustomArmorCategories.heavy, 16)]), 16);
      expect(_ac([_armor(CustomArmorCategories.heavy, 16)], dex: 6), 16);
    });

    test('armure non équipée : ignorée (10 + 3)', () {
      expect(
        _ac([_armor(CustomArmorCategories.heavy, 18, equipped: false)]),
        13,
      );
    });

    test('sans armure : 10 + Dex +3 = 13', () {
      expect(_ac(const []), 13);
    });
  });

  group('bouclier personnalisé', () {
    test('bouclier +2 sans armure : 10 + 3 + 2 = 15', () {
      expect(_ac([_shield()]), 15);
    });

    test('bouclier +3 avec armure lourde 16 : 16 + 3 = 19, sans Dex', () {
      expect(
        _ac([_armor(CustomArmorCategories.heavy, 16), _shield(bonus: 3)]),
        19,
      );
    });

    test('bouclier non équipé : ignoré', () {
      expect(_ac([_shield(equipped: false)]), 13);
    });
  });

  group('bonus magique', () {
    test('armure légère 11 +1/+2/+3 (Dex +3) = 15/16/17', () {
      for (final magic in [1, 2, 3]) {
        expect(
          _ac([_armor(CustomArmorCategories.light, 11, magic: magic)]),
          14 + magic,
          reason: '+$magic',
        );
      }
    });

    test('armure lourde 16 +2 = 18 ; intermédiaire 14 +1 (Dex plafonnée) '
        '= 17', () {
      expect(_ac([_armor(CustomArmorCategories.heavy, 16, magic: 2)]), 18);
      expect(_ac([_armor(CustomArmorCategories.medium, 14, magic: 1)]), 17);
    });

    test('bouclier +2 magique +1, sans armure : 10 + 3 + 2 + 1 = 16', () {
      expect(_ac([_shield(magic: 1)]), 16);
    });

    test('armure +1 et bouclier +1 : chacun compte une fois '
        '(lourde 16 + 1 + 2 + 1 = 20)', () {
      expect(
        _ac([
          _armor(CustomArmorCategories.heavy, 16, magic: 1),
          _shield(magic: 1),
        ]),
        20,
      );
    });

    test('bonus magique d\'un objet non équipé : ignoré', () {
      expect(
        _ac([
          _armor(CustomArmorCategories.heavy, 16, magic: 3, equipped: false),
        ]),
        13,
      );
      expect(_ac([_shield(magic: 2, equipped: false)]), 13);
    });

    test('harmonisation requise non faite : bonus suspendu, base comptée', () {
      expect(
        _ac([
          _armor(
            CustomArmorCategories.light,
            11,
            magic: 2,
            requiresAttunement: true,
          ),
        ]),
        14, // 11 + 3, sans le +2
      );
      expect(
        _ac([_shield(magic: 1, requiresAttunement: true)]),
        15, // 10 + 3 + 2, sans le +1
      );
    });

    test('harmonisation requise et faite : bonus compté', () {
      expect(
        _ac([
          _armor(
            CustomArmorCategories.light,
            11,
            magic: 2,
            requiresAttunement: true,
            isAttuned: true,
          ),
        ]),
        16,
      );
      expect(
        _ac([_shield(magic: 1, requiresAttunement: true, isAttuned: true)]),
        16,
      );
    });

    test('harmonisation non requise : bonus compté même si isAttuned faux', () {
      expect(_ac([_armor(CustomArmorCategories.heavy, 16, magic: 1)]), 17);
    });
  });

  group('plusieurs objets', () {
    test('deux armures équipées : la première seulement (comportement '
        'du catalogue)', () {
      expect(
        _ac([
          _armor(CustomArmorCategories.light, 11, id: 'a'),
          _armor(CustomArmorCategories.heavy, 18, id: 'b'),
        ]),
        14,
      );
      expect(
        _ac([
          _armor(CustomArmorCategories.heavy, 18, id: 'b'),
          _armor(CustomArmorCategories.light, 11, id: 'a'),
        ]),
        18,
      );
    });

    test('le bonus magique de la seconde armure n\'est pas compté', () {
      expect(
        _ac([
          _armor(CustomArmorCategories.heavy, 16, id: 'a'),
          _armor(CustomArmorCategories.heavy, 16, id: 'b', magic: 3),
        ]),
        16,
      );
    });

    test('deux boucliers équipés : le premier seulement', () {
      expect(_ac([_shield(), _shield(bonus: 5)]), 15);
    });

    test('armure personnalisée + bouclier du catalogue : 11 + 3 + 2 = 16', () {
      expect(
        _ac([
          _armor(CustomArmorCategories.light, 11),
          _catalogArmor('aucun', 2, category: 'bouclier'),
        ]),
        16,
      );
    });

    test('armure du catalogue + bouclier personnalisé +1 : '
        '13 + 2 (Dex plafonnée) + 2 + 1 = 18', () {
      expect(_ac([_catalogArmor('max_2', 13), _shield(magic: 1)]), 18);
    });

    test('Défense : +1 avec une armure personnalisée', () {
      expect(
        ArmorClassCalculator.compute(
          abilityScores: const {'dex': 16},
          inventory: [_armor(CustomArmorCategories.heavy, 16)],
          fightingStyles: const {'Défense'},
        ),
        17,
      );
    });
  });

  group('ce qui ne compte jamais', () {
    test('une arme personnalisée à bonus magique n\'ajoute rien à la CA', () {
      final weapon = _custom(
        id: 'epee',
        kind: CustomItemKinds.weapon,
        magic: 3,
      );
      expect(_ac([weapon]), 13);
    });

    test('un objet « autre » équipé n\'ajoute rien', () {
      expect(_ac([_custom(id: 'x', kind: CustomItemKinds.other)]), 13);
    });

    test('armure sans catégorie ou sans CA : hors calcul (jamais devinée), '
        'bonus magique inclus', () {
      final noCategory = _custom(
        id: 'a',
        kind: CustomItemKinds.armor,
        acBase: 14,
        magic: 2,
      );
      final noAc = _custom(
        id: 'b',
        kind: CustomItemKinds.armor,
        category: CustomArmorCategories.heavy,
        magic: 2,
      );
      expect(_ac([noCategory]), 13);
      expect(_ac([noAc]), 13);
    });

    test('un objet du catalogue garde son calcul (magicBonus 0)', () {
      expect(_ac([_catalogArmor('illimite', 11)]), 14);
      expect(_ac([_catalogArmor('max_2', 14)]), 16);
      expect(_ac([_catalogArmor('aucun', 16)]), 16);
    });
  });

  group('customArmorPropertiesOf', () {
    test('valeurs de Dex et emplacement par catégorie', () {
      final light = customArmorPropertiesOf(
        kind: CustomItemKinds.armor,
        acBase: 11,
        armorCategory: CustomArmorCategories.light,
      )!;
      expect(
        (light.acDexBonus, light.slot, light.acBase),
        ('illimite', 'armure', 11),
      );
      final medium = customArmorPropertiesOf(
        kind: CustomItemKinds.armor,
        acBase: 14,
        armorCategory: CustomArmorCategories.medium,
      )!;
      expect(medium.acDexBonus, 'max_2');
      final heavy = customArmorPropertiesOf(
        kind: CustomItemKinds.armor,
        acBase: 16,
        armorCategory: CustomArmorCategories.heavy,
      )!;
      expect(heavy.acDexBonus, 'aucun');
    });

    test('bouclier : emplacement bouclier, sans Dex, catégorie ignorée', () {
      final shield = customArmorPropertiesOf(
        kind: CustomItemKinds.shield,
        acBase: 2,
        armorCategory: CustomArmorCategories.heavy,
      )!;
      expect(
        (shield.slot, shield.acDexBonus, shield.acBase),
        ('bouclier', 'aucun', 2),
      );
    });

    test('données insuffisantes : null', () {
      expect(
        customArmorPropertiesOf(
          kind: CustomItemKinds.armor,
          acBase: null,
          armorCategory: CustomArmorCategories.light,
        ),
        isNull,
      );
      expect(
        customArmorPropertiesOf(
          kind: CustomItemKinds.armor,
          acBase: 11,
          armorCategory: null,
        ),
        isNull,
      );
      expect(
        customArmorPropertiesOf(
          kind: CustomItemKinds.armor,
          acBase: 11,
          armorCategory: 'mithril',
        ),
        isNull,
      );
      expect(
        customArmorPropertiesOf(
          kind: CustomItemKinds.weapon,
          acBase: 11,
          armorCategory: CustomArmorCategories.light,
        ),
        isNull,
      );
      expect(
        customArmorPropertiesOf(kind: null, acBase: 2, armorCategory: null),
        isNull,
      );
    });
  });
}
