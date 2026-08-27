/// Une des 18 compétences résolues pour le personnage (onglet
/// "Compétences", `presentation/widgets/character_skills_card.dart`) — nom
/// traduit, caractéristique associée (`skills.ability_id`, seule source de
/// vérité, PAS le mapping français figé
/// `character_creation/domain/skill_ability_mapping.dart`, réservé à un
/// usage ponctuel côté assistant de création — voir sa documentation de
/// classe) et maîtrise du personnage sur cette compétence.
///
/// Volontairement une classe simple (pas `freezed`) — même précédent que
/// `CharacterDetailClassRow` : donnée en lecture seule affichée telle
/// quelle, aucune égalité structurelle fine nécessaire.
class CharacterSkillRow {
  const CharacterSkillRow({
    required this.id,
    required this.name,
    required this.abilityId,
    required this.proficiency,
  });

  final int id;
  final String name;

  /// 'str'/'dex'/'con'/'int'/'wis'/'cha'.
  final String abilityId;

  /// `character_skill_proficiencies.proficiency` : 'aucune'/'competente'/
  /// 'expertise'. Retombe sur 'aucune' quand le personnage n'a aucune ligne
  /// `character_skill_proficiencies` pour cette compétence (l'assistant de
  /// création n'insère une ligne que pour les compétences effectivement
  /// maîtrisées, voir `character_creation_repository.dart::createCharacter`).
  final String proficiency;
}
