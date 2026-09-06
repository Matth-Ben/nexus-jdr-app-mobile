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

  /// Nouveau niveau TOTAL du personnage (somme de `character_classes.level`
  /// sur toutes les lignes) après écriture — **jamais** le niveau interne à
  /// la seule classe qui vient de progresser : depuis le multiclassage
  /// (`data/character_repository.dart::applyLevelUp`), une classe fraîchement
  /// multiclassée démarre à son niveau 1 alors que le niveau total du
  /// personnage peut être bien plus élevé. [LevelUpScreen] a besoin du niveau
  /// TOTAL pour enchaîner correctement sur le seuil XP suivant
  /// (`domain/level_up_chain_resolver.dart`) et l'afficher dans son en-tête
  /// ("NIVEAU N") — jamais du niveau interne à une classe précise. Pour un
  /// personnage à une seule classe (tous les personnages avant cet
  /// incrément), niveau total == niveau de cette classe, comportement
  /// inchangé.
  final int newLevel;

  final int newMaxHp;
  final int newCurrentHp;
}
