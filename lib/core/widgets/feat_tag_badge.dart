import 'package:flutter/material.dart';

import '../../features/characters/domain/feat_tag.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Pastille d'étiquette d'un don proposé au choix (P13) : « Épopée » ou
/// « Campagne ». Purement informative et non interactive : elle ne grise ni
/// ne masque jamais le don.
///
/// Gabarit de `NotProficientBadge` (fond `parchmentCard`, contour coloré
/// `AppBorders.card`, `AppRadius.sm`) ; la couleur n'est portée que par le
/// contour et l'icône, le texte reste `woodDark` (contraste AA), `body` 12
/// gras. Jamais la couleur seule : texte + icône.
///
/// Accessibilité : le texte est lu avec la ligne du don (le conteneur
/// fusionne ses descendants) ; l'icône est décorative.
class FeatTagBadge extends StatelessWidget {
  const FeatTagBadge({required this.tag, super.key});

  final FeatTag tag;

  /// Libellé localisé de [tag] (aussi utilisé par les tests).
  static String labelOf(AppLocalizations l10n, FeatTag tag) => switch (tag) {
    FeatTag.epic => l10n.featTagEpic,
    FeatTag.campaign => l10n.featTagCampaign,
  };

  @override
  Widget build(BuildContext context) {
    final color = switch (tag) {
      FeatTag.epic => AppColors.accentViolet,
      FeatTag.campaign => AppColors.accentTeal,
    };
    final icon = switch (tag) {
      FeatTag.epic => Icons.auto_awesome,
      FeatTag.campaign => Icons.map_outlined,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color, width: AppBorders.card),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(child: Icon(icon, size: 14, color: color)),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              labelOf(AppLocalizations.of(context)!, tag),
              style: AppTypography.body(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.woodDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
