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
    required this.onTapAddXp,
    required this.onTapLevelUp,
    required this.onTapRest,
    this.hpActionsDisabled = false,
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

  /// `true` pendant qu'un repos (`RestSheet`) — ou la réaffirmation PV
  /// différée qu'un repos peut déclencher, voir
  /// `_CharacterDetailScreenState._reassertCurrentHpState` — est en vol côté
  /// réseau. Désactive le stepper PV (+/-), le bouton crayon "Ajuster PV" ET
  /// le lien "Prendre un repos" lui-même (jamais masqués, juste avec un
  /// callback `null`, pour que la fiche reste lisible) le temps de cette
  /// fenêtre.
  ///
  /// Ferme la course résiduelle confirmée en revue de code : sans le verrou
  /// sur le stepper/crayon, un ajustement PV démarré *pendant* qu'un repos
  /// long écrit encore en base pourrait résoudre *avant* lui et se faire
  /// écraser silencieusement par l'écriture `current_hp = max_hp` du repos,
  /// arrivée après coup. Sans le verrou sur le lien "Prendre un repos"
  /// lui-même, un second repos pourrait de la même façon démarrer et
  /// résoudre pendant qu'une réaffirmation PV différée (déclenchée par
  /// [_restGeneration]/`_reassertCurrentHpState`, l'autre sens de la course :
  /// un ajustement PV démarré *avant* le repos et résolu après lui) est
  /// encore en vol, et se faire écraser à son tour — même bug, un niveau
  /// plus profond. Voir `_CharacterDetailScreenState._isApplyingRest`
  /// (`character_detail_screen.dart`) pour le détail des deux mécanismes.
  final bool hpActionsDisabled;

  /// `IconButton` "+" de fin de ligne d'en-tête XP : ouvre `AddXpSheet`.
  final VoidCallback onTapAddXp;

  /// Lien discret "Monter de niveau manuellement" (XP sous le seuil) ou
  /// bandeau "NIVEAU {n+1} DISPONIBLE" (seuil déjà franchi) : les deux
  /// ouvrent le même flux de montée de niveau, ciblant `totalLevel + 1` —
  /// voir `character_detail_screen.dart`.
  final VoidCallback onTapLevelUp;

  /// Lien texte "Prendre un repos", en fin de carte — ouvre `RestSheet`
  /// (voir `character_detail_screen.dart`).
  final VoidCallback onTapRest;

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
            actionsDisabled: hpActionsDisabled,
          ),
          const SizedBox(height: AppSpacing.sm),
          _XpSection(
            detail: detail,
            onTapAddXp: onTapAddXp,
            onTapLevelUp: onTapLevelUp,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1, thickness: 1, color: AppColors.gaugeTrack),
          const SizedBox(height: AppSpacing.sm),
          _RestLink(onTap: hpActionsDisabled ? null : onTapRest),
        ],
      ),
    );
  }
}

/// Lien texte pleine largeur, centré, "Prendre un repos" — ouvre `RestSheet`
/// (spec visuelle direction-artistique). Volontairement un lien de fin de
/// carte plutôt qu'un second bouton icône dans l'en-tête PV (risque de
/// mistap à côté du crayon existant, voir `_HpSection`).
class _RestLink extends StatelessWidget {
  const _RestLink({required this.onTap});

  /// `null` pendant qu'un repos (ou sa réaffirmation PV différée, voir
  /// `_CharacterDetailScreenState._isApplyingRest`) est déjà en vol — évite
  /// qu'un second repos parte avant que le premier n'ait fini d'écrire.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final color = disabled ? AppColors.textMuted : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_fire_department, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                'Prendre un repos',
                style: AppTypography.body(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
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
    required this.actionsDisabled,
  });

  final CharacterDetail detail;
  final VoidCallback onTapAdjustHp;
  final VoidCallback onQuickHeal;
  final VoidCallback onQuickDamage;

  /// Voir `CharacterVitalsCard.hpActionsDisabled`.
  final bool actionsDisabled;

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
                onPressed: actionsDisabled ? null : onTapAdjustHp,
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
              onIncrement: !actionsDisabled && detail.currentHp < detail.maxHp
                  ? onQuickHeal
                  : null,
              // Un personnage à `current_hp = 0` peut encore avoir des PV
              // temporaires (`HpAdjustmentCalculator.applyDamage` les
              // absorbe en premier) : le "-" doit rester actif tant qu'il
              // reste des PV *ou* des PV temporaires à réduire, pas
              // seulement les premiers.
              onDecrement:
                  !actionsDisabled &&
                      (detail.currentHp > 0 || detail.temporaryHp > 0)
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
  const _XpSection({
    required this.detail,
    required this.onTapAddXp,
    required this.onTapLevelUp,
  });

  final CharacterDetail detail;
  final VoidCallback onTapAddXp;
  final VoidCallback onTapLevelUp;

  @override
  Widget build(BuildContext context) {
    // Au niveau maximum (`nextLevelXpThreshold` nul), il n'y a plus de
    // "prochain seuil" vers lequel afficher une progression : le seuil
    // affiché retombe alors sur l'XP actuelle elle-même (jauge pleine,
    // valeur affichée "{xp} / {xp}") plutôt qu'un cas non couvert par la
    // spec visuelle.
    final threshold = detail.nextLevelXpThreshold ?? detail.xp;
    // Seuil déjà franchi (montée en attente) : `nextLevelXpThreshold` non
    // nul (donc pas déjà au niveau maximum) ET l'XP actuelle l'a atteint ou
    // dépassé.
    final thresholdReached =
        detail.nextLevelXpThreshold != null &&
        detail.xp >= detail.nextLevelXpThreshold!;

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
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: onTapAddXp,
                icon: const Icon(
                  Icons.add,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
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
        const SizedBox(height: AppSpacing.xs),
        if (thresholdReached)
          _LevelUpAvailableBanner(
            targetLevel: detail.totalLevel + 1,
            onTap: onTapLevelUp,
          )
        else
          _ManualLevelUpLink(onTap: onTapLevelUp),
      ],
    );
  }
}

/// Lien discret "Monter de niveau manuellement" (XP sous le seuil), toujours
/// visible sous la jauge XP — déclenchement manuel "hors XP" (spec visuelle
/// section 1a).
class _ManualLevelUpLink extends StatelessWidget {
  const _ManualLevelUpLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.arrow_upward,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                'Monter de niveau manuellement',
                style: AppTypography.body(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bandeau "NIVEAU {n} DISPONIBLE" (seuil franchi, montée en attente) —
/// remplace [_ManualLevelUpLink] tant que la montée n'a pas été effectuée
/// (spec visuelle section 1b).
class _LevelUpAvailableBanner extends StatelessWidget {
  const _LevelUpAvailableBanner({
    required this.targetLevel,
    required this.onTap,
  });

  final int targetLevel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.parchmentCardAlt,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.goldEnd,
              width: AppBorders.card,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.arrow_upward,
                size: 16,
                color: AppColors.accentBrick,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'NIVEAU $targetLevel DISPONIBLE',
                style: AppTypography.display(
                  fontSize: 11,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
