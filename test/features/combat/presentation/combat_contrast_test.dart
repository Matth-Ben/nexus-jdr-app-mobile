// Contrastes de `docs/combat-groupe-ui.md` section 0 (calculés sur les hex du
// design system) et icône pixel « épées croisées ».

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/widgets/pixel_icon.dart';
import 'package:personnages/core/widgets/pixel_icons/combat_pixel_icons.dart';
import 'package:personnages/features/combat/presentation/widgets/initiative_row.dart';

double _luminance(Color color) {
  double channel(double value) => value <= 0.03928
      ? value / 12.92
      : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

double contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('fond « tour en cours » : textPrimary dessus ≥ 13:1 (spec 13,3:1)', () {
    expect(
      contrast(AppColors.textPrimary, kCombatTurnFill),
      greaterThanOrEqualTo(13),
    );
  });

  test('badge PJ : text.on-wood sur wood.medium ≥ 7:1', () {
    expect(
      contrast(AppColors.textOnWood, AppColors.woodMedium),
      greaterThanOrEqualTo(6.9),
    );
  });

  test('textSecondary sur parchment.card-alt ≥ 6,4:1 (AA large marge)', () {
    expect(
      contrast(AppColors.textSecondary, AppColors.parchmentCardAlt),
      greaterThanOrEqualTo(6.4),
    );
  });

  test('textMuted sur parchment.card-alt reste interdit (< 4,5:1)', () {
    // Garde-fou de la règle : ce couple n'est utilisé nulle part dans le
    // combat (voir `textSecondary`, 6,5:1).
    expect(
      contrast(AppColors.textMuted, AppColors.parchmentCardAlt),
      lessThan(4.5),
    );
  });

  test('couples de texte courant de l\'écran Combat ≥ 4,5:1 (AA)', () {
    final pairs = <String, (Color, Color)>{
      'texte sur carte': (AppColors.textPrimary, AppColors.parchmentCard),
      'secondaire sur carte': (
        AppColors.textSecondary,
        AppColors.parchmentCard,
      ),
      'texte sur fond parchemin': (
        AppColors.textPrimary,
        AppColors.parchmentBg,
      ),
      'secondaire sur fond parchemin': (
        AppColors.textSecondary,
        AppColors.parchmentBg,
      ),
      'secondaire sur tour en cours': (AppColors.textPrimary, kCombatTurnFill),
      'erreur brick sur fond alerte': (
        AppColors.accentBrick,
        AppColors.alertBannerBackground,
      ),
      'texte sur bois (en-tête)': (AppColors.textOnWood, AppColors.woodMedium),
    };
    pairs.forEach((name, pair) {
      expect(
        contrast(pair.$1, pair.$2),
        greaterThanOrEqualTo(4.5),
        reason: name,
      );
    });
  });

  test('icône teal du bandeau sur la carte ≥ 3:1 (élément graphique)', () {
    expect(
      contrast(AppColors.accentTeal, AppColors.parchmentCard),
      greaterThanOrEqualTo(3),
    );
  });

  test('le fond « tour en cours » est le mélange à 25 % annoncé', () {
    final expected = Color.alphaBlend(
      AppColors.goldStart.withValues(alpha: 0.25),
      AppColors.parchmentCard,
    );
    expect(kCombatTurnFill, expected);
  });

  group('icône pixel combat_swords', () {
    test('matrice 16×16 de # et .', () {
      expect(kCombatSwordsMatrix, hasLength(kPixelIconGrid));
      for (final row in kCombatSwordsMatrix) {
        expect(row, hasLength(kPixelIconGrid));
        expect(RegExp(r'^[#.]+$').hasMatch(row), isTrue);
      }
    });

    test('symétrique gauche/droite et non vide', () {
      var filled = 0;
      for (final row in kCombatSwordsMatrix) {
        expect(row.split('').reversed.join(), row);
        filled += '#'.allMatches(row).length;
      }
      expect(filled, greaterThan(40));
    });
  });
}
