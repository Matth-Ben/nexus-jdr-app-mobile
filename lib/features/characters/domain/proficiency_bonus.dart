/// Bonus de maîtrise D&D 5e standard, calculé sur le niveau **total** d'un
/// personnage (`character_detail.dart`, `CharacterDetail.totalLevel` —
/// somme de `character_classes.level` sur toutes les lignes, multiclassage
/// inclus), pas sur le niveau d'une classe en particulier.
///
/// Aucune fonction équivalente n'existait déjà dans ce dépôt avant la fiche
/// personnage (l'assistant de création ne va jamais au-delà du niveau 1,
/// donc jamais eu besoin de la table complète) — table officielle 5e :
/// +2 aux niveaux 1-4, +3 aux niveaux 5-8, +4 aux niveaux 9-12, +5 aux
/// niveaux 13-16, +6 aux niveaux 17-20.
abstract final class ProficiencyBonusRules {
  static const int _minLevel = 1;
  static const int _maxLevel = 20;

  /// Bonus de maîtrise pour [totalLevel]. [totalLevel] est borné entre 1 et
  /// 20 (une valeur hors bornes ne lève pas d'erreur, pour rester robuste
  /// face à une donnée serveur incohérente — même règle que
  /// `XpTable.cumulativeXpForLevel`).
  static int forTotalLevel(int totalLevel) {
    final level = totalLevel.clamp(_minLevel, _maxLevel);
    if (level <= 4) return 2;
    if (level <= 8) return 3;
    if (level <= 12) return 4;
    if (level <= 16) return 5;
    return 6;
  }
}
