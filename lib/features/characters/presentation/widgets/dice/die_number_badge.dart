import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import 'die_skin.dart';

/// Pastille du chiffre du résultat : `font.body` 800, 28 dp (1 chiffre) /
/// 24 dp (2 chiffres), plafonné à ×1,3 (conteneur de taille fixe), fond
/// opaque à ≥ 70 %, contraste ≥ 4,5:1 garanti par [DieSkin.ensureReadable].
/// 6, 9, 16 et 19 sont soulignés (un trait de 2 dp) pour ne pas se confondre
/// à l'envers.
class DieNumberBadge extends StatelessWidget {
  const DieNumberBadge({
    required this.value,
    required this.skin,
    this.opacity = 1,
    super.key,
  });

  final int value;
  final DieSkin skin;
  final double opacity;

  /// Chiffres ambigus à l'envers.
  static const Set<int> underlined = {6, 9, 16, 19};

  @override
  Widget build(BuildContext context) {
    final safe = skin.ensureReadable();
    final fontSize = value >= 10 ? 24.0 : 28.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: safe.numberBackdropColor.withValues(
          alpha: safe.numberBackdropOpacity * opacity,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md + 3),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          '$value',
          textScaler: MediaQuery.textScalerOf(context)
              .clamp(maxScaleFactor: 1.3),
          style:
              AppTypography.body(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: safe.numberColor.withValues(alpha: opacity),
                height: 1.1,
              ).copyWith(
                decoration: underlined.contains(value)
                    ? TextDecoration.underline
                    : TextDecoration.none,
                decorationColor: safe.numberColor.withValues(alpha: opacity),
                decorationThickness: 2,
              ),
        ),
      ),
    );
  }
}
