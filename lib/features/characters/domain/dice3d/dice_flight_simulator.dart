/// Simulation précalculée du lancer de dés sur toute la page (P2b, addendum 2
/// du 11/11/2026). Pur Dart, sans Flutter : le résultat est tiré avant par
/// `DiceRoller` et rien ici ne l'influence — la simulation ne fait que
/// converger vers les orientations cibles données. Une seule simulation par
/// lancer (< 1 ms, pas d'isolate) ; le contrôleur d'animation se contente de
/// lire la piste obtenue.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'die_math.dart';

enum ImpactKind { landing, wall, dieDie }

/// Un choc de la piste (sert à l'haptique et au squash).
class ImpactEvent {
  const ImpactEvent({
    required this.t,
    required this.kind,
    required this.strength,
    required this.die,
  });

  /// Instant (secondes depuis le début du lancer).
  final double t;
  final ImpactKind kind;

  /// Force normalisée (0..1).
  final double strength;

  /// Dé concerné ; -1 pour un choc dé-dé (les deux).
  final int die;
}

/// Pose échantillonnée d'un dé (objet réutilisé, aucune allocation).
class TrackPose {
  double x = 0;
  double y = 0;
  double h = 0;
  double qw = 1;
  double qx = 0;
  double qy = 0;
  double qz = 0;

  void copyFrom(TrackPose o) {
    x = o.x;
    y = o.y;
    h = o.h;
    qw = o.qw;
    qx = o.qx;
    qy = o.qy;
    qz = o.qz;
  }
}

/// Piste immuable d'un lancer : échantillons à 120 Hz (x, y, h, quaternion)
/// par dé et liste des chocs.
class DiceFlightTrack {
  DiceFlightTrack({
    required this.count,
    required this.duration,
    required this.samples,
    required this.impacts,
  }) : assert(count == 1 || count == 2),
       sampleCount = (duration * sampleRate).round() + 1,
       assert(
         samples.length == count * ((duration * sampleRate).round() + 1) * 7,
         'taille des échantillons incohérente',
       );

  static const int sampleRate = 120;
  static const int stride = 7;

  final int count;

  /// Durée en secondes (1,6 pour un dé, 1,8 pour deux).
  final double duration;
  final int sampleCount;

  /// `((die * sampleCount) + i) * 7` : x, y, h, qw, qx, qy, qz.
  final Float32List samples;
  final List<ImpactEvent> impacts;

  /// Pose du dé [die] à l'instant [t] (secondes) : position et hauteur en
  /// interpolation linéaire, quaternion en nlerp. Écrit dans [out].
  void poseAt(int die, double t, TrackPose out) {
    final f = (t.clamp(0.0, duration)) * sampleRate;
    var i = f.floor();
    if (i > sampleCount - 2) i = sampleCount - 2;
    if (i < 0) i = 0;
    final a = (f - i).clamp(0.0, 1.0);
    final o0 = ((die * sampleCount) + i) * stride;
    final o1 = o0 + stride;
    final s = samples;
    out.x = s[o0] + (s[o1] - s[o0]) * a;
    out.y = s[o0 + 1] + (s[o1 + 1] - s[o0 + 1]) * a;
    out.h = s[o0 + 2] + (s[o1 + 2] - s[o0 + 2]) * a;
    final dot =
        s[o0 + 3] * s[o1 + 3] +
        s[o0 + 4] * s[o1 + 4] +
        s[o0 + 5] * s[o1 + 5] +
        s[o0 + 6] * s[o1 + 6];
    final sign = dot < 0 ? -1.0 : 1.0;
    var w = s[o0 + 3] + (sign * s[o1 + 3] - s[o0 + 3]) * a;
    var x = s[o0 + 4] + (sign * s[o1 + 4] - s[o0 + 4]) * a;
    var y = s[o0 + 5] + (sign * s[o1 + 5] - s[o0 + 5]) * a;
    var z = s[o0 + 6] + (sign * s[o1 + 6] - s[o0 + 6]) * a;
    final n = math.sqrt(w * w + x * x + y * y + z * z);
    if (n > 0) {
      w /= n;
      x /= n;
      y /= n;
      z /= n;
    }
    out.qw = w;
    out.qx = x;
    out.qy = y;
    out.qz = z;
  }

