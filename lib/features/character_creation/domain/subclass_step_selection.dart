import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'subclass_choice_catalog.dart';

/// Logique pure d'activation du bouton "Suivant" de l'étape "Sous-classe" de
/// l'assistant de création (`presentation/subclass_step_screen.dart`),
/// atteinte uniquement pour les classes qui choisissent leur sous-classe au
/// niveau 1 — voir `presentation/class_step_screen.dart::_submit`.
///
/// Reprend exactement la même règle que l'ancien `ClassStepScreen
/// ._canProceed` (avant que le choix de sous-classe ne devienne sa propre
/// étape) : si le catalogue est en chargement/erreur, "Suivant" reste
/// désactivé ; une liste d'options vide/absente pour [classId] n'est jamais
/// bloquante (cas défensif, données incomplètes) ; sinon, une option doit
/// être choisie parmi celles de [classId].
abstract final class SubclassStepSelection {
  static bool canProceed({
    required AsyncValue<SubclassChoiceCatalog> catalogAsync,
    required int classId,
    required int? selectedSubclassId,
  }) {
    if (catalogAsync.isLoading || catalogAsync.hasError) return false;
    final options = catalogAsync.value?.optionsFor(classId);
    if (options == null || options.isEmpty) return true;
    return options.any((option) => option.id == selectedSubclassId);
  }
}
