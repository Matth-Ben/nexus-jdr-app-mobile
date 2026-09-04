import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Tuile de menu générique (icône + libellé + chevron) du design système
/// (`docs/cahier-des-charges/10-design-system.md` section 4) : carte
/// `parchmentCard`, bordure 2px `woodLight`, `radius.md`, icône 22px
/// `textSecondary`, libellé `font.body` 14px/700 `textPrimary`, chevron 20px
/// `textMuted`.
///
/// Extrait au 3e usage identique (`ProfileScreen._MenuTile`,
/// `ProfilePrivacyScreen._PrivacyMenuTile`, puis `ProfileHelpScreen`) — voir
/// le commentaire de doc historique de `_PrivacyMenuTile` qui documentait
/// déjà la convention de ce dépôt ("dupliquer jusqu'à 2 usages, extraire au
/// 3e") ; spec direction-artistique de la tâche "Aide et support".
class MenuTile extends StatelessWidget {
  const MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
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
                Icon(icon, color: AppColors.textSecondary, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.body(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textMuted,
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
