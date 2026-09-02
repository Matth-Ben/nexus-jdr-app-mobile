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
