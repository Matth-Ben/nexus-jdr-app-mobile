import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// "Ligne destructive" — même famille visuelle que
/// `menu_tile.dart::MenuTile` (carte + icône + libellé + chevron), mais
/// palette dédiée du "Bouton destructif"
/// (`docs/cahier-des-charges/10-design-system.md` section 4 : fond
/// `#FDECE0`, bordure 2px `accent.brick`) plutôt que la palette neutre de
/// `MenuTile` — réservée aux actions de navigation vers un flux irréversible
/// (ex. "Supprimer mon compte").
///
/// Remplace le `DestructiveButton` utilisé jusqu'ici pour "Supprimer mon
/// compte" sur `ProfilePrivacyScreen` (recettage direction-artistique du
/// 13/09/2026, zone "ZONE DANGEREUSE") : `DestructiveButton` reste un bouton
/// plein centré (Se déconnecter, confirmations de sheet), alors que cette
/// ligne a la forme d'une tuile de menu (icône à gauche, chevron à droite)
/// pour s'aligner visuellement sur la carte "MES DONNÉES" juste au-dessus —
/// `DestructiveButton` n'est pas modifié, toujours utilisé tel quel
/// ailleurs.
class DestructiveMenuTile extends StatelessWidget {
  const DestructiveMenuTile({
    required this.label,
    required this.onTap,
    super.key,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.delete_outline,
                  color: AppColors.accentBrick,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.body(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.accentBrick,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.accentBrick,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
