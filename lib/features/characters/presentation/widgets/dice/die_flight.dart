/// Géométrie du lancer sur toute la page (P2b, addendum 2 du 11/11/2026) :
/// mise en page ([DiceFlightLayout]) et ancienne polyligne [DieFlightPlan],
/// conservée comme repli « niveau 0 » si la simulation échoue. Le résultat est
/// tiré avant par `DiceRoller` ; rien ici ne l'influence.
library;

import 'dart:math' as math;

import 'package:flutter/animation.dart';

import '../../../domain/dice3d/dice_flight_simulator.dart';
import '../../../domain/dice3d/die_math.dart';

/// Plan de vol d'un dé : polyligne de points de passage (positions au sol,
/// dans le repère de l'écran).
class DieFlightPlan {
  DieFlightPlan._(this._points, this.rest);

  /// Instants (0..1) des points de passage.
  static const List<double> times = [0, 0.25, 0.35, 0.55, 0.70, 1];

  final List<Offset> _points;

  /// Point de repos (centre du dé posé).
  final Offset rest;

  /// Construit un plan : entrée par le bas, contact avec un bord latéral
  /// (~35 %), contact avec le haut (~55 %), roulis amorti jusqu'au repos.
  ///
  /// [table] : zone de jeu (écran moins zones système, marge 8 dp) ; [radius]
  /// : rayon du dé, qui borne son centre ; [rest] : point de repos.
  factory DieFlightPlan.build({
    required Rect table,
    required Offset rest,
    required double radius,
    required math.Random random,
  }) {
    final minX = table.left + radius;
    final maxX = table.right - radius;
    final minY = table.top + radius;
    double clampX(double x) => x.clamp(minX, math.max(minX, maxX));
    double clampY(double y) => y.clamp(minY, math.max(minY, table.bottom));

    final fromLeft = random.nextBool();
    final entryX = clampX(
      table.left + table.width * (0.25 + 0.5 * random.nextDouble()),
    );
    final entry = Offset(entryX, table.bottom + radius * 1.5);
    final inBottom = Offset(entryX, clampY(table.bottom - radius * 0.6));
    final side = Offset(
      fromLeft ? minX : math.max(minX, maxX),
      clampY(table.top + table.height * (0.35 + 0.2 * random.nextDouble())),
    );
    final top = Offset(
      clampX(table.center.dx + (fromLeft ? 1 : -1) * table.width * 0.2),
      minY,
    );
    final settle = Offset(
      clampX(rest.dx + (random.nextDouble() - 0.5) * table.width * 0.2),
      clampY(rest.dy + radius * 0.4 * random.nextDouble()),
    );
    return DieFlightPlan._([entry, inBottom, side, top, settle, rest], rest);
  }

  /// Position du centre du dé **au sol** à la progression [t] (0..1).
  Offset groundAt(double t) {
    final c = t.clamp(0.0, 1.0);
    var i = 0;
    while (i < times.length - 2 && c > times[i + 1]) {
      i++;
    }
    final u = (c - times[i]) / (times[i + 1] - times[i]);
    final eased = switch (i) {
      0 => Curves.easeOut.transform(u),
      4 => Curves.easeOutCubic.transform(u),
      _ => u,
    };
    return Offset.lerp(_points[i], _points[i + 1], eased)!;
  }

  /// Hauteur du dé au-dessus de la table (0..1) à la progression [t] :
  /// entrée + premier rebond (100 %), second rebond (35 %), petit roulis,
  /// puis posé.
  static double heightAt(double t) {
    double arc(double from, double to, double peak, double c) {
      final v = (c - from) / (to - from);
      return peak * 4 * v * (1 - v);
    }

    final c = t.clamp(0.0, 1.0);
    if (c < 0.25) return 0;
    if (c < 0.55) {
      // Deux rebonds consécutifs contre les bords : 100 % puis 35 %.
      return c < 0.35 ? arc(0.25, 0.35, 1, c) : arc(0.35, 0.55, 0.35, c);
    }
    if (c < 0.70) return arc(0.55, 0.70, 0.12, c);
    return 0;
  }
}

/// Mise en page du lancer : taille des dés, zone de jeu (« table ») et points
/// de repos au-dessus de la feuille à son plafond de 62 % (sans attendre
/// aucune mesure). `D` = diamètre visible ; côté nominal `S = D / 0,84` ;
/// boîte de dessin `1,25 · S`.
class DiceFlightLayout {
  DiceFlightLayout._({
    required this.screen,
    required this.count,
    required this.diameter,
    required this.table,
    required this.rests,
    required this.freeTop,
    required this.freeBottom,
  });

  /// Écart entre deux dés au repos.
  static const double pairGap = 12;

  /// Hauteur de la bande d'étiquette sous un dé (groupe dé + étiquette).
  static const double labelBand = 24;

  /// Plafond de la feuille (fraction de la hauteur) : les dés se posent
  /// au-dessus.
  static const double sheetCeiling = 0.62;
  static const double margin = 8;
  static const double minDiameter = 96;

  /// Rapport diamètre visible / côté nominal.
  static const double visibleRatio = 0.84;

  /// La boîte de dessin est 25 % plus grande que le côté nominal.
  static const double boxFactor = 1.25;

  final Size screen;
  final int count;

  /// Diamètre visible D.
  final double diameter;
  final Rect table;
  final List<Offset> rests;
  final double freeTop;
  final double freeBottom;

  double get nominal => diameter / visibleRatio;
  double get box => nominal * boxFactor;
  double get radius => diameter / 2;

  /// Haut de l'étiquette « Retenu/Écarté » dans la boîte du dé (4 dp sous le
  /// bord du dé : centre + 0,42·S + 4).
  double get labelTop => box / 2 + 0.42 * nominal + 4;

  factory DiceFlightLayout.compute(
    Size screen, {
    required double paddingTop,
    required double paddingBottom,
    required int count,
  }) {
    final w = screen.width;
    final h = screen.height;
    final freeTop = paddingTop + margin;
    final freeBottom = (1 - sheetCeiling) * h - margin;
    final hf = freeBottom - freeTop;
    final d = count == 1
        ? math.max(minDiameter, math.min(0.55 * w, math.min(hf - 20, 280.0)))
        : math.max(minDiameter, math.min(0.45 * w, math.min(hf - 36, 240.0)));
    final yc = (freeTop + freeBottom) / 2;
    final rests = count == 1
        ? [Offset(w / 2, yc)]
        : [
            Offset(w / 2 - (d + pairGap) / 2, yc - labelBand / 2),
            Offset(w / 2 + (d + pairGap) / 2, yc - labelBand / 2),
          ];
    return DiceFlightLayout._(
      screen: screen,
      count: count,
      diameter: d,
      table: Rect.fromLTRB(
        margin,
        paddingTop + margin,
        w - margin,
        h - paddingBottom - margin,
      ),
      rests: rests,
      freeTop: freeTop,
      freeBottom: freeBottom,
    );
  }

  /// Arène de simulation pour les orientations cibles [targets].
  DiceArena arena(List<Quat> targets, double duration) => DiceArena(
    left: table.left,
    top: table.top,
    right: table.right,
    bottom: table.bottom,
    diameter: diameter,
    restX: [for (final r in rests) r.dx],
    restY: [for (final r in rests) r.dy],
    targets: targets,
    duration: duration,
  );

  /// Durée de la piste simulée : 1,6 s (1 dé) / 1,8 s (2 dés).
  static double durationFor(int count) => count == 1 ? 1.6 : 1.8;
}
