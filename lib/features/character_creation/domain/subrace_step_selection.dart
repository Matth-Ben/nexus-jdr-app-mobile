/// Logique pure d'activation du bouton "Suivant" de l'étape "Sous-race" de
/// l'assistant de création (`presentation/subrace_step_screen.dart`),
/// atteinte uniquement pour les races qui ont des sous-races — voir
/// `presentation/race_step_screen.dart::_submit`.
///
/// Même principe que `race_step_selection.dart`, extraite pour rester
/// testable sans widget.
abstract final class SubraceStepSelection {
  static bool canProceed({required int? selectedSubraceId}) =>
      selectedSubraceId != null;
}
