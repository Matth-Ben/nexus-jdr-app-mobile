/// Mapping compétence → caractéristique des 18 compétences D&D 5e, encodé en
/// constante Dart applicative plutôt qu'une requête réseau vers `skills` :
/// `classes.skill_choices`/`backgrounds.skill_proficiencies` donnent déjà les
/// noms de compétences en clair (jsonb, pas de FK), donc `skills.ability_id`
/// n'a jamais besoin d'être lu côté client pour cette étape.
///
/// Vérifié contre `supabase/migrations/20260825090500_seed_reference_core_data.sql`
/// (dépôt web, bloc d'insertion `public.skills`) avant d'écrire ce fichier —
/// noms et associations caractéristique recopiés exactement dans le même
/// ordre que la migration (utilisé pour développer `{"choices": "toutes"}`,
/// forme spécifique au Barde, voir `class_tool_choice.dart` pour le pendant
/// côté outils).
abstract final class SkillAbilityMapping {
  /// `{nom de compétence en français: abréviation de caractéristique}` —
  /// mêmes abréviations que `RaceSummaryFormatter._abilityAbbreviations`
  /// ('For', 'Dex', 'Con', 'Int', 'Sag', 'Cha').
  static const Map<String, String> abilityAbbreviationBySkill = {
    'Acrobaties': 'Dex',
    'Arcanes': 'Int',
    'Athlétisme': 'For',
    'Discrétion': 'Dex',
    'Dressage': 'Sag',
    'Escamotage': 'Dex',
    'Histoire': 'Int',
    'Intimidation': 'Cha',
    'Investigation': 'Int',
    'Médecine': 'Sag',
    'Nature': 'Int',
    'Perception': 'Sag',
    'Perspicacité': 'Sag',
    'Persuasion': 'Cha',
    'Religion': 'Int',
    'Représentation': 'Cha',
    'Survie': 'Sag',
    'Tromperie': 'Cha',
  };

  /// Les 18 noms de compétences, dans l'ordre de la migration de seed —
  /// utilisé pour développer la forme `{"choices": "toutes"}` de
  /// `classes.skill_choices` (Barde uniquement à ce jour) en une vraie liste
  /// de candidats, voir `data/class_row_mapper.dart`.
  static const List<String> allSkillNames = [
    'Acrobaties',
    'Arcanes',
    'Athlétisme',
    'Discrétion',
    'Dressage',
    'Escamotage',
    'Histoire',
    'Intimidation',
    'Investigation',
    'Médecine',
    'Nature',
    'Perception',
    'Perspicacité',
    'Persuasion',
    'Religion',
    'Représentation',
    'Survie',
    'Tromperie',
  ];

  /// Abréviation de caractéristique pour [skillName] ("Int", "Sag"...), ou
  /// chaîne vide si le nom n'est pas l'une des 18 compétences connues
  /// (donnée de seed corrompue/évolution du contenu) — jamais de crash pour
  /// un simple affichage.
  static String abbreviationFor(String skillName) =>
      abilityAbbreviationBySkill[skillName] ?? '';
}
