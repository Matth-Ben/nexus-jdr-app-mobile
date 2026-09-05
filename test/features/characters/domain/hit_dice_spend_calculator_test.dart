import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/hit_dice_spend_calculator.dart';
import 'package:personnages/features/characters/domain/hit_die_method.dart';

void main() {
  group('HitDiceSpendCalculator.rollDice', () {
    test('mode roll : diceCount valeurs entre 1 et hitDie inclus', () {
      final random = Random(42);
      final values = HitDiceSpendCalculator.rollDice(
        hitDie: 8,
        diceCount: 50,
        method: HitDieMethod.roll,
        random: random,
      );
      expect(values, hasLength(50));
      for (final value in values) {
        expect(value, inInclusiveRange(1, 8));
      }
    });

    test('mode average : diceCount fois la valeur moyenne du dé', () {
      final values = HitDiceSpendCalculator.rollDice(
        hitDie: 8,
        diceCount: 3,
        method: HitDieMethod.average,
      );
      expect(values, [5, 5, 5]);
    });

    test('diceCount = 0 -> liste vide', () {
      expect(
        HitDiceSpendCalculator.rollDice(
          hitDie: 8,
          diceCount: 0,
          method: HitDieMethod.roll,
        ),
        isEmpty,
      );
    });
  });

  group('HitDiceSpendCalculator.rawGain', () {
    test('somme (valeur + modificateur) par dé', () {
      expect(
        HitDiceSpendCalculator.rawGain(
          rolledOrAverageValues: [5, 5, 5],
          constitutionModifier: 2,
        ),
        21,
      );
    });

    test('chaque dé est individuellement plancé à 0, jamais négatif — même '
        'avec un modificateur de Constitution négatif', () {
      expect(
        HitDiceSpendCalculator.rawGain(
          rolledOrAverageValues: [1, 2],
          constitutionModifier: -4,
        ),
        0,
      );
    });

    test('un plancher par dé, pas sur le total : contrairement à '
        'LevelUpHitPointsCalculator.hpGain, un dé faible n\'est pas '
        'compensé par un autre plus fort', () {
      // dé 1 (1 - 4 -> plancé à 0) + dé 2 (10 - 4 = 6) = 6, jamais 7
      // (1 + 10 - 4, la somme brute plancée après coup).
      expect(
        HitDiceSpendCalculator.rawGain(
          rolledOrAverageValues: [1, 10],
          constitutionModifier: -4,
        ),
        6,
      );
    });

    test('liste vide -> 0', () {
      expect(
        HitDiceSpendCalculator.rawGain(
          rolledOrAverageValues: const [],
          constitutionModifier: 3,
        ),
        0,
      );
    });
  });

  group('HitDiceSpendCalculator.appliedGain', () {
    test('sous le plafond : renvoie rawGain tel quel', () {
      expect(
        HitDiceSpendCalculator.appliedGain(
          currentHp: 10,
          maxHp: 30,
          rawGain: 7,
        ),
        7,
      );
    });

    test('dépasse le plafond : plafonné à la marge restante', () {
      expect(
        HitDiceSpendCalculator.appliedGain(
          currentHp: 27,
          maxHp: 30,
          rawGain: 10,
        ),
        3,
      );
    });

    test('déjà au maximum : 0, jamais négatif', () {
      expect(
        HitDiceSpendCalculator.appliedGain(
          currentHp: 30,
          maxHp: 30,
          rawGain: 7,
        ),
        0,
      );
    });

    test('rawGain nul -> 0', () {
      expect(
        HitDiceSpendCalculator.appliedGain(
          currentHp: 10,
          maxHp: 30,
          rawGain: 0,
        ),
        0,
      );
    });
  });
}
