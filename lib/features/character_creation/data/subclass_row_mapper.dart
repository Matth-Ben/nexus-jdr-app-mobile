import '../domain/subclass_option.dart';

/// Fonctions de mapping pures entre les lignes brutes renvoyées par
/// PostgREST (`subclasses`, `translations`) et [SubclassOption].
///
/// Dédié au catalogue complet ([SubclassCatalog], `character_creation_repository.dart
/// ::fetchSubclassCatalog`) plutôt que réutilisé depuis
/// `subclass_choice_row_mapper.dart` : même principe de résolution des noms
/// via `translations`, mais dupliqué pour ne jamais coupler les deux
/// catalogues entre eux — même rationale que `ClassRowMapper` vis-à-vis de
/// `RaceRowMapper` (voir sa documentation de classe).
abstract final class SubclassRowMapper {
  /// Identifiants (`id`) à résoudre via `translations`, normalisés en
  /// `String` (les ids reviennent en `int` de PostgREST, `translations
  /// .entity_id` est `text`) — même règle que `ClassRowMapper.collectIds`.
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

  /// Parse les lignes brutes de `translations` (colonnes réelles
  /// `entity_id`/`value`, PAS `name`) en `{entity_id: value}` — même règle
  /// que `ClassRowMapper.parseTranslatedValues`.
  static Map<String, String> parseTranslatedNames(
    List<Map<String, dynamic>> rawRows,
  ) {
    final names = <String, String>{};
    for (final row in rawRows) {
      final entityId = row['entity_id'] as String?;
      final value = row['value'] as String?;
      if (entityId != null && value != null) {
        names[entityId] = value;
      }
    }
    return names;
  }

  /// Construit une [SubclassOption] à partir d'une ligne brute `subclasses`
  /// et des noms déjà résolus (`names`, clés en `String`, voir
  /// [collectIds]). Un id sans nom résolu retombe sur un libellé générique
  /// ("Sous-classe #12") plutôt que de crasher ou d'afficher `null` — même
  /// règle que `ClassRowMapper.toClassOption`.
  static SubclassOption toSubclassOption(
    Map<String, dynamic> row, {
    required Map<String, String> names,
  }) {
    final id = (row['id'] as num).toInt();
    return SubclassOption(
      id: id,
      name: names[id.toString()] ?? 'Sous-classe #$id',
      classId: (row['class_id'] as num).toInt(),
    );
  }
}
