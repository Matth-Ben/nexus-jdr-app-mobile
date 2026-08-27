/// Formate un poids en kilogrammes pour l'onglet "Inventaire" (poids de
/// chaque ligne, poids total de la rangée de stat boxes — voir
/// `domain/inventory_stat_boxes_resolver.dart`).
///
/// Duplique volontairement l'algorithme de
/// `character_creation/domain/gold_amount_formatter.dart::GoldAmountFormatter`
/// (même rationale de duplication cross-feature que partout ailleurs dans ce
/// dépôt) : `items.weight` est, comme `items.cost`, une colonne `numeric`
/// pas toujours entière dans le contenu peuplé (ex. 0.1 kg pour un gourdin,
/// 0.5 kg pour une dague) — [format] doit donc éviter tout zéro inutile
/// ("1" plutôt que "1.0", "2,5" plutôt que "2.50"), avec le même séparateur
/// décimal "," (app entièrement en français).
abstract final class WeightFormatter {
  static String format(num amount) {
    // Arrondi à 2 décimales avant tout (élimine les imprécisions binaires
    // résiduelles, ex. `0.1 + 0.2`), même règle que `GoldAmountFormatter`.
    final rounded = double.parse(amount.toStringAsFixed(2));

    if (rounded == rounded.truncateToDouble()) {
      return rounded.truncate().toString();
    }

    var text = rounded.toStringAsFixed(2);
    if (text.endsWith('0')) {
      text = text.substring(0, text.length - 1);
    }
    return text.replaceFirst('.', ',');
  }
}
