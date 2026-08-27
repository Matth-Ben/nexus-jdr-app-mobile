import '../domain/character_skill_row.dart';

/// Fonctions de mapping pures entre les lignes brutes renvoyées par
/// PostgREST (`skills`, `character_skill_proficiencies`, `translations`) et
/// [CharacterSkillRow], pour la carte "LES 18 COMPÉTENCES" de l'onglet
/// Compétences.
///
/// Dédié à cet onglet plutôt que réutilisé depuis
/// `character_creation/data/skill_row_mapper.dart` (`SkillRowMapper`) : même
/// principe de résolution du nom via `translations` et de la
/// caractéristique via `skills.ability_id`, mais dupliqué pour ne jamais
/// coupler les deux fonctionnalités entre elles — voir le commentaire de
/// classe de `RaceRowMapper` (`character_creation/data/race_row_mapper.dart`)
/// pour le rationale détaillé de cette duplication systématique dans ce
/// dépôt.
///
/// Contrairement aux mappers de `character_creation/data/`, ne duplique pas
/// le parsing des lignes `translations` elles-mêmes
/// (`entity_id`/`value` -> `Map<String, String>`) : ce mapper vit dans le
/// même repository que `CharacterDetailRowMapper`, qui partage déjà ce
/// parsing via `CharacterRowMapper.parseTranslatedNames`
/// (`SupabaseCharacterRepository._fetchTranslatedNames`).
abstract final class CharacterSkillRowMapper {
  /// Identifiants (`id`) à résoudre via `translations`, normalisés en
  /// `String` (les ids reviennent en `int` de PostgREST, `translations
  /// .entity_id` est `text`).
  static Set<String> collectIds(List<Map<String, dynamic>> rows) {
    final ids = <String>{};
    for (final row in rows) {
      final id = row['id'];
      if (id != null) {
        ids.add(id.toString());
      }
    }
    return ids;
  }

  /// `{skill_id: proficiency}` depuis les lignes brutes
  /// `character_skill_proficiencies` embarquées sous `characters`. Une ligne
  /// sans `skill_id`/`proficiency` exploitable est ignorée plutôt que de
  /// faire échouer tout le mapping.
  static Map<int, String> parseProficiencies(List<Map<String, dynamic>> rows) {
    final proficiencies = <int, String>{};
    for (final row in rows) {
      final skillId = row['skill_id'];
      final proficiency = row['proficiency'] as String?;
      if (skillId is num && proficiency != null) {
        proficiencies[skillId.toInt()] = proficiency;
      }
    }
    return proficiencies;
  }

  /// Construit les 18 [CharacterSkillRow] à partir des lignes brutes
  /// `skills` (id, ability_id), des noms déjà résolus (`names`, voir
  /// [collectIds]) et des maîtrises déjà résolues (`proficiencies`, voir
  /// [parseProficiencies]). Une compétence absente de [proficiencies]
  /// retombe sur 'aucune' — voir la documentation de
  /// [CharacterSkillRow.proficiency].
  static List<CharacterSkillRow> toCharacterSkillRows(
    List<Map<String, dynamic>> skillRows, {
    required Map<String, String> names,
    required Map<int, String> proficiencies,
  }) {
    final result = <CharacterSkillRow>[];
    for (final row in skillRows) {
      final id = (row['id'] as num).toInt();
      result.add(
        CharacterSkillRow(
          id: id,
          name: names[id.toString()] ?? 'Compétence #$id',
          abilityId: row['ability_id'] as String? ?? '',
          proficiency: proficiencies[id] ?? 'aucune',
        ),
      );
    }
    return result;
  }
}
