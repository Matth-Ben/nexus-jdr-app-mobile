import '../../character_creation/domain/ability_score_rules.dart';
import 'character_skill_row.dart';

/// Résultat du calcul de bonus pour une compétence, affiché par la carte
/// "LES 18 COMPÉTENCES" de l'onglet Compétences
/// (`presentation/widgets/character_skills_card.dart`).
class SkillBonusResult {
  const SkillBonusResult({
    required this.skillId,
    required this.name,
    required this.abilityId,
    required this.proficiency,
    required this.bonus,
  });

  final int skillId;
  final String name;

  /// 'str'/'dex'/'con'/'int'/'wis'/'cha'.
  final String abilityId;

  /// 'aucune'/'competente'/'expertise'.
  final String proficiency;

  final int bonus;

  /// Vrai si maîtrisée ou expertisée — affiche le point plein (légende
  /// "● maîtrisée" de la carte), pas seulement en cas d'expertise.
  bool get isMastered => proficiency != 'aucune';
}

/// Calcul pur des bonus des 18 compétences de l'onglet Compétences.
///
/// Même principe que `saving_throw_calculator.dart` (`SavingThrowCalculator`) :
/// modificateur de caractéristique (`AbilityScoreRules.abilityModifier`) +
/// bonus de maîtrise une fois si 'competente', deux fois si 'expertise'.
/// Dupliqué plutôt que généralisé avec `SavingThrowCalculator` — même
/// rationale de duplication systématique que le reste de ce dépôt (voir le
/// commentaire de classe de `RaceRowMapper`), la formule de multiplication
/// par l'expertise n'existant nulle part ailleurs.
abstract final class SkillBonusCalculator {
  /// 0 pour 'aucune', 1 pour 'competente', 2 pour 'expertise' — toute autre
  /// valeur (donnée serveur incohérente) retombe sur 0 plutôt que de
  /// crasher.
  static int proficiencyMultiplier(String proficiency) {
    switch (proficiency) {
      case 'expertise':
        return 2;
      case 'competente':
        return 1;
      default:
        return 0;
    }
  }

  static int bonusFor({
    required int score,
    required String proficiency,
    required int proficiencyBonus,
  }) {
    final modifier = AbilityScoreRules.abilityModifier(score);
    return modifier + proficiencyMultiplier(proficiency) * proficiencyBonus;
  }

  /// Un résultat par compétence de [skills], dans l'ordre reçu (déjà
  /// l'ordre alphabétique français des 18 compétences côté base — voir
  /// `character_skill_row_mapper.dart`). Une caractéristique absente de
  /// [abilityScores] retombe sur un score de 10 (modificateur nul), même
  /// règle que `SavingThrowCalculator.computeAll`.
  static List<SkillBonusResult> computeAll({
    required List<CharacterSkillRow> skills,
    required Map<String, int> abilityScores,
    required int proficiencyBonus,
  }) {
    return [
      for (final skill in skills)
        SkillBonusResult(
          skillId: skill.id,
          name: skill.name,
          abilityId: skill.abilityId,
          proficiency: skill.proficiency,
          bonus: bonusFor(
            score: abilityScores[skill.abilityId] ?? 10,
            proficiency: skill.proficiency,
            proficiencyBonus: proficiencyBonus,
          ),
        ),
    ];
  }
}
