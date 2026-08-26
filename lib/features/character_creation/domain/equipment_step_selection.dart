import 'equipment_choice_tab.dart';
import 'item_option.dart';

/// Logique pure de l'étape 7/9 "Équipement de départ" de l'assistant de
/// création, extraite de `presentation/equipment_step_screen.dart` pour
/// rester testable sans widget — même principe que
/// `SkillsAndToolsStepSelection`/`SpellsStepSelection` des étapes
/// précédentes.
abstract final class EquipmentStepSelection {
  /// Coût total du panier de l'onglet "Acheter" (`{nom d'objet: quantité}`,
  /// même convention noms-plutôt-qu'ids que `CharacterCreationDraft`, voir
  /// son commentaire de classe) contre le catalogue [items] fourni. Une
  /// entrée du panier sans correspondance dans [items] ne contribue rien au
  /// total plutôt que de crasher (ne devrait normalement jamais arriver : le
  /// panier n'est peuplé qu'à partir de [items] lui-même, voir
  /// `presentation/equipment_step_screen.dart`).
  static double totalCost({
    required Map<String, int> cart,
    required List<ItemOption> items,
  }) {
    final costByName = {for (final item in items) item.name: item.costAmount};
    var total = 0.0;
    for (final entry in cart.entries) {
      final unitCost = costByName[entry.key];
      if (unitCost == null) continue;
      total += unitCost * entry.value;
    }
    // Arrondi à 2 décimales : élimine les imprécisions binaires résiduelles
    // de l'accumulation en virgule flottante (ex. `0.1 + 0.2`), avant toute
    // comparaison au budget.
    return double.parse(total.toStringAsFixed(2));
  }

  /// "OR RESTANT" affiché par l'onglet "Acheter" : peut être négatif (budget
  /// dépassé, voir [isOverBudget]).
  static double remainingGold({
    required int startingGold,
    required double spent,
  }) {
    return startingGold - spent;
  }

  /// `true` ssi le panier dépasse le budget de départ — bloque "Suivant"
  /// (voir [canProceed]) et remplace le bandeau "OR RESTANT" par le bandeau
  /// d'alerte inline (voir `presentation/equipment_step_screen.dart`).
  static bool isOverBudget(double remainingGold) => remainingGold < 0;

  /// "Suivant" est toujours actif sur l'onglet "Historique" (équipement
  /// automatiquement accordé, rien à valider). Sur l'onglet "Acheter", actif
  /// tant que le budget n'est pas dépassé — même si rien n'est acheté
  /// (décision du chef de projet, voir la consigne d'origine).
  static bool canProceed({
    required EquipmentChoiceTab activeTab,
    required double remainingGold,
  }) {
    if (activeTab == EquipmentChoiceTab.purchase) {
      return !isOverBudget(remainingGold);
    }
    return true;
  }

  /// Met à jour la quantité de [name] dans [current] (panier de l'onglet
  /// "Acheter") : une quantité `<= 0` retire l'entrée plutôt que de garder
  /// une clé à 0 (le panier ne porte que des objets réellement choisis, même
  /// convention que les listes de choix des étapes précédentes qui ne
  /// portent jamais d'entrée "non choisie").
  static Map<String, int> setQuantity({
    required Map<String, int> current,
    required String name,
    required int quantity,
  }) {
    final next = Map<String, int>.from(current);
    if (quantity <= 0) {
      next.remove(name);
    } else {
      next[name] = quantity;
    }
    return next;
  }
}