  /// Échantillon brut `i` du dé [die] (tests).
  List<double> sample(int die, int i) {
    final o = ((die * sampleCount) + i) * stride;
    return [for (var k = 0; k < stride; k++) samples[o + k]];
  }
}

/// Arène du lancer : table (zone de jeu), diamètre visible des dés, points
/// de repos et orientations cibles (une par dé).
class DiceArena {
  const DiceArena({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.diameter,
    required this.restX,
    required this.restY,
    required this.targets,
    required this.duration,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;

  /// Diamètre visible D du dé (rayon R = D / 2).
  final double diameter;
  final List<double> restX;
  final List<double> restY;
  final List<Quat> targets;
  final double duration;

  int get count => targets.length;
  double get radius => diameter / 2;
  double get width => right - left;
  double get height => bottom - top;
}

class _Attempt {
  _Attempt(this.track, this.angle);
  final DiceFlightTrack track;
  final double angle;
}

abstract final class DiceFlightSimulator {
  static const double _dt = 1 / DiceFlightTrack.sampleRate;
  static const double _drag = 2.2;
  static const double _wallRestitution = 0.60;
  static const double _wallTangential = 0.90;
  static const double _gravity = 14;
  static const double _groundRestitution = 0.45;
  static const double _stopSpeed = 0.5;
  static const double _springK = 60;
  static const double _springStart = 0.85;
  static const double _springRamp = 0.30;
  static const double _pullStart = 0.90;
  static const double _orientStart = 0.80;
  static const double _orientGain = 30;
  static const double _poseTime = 0.25;
  static const double _dieRestitution = 0.82;
  static const int _maxAttempts = 8;
  static const double _maxOrientAngle = 110 * math.pi / 180;

  /// Simule le lancer ; renvoie `null` si aucune tentative (ni la tentative
  /// canonique) ne satisfait les critères d'acceptation — l'appelant retombe
  /// alors sur le repli « niveau 0 » (ancienne polyligne).
  static DiceFlightTrack? simulate(DiceArena arena, math.Random random) {
    _Attempt? best;
    for (var i = 0; i < _maxAttempts; i++) {
      final a = _attempt(arena, random, canonical: false);
      if (a == null) continue;
      if (a.angle > _maxOrientAngle) continue;
      if (best == null || a.angle < best.angle) best = a;
    }
    best ??= _attempt(arena, random, canonical: true);
    return best?.track;
  }

  static double _smooth(double u) {
    final c = u.clamp(0.0, 1.0);
    return c * c * (3 - 2 * c);
  }

  /// Courbe d'ordre supérieur (dérivées première et seconde nulles aux
  /// extrémités) : la convergence exacte arrive à vitesse quasi nulle.
  static double _smoother(double u) {
    final c = u.clamp(0.0, 1.0);
    return c * c * c * (c * (c * 6 - 15) + 10);
  }

  static _Attempt? _attempt(
    DiceArena arena,
    math.Random rng, {
    required bool canonical,
  }) {
    final n = arena.count;
    final d = arena.diameter;
    final r = arena.radius;
    final rc = 0.94 * r;
    final dur = arena.duration;
    final steps = (dur * DiceFlightTrack.sampleRate).round();
    final lock = dur - _poseTime;

    double jit() => canonical ? 0 : (rng.nextDouble() * 2 - 1);

    // --- État initial.
    final px = List<double>.filled(n, 0);
    final py = List<double>.filled(n, 0);
    final vx = List<double>.filled(n, 0);
    final vy = List<double>.filled(n, 0);
    final h = List<double>.filled(n, 0);
    final vh = List<double>.filled(n, 0);
    final bounces = List<int>.filled(n, 0);
    final resting = List<bool>.filled(n, false);
    final entered = List<bool>.filled(n, false);
    final tumbleFactor = List<double>.filled(n, 1);
    final spinZ = List<double>.filled(n, 0);
    final qw = List<double>.filled(n, 1);
    final qx = List<double>.filled(n, 0);
    final qy = List<double>.filled(n, 0);
    final qz = List<double>.filled(n, 0);
    final axis = <Vec3>[];
    final tumbleMag = List<double>.filled(n, 0);
    final restX = List<double>.of(arena.restX);
    final restY = List<double>.of(arena.restY);

    final y0 = arena.bottom + 1.5 * r;
    const g0 = 1.0;
    for (var i = 0; i < n; i++) {
      h[i] = g0 * (1 + 0.05 * jit());
      // Orientation initiale aléatoire (normalisée).
      if (canonical) {
        axis.add(Vec3(0.6 + 0.1 * i, 0.7, 0.35).normalized());
        tumbleMag[i] = 14;
      } else {
        axis.add(
          Vec3(
            rng.nextDouble() * 2 - 1,
            rng.nextDouble() * 2 - 1,
            rng.nextDouble() * 2 - 1,
          ).normalized(),
        );
        tumbleMag[i] = 14 + 4 * jit();
        final q = Quat(
          rng.nextDouble() * 2 - 1,
          rng.nextDouble() * 2 - 1,
          rng.nextDouble() * 2 - 1,
          rng.nextDouble() * 2 - 1,
        ).normalized();
        qw[i] = q.w;
        qx[i] = q.x;
        qy[i] = q.y;
        qz[i] = q.z;
      }
    }

    // --- Lancement.
    final tc = 0.55 + 0.08 * jit();
    final k0 = _drag / (1 - math.exp(-_drag * tc));
    if (n == 2) {
      px[0] = arena.left + arena.width * 0.28;
      px[1] = arena.left + arena.width * 0.72;
      py[0] = py[1] = y0;
      final mx = (restX[0] + restX[1]) / 2 + 0.06 * arena.width * jit();
      final my = (restY[0] + restY[1]) / 2 + 0.06 * arena.height * jit();
      final b = (canonical || rng.nextBool() ? 1.0 : -1.0) * 0.35 * d;
      final len = math.sqrt(4 * rc * rc + b * b);
      final dx = 2 * rc / len;
      final dy = b / len;
      final ax = [mx - dx * rc, mx + dx * rc];
      final ay = [my - dy * rc, my + dy * rc];
      for (var i = 0; i < 2; i++) {
        vx[i] = k0 * (ax[i] - px[i]);
        vy[i] = k0 * (ay[i] - py[i]);
      }
    } else {
      final right = canonical || rng.nextBool();
      px[0] = arena.left + arena.width * (0.5 + 0.1 * jit());
      py[0] = y0;
      final wallX = right ? arena.right - r : arena.left + r;
      final aimY = restY[0] + 0.35 * (arena.bottom - restY[0]);
      vx[0] = k0 * (wallX - px[0]);
      vy[0] = k0 * (aimY - py[0]);
    }

    // --- Intégration.
    final samples = Float32List(n * (steps + 1) * DiceFlightTrack.stride);
    final impacts = <ImpactEvent>[];
    var contacted = false;
    var dieDieCount = 0;
    var bigShock = false;
    var walls = 0;
    var minDistAfterContact = double.infinity;
    var sorted = false;
    final qAt08 = List<Quat?>.filled(n, null);
    final targets = arena.targets;

    // Les échantillons enregistrent l'état réel : la convergence vers la
    // cible est une vraie dynamique (direction pilotée dans l'intégration),
    // jamais un recalage a posteriori.
    void writeSample(int i) {
      for (var k = 0; k < n; k++) {
        final o = ((k * (steps + 1)) + i) * DiceFlightTrack.stride;
        samples[o] = px[k];
        samples[o + 1] = py[k];
        samples[o + 2] = h[k];
        samples[o + 3] = qw[k];
        samples[o + 4] = qx[k];
        samples[o + 5] = qy[k];
        samples[o + 6] = qz[k];
      }
    }

    for (var i = 0; i <= steps; i++) {
      final t = i * _dt;
      writeSample(i);
      if (i == (_orientStart * DiceFlightTrack.sampleRate).round()) {
        for (var k = 0; k < n; k++) {
          qAt08[k] = Quat(qw[k], qx[k], qy[k], qz[k]);
        }
      }
      if (i == steps) break;
      final tn = t + _dt;

      if (!sorted && t >= _springStart && n == 2) {
        sorted = true;
        // Le dé le plus à gauche prend le repos le plus à gauche.
        final leftDie = px[0] <= px[1] ? 0 : 1;
        final leftRest = restX[0] <= restX[1] ? 0 : 1;
        final a = restX[leftRest], ay = restY[leftRest];
        final bIdx = 1 - leftRest;
        final bx = restX[bIdx], by = restY[bIdx];
        restX[leftDie] = a;
        restY[leftDie] = ay;
        restX[1 - leftDie] = bx;
        restY[1 - leftDie] = by;
      }

      final locking = tn >= lock - 1e-9;
      for (var k = 0; k < n; k++) {
        if (locking) {
          px[k] = restX[k];
          py[k] = restY[k];
          vx[k] = vy[k] = 0;
          h[k] = 0;
          vh[k] = 0;
          qw[k] = targets[k].w;
          qx[k] = targets[k].x;
          qy[k] = targets[k].y;
          qz[k] = targets[k].z;
          continue;
        }
        // Traînée.
        vx[k] -= _drag * vx[k] * _dt;
        vy[k] -= _drag * vy[k] * _dt;
        // Ressort critique vers le repos (poids lissé).
        final w = _smooth((t - _springStart) / _springRamp);
        if (w > 0) {
          final damp = 2 * math.sqrt(_springK);
          vx[k] += w * (-_springK * (px[k] - restX[k]) - damp * vx[k]) * _dt;
          vy[k] += w * (-_springK * (py[k] - restY[k]) - damp * vy[k]) * _dt;
        }
        px[k] += vx[k] * _dt;
        py[k] += vy[k] * _dt;

        // Convergence exacte vers le repos (tirage doux vers le point fixe).
        final s0 = _smoother((t - _pullStart) / (lock - _pullStart));
        final s1 = _smoother((tn - _pullStart) / (lock - _pullStart));
        if (s1 > s0 && s0 < 1) {
          final alpha = (s1 - s0) / (1 - s0);
          px[k] += (restX[k] - px[k]) * alpha;
          py[k] += (restY[k] - py[k]) * alpha;
        }

        // Entrée dans la table, puis murs.
        if (py[k] < arena.bottom - r) entered[k] = true;
        double strengthOf(double speed) => (speed / (10 * d)).clamp(0.0, 1.0);
        if (px[k] < arena.left + r) {
          final sp = vx[k].abs();
          px[k] = arena.left + r;
          if (vx[k] < 0) {
            vx[k] = -vx[k] * _wallRestitution;
            vy[k] *= _wallTangential;
            impacts.add(
              ImpactEvent(
                t: tn,
                kind: ImpactKind.wall,
                strength: strengthOf(sp),
                die: k,
              ),
            );
            walls++;
          }
        } else if (px[k] > arena.right - r) {
          final sp = vx[k].abs();
          px[k] = arena.right - r;
          if (vx[k] > 0) {
            vx[k] = -vx[k] * _wallRestitution;
            vy[k] *= _wallTangential;
            impacts.add(
              ImpactEvent(
                t: tn,
                kind: ImpactKind.wall,
                strength: strengthOf(sp),
                die: k,
              ),
            );
            walls++;
          }
        }
        if (py[k] < arena.top + r) {
          final sp = vy[k].abs();
          py[k] = arena.top + r;
          if (vy[k] < 0) {
            vy[k] = -vy[k] * _wallRestitution;
            vx[k] *= _wallTangential;
            impacts.add(
              ImpactEvent(
                t: tn,
                kind: ImpactKind.wall,
                strength: strengthOf(sp),
                die: k,
              ),
            );
            walls++;
          }
        } else if (entered[k] && py[k] > arena.bottom - r) {
          final sp = vy[k].abs();
          py[k] = arena.bottom - r;
          if (vy[k] > 0) {
            vy[k] = -vy[k] * _wallRestitution;
            vx[k] *= _wallTangential;
            impacts.add(
              ImpactEvent(
                t: tn,
                kind: ImpactKind.wall,
                strength: strengthOf(sp),
                die: k,
              ),
            );
            walls++;
          }
        }

        // Axe vertical normalisé.
        if (!resting[k]) {
          vh[k] -= _gravity * _dt;
          h[k] += vh[k] * _dt;
          if (h[k] <= 0) {
            final speed = vh[k].abs();
            h[k] = 0;
            if (speed < _stopSpeed || bounces[k] >= 4) {
              vh[k] = 0;
              resting[k] = true;
            } else {
              vh[k] = _groundRestitution * speed;
              bounces[k]++;
              tumbleFactor[k] *= 0.7;
              impacts.add(
                ImpactEvent(
                  t: tn,
                  kind: ImpactKind.landing,
                  strength: (speed / 5.3).clamp(0.0, 1.5),
                  die: k,
                ),
              );
            }
          }
        }

        // Rotation : roulis + culbute + spin autour de z.
        final wr = 1 - (h[k] / 0.15).clamp(0.0, 1.0);
        final wx =
            wr * 0.8 * vy[k] / r +
            axis[k].x * tumbleMag[k] * math.exp(-2 * t) * tumbleFactor[k];
        final wy =
            wr * 0.8 * vx[k] / r +
            axis[k].y * tumbleMag[k] * math.exp(-2 * t) * tumbleFactor[k];
        final wz =
            axis[k].z * tumbleMag[k] * math.exp(-2 * t) * tumbleFactor[k] +
            spinZ[k];
        spinZ[k] *= 1 - 3 * _dt;
        // Convergence d'orientation (dès 0,80 s) : la vitesse angulaire
        // physique s'estompe au profit d'une rotation proportionnelle vers la
        // cible (plus court chemin), sans aucun saut.
        var ox = wx, oy = wy, oz = wz;
        final so = _smooth((t - _orientStart) / (lock - _orientStart));
        if (so > 0) {
          final tg = targets[k];
          var ew = tg.w * qw[k] + tg.x * qx[k] + tg.y * qy[k] + tg.z * qz[k];
          var ex = -tg.w * qx[k] + tg.x * qw[k] - tg.y * qz[k] + tg.z * qy[k];
          var ey = -tg.w * qy[k] + tg.x * qz[k] + tg.y * qw[k] - tg.z * qx[k];
          var ez = -tg.w * qz[k] - tg.x * qy[k] + tg.y * qx[k] + tg.z * qw[k];
          if (ew < 0) {
            ew = -ew;
            ex = -ex;
            ey = -ey;
            ez = -ez;
          }
          final sinHalf = math.sqrt(ex * ex + ey * ey + ez * ez);
          var rx = 0.0, ry = 0.0, rz = 0.0;
          if (sinHalf > 1e-9) {
            final ang = 2 * math.atan2(sinHalf, ew);
            final f = ang / sinHalf;
            rx = ex * f;
            ry = ey * f;
            rz = ez * f;
          }
          ox = (1 - so) * wx + so * _orientGain * rx;
          oy = (1 - so) * wy + so * _orientGain * ry;
          oz = (1 - so) * wz + so * _orientGain * rz;
        }
        final a = qw[k], b = qx[k], c = qy[k], e = qz[k];
        // q += 0.5 dt (0, ω) ⊗ q
        final hdt = 0.5 * _dt;
        final nw = a + hdt * (-ox * b - oy * c - oz * e);
        final nx = b + hdt * (ox * a + oy * e - oz * c);
        final ny = c + hdt * (oy * a + oz * b - ox * e);
        final nz = e + hdt * (oz * a + ox * c - oy * b);
        final nn = math.sqrt(nw * nw + nx * nx + ny * ny + nz * nz);
        qw[k] = nw / nn;
        qx[k] = nx / nn;
        qy[k] = ny / nn;
        qz[k] = nz / nn;
      }

      // Collision dé-dé.
      if (n == 2 && !locking) {
        var ddx = px[1] - px[0];
        var ddy = py[1] - py[0];
        var dist = math.sqrt(ddx * ddx + ddy * ddy);
        final dh = (h[0] - h[1]).abs();
        final low = h[0] < 0.45 && h[1] < 0.45;
        final inRange = dh < 0.2 && low;
        if (dist < 2 * rc && (inRange || contacted)) {
          if (dist < 1e-6) {
            ddx = 1;
            ddy = 0;
            dist = 1;
          }
          final nx = ddx / dist;
          final ny = ddy / dist;
          final overlap = 2 * rc - dist;
          px[0] -= nx * overlap / 2;
          py[0] -= ny * overlap / 2;
          px[1] += nx * overlap / 2;
          py[1] += ny * overlap / 2;
          final vrel = (vx[0] - vx[1]) * nx + (vy[0] - vy[1]) * ny;
          if (vrel > 0 && inRange) {
            final j = (1 + _dieRestitution) / 2 * vrel;
            vx[0] -= j * nx;
            vy[0] -= j * ny;
            vx[1] += j * nx;
            vy[1] += j * ny;
            final tx = -ny;
            final ty = nx;
            final vt = (vx[0] - vx[1]) * tx + (vy[0] - vy[1]) * ty;
            spinZ[0] -= 0.5 * vt / r;
            spinZ[1] -= 0.5 * vt / r;
            dieDieCount++;
            if (vrel >= 1.0 * d && tn >= 0.3 && tn <= 1.0) bigShock = true;
            impacts.add(
              ImpactEvent(
                t: tn,
                kind: ImpactKind.dieDie,
                strength: (vrel / (8 * d)).clamp(0.0, 1.0),
                die: -1,
              ),
            );
          }
          contacted = true;
        }
        if (contacted) {
          ddx = px[1] - px[0];
          ddy = py[1] - py[0];
          dist = math.sqrt(ddx * ddx + ddy * ddy);
          minDistAfterContact = math.min(minDistAfterContact, dist);
        }
      }
    }

    // --- Acceptation.
    for (final v in samples) {
      if (v.isNaN || v.isInfinite) return null;
    }
    if (walls < 1) return null;
    if (n == 2) {
      if (!bigShock || dieDieCount > 4) return null;
      if (minDistAfterContact < 1.88 * r - 1e-6) return null;
    }
    var angle = 0.0;
    for (var k = 0; k < n; k++) {
      final q = qAt08[k]!;
      final tgt = targets[k];
      final dot = (q.w * tgt.w + q.x * tgt.x + q.y * tgt.y + q.z * tgt.z)
          .abs()
          .clamp(0.0, 1.0);
      angle = math.max(angle, 2 * math.acos(dot));
    }
    return _Attempt(
      DiceFlightTrack(
        count: n,
        duration: dur,
        samples: samples,
        impacts: List.unmodifiable(impacts),
      ),
      angle,
    );
  }
}
