import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/stepper_counter.dart';
import '../../domain/character_detail.dart';

/// Carte combinant les bandeaux PV et XP de l'onglet "Personnage" — voir la
/// spec visuelle de la tâche qui a produit ce fichier.
class CharacterVitalsCard extends StatelessWidget {
  const CharacterVitalsCard({
    required this.detail,
    required this.onTapAdjustHp,
    required this.onQuickHeal,
    required this.onQuickDamage,
    super.key,
  });

  final CharacterDetail detail;

  /// Ouvre la feuille d'ajustement PV détaillée (bouton crayon).
  final VoidCallback onTapAdjustHp;

  /// `StepperCounter` "+" : soin rapide de 1 PV.
  final VoidCallback onQuickHeal;

  /// `StepperCounter` "-" : dégât rapide de 1 PV (PV temporaires absorbés en
  /// premier, même règle que la feuille d'ajustement détaillée).
  final VoidCallback onQuickDamage;

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
          _HpSection(
            detail: detail,
            onTapAdjustHp: onTapAdjustHp,
            onQuickHeal: onQuickHeal,
            onQuickDamage: onQuickDamage,
          ),
          const SizedBox(height: AppSpacing.sm),
          _XpSection(detail: detail),
        ],
      ),
    );
  }
}

class _HpSection extends StatelessWidget {
  const _HpSection({
    required this.detail,
    required this.onTapAdjustHp,
    required this.onQuickHeal,
    required this.onQuickDamage,
  });

  final CharacterDetail detail;
  final VoidCallback onTapAdjustHp;
  final VoidCallback onQuickHeal;
  final VoidCallback onQuickDamage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'POINTS DE VIE',
              style: AppTypography.display(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              '${detail.currentHp} / ${detail.maxHp}',
              style: AppTypography.body(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: onTapAdjustHp,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        _HpGauge(ratio: detail.hpRatio),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            if (detail.temporaryHp > 0)
              _TemporaryHpChip(amount: detail.temporaryHp),
            const Spacer(),
            StepperCounter(
              value: detail.currentHp,
              onIncrement: detail.currentHp < detail.maxHp ? onQuickHeal : null,
              // Un personnage à `current_hp = 0` peut encore avoir des PV
              // temporaires (`HpAdjustmentCalculator.applyDamage` les
              // absorbe en premier) : le "-" doit rester actif tant qu'il
              // reste des PV *ou* des PV temporaires à réduire, pas
              // seulement les premiers.
              onDecrement: detail.currentHp > 0 || detail.temporaryHp > 0
                  ? onQuickDamage
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}

/// Jauge PV 12px, dégradé selon le seuil de [ratio] (PV temporaires exclus,
/// voir `CharacterDetail.hpRatio`) : vert au-dessus de 50 %, orange entre 25
/// et 50 % (bornes incluses), rouge en-dessous de 25 %.
class _HpGauge extends StatelessWidget {
  const _HpGauge({required this.ratio});

  final double ratio;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        height: 12,
        decoration: BoxDecoration(
          color: AppColors.gaugeTrack,
          border: Border.all(color: AppColors.gaugeTrackBorder),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: ratio,
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: _gradientFor(ratio)),
          ),
        ),
      ),
    );
  }

  LinearGradient _gradientFor(double ratio) {
    if (ratio > 0.5) {
      return const LinearGradient(
        colors: [AppColors.hpHealthyStart, AppColors.hpHealthyEnd],
      );
    }
    if (ratio >= 0.25) {
      return const LinearGradient(
        colors: [AppColors.hpCautionStart, AppColors.hpCautionEnd],
      );
    }
    return const LinearGradient(
      colors: [AppColors.hpCriticalStart, AppColors.hpCriticalEnd],
    );
  }
}

class _TemporaryHpChip extends StatelessWidget {
  const _TemporaryHpChip({required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.parchmentCardAlt,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.accentTeal, width: 1),
      ),
      child: Text(
        '+$amount PV temp.',
        style: AppTypography.body(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.accentTeal,
        ),
      ),
    );
  }
}

class _XpSection extends StatelessWidget {
  const _XpSection({required this.detail});

  final CharacterDetail detail;

  @override
  Widget build(BuildContext context) {
    // Au niveau maximum (`nextLevelXpThreshold` nul), il n'y a plus de
    // "prochain seuil" vers lequel afficher une progression : le seuil
    // affiché retombe alors sur l'XP actuelle elle-même (jauge pleine,
    // valeur affichée "{xp} / {xp}") plutôt qu'un cas non couvert par la
    // spec visuelle.
    final threshold = detail.nextLevelXpThreshold ?? detail.xp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'EXPÉRIENCE',
              style: AppTypography.display(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              '${detail.xp} / $threshold',
              style: AppTypography.body(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.gaugeTrack,
              border: Border.all(color: AppColors.gaugeTrackBorder),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: detail.xpProgress,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryButtonGradient,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
