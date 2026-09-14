import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'dashed_border_painter.dart';

/// Bouton pleine largeur à bordure pointillée dorée — variant de
/// [DashedAddTile] (`core/widgets/dashed_add_tile.dart`, même technique de
/// rendu via [DashedBorderPainter]) mais avec une bordure
/// [AppColors.goldEnd] plutôt que neutre `textMuted`, et une icône/un
/// libellé libres plutôt que le seul `Icons.add`. Extrait comme composant
/// partagé (recettage direction-artistique du 13/09) pour le bouton
/// "Répartir vers mon inventaire" de l'onglet "Butin" du groupe
/// (`group_treasure_tab_body.dart`), potentiellement réutilisable ailleurs
/// qu'un simple "+ Ajouter".
///
/// Fond transparent, hauteur minimale 48px (même gabarit que
/// [DashedAddTile]/`PrimaryButton`/`SecondaryButton`). `onPressed` à `null`
/// désactive le bouton et l'assourdit (même convention d'opacité 0.6 que
/// `PrimaryButton`/`SecondaryButton`), contrairement à [DashedAddTile] qui
/// ne change pas son rendu au repos quand désactivé.
class DashedButton extends StatelessWidget {
  const DashedButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;

  /// `null` désactive le tap.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return Opacity(
      opacity: isEnabled ? 1 : 0.6,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: CustomPaint(
              painter: const DashedBorderPainter(color: AppColors.goldEnd),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: AppTypography.display(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
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
      ),
    );
  }
}
