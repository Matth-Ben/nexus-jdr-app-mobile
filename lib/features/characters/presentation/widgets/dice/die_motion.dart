/// Chronologie et mouvement du dé animé (P2b) : fonctions pures du temps,
/// sans état ni allocation dans le chemin chaud (l'objet [DiePose] est
/// réutilisé image après image).
library;

import 'dart:math' as math;

import 'package:flutter/animation.dart';

import '../../../domain/dice3d/die_math.dart';

/// Pose du dé à un instant : orientation (quaternion), décalage horizontal
/// (fraction de la largeur du plateau), hauteur (0 = au sol), échelle.
class DiePose {
  double qw = 1;
  double qx = 0;
  double qy = 0;
  double qz = 0;
  double offsetX = 0;
  double lift = 0;
  double scale = 1;
}

abstract final class DieTimeline {
  /// Durée d'un lancer (spec : 1 400 ms).
  static const int rollMs = 1400;

  /// Décalage du second dé en avantage/désavantage.
  static const int staggerMs = 120;

  /// Fondu du résultat (formule, pastille, halo) en fin de lancer.
  static const int fadeMs = 200;

  /// Tressautement du 1 naturel.
  static const int shakeMs = 150;

  static const double throwEnd = 0.15;
  static const double bounceEnd = 0.70;

  /// Durée totale du contrôleur pour [plateCount] plateaux.
  static Duration totalDuration(int plateCount) => Duration(
    milliseconds: rollMs + staggerMs * (math.max(1, plateCount) - 1),
  );

  /// Progression (0..1) du plateau [plateIndex] à partir de la valeur
  /// (0..1) du contrôleur unique : le plateau i démarre [staggerMs] × i
  /// après le premier.
  static double plateProgress(
    double controllerValue,
    int plateIndex,
    int plateCount,
  ) {
    final total = totalDuration(plateCount).inMilliseconds;
    final elapsed = controllerValue * total - staggerMs * plateIndex;
    return (elapsed / rollMs).clamp(0.0, 1.0);
  }

  /// Avancement (0..1) du fondu de résultat à la progression [t].
  static double resultFade(double t) =>
      ((t - (rollMs - fadeMs) / rollMs) / (fadeMs / rollMs)).clamp(0.0, 1.0);

  /// Avancement (0..1) du tressautement à la progression [t].
  static double shakeProgress(double t) =>
      ((t - (rollMs - shakeMs) / rollMs) / (shakeMs / rollMs)).clamp(0.0, 1.0);

  /// Décalage horizontal du tressautement du 1 naturel, en dp (±4).
  static double shakeOffsetDp(double t) {
    final u = shakeProgress(t);
    if (u <= 0 || u >= 1) return 0;
    return 4 * math.sin(u * 3 * math.pi) * (1 - u);
  }
}

/// Mouvement du dé : trois phases (lancer 0–15 %, rebonds 15–70 %, pose
/// 70–100 %), un seul contrôleur. L'orientation est `cible × rotation
/// résiduelle` : la rotation résiduelle (autour d'un axe fixe) tombe à
/// zéro à la fin, donc la pose finale est exactement la cible.
abstract final class DieMotion {
  static const double _turns = 3;
  static const double _quarter = math.pi / 2;
  static const double _afterThrow = 2 * math.pi + _quarter;
  static final Vec3 _axis = const Vec3(0.6, 0.7, 0.35).normalized();
  static final double _axisX = _axis.x;
  static final double _axisY = _axis.y;
  static final double _axisZ = _axis.z;

  /// Hauteur de chute initiale / premier rebond / second rebond (35 %).
  static const double _dropHeight = 1.1;
  static const double _bounce1 = 0.30;
  static const double _bounce2 = _bounce1 * 0.35;

