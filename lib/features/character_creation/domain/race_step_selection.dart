/// Logique pure d'activation du bouton "Suivant" de l'étape 1/9 (Race) de
/// l'assistant de création, extraite de `presentation/race_step_screen.dart`
/// pour rester testable sans widget.
///
/// Règles tranchées par le chef de projet (voir la tâche qui a produit ce
/// fichier) :
/// - Race personnalisée (homebrew) sélectionnée : le texte libre doit être
///   non vide (hors espaces).
/// - Race du catalogue sélectionnée : suffisant, sauf si cette race a des
///   sous-races, auquel cas une sous-race doit aussi être choisie.
/// - Aucune race sélectionnée : jamais activé.
abstract final class RaceStepSelection {
  static bool canProceed({
    required bool isCustomRace,
    required String customRaceText,
    required int? selectedRaceId,
    required bool selectedRaceHasSubraces,
    required int? selectedSubraceId,
  }) {
    if (isCustomRace) {
      return customRaceText.trim().isNotEmpty;
    }
    if (selectedRaceId == null) {
      return false;
    }
    if (selectedRaceHasSubraces && selectedSubraceId == null) {
      return false;
    }
    return true;
  }
}
