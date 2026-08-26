/// Formate un montant en pièces d'or ("po") pour l'affichage à l'étape 7/9
/// "Équipement de départ" ("OR DE DÉPART"/"OR RESTANT"/prix du catalogue
/// d'achat).
///
/// Vérifié contre le contenu peuplé de `items.cost` : les montants ne sont
/// **pas** tous entiers (ex. 0.05 gp pour une flèche, 0.5 gp pour une
/// gourde) — contrairement au montant "Bourse (N po)" des historiques,
/// toujours entier. [format] doit donc gérer les deux cas sans jamais
/// afficher de zéros inutiles ("15" plutôt que "15.0", "2.5" plutôt que
/// "2.50").
///
/// Séparateur décimal "," (virgule française) : app entièrement en
/// français, aucune raison d'afficher un point anglo-saxon (correction
/// direction-artistique) — pas besoin du package `intl` pour autant, un
/// simple remplacement de caractère sur le résultat déjà calculé en "."
/// suffit (`String.replaceFirst`).
abstract final class GoldAmountFormatter {
  static String format(num amount) {
    // Arrondi à 2 décimales avant tout (élimine les imprécisions binaires
    // résiduelles, ex. `0.1 + 0.2`), même règle que les totaux de panier de
    // `EquipmentStepSelection.totalCost`.
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
