/// Logique pure de l'étape 6/9 "Sorts" de l'assistant de création, extraite
/// de `presentation/spells_step_screen.dart` pour rester testable sans
/// widget — même principe que `SkillsAndToolsStepSelection` de l'étape 5/9.
///
/// [toggle]/[isChoiceLocked] sont des duplicatas volontaires de leurs
/// homonymes sur `SkillsAndToolsStepSelection` (logique identique : bascule
/// une valeur dans une liste bornée par un quota) plutôt qu'une factorisation
/// commune — même rationale que `ToolRowMapper` dupliqué depuis
/// `RaceRowMapper` : ne jamais coupler deux étapes de l'assistant entre elles
/// pour un bout de logique générique partagé.
abstract final class SpellsStepSelection {
  /// Une option non cochée devient "estompée" (non cliquable tant qu'une
  /// autre n'est pas décochée) dès que le quota de l'onglet actif est
  /// atteint — un sort déjà coché n'est jamais verrouillé par cette règle.
  static bool isChoiceLocked({
    required bool isSelected,
    required int selectedCount,
    required int quota,
  }) {
    return !isSelected && selectedCount >= quota;
  }

  /// Bascule [value] dans [current] : le retire s'il y est déjà, l'ajoute
  /// sinon — sauf si le quota est déjà atteint, auquel cas [current] est
  /// renvoyée inchangée (garde-fou, même règle que [isChoiceLocked]).
  static List<String> toggle({
    required List<String> current,
    required String value,
    required int quota,
  }) {
    if (current.contains(value)) {
      return List<String>.from(current)..remove(value);
    }
    if (current.length >= quota) {
      return current;
    }
    return List<String>.from(current)..add(value);
  }

  /// "Suivant" ne s'active que lorsque chaque onglet visible
  /// (quota > 0, voir `SpellcastingRules`) a atteint EXACTEMENT son quota —
  /// un onglet masqué (quota nul, ex. "Mineurs" pour un Paladin) ne bloque
  /// jamais "Suivant".
  static bool canProceed({
    required int cantripQuota,
    required List<String> selectedCantrips,
    required int levelOneSpellQuota,
    required List<String> selectedLevelOneSpells,
  }) {
    if (cantripQuota > 0 && selectedCantrips.length != cantripQuota) {
      return false;
    }
    if (levelOneSpellQuota > 0 &&
        selectedLevelOneSpells.length != levelOneSpellQuota) {
      return false;
    }
    return true;
  }
}
