import 'dart:math' as math;

import 'package:flutter/animation.dart';

import '../../../domain/dice3d/dice_flight_simulator.dart';
import '../../../domain/dice3d/die_math.dart';
import 'die_flight.dart';
import 'die_motion.dart';

/// Saut au tap : état partagé par tous les dés d'un lancer. Quand il est
/// actif, chaque dé glisse en [durationMs] de sa pose courante (celle de
/// [fromValue]) vers sa pose posée.
class DieSkipState {
  /// Durée du glissement doux vers la pose.
  static const int durationMs = 160;

  double _from = -1;

  bool get active => _from >= 0;
  double get fromValue => _from;

  /// Démarre le saut à la valeur [value] (0..1) du contrôleur.
  void begin(double value) => _from = value.clamp(0.0, 1.0);
}

/// Lit une piste (ou, en repli « niveau 0 », l'ancienne polyligne) et en
/// déduit, à chaque image, tout ce qu'il faut dessiner : position, hauteur,
/// orientation, échelle, squash, fondu et tressautement. Un seul calcul par
/// valeur du contrôleur (les painters et les widgets de translation y
/// puisent sans recalculer) ; aucun objet alloué en régime établi.
class DieFlightRunner {
  /// Lecture d'une piste simulée : contrôleur linéaire sur [track].duration.
  DieFlightRunner.track({
    required DiceFlightTrack this.track,
    required this.die,
    required this.rest,
    required this.target,
    required this.diameter,
    required this.skip,
  }) : plan = null,
       count = track.count,
       totalSeconds = track.duration;

  /// Repli niveau 0 : ancienne polyligne cosmétique (rotation `DieMotion`).
  DieFlightRunner.plan({
    required DieFlightPlan this.plan,
    required this.die,
    required this.count,
    required this.rest,
    required this.target,
    required this.diameter,
    required this.skip,
  }) : track = null,
       totalSeconds = DieTimeline.totalDuration(count).inMilliseconds / 1000;

  final DiceFlightTrack? track;
  final DieFlightPlan? plan;
  final int die;
  final int count;
  final Offset rest;
  final Quat target;

  /// Diamètre visible D.
  final double diameter;
  final DieSkipState skip;

  /// Durée totale du contrôleur (secondes).
  final double totalSeconds;

  // Sorties (valables pour la dernière valeur passée à [update]).
  double x = 0;
  double y = 0;
  double h = 0;
  double qw = 1;
  double qx = 0;
  double qy = 0;
  double qz = 0;

  /// Montée du dé au-dessus de son ombre, en dp.
  double lift = 0;

  /// Échelle totale : vol `1 + 0,20·h` × pulsation de pose.
  double scale = 1;
  double squashX = 1;
  double squashY = 1;

  /// Fondu du résultat (200 derniers ms) : 0..1.
  double fade = 0;

  /// Tressautement horizontal du 1 naturel, en dp.
  double shakeDp = 0;

  /// Avancement (0..1) de la pose finale (dernière 0,25 s).
  double poseU = 0;

  double _lastValue = double.nan;
  final TrackPose _a = TrackPose();
  final DiePose _legacy = DiePose();

