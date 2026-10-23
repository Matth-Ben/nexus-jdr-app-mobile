import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/sheet_header_bar.dart';

/// Ouvre le panneau "Infos" d'un don — même gabarit B que
/// `class_feature_info_panel.dart` ([SheetHeaderBar], contenu scrollable),
/// mais SANS pied fixe/bouton d'action — un don n'a pas d'activation
/// ("Utiliser"/"Lancer" n'ont pas de sens ici), le bouton de fermeture (X) de
/// [SheetHeaderBar] suffit.
///
/// Généralisé à `name`/`description`/[prerequisiteText] plutôt que typé sur
/// un seul modèle de domaine (chantier carte "DONS" de l'onglet "Aptitudes",
/// voir `character_feats_card.dart`) : partagé par deux provenances qui
/// n'ont pas le même cycle de vie —
/// - `LevelUpFeatOption` (`domain/level_up_feat_option.dart`), étape "Choix
///   à faire" de la montée de niveau, sous-mode "don" (spec visuelle
///   direction-artistique section 2 de `presentation/level_up_screen.dart`) :
///   consultable pendant la sélection uniquement, aucune persistance dans un
///   nouvel onglet de la fiche ;
/// - `CharacterFeatSummary` (`domain/character_feat_summary.dart`), carte
///   "DONS" de l'onglet "Aptitudes" : un don déjà possédé par le
///   personnage.
///
/// Les deux rendent un panneau pixel-identique (même contenu, même mise en
/// page) sans dupliquer ce widget.
Future<void> showFeatInfoPanel(
  BuildContext context, {
  required String name,
  required String description,
  String? prerequisiteText,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _FeatInfoPanelContent(
      name: name,
      description: description,
      prerequisiteText: prerequisiteText,
    ),
  );
}

class _FeatInfoPanelContent extends StatelessWidget {
  const _FeatInfoPanelContent({
    required this.name,
    required this.description,
    this.prerequisiteText,
  });

  final String name;
  final String description;
  final String? prerequisiteText;

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
              SheetHeaderBar(title: name.toUpperCase()),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (prerequisiteText case final prerequisite?) ...[
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
                        description,
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
