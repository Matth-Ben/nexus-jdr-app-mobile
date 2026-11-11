/// Trajectoire cosmétique d'un dé lancé sur toute la page (P2b, addendum du
/// 11/11/2026) : fonctions pures du temps. Le résultat est tiré avant par
/// `DiceRoller` ; rien ici ne l'influence, seul le chemin varie (via un
/// `Random` distinct et injectable).
library;

import 'dart:math' as math;

import 'package:flutter/animation.dart';

/// Tailles du dé (côté de sa boîte « nominale », hors échelle de vol).
abstract final class DieFlightSizes {
  /// Un dé : 176 dp (tablette >= 600 dp : 220).
  static double single(double screenWidth) => screenWidth >= 600 ? 220 : 176;

  /// Deux dés : 136 dp chacun (tablette 168).
  static double pair(double screenWidth) => screenWidth >= 600 ? 168 : 136;

  /// Écart entre deux dés au repos.
  static const double pairGap = 16;

  /// La boîte de dessin est 25 % plus grande que le dé nominal (échelle de
  /// vol jusqu'à 1,25).
  static const double boxFactor = 1.25;

  /// Marge de la table (écran moins zones système).
  static const double tableMargin = 8;
}

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

  /// Échelle de vol : `1 + 0,25 · hauteur`.
  static double flightScale(double t) => 1 + 0.25 * heightAt(t);

  /// Décalage visuel vers le haut du dé par rapport à son ombre (dp).
  static double liftPx(double t, double dieSize) =>
      heightAt(t) * dieSize * 0.22;
}

/// Zone de jeu : écran moins zones système, marge de 8 dp.
Rect tableRect(Size screen, {required double top, required double bottom}) {
  const m = DieFlightSizes.tableMargin;
  return Rect.fromLTRB(
    m,
    top + m,
    screen.width - m,
    screen.height - bottom - m,
  );
}

/// Points de repos des dés au-dessus de la feuille : centre horizontal de la
/// table, milieu vertical de la zone libre ([table].top .. [sheetTop]).
List<Offset> restPoints({
  required Rect table,
  required double sheetTop,
  required double dieSize,
  required int count,
}) {
  final freeBottom = math.max(table.top + dieSize, sheetTop - 8);
  final y = (table.top + freeBottom) / 2;
  final gap = DieFlightSizes.pairGap;
  if (count == 1) return [Offset(table.center.dx, y)];
  final dx = (dieSize + gap) / 2;
  return [Offset(table.center.dx - dx, y), Offset(table.center.dx + dx, y)];
}
