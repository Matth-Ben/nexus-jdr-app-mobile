import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/accent_icon_badge.dart';
import '../../../../core/widgets/sheet_action_row.dart';
import '../../domain/character_inventory_item.dart';
import '../../domain/inventory_category_rules.dart';
import '../../domain/signed_modifier_formatter.dart';
import '../../domain/weapon_attack_calculator.dart';
import '../../domain/weapon_slot.dart';
import '../../domain/weight_formatter.dart';
import 'item_info_panel.dart';

/// Carte « ARMES ÉQUIPÉES » de l'onglet « Personnage » — même gabarit que
/// `CharacterPactWeaponCard`/les autres cartes de ce dossier.
///
/// L'appelant filtre en amont [weapons] depuis `CharacterDetail.inventory`
/// (`item.category == 'arme' && item.equipped`) : cette carte se contente
/// d'afficher la liste déjà résolue, sans logique d'écriture (équiper/
/// déséquiper/harmoniser reste une action de l'onglet "Inventaire"
/// uniquement).
///
/// Affichage simplifié par arme : nom, bonus d'attaque (`+n`, voir
/// [WeaponAttackCalculator.attackBonus]) et dégâts avec le modificateur de
/// caractéristique déjà intégré (ex. "1d8+3 tranchant", voir
/// [WeaponAttackCalculator.abilityModifierFor]) — propriétés et portée ne
/// sont plus affichées ici (retirées de cette ligne compacte, spec de la
/// tâche), seulement dans le panneau "Infos" ouvert au tap (voir
/// [showItemInfoPanel], `readOnly: true` : aucune action possible depuis
/// cette carte, seulement la consultation du détail complet).
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
/// "Compétences" couvre déjà les maîtrises générales. [weaponProficiencyNames]
/// (voir `CharacterDetail.weaponProficiencyNames`) sert uniquement au calcul
/// interne du bonus d'attaque, jamais affiché tel quel ici.
class CharacterEquippedWeaponsCard extends StatelessWidget {
  const CharacterEquippedWeaponsCard({
    required this.weapons,
    required this.abilityScores,
    required this.proficiencyBonus,
    required this.weaponProficiencyNames,
    super.key,
  });

  final List<CharacterInventoryItem> weapons;

  /// Voir `CharacterDetail.abilityScores` — utilisé par
  /// [WeaponAttackCalculator] pour dériver le modificateur de caractéristique
  /// de chaque arme.
  final Map<String, int> abilityScores;

  /// Bonus de maîtrise du personnage (`ProficiencyBonusRules.forTotalLevel`,
  /// calculé une seule fois par l'appelant) — appliqué au bonus d'attaque
  /// d'une arme maîtrisée.
  final int proficiencyBonus;

  /// Voir `CharacterDetail.weaponProficiencyNames`.
  final List<String> weaponProficiencyNames;

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
              abilityScores: abilityScores,
              proficiencyBonus: proficiencyBonus,
              weaponProficiencyNames: weaponProficiencyNames,
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
              abilityScores: abilityScores,
              proficiencyBonus: proficiencyBonus,
              weaponProficiencyNames: weaponProficiencyNames,
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
  const _WeaponSlotSection({
    required this.title,
    required this.weapons,
    required this.abilityScores,
    required this.proficiencyBonus,
    required this.weaponProficiencyNames,
  });

  final String title;
  final List<CharacterInventoryItem> weapons;
  final Map<String, int> abilityScores;
  final int proficiencyBonus;
  final List<String> weaponProficiencyNames;

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
            _Weapon(
              weapons[i],
              abilityScores: abilityScores,
              proficiencyBonus: proficiencyBonus,
              weaponProficiencyNames: weaponProficiencyNames,
            ),
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
  const _Weapon(
    this.item, {
    required this.abilityScores,
    required this.proficiencyBonus,
    required this.weaponProficiencyNames,
  });

  final CharacterInventoryItem item;
  final Map<String, int> abilityScores;
  final int proficiencyBonus;
  final List<String> weaponProficiencyNames;

  @override
  Widget build(BuildContext context) {
    final weapon = item.weaponProperties;
    final damageDice = weapon?.damageDice;
    final damageType = weapon?.damageType;
    final properties = weapon?.properties ?? const <String>[];
    final rangeNormal = weapon?.rangeNormal;
    final rangeMax = weapon?.rangeMax;
    final range = rangeNormal != null
        ? rangeMax != null
              ? '${WeightFormatter.format(rangeNormal)} m '
                    '(max ${WeightFormatter.format(rangeMax)} m)'
              : '${WeightFormatter.format(rangeNormal)} m'
        : null;

    final attackBonus = damageDice != null
        ? WeaponAttackCalculator.attackBonus(
            weaponName: item.name,
            weaponProperties: properties,
            abilityScores: abilityScores,
            proficiencyTokens: weaponProficiencyNames,
            proficiencyBonus: proficiencyBonus,
          )
        : null;
    final damageModifier = damageDice != null
        ? WeaponAttackCalculator.abilityModifierFor(
            weaponProperties: properties,
            abilityScores: abilityScores,
          )
        : null;
    final damage = damageDice != null && damageType != null
        ? '$damageDice'
              '${damageModifier == null || damageModifier == 0 ? '' : SignedModifierFormatter.format(damageModifier)} '
              '$damageType'
        : null;

    final semanticsLabel = StringBuffer('Arme équipée : ${item.name}');
    if (attackBonus != null) {
      semanticsLabel.write(
        ', Attaque : ${SignedModifierFormatter.format(attackBonus)}',
      );
    }
    if (damage != null) semanticsLabel.write(', $damage');
    if (properties.isNotEmpty) {
      semanticsLabel.write(', ${properties.join(', ')}');
    }
    if (range != null) semanticsLabel.write(', Portée : $range');

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: semanticsLabel.toString(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => showItemInfoPanel(
            context,
            item: item,
            onUseItem: (_) {},
            onToggleEquipped: (_) {},
            onToggleAttuned: (_) {},
            attunedCount: 0,
            readOnly: true,
            weaponAttackBonus: attackBonus,
            weaponDamageModifier: damageModifier,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
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
                      if (attackBonus != null)
                        Text(
                          'Attaque : '
                          '${SignedModifierFormatter.format(attackBonus)}',
                          style: AppTypography.body(
                            fontSize: 12,
                            color: AppColors.textSecondary,
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
