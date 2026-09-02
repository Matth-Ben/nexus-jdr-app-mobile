import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/destructive_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/sheet_action_row.dart';
import '../../domain/character_inventory_item.dart';
import '../../domain/inventory_category_rules.dart';
import 'item_info_panel.dart';

/// Callback d'exécution de l'action "Utiliser" un objet consommable —
/// délègue toute la logique d'écriture (optimiste + réseau + message) à
/// l'appelant, voir `character_detail_screen.dart::_useInventoryItem`.
typedef UseInventoryItemCallback = void Function(CharacterInventoryItem item);

/// Callback d'exécution de l'action "Équiper"/"Déséquiper" — délègue toute
/// la logique d'écriture à l'appelant, voir
/// `character_detail_screen.dart::_toggleInventoryItemEquipped`.
typedef ToggleInventoryItemEquippedCallback =
    void Function(CharacterInventoryItem item);

/// Callback d'exécution de l'action "Retirer" (déjà confirmée, voir
/// [removeItemFlow]) — délègue toute la logique d'écriture à l'appelant, voir
/// `character_detail_screen.dart::_removeInventoryItem`.
typedef RemoveInventoryItemCallback = void Function(CharacterInventoryItem item);

/// Catégories pour lesquelles l'action "Équiper"/"Déséquiper" a un sens —
/// voir la spec visuelle de la tâche.
const Set<String> equippableInventoryCategories = {'arme', 'armure', 'bouclier'};

/// Ouvre la sheet "Actions d'objet" (tap sur une carte de l'onglet
/// "Inventaire", `character_inventory_item_card.dart`) — même gabarit A que
/// `spell_action_sheet.dart`/`class_feature_action_sheet.dart` : "Infos"
/// (ouvre [showItemInfoPanel]) toujours affichée, "Utiliser"
/// ([CharacterInventoryItem.consumable]) et "Équiper"/"Déséquiper"
/// (catégorie ∈ [equippableInventoryCategories]) affichées selon les
/// conditions de la spec, puis "Retirer" (toujours, séparée par un
/// [SheetActionDivider], couleur `accentBrick`).
///
/// Un objet personnalisé ([CharacterInventoryItem.isCustom]) n'a jamais
/// "Utiliser" ni "Équiper"/"Déséquiper" (pas de `consumable`/`category`
/// résolus, voir la documentation de ces champs) : seulement "Infos" et
/// "Retirer".
Future<void> showItemActionSheet(
  BuildContext context, {
  required CharacterInventoryItem item,
  required UseInventoryItemCallback onUseItem,
  required ToggleInventoryItemEquippedCallback onToggleEquipped,
  required RemoveInventoryItemCallback onRemoveItem,
}) async {
  final action = await showModalBottomSheet<_ItemSheetAction>(
    context: context,
    backgroundColor: AppColors.parchmentCard,
    isScrollControlled: true,
    builder: (sheetContext) => _ItemActionSheetContent(item: item),
  );
  if (action == null || !context.mounted) return;

  switch (action) {
    case _ItemSheetAction.info:
      await showItemInfoPanel(
        context,
        item: item,
        onUseItem: onUseItem,
        onToggleEquipped: onToggleEquipped,
      );
    case _ItemSheetAction.use:
      onUseItem(item);
    case _ItemSheetAction.toggleEquipped:
      onToggleEquipped(item);
    case _ItemSheetAction.remove:
      await removeItemFlow(context, item: item, onRemoveItem: onRemoveItem);
  }
}

/// Orchestre l'action "Retirer" (bouton de [showItemActionSheet] ou pied du
/// panneau "Infos" n'en a pas — seulement la sheet d'actions, voir la spec) :
/// ouvre le dialogue de confirmation ([showRemoveInventoryItemConfirmationDialog],
/// calque exact de `showRemovePortraitConfirmationDialog`), puis appelle
/// [onRemoveItem] seulement si confirmé.
Future<void> removeItemFlow(
  BuildContext context, {
  required CharacterInventoryItem item,
  required RemoveInventoryItemCallback onRemoveItem,
}) async {
  final confirmed = await showRemoveInventoryItemConfirmationDialog(
    context,
    itemName: item.name,
  );
  if (confirmed != true || !context.mounted) return;
  onRemoveItem(item);
}

enum _ItemSheetAction { info, use, toggleEquipped, remove }

class _ItemActionSheetContent extends StatelessWidget {
  const _ItemActionSheetContent({required this.item});

  final CharacterInventoryItem item;

  @override
  Widget build(BuildContext context) {
    final equippable =
        !item.isCustom && equippableInventoryCategories.contains(item.category);
    final usable = !item.isCustom && item.consumable;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name,
              style: AppTypography.body(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${InventoryCategoryRules.labelFor(item.category)} · '
              'x${item.quantity}',
              style: AppTypography.body(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE0D2AB)),
            SheetActionRow(
              icon: Icons.info_outline,
              label: 'Infos',
              onTap: () => Navigator.of(context).pop(_ItemSheetAction.info),
            ),
            if (usable)
              SheetActionRow(
                icon: Icons.check_circle_outline,
                label: 'Utiliser',
                onTap: () => Navigator.of(context).pop(_ItemSheetAction.use),
              ),
            if (equippable)
              SheetActionRow(
                icon: Icons.checkroom_outlined,
                label: item.equipped ? 'Déséquiper' : 'Équiper',
                onTap: () =>
                    Navigator.of(context).pop(_ItemSheetAction.toggleEquipped),
              ),
            const SheetActionDivider(),
            SheetActionRow(
              icon: Icons.delete_outline,
              label: 'Retirer',
              color: AppColors.accentBrick,
              onTap: () => Navigator.of(context).pop(_ItemSheetAction.remove),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialogue de confirmation "Retirer {nom} ?" — calque exact de
/// `portrait_upload_sheet.dart::showRemovePortraitConfirmationDialog`, avec
/// [itemName] en plus dans le titre et un texte fixe ("Cette action est
/// définitive.") plutôt qu'aucun texte du tout (spec de la tâche). Retourne
/// `true` si le joueur confirme, `false`/`null` sinon.
Future<bool?> showRemoveInventoryItemConfirmationDialog(
  BuildContext context, {
  required String itemName,
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
              'Retirer $itemName ?',
              style: AppTypography.body(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Cette action est définitive.',
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
                    label: 'Retirer',
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
