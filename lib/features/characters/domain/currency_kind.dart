/// Les 5 monnaies d'un personnage (`characters.currency_gp/pp/ep/sp/cp`) —
/// onglet "Inventaire", rangée de stat boxes
/// (`domain/inventory_stat_boxes_resolver.dart`) et sheet d'ajustement de
/// monnaie (`presentation/widgets/currency_adjustment_sheet.dart`).
///
/// Centralise le mapping colonne/unité/libellé complet par monnaie plutôt
/// que de le laisser dupliqué entre le resolver de stat boxes (déjà
/// existant, non modifié ici) et la nouvelle sheet d'ajustement — voir
/// [columnName]/[unitLabel]/[fullLabel].
enum CurrencyKind {
  /// Pièces de platine (`currency_pp`) — la plus rare des 5, non toujours
  /// affichée en tête de liste (voir `InventoryStatBoxesResolver`).
  platinum,
  gold,
  electrum,
  silver,
  copper,
}

/// Regroupe les propriétés dérivées de [CurrencyKind] — extension plutôt que
/// méthodes statiques indexées sur l'enum, pour un usage `currency.unitLabel`
/// plus lisible côté appelants (sheets/repository).
extension CurrencyKindProperties on CurrencyKind {
  /// Nom de colonne `characters.currency_*` correspondant — voir
  /// `CharacterRepository.adjustCurrency`/`addReward`.
  String get columnName => switch (this) {
    CurrencyKind.platinum => 'currency_pp',
    CurrencyKind.gold => 'currency_gp',
    CurrencyKind.electrum => 'currency_ep',
    CurrencyKind.silver => 'currency_sp',
    CurrencyKind.copper => 'currency_cp',
  };

  /// Unité courte affichée sur la stat box ("PP"/"PO"/"PE"/"PA"/"PC") — même
  /// libellés que `InventoryStatBoxesResolver` (non dupliqués ici, ce
  /// resolver construit ses `InventoryStatBox` directement, voir sa
  /// documentation de classe).
  String get unitLabel => switch (this) {
    CurrencyKind.platinum => 'PP',
    CurrencyKind.gold => 'PO',
    CurrencyKind.electrum => 'PE',
    CurrencyKind.silver => 'PA',
    CurrencyKind.copper => 'PC',
  };

  /// Libellé complet FR, pour le titre de la sheet d'ajustement ("Ajuster
  /// les pièces d'or") et la section "MONNAIE" de la sheet de récompense.
  String get fullLabel => switch (this) {
    CurrencyKind.platinum => 'pièces de platine',
    CurrencyKind.gold => "pièces d'or",
    CurrencyKind.electrum => "pièces d'électrum",
    CurrencyKind.silver => "pièces d'argent",
    CurrencyKind.copper => 'pièces de cuivre',
  };
}

/// Colonnes `characters.currency_*` valides d'un payload de file `currency`.
const _currencyColumns = {
  'currency_pp',
  'currency_gp',
  'currency_ep',
  'currency_sp',
  'currency_cp',
};

/// [raw] (`{colonne currency_*: total}`) si c'est un objet non vide dont
/// **toutes** les clés sont des colonnes de monnaie connues et toutes les
/// valeurs des entiers `>= 0` ; sinon `null` (payload illisible : jamais
/// rejoué ni superposé — un total absolu douteux écraserait la bourse).
Map<String, int>? validCurrencyTotals(Object? raw) {
  if (raw is! Map || raw.isEmpty) return null;
  final result = <String, int>{};
  for (final entry in raw.entries) {
    final key = entry.key;
    final value = entry.value;
    if (key is! String || !_currencyColumns.contains(key)) return null;
    if (value is! int || value < 0) return null;
    result[key] = value;
  }
  return result;
}
