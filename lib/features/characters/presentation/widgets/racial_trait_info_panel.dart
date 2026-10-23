import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../domain/character_racial_trait.dart';

/// Ouvre le panneau "Infos" d'un trait racial — carte "TRAITS RACIAUX" de
/// l'onglet "Aptitudes" (`character_racial_traits_card.dart`) : même gabarit
/// B que `feat_info_panel.dart`/`class_feature_info_panel.dart`
/// ([SheetHeaderBar], contenu scrollable), MOINS deux lignes qu'elles
/// portent toutes les deux :
/// - pas de "Prérequis" (`feat_info_panel.dart`) : un trait racial n'en a
///   pas, il est acquis avec la race elle-même ;
/// - pas de "Obtenue au niveau X" (`class_feature_info_panel.dart`) : un
///   trait racial n'a pas de niveau d'obtention, contrairement à une
///   aptitude de classe — il est acquis dès la création du personnage.
///
/// Pas de pied/bouton d'action non plus (même rationale que
/// `feat_info_panel.dart`) : le suivi de ressources d'un trait actif à
/// usages limités (ex. "Poussée d'adrénaline" de l'Orc) reste explicitement
/// hors périmètre de ce chantier — voir la documentation de classe de
/// `character_racial_traits_card.dart`. Le texte RAW de la limite d'usage
/// reste dans [CharacterRacialTrait.description], lu ici tel quel.
Future<void> showRacialTraitInfoPanel(
  BuildContext context, {
  required CharacterRacialTrait trait,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _RacialTraitInfoPanelContent(trait: trait),
  );
}

class _RacialTraitInfoPanelContent extends StatelessWidget {
  const _RacialTraitInfoPanelContent({required this.trait});

  final CharacterRacialTrait trait;

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
              SheetHeaderBar(title: trait.name.toUpperCase()),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DESCRIPTION',
                        style: AppTypography.display(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        trait.description.isEmpty
                            ? 'Description indisponible.'
                            : trait.description,
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
