import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Ligne de liste sélectionnable à choix exclusif, combinant les composants
/// "Case à cocher / élément de liste sélectionnable" et "Bouton radio" de
/// `docs/cahier-des-charges/10-design-system.md` section 4 : fond
/// `parchment.card`, bordure `wood.light` normale à l'état non sélectionné,
/// bordure `gold-end` mise en avant à l'état sélectionné, bouton radio à
/// droite.
///
/// Composant partagé (`core/widgets/`) : réutilisé par les choix mutuellement
/// exclusifs de l'assistant de création (race, sous-race, et plus tard
/// classe, historique, méthode de génération des caractéristiques...).
class SelectableOptionTile extends StatelessWidget {
  const SelectableOptionTile({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.leading,
    super.key,
  });

  final String title;

  /// Ligne de résumé optionnelle affichée sous [title].
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  /// Icône/illustration à gauche de la ligne, ex. un badge coloré.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.parchmentCard,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? AppColors.goldEnd : AppColors.woodLight,
              width: selected ? AppBorders.cardEmphasis : AppBorders.card,
            ),
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTypography.body(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTypography.body(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _RadioIndicator(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bouton radio 20×20px du design système : bordure `wood.light` neutre à
/// l'état non sélectionné ; fond `gold-end` + bordure `wood.dark` + coche
/// blanche centrée à l'état sélectionné.
class _RadioIndicator extends StatelessWidget {
  const _RadioIndicator({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.goldEnd : Colors.transparent,
        border: Border.all(
          color: selected ? AppColors.woodDark : AppColors.woodLight,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }
}
