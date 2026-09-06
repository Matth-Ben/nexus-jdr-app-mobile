import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../domain/level_up_feat_option.dart';

/// Ouvre le panneau "Infos" d'un don — étape "Choix à faire" de la montée de
/// niveau, sous-mode "don" (spec visuelle direction-artistique section 2 de
/// `presentation/level_up_screen.dart`) : même gabarit B que
/// `class_feature_info_panel.dart` ([SheetHeaderBar], contenu scrollable),
/// mais SANS pied fixe/bouton d'action — un don n'a pas d'activation
/// ("Utiliser"/"Lancer" n'ont pas de sens ici), le bouton de fermeture (X) de
/// [SheetHeaderBar] suffit. Consultable pendant la sélection uniquement,
/// aucune persistance dans un nouvel onglet de la fiche (qui n'existe pas
/// encore pour les dons).
Future<void> showFeatInfoPanel(
  BuildContext context, {
  required LevelUpFeatOption feat,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _FeatInfoPanelContent(feat: feat),
  );
}

class _FeatInfoPanelContent extends StatelessWidget {
  const _FeatInfoPanelContent({required this.feat});

  final LevelUpFeatOption feat;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.88,
        child: Container(
          decoration: const BoxDecoration(color: AppColors.parchmentBg),
          child: Column(
            children: [
              SheetHeaderBar(title: feat.name.toUpperCase()),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (feat.prerequisiteText case final prerequisite?) ...[
                        Text(
                          'Prérequis : $prerequisite',
                          style: AppTypography.body(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      Text(
                        'DESCRIPTION',
                        style: AppTypography.display(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        feat.description,
                        style: AppTypography.body(fontSize: 14, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
