import 'skill_bonus_calculator.dart';

/// Filtre pur des compétences par nom — voir la carte "LES 18 COMPÉTENCES"
/// de l'onglet "Compétences" (`presentation/widgets/character_skills_tab_body.dart`)
/// et l'icône recherche du bandeau bois de cet onglet
/// (`presentation/character_detail_screen.dart`).
///
/// Même convention que `spell_name_filter.dart::SpellNameFilter` (sous-chaîne
/// insensible à la casse, sans normalisation des accents).
abstract final class SkillNameFilter {
  static List<SkillBonusResult> apply({
    required List<SkillBonusResult> results,
    required String query,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return results;
    return results
        .where((result) => result.name.toLowerCase().contains(normalizedQuery))
        .toList(growable: false);
  }
}
