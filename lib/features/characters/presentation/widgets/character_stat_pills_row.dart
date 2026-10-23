import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/signed_modifier_formatter.dart';

/// Rangée "VIT. / CA / INIT. / INSP." en tête de l'onglet
/// "Personnage", juste sous la carte d'identité — voir
/// `docs/cahier-des-charges/11-fonctionnalites-a-ajouter.md` section "Onglet
/// Personnage" et la maquette "Fiche — Personnage"
/// (`09-maquettes-captures.md`). Composant "Tuile de statistique" du design
/// système (section 4), 4 tuiles de largeur égale plutôt que défilables
/// (contrairement à `CharacterInventoryStatBoxesRow`, qui peut compter
/// jusqu'à 6 entrées) : toujours exactement 4 ici. Libellés abrégés
/// (demande utilisateur du 2026-09-24) pour tenir à 4 par rangée.
///
/// Réutilisée telle quelle par `SharedCharacterViewScreen` (vue en lecture
/// seule) avec [onTapInspiration]/[onTapArmorClass] à `null` — voir leur
/// documentation respective.
class CharacterStatPillsRow extends StatelessWidget {
  const CharacterStatPillsRow({
    required this.speed,
    required this.armorClass,
    required this.armorClassBonus,
    required this.initiative,
    required this.inspiration,
    this.onTapInspiration,
    this.onTapInitiative,
    this.onTapArmorClass,
    super.key,
  });

  /// Vitesse de déplacement en mètres (`CharacterDetail.speed`), `null` si
  /// la race n'a pas pu être résolue — affiche un tiret plutôt qu'une
  /// fausse valeur.
  final int? speed;

  /// `CharacterDetail.armorClass`, déjà calculé par l'appelant (valeur RAW,
  /// sans [armorClassBonus]).
  final int armorClass;

  /// `CharacterDetail.armorClassBonus` — ajustement manuel persistant, voir
  /// sa documentation de classe. Additionné à [armorClass] pour la valeur
  /// affichée sur la tuile ; son signe est en plus affiché à part (suffixe
  /// `+N`/`−N`), uniquement si non nul — voir `_StatPill`.
  final int armorClassBonus;

  /// Bonus d'initiative (modificateur de Dextérité, D&D 5e), déjà calculé
  /// par l'appelant.
  final int initiative;

  /// Lance un jet d'initiative au tap — `null` désactive le tap.
  final VoidCallback? onTapInitiative;

  /// `CharacterDetail.inspiration`.
  final bool inspiration;

  /// Bascule le jeton d'Inspiration au tap sur cette tuile — `null` désactive
  /// le tap (vue en lecture seule) sans changer son rendu.
  final VoidCallback? onTapInspiration;

  /// Ouvre la feuille d'ajustement de CA (`armor_class_bonus_sheet.dart`) au
  /// tap sur la tuile "CA" — `null` désactive le tap (vue en lecture seule,
  /// `SharedCharacterViewScreen`) sans changer son rendu, même convention
  /// que [onTapInspiration]/[onTapInitiative].
  final VoidCallback? onTapArmorClass;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatPill(
            label: 'VIT.',
            value: speed != null ? '$speed m' : '—',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatPill(
            label: 'CA',
            value: '${armorClass + armorClassBonus}',
            valueSuffix: armorClassBonus != 0
                ? SignedModifierFormatter.format(armorClassBonus)
                : null,
            onTap: onTapArmorClass,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatPill(
            label: 'INIT.',
            value: SignedModifierFormatter.format(initiative),
            onTap: onTapInitiative,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatPill(
            label: 'INSP.',
            value: inspiration ? '✓' : '—',
            emphasized: inspiration,
            onTap: onTapInspiration,
          ),
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    this.valueSuffix,
    this.emphasized = false,
    this.onTap,
  });

  final String label;
  final String value;

  /// Suffixe signé affiché à côté de [value] (tuile "CA" avec
  /// `armorClassBonus != 0` uniquement) — `null` laisse le rendu
  /// strictement identique à avant l'introduction de l'ajustement manuel de
  /// CA (pas de changement visuel pour les autres tuiles, ni pour la CA
  /// quand le bonus est nul).
  final String? valueSuffix;

  /// Bordure dorée d'emphase (voir "INSPIRATION" active sur la maquette) —
  /// `false` pour Vitesse/CA/Initiative.
  final bool emphasized;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: emphasized ? AppColors.goldEnd : AppColors.woodLight,
          width: emphasized ? AppBorders.cardEmphasis : AppBorders.card,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTypography.body(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (valueSuffix != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  valueSuffix!,
                  style: AppTypography.body(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentTeal,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: content,
      ),
    );
  }
}
