import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../domain/character_class_feature.dart';
import '../../domain/class_feature_usage_formatter.dart';
import 'class_feature_action_sheet.dart';

/// Ouvre le panneau "Infos" d'une aptitude de classe à usage limité —
/// gabarit B ([SheetHeaderBar], contenu scrollable, pied fixe) : niveau
/// d'obtention, compteur d'utilisation (`ClassFeatureUsageFormatter.format`,
/// littéral), puis description, avec un bouton "Utiliser" en pied qui
/// délègue directement à [onUseFeature] (mêmes états/logique que la sheet
/// d'actions, pour éviter l'aller-retour).
Future<void> showClassFeatureInfoPanel(
  BuildContext context, {
  required CharacterClassFeature feature,
  required UseClassFeatureCallback onUseFeature,
}) async {
  final shouldUse = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _ClassFeatureInfoPanelContent(feature: feature),
  );
  if (shouldUse != true || !context.mounted) return;

  onUseFeature(feature);
}

class _ClassFeatureInfoPanelContent extends StatelessWidget {
  const _ClassFeatureInfoPanelContent({required this.feature});

  final CharacterClassFeature feature;

  @override
  Widget build(BuildContext context) {
    final remaining = feature.usesRemaining ?? feature.usesMax!;
    final exhausted = remaining <= 0;

    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.88,
        child: Container(
          decoration: const BoxDecoration(color: AppColors.parchmentBg),
          child: Column(
            children: [
              SheetHeaderBar(title: feature.name.toUpperCase()),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Obtenue au niveau ${feature.level}.',
                        style: AppTypography.body(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _FeatureInfoRow(
                        label: 'Utilisations',
                        value: ClassFeatureUsageFormatter.format(feature) ?? '',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'DESCRIPTION',
                        style: AppTypography.display(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        feature.description,
                        style: AppTypography.body(fontSize: 14, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: PrimaryButton(
                  label: 'Utiliser',
                  onPressed: exhausted
                      ? null
                      : () => Navigator.of(context).pop(true),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ligne "libellé/valeur" — même gabarit que
/// `spell_info_panel.dart::_SpellInfoRow`, dupliqué ici plutôt que partagé
/// (usage isolé dans chacun des deux panneaux, même rationale de duplication
/// que le reste de ce dépôt).
class _FeatureInfoRow extends StatelessWidget {
  const _FeatureInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: AppTypography.body(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.body(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
