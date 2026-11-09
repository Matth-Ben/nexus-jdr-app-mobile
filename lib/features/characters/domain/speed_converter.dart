/// Conversion de la vitesse de déplacement des races.
///
/// `races.speed` est stocké en PIEDS (25/30/35/40, valeurs du PHB), alors que
/// l'app est entièrement métrique (kg, mètres) : la conversion se fait à
/// l'affichage uniquement, la base reste en pieds. Règle 5e officielle :
/// 1,5 m par tranche de 5 pieds (30 pi -> 9 m), soit `pieds * 0,3`.
abstract final class SpeedConverter {
  /// Convertit [feet] (pieds) en mètres (30 -> 9, 25 -> 7,5, 35 -> 10,5).
  /// Calcul fait en entiers (`feet * 3 / 10`) : exact pour tout multiple de 5.
  static double feetToMetres(int feet) => feet * 3 / 10;
}
