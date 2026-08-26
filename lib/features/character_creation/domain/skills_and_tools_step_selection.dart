import 'background_option.dart';
import 'class_option.dart';

/// Logique pure de l'étape 5/9 "Compétences et outils" de l'assistant de
/// création, extraite de `presentation/skills_and_tools_step_screen.dart`
/// pour rester testable sans widget — même principe que
/// `RaceStepSelection`/`AbilityScoreRules` des étapes précédentes.
///
/// Cette étape est la plus hétérogène jusqu'ici : jusqu'à 4 sections,
/// chacune affichée seulement si applicable selon la classe/l'historique
/// déjà choisis (étapes 2 et 3) :
/// 1. "COMPÉTENCES DE CLASSE" — toujours affichée.
/// 2. "OUTILS (CLASSE)" — affichée si [isClassToolSectionVisible].
/// 3. "OUTILS (HISTORIQUE)" — affichée si [isBackgroundToolSectionVisible],
///    jamais interactive (octroi automatique) et ne bloque jamais "Suivant".
/// 4. "LANGUES (HISTORIQUE)" — affichée si [isLanguageSectionVisible].
abstract final class SkillsAndToolsStepSelection {
  /// La section 2 "OUTILS (CLASSE)" est affichée dès que la classe a un
  /// choix interactif d'outils ([ClassOption.toolChoice] non `null`) *ou*
  /// un octroi automatique d'outils précis ([ClassOption.grantedToolNames]
  /// non vide) — les deux formes partagent la même section (voir le
  /// commentaire de classe de [ClassOption] pour le rationale), seul le
  /// rendu (interactif ou verrouillé) diffère.
  static bool isClassToolSectionVisible(ClassOption classOption) {
    return classOption.toolChoice != null ||
        classOption.grantedToolNames.isNotEmpty;
  }

  /// La section 3 "OUTILS (HISTORIQUE)" est affichée dès que l'historique a
  /// au moins un outil octroyé automatiquement (`tool_or_language_choices
  /// .tools` non vide).
  static bool isBackgroundToolSectionVisible(BackgroundOption background) {
    return background.toolOrLanguageGrantedTools.isNotEmpty;
  }

  /// La section 4 "LANGUES (HISTORIQUE)" est affichée dès que l'historique a
  /// un nombre de langues au choix strictement positif
  /// (`tool_or_language_choices.languages`).
  static bool isLanguageSectionVisible(BackgroundOption background) {
    return (background.languageChoiceCount ?? 0) > 0;
  }

  /// Une option non cochée d'une section interactive devient "estompée"
  /// (non cliquable tant qu'une autre n'est pas décochée) dès que le quota
  /// de la section est atteint — une option déjà cochée n'est jamais
  /// verrouillée par cette règle (elle doit rester décochable).
  static bool isChoiceLocked({
    required bool isSelected,
    required int selectedCount,
    required int quota,
  }) {
    return !isSelected && selectedCount >= quota;
  }

  /// Bascule [value] dans [current] : le retire s'il y est déjà, l'ajoute
  /// sinon — sauf si le quota est déjà atteint, auquel cas [current] est
  /// renvoyée inchangée (même règle que [isChoiceLocked], dupliquée ici en
  /// garde-fou plutôt que de supposer que l'appelant a bien vérifié
  /// [isChoiceLocked] avant d'appeler [toggle]).
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

  /// "Suivant" ne s'active que lorsque toutes les sections interactives
  /// affichées (1, 2 si présente, 4 si présente) ont atteint EXACTEMENT leur
  /// quota — la section 3 (verrouillée, octroi automatique) ne bloque jamais
  /// "Suivant".
  static bool canProceed({
    required ClassOption classOption,
    required BackgroundOption backgroundOption,
    required List<String> selectedClassSkills,
    required List<String> selectedClassTools,
    required List<String> selectedBackgroundLanguages,
  }) {
    if (selectedClassSkills.length != classOption.skillChoices.count) {
      return false;
    }

    final toolChoice = classOption.toolChoice;
    if (toolChoice != null && selectedClassTools.length != toolChoice.count) {
      return false;
    }

    final languageCount = backgroundOption.languageChoiceCount ?? 0;
    if (languageCount > 0 &&
        selectedBackgroundLanguages.length != languageCount) {
      return false;
    }

    return true;
  }
}
