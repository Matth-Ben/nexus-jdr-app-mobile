import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'dashed_border_painter.dart';

/// Tuile "+ {label}" en pointillés, pleine largeur, hauteur fixe 48px —
/// composant partagé (`core/widgets/`), extrait de
/// `features/characters/presentation/widgets/character_inventory_tab_body.dart`
/// (tuile "+ Ajouter un objet" en bas de l'onglet "Inventaire") pour être
/// réutilisé tel quel par `add_reward_sheet.dart` (même libellé/déclenche le
/// même flux d'ajout, en mode "collecte locale").
class DashedAddTile extends StatelessWidget {
  const DashedAddTile({required this.label, required this.onTap, super.key});

  final String label;

  /// `null` désactive le tap (ex. verrou `actionsDisabled` de tout l'onglet
  /// "Inventaire") sans changer le rendu au repos — même convention que
  /// `CharacterInventoryItemCard.onTap`.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        height: 48,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: CustomPaint(
          painter: const DashedBorderPainter(color: AppColors.textMuted),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add, size: 18, color: AppColors.textMuted),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: AppTypography.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
