// Tests unitaires du calcul des PV de départ (niveau 1) de l'étape 9/9
// "Récapitulatif" (`lib/features/character_creation/domain/hit_points_calculator.dart`).

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/hit_points_calculator.dart';

void main() {
  group('maxHpAtLevel1', () {
    test('additionne le dé de vie maximum et le modificateur de '
        'Constitution', () {
      expect(
        HitPointsCalculator.maxHpAtLevel1(hitDie: 10, constitutionModifier: 2),
        12,
      );
    });

    test('gère un modificateur de Constitution négatif', () {
      expect(
        HitPointsCalculator.maxHpAtLevel1(hitDie: 6, constitutionModifier: -1),
        5,
      );
    });

    test('plancher à 1 même pour un modificateur très négatif', () {
      expect(
        HitPointsCalculator.maxHpAtLevel1(hitDie: 6, constitutionModifier: -10),
        1,
      );
    });

    test('modificateur nul -> PV = dé de vie tel quel', () {
      expect(
        HitPointsCalculator.maxHpAtLevel1(hitDie: 8, constitutionModifier: 0),
        8,
      );
    });
  });
}
