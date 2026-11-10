import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../l10n/app_localizations.dart';

/// Dialogue du retour Android depuis la liste racine quand des écritures
/// hors-ligne attendent encore d'être envoyées (T2 du chantier hors-ligne) :
/// « Rester » (primaire) ferme le dialogue, « Quitter quand même »
/// (secondaire) quitte l'app. Un tap hors du dialogue vaut « Rester » (le
/// futur résolu à `null`). Retourne `true` si le joueur choisit de quitter.
///
/// Gabarit identique à `showDeleteCharacterConfirmationDialog`. Aucun
/// équivalent iOS (pas de bouton retour système).
Future<bool?> showSyncExitDialog(
  BuildContext context, {
  required int pendingCount,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      return Dialog(
        backgroundColor: AppColors.parchmentCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(
            color: AppColors.woodLight,
            width: AppBorders.card,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.syncExitDialogTitle,
                style: AppTypography.body(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.syncExitDialogBody(pendingCount),
                style: AppTypography.body(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: l10n.syncExitDialogStay,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: SecondaryButton(
                      label: l10n.syncExitDialogLeave,
                      surface: SecondaryButtonSurface.parchment,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
