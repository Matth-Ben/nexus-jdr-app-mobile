import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// Rangée "VITESSE / CLASSE D'ARMURE / INSPIRATION" en tête de l'onglet
/// "Personnage", juste sous la carte d'identité — voir
/// `docs/cahier-des-charges/11-fonctionnalites-a-ajouter.md` section "Onglet
/// Personnage" et la maquette "Fiche — Personnage"
/// (`09-maquettes-captures.md`). Composant "Tuile de statistique" du design
/// système (section 4), 3 tuiles de largeur égale plutôt que défilables
/// (contrairement à `CharacterInventoryStatBoxesRow`, qui peut compter
/// jusqu'à 6 entrées) : toujours exactement 3 ici.
///
/// Réutilisée telle quelle par `SharedCharacterViewScreen` (vue en lecture
/// seule) avec [onTapInspiration] à `null` — voir sa documentation de
/// classe.
class CharacterStatPillsRow extends StatelessWidget {
  const CharacterStatPillsRow({
    required this.speed,
    required this.armorClass,
    required this.inspiration,
    this.onTapInspiration,
    super.key,
  });

  /// Vitesse de déplacement en mètres (`CharacterDetail.speed`), `null` si
  /// la race n'a pas pu être résolue — affiche un tiret plutôt qu'une
  /// fausse valeur.
  final int? speed;

  /// `CharacterDetail.armorClass`, déjà calculé par l'appelant.
  final int armorClass;

  /// `CharacterDetail.inspiration`.
  final bool inspiration;

  /// Bascule le jeton d'Inspiration au tap sur cette tuile — `null` désactive
  /// le tap (vue en lecture seule) sans changer son rendu.
  final VoidCallback? onTapInspiration;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatPill(
            label: 'VITESSE',
            value: speed != null ? '$speed m' : '—',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatPill(label: "CLASSE D'ARMURE", value: '$armorClass'),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatPill(
            label: 'INSPIRATION',
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
    this.emphasized = false,
    this.onTap,
  });

  final String label;
  final String value;

  /// Bordure dorée d'emphase (voir "INSPIRATION" active sur la maquette) —
  /// `false` pour Vitesse/Classe d'Armure, toujours statiques.
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
          Text(
            value,
            style: AppTypography.body(fontSize: 18, fontWeight: FontWeight.w800),
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
