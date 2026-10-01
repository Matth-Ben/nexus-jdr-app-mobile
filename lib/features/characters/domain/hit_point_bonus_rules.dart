/// Bonus de points de vie maximum hors dé de vie et Constitution, ajoutés à
/// la création (`HitPointsCalculator`) et à chaque montée de niveau
/// (`LevelUpHitPointsCalculator`) :
///
/// - Nain des collines (Robustesse naine) : +1 par niveau de personnage ;
/// - don Tough (« Robuste physiquement » en base — « Robuste » y désigne
///   Resilient) : +2 par niveau de personnage (rétroactif quand le don est
///   pris : +2 × niveau atteint) ;
/// - Ensorceleur du Lignage draconique (Résilience draconique) : +1 par
///   niveau d'Ensorceleur ;
/// - Faveur de robustesse (faveur épique) : +40 une fois, quand elle est
///   prise.
///
/// Et la règle de rétroactivité de la Constitution : quand son modificateur
/// augmente, les PV maximum augmentent de la différence × niveau total.
///
/// Noms comparés en français (`translations`), même principe que
/// `ArmorClassCalculator`.
abstract final class HitPointBonusRules {
  static const String hillDwarfSubraceName = 'Nain des collines';
  static const String toughFeatName = 'Robuste physiquement';
  static const String fortitudeBoonName = 'Faveur de robustesse';
  static const int fortitudeBoonHitPoints = 40;
  static const String sorcererClassName = 'Ensorceleur';
  static const String draconicSubclassName = 'Lignage draconique';

  /// Bonus du niveau gagné : [subraceName] du personnage, [hasToughFeat]
  /// (don déjà possédé), et la classe qui progresse ce niveau
  /// ([levelingClassName]/[levelingSubclassName]).
  static int perLevelBonus({
    required String? subraceName,
    required bool hasToughFeat,
    required String levelingClassName,
    required String? levelingSubclassName,
  }) {
    var bonus = 0;
    if (subraceName == hillDwarfSubraceName) bonus += 1;
    if (hasToughFeat) bonus += 2;
    if (levelingClassName == sorcererClassName &&
        levelingSubclassName == draconicSubclassName) {
      bonus += 1;
    }
    return bonus;
  }

  /// PV maximum gagnés rétroactivement en prenant le don Robuste au niveau
  /// total [totalLevel] (ce niveau inclus).
  static int toughFeatRetroactiveBonus(int totalLevel) => 2 * totalLevel;

  /// PV maximum gagnés en prenant le don [featName] au niveau total
  /// [totalLevel] : Robuste physiquement (rétroactif) ou Faveur de
  /// robustesse, 0 pour tout autre don.
  static int featTakenBonus({
    required String? featName,
    required int totalLevel,
  }) => switch (featName) {
    toughFeatName => toughFeatRetroactiveBonus(totalLevel),
    fortitudeBoonName => fortitudeBoonHitPoints,
    _ => 0,
  };

  /// PV maximum gagnés quand la Constitution passe de [oldScore] à
  /// [newScore], pour un personnage de niveau total [totalLevel] — 0 si le
  /// modificateur ne change pas.
  static int constitutionRetroactiveBonus({
    required int oldScore,
    required int newScore,
    required int totalLevel,
  }) {
    int modifier(int score) => ((score - 10) / 2).floor();
    return (modifier(newScore) - modifier(oldScore)) * totalLevel;
  }
}
