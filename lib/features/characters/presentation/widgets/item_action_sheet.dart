import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/destructive_button.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/not_proficient_badge.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../../core/widgets/sheet_action_row.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/armor_proficiency_rules.dart';
import '../../domain/character_detail.dart';
import '../../domain/character_inventory_item.dart';
import '../../domain/custom_item_edit_rules.dart';
import '../../domain/inventory_category_rules.dart';
import '../../domain/weapon_attack_calculator.dart';
import '../../domain/weapon_slot.dart';
import 'item_info_panel.dart';
import 'weapon_slot_picker_sheet.dart';

/// Callback d'exécution de l'action "Utiliser" un objet consommable —
/// délègue toute la logique d'écriture (optimiste + réseau + message) à
/// l'appelant, voir `character_detail_screen.dart::_useInventoryItem`.
typedef UseInventoryItemCallback = void Function(CharacterInventoryItem item);

/// Callback d'exécution de l'action "Équiper"/"Déséquiper" — délègue toute
/// la logique d'écriture à l'appelant, voir
/// `character_detail_screen.dart::_toggleInventoryItemEquipped`.
typedef ToggleInventoryItemEquippedCallback = void Function(
  CharacterInventoryItem item,
);

/// Callback d'exécution de l'action "Harmoniser cet objet"/"Ne plus
/// harmoniser" — délègue toute la logique d'écriture à l'appelant, voir
/// `character_detail_screen.dart::_toggleInventoryItemAttuned`.
typedef ToggleInventoryItemAttunedCallback = void Function(
  CharacterInventoryItem item,
);

/// Callback d'exécution de l'action "Retirer" (déjà confirmée, voir
/// [removeItemFlow]) — délègue toute la logique d'écriture à l'appelant, voir
/// `character_detail_screen.dart::_removeInventoryItem`.
typedef RemoveInventoryItemCallback = void Function(
  CharacterInventoryItem item,
);

/// Callback d'exécution de l'action "Équiper"/"Changer de set" d'une arme
/// (choix du set fait via [showWeaponSlotPickerSheet]) — délègue toute la
/// logique d'écriture (calcul du déséquipement automatique inclus) à
/// l'appelant, voir `character_detail_screen.dart::_equipWeaponToSlot`.
typedef EquipWeaponToSlotCallback = void Function(
  CharacterInventoryItem item,
  WeaponSlot slot,
);

/// Callback de l'action « Modifier » / « Enrichir » d'un objet personnalisé
/// (P7 PR 4) : ouvre le formulaire pré-rempli puis écrit le résultat, voir
/// `character_inventory_tab_body.dart`.
typedef EditCustomInventoryItemCallback = Future<void> Function(
  CharacterInventoryItem item,
);

/// Catégories pour lesquelles l'action "Équiper"/"Déséquiper" a un sens —
/// voir la spec visuelle de la tâche.
const Set<String> equippableInventoryCategories = {
  'arme',
  'armure',
  'bouclier',
};

/// `true` si "Équiper"/"Déséquiper" a un sens pour [item] (hors arme, qui
/// passe par les sets d'armes) : armure/bouclier, ou objet magique qui
/// agit sur la CA une fois porté (armure ou bouclier magique, anneau/cape
/// de protection, Armure +N... — voir `domain/armor_class_calculator.dart`).
///
/// Un objet personnalisé de type arme ([CharacterInventoryItem.isWeapon], P7)
/// est équipable comme une arme du catalogue : par set, via la sheet
/// d'actions (jamais par le bouton bascule du panneau « Infos », voir
/// `item_info_panel.dart`).
bool isEquippableItem(CharacterInventoryItem item) => item.isCustom
    ? item.isWeapon || item.isCustomArmorOrShield
    : item.category != 'arme' &&
          (equippableInventoryCategories.contains(item.category) ||
              item.armorProperties != null ||
              item.acBonus != null);

