import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Pastille « Non maîtrisé » d'une armure ou d'un bouclier que le personnage
/// ne maîtrise pas (P10/F16) — une seule copie, trois usages : carte
/// d'inventaire, en-tête de la feuille d'actions et du panneau « Infos ».
///
/// Gabarit de la pastille « ÉQUIPÉ » (padding sm/4, `AppRadius.sm`) mais fond
/// `parchmentCard` et contour `accentBrick` : la couleur n'est portée que par
/// le contour et l'icône, le texte reste `woodDark` (contraste AA), police
/// `body` 11 px (jamais `display`). Purement informative.
///
/// Accessibilité : `ExcludeSemantics` — le libellé complet (« non maîtrisé,
/// désavantage... ») est porté par la ligne/l'en-tête qui contient la
/// pastille, pour ne pas lire deux fois la même chose.
class NotProficientBadge extends StatelessWidget {
  const NotProficientBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: AppColors.parchmentCard,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: AppColors.accentBrick,
            width: AppBorders.card,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 12,
              color: AppColors.accentBrick,
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                AppLocalizations.of(context)!
                    .characterInventoryItemCardNotProficientBadge,
                style: AppTypography.body(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.woodDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
