import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Bouton secondaire du design système
/// (`docs/cahier-des-charges/10-design-system.md` section 4, "Bouton
/// secondaire") : fond `wood.medium` uni, bordure 2px `wood.light`, texte
/// `font.display` en `color.text.on-wood`, hauteur minimale 48px (même
/// gabarit que [PrimaryButton] pour s'aligner correctement à côté de lui).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  /// Libellé affiché (converti en majuscules à l'affichage).
  final String label;

  /// `null` désactive le bouton.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return Opacity(
      opacity: isEnabled ? 1 : 0.6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.woodMedium,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.woodLight,
            width: AppBorders.card,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: isEnabled ? onPressed : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Text(
                    label.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: AppTypography.display(
                      fontSize: 11,
                      color: AppColors.textOnWood,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
