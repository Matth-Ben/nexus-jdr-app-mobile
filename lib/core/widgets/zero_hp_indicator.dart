import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Signal d'état "À 0 PV" (décision du 09/11/2026) : icône + libellé, jamais
/// la couleur seule (accessibilité) — mêmes tokens que `AlertBanner`
/// (fond [AppColors.alertBannerBackground], bordure/icône
/// [AppColors.accentBrick]) mais texte en [AppColors.textPrimary] pour un
/// contraste AA. Constat d'état uniquement : aucune règle de jeu.
/// Partagé entre `CharacterVitalsCard` (fiche) et `CharacterCard` (liste,
/// P18) : rendu strictement identique.
class ZeroHpIndicator extends StatelessWidget {
  const ZeroHpIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.alertBannerBackground,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.accentBrick, width: 1),
      ),
      // `Flexible` : le libellé passe à la ligne (texte système agrandi,
      // 320 px) au lieu de déborder ; icône purement décorative.
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ExcludeSemantics(
            child: Icon(
              Icons.heart_broken_outlined,
              size: 16,
              color: AppColors.accentBrick,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              AppLocalizations.of(context)!.characterVitalsCardZeroHpLabel,
              style: AppTypography.body(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
