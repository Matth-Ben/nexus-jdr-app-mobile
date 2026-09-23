import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/sheet_action_row.dart';
import '../../../../core/widgets/sheet_header_bar.dart';
import '../../../character_creation/domain/gold_amount_formatter.dart';
import '../../domain/character_detail.dart';
import '../../domain/character_inventory_item.dart';
import '../../domain/inventory_armor_dex_bonus_formatter.dart';
import '../../domain/inventory_rarity_formatter.dart';
import '../../domain/signed_modifier_formatter.dart';
import '../../domain/weapon_slot.dart';
import '../../domain/weight_formatter.dart';
import 'item_action_sheet.dart';

/// Ouvre le panneau "Infos" d'un objet de l'onglet "Inventaire" — gabarit B
/// ([SheetHeaderBar], contenu scrollable, pied fixe) : détail technique
/// (poids unitaire, coût, dégâts/propriétés/portée pour une arme, CA de
/// base/bonus Dex/force requise/désavantage discrétion pour une armure ou un
/// bouclier, rareté si renseignée) puis description, avec au plus un
/// bouton contextuel en pied ("Utiliser" ou "Équiper"/"Déséquiper", voir
/// [_ItemInfoPanelContent.build]) qui délègue directement à
/// [onUseItem]/[onToggleEquipped] (mêmes états/logique que la sheet
/// d'actions, pour éviter l'aller-retour) — [readOnly] retire aussi ce
/// bouton (ainsi que le lien d'harmonisation `_ToggleAttunedLink`), voir sa
/// documentation. Une arme (`category == 'arme'`) n'affiche jamais ce bouton
/// même hors [readOnly] : choisir un set ne peut pas se représenter par un
/// simple bouton bascule, ce pied ne représentant jamais plus d'un bouton
/// (invariant volontaire) — le joueur passe par la sheet d'actions
/// (`item_action_sheet.dart`) pour équiper une arme. Une arme équipée
/// affiche en revanche une ligne d'info en lecture seule "Set" (voir
/// [_ItemInfoRow]) quand son set est connu.
///
/// [onToggleAttuned]/[attunedCount] : voir `item_action_sheet.dart` pour le
/// même mécanisme de bascule/plafond, dupliqué ici pour le lien
/// `_ToggleAttunedLink` affiché quand [CharacterInventoryItem
/// .requiresAttunement] est vrai — même principe que
/// `spell_info_panel.dart::onTogglePrepared` (le tap ferme directement le
/// panneau plutôt que de le garder synchronisé avec l'état réseau en cours).
///
/// [readOnly] (`false` par défaut) retire en plus tout élément d'action de ce
/// panneau — ni `_ToggleAttunedLink`, ni le bouton contextuel de pied — pour
/// un affichage purement informatif (ex. `character_equipped_weapons_card
/// .dart`, tap sur une arme équipée depuis l'onglet "Personnage" : aucune
/// action d'écriture n'y est jamais proposée, seul l'onglet "Inventaire" en
/// permet).
///
/// [weaponAttackBonus]/[weaponDamageModifier] : bonus d'attaque et
/// modificateur de dégâts déjà calculés par l'appelant (voir
/// `domain/weapon_attack_calculator.dart::WeaponAttackCalculator`), affichés
/// pour une arme (`item.weaponProperties != null`) — `null` n'affiche pas la
/// ligne "Attaque" et n'ajoute aucun modificateur à la ligne "Dégâts".
Future<void> showItemInfoPanel(
  BuildContext context, {
  required CharacterInventoryItem item,
  required UseInventoryItemCallback onUseItem,
  required ToggleInventoryItemEquippedCallback onToggleEquipped,
  required ToggleInventoryItemAttunedCallback onToggleAttuned,
  required int attunedCount,
  bool readOnly = false,
  int? weaponAttackBonus,
  int? weaponDamageModifier,
}) async {
  final action = await showModalBottomSheet<_ItemInfoPanelAction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _ItemInfoPanelContent(
      item: item,
      attunedCount: attunedCount,
      readOnly: readOnly,
      weaponAttackBonus: weaponAttackBonus,
      weaponDamageModifier: weaponDamageModifier,
      onToggleAttuned: () {
        onToggleAttuned(item);
        Navigator.of(sheetContext).pop();
      },
    ),
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
  const _ItemInfoPanelContent({
    required this.item,
    required this.attunedCount,
    required this.onToggleAttuned,
    this.readOnly = false,
    this.weaponAttackBonus,
    this.weaponDamageModifier,
  });

  final CharacterInventoryItem item;
  final int attunedCount;
  final VoidCallback onToggleAttuned;
  final bool readOnly;
  final int? weaponAttackBonus;
  final int? weaponDamageModifier;

  @override
  Widget build(BuildContext context) {
    // Une arme n'affiche jamais le bouton "Équiper"/"Déséquiper" de ce pied
    // (armure/bouclier gardent le leur inchangé) : équiper une arme requiert
    // de choisir un set ("set principal"/"set secondaire", voir
    // `weapon_slot_picker_sheet.dart`), ce que ce pied (au plus un bouton
    // contextuel, voir la documentation de classe) ne peut pas représenter —
    // le joueur passe par la sheet d'actions d'objet pour équiper une arme.
    final equippable =
        !readOnly &&
        !item.isCustom &&
        item.category != 'arme' &&
        equippableInventoryCategories.contains(item.category);
    final usable = !readOnly && !item.isCustom && item.consumable;
    final attunable = !readOnly && !item.isCustom && item.requiresAttunement;
    final atAttunementCap =
        !item.isAttuned && attunedCount >= CharacterDetail.attunementCap;
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
      if (item.category == 'arme' && item.equipped && item.weaponSlot != null)
        _ItemInfoRow(label: 'Set', value: item.weaponSlot!.label),
      if (weapon != null) ...[
        if (weaponAttackBonus != null)
          _ItemInfoRow(
            label: 'Attaque',
            value: SignedModifierFormatter.format(weaponAttackBonus!),
          ),
        if (weapon.damageDice != null && weapon.damageType != null)
          _ItemInfoRow(
            label: 'Dégâts',
            value:
                '${weapon.damageDice}'
                '${weaponDamageModifier == null || weaponDamageModifier == 0 ? '' : SignedModifierFormatter.format(weaponDamageModifier!)} '
                '${weapon.damageType}',
          ),
        if (weapon.properties.isNotEmpty)
          _ItemInfoRow(
            label: 'Propriétés',
            value: weapon.properties.join(', '),
          ),
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
          _ItemInfoRow(label: 'Force requise', value: '$strengthRequirement'),
        _ItemInfoRow(
          label: 'Désavantage discrétion',
          value: armor.stealthDisadvantage ? 'Oui' : 'Non',
        ),
      ],
      if (rarity != null)
        // Texte en `textPrimary`, jamais doré — voir la spec de la tâche
        // (contrainte de contraste déjà documentée ailleurs dans ce dépôt,
        // ex. `character_inventory_stat_boxes_row.dart`).
        _ItemInfoRow(
          label: 'Rareté',
          value: InventoryRarityFormatter.format(rarity),
        ),
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
                      if (attunable) ...[
                        _ToggleAttunedLink(
                          attuned: item.isAttuned,
                          disabled: atAttunementCap,
                          onTap: onToggleAttuned,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      if (infoRows.isNotEmpty)
                        for (var i = 0; i < infoRows.length; i++) ...[
                          infoRows[i],
                          if (i < infoRows.length - 1)
                            const SheetActionDivider(),
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
                    onPressed: () =>
                        Navigator.of(context)
                            .pop(_ItemInfoPanelAction.toggleEquipped),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lien "Harmoniser cet objet"/"Ne plus harmoniser" — calque de
/// `spell_info_panel.dart::_TogglePreparedLink` (`body` 700/13, zone de tap
/// 44px min-height), icône dépendante de l'état : `Icons.link` pour
/// harmoniser, `Icons.link_off` pour retirer l'harmonisation. [disabled]
/// (plafond de `CharacterDetail.attunementCap` atteint, objet pas encore
/// harmonisé) grise le lien et ajoute une légende — même situation que
/// `item_action_sheet.dart`, sans l'infrastructure `SheetActionRow`
/// (`trailingText`) qui n'a pas d'équivalent direct ici, ce petit bloc reste
/// donc un widget dédié plutôt que réutilisé tel quel.
class _ToggleAttunedLink extends StatelessWidget {
  const _ToggleAttunedLink({
    required this.attuned,
    required this.disabled,
    required this.onTap,
  });

  final bool attuned;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = disabled ? AppColors.textMuted : AppColors.textSecondary;
    return InkWell(
      onTap: disabled ? null : onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  attuned ? Icons.link_off : Icons.link,
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: 4),
                Text(
                  attuned ? 'Ne plus harmoniser' : 'Harmoniser cet objet',
                  style: AppTypography.body(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
            if (disabled)
              Text(
                'Limite de ${CharacterDetail.attunementCap} objets '
                'harmonisés atteinte.',
                style: AppTypography.body(fontSize: 11, color: color),
              ),
          ],
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
