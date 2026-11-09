import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/currency_conversion.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';

CurrencyConversion _convert(
  CurrencyKind from,
  CurrencyKind to,
  int amount, {
  int? balance,
}) => convertCurrency(
  from: from,
  to: to,
  amount: amount,
  balanceFrom: balance ?? amount,
);

void main() {
  const pp = CurrencyKind.platinum;
  const gp = CurrencyKind.gold;
  const ep = CurrencyKind.electrum;
  const sp = CurrencyKind.silver;
  const cp = CurrencyKind.copper;

  group('taux RAW 2014', () {
    test('1 PP = 10 PO', () {
      expect(_convert(pp, gp, 1).obtained, 10);
      expect(_convert(gp, pp, 10).obtained, 1);
    });
    test('1 PO = 2 PE = 10 PA = 100 PC', () {
      expect(_convert(gp, ep, 1).obtained, 2);
      expect(_convert(gp, sp, 1).obtained, 10);
      expect(_convert(gp, cp, 1).obtained, 100);
      expect(_convert(ep, gp, 2).obtained, 1);
      expect(_convert(sp, gp, 10).obtained, 1);
      expect(_convert(cp, gp, 100).obtained, 1);
    });
    test('1 PE = 5 PA = 50 PC', () {
      expect(_convert(ep, sp, 1).obtained, 5);
      expect(_convert(ep, cp, 1).obtained, 50);
      expect(_convert(sp, ep, 5).obtained, 1);
      expect(_convert(cp, ep, 50).obtained, 1);
    });
    test('1 PA = 10 PC', () {
      expect(_convert(sp, cp, 1).obtained, 10);
      expect(_convert(cp, sp, 10).obtained, 1);
    });
    test('1 PP = 1000 PC et 20 PE', () {
      expect(_convert(pp, cp, 1).obtained, 1000);
      expect(_convert(pp, ep, 1).obtained, 20);
      expect(_convert(ep, pp, 20).obtained, 1);
    });
  });

  group('unités entières, reste jamais perdu', () {
    test('15 PA vers PO : 1 PO, 5 PA restent', () {
      final result = _convert(sp, gp, 15);
      expect(result.isValid, isTrue);
      expect(result.spent, 10);
      expect(result.obtained, 1);
      expect(result.unconverted, 5);
    });

    test('conservation de la valeur sur toutes les paires', () {
      for (final from in CurrencyKind.values) {
        for (final to in CurrencyKind.values) {
          if (from == to) continue;
          for (final amount in [1, 7, 15, 99, 1234]) {
            final r = _convert(from, to, amount);
            if (!r.isValid) continue;
            expect(r.spent + r.unconverted, amount);
            expect(
              r.spent * copperValueOf(from),
              r.obtained * copperValueOf(to),
            );
          }
        }
      }
    });

    test('montant trop faible : 5 PA vers PO', () {
      final r = _convert(sp, gp, 5);
      expect(r.error, CurrencyConversionError.tooSmall);
      expect(r.isValid, isFalse);
      expect(r.spent, 0);
    });
  });

  group('erreurs', () {
    test('solde insuffisant', () {
      final r = _convert(gp, sp, 11, balance: 10);
      expect(r.error, CurrencyConversionError.insufficientBalance);
    });
    test('solde exactement suffisant', () {
      expect(_convert(gp, sp, 10, balance: 10).isValid, isTrue);
    });
    test('même pièce', () {
      expect(_convert(gp, gp, 5).error, CurrencyConversionError.sameCurrency);
    });
    test('montant nul ou négatif', () {
      expect(
        _convert(gp, sp, 0, balance: 5).error,
        CurrencyConversionError.nonPositiveAmount,
      );
      expect(
        _convert(gp, sp, -3, balance: 5).error,
        CurrencyConversionError.nonPositiveAmount,
      );
    });
  });

  group('convertibleCurrencies', () {
    test('PE masqué tant que son solde est à 0', () {
      expect(convertibleCurrencies({ep: 0, gp: 5}), isNot(contains(ep)));
      expect(convertibleCurrencies(const {}), isNot(contains(ep)));
    });
    test('PE présent dès que son solde est > 0, ordre décroissant', () {
      expect(convertibleCurrencies({ep: 3}), [pp, gp, ep, sp, cp]);
    });
  });
}
