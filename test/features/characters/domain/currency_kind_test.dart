import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';

void main() {
  group('CurrencyKindProperties', () {
    test('columnName mappe chaque monnaie vers sa colonne characters.'
        'currency_*', () {
      expect(CurrencyKind.platinum.columnName, 'currency_pp');
      expect(CurrencyKind.gold.columnName, 'currency_gp');
      expect(CurrencyKind.electrum.columnName, 'currency_ep');
      expect(CurrencyKind.silver.columnName, 'currency_sp');
      expect(CurrencyKind.copper.columnName, 'currency_cp');
    });

    test('unitLabel mappe chaque monnaie vers son abréviation (même '
        'libellés que InventoryStatBoxesResolver)', () {
      expect(CurrencyKind.platinum.unitLabel, 'PP');
      expect(CurrencyKind.gold.unitLabel, 'PO');
      expect(CurrencyKind.electrum.unitLabel, 'PE');
      expect(CurrencyKind.silver.unitLabel, 'PA');
      expect(CurrencyKind.copper.unitLabel, 'PC');
    });

    test('fullLabel mappe chaque monnaie vers son libellé complet FR', () {
      expect(CurrencyKind.platinum.fullLabel, 'pièces de platine');
      expect(CurrencyKind.gold.fullLabel, "pièces d'or");
      expect(CurrencyKind.electrum.fullLabel, "pièces d'électrum");
      expect(CurrencyKind.silver.fullLabel, "pièces d'argent");
      expect(CurrencyKind.copper.fullLabel, 'pièces de cuivre');
    });
  });
}
