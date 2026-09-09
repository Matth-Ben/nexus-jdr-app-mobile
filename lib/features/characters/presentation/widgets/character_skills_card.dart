import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/signed_modifier_formatter.dart';
import '../../domain/skill_bonus_calculator.dart';
import 'dice_roll_sheet.dart';

/// "For"/"Dex"/"Con"/"Int"/"Sag"/"Cha" — dupliqué depuis
/// `character_saving_throws_card.dart` (`_abilityAbbreviations`, privée, non
/// réutilisable telle quelle), même rationale de duplication que partout
/// ailleurs dans ce dépôt.
const Map<String, String> _abilityAbbreviations = {
  'str': 'For',
  'dex': 'Dex',
  'con': 'Con',
  'int': 'Int',
  'wis': 'Sag',
  'cha': 'Cha',
};

/// Carte "LES 18 COMPÉTENCES" de l'onglet "Compétences" : une ligne par
/// compétence (point de maîtrise, nom, abréviation de caractéristique,
/// bonus final), avec une légende "● maîtrisée" en tête de carte.
///
/// Chaque ligne est tappable : ouvre `showDiceRollSheet` (mini lancer de dé
/// virtuel, `docs/cahier-des-charges/11-fonctionnalites-a-ajouter.md`,
/// section "Onglet Compétences") avec le bonus déjà calculé de cette
/// compétence — jamais désactivé par un `actionsDisabled` (contrairement aux
/// autres cartes de cet onglet) : un lancer de dé n'écrit jamais en base,
/// donc reste utilisable même dans la vue en lecture seule d'un personnage
/// partagé (`SharedCharacterViewScreen`).
class CharacterSkillsCard extends StatelessWidget {
  const CharacterSkillsCard({required this.results, super.key});

  /// Déjà calculés par l'appelant via `SkillBonusCalculator.computeAll` —
  /// widget purement présentationnel, même convention que
  /// `CharacterSavingThrowsCard`.
  final List<SkillBonusResult> results;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LES 18 COMPÉTENCES',
                style: AppTypography.display(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const _MasteredLegend(),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final result in results) _SkillRow(result: result),
        ],
      ),
    );
  }
}

class _MasteredLegend extends StatelessWidget {
  const _MasteredLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _SkillDot(filled: true),
        const SizedBox(width: AppSpacing.xs),
        Text(
          'maîtrisée',
          style: AppTypography.body(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({required this.result});

  final SkillBonusResult result;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: () => showDiceRollSheet(
          context,
          label: result.name,
          modifier: result.bonus,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xs / 2,
            horizontal: AppSpacing.xs / 2,
          ),
          child: Row(
            children: [
              _SkillDot(filled: result.isMastered),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  result.name,
                  style: AppTypography.body(fontSize: 14),
                ),
              ),
              Text(
                _abilityAbbreviations[result.abilityId] ?? result.abilityId,
                style: AppTypography.body(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 28,
                child: Text(
                  SignedModifierFormatter.format(result.bonus),
                  textAlign: TextAlign.right,
                  style: AppTypography.body(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: result.bonus < 0
                        ? AppColors.accentBrick
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(
                Icons.casino_outlined,
                size: 16,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillDot extends StatelessWidget {
  const _SkillDot({required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? AppColors.goldEnd : Colors.transparent,
        border: filled
            ? null
            : Border.all(color: AppColors.woodLight, width: 1.5),
      ),
    );
  }
}
