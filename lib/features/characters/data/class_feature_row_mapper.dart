import '../domain/character_class_feature.dart';

/// Fonctions de mapping pures entre les lignes brutes renvoyées par
/// PostgREST (`class_features`, `character_feature_uses`, `translations`) et
/// [CharacterClassFeature], pour la carte "APTITUDES DE CLASSE" de l'onglet
/// Compétences.
///
/// Voir le commentaire de classe de `CharacterSkillRowMapper` pour le
/// rationale de duplication avec les mappers de `character_creation/data/`,
/// et la documentation de classe de [CharacterClassFeature] pour la portée
/// volontairement limitée aux aptitudes de classe (jamais de sous-classe) à
/// cette itération.
abstract final class ClassFeatureRowMapper {
  /// Identifiants (`id`) à résoudre via `translations`, normalisés en
  /// `String`.
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

  /// Ne garde que les lignes `class_features` dont le niveau est atteint par
  /// la classe correspondante — [classLevels] associe un `class_id`
  /// (normalisé en `String`) au niveau de cette classe pour le personnage
  /// (`character_classes.level`). Une ligne dont la classe n'est pas
  /// présente dans [classLevels] (ne devrait pas arriver, la requête
  /// `class_features` est déjà filtrée sur les `class_id` du personnage) est
  /// ignorée par prudence plutôt que de crasher.
  ///
  /// Ne filtre pas explicitement sur `subclass_id is null` : la requête
  /// amont (`SupabaseCharacterRepository.fetchCharacterDetail`) filtre déjà
  /// `class_id in (...)`, ce qui exclut mécaniquement les aptitudes de
  /// sous-classe (`class_id` toujours `null` sur ces lignes-là, voir
  /// `class_features_class_or_subclass` côté migration).
  static List<Map<String, dynamic>> filterAttained(
    List<Map<String, dynamic>> rows, {
    required Map<String, int> classLevels,
  }) {
    final result = <Map<String, dynamic>>[];
    for (final row in rows) {
      final classId = row['class_id'];
      if (classId == null) continue;
      final classLevel = classLevels[classId.toString()];
      if (classLevel == null) continue;
      final featureLevel = (row['level'] as num?)?.toInt() ?? 0;
      if (featureLevel > classLevel) continue;
      result.add(row);
    }
    return result;
  }

  /// `{class_feature_id: uses_remaining}` depuis les lignes brutes
  /// `character_feature_uses` embarquées sous `characters`. Une ligne sans
  /// `class_feature_id`/`uses_remaining` exploitable est ignorée.
  static Map<String, int> parseUsesRemaining(List<Map<String, dynamic>> rows) {
    final result = <String, int>{};
    for (final row in rows) {
      final classFeatureId = row['class_feature_id'];
      final usesRemaining = row['uses_remaining'];
      if (classFeatureId != null && usesRemaining is num) {
        result[classFeatureId.toString()] = usesRemaining.toInt();
      }
    }
    return result;
  }

  /// Construit un [CharacterClassFeature] à partir d'une ligne brute
  /// `class_features` (déjà filtrée par [filterAttained]), des noms déjà
  /// résolus (`names`, voir [collectIds]) et des utilisations déjà résolues
  /// (`usesRemaining`, voir [parseUsesRemaining]). `uses_per_rest` absent ou
  /// de forme inattendue retombe sur une aptitude passive plutôt que de
  /// crasher.
  static CharacterClassFeature toCharacterClassFeature(
    Map<String, dynamic> row, {
    required Map<String, String> names,
    required Map<String, int> usesRemaining,
  }) {
    final id = (row['id'] as num).toInt();
    final usesPerRest = row['uses_per_rest'] as Map<String, dynamic>?;
    final usesMax = (usesPerRest?['amount'] as num?)?.toInt();

    return CharacterClassFeature(
      id: id,
      name: names[id.toString()] ?? 'Aptitude #$id',
      level: (row['level'] as num?)?.toInt() ?? 0,
      usesMax: usesMax,
      usesRemaining: usesMax != null ? usesRemaining[id.toString()] : null,
      restType: usesPerRest?['rest_type'] as String?,
      description: row['description'] as String? ?? '',
    );
  }
}
