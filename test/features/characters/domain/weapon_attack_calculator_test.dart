// Tests unitaires du calcul pur du bonus d'attaque/modificateur de dégâts
// d'une arme (`domain/weapon_attack_calculator.dart`).

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/weapon_attack_calculator.dart';

void main() {
  group('isProficient', () {
    test('token de catégorie "courantes" avec une arme simple -> true', () {
      expect(
        WeaponAttackCalculator.isProficient(
          weaponName: 'Dague',
          proficiencyTokens: ['courantes'],
        ),
        isTrue,
      );
    });

    test('token de catégorie "martiales" avec une arme martiale -> true', () {
      expect(
        WeaponAttackCalculator.isProficient(
          weaponName: 'Épée longue',
          proficiencyTokens: ['martiales'],
        ),
        isTrue,
      );
    });

    test('token "courantes" avec une arme martiale -> false', () {
      expect(
        WeaponAttackCalculator.isProficient(
          weaponName: 'Épée longue',
          proficiencyTokens: ['courantes'],
        ),
        isFalse,
      );
    });

    test('nom spécifique exact ("dague") -> true', () {
      expect(
        WeaponAttackCalculator.isProficient(
          weaponName: 'Dague',
          proficiencyTokens: ['dague'],
        ),
        isTrue,
      );
    });

    test('nom spécifique au pluriel ("épées courtes") contre l\'arme catalogue '
        '"Épée courte" -> true (singularisation)', () {
      expect(
        WeaponAttackCalculator.isProficient(
          weaponName: 'Épée courte',
          proficiencyTokens: ['épées courtes'],
        ),
        isTrue,
      );
    });

    test('aucun token pertinent -> false', () {
      expect(
        WeaponAttackCalculator.isProficient(
          weaponName: 'Épée longue',
          proficiencyTokens: ['dague', 'courantes'],
        ),
        isFalse,
      );
    });

    test('liste de tokens vide -> false', () {
      expect(
        WeaponAttackCalculator.isProficient(
          weaponName: 'Dague',
          proficiencyTokens: [],
        ),
        isFalse,
      );
    });
  });

  group('abilityModifierFor', () {
    test(
      'arme à distance (munitions) -> Dextérité même si Force plus élevée',
      () {
        final modifier = WeaponAttackCalculator.abilityModifierFor(
          weaponProperties: const ['munitions(24/96)'],
          abilityScores: const {'str': 18, 'dex': 12},
        );
        expect(modifier, 1); // Dex 12 -> +1 (pas Force 18 -> +4).
      },
    );

    test(
      'arme corps à corps "finesse" -> meilleur des deux (Force > Dext)',
      () {
        final modifier = WeaponAttackCalculator.abilityModifierFor(
          weaponProperties: const ['finesse'],
          abilityScores: const {'str': 16, 'dex': 12},
        );
        expect(modifier, 3); // Force 16 -> +3, supérieur à Dext 12 -> +1.
      },
    );

    test(
      'arme corps à corps "finesse" -> meilleur des deux (Dext > Force)',
      () {
        final modifier = WeaponAttackCalculator.abilityModifierFor(
          weaponProperties: const ['finesse'],
          abilityScores: const {'str': 10, 'dex': 18},
        );
        expect(modifier, 4); // Dext 18 -> +4, supérieur à Force 10 -> +0.
      },
    );

    test('arme corps à corps sans "finesse" (même avec "lancer") -> Force '
        'uniquement', () {
      final modifier = WeaponAttackCalculator.abilityModifierFor(
        weaponProperties: const ['lancer', 'légère'],
        abilityScores: const {'str': 8, 'dex': 18},
      );
      expect(modifier, -1); // Force 8 -> -1, jamais Dext malgré "lancer".
    });

    test(
      'caractéristique absente de la map -> repli sur 10 (modificateur 0)',
      () {
        final modifier = WeaponAttackCalculator.abilityModifierFor(
          weaponProperties: const [],
          abilityScores: const {},
        );
        expect(modifier, 0);
      },
    );
  });

  group('attackBonus', () {
    test('compétent -> modificateur + bonus de maîtrise', () {
      final bonus = WeaponAttackCalculator.attackBonus(
        weaponName: 'Dague',
        weaponProperties: const ['finesse', 'légère'],
        abilityScores: const {'str': 10, 'dex': 16},
        proficiencyTokens: const ['courantes'],
        proficiencyBonus: 2,
      );
      expect(bonus, 5); // Dext +3 (finesse, meilleur des deux) + maîtrise +2.
    });

    test('non compétent -> modificateur seul (pas de bonus de maîtrise)', () {
      final bonus = WeaponAttackCalculator.attackBonus(
        weaponName: 'Épée longue',
        weaponProperties: const [],
        abilityScores: const {'str': 16, 'dex': 10},
        proficiencyTokens: const ['courantes'],
        proficiencyBonus: 2,
      );
      expect(bonus, 3); // Force +3 uniquement (pas martiale -> pas maîtrisé).
    });

    test('modificateur négatif géré correctement', () {
      final bonus = WeaponAttackCalculator.attackBonus(
        weaponName: 'Dague',
        weaponProperties: const [],
        abilityScores: const {'str': 6, 'dex': 8},
        proficiencyTokens: const [],
        proficiencyBonus: 2,
      );
      expect(bonus, -2); // Force 6 -> -2, non compétent (aucun token).
    });
  });
}
