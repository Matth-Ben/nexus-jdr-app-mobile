import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/sheet_action_row.dart';
import '../../domain/character_class_feature.dart';
import '../../domain/class_feature_usage_formatter.dart';
import 'class_feature_info_panel.dart';

/// Callback d'exécution de l'action "Utiliser" une aptitude de classe à
/// usage limité — délègue toute la logique d'écriture (optimiste + réseau +
/// message) à l'appelant, voir
/// `character_detail_screen.dart::_useClassFeature`.
typedef UseClassFeatureCallback = void Function(CharacterClassFeature feature);

/// Ouvre la sheet "Actions d'aptitude" (tap sur une ligne d'aptitude à usage
/// limité de la carte "APTITUDES DE CLASSE",
/// `character_class_features_card.dart::_FeatureRow`) — gabarit A, mêmes
/// principes que [showSpellActionSheet]
/// (`spell_action_sheet.dart`)/`showPortraitUploadSheet` : deux actions,
/// "Infos" (ouvre [showClassFeatureInfoPanel]) et "Utiliser" (appelle
/// directement [onUseFeature], pas de sheet de choix intermédiaire — un seul
/// coût possible, contrairement au lancer de sort).
Future<void> showClassFeatureActionSheet(
  BuildContext context, {
  required CharacterClassFeature feature,
  required UseClassFeatureCallback onUseFeature,
}) async {
  final action = await showModalBottomSheet<_FeatureSheetAction>(
    context: context,
    backgroundColor: AppColors.parchmentCard,
    isScrollControlled: true,
    builder: (sheetContext) => _FeatureActionSheetContent(feature: feature),
  );
  if (action == null || !context.mounted) return;

  switch (action) {
    case _FeatureSheetAction.info:
      await showClassFeatureInfoPanel(
        context,
        feature: feature,
        onUseFeature: onUseFeature,
      );
    case _FeatureSheetAction.use:
      onUseFeature(feature);
  }
}

enum _FeatureSheetAction { info, use }

class _FeatureActionSheetContent extends StatelessWidget {
  const _FeatureActionSheetContent({required this.feature});

  final CharacterClassFeature feature;

  @override
  Widget build(BuildContext context) {
    // Aptitude jamais encore utilisée (`character_feature_uses` sans ligne
    // pour elle) : aucune utilisation encore consommée, même repli que
    // `ClassFeatureUsageFormatter.format`.
    final remaining = feature.usesRemaining ?? feature.usesMax!;
    final exhausted = remaining <= 0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              feature.name,
              style: AppTypography.body(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              // Sortie littérale du formateur déjà existant — voir la spec
              // visuelle de la tâche ("ne pas réécrire ce formateur").
              ClassFeatureUsageFormatter.format(feature) ?? '',
              style: AppTypography.body(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE0D2AB)),
            SheetActionRow(
              icon: Icons.info_outline,
              label: 'Infos',
              onTap: () => Navigator.of(context).pop(_FeatureSheetAction.info),
            ),
            SheetActionRow(
              icon: Icons.bolt_outlined,
              label: 'Utiliser',
              enabled: !exhausted,
              trailingText: exhausted ? 'Épuisée' : null,
              trailingTextColor: AppColors.accentBrick,
              onTap: () => Navigator.of(context).pop(_FeatureSheetAction.use),
            ),
          ],
        ),
      ),
    );
  }
}
