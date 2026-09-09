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

    test('armure légère (ac_dex_bonus illimité) : Dex ajoutée sans plafond', () {
      final ac = ArmorClassCalculator.compute(
        abilityScores: {'dex': 18}, // modificateur +4
        inventory: [_armor(equipped: true, acBase: 11, acDexBonus: 'illimite')],
      );
      expect(ac, 15);
    });

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
}
