import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'subclass_feature_choice.dart';

/// Logique pure d'activation du bouton "Suivant" de l'étape "Sous-classe"
/// pour le SECOND choix de niveau 1 propre à la sous-classe (ex. Ancêtre
/// draconique) — correctif D99 (`docs/dette-technique.md`), même rationale
/// et même structure que `SubclassStepSelection` (choix de SOUS-CLASSE
/// elle-même) : si le catalogue est en chargement/erreur, "Suivant" reste
/// désactivé ; une sous-classe sans second choix (immense majorité) ou à
/// options vides (cas défensif, données incomplètes — voir D95 du registre
/// de dette technique) n'est jamais bloquante ; sinon, une option doit être
/// choisie.
abstract final class SubclassFeatureChoiceSelection {
  static bool canProceed({
    required AsyncValue<SubclassFeatureChoice?> catalogAsync,
    required String? selectedOptionName,
  }) {
    if (catalogAsync.isLoading || catalogAsync.hasError) return false;
    final choice = catalogAsync.value;
    if (choice == null || choice.options.isEmpty) return true;
    return choice.options.any((option) => option.name == selectedOptionName);
  }
}
