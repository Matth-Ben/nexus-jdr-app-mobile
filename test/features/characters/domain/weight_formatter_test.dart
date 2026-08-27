import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/weight_formatter.dart';

void main() {
  group('WeightFormatter.format', () {
    test('un montant entier n\'affiche jamais de décimale', () {
      expect(WeightFormatter.format(38), '38');
      expect(WeightFormatter.format(1.0), '1');
    });

    test('un montant fractionnaire utilise la virgule française', () {
      expect(WeightFormatter.format(2.5), '2,5');
    });

    test('un montant à 2 décimales non nulles est conservé tel quel', () {
      expect(WeightFormatter.format(0.15), '0,15');
    });

    test('arrondit les imprécisions binaires résiduelles', () {
      expect(WeightFormatter.format(0.1 + 0.2), '0,3');
    });

    test('zéro s\'affiche "0"', () {
      expect(WeightFormatter.format(0), '0');
    });
  });
}
