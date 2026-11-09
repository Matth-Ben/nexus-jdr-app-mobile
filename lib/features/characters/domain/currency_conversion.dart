import 'currency_kind.dart';

/// Pourquoi une conversion de pièces est impossible.
enum CurrencyConversionError {
  /// Source et cible identiques.
  sameCurrency,

  /// Montant nul (ou négatif).
  nonPositiveAmount,

  /// Montant supérieur au solde de la pièce source.
  insufficientBalance,

  /// Montant trop faible pour obtenir au moins une pièce cible entière
  /// (ex. 5 PA vers PO).
  tooSmall,
}

/// Résultat d'une conversion de pièces calculée par [convertCurrency].
class CurrencyConversion {
  const CurrencyConversion._({
    required this.spent,
    required this.obtained,
    required this.unconverted,
    this.error,
  });

  const CurrencyConversion._failure(CurrencyConversionError error, int amount)
    : this._(spent: 0, obtained: 0, unconverted: amount, error: error);

  /// Pièces source réellement débitées.
  final int spent;

  /// Pièces cible créditées.
  final int obtained;

  /// Part du montant demandé qui n'a pas pu être convertie (reste jamais
  /// perdu : elle reste dans le solde source).
  final int unconverted;

  /// `null` si la conversion est possible.
  final CurrencyConversionError? error;

  bool get isValid => error == null;
}

/// Valeur d'une pièce en pièces de cuivre, taux RAW D&D 5e (2014) :
/// 1 PP = 10 PO ; 1 PO = 2 PE = 10 PA = 100 PC ; 1 PE = 5 PA = 50 PC ;
/// 1 PA = 10 PC.
int copperValueOf(CurrencyKind currency) => switch (currency) {
  CurrencyKind.copper => 1,
  CurrencyKind.silver => 10,
  CurrencyKind.electrum => 50,
  CurrencyKind.gold => 100,
  CurrencyKind.platinum => 1000,
};

/// Convertit [amount] pièces [from] en pièces [to], en unités entières
/// uniquement : seules les pièces source qui forment un nombre entier de
/// pièces cible sont débitées, le reste n'est jamais perdu (ex. 15 PA vers
/// PO : 10 PA débitées, 1 PO obtenue, 5 PA restent). Les valeurs de pièces
/// étant toutes multiples les unes des autres, le débit est toujours un
/// nombre entier de pièces source.
///
/// [balanceFrom] est le solde actuel de la pièce source : un [amount]
/// supérieur donne [CurrencyConversionError.insufficientBalance].
CurrencyConversion convertCurrency({
  required CurrencyKind from,
  required CurrencyKind to,
  required int amount,
  required int balanceFrom,
}) {
  if (from == to) {
    return CurrencyConversion._failure(
      CurrencyConversionError.sameCurrency,
      amount,
    );
  }
  if (amount <= 0) {
    return CurrencyConversion._failure(
      CurrencyConversionError.nonPositiveAmount,
      amount,
    );
  }
  if (amount > balanceFrom) {
    return CurrencyConversion._failure(
      CurrencyConversionError.insufficientBalance,
      amount,
    );
  }

  final fromValue = copperValueOf(from);
  final toValue = copperValueOf(to);
  final obtained = amount * fromValue ~/ toValue;
  if (obtained == 0) {
    return CurrencyConversion._failure(
      CurrencyConversionError.tooSmall,
      amount,
    );
  }
  final spent = obtained * toValue ~/ fromValue;
  return CurrencyConversion._(
    spent: spent,
    obtained: obtained,
    unconverted: amount - spent,
  );
}

/// Monnaies proposées comme source/cible d'une conversion, dans l'ordre
/// décroissant de valeur : l'électrum n'apparaît que si son solde est
/// positif (même règle que la rangée de stat boxes de l'onglet Inventaire).
List<CurrencyKind> convertibleCurrencies(Map<CurrencyKind, int> balances) => [
  CurrencyKind.platinum,
  CurrencyKind.gold,
  if ((balances[CurrencyKind.electrum] ?? 0) > 0) CurrencyKind.electrum,
  CurrencyKind.silver,
  CurrencyKind.copper,
];
