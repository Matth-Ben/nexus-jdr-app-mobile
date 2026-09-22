import '../domain/subclass_choice_catalog.dart';
import '../domain/subclass_choice_option.dart';

/// Mapping pur des lignes brutes `class_features`, `subclasses` et
/// `translations` vers [SubclassChoiceCatalog].
abstract final class SubclassChoiceRowMapper {
  /// `classes.id` des classes portant une aptitude de niveau 1
  /// `choice_type = 'sous_classe'` (les lignes d'une sous-classe,
  /// `subclass_id` non nul, sont ignorées).
  static Set<int> collectConcernedClassIds(
    List<Map<String, dynamic>> featureRows,
  ) {
    final ids = <int>{};
    for (final row in featureRows) {
      final classId = row['class_id'];
      if (classId is! num) continue;
      if (row['choice_type'] != 'sous_classe') continue;
      if (row['subclass_id'] != null) continue;
      final level = row['level'];
      if (level is num && level != 1) continue;
      ids.add(classId.toInt());
    }
    return ids;
  }

  /// Identifiants `subclasses.id` (en `String`, clés de `translations`).
  static Set<String> collectSubclassIds(List<Map<String, dynamic>> rows) => {
    for (final row in rows)
      if (row['id'] != null) row['id'].toString(),
  };

  /// Construit le catalogue : chaque classe de [concernedClassIds] est une
  /// clé, avec ses sous-classes de niveau 1 (`available_from_level <= 1`)
  /// dans l'ordre des lignes.
  static SubclassChoiceCatalog toCatalog({
    required Set<int> concernedClassIds,
    required List<Map<String, dynamic>> subclassRows,
    required Map<String, String> names,
    required Map<String, String> descriptions,
  }) {
    final byClass = <int, List<SubclassChoiceOption>>{
      for (final classId in concernedClassIds)
        classId: <SubclassChoiceOption>[],
    };
    for (final row in subclassRows) {
      final id = row['id'];
      final classId = row['class_id'];
      if (id is! num || classId is! num) continue;
      final level = row['available_from_level'];
      if (level is num && level > 1) continue;
      final options = byClass[classId.toInt()];
      if (options == null) continue;
      final description = descriptions[id.toString()]?.trim();
      options.add(
        SubclassChoiceOption(
          id: id.toInt(),
          name: names[id.toString()] ?? 'Sous-classe #$id',
          description: (description == null || description.isEmpty)
              ? null
              : description,
        ),
      );
    }
    return SubclassChoiceCatalog(optionsByClassId: byClass);
  }
}
