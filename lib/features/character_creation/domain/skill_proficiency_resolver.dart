import 'skill_catalog.dart';

/// Résout les compétences de classe (`CharacterCreationDraft
/// .classSkillChoices`) et les compétences d'historique (`BackgroundOption
/// .skillProficiencies`, toujours accordées automatiquement — pas un choix du
/// joueur) en lignes prêtes pour `character_skill_proficiencies`, à l'étape
/// 9/9 "Récapitulatif" de l'assistant de création.
///
/// Dédupliqué par `skill_id` (la table a une PK composite `(character_id,
/// skill_id)`) : une compétence choisie à l'étape 5/9 qui se trouve être
/// *aussi* octroyée par l'historique choisi à l'étape 3/9 ne doit générer
/// qu'une seule ligne, pas deux — cas plausible (le joueur peut choisir une
/// compétence de classe qui recoupe celles de son historique, D&D 5e ne
/// l'interdit pas explicitement à la création selon les tables déjà peuplées
/// ici) plutôt qu'un cas théorique à ignorer.
///
/// Toujours `proficiency: 'competente'` pour les deux sources (voir la
/// consigne d'origine) : `'expertise'` n'est jamais atteignable à la création
/// d'un personnage niveau 1 (aptitude de classe ultérieure, ex. Roublard
/// niveau 1... en réalité si, mais hors périmètre de cet assistant — décision
/// du chef de projet).
///
/// Un nom de compétence sans correspondance dans [catalog] est ignoré
/// silencieusement plutôt que de faire échouer toute la création (ne devrait
/// normalement jamais arriver : ces noms viennent de `classes.skill_choices`/
/// `backgrounds.skill_proficiencies`, censés utiliser exactement les 18 noms
/// de `skills.name` résolus par [catalog] — mêmes garanties que le reste de
/// ce module, voir `data/background_row_mapper.dart`).
abstract final class SkillProficiencyResolver {
  static List<({int skillId, String proficiency})> resolve({
    required List<String> classSkillNames,
    required List<String> backgroundSkillNames,
    required SkillCatalog catalog,
  }) {
    final idByName = {for (final skill in catalog.skills) skill.name: skill.id};

    final resolvedIds = <int>{};
    for (final name in [...classSkillNames, ...backgroundSkillNames]) {
      final id = idByName[name];
      if (id != null) {
        resolvedIds.add(id);
      }
    }

    return [
      for (final id in resolvedIds) (skillId: id, proficiency: 'competente'),
    ];
  }
}
