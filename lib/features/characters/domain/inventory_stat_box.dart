import '../domain/currency_kind.dart';

/// Une "stat box" de la rangée en tête de l'onglet "Inventaire" (montant de
/// monnaie ou compteur d'objets harmonisés) — voir
/// `domain/inventory_stat_boxes_resolver.dart` pour leur construction et
/// `presentation/widgets/character_inventory_stat_boxes_row.dart` pour leur
/// rendu.
///
/// Volontairement une classe simple (pas `freezed`), même précédent que
/// `CharacterSpellEntry`/`CharacterInventoryItem` : donnée en lecture seule
/// déjà entièrement formatée par l'appelant, affichée telle quelle.
class InventoryStatBox {
  const InventoryStatBox({
    required this.value,
    required this.unit,
    this.currency,
  });

  /// Montant déjà formaté (un entier de pièces, ou un ratio "x/y" pour la
  /// box "HARM."), affiché en gros dans la box.
  final String value;

  /// Unité affichée en petit sous [value] ("PO"/"PP"/"PE"/"PA"/"PC"/"HARM.").
  final String unit;

  /// Monnaie représentée par cette box, `null` pour la box "HARM." (compteur
  /// d'objets harmonisés, pas une monnaie ajustable) — voir
  /// `presentation/widgets/character_inventory_stat_boxes_row.dart` : seule
  /// une box dont [currency] est non nul devient cliquable (Flux "Ajuster la
  /// monnaie").
  final CurrencyKind? currency;
}
