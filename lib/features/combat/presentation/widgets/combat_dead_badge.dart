import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';

/// Badge « Mort » d'un héros dans l'ordre d'initiative (décision 58, spec
/// `docs/combat-grimoire-ui.md` §4) : fond `alertBannerBackground`, bordure
/// 1,5 `accentBrick`, `heart_broken_outlined` 16 et « Mort » en `font.body`
/// 11/800 `accentBrick` (5,7:1). Même police que les badges PJ/PNJ pour une
/// ligne homogène ; jamais la couleur seule (texte + icône).
class CombatDeadBadge extends StatelessWidget {
  const CombatDeadBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      key: const Key('combatDeadBadge'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.alertBannerBackground,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.accentBrick, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.heart_broken_outlined,
            size: 16,
            color: AppColors.accentBrick,
          ),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              l10n.combatBadgeDead,
              style: AppTypography.body(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.accentBrick,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
