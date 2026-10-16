import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Bouton d'authentification sociale (design système, écran de connexion) —
/// nommé génériquement (pas `GoogleSignInButton`) pour pouvoir accueillir un
/// futur bouton Apple sans dupliquer ce composant.
///
/// Fond `parchment.card-alt` (pas `parchment.card`, déjà le fond de la carte
/// de connexion — invisible sinon), bordure 2px `wood.light`, pas d'ombre
/// (pas de style "pressable" comme [PrimaryButton], cohérent avec
/// [SecondaryButton]). Exception typographique délibérée : [AppTypography
/// .body] et non [AppTypography.display] — une police pixel art casserait la
/// reconnaissance immédiate attendue d'un bouton OAuth.
class SocialAuthButton extends StatelessWidget {
  const SocialAuthButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  /// Libellé affiché tel quel (jamais converti en majuscules, contrairement à
  /// [PrimaryButton]/[SecondaryButton]).
  final String label;

  /// Logo affiché avant [label] (ex. [GoogleGLogo]).
  final Widget icon;

  /// `null` désactive le bouton (ex. pendant une soumission concurrente sur
  /// le même écran).
  final VoidCallback? onPressed;

  /// Remplace le contenu par un indicateur de chargement, et désactive le
  /// bouton, le temps de l'appel OAuth.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    return Opacity(
      opacity: isEnabled ? 1 : 0.6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.parchmentCardAlt,
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
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            icon,
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              label,
                              style: AppTypography.body(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
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
