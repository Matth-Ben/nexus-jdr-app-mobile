import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'accent_icon_badge.dart';

/// Une ligne de "gain" de l'écran "Montée de niveau"
/// (`features/characters/presentation/level_up_screen.dart`) : badge
/// d'accent coloré, titre en gras et sous-titre secondaire — utilisée à la
/// fois pour l'aperçu live de l'étape "Points de vie", la liste des
/// aptitudes automatiques de l'étape 2 et le récapitulatif final (spec
/// visuelle direction-artistique, section 7 "Nouveaux composants partagés").
///
/// Composant partagé (`core/widgets/`) dès sa première utilisation, comme
/// `AccentIconBadge`/`StepperCounter` : plusieurs écrans du flux "Montée de
/// niveau" le réutilisent tel quel.
class GainRow extends StatelessWidget {
  const GainRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AccentIconBadge(icon: icon, color: color),
        const SizedBox(width: AppSpacing.sm),
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
              Text(
                subtitle,
                style: AppTypography.body(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
