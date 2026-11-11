/// Mathématiques 3D minimales du dé animé (prototype P2b) : vecteurs,
/// quaternions et projection orthographique. Pur Dart, aucune dépendance à
/// Flutter, pour rester testable sans moteur de rendu.
library;

import 'dart:math' as math;

/// Vecteur 3D immuable. Repère main droite : X vers la droite, Y vers le
/// haut, Z vers l'observateur (la face « frontale » a donc sa normale en +Z).
class Vec3 {
  const Vec3(this.x, this.y, this.z);

  static const Vec3 zero = Vec3(0, 0, 0);
  static const Vec3 unitX = Vec3(1, 0, 0);
  static const Vec3 unitY = Vec3(0, 1, 0);
  static const Vec3 unitZ = Vec3(0, 0, 1);

  final double x;
  final double y;
  final double z;

  Vec3 operator +(Vec3 o) => Vec3(x + o.x, y + o.y, z + o.z);
  Vec3 operator -(Vec3 o) => Vec3(x - o.x, y - o.y, z - o.z);
  Vec3 operator -() => Vec3(-x, -y, -z);
  Vec3 scaled(double k) => Vec3(x * k, y * k, z * k);

  double dot(Vec3 o) => x * o.x + y * o.y + z * o.z;

  Vec3 cross(Vec3 o) =>
      Vec3(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);

  double get length => math.sqrt(dot(this));

  Vec3 normalized() {
    final l = length;
    return l == 0 ? this : scaled(1 / l);
  }

  /// Angle non orienté entre deux vecteurs, en radians.
  double angleTo(Vec3 o) {
    final d = normalized().dot(o.normalized()).clamp(-1.0, 1.0);
    return math.acos(d);
  }

  @override
  bool operator ==(Object other) =>
      other is Vec3 && other.x == x && other.y == y && other.z == z;

  @override
  int get hashCode => Object.hash(x, y, z);

  @override
  String toString() => 'Vec3($x, $y, $z)';
}

/// Quaternion unitaire de rotation (w + xi + yj + zk).
class Quat {
  const Quat(this.w, this.x, this.y, this.z);

  static const Quat identity = Quat(1, 0, 0, 0);

  final double w;
  final double x;
  final double y;
  final double z;

  /// Rotation de [angle] radians autour de [axis] (normalisé ici).
  factory Quat.fromAxisAngle(Vec3 axis, double angle) {
    final a = axis.normalized();
    final s = math.sin(angle / 2);
    return Quat(math.cos(angle / 2), a.x * s, a.y * s, a.z * s);
  }

  /// Rotation qui envoie les vecteurs de base du modèle [right], [up] et
  /// [normal] (orthonormés, main droite) sur X, Y et Z : la face dont c'est
  /// le repère se retrouve face à l'observateur, son « haut » vers le haut.
  factory Quat.fromBasisToAxes(Vec3 right, Vec3 up, Vec3 normal) {
    // Matrice de rotation dont les lignes sont right, up, normal.
    final m00 = right.x, m01 = right.y, m02 = right.z;
    final m10 = up.x, m11 = up.y, m12 = up.z;
    final m20 = normal.x, m21 = normal.y, m22 = normal.z;
    final trace = m00 + m11 + m22;
    double w, x, y, z;
    if (trace > 0) {
      final s = math.sqrt(trace + 1) * 2;
      w = 0.25 * s;
      x = (m21 - m12) / s;
      y = (m02 - m20) / s;
      z = (m10 - m01) / s;
    } else if (m00 > m11 && m00 > m22) {
      final s = math.sqrt(1 + m00 - m11 - m22) * 2;
      w = (m21 - m12) / s;
      x = 0.25 * s;
      y = (m01 + m10) / s;
      z = (m02 + m20) / s;
    } else if (m11 > m22) {
      final s = math.sqrt(1 + m11 - m00 - m22) * 2;
      w = (m02 - m20) / s;
      x = (m01 + m10) / s;
      y = 0.25 * s;
      z = (m12 + m21) / s;
    } else {
      final s = math.sqrt(1 + m22 - m00 - m11) * 2;
      w = (m10 - m01) / s;
      x = (m02 + m20) / s;
      y = (m12 + m21) / s;
      z = 0.25 * s;
    }
    return Quat(w, x, y, z).normalized();
  }

  double get norm => math.sqrt(w * w + x * x + y * y + z * z);

  Quat normalized() {
    final n = norm;
    return n == 0 ? identity : Quat(w / n, x / n, y / n, z / n);
  }

  /// Composition : `(a * b).rotate(v) == a.rotate(b.rotate(v))`.
  Quat operator *(Quat o) => Quat(
    w * o.w - x * o.x - y * o.y - z * o.z,
    w * o.x + x * o.w + y * o.z - z * o.y,
    w * o.y - x * o.z + y * o.w + z * o.x,
    w * o.z + x * o.y - y * o.x + z * o.w,
  );

  Vec3 rotate(Vec3 v) {
    // v' = v + 2w(q × v) + 2 q × (q × v)
    final q = Vec3(x, y, z);
    final t = q.cross(v).scaled(2);
    return v + t.scaled(w) + q.cross(t);
  }
}

/// Projection orthographique déterministe : un point du modèle (rayon du
/// dé = 1) vers un point d'écran (Y vers le bas), centré sur ([cx], [cy]),
/// à l'échelle [radiusPx] pixels par unité.
({double x, double y}) projectOrtho(
  Vec3 p, {
  required double cx,
  required double cy,
  required double radiusPx,
}) => (x: cx + p.x * radiusPx, y: cy - p.y * radiusPx);
