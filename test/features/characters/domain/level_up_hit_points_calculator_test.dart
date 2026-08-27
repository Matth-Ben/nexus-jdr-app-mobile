import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/level_up_hit_points_calculator.dart';

void main() {
  group('LevelUpHitPointsCalculator.rollHitDie', () {
    test('retourne toujours une valeur entre 1 et hitDie inclus', () {
      final random = Random(42);
      for (var i = 0; i < 200; i++) {
        final result = LevelUpHitPointsCalculator.rollHitDie(8, random);
        expect(result, inInclusiveRange(1, 8));
      }
    });

    test('un d1 retourne toujours 1', () {
      final random = Random(1);
      expect(LevelUpHitPointsCalculator.rollHitDie(1, random), 1);
    });
  });

  group('LevelUpHitPointsCalculator.averageValue', () {
    test('d8 -> 5 (moitié arrondie au supérieur + 1)', () {
      expect(LevelUpHitPointsCalculator.averageValue(8), 5);
    });

    test('d6 -> 4', () {
      expect(LevelUpHitPointsCalculator.averageValue(6), 4);
    });

    test('d10 -> 6', () {
      expect(LevelUpHitPointsCalculator.averageValue(10), 6);
    });

    test('d12 -> 7', () {
      expect(LevelUpHitPointsCalculator.averageValue(12), 7);
    });
  });

  group('LevelUpHitPointsCalculator.hpGain', () {
    test('additionne la valeur et le modificateur de Constitution', () {
      expect(
        LevelUpHitPointsCalculator.hpGain(
          rolledOrAverageValue: 5,
          constitutionModifier: 2,
        ),
        7,
      );
    });

    test('jamais inférieur à 1, même avec un modificateur très négatif', () {
      expect(
        LevelUpHitPointsCalculator.hpGain(
          rolledOrAverageValue: 1,
          constitutionModifier: -4,
        ),
        1,
      );
    });

    test('un modificateur nul laisse la valeur inchangée', () {
      expect(
        LevelUpHitPointsCalculator.hpGain(
          rolledOrAverageValue: 6,
          constitutionModifier: 0,
        ),
        6,
      );
    });
  });
}
