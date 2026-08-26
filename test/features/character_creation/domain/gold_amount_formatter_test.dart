import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/gold_amount_formatter.dart';

void main() {
  group('format', () {
    test('montant entier -> pas de décimale affichée', () {
      expect(GoldAmountFormatter.format(15), '15');
      expect(GoldAmountFormatter.format(0), '0');
    });

    test('montant décimal (int en Dart, ex. 15.0) -> pas de décimale non '
        'plus', () {
      expect(GoldAmountFormatter.format(15.0), '15');
    });

    test('montant fractionnaire -> décimales conservées sans zéro '
        "superflu, séparateur virgule (app en français)", () {
      expect(GoldAmountFormatter.format(2.5), '2,5');
      expect(GoldAmountFormatter.format(0.05), '0,05');
      expect(GoldAmountFormatter.format(0.1), '0,1');
    });

    test('imprécision binaire résiduelle (ex. accumulation de flottants) -> '
        'arrondie à 2 décimales avant affichage', () {
      // `0.1 + 0.2` vaut `0.30000000000000004` en double.
      expect(GoldAmountFormatter.format(0.1 + 0.2), '0,3');
    });

    test('montant négatif (ex. le dépassement affiché par le bandeau '
        "d'alerte) -> signe conservé", () {
      expect(GoldAmountFormatter.format(-5), '-5');
    });
  });
}
