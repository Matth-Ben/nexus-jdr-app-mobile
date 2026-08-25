import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Bouton primaire du design système
/// (`docs/cahier-des-charges/10-design-system.md` section 4, "Bouton
/// primaire") : fond dégradé `gold-start` → `gold-end`, bordure 2px
/// `wood.light`, ombre portée basse (effet "bouton pressable"), texte
/// `font.display` en majuscules sur `wood.dark`, hauteur minimale 48px.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  /// Libellé affiché (converti en majuscules à l'affichage).
  final String label;

  /// `null` désactive le bouton (ex. pendant une soumission en cours).
  final VoidCallback? onPressed;

  /// Remplace le libellé par un indicateur de chargement, et désactive le
  /// bouton, le temps d'un appel réseau (ex. connexion/inscription).
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    return Opacity(
      opacity: isEnabled ? 1 : 0.6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.primaryButtonGradient,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.woodLight,
            width: AppBorders.card,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.primaryButtonShadow,
              offset: Offset(0, 3),
            ),
          ],
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
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.woodDark,
                        ),
                      )
                    : Text(
                        label.toUpperCase(),
                        style: AppTypography.display(
                          fontSize: 11,
                          color: AppColors.woodDark,
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
