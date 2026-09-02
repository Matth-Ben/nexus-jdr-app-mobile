import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Barre de tête de bottom sheet (fond `wood.medium`, hauteur 56px, titre
/// `font.display` majuscules, icône fermeture zone de tap 44×44) —
/// composant partagé (`core/widgets/`), extrait de
/// `features/xml_import/presentation/xml_import_review_screen.dart`
/// (`_SheetHeaderBar`, gabarit B "mode liste"/"pleine page" du design
/// système) : 3e usage identique (panneaux "Infos" sort/aptitude de la fiche
/// personnage), factorisé ici plutôt que dupliqué une 3e fois.
class SheetHeaderBar extends StatelessWidget {
  const SheetHeaderBar({
    required this.title,
    this.closeEnabled = true,
    super.key,
  });

  final String title;

  /// Désactive le bouton de fermeture (X) sans rien changer visuellement au
  /// reste de la barre — ajouté pour l'éditeur "Histoire" de la fiche
  /// personnage (`presentation/widgets/character_story_edit_sheet.dart`),
  /// qui doit empêcher un tap sur le X d'interrompre un `await` de
  /// sauvegarde en cours (la sheet reste ouverte le temps de l'appel
  /// réseau, voir sa documentation de classe). `true` par défaut :
  /// rétrocompatible avec les usages existants, qui ne passent jamais ce
  /// paramètre.
  final bool closeEnabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: AppColors.woodMedium,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(
                title,
                style: AppTypography.display(
                  fontSize: 11,
                  color: AppColors.textOnWood,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              onPressed: closeEnabled
                  ? () => Navigator.of(context).pop()
                  : null,
              icon: const Icon(Icons.close, color: AppColors.textOnWood),
            ),
          ),
        ],
      ),
    );
  }
}
