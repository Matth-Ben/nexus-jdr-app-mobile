import '../../character_creation/domain/ability_score_definitions.dart';
import '../../character_creation/domain/ability_score_rules.dart';

/// Résultat du calcul de jet de sauvegarde pour une caractéristique, affiché
/// par la carte "Jets de sauvegarde" de la fiche personnage
/// (`presentation/widgets/character_saving_throws_card.dart`).
class SavingThrowResult {
  const SavingThrowResult({
    required this.abilityKey,
    required this.isProficient,
    required this.bonus,
  });

  /// 'str'/'dex'/'con'/'int'/'wis'/'cha'.
  final String abilityKey;

  /// Vrai si la classe principale du personnage octroie une maîtrise de jet
  /// de sauvegarde sur cette caractéristique — voir
  /// `CharacterDetail.primarySavingThrowProficiencies`.
  final bool isProficient;

  /// Modificateur de caractéristique + bonus de maîtrise si [isProficient].
  final int bonus;
}

/// Calcul pur des bonus de jets de sauvegarde de la fiche personnage.
///
/// Réutilise volontiers `character_creation/domain/ability_score_definitions.dart`
/// (ordre canonique For/Dex/Con/Int/Sag/Cha) et `ability_score_rules.dart`
/// (`AbilityScoreRules.abilityModifier`) tels quels, plutôt que de les
/// dupliquer — exception explicitement actée à la règle habituelle de ce
/// dépôt ("chaque étape/écran duplique son propre mapping pour ne jamais
/// coupler deux fonctionnalités") : ces deux fichiers sont des utilitaires
/// purs sans état ni logique propre à l'assistant de création, la spec de
/// cette tâche demande explicitement de les réutiliser tels quels plutôt que
/// d'en recréer une 3ᵉ version.
abstract final class SavingThrowCalculator {
  /// Bonus d'un seul jet de sauvegarde : modificateur de caractéristique
  /// (`AbilityScoreRules.abilityModifier`) + [proficiencyBonus] si
  /// [isProficient].
  static int bonusFor({
    required int score,
    required bool isProficient,
    required int proficiencyBonus,
  }) {
    final modifier = AbilityScoreRules.abilityModifier(score);
    return isProficient ? modifier + proficiencyBonus : modifier;
  }

  /// Les 6 résultats, dans l'ordre canonique de [abilityScoreDefinitions].
  /// Une caractéristique absente de [abilityScores] (donnée serveur
  /// incohérente) retombe sur un score de 10 (modificateur nul) plutôt que
  /// de crasher.
  static List<SavingThrowResult> computeAll({
    required Map<String, int> abilityScores,
    required Set<String> proficientAbilities,
    required int proficiencyBonus,
  }) {
    return [
      for (final definition in abilityScoreDefinitions)
        SavingThrowResult(
          abilityKey: definition.key,
          isProficient: proficientAbilities.contains(definition.key),
          bonus: bonusFor(
            score: abilityScores[definition.key] ?? 10,
            isProficient: proficientAbilities.contains(definition.key),
            proficiencyBonus: proficiencyBonus,
          ),
        ),
    ];
  }
}