  /// Angle résiduel (radians) à la progression [t].
  static double residualAngle(double t) {
    if (t <= DieTimeline.throwEnd) {
      final u = Curves.easeOut.transform(t / DieTimeline.throwEnd);
      return _lerp(_turns * 2 * math.pi + _quarter, _afterThrow, u);
    }
    if (t <= DieTimeline.bounceEnd) {
      final u =
          (t - DieTimeline.throwEnd) /
          (DieTimeline.bounceEnd - DieTimeline.throwEnd);
      return _lerp(_afterThrow, _quarter, Curves.decelerate.transform(u));
    }
    final u = (t - DieTimeline.bounceEnd) / (1 - DieTimeline.bounceEnd);
    return _quarter * (1 - Curves.easeOutCubic.transform(u));
  }

  /// Hauteur du dé au-dessus du sol (fraction de la taille du plateau).
  static double lift(double t) {
    if (t <= DieTimeline.throwEnd) {
      return _dropHeight *
          (1 - Curves.easeOut.transform(t / DieTimeline.throwEnd));
    }
    if (t <= DieTimeline.bounceEnd) {
      final u =
          (t - DieTimeline.throwEnd) /
          (DieTimeline.bounceEnd - DieTimeline.throwEnd);
      // Deux arcs : le premier à 100 % de l'amplitude, le second à 35 %.
      if (u < 0.55) {
        final v = u / 0.55;
        return _bounce1 * 4 * v * (1 - v);
      }
      final v = (u - 0.55) / 0.45;
      return _bounce2 * 4 * v * (1 - v);
    }
    return 0;
  }

  /// Glissement horizontal vers le centre (fraction de la largeur).
  static double offsetX(double t) {
    final u = (t / DieTimeline.bounceEnd).clamp(0.0, 1.0);
    return 0.22 * (1 - Curves.decelerate.transform(u));
  }

  /// Échelle : 1,00 -> 1,04 -> 1,00 pendant la pose.
  static double scale(double t) {
    if (t <= DieTimeline.bounceEnd) return 1;
    final u = (t - DieTimeline.bounceEnd) / (1 - DieTimeline.bounceEnd);
    return 1 + 0.04 * math.sin(math.pi * u.clamp(0.0, 1.0));
  }

  /// Calcule la pose à la progression [t] (0..1) vers la cible
  /// (`tw`,`tx`,`ty`,`tz`) et l'écrit dans [out].
  static void evaluate(
    double t,
    double tw,
    double tx,
    double ty,
    double tz,
    DiePose out,
  ) {
    final clamped = t.clamp(0.0, 1.0);
    final angle = residualAngle(clamped);
    final s = math.sin(angle / 2);
    final rw = math.cos(angle / 2);
    final rx = _axisX * s;
    final ry = _axisY * s;
    final rz = _axisZ * s;
    // cible × résiduel
    out.qw = tw * rw - tx * rx - ty * ry - tz * rz;
    out.qx = tw * rx + tx * rw + ty * rz - tz * ry;
    out.qy = tw * ry - tx * rz + ty * rw + tz * rx;
    out.qz = tw * rz + tx * ry - ty * rx + tz * rw;
    out.offsetX = offsetX(clamped);
    out.lift = lift(clamped);
    out.scale = scale(clamped);
  }

  static double _lerp(double a, double b, double u) => a + (b - a) * u;
}

/// Progression (0..1) d'un plateau, dérivée du contrôleur unique de la
/// feuille : le plateau d'indice i démarre [DieTimeline.staggerMs] × i après
/// le premier.
class PlateProgress extends Animation<double>
    with AnimationWithParentMixin<double> {
  PlateProgress(this.parent, this.index, this.count);

  @override
  final Animation<double> parent;
  final int index;
  final int count;

  @override
  double get value => DieTimeline.plateProgress(parent.value, index, count);
}

/// Courbe du fondu de résultat (derniers 200 ms) d'un plateau.
class ResultFadeCurve extends Curve {
  const ResultFadeCurve();

  @override
  double transformInternal(double t) => DieTimeline.resultFade(t);
}
