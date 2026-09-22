import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/accent_icon_badge.dart';
import '../../../../core/widgets/sheet_action_row.dart';
import '../../domain/character_inventory_item.dart';
import '../../domain/inventory_category_rules.dart';
import '../../domain/weapon_slot.dart';
import '../../domain/weight_formatter.dart';

/// Carte « ARMES ÉQUIPÉES » de l'onglet « Personnage » — même gabarit que
/// `CharacterPactWeaponCard`/les autres cartes de ce dossier.
///
/// L'appelant filtre en amont [weapons] depuis `CharacterDetail.inventory`
/// (`item.category == 'arme' && item.equipped`) : cette carte se contente
/// d'afficher la liste déjà résolue, sans logique d'écriture (équiper/
/// déséquiper reste une action de l'onglet "Inventaire" uniquement).
///
/// Regroupée en deux sous-sections "SET PRINCIPAL"/"SET SECONDAIRE" (voir
/// `domain/weapon_slot.dart::WeaponSlot`) plutôt qu'une liste plate — un
/// [CharacterInventoryItem.weaponSlot] à `null` est traité comme principal
/// (ne devrait pas arriver après le backfill de la migration qui a
/// introduit `weapon_slot`, mais évite qu'une arme équipée disparaisse
/// silencieusement de la carte si jamais). Un groupe vide affiche un texte
/// discret ("Aucune arme dans ce set.") plutôt que d'être masqué, pour que
/// le joueur voie qu'il a de la place — sauf si aucune arme n'est équipée du
/// tout, auquel cas c'est l'état vide global ([_EmptyWeapons]) qui s'affiche
/// à la place des deux sous-sections.
///
/// Aucune puce "Maîtrisée"/"Arme magique" ici (contrairement à
/// `CharacterPactWeaponCard`) : aucune donnée de maîtrise par arme
/// disponible côté schéma — `CharacterWeaponProficienciesCard` de l'onglet
/// "Compétences" couvre déjà les maîtrises générales.
class CharacterEquippedWeaponsCard extends StatelessWidget {
  const CharacterEquippedWeaponsCard({required this.weapons, super.key});

  final List<CharacterInventoryItem> weapons;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ARMES ÉQUIPÉES',
            style: AppTypography.display(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (weapons.isEmpty)
            const _EmptyWeapons()
          else ...[
            _WeaponSlotSection(
              title: 'SET PRINCIPAL',
              weapons: [
                for (final weapon in weapons)
                  if (weapon.weaponSlot != WeaponSlot.secondary) weapon,
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const SheetActionDivider(),
            const SizedBox(height: AppSpacing.sm),
            _WeaponSlotSection(
              title: 'SET SECONDAIRE',
              weapons: [
                for (final weapon in weapons)
                  if (weapon.weaponSlot == WeaponSlot.secondary) weapon,
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Sous-section "SET PRINCIPAL"/"SET SECONDAIRE" — voir la documentation de
/// classe de [CharacterEquippedWeaponsCard].
class _WeaponSlotSection extends StatelessWidget {
  const _WeaponSlotSection({required this.title, required this.weapons});

  final String title;
  final List<CharacterInventoryItem> weapons;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.body(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (weapons.isEmpty)
          Text(
            'Aucune arme dans ce set.',
            style: AppTypography.body(fontSize: 12, color: AppColors.textMuted),
          )
        else
          for (var i = 0; i < weapons.length; i++) ...[
            _Weapon(weapons[i]),
            if (i < weapons.length - 1) ...[
              const SizedBox(height: AppSpacing.sm),
              const SheetActionDivider(),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
      ],
    );
  }
}

class _Weapon extends StatelessWidget {
  const _Weapon(this.item);

  final CharacterInventoryItem item;

  @override
  Widget build(BuildContext context) {
    final weapon = item.weaponProperties;
    final damageDice = weapon?.damageDice;
    final damageType = weapon?.damageType;
    final damage = damageDice != null && damageType != null
        ? '$damageDice $damageType'
        : null;
    final properties = weapon?.properties ?? const <String>[];
    final rangeNormal = weapon?.rangeNormal;
    final rangeMax = weapon?.rangeMax;
    final range = rangeNormal != null
        ? rangeMax != null
              ? '${WeightFormatter.format(rangeNormal)} m '
                    '(max ${WeightFormatter.format(rangeMax)} m)'
              : '${WeightFormatter.format(rangeNormal)} m'
        : null;

    final semanticsLabel = StringBuffer('Arme équipée : ${item.name}');
    if (damage != null) semanticsLabel.write(', $damage');
    if (range != null) semanticsLabel.write(', Portée : $range');

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: semanticsLabel.toString(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AccentIconBadge(
            icon: InventoryCategoryRules.iconFor('arme'),
            color: InventoryCategoryRules.colorFor('arme'),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (damage != null)
                  Text(
                    damage,
                    style: AppTypography.body(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                if (properties.isNotEmpty)
                  Text(
                    properties.join(', '),
                    style: AppTypography.body(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (range != null)
                  Text(
                    'Portée : $range',
                    style: AppTypography.body(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyWeapons extends StatelessWidget {
  const _EmptyWeapons();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aucune arme équipée',
          style: AppTypography.body(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          "Équipez une arme depuis l'onglet Inventaire pour qu'elle "
          'apparaisse ici.',
          style: AppTypography.body(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
