import 'level_up_choice_kind.dart';

/// Choix effectué par le joueur à l'étape "Choix à faire" (increment 2),
/// prêt à être écrit par `CharacterRepository.applyLevelUp` — voir
/// `presentation/level_up_screen.dart` et [LevelUpChoiceKind] pour la
/// détermination du type de choix attendu à un niveau donné.
///
/// Volontairement une seule classe à constructeurs nommés (pas une
/// hiérarchie scellée) : même précédent que le reste de ce dépôt, où aucun
/// type union `freezed` n'existe encore — un seul groupe de champs pertinent
/// par [kind], chaque constructeur nommé ne renseigne que les siens.
class LevelUpChoiceSelection {
  const LevelUpChoiceSelection.abilityScoreImprovement(this.abilityAllocations)
    : kind = LevelUpChoiceKind.abilityScoreImprovement,
      subclassId = null,
      classFeatureId = null,
      chosenValue = null;

  const LevelUpChoiceSelection.subclass(this.subclassId)
    : kind = LevelUpChoiceKind.subclass,
      abilityAllocations = null,
      classFeatureId = null,
      chosenValue = null;

  const LevelUpChoiceSelection.fightingStyle({
    required this.classFeatureId,
    required this.chosenValue,
  }) : kind = LevelUpChoiceKind.fightingStyle,
       abilityAllocations = null,
       subclassId = null;

  const LevelUpChoiceSelection.favoredEnemy({
    required this.classFeatureId,
    required this.chosenValue,
  }) : kind = LevelUpChoiceKind.favoredEnemy,
       abilityAllocations = null,
       subclassId = null;

  final LevelUpChoiceKind kind;

  /// [kind] == [LevelUpChoiceKind.abilityScoreImprovement] uniquement :
  /// clés 'str'/'dex'/'con'/'int'/'wis'/'cha' -> points alloués (1 ou 2),
  /// seules les caractéristiques effectivement augmentées sont présentes
  /// (budget total 2, jamais d'entrée à 0 — voir
  /// `presentation/level_up_screen.dart::_AllocationRow`).
  final Map<String, int>? abilityAllocations;

  /// [kind] == [LevelUpChoiceKind.subclass] uniquement : `subclasses.id`
  /// choisi, écrit dans `character_classes.subclass_id`.
  final Object? subclassId;

  /// [kind] == [LevelUpChoiceKind.fightingStyle] ou
  /// [LevelUpChoiceKind.favoredEnemy] uniquement : `class_features.id` de la
  /// ligne `choice_type` concernée (voir
  /// `domain/level_up_level_data.dart::choiceClassFeatureId`), écrit dans
  /// `character_class_options.class_feature_id`.
  final int? classFeatureId;

  /// [kind] == [LevelUpChoiceKind.fightingStyle] ou
  /// [LevelUpChoiceKind.favoredEnemy] uniquement : libellé choisi dans
  /// `domain/level_up_choice_options.dart`, écrit dans
  /// `character_class_options.chosen_value`.
  final String? chosenValue;
}
