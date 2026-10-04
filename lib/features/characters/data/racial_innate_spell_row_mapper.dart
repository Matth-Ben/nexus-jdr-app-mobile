import '../domain/racial_innate_spell_grant.dart';

/// Mapping pur entre les lignes brutes `racial_innate_spells`/`translations`
/// et [RacialInnateSpellGrant] — voir `racial_innate_spell_repository.dart`.
abstract final class RacialInnateSpellRowMapper {
  /// Identifiants de sorts des lignes [rows] (`spell_id`), en `String` pour
  /// interroger `translations` (`entity_id` est `text`) — même principe que
  /// `PactWeaponRowMapper.collectIds`. Une ligne sans `spell_id` est ignorée.
  static Set<String> collectSpellIds(List<Map<String, dynamic>> rows) => {
    for (final row in rows)
      if (row['spell_id'] != null) row['spell_id'].toString(),
  };

  /// Convertit [rows] (déjà filtrées côté requête sur `race_id`/
  /// `lineage_id IS NULL`/`spell_id IS NOT NULL`/`character_level <=` le
  /// niveau max demandé, voir [RacialInnateSpellRepository.fetchApplicableGrants])
  /// en [RacialInnateSpellGrant], triés par [RacialInnateSpellGrant
  /// .characterLevel] croissant.
  ///
  /// Filtre ici la dernière condition que la requête ne peut pas exprimer
  /// proprement (`subrace_id IS NULL OR subrace_id = :subraceId`) : une ligne
  /// dont `subrace_id` est non nul et différent de [subraceId] est ignorée —
  /// une ligne sans `subrace_id` (race entière) est toujours conservée.
  ///
  /// Ignore aussi silencieusement une ligne dont `spell_id`/`character_level`
  /// n'est pas numérique, ou dont le nom du sort n'a pas pu être résolu via
  /// [names] (sort introuvable dans le catalogue de cet environnement) — même
  /// discipline défensive que `PatronExtendedSpellRowMapper.parse`.
  static List<RacialInnateSpellGrant> parse({
    required List<Map<String, dynamic>> rows,
    required int? subraceId,
    required Map<String, String> names,
  }) {
    final grants = <RacialInnateSpellGrant>[];
    for (final row in rows) {
      final spellId = row['spell_id'];
      final characterLevel = row['character_level'];
      if (spellId is! num || characterLevel is! num) continue;

      final rowSubraceId = row['subrace_id'];
      if (rowSubraceId is num && rowSubraceId.toInt() != subraceId) continue;

      final name = names[spellId.toInt().toString()];
      if (name == null) continue;

      grants.add(
        RacialInnateSpellGrant(
          spellId: spellId.toInt(),
          spellName: name,
          characterLevel: characterLevel.toInt(),
        ),
      );
    }
    grants.sort((a, b) => a.characterLevel.compareTo(b.characterLevel));
    return grants;
  }
}
