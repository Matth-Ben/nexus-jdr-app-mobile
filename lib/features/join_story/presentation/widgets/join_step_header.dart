import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/step_progress_bar.dart';

/// Gabarit commun aux 4 étapes du flux "Rejoindre une histoire" (spec
/// visuelle de la tâche) : bandeau bois plein, titre fixe "REJOINDRE",
/// titre d'étape + "Étape N / 4", `StepProgressBar`.
///
/// Contrairement à l'assistant de création de personnage
/// (`character_creation/presentation/race_step_screen.dart` et consorts, qui
/// dupliquent délibérément ce même bandeau écran par écran — voir sa
/// documentation de classe pour le rationale), un seul composant partagé ici
/// : les 4 étapes de ce flux, bien plus courtes et homogènes, n'ont *aucune*
/// variation de mise en page entre elles au-delà du titre d'étape/du numéro
/// — la spec de la tâche les décrit d'ailleurs explicitement comme un
/// "gabarit commun", contrairement à l'assistant de création où chaque étape
/// a son propre contenu substantiel.
class JoinStepHeader extends StatelessWidget {
  const JoinStepHeader({
    required this.stepTitle,
    required this.currentStep,
    required this.onBack,
    super.key,
  });

  final String stepTitle;
  final int currentStep;
  final VoidCallback onBack;

  static const int totalSteps = 4;

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

/// Bandeau bois minimal (retour + "REJOINDRE" uniquement, sans titre
/// d'étape ni barre de progression) — affiché pendant le chargement/l'erreur
/// de l'étape 2/4, même patron que `_MinimalHeader` de
/// `character_creation/presentation/race_step_screen.dart` et consorts.
class JoinStepMinimalHeader extends StatelessWidget {
  const JoinStepMinimalHeader({required this.onBack, super.key});

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
