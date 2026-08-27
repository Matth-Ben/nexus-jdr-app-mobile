import 'dart:math' as math;

/// Calcul des points de vie gagnés à une montée de niveau (increment 1,
/// `presentation/level_up_screen.dart`, étape "Points de vie") —
/// `docs/cahier-des-charges/04-fonctionnalites-app-mobile.md` section 6.
///
/// Distinct de `character_creation/domain/hit_points_calculator.dart` : ce
/// dernier calcule les PV de départ (niveau 1), toujours déterministes (dé
/// de vie maximum + modificateur de Constitution, sans choix du joueur) —
/// ici, le joueur choisit entre lancer le dé ou prendre la valeur moyenne à
/// chaque niveau.
abstract final class LevelUpHitPointsCalculator {
  /// Lance le dé de vie de la classe ([hitDie], 6/8/10/12) : un entier entre
  /// 1 et [hitDie] inclus. [random] injectable pour les tests
  /// (déterminisme), `null` par défaut utilise une graine aléatoire réelle.
  static int rollHitDie(int hitDie, [math.Random? random]) {
    final rng = random ?? math.Random();
    return rng.nextInt(hitDie) + 1;
  }

  /// Valeur moyenne officielle (règle alternative 5e) : moitié du dé
  /// arrondie au supérieur, +1 (ex. 5 pour un d8).
  static int averageValue(int hitDie) => (hitDie / 2).ceil() + 1;

  /// Gain de PV maximum/actuels final pour ce niveau : [rolledOrAverageValue]
  /// (résultat de [rollHitDie] ou [averageValue]) + [constitutionModifier],
  /// jamais inférieur à 1 — règle standard 5e (un personnage gagne toujours
  /// au moins 1 PV par niveau, même avec un modificateur de Constitution
  /// négatif), même plancher que
  /// `character_creation/domain/hit_points_calculator.dart::maxHpAtLevel1`.
  static int hpGain({
    required int rolledOrAverageValue,
    required int constitutionModifier,
  }) {
    return math.max(1, rolledOrAverageValue + constitutionModifier);
  }
}
