import '../../character_creation/data/spell_row_mapper.dart';
import '../domain/patron_extended_spells.dart';

/// Mapping pur des lignes `subclass_spells` (`grant_kind = 'extends_list'`),
/// `spells` et `translations` vers les [PatronExtendedSpell] de chaque
/// sous-classe (patron).
abstract final class PatronExtendedSpellRowMapper {
  /// Identifiants de sorts des lignes [grantRows] (lignes incomplètes
  /// ignorées), dédupliqués.
  static Set<int> collectSpellIds(List<Map<String, dynamic>> grantRows) =>
      SpellRowMapper.collectSpellIds(grantRows);

  /// `{subclass_id: sorts étendus}`. Une ligne sans `subclass_id`/`spell_id`/
  /// `class_level` numérique, ou dont le sort n'est pas dans [spellRows], est
  /// ignorée.
  static Map<int, List<PatronExtendedSpell>> parse({
    required List<Map<String, dynamic>> grantRows,
    required List<Map<String, dynamic>> spellRows,
    required Map<String, String> names,
  }) {
    final spellsById = {
      for (final row in spellRows)
        if (row['id'] is num)
          (row['id'] as num).toInt(): SpellRowMapper.toSpellOption(
            row,
            names: names,
          ),
    };
    final result = <int, List<PatronExtendedSpell>>{};
    for (final row in grantRows) {
      final subclassId = row['subclass_id'];
      final spellId = row['spell_id'];
      final classLevel = row['class_level'];
      if (subclassId is! num || spellId is! num || classLevel is! num) {
        continue;
      }
      final spell = spellsById[spellId.toInt()];
      if (spell == null) continue;
      result
          .putIfAbsent(subclassId.toInt(), () => [])
          .add(
            PatronExtendedSpell(spell: spell, classLevel: classLevel.toInt()),
          );
    }
    return result;
  }
}
