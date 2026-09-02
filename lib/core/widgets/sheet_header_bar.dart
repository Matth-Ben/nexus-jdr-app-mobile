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
  const SheetHeaderBar({required this.title, super.key});

  final String title;

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
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: AppColors.textOnWood),
            ),
          ),
        ],
      ),
    );
  }
}
