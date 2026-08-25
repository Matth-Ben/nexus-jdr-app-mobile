import '../domain/character_class_row.dart';
import '../domain/character_summary.dart';

/// Fonctions de mapping pures entre les lignes brutes renvoyées par
/// PostgREST (`characters`, `character_classes`, `translations`) et les
/// modèles du domaine.
///
/// Extraites de `SupabaseCharacterRepository` (`character_repository.dart`)
/// pour rester testables sans réseau ni double de `SupabaseClient` : c'est
/// précisément à ce niveau qu'un bug (mauvaise colonne `translations`,
/// mismatch de type `int`/`text` entre `race_id`/`class_id` côté
/// `characters` et `entity_id` côté `translations`) est passé inaperçu, les
/// tests de widget n'exerçant jamais le vrai chemin Supabase → `CharacterSummary`
/// (ils injectent un `CharacterRepository` factice qui renvoie déjà des
/// `CharacterSummary` tout construits).
abstract final class CharacterRowMapper {
  /// Lignes `character_classes` imbriquées dans une ligne `characters`
  /// (résultat du `select` avec relation imbriquée PostgREST).
  static List<Map<String, dynamic>> classRowsOf(
    Map<String, dynamic> characterRow,
  ) {
    final raw = characterRow['character_classes'] as List<dynamic>?;
    return raw?.cast<Map<String, dynamic>>() ?? const [];
  }

  /// Identifiants de race à résoudre via `translations`, normalisés en
  /// `String` (`race_id` revient en `int` de PostgREST, `translations.entity_id`
  /// est `text`).
  static Set<String> collectRaceIds(List<Map<String, dynamic>> characterRows) {
    final ids = <String>{};
    for (final row in characterRows) {
      final raceId = row['race_id'];
      if (raceId != null) {
        ids.add(raceId.toString());
      }
    }
    return ids;
  }

  /// Identifiants de classe à résoudre via `translations`, mêmes règles de
  /// normalisation que [collectRaceIds].
  static Set<String> collectClassIds(List<Map<String, dynamic>> characterRows) {
    final ids = <String>{};
    for (final row in characterRows) {
      for (final classRow in classRowsOf(row)) {
        final classId = classRow['class_id'];
        if (classId != null) {
          ids.add(classId.toString());
        }
      }
    }
    return ids;
  }

  /// Parse les lignes brutes de `translations` (colonnes réelles
  /// `entity_id`/`value`, PAS `name` — voir
  /// `20260825090050_create_translations_table.sql` côté dépôt web) en
  /// `{entity_id: value}`. Une ligne sans `entity_id`/`value` exploitable est
  /// ignorée plutôt que de faire échouer tout le mapping.
  static Map<String, String> parseTranslatedNames(
    List<Map<String, dynamic>> rawRows,
  ) {
    final names = <String, String>{};
    for (final row in rawRows) {
      final entityId = row['entity_id'] as String?;
      final name = row['value'] as String?;
      if (entityId != null && name != null) {
        names[entityId] = name;
      }
    }
    return names;
  }

  /// Construit un [CharacterSummary] à partir d'une ligne brute `characters`
  /// (avec ses `character_classes` imbriquées) et des noms déjà résolus
  /// (`raceNames`/`classNames`, clés en `String`, voir [collectRaceIds]).
  static CharacterSummary toSummary(
    Map<String, dynamic> row, {
    required Map<String, String> raceNames,
    required Map<String, String> classNames,
  }) {
    final classRows = classRowsOf(row)
        .where((classRow) => classRow['class_id'] != null)
        .map(
          (classRow) => CharacterClassRow(
            classId: classRow['class_id'] as Object,
            level: (classRow['level'] as num?)?.toInt() ?? 0,
            isPrimary: classRow['is_primary'] == true,
          ),
        )
        .toList();

    final totalLevel = CharacterClassesSummary.totalLevel(classRows);
    final primaryClassId = CharacterClassesSummary.primaryClassId(classRows);

    final raceId = row['race_id'];

    return CharacterSummary(
      id: row['id'] as String,
      name: row['name'] as String,
      portraitUrl: row['portrait_url'] as String?,
      raceName: raceId != null ? raceNames[raceId.toString()] : null,
      className: primaryClassId != null
          ? classNames[primaryClassId.toString()]
          : null,
      // Un personnage sans ligne `character_classes` (donnée incohérente,
      // ne devrait pas arriver) est traité comme niveau 1 plutôt que 0, pour
      // ne jamais afficher une jauge XP ni un libellé de niveau absurdes.
      level: totalLevel > 0 ? totalLevel : 1,
      xp: (row['xp'] as num?)?.toInt() ?? 0,
    );
  }
}
