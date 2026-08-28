import 'character_class_feature.dart';
import 'level_up_subclass_option.dart';

/// Aptitudes/choix `class_features` d'un niveau ciblé donné, pour la classe
/// primaire d'un personnage — voir
/// `data/character_repository.dart::fetchLevelUpLevelData`.
///
/// Volontairement une classe simple (pas `freezed`) : même précédent que
/// [CharacterClassFeature], donnée en lecture seule construite une fois par
/// le repository.
class LevelUpLevelData {
  const LevelUpLevelData({
    required this.choiceType,
    required this.automaticFeatures,
    this.choiceClassFeatureId,
    this.availableSubclasses = const [],
  });

  /// `class_features.choice_type` de la première ligne de ce niveau dont
  /// `choice_type` est non nul, `null` si aucune.
  ///
  /// Nommé `choiceType` depuis l'increment 2 (renommé depuis
  /// `blockingChoiceType`) : ce champ ne bloque plus systématiquement le
  /// flux — `'sous_classe'`/`'style_combat'`/`'ennemi_jure'` mènent
  /// désormais à l'étape "Choix à faire" (voir
  /// `domain/level_up_choice_kind.dart::LevelUpPendingChoiceResolver`),
  /// seules les autres valeurs (ex. `'invocation'`) bloquent encore — voir
  /// `domain/level_up_block_reason.dart::LevelUpBlockRules.evaluate`.
  final String? choiceType;

  /// Aptitudes automatiques de ce niveau (`choice_type IS NULL`), noms déjà
  /// résolus via `translations` — étape "Aptitudes de classe automatiques"
  /// et récapitulatif.
  final List<CharacterClassFeature> automaticFeatures;

  /// `class_features.id` de la ligne [choiceType], nécessaire pour écrire
  /// `character_class_options.class_feature_id` (style de combat/ennemi
  /// juré) à l'étape "Choix à faire" — voir
  /// `data/character_repository.dart::applyLevelUp`. `null` si [choiceType]
  /// est `null`, ou n'a simplement pas encore été renseigné par l'appelant
  /// (ex. dans les tests). Pas nécessaire pour `'sous_classe'` (écrit
  /// directement dans `character_classes.subclass_id`), mais renseigné
  /// quand même dans ce cas par le repository, sans conséquence.
  final int? choiceClassFeatureId;

  /// Sous-classes disponibles à ce niveau, résolues (id/nom/description) —
  /// non vide seulement quand [choiceType] vaut `'sous_classe'`.
  final List<LevelUpSubclassOption> availableSubclasses;
}
