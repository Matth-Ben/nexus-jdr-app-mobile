import 'character_class_feature.dart';

/// Aptitudes/choix `class_features` d'un niveau ciblé donné, pour la classe
/// primaire d'un personnage — voir
/// `data/character_repository.dart::fetchLevelUpLevelData`.
///
/// Volontairement une classe simple (pas `freezed`) : même précédent que
/// [CharacterClassFeature], donnée en lecture seule construite une fois par
/// le repository.
class LevelUpLevelData {
  const LevelUpLevelData({
    required this.blockingChoiceType,
    required this.automaticFeatures,
  });

  /// `class_features.choice_type` de la première ligne de ce niveau dont
  /// `choice_type` est non nul, `null` si aucune (voir
  /// `domain/level_up_block_reason.dart::LevelUpBlockRules.evaluate`,
  /// condition 1).
  final String? blockingChoiceType;

  /// Aptitudes automatiques de ce niveau (`choice_type IS NULL`), noms déjà
  /// résolus via `translations` — étape "Aptitudes de classe automatiques"
  /// et récapitulatif.
  final List<CharacterClassFeature> automaticFeatures;
}
