/// Logique pure d'activation du bouton "Suivant" de l'étape "Lignée" de
/// l'assistant de création (`presentation/lineage_step_screen.dart`),
/// atteinte uniquement pour les races qui ont des lignées 2024 sans
/// sous-race — voir `presentation/race_step_screen.dart::_submit`.
///
/// Même principe que `subrace_step_selection.dart`, extraite pour rester
/// testable sans widget.
abstract final class LineageStepSelection {
  static bool canProceed({required int? selectedLineageId}) =>
      selectedLineageId != null;
}
