/// Une classe déjà possédée par le personnage, proposée comme option
/// "Continuer" à l'étape `classDecision` de la montée de niveau
/// (`presentation/level_up_screen.dart`) — une entrée par ligne
/// `character_classes` du personnage, primaire **incluse** (redevenue une
/// option comme les autres, plus un cas spécial câblé en dur dans l'écran).
/// Voir
/// `presentation/providers/level_up_provider.dart::LevelUpStepData.continueOptions`.
///
/// Volontairement une classe simple (pas `freezed`) : même précédent que
/// [LevelUpMulticlassOption] (voir `level_up_multiclass_option.dart`), donnée
/// en lecture seule construite une fois par le provider.
class LevelUpContinueOption {
  const LevelUpContinueOption({
    required this.classId,
    required this.className,
    required this.currentLevel,
    required this.isPrimary,
  });

  /// `classes.id` (entier côté Supabase, gardé en [Object] — même convention
  /// que `CharacterDetailClassRow.classId`/`LevelUpMulticlassOption.classId`).
  final Object classId;

  final String className;

  /// Niveau ACTUEL de cette classe (avant la montée de niveau en cours),
  /// `character_classes.level` — le niveau après ("niveau X → X+1") est
  /// calculé côté écran, jamais stocké ici.
  final int currentLevel;

  /// `true` pour la classe marquée `character_classes.is_primary` — utilisé
  /// uniquement pour la présélection par défaut de l'étape `classDecision`
  /// (voir `presentation/level_up_screen.dart::_LevelUpScreenState`) : ne
  /// change rien au calcul de progression lui-même, qui traite toutes les
  /// classes possédées de façon symétrique.
  final bool isPrimary;
}
