import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// En-tête commun à tout le flux "Montée de niveau"
/// (`presentation/level_up_screen.dart`) : icône bouclier, eyebrow, niveau
/// (optionnel), sous-titre d'étape (optionnel) et sous-titre de chaînage
/// multi-niveaux (optionnel) — voir la spec visuelle direction-artistique,
/// section 0 "Architecture commune du flux scène".
///
/// Toujours visible, jamais interactif, centré — posé directement sur le
/// fond "scène" (`SceneScaffold`), jamais sur une carte parchemin.
class LevelUpHeader extends StatelessWidget {
  const LevelUpHeader({
    required this.eyebrow,
    this.levelLabel,
    this.stepLabel,
    this.remainingLevelsLabel,
    super.key,
  });

  /// "MONTÉE DE NIVEAU" (déclenchement normal) ou "NIVEAU ATTEINT" (écran de
  /// blocage en cours de chaînage, voir la spec visuelle section 6).
  final String eyebrow;

  /// "NIVEAU {n}", `null` seulement pour l'écran de blocage immédiat (aucun
  /// niveau validé dans cette session).
  final String? levelLabel;

  /// "Étape X sur 3 · {nom de l'étape}", affiché uniquement aux étapes 1 et
  /// 2 du flux (jamais au récapitulatif ni sur l'écran de blocage).
  final String? stepLabel;

  /// "Encore {k} niveau(x) à valider ensuite", affiché uniquement en cas de
  /// chaînage multi-seuils (voir `domain/level_up_chain_resolver.dart`).
  final String? remainingLevelsLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        children: [
          const Icon(Icons.shield_outlined, size: 64, color: AppColors.goldEnd),
          const SizedBox(height: AppSpacing.sm),
          Text(
            eyebrow,
            textAlign: TextAlign.center,
            style: AppTypography.display(
              fontSize: 11,
              color: AppColors.textOnWoodMuted,
              letterSpacing: 1.5,
            ),
          ),
          if (levelLabel != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              levelLabel!,
              textAlign: TextAlign.center,
              // `color.text.on-wood`, PAS `goldEnd` : correctif de contraste
              // obligatoire (ratio ~3,7:1 < 4,5:1 AA sur `wood.deep-bg-end`,
              // voir la spec visuelle direction-artistique section 0).
              style: AppTypography.display(
                fontSize: 15,
                color: AppColors.textOnWood,
              ),
            ),
          ],
          if (stepLabel != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              stepLabel!,
              textAlign: TextAlign.center,
              style: AppTypography.body(
                fontSize: 13,
                color: AppColors.textOnWoodMuted,
              ),
            ),
          ],
          if (remainingLevelsLabel != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              remainingLevelsLabel!,
              textAlign: TextAlign.center,
              style: AppTypography.body(
                fontSize: 12,
                color: AppColors.textOnWoodMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
