import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// "Bouton destructif" du design système
/// (`docs/cahier-des-charges/10-design-system.md` section 4) : fond
/// `#FDECE0` (= [AppColors.alertBannerBackground]), bordure 2px
/// `accent.brick`, texte `font.body` 700 en `accent.brick` — "Réservé aux
/// actions irréversibles (déconnexion, suppression de personnage)".
///
/// Premier composant partagé dédié à ce token, introduit à l'occasion de
/// la confirmation "Retirer le portrait" de la fiche personnage
/// (`presentation/widgets/portrait_upload_sheet.dart`) — depuis, aussi
/// utilisé pour l'action "Se déconnecter" de l'écran Profil
/// (`features/profile/presentation/profile_screen.dart`), et réutilisable
/// tel quel pour la suppression de personnage à venir.
///
/// Contrairement à [PrimaryButton]/[SecondaryButton], le texte n'est **pas**
/// en `font.display`/majuscules : le design système précise explicitement
/// `font.body` 700 pour ce composant.
class DestructiveButton extends StatelessWidget {
  const DestructiveButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

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
          color: AppColors.alertBannerBackground,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.accentBrick,
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
                    label,
                    textAlign: TextAlign.center,
                    style: AppTypography.body(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentBrick,
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
