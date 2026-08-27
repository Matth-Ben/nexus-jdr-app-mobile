import 'xp_table.dart';

/// Détermine si un personnage a déjà, avec son XP actuelle, franchi un ou
/// plusieurs seuils *au-delà* d'un niveau donné — sert au chaînage
/// automatique de l'écran de montée de niveau
/// (`presentation/level_up_screen.dart`) : "Si le gain d'XP fait franchir
/// plusieurs seuils d'un coup, l'app enchaîne les montées de niveau une par
/// une" (`docs/cahier-des-charges/04-fonctionnalites-app-mobile.md`
/// section 5).
///
/// Logique pure sur [XpTable], jamais de dépendance réseau : le
/// personnage n'a qu'une seule classe gérée par l'app (pas de
/// multiclassage), donc le niveau total == le niveau de la classe primaire
/// (voir `data/character_repository.dart::applyLevelUp`).
abstract final class LevelUpChainResolver {
  /// `true` si le seuil XP du niveau `targetLevel + 1` est déjà atteint par
  /// [currentXp] — l'app doit alors enchaîner directement sur ce niveau
  /// suivant plutôt que de revenir à la fiche personnage (sous réserve que
  /// ce niveau suivant ne soit pas lui-même bloqué, revérifié séparément par
  /// `domain/level_up_block_reason.dart::LevelUpBlockRules.evaluate`).
  static bool hasNextLevelAlreadyUnlocked({
    required int targetLevel,
    required int currentXp,
  }) {
    if (targetLevel >= XpTable.maxLevel) return false;
    final nextThreshold = XpTable.cumulativeXpForLevel(targetLevel + 1);
    return currentXp >= nextThreshold;
  }

  /// Nombre de niveaux, au-delà de [targetLevel], déjà déverrouillés par
  /// [currentXp] — alimente le sous-titre optionnel "Encore {k} niveau(x) à
  /// valider ensuite" du header du flux (spec visuelle direction-artistique
  /// section 0), affiché uniquement si le résultat est strictement positif.
  static int remainingLevelsAfter({
    required int targetLevel,
    required int currentXp,
  }) {
    var level = targetLevel;
    while (level < XpTable.maxLevel &&
        currentXp >= XpTable.cumulativeXpForLevel(level + 1)) {
      level++;
    }
    return level - targetLevel;
  }
}
