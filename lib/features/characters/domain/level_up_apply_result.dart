/// Résultat de `CharacterRepository.applyLevelUp` : les nouvelles valeurs
/// effectivement écrites en base, pour permettre à l'écran de montée de
/// niveau de décider d'enchaîner sur le niveau suivant (voir
/// `domain/level_up_chain_resolver.dart`) sans avoir à recharger toute la
/// fiche personnage avant de savoir si un autre seuil est déjà franchi.
///
/// Volontairement une classe simple (pas `freezed`) : donnée éphémère
/// retournée par un seul appel, jamais stockée ni comparée structurellement.
class LevelUpApplyResult {
  const LevelUpApplyResult({
    required this.newLevel,
    required this.newMaxHp,
    required this.newCurrentHp,
  });

  /// Nouveau niveau de la classe primaire (`character_classes.level`) après
  /// écriture.
  final int newLevel;

  final int newMaxHp;
  final int newCurrentHp;
}
