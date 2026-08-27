import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/character_class_feature.dart';
import '../../domain/class_feature_usage_formatter.dart';

/// Carte "APTITUDES DE CLASSE" de l'onglet "Compétences" : une ligne par
/// aptitude de classe déjà atteinte par le niveau actuel du personnage, avec
/// à droite soit un compteur d'usage ("X / Y · repos long"/"repos court")
/// pour une aptitude à usage limité, soit "Passive" sinon.
///
/// N'affiche rien tant que [features] est vide — appelant responsable de ne
/// pas monter cette carte dans ce cas (voir `character_skills_tab_body.dart`).
class CharacterClassFeaturesCard extends StatelessWidget {
  const CharacterClassFeaturesCard({required this.features, super.key});

  final List<CharacterClassFeature> features;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'APTITUDES DE CLASSE',
            style: AppTypography.display(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final feature in features) _FeatureRow(feature: feature),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.feature});

  final CharacterClassFeature feature;

  @override
  Widget build(BuildContext context) {
    final usageLabel = ClassFeatureUsageFormatter.format(feature);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(feature.name, style: AppTypography.body(fontSize: 14)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            usageLabel ?? 'Passive',
            textAlign: TextAlign.right,
            style: AppTypography.body(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