/// Ouvre la sheet "Actions d'objet" (tap sur une carte de l'onglet
/// "Inventaire", `character_inventory_item_card.dart`) — même gabarit A que
/// `spell_action_sheet.dart`/`class_feature_action_sheet.dart` : "Infos"
/// (ouvre [showItemInfoPanel]) toujours affichée, "Utiliser"
/// ([CharacterInventoryItem.consumable]) et "Équiper"/"Déséquiper"
/// (catégorie ∈ [equippableInventoryCategories]) affichées selon les
/// conditions de la spec, puis "Retirer" (toujours, séparée par un
/// [SheetActionDivider], couleur `accentBrick`).
///
/// Cas particulier d'une arme (`category == 'arme'`) : "Équiper"/
/// "Déséquiper" ne bascule jamais directement — équiper une arme requiert de
/// choisir un set ("set principal"/"set secondaire", voir
/// [showWeaponSlotPickerSheet]), donc le libellé est "Équiper" (non équipée)
/// ou "Changer de set" (déjà équipée), et une arme déjà équipée affiche en
/// plus une action "Déséquiper" séparée (bascule directe, sans passer par la
/// sheet de choix de set) — voir [onEquipWeaponToSlot]/[onToggleEquipped].
///
/// Un objet personnalisé ([CharacterInventoryItem.isCustom]) n'a jamais
/// "Utiliser" ni "Équiper"/"Déséquiper" (pas de `consumable`/`category`
/// résolus) ; "Harmoniser" n'apparaît que s'il requiert l'harmonisation
/// (`custom_requires_attunement`, P7) : sinon seulement "Infos" et "Retirer".
///
/// "Harmoniser cet objet" n'apparaît que pour un objet
/// [CharacterInventoryItem.requiresAttunement] — désactivée (grisée, avec
/// un libellé de fin "Limite (3) atteinte") si [attunedCount] a déjà atteint
/// `CharacterDetail.attunementCap` et que l'objet n'est pas déjà harmonisé
/// (le retirer de l'harmonisation reste toujours possible, voir
/// `CharacterDetail.attunementCap`).
Future<void> showItemActionSheet(
  BuildContext context, {
  required CharacterInventoryItem item,
  required UseInventoryItemCallback onUseItem,
  required ToggleInventoryItemEquippedCallback onToggleEquipped,
  required ToggleInventoryItemAttunedCallback onToggleAttuned,
  required RemoveInventoryItemCallback onRemoveItem,
  required int attunedCount,
  required List<CharacterInventoryItem> equippedWeapons,
  required EquipWeaponToSlotCallback onEquipWeaponToSlot,
  int? weaponAttackBonus,
  int? weaponDamageModifier,
  WeaponAttackStats? weaponStats,
  bool notProficient = false,
  EditCustomInventoryItemCallback? onEditCustomItem,
}) async {
  final action = await showModalBottomSheet<_ItemSheetAction>(
    context: context,
    backgroundColor: AppColors.parchmentCard,
    isScrollControlled: true,
    builder: (sheetContext) => _ItemActionSheetContent(
      item: item,
      attunedCount: attunedCount,
      notProficient: notProficient,
      editMode: onEditCustomItem == null ? null : customItemEditModeOf(item),
    ),
  );
  if (action == null || !context.mounted) return;

  switch (action) {
    case _ItemSheetAction.info:
      await showItemInfoPanel(
        context,
        item: item,
        onUseItem: onUseItem,
        onToggleEquipped: onToggleEquipped,
        onToggleAttuned: onToggleAttuned,
        attunedCount: attunedCount,
        weaponAttackBonus: weaponAttackBonus,
        weaponDamageModifier: weaponDamageModifier,
        weaponStats: weaponStats,
        notProficient: notProficient,
      );
    case _ItemSheetAction.use:
      onUseItem(item);
    case _ItemSheetAction.toggleEquipped:
      onToggleEquipped(item);
    case _ItemSheetAction.toggleAttuned:
      onToggleAttuned(item);
    case _ItemSheetAction.equipWeapon:
      final slot = await showWeaponSlotPickerSheet(
        context,
        equippedWeapons: equippedWeapons,
        currentItemId: item.id,
      );
      if (slot == null || !context.mounted) return;
      onEquipWeaponToSlot(item, slot);
    case _ItemSheetAction.editCustom:
      await onEditCustomItem?.call(item);
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

enum _ItemSheetAction {
  info,
  use,
  toggleEquipped,
  toggleAttuned,
  equipWeapon,
  editCustom,
  remove,
}

class _ItemActionSheetContent extends StatelessWidget {
  const _ItemActionSheetContent({
    required this.item,
    required this.attunedCount,
    this.notProficient = false,
    this.editMode,
  });

  final CharacterInventoryItem item;
  final int attunedCount;

  /// Action « Modifier » / « Enrichir » à afficher (`null` : aucune — objet du
  /// catalogue, vue en lecture seule).
  final CustomItemEditMode? editMode;

  /// Armure/bouclier non maîtrisé (P10/F16) : pastille dans l'en-tête et
  /// bannière informative au-dessus de « Équiper »/« Déséquiper ».
  final bool notProficient;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isWeapon = item.isWeapon;
    final equippable = !isWeapon && isEquippableItem(item);
    final usable = !item.isCustom && item.consumable;
    final attunable = item.requiresAttunement;
    final atAttunementCap =
        !item.isAttuned && attunedCount >= CharacterDetail.attunementCap;
    final subtitle = l10n.itemActionSheetSubtitle(
      InventoryCategoryRules.labelFor(item.customCategoryKey ?? item.category),
      item.quantity,
    );

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
            // `Wrap` : la pastille descend sous le nom plutôt que de l'écraser
            // (police très agrandie).
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  item.name,
                  style: AppTypography.body(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (notProficient) const NotProficientBadge(),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              semanticsLabel: notProficient
                  ? '$subtitle, '
                        '${l10n.characterInventoryItemCardNotProficientSemantics}'
                  : null,
              style: AppTypography.body(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE0D2AB)),
            SheetActionRow(
              icon: Icons.info_outline,
              label: l10n.itemActionSheetInfoLabel,
              onTap: () => Navigator.of(context).pop(_ItemSheetAction.info),
            ),
            if (usable)
              SheetActionRow(
                icon: Icons.check_circle_outline,
                label: l10n.itemActionSheetUseLabel,
                onTap: () => Navigator.of(context).pop(_ItemSheetAction.use),
              ),
            if (notProficient) ...[
              const SizedBox(height: AppSpacing.sm),
              InfoBanner(
                icon: Icons.warning_amber_rounded,
                message: ArmorProficiencyRules.isShield(item)
                    ? l10n.inventoryNotProficientShieldBanner
                    : l10n.inventoryNotProficientArmorBanner,
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            if (isWeapon) ...[
              SheetActionRow(
                icon: Icons.checkroom_outlined,
                label: item.equipped
                    ? l10n.itemActionSheetChangeSetLabel
                    : l10n.itemActionSheetEquipLabel,
                onTap: () =>
                    Navigator.of(context).pop(_ItemSheetAction.equipWeapon),
              ),
              if (item.equipped)
                SheetActionRow(
                  icon: Icons.remove_circle_outline,
                  label: l10n.itemActionSheetUnequipLabel,
                  onTap: () =>
                      Navigator.of(context)
                          .pop(_ItemSheetAction.toggleEquipped),
                ),
            ] else if (equippable)
              SheetActionRow(
                icon: Icons.checkroom_outlined,
                label: item.equipped
                    ? l10n.itemActionSheetUnequipLabel
                    : l10n.itemActionSheetEquipLabel,
                onTap: () =>
                    Navigator.of(context).pop(_ItemSheetAction.toggleEquipped),
              ),
            if (attunable)
              SheetActionRow(
                icon: item.isAttuned ? Icons.link_off : Icons.link,
                label: item.isAttuned
                    ? l10n.itemActionSheetStopAttuneLabel
                    : l10n.itemActionSheetAttuneLabel,
                enabled: !atAttunementCap,
                trailingText: atAttunementCap
                    ? l10n.itemActionSheetAttunementCapReachedLabel(
                        CharacterDetail.attunementCap,
                      )
                    : null,
                onTap: () =>
                    Navigator.of(context).pop(_ItemSheetAction.toggleAttuned),
              ),
            if (editMode != null)
              SheetActionRow(
                icon: Icons.edit,
                label: editMode == CustomItemEditMode.enrich
                    ? l10n.itemActionSheetEnrichLabel
                    : l10n.itemActionSheetEditLabel,
                onTap: () =>
                    Navigator.of(context).pop(_ItemSheetAction.editCustom),
              ),
            const SheetActionDivider(),
            SheetActionRow(
              icon: Icons.delete_outline,
              label: l10n.itemActionSheetRemoveLabel,
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
                l10n.itemActionSheetRemoveConfirmationTitle(itemName),
                style: AppTypography.body(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.itemActionSheetRemoveConfirmationBody,
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
                      label: l10n.itemActionSheetRemoveConfirmationCancelButton,
                      surface: SecondaryButtonSurface.parchment,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: DestructiveButton(
                      label:
                          l10n.itemActionSheetRemoveConfirmationConfirmButton,
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
