/// Table d'orientation du d20 : pour chaque résultat 1..20, la rotation qui
/// amène la face portant ce chiffre face à l'observateur, chiffre à
/// l'endroit.
library;

import 'dart:math' as math;

import 'die_math.dart';
import 'icosahedron.dart';

/// Légère inclinaison d'arrivée (le dé « repose » vu un peu de dessus, ce
/// qui laisse voir les faces voisines) — bien en deçà de la tolérance de
/// 15° de la spec.
const double kRestTiltRadians = 8 * math.pi / 180;

/// Tolérance de la spec : la normale de la face cible reste à moins de 15°
/// de l'axe caméra, et le haut du chiffre à moins de 15° de la verticale.
const double kOrientationToleranceRadians = 15 * math.pi / 180;

abstract final class D20Orientation {
  static final Quat _tilt = Quat.fromAxisAngle(Vec3.unitX, kRestTiltRadians);

  /// Rotation sans inclinaison : normale de la face -> +Z, haut du chiffre
  /// -> +Y.
  static Quat faceToCamera(int faceIndex) => Quat.fromBasisToAxes(
    Icosahedron.rights[faceIndex],
    Icosahedron.ups[faceIndex],
    Icosahedron.normals[faceIndex],
  );

  /// Orientation d'arrivée pour chaque résultat ; index 0 inutilisé.
  static final List<Quat> table = List.unmodifiable([
    Quat.identity,
    for (var value = 1; value <= Icosahedron.faceCount; value++)
      _tilt * faceToCamera(Icosahedron.faceIndexOf(value)),
  ]);

  /// Orientation d'arrivée du résultat [value] (1..20).
  static Quat forValue(int value) {
    assert(value >= 1 && value <= Icosahedron.faceCount, 'valeur : $value');
    return table[value];
  }

  /// Centre de la face portant [value] une fois le dé posé, en unités du
  /// modèle (rayon circonscrit = 1), repère de l'observateur (Y vers le
  /// haut) : sert à placer la pastille du chiffre.
  static Vec3 restCenter(int value) =>
      forValue(value)
          .rotate(Icosahedron.centers[Icosahedron.faceIndexOf(value)]);
}
