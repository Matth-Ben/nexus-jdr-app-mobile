import '../domain/character_spell_entry.dart';

/// Fonctions de mapping pures entre les lignes brutes renvoyées par
/// PostgREST (`character_spells`, `spells`, `translations`) et
/// [CharacterSpellEntry], pour la section "SORTS" de l'onglet Compétences.
///
/// Voir le commentaire de classe de `CharacterSkillRowMapper` pour le
/// rationale de duplication avec `character_creation/data/spell_row_mapper.dart`
/// (`SpellRowMapper`).
abstract final class CharacterSpellRowMapper {
  /// Identifiants de sorts (`character_spells.spell_id`) du personnage,
  /// dédupliqués — sert à la fois à interroger `spells.id` (`.inFilter`) et,
  /// une fois stringifiés, `translations.entity_id`.
  static Set<int> collectSpellIds(List<Map<String, dynamic>> rows) {
    final ids = <int>{};
    for (final row in rows) {
      final spellId = row['spell_id'];
      if (spellId is num) {
        ids.add(spellId.toInt());
      }
    }
    return ids;
  }

  /// `{spell_id: status}` depuis les lignes brutes `character_spells`
  /// embarquées sous `characters`. Une ligne sans `spell_id`/`status`
  /// exploitable est ignorée.
  static Map<int, String> parseStatuses(List<Map<String, dynamic>> rows) {
    final statuses = <int, String>{};
    for (final row in rows) {
      final spellId = row['spell_id'];
      final status = row['status'] as String?;
      if (spellId is num && status != null) {
        statuses[spellId.toInt()] = status;
      }
    }
    return statuses;
  }

  /// Construit les [CharacterSpellEntry] à partir des lignes brutes `spells`
  /// (id, level, school) déjà filtrées sur les sorts du personnage, des
  /// noms déjà résolus (`names`) et des statuts déjà résolus (`statuses`,
  /// voir [parseStatuses]). Un sort sans statut résolu (ne devrait pas
  /// arriver, `spellRows` est dérivé de `character_spells`) retombe sur
  /// 'connu' plutôt que de crasher.
  static List<CharacterSpellEntry> toCharacterSpellEntries(
    List<Map<String, dynamic>> spellRows, {
    required Map<String, String> names,
    required Map<int, String> statuses,
  }) {
    final result = <CharacterSpellEntry>[];
    for (final row in spellRows) {
      final id = (row['id'] as num).toInt();
      result.add(
        CharacterSpellEntry(
          id: id,
          name: names[id.toString()] ?? 'Sort #$id',
          level: (row['level'] as num?)?.toInt() ?? 0,
          school: row['school'] as String? ?? '',
          status: statuses[id] ?? 'connu',
        ),
      );
    }
    return result;
  }
}
