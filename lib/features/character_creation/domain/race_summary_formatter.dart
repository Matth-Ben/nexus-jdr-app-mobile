import 'race_trait.dart';

/// Formatte la ligne de résumé affichée sous le nom d'une race/sous-race à
/// l'étape 1/9 de l'assistant de création
/// (`docs/cahier-des-charges/04-fonctionnalites-app-mobile.md` section 3
/// point 1, maquette `02_étape_1_race.png`) : ex. "+2 Dex · Vision dans le
/// noir · Transe".
///
/// Règles tranchées par le chef de projet (voir la tâche qui a produit ce
/// fichier), volontairement simples plutôt que de tenter de deviner quels
/// bonus/traits sont "les plus emblématiques" :
/// - Si les 6 caractéristiques ont chacune un bonus de +1 (cas de l'Humain),
///   affiche "+1 à toutes les caractéristiques" plutôt que de les lister une
///   à une.
/// - Sinon, une entrée "+X Abr" par bonus de caractéristique présent dans
///   `ability_bonuses`, dans l'ordre canonique For/Dex/Con/Int/Sag/Cha. La
///   clé spéciale `choice_others` (bonus à caractéristiques au choix, ex.
///   Demi-elfe) n'apparaît jamais dans [_abilityAbbreviations] : elle est
///   donc ignorée ici sans traitement dédié, et sera détaillée à une étape
///   ultérieure de l'assistant (répartition des caractéristiques).
/// - Complète avec les deux premiers traits, dans l'ordre où ils
///   apparaissent dans le jsonb `traits`.
abstract final class RaceSummaryFormatter {
  static const Map<String, String> _abilityAbbreviations = {
    'str': 'For',
    'dex': 'Dex',
    'con': 'Con',
    'int': 'Int',
    'wis': 'Sag',
    'cha': 'Cha',
  };

  static const int maxTraitsInSummary = 2;

  static String format({
    required Map<String, dynamic> abilityBonuses,
    required List<RaceTrait> traits,
  }) {
    final abilityPart = _formatAbilityBonuses(abilityBonuses);
    final segments = [
      if (abilityPart.isNotEmpty) abilityPart,
      ...traits.take(maxTraitsInSummary).map((trait) => trait.name),
    ];
    return segments.join(' · ');
  }

  static String _formatAbilityBonuses(Map<String, dynamic> abilityBonuses) {
    final hasUniformBonusToAllAbilities = _abilityAbbreviations.keys.every(
      (key) => abilityBonuses[key] == 1,
    );
    if (hasUniformBonusToAllAbilities) {
      return '+1 à toutes les caractéristiques';
    }

    final parts = <String>[
      for (final entry in _abilityAbbreviations.entries)
        if (abilityBonuses[entry.key] is num)
          '+${(abilityBonuses[entry.key] as num).toInt()} ${entry.value}',
    ];
    return parts.join(', ');
  }
}