  /// Recalcule les sorties pour la valeur [value] (0..1) du contrôleur.
  void update(double value) {
    if (value == _lastValue) return;
    _lastValue = value;
    final v = value.clamp(0.0, 1.0);
    final t = v * totalSeconds;

    _base(v, _a);
    var impactT = t;
    if (skip.active && skip.fromValue < 1) {
      // Glissement doux : position en easeOutCubic, orientation en nlerp,
      // hauteur ramenée à 0.
      final u = ((v - skip.fromValue) / (1 - skip.fromValue)).clamp(0.0, 1.0);
      // easeOutCubic analytique (la courbe Bézier de Flutter n'est exacte
      // qu'à 1e-3 près, ce qui ferait un micro-saut au début du glissement).
      final e = 1 - (1 - u) * (1 - u) * (1 - u);
      _base(skip.fromValue, _a);
      x = _a.x + (rest.dx - _a.x) * e;
      y = _a.y + (rest.dy - _a.y) * e;
      h = _a.h * (1 - e);
      _nlerp(_a, target, e);
      impactT = -10;
    } else {
      x = _a.x;
      y = _a.y;
      h = _a.h;
      qw = _a.qw;
      qx = _a.qx;
      qy = _a.qy;
      qz = _a.qz;
    }

    lift = 0.28 * diameter * h;
    final lock = totalSeconds - 0.25;
    poseU = t > lock ? ((t - lock) / 0.25).clamp(0.0, 1.0) : 0;
    scale = (1 + 0.20 * h) * (1 + 0.045 * math.sin(math.pi * poseU));
    fade = ((t - (totalSeconds - 0.2)) / 0.2).clamp(0.0, 1.0);
    final su = ((t - (totalSeconds - 0.15)) / 0.15).clamp(0.0, 1.0);
    shakeDp = su > 0 && su < 1 ? 4 * math.sin(su * 3 * math.pi) * (1 - su) : 0;
    _squash(impactT);
  }

  void _base(double v, TrackPose out) {
    final tr = track;
    if (tr != null) {
      tr.poseAt(die, v * totalSeconds, out);
      return;
    }
    final p = DieTimeline.plateProgress(v, die, count);
    final g = plan!.groundAt(p);
    out.x = g.dx;
    out.y = g.dy;
    out.h = DieFlightPlan.heightAt(p);
    DieMotion.evaluate(p, target.w, target.x, target.y, target.z, _legacy);
    out.qw = _legacy.qw;
    out.qx = _legacy.qx;
    out.qy = _legacy.qy;
    out.qz = _legacy.qz;
  }

  void _nlerp(TrackPose from, Quat to, double e) {
    final dot =
        from.qw * to.w + from.qx * to.x + from.qy * to.y + from.qz * to.z;
    final s = dot < 0 ? -1.0 : 1.0;
    var w = from.qw + (s * to.w - from.qw) * e;
    var xx = from.qx + (s * to.x - from.qx) * e;
    var yy = from.qy + (s * to.y - from.qy) * e;
    var zz = from.qz + (s * to.z - from.qz) * e;
    final n = math.sqrt(w * w + xx * xx + yy * yy + zz * zz);
    if (n > 0) {
      w /= n;
      xx /= n;
      yy /= n;
      zz /= n;
    }
    qw = w;
    qx = xx;
    qy = yy;
    qz = zz;
  }

  /// Squash à chaque impact : amplitude `0,06·|vitesse|/5,3` (<= 0,06) au
  /// sol, 40 % sur un mur, décroissance `e^(−dt/0,04)`.
  void _squash(double t) {
    squashX = 1;
    squashY = 1;
    final tr = track;
    if (tr == null) return;
    var amp = 0.0;
    for (final e in tr.impacts) {
      if (e.t > t) break;
      if (e.die != die && e.die != -1) continue;
      final dt = t - e.t;
      if (dt > 0.2) continue;
      final base = switch (e.kind) {
        ImpactKind.landing => math.min(0.06, 0.06 * e.strength),
        ImpactKind.wall => 0.4 * math.min(0.06, 0.06 * e.strength * 5),
        ImpactKind.dieDie => 0.4 * math.min(0.06, 0.06 * e.strength * 5),
      };
      amp = math.max(amp, base * math.exp(-dt / 0.04));
    }
    squashX = 1 + amp;
    squashY = 1 - amp;
  }
}

/// Fondu du résultat d'un dé, exposé comme animation pour `FadeTransition`.
class RunnerFade extends Animation<double>
    with AnimationWithParentMixin<double> {
  RunnerFade(this.parent, this.runner);

  @override
  final Animation<double> parent;
  final DieFlightRunner runner;

  @override
  double get value {
    runner.update(parent.value);
    return runner.fade;
  }
}
