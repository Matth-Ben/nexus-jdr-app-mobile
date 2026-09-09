import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/carrying_capacity_calculator.dart';

void main() {
  group('CarryingCapacityCalculator.capacityOf', () {
    test('Force x 7,5 kg (simplification 1 lb ≈ 0,5 kg de la règle RAW 15 lb '
        'par point de Force)', () {
      expect(CarryingCapacityCalculator.capacityOf(10), 75);
      expect(CarryingCapacityCalculator.capacityOf(16), 120);
      expect(CarryingCapacityCalculator.capacityOf(8), 60);
    });

    test('score de Force minimal (1) -> capacité non nulle', () {
      expect(CarryingCapacityCalculator.capacityOf(1), 7.5);
    });
  });

  group('CarryingCapacityCalculator.isOverloaded', () {
    test('faux quand le poids reste sous la capacité', () {
      expect(
        CarryingCapacityCalculator.isOverloaded(
          totalWeightKg: 50,
          strengthScore: 10, // capacité 75
        ),
        isFalse,
      );
    });

    test('faux quand le poids égale exactement la capacité', () {
      expect(
        CarryingCapacityCalculator.isOverloaded(
          totalWeightKg: 75,
          strengthScore: 10,
        ),
        isFalse,
      );
    });

    test('vrai quand le poids dépasse la capacité', () {
      expect(
        CarryingCapacityCalculator.isOverloaded(
          totalWeightKg: 75.1,
          strengthScore: 10,
        ),
        isTrue,
      );
    });
  });
}
