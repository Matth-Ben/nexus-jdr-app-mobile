import 'package:flutter/material.dart';

import '../../../../core/widgets/display_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/character_detail.dart';
import '../../domain/weight_formatter.dart';

/// Jauge "CHARGE" de l'onglet "Inventaire" — poids total porté (
/// [CharacterDetail.inventoryWeight]) rapporté à la capacité de transport
/// dérivée de la Force ([CharacterDetail.carryingCapacity]), avec une
/// alerte de surcharge quand le poids la dépasse
/// ([CharacterDetail.isOverloaded]) — voir
/// `docs/cahier-des-charges/11-fonctionnalites-a-ajouter.md`, section
/// "Onglet Inventaire" : "Capacité de transport / limite de poids selon la
/// Force, avec alerte en cas de surcharge".
///
/// Toujours affichée (même inventaire vide, capacité de transport quand
/// même dérivée de la Force) — même principe que
/// `CharacterInventoryStatBoxesRow`. Même recette de jauge que la jauge PV
/// de `character_vitals_card.dart::_HpGauge` (piste `gaugeTrack`/
/// `gaugeTrackBorder`, dégradé par seuil), mais avec un sens inversé (un
/// ratio *élevé* est ici le cas défavorable) : jamais > 80% = sain, 80-100%
/// = prudence, > 100% = surcharge.
class CharacterInventoryCapacityGauge extends StatelessWidget {
  const CharacterInventoryCapacityGauge({required this.detail, super.key});

  final CharacterDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final weight = detail.inventoryWeight;
    final capacity = detail.carryingCapacity;
    // `capacity` est toujours > 0 en pratique (score de Force minimal de 1,
    // jamais 0 côté création de personnage), mais gardé défensif plutôt que
    // de diviser par 0 sur une donnée de test/incohérente.
    final ratio = capacity <= 0 ? 0.0 : weight / capacity;
    final overloaded = detail.isOverloaded;
    final formattedWeight = WeightFormatter.format(weight);
    final formattedCapacity = WeightFormatter.format(capacity);

    return Semantics(
      label: overloaded
          ? l10n.characterInventoryCapacityGaugeSemanticsLabelOverloaded(
              formattedWeight,
              formattedCapacity,
            )
          : l10n.characterInventoryCapacityGaugeSemanticsLabel(
              formattedWeight,
              formattedCapacity,
            ),
      container: true,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // `Wrap` : à grande taille de police, le poids passe sous le titre au
          // lieu de l'écraser (« CHARGE » coupé en plein mot).
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            children: [
              DisplayText(
                l10n.characterInventoryCapacityGaugeTitle,
                style: AppTypography.display(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                l10n.characterInventoryCapacityGaugeValueLabel(
                  formattedWeight,
                  formattedCapacity,
                ),
                style: AppTypography.body(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: overloaded
                      ? AppColors.hpCriticalStart
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs / 2),
          _CapacityGaugeBar(ratio: ratio),
          if (overloaded) ...[
            const SizedBox(height: AppSpacing.xs / 2),
            Text(
              l10n.characterInventoryCapacityGaugeOverloadedWarning,
              style: AppTypography.body(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.hpCriticalStart,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CapacityGaugeBar extends StatelessWidget {
  const _CapacityGaugeBar({required this.ratio});

  /// Peut dépasser 1 (surcharge) — le remplissage visuel est plafonné à
  /// 100% ([widthFactor]), seule la couleur continue de refléter
  /// l'ampleur du dépassement au-delà.
  final double ratio;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.gaugeTrack,
          border: Border.all(color: AppColors.gaugeTrackBorder),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: ratio.clamp(0, 1),
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: _gradientFor(ratio)),
          ),
        ),
      ),
    );
  }

  LinearGradient _gradientFor(double ratio) {
    if (ratio > 1) {
      return const LinearGradient(
        colors: [AppColors.hpCriticalStart, AppColors.hpCriticalEnd],
      );
    }
    if (ratio >= 0.8) {
      return const LinearGradient(
        colors: [AppColors.hpCautionStart, AppColors.hpCautionEnd],
      );
    }
    return const LinearGradient(
      colors: [AppColors.hpHealthyStart, AppColors.hpHealthyEnd],
    );
  }
}
