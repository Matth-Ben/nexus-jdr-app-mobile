import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// "Stepper" de l'assistant de création
/// (`docs/cahier-des-charges/10-design-system.md` section 4) : segments
/// égaux espacés de `space.xs`, segment(s) franchis (dont l'étape courante)
/// en `gold-end`, segments à venir dans un ton bois foncé.
///
/// Composant partagé (`core/widgets/`) plutôt que propre à l'étape Race :
/// les 9 étapes de l'assistant (`04-fonctionnalites-app-mobile.md` section
/// 3) réutiliseront toutes cette même barre.
class StepProgressBar extends StatelessWidget {
  const StepProgressBar({
    required this.totalSteps,
    required this.currentStep,
    super.key,
  });

  /// Nombre total d'étapes de l'assistant.
  final int totalSteps;

  /// Étape courante, 1-indexée.
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var step = 1; step <= totalSteps; step++) ...[
          if (step > 1) const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: step <= currentStep
                    ? AppColors.goldEnd
                    : AppColors.woodDark,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
