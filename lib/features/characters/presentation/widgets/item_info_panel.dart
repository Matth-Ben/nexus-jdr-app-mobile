import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/sheet_action_row.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../../character_creation/domain/gold_amount_formatter.dart';
import '../../domain/character_inventory_item.dart';
import '../../domain/inventory_armor_dex_bonus_formatter.dart';
import '../../domain/inventory_rarity_formatter.dart';
import '../../domain/weight_formatter.dart';
import 'item_action_sheet.dart';

/// Ouvre le panneau "Infos" d'un objet de l'onglet "Inventaire" — gabarit B
/// ([SheetHeaderBar], contenu scrollable, pied fixe) : détail technique
/// (poids unitaire, coût, dégâts/propriétés/portée pour une arme, CA de
/// base/bonus Dex/force requise/désavantage discrétion pour une armure ou un
/// bouclier, rareté/attunement si renseignés) puis description, avec au plus
/// un bouton contextuel en pied ("Utiliser" ou "Équiper"/"Déséquiper", voir
/// [_ItemInfoPanelContent.build]) qui délègue directement à
/// [onUseItem]/[onToggleEquipped] (mêmes états/logique que la sheet
/// d'actions, pour éviter l'aller-retour).
Future<void> showItemInfoPanel(
  BuildContext context, {
  required CharacterInventoryItem item,
  required UseInventoryItemCallback onUseItem,
  required ToggleInventoryItemEquippedCallback onToggleEquipped,
}) async {
  final action = await showModalBottomSheet<_ItemInfoPanelAction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _ItemInfoPanelContent(item: item),
  );
  if (action == null || !context.mounted) return;

  switch (action) {
    case _ItemInfoPanelAction.use:
      onUseItem(item);
    case _ItemInfoPanelAction.toggleEquipped:
      onToggleEquipped(item);
  }
}

enum _ItemInfoPanelAction { use, toggleEquipped }

class _ItemInfoPanelContent extends StatelessWidget {
  const _ItemInfoPanelContent({required this.item});

  final CharacterInventoryItem item;

  @override
  Widget build(BuildContext context) {
    final equippable =
        !item.isCustom && equippableInventoryCategories.contains(item.category);
    final usable = !item.isCustom && item.consumable;
    final weapon = item.weaponProperties;
    final armor = item.armorProperties;
    final rarity = item.rarity;

    final infoRows = <Widget>[
      if (item.unitWeight case final unitWeight?)
        _ItemInfoRow(
          label: 'Poids unitaire',
          value: '${WeightFormatter.format(unitWeight)} kg',
        ),
      if (item.costAmount case final costAmount?)
        _ItemInfoRow(
          label: 'Coût',
          value: '${GoldAmountFormatter.format(costAmount)} po',
        ),
      if (weapon != null) ...[
        if (weapon.damageDice != null && weapon.damageType != null)
          _ItemInfoRow(
            label: 'Dégâts',
            value: '${weapon.damageDice} ${weapon.damageType}',
          ),
        if (weapon.properties.isNotEmpty)
          _ItemInfoRow(label: 'Propriétés', value: weapon.properties.join(', ')),
        if (weapon.rangeNormal case final rangeNormal?)
          _ItemInfoRow(
            label: 'Portée',
            value: weapon.rangeMax != null
                ? '${WeightFormatter.format(rangeNormal)} m '
                      '(max ${WeightFormatter.format(weapon.rangeMax!)} m)'
                : '${WeightFormatter.format(rangeNormal)} m',
          ),
      ],
      if (armor != null) ...[
        _ItemInfoRow(label: 'CA de base', value: '${armor.acBase}'),
        _ItemInfoRow(
          label: 'Bonus Dex',
          value: InventoryArmorDexBonusFormatter.format(armor.acDexBonus),
        ),
        if (armor.strengthRequirement case final strengthRequirement?)
          _ItemInfoRow(
            label: 'Force requise',
            value: '$strengthRequirement',
          ),
        _ItemInfoRow(
          label: 'Désavantage discrétion',
          value: armor.stealthDisadvantage ? 'Oui' : 'Non',
        ),
      ],
      if (rarity != null) ...[
        // Texte en `textPrimary`, jamais doré — voir la spec de la tâche
        // (contrainte de contraste déjà documentée ailleurs dans ce dépôt,
        // ex. `character_inventory_stat_boxes_row.dart`).
        _ItemInfoRow(label: 'Rareté', value: InventoryRarityFormatter.format(rarity)),
        _ItemInfoRow(
          label: 'Attunement requis',
          value: item.requiresAttunement ? 'Oui' : 'Non',
        ),
      ],
    ];

    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.88,
        child: Container(
          decoration: const BoxDecoration(color: AppColors.parchmentBg),
          child: Column(
            children: [
              SheetHeaderBar(title: item.name.toUpperCase()),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (infoRows.isNotEmpty)
                        for (var i = 0; i < infoRows.length; i++) ...[
                          infoRows[i],
                          if (i < infoRows.length - 1) const SheetActionDivider(),
                        ],
                      if (infoRows.isNotEmpty)
                        const SizedBox(height: AppSpacing.md),
                      Text(
                        'DESCRIPTION',
                        style: AppTypography.display(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        item.description?.isNotEmpty == true
                            ? item.description!
                            : 'Aucune description disponible.',
                        style: AppTypography.body(fontSize: 14, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
              if (usable)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: PrimaryButton(
                    label: 'Utiliser',
                    onPressed: () =>
                        Navigator.of(context).pop(_ItemInfoPanelAction.use),
                  ),
                )
              else if (equippable)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: PrimaryButton(
                    label: item.equipped ? 'Déséquiper' : 'Équiper',
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(_ItemInfoPanelAction.toggleEquipped),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ligne "libellé/valeur" — même gabarit que
/// `spell_info_panel.dart::_SpellInfoRow`, dupliqué ici (usage isolé dans ce
/// panneau, même rationale de duplication que le reste de ce dépôt).
class _ItemInfoRow extends StatelessWidget {
  const _ItemInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTypography.body(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.body(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
