import 'ability_score_modifier_calculator.dart';
import 'race_catalog.dart';

/// Résout les 6 scores de caractéristiques **finaux** (score de base choisi à
/// l'étape 4/9 + bonus racial déjà appliqué) à l'étape 9/9 "Récapitulatif" de
/// l'assistant de création, avant écriture dans `character_ability_scores`
/// (une ligne par caractéristique, `ability_id` = la clé texte directement —
/// voir `data/character_creation_repository.dart`) et avant calcul des PV de
/// départ (`domain/hit_points_calculator.dart`, qui a besoin du modificateur
/// de Constitution final).
///
/// Pure réutilisation de [AbilityScoreModifierCalculator.racialBonusFor]
/// (déjà utilisé à l'étape 4/9 pour l'affichage "Modificateur +X") : ce
/// fichier ne fait qu'itérer les 6 clés et sommer, pour rester testable
/// isolément sans reconstruire cette boucle inline dans le dépôt de données.
abstract final class FinalAbilityScoresResolver {
  static Map<String, int> resolve({
    required Map<String, int> baseScores,
    required RaceCatalog raceCatalog,
    required int? raceId,
    required int? subraceId,
  }) {
    return {
      for (final entry in baseScores.entries)
        entry.key:
            entry.value +
            AbilityScoreModifierCalculator.racialBonusFor(
              abilityKey: entry.key,
              catalog: raceCatalog,
              raceId: raceId,
              subraceId: subraceId,
            ),
    };
  }
}
