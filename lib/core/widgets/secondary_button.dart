import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Surface sur laquelle repose un [SecondaryButton], qui détermine son
/// habillage (voir `docs/cahier-des-charges/10-design-system.md` section 4,
/// "Bouton secondaire").
enum SecondaryButtonSurface {
  /// Écrans "scène" (fond dégradé bois foncé, voir [AppColors.sceneBackground]) :
  /// fond `wood.medium` uni, bordure 2px `wood.light`, texte `font.display`
  /// en `color.text.on-wood`. Comportement historique du composant, gardé
  /// par défaut pour ne rien changer aux usages existants
  /// (`character_list_screen.dart`, bouton "Importer XML").
  scene,

  /// Écrans "parchemin" (fond clair, voir [AppColors.parchmentBg]) : fond
  /// `parchment.card-alt`, bordure 2px `wood.light`, texte `font.display` en
  /// `color.text.secondary` (maquette `02_étape_1_race.png`, bouton
  /// "RETOUR").
  parchment,
}

/// Bouton secondaire du design système
/// (`docs/cahier-des-charges/10-design-system.md` section 4, "Bouton
/// secondaire"), hauteur minimale 48px (même gabarit que [PrimaryButton]
/// pour s'aligner correctement à côté de lui). Son habillage varie selon
/// [surface] (voir [SecondaryButtonSurface]).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.onPressed,
    this.surface = SecondaryButtonSurface.scene,
    super.key,
  });

  /// Libellé affiché (converti en majuscules à l'affichage).
  final String label;

  /// `null` désactive le bouton.
  final VoidCallback? onPressed;

  /// Fond sur lequel le bouton est posé. Voir [SecondaryButtonSurface].
  final SecondaryButtonSurface surface;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    final backgroundColor = switch (surface) {
      SecondaryButtonSurface.scene => AppColors.woodMedium,
      SecondaryButtonSurface.parchment => AppColors.parchmentCardAlt,
    };
    final textColor = switch (surface) {
      SecondaryButtonSurface.scene => AppColors.textOnWood,
      SecondaryButtonSurface.parchment => AppColors.textSecondary,
    };

    return Opacity(
      opacity: isEnabled ? 1 : 0.6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
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
                      color: textColor,
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
