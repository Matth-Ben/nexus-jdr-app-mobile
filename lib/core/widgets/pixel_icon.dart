import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Côté de la grille d'une icône pixel (cellules).
const int kPixelIconGrid = 16;

/// Icône pixel décorative dessinée depuis une matrice 16×16 (`#` = cellule
/// pleine, `.` = vide) — jeu dédié des conditions, voir
/// `docs/p6-icones-conditions.md` et `pixel_icons/condition_pixel_icons.dart`.
///
/// [size] doit être un multiple de 16 (16, 32, 48 ; jamais 24) pour que
/// chaque cellule tombe sur un nombre entier de dp. Dessin sans
/// anti-aliasing, cellule arrondie à un multiple entier de pixels physiques.
///
/// **Décoratif** : enveloppé dans [ExcludeSemantics] ; le libellé de la
/// condition doit toujours être affiché à côté, jamais l'icône seule.
class PixelIcon extends StatelessWidget {
  const PixelIcon({required this.matrix, this.size = 32, this.color, super.key})
    : assert(
        size % kPixelIconGrid == 0,
        'PixelIcon.size doit être un multiple de 16',
      );

  final List<String> matrix;
  final double size;

  /// [AppColors.textSecondary] par défaut ; [AppColors.accentBrick] pour
  /// l'état actif (pastille).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: PixelIconPainter(
            matrix: matrix,
            color: color ?? AppColors.textSecondary,
            devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
          ),
        ),
      ),
    );
  }
}

/// Peintre de [PixelIcon] — public pour pouvoir être testé directement.
class PixelIconPainter extends CustomPainter {
  const PixelIconPainter({
    required this.matrix,
    required this.color,
    required this.devicePixelRatio,
  });

  final List<String> matrix;
  final Color color;
  final double devicePixelRatio;

  /// Côté d'une cellule en dp : `size / 16` arrondi à un multiple entier de
  /// pixels physiques (au moins 1 pixel physique).
  static double cellSize(double size, double devicePixelRatio) {
    final raw = size / kPixelIconGrid;
    final physical = (raw * devicePixelRatio).roundToDouble();
    return (physical < 1 ? 1 : physical) / devicePixelRatio;
  }

  /// Rectangles à peindre : les suites horizontales de `#` d'une ligne sont
  /// fusionnées en un seul rectangle.
  static List<Rect> runs(List<String> matrix, double cell, Offset origin) {
    final rects = <Rect>[];
    for (var row = 0; row < matrix.length; row++) {
      final line = matrix[row];
      var col = 0;
      while (col < line.length) {
        if (line[col] != '#') {
          col++;
          continue;
        }
        final start = col;
        while (col < line.length && line[col] == '#') {
          col++;
        }
        rects.add(
          Rect.fromLTWH(
            origin.dx + start * cell,
            origin.dy + row * cell,
            (col - start) * cell,
            cell,
          ),
        );
      }
    }
    return rects;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cell = cellSize(size.width, devicePixelRatio);
    final extent = cell * kPixelIconGrid;
    // Grille centrée si l'arrondi physique la rend plus petite que la boîte,
    // alignée sur un pixel physique.
    final dx =
        ((size.width - extent) / 2 * devicePixelRatio).floorToDouble() /
        devicePixelRatio;
    final dy =
        ((size.height - extent) / 2 * devicePixelRatio).floorToDouble() /
        devicePixelRatio;
    final paint = Paint()
      ..color = color
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none;
    for (final rect in runs(matrix, cell, Offset(dx, dy))) {
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(PixelIconPainter oldDelegate) =>
      !listEquals(oldDelegate.matrix, matrix) ||
      oldDelegate.color != color ||
      oldDelegate.devicePixelRatio != devicePixelRatio;
}
