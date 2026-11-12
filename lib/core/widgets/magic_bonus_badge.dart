import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Pastille « bonus magique » d'une arme (ou, plus tard, d'une armure/d'un
/// bouclier) personnalisée (P7) : icône étincelle + « +1 ».
///
/// Gabarit de `NotProficientBadge` : fond `parchmentCard`, contour `goldEnd`
/// (l'or n'est porté que par le contour et l'icône), texte `woodDark` en
/// `body` 11 px (contraste AA). Le bonus est aussi écrit en toutes lettres
/// (« +1 ») et dans le libellé sémantique : jamais la couleur seule.
///
/// Rien n'est dessiné si [bonus] < 1.
class MagicBonusBadge extends StatelessWidget {
  const MagicBonusBadge({required this.bonus, super.key});

  final int bonus;

  @override
  Widget build(BuildContext context) {
    if (bonus < 1) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.magicBonusBadgeSemantics(bonus),
      container: true,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: AppColors.parchmentCard,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.goldEnd, width: AppBorders.card),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 12, color: AppColors.goldEnd),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '+$bonus',
              style: AppTypography.body(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.woodDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
