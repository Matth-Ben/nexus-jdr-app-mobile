/// Une classe éligible au multiclassage à l'étape `classDecision` de la
/// montée de niveau (`presentation/level_up_screen.dart`) — voir
/// `presentation/providers/level_up_provider.dart::LevelUpStepData.multiclassOptions`
/// et `domain/multiclass_prerequisites.dart` pour le calcul d'éligibilité.
///
/// Volontairement une classe simple (pas `freezed`) : même précédent que
/// [LevelUpSubclassOption]/[CharacterClassFeature], donnée en lecture seule
/// construite une fois par le provider.
class LevelUpMulticlassOption {
  const LevelUpMulticlassOption({
    required this.classId,
    required this.className,
    required this.satisfiedAbilityLabels,
  });

  /// `classes.id` (entier côté Supabase, gardé en [Object] — même convention
  /// que `CharacterDetailClassRow.classId`).
  final Object classId;

  final String className;

  /// Libellés français des caractéristiques réellement responsables de
  /// l'éligibilité (ex. `['Force']`, jamais `['Force', 'Dextérité']` pour le
  /// Guerrier si seule la Force satisfait le prérequis) — voir
  /// `MulticlassPrerequisites.satisfiedAbilityIds`, spec direction-artistique
  /// section 2 : "Prérequis rempli : {liste des caractéristiques ≥13
  /// effectivement satisfaites}".
  final List<String> satisfiedAbilityLabels;
}
