import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/destructive_button.dart';
import '../../../../core/widgets/secondary_button.dart';

/// Dialogues de confirmation avant suppression définitive d'un ou plusieurs
/// personnages — regroupés ici (plutôt que dans `character_detail_screen.dart`
/// pour le singulier et `character_list_screen.dart` pour le pluriel) pour ne
/// jamais dupliquer le gabarit visuel partagé (`Dialog` `parchment.card`,
/// bordure 2px `wood.light`, `radius.md`, `SecondaryButton`/`DestructiveButton`).

/// Dialogue de confirmation "Supprimer {nom} ?" — calque exact de
/// `item_action_sheet.dart::showRemoveInventoryItemConfirmationDialog`, avec
/// un texte adapté à la portée bien plus large de cette suppression (tout le
/// personnage, pas un seul objet). Retourne `true` si le joueur confirme,
/// `false`/`null` sinon.
///
/// Utilisé pour la suppression d'un unique personnage (menu "…" de la fiche,
/// menu d'actions au clic long d'une carte, et suppression groupée quand
/// exactement un personnage est sélectionné — voir
/// [showDeleteCharactersConfirmationDialog] pour n > 1).
Future<bool?> showDeleteCharacterConfirmationDialog(
  BuildContext context, {
  required String characterName,
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
              'Supprimer $characterName ?',
              style: AppTypography.body(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Cette action est définitive : le personnage et toutes ses '
              'données (sorts, inventaire, historique...) seront '
              'irrémédiablement supprimés.',
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
                  child: DestructiveButton(
                    label: 'Supprimer',
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

/// Variante de [showDeleteCharacterConfirmationDialog] pour une suppression
/// groupée de [count] personnages (mode sélection multiple de
/// `character_list_screen.dart`, n > 1 — le cas n == 1 réutilise directement
/// [showDeleteCharacterConfirmationDialog], qui nomme le personnage plutôt
/// que de le compter). Même gabarit visuel, titre/corps/bouton adaptés au
/// pluriel. Retourne `true` si le joueur confirme, `false`/`null` sinon.
Future<bool?> showDeleteCharactersConfirmationDialog(
  BuildContext context, {
  required int count,
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
              'Supprimer ces $count personnages ?',
              style: AppTypography.body(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Cette action est définitive : les personnages et toutes '
              'leurs données (sorts, inventaire, historique...) seront '
              'irrémédiablement supprimés.',
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
                  child: DestructiveButton(
                    label: 'Supprimer ($count)',
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
