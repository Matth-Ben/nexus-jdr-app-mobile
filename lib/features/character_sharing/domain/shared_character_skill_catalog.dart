/// Les 18 compétences D&D 5e (nom français + clé de caractéristique), pour
/// reconstruire la liste complète attendue par [CharacterSkillRow]
/// (`features/characters/domain/character_skill_row.dart`) côté vue
/// partagée en lecture seule.
///
/// `public.get_shared_character` (dépôt web) ne renvoie que les compétences
/// pour lesquelles le personnage a une ligne `character_skill_proficiencies`
/// (maîtrisées), jamais les 18 avec 'aucune' en repli — contrairement à la
/// fiche authentifiée, qui les lit depuis la table de référence `skills`
/// (`SupabaseCharacterRepository.fetchCharacterDetail`, `.from('skills')`),
/// une table non exposée à un lecteur anonyme (voir le rationale RPC-vs-RLS
/// documenté dans `supabase/migrations/20260908090000_add_character_share_token.sql`
/// du dépôt web). Dupliqué ici en constante Dart plutôt que d'élargir
/// encore la fonction RPC : les 18 compétences D&D 5e (et leur
/// caractéristique associée) sont une règle de jeu figée, jamais du contenu
/// éditorial — même rationale que
/// `character_creation/domain/skill_ability_mapping.dart::SkillAbilityMapping`,
/// dont ce fichier reprend les mêmes noms/associations (vérifiés contre
/// `supabase/migrations/20260825090500_seed_reference_core_data.sql` côté
/// dépôt web), converties en clé de caractéristique ('str'/'dex'/...) plutôt
/// qu'en abréviation d'affichage ('For'/'Dex'/...) : c'est cette clé-là que
/// `CharacterSkillRow.abilityId`/`SkillBonusCalculator` attendent.
abstract final class SharedCharacterSkillCatalog {
  /// `{nom de compétence en français: clé de caractéristique}`, mêmes 18
  /// compétences et associations que `SkillAbilityMapping
  /// .abilityAbbreviationBySkill`, dans le même ordre (alphabétique
  /// français).
  static const Map<String, String> abilityKeyBySkillName = {
    'Acrobaties': 'dex',
    'Arcanes': 'int',
    'Athlétisme': 'str',
    'Discrétion': 'dex',
    'Dressage': 'wis',
    'Escamotage': 'dex',
    'Histoire': 'int',
    'Intimidation': 'cha',
    'Investigation': 'int',
    'Médecine': 'wis',
    'Nature': 'int',
    'Perception': 'wis',
    'Perspicacité': 'wis',
    'Persuasion': 'cha',
    'Religion': 'int',
    'Représentation': 'cha',
    'Survie': 'wis',
    'Tromperie': 'cha',
  };
}
