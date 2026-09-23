import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../character_creation/domain/ability_score_definitions.dart';
import '../../../character_creation/domain/ability_score_rules.dart';
import '../../domain/signed_modifier_formatter.dart';
import 'dice_roll_sheet.dart';

/// Grille 3×2 des 6 caractéristiques (For/Dex/Con puis Int/Sag/Cha) de
/// l'onglet "Personnage" — réutilise tel quel le mapping icône/couleur de
/// `character_creation/domain/ability_score_definitions.dart` (déjà validé
/// par la direction artistique), score déjà final dans
/// `character_ability_scores` (aucun recalcul de bonus racial ici).
///
/// Chaque tuile est tappable : ouvre `showDiceRollSheet` (mini lancer de dé
/// virtuel, `docs/cahier-des-charges/11-fonctionnalites-a-ajouter.md`,
/// section "Onglet Compétences" — le jet de caractéristique brut y est cité
/// au même titre que le jet de compétence) avec le modificateur de
/// caractéristique seul, sans bonus de maîtrise (un jet de caractéristique
/// n'en a jamais). Jamais désactivé (voir la documentation de classe de
/// `CharacterSkillsCard` pour le même choix et son rationale).
class CharacterAbilityScoreGrid extends StatelessWidget {
  const CharacterAbilityScoreGrid({required this.abilityScores, super.key});

  /// Clé 'str'/'dex'/'con'/'int'/'wis'/'cha' -> score final.
  final Map<String, int> abilityScores;

  @override
  Widget build(BuildContext context) {
    // 2 rangées de 3 (`Row`+`Expanded`) plutôt qu'un `GridView.count` à
    // `childAspectRatio` fixe : ce dernier imposait une hauteur de tuile
    // dérivée de sa largeur, plus courte que le contenu réel (icône + 3
    // lignes de texte) sur certaines largeurs d'écran/échelles de police —
    // "bottom overflowed by 8.7 pixels" signalé par l'utilisateur. `Row` ne
    // contraint que la largeur de chaque tuile (`Expanded`), sa hauteur suit
    // naturellement son contenu, quels que soient l'écran ou la taille de
    // police système : plus aucun risque de débordement vertical.
    final cards = [
      for (final definition in abilityScoreDefinitions)
        _AbilityScoreCard(
          definition: definition,
          score: abilityScores[definition.key] ?? 10,
        ),
    ];

    return Column(
      children: [
        for (var row = 0; row < 2; row++) ...[
          if (row > 0) const SizedBox(height: AppSpacing.sm),
          Row(
            // PAS `CrossAxisAlignment.stretch` : cette `Row` vit dans une
            // `Column` elle-même dans une `ListView` (hauteur non bornée le
            // long de l'axe de défilement) — demander à chaque enfant de
            // s'étirer sur la hauteur de la `Row` lui transmettrait une
            // contrainte de hauteur infinie ("BoxConstraints forces an
            // infinite height", plantage réel constaté). `center` (défaut)
            // laisse chaque carte reporter sa propre hauteur naturelle, déjà
            // égale entre les 3 colonnes puisque leur contenu est structuré
            // à l'identique.
            children: [
              for (var col = 0; col < 3; col++) ...[
                if (col > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(child: cards[row * 3 + col]),
              ],
            ],
          ),
        ],
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => showDiceRollSheet(
          context,
          label: definition.label,
          modifier: modifier,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.parchmentCard,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.woodLight,
              width: AppBorders.card,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(definition.icon, size: 22, color: definition.accentColor),
              const SizedBox(height: AppSpacing.xs),
              // Abréviation plutôt que le libellé complet (demande
              // utilisateur, 2026-09-24).
              Text(
                definition.abbreviation.toUpperCase(),
                style: AppTypography.body(
                  // Plancher d'accessibilité strict du design système
                  // (section 7 : "taille de police minimale 11px, jamais
                  // en dessous") — l'emporte sur la recommandation 9-10px
                  // de la section 4 ("Icône de caractéristique"),
                  // contradiction interne notée pour la prochaine
                  // resynchronisation de
                  // `docs/cahier-des-charges/10-design-system.md`.
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              // Score et modificateur côte à côte (demande utilisateur,
              // 2026-09-15 : le modificateur était auparavant affiché seul
              // sur sa propre ligne, sous le score) plutôt qu'empilés.
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$score',
                    style: AppTypography.body(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
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
            ],
          ),
        ),
      ),
    );
  }
}
