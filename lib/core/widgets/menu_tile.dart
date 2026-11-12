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
    this.iconColor,
    this.subtitle,
    this.badgeText,
    this.semanticsLabel,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool standalone;

  /// Couleur de l'icône de gauche (`textSecondary` par défaut).
  final Color? iconColor;

  /// Sous-libellé sous [label] (`font.body` 12 `textMuted`), absent par défaut.
  final String? subtitle;

  /// Texte d'un badge `accent.brick` (blanc dessus) devant le chevron — le
  /// chiffre est dans le texte, jamais la couleur seule. Absent par défaut.
  final String? badgeText;

  /// Si non nul, libellé d'accessibilité unique de la ligne (remplace la
  /// lecture du libellé, du sous-libellé et du badge).
  final String? semanticsLabel;

  /// Remplace le chevron par défaut (`Icons.chevron_right`) — ex.
  /// `Icons.north_east` pour une action qui sort de l'app ou ouvre une sheet
  /// système ("Liste de réglages" ne documente qu'un chevron par défaut,
  /// cette extension reste dans le même esprit visuel : une icône de fin
  /// 20px `color.text.muted`).
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final labelText = Text(
      label,
      style: AppTypography.body(
        fontWeight: FontWeight.w700,
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
    );
    final inkContent = Material(
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
              Icon(icon, color: iconColor ?? AppColors.textSecondary, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: subtitle == null
                    ? labelText
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          labelText,
                          Text(
                            subtitle!,
                            style: AppTypography.body(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
              ),
              if (badgeText != null) ...[
                const SizedBox(width: AppSpacing.sm),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.accentBrick,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    child: Text(
                      badgeText!,
                      style: AppTypography.body(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
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

    // Libellé d'accessibilité unique (ligne à badge/sous-libellé) : le texte
    // visible est exclu au profit de [semanticsLabel].
    final content = semanticsLabel == null
        ? inkContent
        : Semantics(
            button: true,
            label: semanticsLabel,
            excludeSemantics: true,
            onTap: onTap,
            child: inkContent,
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
