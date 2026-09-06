/// Prérequis RAW 5e pour multiclasser dans une classe — utilisés par l'étape
/// `classDecision` de la montée de niveau (`presentation/level_up_screen.dart`)
/// pour déterminer les classes éligibles au multiclassage (voir
/// `presentation/providers/level_up_provider.dart`) et revérifiés côté
/// écriture (`data/character_repository.dart::applyLevelUp`, défense en
/// profondeur — même discipline que le plafond ASI à 20).
///
/// Un personnage peut multiclasser dans une NOUVELLE classe uniquement s'il
/// remplit le prérequis de cette nouvelle classe **ET** celui de TOUTES ses
/// classes ACTUELLES (RAW : on ne peut jamais avoir de niveau dans une classe
/// dont on ne remplit plus le prérequis, ce qui inclut de rester dans sa
/// classe de départ).
///
/// Score de caractéristique = score final déjà stocké
/// (`character_ability_scores.score`, PAS le score de base — bonus raciaux/ASI
/// déjà inclus).
///
/// Données fournies par le chef de projet, autoritaires : encodées telles
/// quelles ci-dessous, non re-vérifiées ici — même convention de clé (nom de
/// classe en français) que `character_creation/domain/spellcasting_rules.dart`
/// / `characters/domain/spell_slot_progression.dart`.
abstract final class MulticlassPrerequisites {
  /// Liste de clauses par classe : la classe est éligible si AU MOINS UNE
  /// clause est entièrement remplie (chaque clause est une liste de
  /// `(abilityId, minScore)` qui doivent TOUTES être remplies). Une seule
  /// classe (Guerrier) a un OU réel entre 2 caractéristiques ; toutes les
  /// autres n'ont qu'une seule clause.
  static const Map<String, List<List<(String abilityId, int minScore)>>>
  _requirementsByClassName = {
    'Barbare': [
      [('str', 13)],
    ],
    'Barde': [
      [('cha', 13)],
    ],
    'Clerc': [
      [('wis', 13)],
    ],
    'Druide': [
      [('wis', 13)],
    ],
    'Guerrier': [
      [('str', 13)],
      [('dex', 13)],
    ], // OU
    'Moine': [
      [('dex', 13), ('wis', 13)],
    ], // ET
    'Paladin': [
      [('str', 13), ('cha', 13)],
    ], // ET
    'Rôdeur': [
      [('dex', 13), ('wis', 13)],
    ], // ET
    'Roublard': [
      [('dex', 13)],
    ],
    'Ensorceleur': [
      [('cha', 13)],
    ],
    'Occultiste': [
      [('cha', 13)],
    ],
    'Magicien': [
      [('int', 13)],
    ],
  };

  /// `true` ssi au moins une clause de [className] est entièrement remplie
  /// par [scoresByAbilityId] (`ability_id` -> score final). `false` pour une
  /// classe absente de [_requirementsByClassName] (ne devrait pas arriver
  /// pour les 12 classes RAW couvertes ci-dessus — traité comme "prérequis
  /// non rempli" plutôt que de deviner une éligibilité, même philosophie que
  /// le reste de ce dépôt).
  static bool meetsRequirement(
    String className,
    Map<String, int> scoresByAbilityId,
  ) => satisfiedAbilityIds(className, scoresByAbilityId).isNotEmpty;

  /// Caractéristiques effectivement responsables de l'éligibilité de
  /// [className] (union des clauses entièrement remplies) — sert à
  /// construire le texte "Prérequis rempli : {liste}" de l'étape
  /// `classDecision` (spec direction-artistique section 2) : pour une classe
  /// à prérequis OU (Guerrier), ne cite que la/les caractéristiques
  /// réellement remplies, jamais les deux systématiquement. Liste vide si
  /// [meetsRequirement] serait `false`.
  static List<String> satisfiedAbilityIds(
    String className,
    Map<String, int> scoresByAbilityId,
  ) {
    final clauses = _requirementsByClassName[className];
    if (clauses == null) return const [];

    final satisfied = <String>{};
    for (final clause in clauses) {
      final clauseSatisfied = clause.every(
        (requirement) =>
            (scoresByAbilityId[requirement.$1] ?? 0) >= requirement.$2,
      );
      if (clauseSatisfied) {
        satisfied.addAll(clause.map((requirement) => requirement.$1));
      }
    }
    return satisfied.toList();
  }
}
