import '../domain/invocation_prerequisites.dart';
import '../domain/level_up_invocation_option.dart';

/// Fonctions de mapping pures entre les lignes brutes
/// `invocations`/`translations` renvoyées par PostgREST et
/// [LevelUpInvocationOption], pour l'étape "Invocations" de la montée de
/// niveau (Occultiste) — voir
/// `SupabaseCharacterRepository.fetchAvailableInvocations`.
///
/// Duplicata volontaire de `LevelUpFeatRowMapper` (même structure
/// `prerequisites` jsonb, même résolution `translations`) — voir sa
/// documentation de classe pour le rationale de duplication.
abstract final class LevelUpInvocationRowMapper {
  /// Identifiants (`invocations.id`) à résoudre via `translations`,
  /// normalisés en `String`.
  static Set<String> collectInvocationIds(List<Map<String, dynamic>> rows) {
    final ids = <String>{};
    for (final row in rows) {
      final id = row['id'];
      if (id != null) {
        ids.add(id.toString());
      }
    }
    return ids;
  }

  /// Extrait `prerequisites->>'text'` d'une ligne `invocations` brute —
  /// même règle que `LevelUpFeatRowMapper.prerequisiteTextFor`.
  static String? prerequisiteTextFor(Map<String, dynamic> row) {
    final prerequisites = row['prerequisites'];
    if (prerequisites is Map) {
      final text = prerequisites['text'];
      if (text is String && text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  /// Prérequis structurés (`level`/`pact`/`cantrip_spell_id`) d'une ligne
  /// `invocations` brute — tolérant, voir [InvocationPrerequisites.fromJson].
  static InvocationPrerequisites structuredPrerequisitesFor(
    Map<String, dynamic> row,
  ) => InvocationPrerequisites.fromJson(row['prerequisites']);

  /// `spells.id` des sorts mineurs requis par au moins une des [rows], à
  /// résoudre via `translations` (`entity_type = 'spell'`), normalisés en
  /// `String`.
  static Set<String> collectCantripSpellIds(List<Map<String, dynamic>> rows) {
    return {
      for (final row in rows)
        if (structuredPrerequisitesFor(row).cantripSpellId case final id?)
          id.toString(),
    };
  }

  /// Construit les [LevelUpInvocationOption] à partir des lignes brutes
  /// `invocations` (déjà filtrées pour exclure les invocations connues, voir
  /// `SupabaseCharacterRepository.fetchAvailableInvocations`) et des
  /// noms/descriptions déjà résolus — triées alphabétiquement (même règle
  /// que `LevelUpFeatRowMapper.toFeatOptions`).
  static List<LevelUpInvocationOption> toInvocationOptions(
    List<Map<String, dynamic>> rows, {
    required Map<String, String> names,
    required Map<String, String> descriptions,
    Map<String, String> cantripNames = const {},
  }) {
    final options = [
      for (final row in rows)
        if (row['id'] != null)
          LevelUpInvocationOption(
            id: row['id'] as Object,
            name: names[row['id'].toString()] ?? 'Invocation #${row['id']}',
            description: descriptions[row['id'].toString()] ?? '',
            prerequisiteText: prerequisiteTextFor(row),
            prerequisites: structuredPrerequisitesFor(row),
            cantripName:
                cantripNames[structuredPrerequisitesFor(row).cantripSpellId
                    ?.toString()],
          ),
    ]..sort((a, b) => a.name.compareTo(b.name));
    return options;
  }
}
