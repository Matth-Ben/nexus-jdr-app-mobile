import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/armor_class_calculator.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';

CharacterInventoryItem _armor({
  required bool equipped,
  required int acBase,
  required String acDexBonus,
}) => CharacterInventoryItem(
  id: 'armor-1',
  itemId: 1,
  name: 'Armure',
  category: 'armure',
  quantity: 1,
  equipped: equipped,
  armorProperties: CharacterInventoryArmorProperties(
    acBase: acBase,
    acDexBonus: acDexBonus,
    stealthDisadvantage: false,
  ),
);

CharacterInventoryItem _shield({required bool equipped}) =>
    CharacterInventoryItem(
      id: 'shield-1',
      itemId: 2,
      name: 'Bouclier',
      category: 'bouclier',
      quantity: 1,
      equipped: equipped,
      armorProperties: const CharacterInventoryArmorProperties(
        acBase: 2,
        acDexBonus: 'illimite',
        stealthDisadvantage: false,
      ),
    );

void main() {
  group('ArmorClassCalculator.compute', () {
    test('sans armure équipée : 10 + modificateur de Dextérité', () {
      final ac = ArmorClassCalculator.compute(
        abilityScores: {'dex': 16}, // modificateur +3
        inventory: const [],
      );
      expect(ac, 13);
    });

    test('sans armure équipée, Dextérité négative : le modificateur réduit '
        'bien la CA en dessous de 10', () {
      final ac = ArmorClassCalculator.compute(
        abilityScores: {'dex': 6}, // modificateur -2
        inventory: const [],
      );
      expect(ac, 8);
    });

    test(
      'armure légère (ac_dex_bonus illimité) : Dex ajoutée sans plafond',
      () {
        final ac = ArmorClassCalculator.compute(
          abilityScores: {'dex': 18}, // modificateur +4
          inventory: [
            _armor(equipped: true, acBase: 11, acDexBonus: 'illimite'),
          ],
        );
        expect(ac, 15);
      },
    );

    test('armure intermédiaire (ac_dex_bonus max_2) : Dex plafonnée à +2 '
        'même avec un modificateur supérieur', () {
      final ac = ArmorClassCalculator.compute(
        abilityScores: {'dex': 18}, // modificateur +4, plafonné à +2
        inventory: [_armor(equipped: true, acBase: 13, acDexBonus: 'max_2')],
      );
      expect(ac, 15);
    });

    test('ac_dex_bonus max_2 avec un modificateur déjà sous le plafond : '
        'appliqué tel quel (pas de plancher à 0)', () {
      final ac = ArmorClassCalculator.compute(
        abilityScores: {'dex': 10}, // modificateur 0
        inventory: [_armor(equipped: true, acBase: 13, acDexBonus: 'max_2')],
      );
      expect(ac, 13);
    });

    test('armure lourde (ac_dex_bonus aucun) : Dex jamais ajoutée', () {
      final ac = ArmorClassCalculator.compute(
        abilityScores: {'dex': 18}, // modificateur +4, ignoré
        inventory: [_armor(equipped: true, acBase: 18, acDexBonus: 'aucun')],
      );
      expect(ac, 18);
    });

    test('une armure présente dans l\'inventaire mais NON équipée n\'a aucun '
        'effet sur la CA (repli sur 10 + Dex)', () {
      final ac = ArmorClassCalculator.compute(
        abilityScores: {'dex': 14}, // modificateur +2
        inventory: [_armor(equipped: false, acBase: 18, acDexBonus: 'aucun')],
      );
      expect(ac, 12);
    });

    test('bouclier équipé sans armure : +2 ajouté à la base non-armurée '
        '(10 + Dex), jamais affecté par le Dex', () {
      final ac = ArmorClassCalculator.compute(
        abilityScores: {'dex': 14}, // modificateur +2
        inventory: [_shield(equipped: true)],
      );
      expect(ac, 14); // 10 + 2 (dex) + 2 (bouclier)
    });

    test('armure ET bouclier équipés simultanément : les deux bonus '
        's\'additionnent', () {
      final ac = ArmorClassCalculator.compute(
        abilityScores: {'dex': 14}, // modificateur +2
        inventory: [
          _armor(equipped: true, acBase: 13, acDexBonus: 'max_2'),
          _shield(equipped: true),
        ],
      );
      expect(ac, 17); // 13 + 2 (dex, sous le plafond) + 2 (bouclier)
    });

    test('bouclier présent mais non équipé : aucun effet', () {
      final ac = ArmorClassCalculator.compute(
        abilityScores: {'dex': 10},
        inventory: [_shield(equipped: false)],
      );
      expect(ac, 10);
    });

    test('caractéristique Dextérité absente de abilityScores : repli sur un '
        'score de 10 (modificateur nul), pas de crash', () {
      final ac = ArmorClassCalculator.compute(
        abilityScores: const {},
        inventory: const [],
      );
      expect(ac, 10);
    });
  });

  group('ArmorClassCalculator.compute — aptitudes de classe', () {
    const barbarianScores = {'dex': 14, 'con': 16, 'wis': 10}; // +2 / +3

    test('Barbare sans armure : 10 + Dex + Con', () {
      final ac = ArmorClassCalculator.compute(
        abilityScores: barbarianScores,
        inventory: const [],
        classNames: {ArmorClassCalculator.barbarianClassName},
      );
      expect(ac, 15);
    });

    test('Barbare sans armure garde son bouclier', () {
      final ac = ArmorClassCalculator.compute(
        abilityScores: barbarianScores,
        inventory: [_shield(equipped: true)],
        classNames: {ArmorClassCalculator.barbarianClassName},
      );
      expect(ac, 17);
    });

    test('Barbare en armure : la Défense sans armure ne s\'applique plus', () {
      final ac = ArmorClassCalculator.compute(
        abilityScores: barbarianScores,
        inventory: [_armor(equipped: true, acBase: 12, acDexBonus: 'max_2')],
        classNames: {ArmorClassCalculator.barbarianClassName},
      );
      expect(ac, 14);
    });

    test('Moine sans armure ni bouclier : 10 + Dex + Sag', () {
      final ac = ArmorClassCalculator.compute(
        abilityScores: const {'dex': 16, 'wis': 14}, // +3 / +2
        inventory: const [],
        classNames: {ArmorClassCalculator.monkClassName},
      );
      expect(ac, 15);
    });

    test('Moine avec bouclier : perd la Défense sans armure', () {
      final ac = ArmorClassCalculator.compute(
        abilityScores: const {'dex': 16, 'wis': 14},
        inventory: [_shield(equipped: true)],
        classNames: {ArmorClassCalculator.monkClassName},
      );
      expect(ac, 15); // 10 + 3 (dex) + 2 (bouclier), sans la Sagesse
    });

    test('Barbare/Moine multiclassé : la meilleure Défense sans armure', () {
      final ac = ArmorClassCalculator.compute(
        abilityScores: const {'dex': 14, 'con': 12, 'wis': 18}, // +2/+1/+4
        inventory: const [],
        classNames: {
          ArmorClassCalculator.barbarianClassName,
          ArmorClassCalculator.monkClassName,
        },
      );
      expect(ac, 16); // 10 + 2 + 4 (Moine) > 10 + 2 + 1 (Barbare)
    });

    test('Ensorceleur du Lignage draconique sans armure : 13 + Dex', () {
      final ac = ArmorClassCalculator.compute(
        abilityScores: const {'dex': 14},
        inventory: const [],
        classNames: {'Ensorceleur'},
        subclassNames: {ArmorClassCalculator.draconicSubclassName},
      );
      expect(ac, 15);
    });

    test('style de combat Défense : +1 en armure', () {
      final ac = ArmorClassCalculator.compute(
        abilityScores: const {'dex': 10},
        inventory: [
          _armor(equipped: true, acBase: 16, acDexBonus: 'aucun'),
          _shield(equipped: true),
        ],
        fightingStyles: {ArmorClassCalculator.defenseFightingStyle},
      );
      expect(ac, 19);
    });

    test('style de combat Défense : aucun effet sans armure', () {
      final ac = ArmorClassCalculator.compute(
        abilityScores: const {'dex': 14},
        inventory: const [],
        fightingStyles: {ArmorClassCalculator.defenseFightingStyle},
      );
      expect(ac, 12);
    });
  });
}
