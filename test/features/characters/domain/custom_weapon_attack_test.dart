// P7 PR 2b : arme personnalisée équipable, attaque et dégâts calculés
// (WeaponAttackCalculator.statsFor), classement « Armes », deux mains.
//
// Personnage de référence : Force 16 (+3), Dextérité 18 (+4), maîtrise +3.

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/domain/inventory_category_filter.dart';
import 'package:personnages/features/characters/domain/weapon_attack_calculator.dart';
import 'package:personnages/features/characters/domain/weapon_slot.dart';
import 'package:personnages/features/characters/domain/weapon_slot_rules.dart';

const _scores = {'str': 16, 'dex': 18};
const _warrior = ['courantes', 'martiales'];
const _wizard = [
  'dagues',
  'fléchettes',
  'frondes',
  'bâtons',
  'arbalètes légères',
];

CharacterInventoryItem _custom({
  String? kind = 'arme',
  String? category = 'guerre',
  String? range = 'melee',
  int magic = 0,
  bool requiresAttunement = false,
  bool attuned = false,
  List<String> properties = const [],
  String? dice = '1d8',
  bool equipped = false,
  WeaponSlot? slot,
  String id = 'c-1',
}) => CharacterInventoryItem(
  id: id,
  name: 'Lame maison',
  quantity: 1,
  equipped: equipped,
  weaponSlot: slot,
  customKind: kind,
  magicBonus: magic,
  requiresAttunement: requiresAttunement,
  customRequiresAttunement: requiresAttunement,
  isAttuned: attuned,
  customWeaponCategory: category,
  customWeaponRange: range,
  weaponProperties: CharacterInventoryWeaponProperties(
    damageDice: dice,
    damageType: 'radiant',
    properties: properties,
  ),
);

WeaponAttackStats _stats(
  CharacterInventoryItem item, {
  List<String> tokens = _warrior,
  int pb = 3,
}) => WeaponAttackCalculator.statsFor(
  item: item,
  abilityScores: _scores,
  proficiencyTokens: tokens,
  proficiencyBonus: pb,
)!;

