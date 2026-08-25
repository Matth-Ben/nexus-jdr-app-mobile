/// Table de progression XP standard D&D 5e, identique quelle que soit la
/// classe (`docs/cahier-des-charges/04-fonctionnalites-app-mobile.md`
/// section 6).
///
/// Encodée ici comme constante applicative plutôt qu'en table Supabase
/// (conforme à `02-modele-donnees.md`, note sur `characters.xp`) — réutilisée
/// par la liste des personnages (jauge XP), et plus tard par la fiche
/// personnage et l'écran de montée de niveau.
abstract final class XpTable {
  /// Niveau maximum couvert par la table de progression.
  static const int maxLevel = 20;

  /// XP cumulée minimale requise pour atteindre chaque niveau, index 0 =
  /// niveau 1 (toujours 0 XP).
  static const List<int> _cumulativeXpByLevel = [
    0, // Niveau 1
    300, // Niveau 2
    900, // Niveau 3
    2700, // Niveau 4
    6500, // Niveau 5
    14000, // Niveau 6
    23000, // Niveau 7
    34000, // Niveau 8
    48000, // Niveau 9
    64000, // Niveau 10
    85000, // Niveau 11
    100000, // Niveau 12
    120000, // Niveau 13
    140000, // Niveau 14
    165000, // Niveau 15
    195000, // Niveau 16
    225000, // Niveau 17
    265000, // Niveau 18
    305000, // Niveau 19
    355000, // Niveau 20
  ];

  /// XP cumulée minimale pour atteindre [level]. [level] est borné entre 1
  /// et [maxLevel] (une valeur hors bornes ne lève pas d'erreur, pour rester
  /// robuste face à une donnée serveur incohérente).
  static int cumulativeXpForLevel(int level) {
    final clampedLevel = level.clamp(1, maxLevel);
    return _cumulativeXpByLevel[clampedLevel - 1];
  }

  /// XP cumulée requise pour passer de [level] au niveau suivant.
  ///
  /// Retourne `null` si [level] est déjà au niveau maximum (pas de niveau
  /// suivant, la jauge doit alors être affichée pleine).
  static int? cumulativeXpForNextLevel(int level) {
    final clampedLevel = level.clamp(1, maxLevel);
    if (clampedLevel >= maxLevel) {
      return null;
    }
    return cumulativeXpForLevel(clampedLevel + 1);
  }
}
