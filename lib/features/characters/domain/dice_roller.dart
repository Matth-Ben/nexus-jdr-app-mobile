import 'dart:math';

/// Mode d'un jet de d20 : normal, avec avantage (on garde le plus haut de
/// deux d20) ou avec désavantage (on garde le plus bas). Saisi par le joueur,
/// jamais déduit ni persisté (P2, décision du 11/11/2026).
enum RollMode { normal, advantage, disadvantage }

/// Résultat d'un jet de d20 avec modificateur. Les deux dés tirés sont
/// conservés ([dice]) même quand l'un est écarté.
class RollResult {
  const RollResult({
    required this.dice,
    required this.kept,
    required this.modifier,
    required this.mode,
  });

  /// Dés tirés dans l'ordre : 1 en mode normal, 2 avec avantage/désavantage.
  final List<int> dice;

  /// Dé retenu : le max (avantage), le min (désavantage) ou l'unique dé.
  final int kept;

  final int modifier;
  final RollMode mode;

  int get total => kept + modifier;

  /// Dé écarté (`null` en mode normal). À égalité, c'est le second dé.
  int? get discarded {
    if (dice.length < 2) return null;
    return kept == dice[0] ? dice[1] : dice[0];
  }

  /// Indice du dé écarté dans [dice] (`null` en mode normal) : le second en
  /// cas d'égalité.
  int? get discardedIndex {
    if (dice.length < 2) return null;
    return kept == dice[0] ? 1 : 0;
  }

  /// 20 naturel / 1 naturel : toujours évalués sur le dé GARDÉ, jamais sur le
  /// dé écarté.
  bool get isNaturalTwenty => kept == 20;
  bool get isNaturalOne => kept == 1;
}

/// Tirage pur de dés — "mini lancer de dé virtuel" des jets de
/// compétences/caractéristiques de la fiche personnage, voir
/// `docs/cahier-des-charges/11-fonctionnalites-a-ajouter.md`, section
/// "Onglet Compétences".
///
/// [random] injectable (défaut `Random()`, non déterministe) pour rester
/// testable — un test qui appellerait `Random()` directement ne pourrait
/// jamais vérifier une valeur précise, seulement un intervalle.
abstract final class DiceRoller {
  /// Résultat entre 1 et 20 inclus.
  static int rollD20({Random? random}) => rollDie(20, random: random);

  /// Un dé à [sides] faces : résultat entre 1 et [sides] inclus.
  static int rollDie(int sides, {Random? random}) {
    assert(sides >= 2, 'Un dé a au moins 2 faces.');
    return (random ?? Random()).nextInt(sides) + 1;
  }

  /// Jet de d20 avec [mode] et [modifier]. Le premier dé est tiré d'abord,
  /// puis le second seulement avec avantage/désavantage (en mode normal, la
  /// séquence de [random] est donc identique à [rollD20]).
  static RollResult rollD20Check({
    RollMode mode = RollMode.normal,
    int modifier = 0,
    Random? random,
  }) {
    final rng = random ?? Random();
    final first = rollDie(20, random: rng);
    if (mode == RollMode.normal) {
      return RollResult(
        dice: [first],
        kept: first,
        modifier: modifier,
        mode: mode,
      );
    }
    final second = rollDie(20, random: rng);
    final kept = mode == RollMode.advantage
        ? max(first, second)
        : min(first, second);
    return RollResult(
      dice: [first, second],
      kept: kept,
      modifier: modifier,
      mode: mode,
    );
  }
}