void main() {
  group('caractéristique', () {
    test('corps à corps : Force +3, maîtrisé +3 -> attaque +6, dégâts +3', () {
      final s = _stats(_custom());
      expect(s.attackBonus, 6);
      expect(s.damageModifier, 3);
      expect(s.rangeUnspecified, isFalse);
    });

    test('distance : Dextérité +4 -> attaque +7, dégâts +4', () {
      final s = _stats(_custom(range: 'distance'));
      expect(s.attackBonus, 7);
      expect(s.damageModifier, 4);
    });

    test('finesse au corps à corps : la meilleure des deux (Dex +4)', () {
      final s = _stats(_custom(properties: ['Finesse']));
      expect(s.attackBonus, 7);
      expect(s.damageModifier, 4);
    });

    test('finesse : Force meilleure que Dex -> Force', () {
      final s = WeaponAttackCalculator.statsFor(
        item: _custom(properties: ['finesse']),
        abilityScores: const {'str': 18, 'dex': 12},
        proficiencyTokens: _warrior,
        proficiencyBonus: 3,
      )!;
      expect(s.damageModifier, 4);
    });

    test('munitions : Dextérité même annoncée au corps à corps', () {
      final s = _stats(_custom(properties: ['munitions(24/96)']));
      expect(s.damageModifier, 4);
    });

    test('portée non précisée : Force par défaut, légende demandée', () {
      final s = _stats(_custom(range: null));
      expect(s.damageModifier, 3);
      expect(s.rangeUnspecified, isTrue);
    });

    test('portée non précisée mais finesse/munitions : pas de légende', () {
      expect(
        _stats(_custom(range: null, properties: ['finesse'])).rangeUnspecified,
        isFalse,
      );
      expect(
        _stats(_custom(range: null, properties: ['munitions'])).damageModifier,
        4,
      );
    });
  });

  group('maîtrise', () {
    test('maîtrise 2 puis 3 selon le niveau', () {
      expect(_stats(_custom(), pb: 2).attackBonus, 5);
      expect(_stats(_custom(), pb: 3).attackBonus, 6);
    });

    test('guerrier : courante et de guerre maîtrisées', () {
      expect(_stats(_custom(category: 'courante')).attackBonus, 6);
      expect(_stats(_custom(category: 'guerre')).attackBonus, 6);
      expect(
        _stats(_custom(category: 'guerre')).proficiency,
        WeaponProficiencyStatus.proficient,
      );
    });

    test('magicien : aucune catégorie générique maîtrisée, pas de bonus', () {
      final s = _stats(_custom(category: 'courante'), tokens: _wizard);
      expect(s.proficiency, WeaponProficiencyStatus.notProficient);
      expect(s.attackBonus, 3);
    });

    test(
      'seulement armes courantes : une arme de guerre n\'est pas maîtrisée',
      () {
        final s = _stats(_custom(category: 'guerre'), tokens: ['courantes']);
        expect(s.proficiency, WeaponProficiencyStatus.notProficient);
        expect(s.attackBonus, 3);
        expect(
          _stats(
            _custom(category: 'courante'),
            tokens: ['courantes'],
          ).attackBonus,
          6,
        );
      },
    );

    test('catégorie absente : non évaluée, aucun bonus de maîtrise', () {
      final s = _stats(_custom(category: null));
      expect(s.proficiency, WeaponProficiencyStatus.unknown);
      expect(s.attackBonus, 3);
      expect(s.damageModifier, 3);
    });

    test('propriété naturelle : toujours maîtrisée', () {
      final s = _stats(
        _custom(category: null, properties: ['naturelle']),
        tokens: const [],
      );
      expect(s.proficiency, WeaponProficiencyStatus.proficient);
      expect(s.attackBonus, 6);
    });
  });

  group('bonus magique', () {
    for (final magic in [1, 2, 3]) {
      test('+$magic : ajouté à l\'attaque et aux dégâts', () {
        final s = _stats(_custom(magic: magic));
        expect(s.attackBonus, 6 + magic);
        expect(s.damageModifier, 3 + magic);
        expect(s.magicBonus, magic);
      });
    }

    test('jamais la maîtrise dans les dégâts', () {
      final s = _stats(_custom(magic: 1), pb: 6);
      expect(s.damageModifier, 4);
      expect(s.attackBonus, 3 + 6 + 1);
    });

    test('harmonisation requise et non faite : bonus suspendu', () {
      final s = _stats(_custom(magic: 2, requiresAttunement: true));
      expect(s.magicBonus, 0);
      expect(s.magicBonusSuspended, isTrue);
      expect(s.attackBonus, 6);
      expect(s.damageModifier, 3);
    });

    test('harmonisation requise et faite : bonus actif', () {
      final s = _stats(
        _custom(magic: 2, requiresAttunement: true, attuned: true),
      );
      expect(s.magicBonus, 2);
      expect(s.magicBonusSuspended, isFalse);
      expect(s.attackBonus, 8);
      expect(s.damageModifier, 5);
    });
  });

  group('non-régression', () {
    test(
      'arme du catalogue : mêmes valeurs que attackBonus/abilityModifierFor',
      () {
        const sword = CharacterInventoryItem(
          id: 'k-1',
          itemId: 7,
          name: 'Épée longue',
          category: 'arme',
          quantity: 1,
          equipped: true,
          weaponProperties: CharacterInventoryWeaponProperties(
            damageDice: '1d8',
            damageType: 'tranchant',
            properties: [],
          ),
        );
        final s = _stats(sword);
        expect(s.attackBonus, 6);
        expect(s.damageModifier, 3);
        expect(s.magicBonus, 0);
        expect(s.rangeUnspecified, isFalse);
        expect(_stats(sword, tokens: const []).attackBonus, 3);
      },
    );

    test(
      'ancien objet à dés sans type : traité en arme, catégorie non évaluée',
      () {
        final legacy = _custom(kind: null, category: null, range: null);
        expect(legacy.resolvedCustomKind, 'arme');
        expect(legacy.isWeapon, isTrue);
        final s = _stats(legacy);
        expect(s.proficiency, WeaponProficiencyStatus.unknown);
        expect(s.rangeUnspecified, isTrue);
        expect(s.attackBonus, 3);
      },
    );

    test('objet « autre » ou arme sans dé : pas de calcul', () {
      expect(
        WeaponAttackCalculator.statsFor(
          item: _custom(kind: 'autre', dice: null),
          abilityScores: _scores,
          proficiencyTokens: _warrior,
          proficiencyBonus: 3,
        ),
        isNull,
      );
      expect(
        WeaponAttackCalculator.statsFor(
          item: _custom(dice: null),
          abilityScores: _scores,
          proficiencyTokens: _warrior,
          proficiencyBonus: 3,
        ),
        isNull,
      );
    });
  });

  group('classement « Armes »', () {
    test('arme personnalisée enrichie : Armes, pas Divers', () {
      final weapon = _custom();
      expect(InventoryCategoryFilter.weapons.matches(weapon), isTrue);
      expect(InventoryCategoryFilter.misc.matches(weapon), isFalse);
      expect(InventoryCategoryFilter.armor.matches(weapon), isFalse);
    });

    test('objet « autre » : reste Divers', () {
      final other = _custom(kind: 'autre', dice: null);
      expect(InventoryCategoryFilter.weapons.matches(other), isFalse);
      expect(InventoryCategoryFilter.misc.matches(other), isTrue);
    });
  });

  group('deux mains et sets', () {
    test('variantes du texte libre', () {
      expect(WeaponSlotRules.isTwoHanded(['Deux mains']), isTrue);
      expect(WeaponSlotRules.isTwoHanded(['deux mains']), isTrue);
      expect(WeaponSlotRules.isTwoHanded(['à deux mains']), isTrue);
      expect(WeaponSlotRules.isTwoHanded(['À Deux Mains']), isTrue);
      expect(WeaponSlotRules.isTwoHanded(['une main']), isFalse);
    });

    test('coût en mains d\'une arme personnalisée à deux mains : 2', () {
      final big = _custom(properties: ['Deux mains']);
      expect(WeaponSlotRules.handCost(big.weaponProperties), 2);
    });

    test('équiper une arme à deux mains libère les armes du set', () {
      final inSet = _custom(
        id: 'a',
        equipped: true,
        slot: WeaponSlot.principal,
      );
      final other = _custom(
        id: 'b',
        equipped: true,
        slot: WeaponSlot.secondary,
      );
      final candidate = _custom(id: 'c', properties: ['deux mains']);
      final toUnequip = WeaponSlotRules.itemsToAutoUnequip(
        inventory: [inSet, other, candidate],
        slot: WeaponSlot.principal,
        candidate: candidate,
      );
      expect(toUnequip.map((i) => i.id), ['a']);
    });

    test('deux armes à une main : tiennent dans un set', () {
      final a = _custom(id: 'a', equipped: true, slot: WeaponSlot.principal);
      final candidate = _custom(id: 'c');
      expect(
        WeaponSlotRules.itemsToAutoUnequip(
          inventory: [a, candidate],
          slot: WeaponSlot.principal,
          candidate: candidate,
        ),
        isEmpty,
      );
    });
  });
}
