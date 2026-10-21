import '../../../core/utils/french_text_normalizer.dart';
import '../domain/level_up_draconic_ancestry_option.dart';

/// Fonctions de mapping pures entre les lignes brutes `class_options`/
/// `translations` renvoyées par PostgREST et [LevelUpDraconicAncestryOption],
/// pour l'aptitude "Ancêtre draconique" (Ensorceleur, Lignage draconique,
/// niveau 1 de sous-classe) — voir
/// `SupabaseCharacterRepository.fetchAvailableDraconicAncestryOptions`.
///
/// Duplicata volontaire de `LevelUpRuneRowMapper`/`LevelUpInfusionRowMapper`
/// — voir leur documentation de classe pour le rationale de duplication.
abstract final class LevelUpDraconicAncestryRowMapper {
  /// Identifiants (`class_options.id`) à résoudre via `translations`,
  /// normalisés en `String`.
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

  /// Extrait `prerequisites->>'damage_type'` d'une ligne `class_options`
  /// brute — `null` si la clé est absente/vide, ou si `prerequisites` n'est
  /// pas un objet JSON (une ligne sans type de dégâts résolu est ignorée par
  /// [toOptions], jamais affichée avec un type vide).
  static String? damageTypeFor(Map<String, dynamic> row) {
    final prerequisites = row['prerequisites'];
    if (prerequisites is Map) {
      final damageType = prerequisites['damage_type'];
      if (damageType is String && damageType.isNotEmpty) {
        return damageType;
      }
    }
    return null;
  }

  /// Construit les [LevelUpDraconicAncestryOption] à partir des lignes
  /// brutes `class_options` et des noms/descriptions déjà résolus — triées
  /// alphabétiquement (même règle que les autres mappers de ce chantier).
  /// Une ligne sans `damage_type` résolu est ignorée (défensif : ne devrait
  /// jamais arriver une fois le contenu peuplé, voir
  /// `domain/level_up_draconic_ancestry_option.dart`).
  static List<LevelUpDraconicAncestryOption> toOptions(
    List<Map<String, dynamic>> rows, {
    required Map<String, String> names,
    required Map<String, String> descriptions,
  }) {
    final options = [
      for (final row in rows)
        if (row['id'] != null && damageTypeFor(row) != null)
          LevelUpDraconicAncestryOption(
            id: row['id'] as Object,
            name: names[row['id'].toString()] ?? 'Ascendance #${row['id']}',
            description: descriptions[row['id'].toString()] ?? '',
            damageType: damageTypeFor(row)!,
          ),
    ]..sort((a, b) => FrenchTextNormalizer.compare(a.name, b.name));
    return options;
  }
}
