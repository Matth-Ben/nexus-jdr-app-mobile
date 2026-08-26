import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/saving_throw_calculator.dart';
import '../../domain/signed_modifier_formatter.dart';

/// "For"/"Dex"/"Con"/"Int"/"Sag"/"Cha" — dupliqué depuis
/// `character_creation/domain/race_summary_formatter.dart`
/// (`_abilityAbbreviations`, privée, non réutilisable telle quelle), même
/// rationale de duplication que `summary_step_screen.dart`.
const Map<String, String> _abilityAbbreviations = {
  'str': 'For',
  'dex': 'Dex',
  'con': 'Con',
  'int': 'Int',
  'wis': 'Sag',
  'cha': 'Cha',
};

/// Carte "Jets de sauvegarde" de l'onglet "Personnage" : les 6
/// caractéristiques (pas 4, voir la spec de la tâche qui a produit ce
/// fichier), dans l'ordre canonique For/Dex/Con/Int/Sag/Cha.
class CharacterSavingThrowsCard extends StatelessWidget {
  const CharacterSavingThrowsCard({required this.results, super.key});

  /// Déjà calculés par l'appelant via `SavingThrowCalculator.computeAll` —
  /// widget purement présentationnel.
  final List<SavingThrowResult> results;

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
            'JETS DE SAUVEGARDE',
            style: AppTypography.display(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              for (final result in results) _SavingThrowItem(result: result),
            ],
          ),
        ],
      ),
    );
  }
}

class _SavingThrowItem extends StatelessWidget {
  const _SavingThrowItem({required this.result});

  final SavingThrowResult result;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ProficiencyDot(isProficient: result.isProficient),
        const SizedBox(width: AppSpacing.xs),
        Text(
          _abilityAbbreviations[result.abilityKey] ?? result.abilityKey,
          style: AppTypography.body(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: AppSpacing.xs / 2),
        Text(
          SignedModifierFormatter.format(result.bonus),
          style: AppTypography.body(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: result.bonus < 0
                ? AppColors.accentBrick
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ProficiencyDot extends StatelessWidget {
  const _ProficiencyDot({required this.isProficient});

  final bool isProficient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isProficient ? AppColors.goldEnd : Colors.transparent,
        border: isProficient
            ? null
            : Border.all(color: AppColors.woodLight, width: 1.5),
      ),
    );
  }
}
