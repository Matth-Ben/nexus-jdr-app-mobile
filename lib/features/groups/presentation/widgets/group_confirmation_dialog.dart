import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/destructive_button.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';

/// Dialogue de confirmation léger (titre + message + "Annuler"/[confirmLabel])
/// — calque exact de
/// `characters/presentation/widgets/portrait_upload_sheet.dart::
/// showRemovePortraitConfirmationDialog`, factorisé ici pour les 3 usages du
/// chantier "Système de groupe" (`docs/cahier-des-charges/
/// 12-partage-et-groupes.md` section 2.2) : "Quitter « {nom} } ?"/"Exclure
/// {personnage} du groupe ?" ([destructive] par défaut, même bouton
/// `DestructiveButton` que "Retirer") et "Régénérer le code d'invitation ?"
/// (`destructive: false`, spec explicite de la tâche : "`PrimaryButton` PAS
/// `DestructiveButton`"). Pure (aucun appel réseau) : l'appelant réalise
/// l'écriture après avoir reçu `true`, même principe que
/// `removeItemFlow`/`onRemoveItem`. Retourne `true` si le joueur confirme,
/// `false`/`null` sinon.
Future<bool?> showGroupConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = true,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
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
              title,
              style: AppTypography.body(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: AppTypography.body(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Annuler',
                    surface: SecondaryButtonSurface.parchment,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: destructive
                      ? DestructiveButton(
                          label: confirmLabel,
                          onPressed: () => Navigator.of(context).pop(true),
                        )
                      : PrimaryButton(
                          label: confirmLabel,
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
