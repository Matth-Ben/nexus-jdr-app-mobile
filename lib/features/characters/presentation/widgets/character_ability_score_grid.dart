import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../character_creation/domain/ability_score_definitions.dart';
import '../../../character_creation/domain/ability_score_rules.dart';
import '../../domain/signed_modifier_formatter.dart';

/// Grille 3×2 des 6 caractéristiques (For/Dex/Con puis Int/Sag/Cha) de
/// l'onglet "Personnage" — réutilise tel quel le mapping icône/couleur de
/// `character_creation/domain/ability_score_definitions.dart` (déjà validé
/// par la direction artistique), score déjà final dans
/// `character_ability_scores` (aucun recalcul de bonus racial ici).
class CharacterAbilityScoreGrid extends StatelessWidget {
  const CharacterAbilityScoreGrid({required this.abilityScores, super.key});

  /// Clé 'str'/'dex'/'con'/'int'/'wis'/'cha' -> score final.
  final Map<String, int> abilityScores;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1.05,
      children: [
        for (final definition in abilityScoreDefinitions)
          _AbilityScoreCard(
            definition: definition,
            score: abilityScores[definition.key] ?? 10,
          ),
      ],
    );
  }
}

class _AbilityScoreCard extends StatelessWidget {
  const _AbilityScoreCard({required this.definition, required this.score});

  final AbilityScoreDefinition definition;
  final int score;

  @override
  Widget build(BuildContext context) {
    final modifier = AbilityScoreRules.abilityModifier(score);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.parchmentCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.woodLight, width: AppBorders.card),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(definition.icon, size: 22, color: definition.accentColor),
          const SizedBox(height: AppSpacing.xs),
          Text(
            definition.label.toUpperCase(),
            style: AppTypography.body(
              // Plancher d'accessibilité strict du design système (section
              // 7 : "taille de police minimale 11px, jamais en dessous") —
              // l'emporte sur la recommandation 9-10px de la section 4
              // ("Icône de caractéristique"), contradiction interne notée
              // pour la prochaine resynchronisation de
              // `docs/cahier-des-charges/10-design-system.md`.
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            '$score',
            style: AppTypography.body(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            SignedModifierFormatter.format(modifier),
            style: AppTypography.body(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: modifier < 0
                  ? AppColors.accentBrick
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
