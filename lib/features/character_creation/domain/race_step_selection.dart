/// Logique pure d'activation du bouton "Suivant" de l'étape 1/9 (Race) de
/// l'assistant de création, extraite de `presentation/race_step_screen.dart`
/// pour rester testable sans widget.
///
/// Règles tranchées par le chef de projet (voir la tâche qui a produit ce
/// fichier) :
/// - Race personnalisée (homebrew) sélectionnée : le texte libre doit être
///   non vide (hors espaces).
/// - Race du catalogue sélectionnée : suffisant.
/// - Aucune race sélectionnée : jamais activé.
///
/// Le choix de sous-race n'est plus une condition de CETTE étape : les races
/// qui en ont sont envoyées vers `SubraceStepScreen` (sa propre étape, voir
/// `domain/subrace_step_selection.dart`), atteinte après validation de la
/// race — voir `presentation/race_step_screen.dart::_submit`.
abstract final class RaceStepSelection {
  static bool canProceed({
    required bool isCustomRace,
    required String customRaceText,
    required int? selectedRaceId,
  }) {
    if (isCustomRace) {
      return customRaceText.trim().isNotEmpty;
    }
    return selectedRaceId != null;
  }
}
