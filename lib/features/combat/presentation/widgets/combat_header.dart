import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/compact_action_button.dart';
import '../../../../l10n/app_localizations.dart';

/// En-tête fixe de l'écran Combat (`docs/combat-groupe-ui.md` §1) : « Round N »
/// (jamais en police pixel), « Tour de X » ou « Aucun tour actif · initiatives
/// 2/4 », kebab MJ, bouton « Voir le tour en cours » quand le tour est hors
/// écran. Textes plafonnés ×2,0, hauteur plafonnée à 40 % du viewport.
class CombatHeader extends StatelessWidget {
  const CombatHeader({
    required this.round,
    required this.initiativeEntered,
    required this.initiativeTotal,
    this.turnName,
    this.showKebab = false,
    this.kebabEnabled = true,
    this.onKebab,
    this.reorderMode = false,
    this.onReorderDone,
    this.showJumpToTurn = false,
    this.onJumpToTurn,
    super.key,
  });

  final int round;
  final String? turnName;
  final int initiativeEntered;
  final int initiativeTotal;

  /// Kebab MJ (« Réordonner les égalités », « Terminer le combat »).
  final bool showKebab;
  final bool kebabEnabled;
  final VoidCallback? onKebab;

  /// Mode « Réordonner » : le kebab devient « Terminé ».
  final bool reorderMode;
  final VoidCallback? onReorderDone;

  /// Tour en cours hors écran : bouton « Voir le tour en cours ».
  final bool showJumpToTurn;
  final VoidCallback? onJumpToTurn;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final second = turnName != null
        ? l10n.combatTurnOf(turnName!)
        : '${l10n.combatNoActiveTurn} · '
              '${l10n.combatInitiativeProgress(initiativeEntered, initiativeTotal)}';

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: AppTypography.maxTextScaleFactor,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: viewportHeight * 0.4),
        child: DecoratedBox(
          key: const Key('combatHeader'),
          decoration: BoxDecoration(
            color: AppColors.parchmentCard,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.woodLight,
              width: AppBorders.card,
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                l10n.combatRound(round),
                                style: AppTypography.body(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              second,
                              style: AppTypography.body(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (reorderMode)
                        CompactActionButton(
                          icon: Icons.check,
                          label: l10n.combatReorderDone,
                          onTap: onReorderDone,
                        )
                      else if (showKebab)
                        Tooltip(
                          message: kebabEnabled
                              ? l10n.combatKebabLabel
                              : l10n.combatStartUnavailableOffline,
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: IconButton(
                              key: const Key('combatHeaderMenu'),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 44,
                                height: 44,
                              ),
                              icon: Icon(
                                Icons.more_vert,
                                color: kebabEnabled
                                    ? AppColors.textSecondary
                                    : AppColors.textSecondary.withValues(
                                        alpha: 0.5,
                                      ),
                              ),
                              onPressed: kebabEnabled ? onKebab : null,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (showJumpToTurn) ...[
                    const SizedBox(height: AppSpacing.xs),
                    CompactActionButton(
                      icon: Icons.my_location_outlined,
                      label: l10n.combatJumpToTurn,
                      onTap: onJumpToTurn,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
