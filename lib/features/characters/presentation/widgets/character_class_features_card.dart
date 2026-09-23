import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/character_class_feature.dart';
import '../../domain/class_feature_usage_formatter.dart';
import 'class_feature_action_sheet.dart';
import 'class_feature_info_panel.dart';

/// Carte "APTITUDES DE CLASSE" de l'onglet "Compétences" : une ligne par
/// aptitude de classe déjà atteinte par le niveau actuel du personnage, avec
/// à droite soit un compteur d'usage ("X / Y · repos long"/"repos court")
/// pour une aptitude à usage limité, soit "Passive" sinon.
///
/// Chaque aptitude (passive comprise) est cliquable et ouvre directement son
/// panneau de description ([showClassFeatureInfoPanel]), qui porte aussi le
/// bouton "Utiliser" d'une aptitude à usage limité.
///
/// N'affiche rien tant que [features] est vide — appelant responsable de ne
/// pas monter cette carte dans ce cas (voir `character_skills_tab_body.dart`).
///
/// [title] surchargeable (par défaut "APTITUDES DE CLASSE") — réutilisé tel
/// quel par `character_spells_tab_body.dart` pour sa carte de pied
/// "INVOCATIONS & APTITUDES À USAGE LIMITÉ" (recettage direction-artistique
/// du 13/09), filtrée aux seules aptitudes non passives : même formatage de
/// ligne que la carte "Aptitudes de classe" de l'onglet "Compétences", sans
/// dupliquer [_FeatureRow].
class CharacterClassFeaturesCard extends StatelessWidget {
  const CharacterClassFeaturesCard({
    required this.features,
    required this.onUseFeature,
    this.actionsDisabled = false,
    this.title = 'APTITUDES DE CLASSE',
    super.key,
  });

  final List<CharacterClassFeature> features;
  final UseClassFeatureCallback onUseFeature;
  final String title;

  /// `true` pendant qu'un repos (court ou long) est en cours d'application —
  /// voir `character_detail_screen.dart::_isApplyingRest` et la
  /// documentation de `character_spells_section.dart::actionsDisabled` pour
  /// le rationale exact (même verrou, même type de course fermée).
  final bool actionsDisabled;

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
            title,
            style: AppTypography.display(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final feature in features)
            _FeatureRow(
              feature: feature,
              onUseFeature: onUseFeature,
              enabled: !actionsDisabled,
            ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.feature,
    required this.onUseFeature,
    required this.enabled,
  });

  final CharacterClassFeature feature;
  final UseClassFeatureCallback onUseFeature;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final usageLabel = ClassFeatureUsageFormatter.format(feature);

    final row = Padding(
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
          const SizedBox(width: AppSpacing.xs / 2),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
        ],
      ),
    );

    // Toute aptitude (passive comprise) ouvre directement son panneau de
    // description au tap (demande utilisateur, 2026-09-24) ; pour une
    // aptitude à usage limité, ce panneau porte aussi le bouton "Utiliser",
    // désactivé tant que [enabled] est faux.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showClassFeatureInfoPanel(
          context,
          feature: feature,
          onUseFeature: onUseFeature,
          canUse: enabled,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: row,
        ),
      ),
    );
  }
}
