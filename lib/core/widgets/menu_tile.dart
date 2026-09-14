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
///
/// [standalone] (`true` par défaut, comportement historique inchangé) porte
/// sa propre carte (fond/bordure/rayon ci-dessous) — usages isolés
/// (`ProfileHelpScreen`, `character_share_screen.dart`,
/// `group_settings_screen.dart`...). À `false`, la tuile ne dessine plus
/// aucune carte/bordure propre : pensé pour être empilé comme ligne d'un
/// `core/widgets/settings_list_card.dart::SettingsListCard`, qui porte déjà
/// la carte englobante (recettage direction-artistique du 13/09/2026, "Liste
/// de réglages" de `docs/cahier-des-charges/10-design-system.md` section 4).
class MenuTile extends StatelessWidget {
  const MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.standalone = true,
    this.trailingIcon,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool standalone;

  /// Remplace le chevron par défaut (`Icons.chevron_right`) — ex.
  /// `Icons.north_east` pour une action qui sort de l'app ou ouvre une sheet
  /// système ("Liste de réglages" ne documente qu'un chevron par défaut,
  /// cette extension reste dans le même esprit visuel : une icône de fin
  /// 20px `color.text.muted`).
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final content = Material(
      color: Colors.transparent,
      borderRadius: standalone ? BorderRadius.circular(AppRadius.md) : null,
      child: InkWell(
        borderRadius: standalone ? BorderRadius.circular(AppRadius.md) : null,
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
              Icon(
                trailingIcon ?? Icons.chevron_right,
                color: AppColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );

    if (!standalone) return content;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: content,
    );
  }
}
