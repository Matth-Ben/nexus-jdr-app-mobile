import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Pastille « Modifié » — spec du prix d'un objet modifiable (§1.2) : affichée
/// à côté du prix d'un objet du catalogue dont le prix officiel a été
/// surchargé (jamais pour un objet personnalisé, qui n'a pas de prix officiel
/// à surcharger, voir `CharacterInventoryItem.priceIsOverridden`).
///
/// Gabarit de [NotProficientBadge] (padding sm/4, [AppRadius.sm]) mais ton
/// **neutre, pas d'alerte** : fond `parchmentCard`, contour `woodLight`
/// (jamais `accentBrick`), icône [Icons.edit] 12 px `textSecondary`, texte
/// `body` 11 px `textSecondary` (jamais `woodDark`, qui porterait une
/// connotation d'avertissement ici absente).
///
/// Accessibilité : `ExcludeSemantics` — le libellé complet est porté par la
/// ligne qui contient la pastille (même principe que [NotProficientBadge]).
class ModifiedBadge extends StatelessWidget {
  const ModifiedBadge({super.key});

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
            color: AppColors.woodLight,
            width: AppBorders.card,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit, size: 12, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                AppLocalizations.of(context)!.itemPriceOverriddenBadge,
                style: AppTypography.body(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
