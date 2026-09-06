import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/step_progress_bar.dart';

/// Gabarit commun aux 3 étapes du flux "Rejoindre un groupe" — calque exact
/// de `features/join_story/presentation/widgets/join_step_header.dart`
/// (`JoinStepHeader`/`JoinStepMinimalHeader`), adapté à 3 étapes au lieu de 4
/// (voir `docs/cahier-des-charges/12-partage-et-groupes.md` section 2 :
/// "calque EXACT de `lib/features/join_story/presentation/*`") — même titre
/// fixe "REJOINDRE" que le flux "Rejoindre une histoire" (les deux flux ne
/// sont jamais visibles en même temps, aucun risque de confusion en
/// pratique).
class GroupJoinStepHeader extends StatelessWidget {
  const GroupJoinStepHeader({
    required this.stepTitle,
    required this.currentStep,
    required this.onBack,
    super.key,
  });

  final String stepTitle;
  final int currentStep;
  final VoidCallback onBack;

  static const int totalSteps = 3;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.woodMedium,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: AppColors.textOnWood,
                      ),
                    ),
                    Text(
                      'REJOINDRE',
                      style: AppTypography.display(
                        fontSize: 11,
                        color: AppColors.textOnWood,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          stepTitle,
                          style: AppTypography.body(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textOnWood,
                          ),
                        ),
                        Text(
                          'Étape $currentStep / $totalSteps',
                          style: AppTypography.body(
                            fontSize: 13,
                            color: AppColors.textOnWoodMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    StepProgressBar(
                      totalSteps: totalSteps,
                      currentStep: currentStep,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bandeau bois minimal (retour + "REJOINDRE" uniquement) — affiché pendant
/// le chargement/l'erreur de l'étape 2/3, même patron que
/// `JoinStepMinimalHeader`.
class GroupJoinStepMinimalHeader extends StatelessWidget {
  const GroupJoinStepMinimalHeader({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.woodMedium,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.textOnWood,
                ),
              ),
              Text(
                'REJOINDRE',
                style: AppTypography.display(
                  fontSize: 11,
                  color: AppColors.textOnWood,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
