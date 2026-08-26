import '../domain/character_detail.dart';
import '../domain/character_detail_class_row.dart';

/// Fonctions de mapping pures entre la ligne brute `characters` (avec ses
/// relations imbriquées `character_classes`/`character_ability_scores`)
/// renvoyée par PostgREST et [CharacterDetail].
///
/// Dédié à la fiche personnage plutôt que réutilisé/étendu depuis
/// `character_row_mapper.dart` (liste des personnages) : même principe de
/// résolution des noms via `translations`, mais un jeu de colonnes bien plus
/// large — voir le commentaire de classe de `RaceRowMapper`
/// (`character_creation/data/race_row_mapper.dart`) pour le rationale
/// détaillé de cette duplication systématique dans ce dépôt.
///
/// `character_classes.classes.saving_throw_proficiencies` est embarqué via
/// une vraie relation de clé étrangère (`character_classes.class_id ->
/// classes.id`), contrairement à `race_id`/`subrace_id`/`background_id`/
/// `alignment_id`/`class_id` eux-mêmes : leurs *noms* restent résolus via la
/// table polymorphe `translations`, que PostgREST ne peut pas embarquer
/// automatiquement (voir `character_repository.dart`).
abstract final class CharacterDetailRowMapper {
  static List<Map<String, dynamic>> classRowsOf(Map<String, dynamic> row) {
    final raw = row['character_classes'] as List<dynamic>?;
    return raw?.cast<Map<String, dynamic>>() ?? const [];
  }

  static List<Map<String, dynamic>> abilityScoreRowsOf(
    Map<String, dynamic> row,
  ) {
    final raw = row['character_ability_scores'] as List<dynamic>?;
    return raw?.cast<Map<String, dynamic>>() ?? const [];
  }

  static Set<String> collectRaceIds(Map<String, dynamic> row) =>
      _singletonIdSet(row['race_id']);

  static Set<String> collectSubraceIds(Map<String, dynamic> row) =>
      _singletonIdSet(row['subrace_id']);

  static Set<String> collectBackgroundIds(Map<String, dynamic> row) =>
      _singletonIdSet(row['background_id']);

  static Set<String> collectAlignmentIds(Map<String, dynamic> row) =>
      _singletonIdSet(row['alignment_id']);

  static Set<String> collectClassIds(Map<String, dynamic> row) {
    final ids = <String>{};
    for (final classRow in classRowsOf(row)) {
      final id = classRow['class_id'];
      if (id != null) {
        ids.add(id.toString());
      }
    }
    return ids;
  }

  static Set<String> _singletonIdSet(dynamic id) =>
      id != null ? {id.toString()} : const {};

  /// Parse `classes.saving_throw_proficiencies` (jsonb, ex. `["wis",
  /// "cha"]`) embarqué sous la clé `classes` d'une ligne `character_classes`.
  /// `null`/type inattendu retombe sur une liste vide plutôt que de crasher.
  static List<String> parseSavingThrowProficiencies(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<String>().toList();
  }

  /// Construit les [CharacterDetailClassRow] d'un personnage à partir de ses
  /// lignes `character_classes` brutes et des noms de classe déjà résolus.
  /// Une ligne sans `class_id` exploitable est ignorée plutôt que de faire
  /// échouer tout le mapping.
  static List<CharacterDetailClassRow> parseClasses(
    Map<String, dynamic> row, {
    required Map<String, String> classNames,
  }) {
    final rows = <CharacterDetailClassRow>[];
    for (final classRow in classRowsOf(row)) {
      final classId = classRow['class_id'];
      if (classId == null) continue;
      final key = classId.toString();
      final nestedClass = classRow['classes'] as Map<String, dynamic>?;
      rows.add(
        CharacterDetailClassRow(
          classId: classId as Object,
          className: classNames[key] ?? 'Classe #$key',
          level: (classRow['level'] as num?)?.toInt() ?? 0,
          isPrimary: classRow['is_primary'] == true,
          savingThrowProficiencies: parseSavingThrowProficiencies(
            nestedClass?['saving_throw_proficiencies'],
          ),
        ),
      );
    }
    return rows;
  }

  /// Parse les lignes `character_ability_scores` (`ability_id`/`score`) en
  /// `{ability_id: score}`. Une ligne sans `ability_id`/`score` exploitable
  /// est ignorée plutôt que de faire échouer tout le mapping.
  static Map<String, int> parseAbilityScores(Map<String, dynamic> row) {
    final scores = <String, int>{};
    for (final scoreRow in abilityScoreRowsOf(row)) {
      final abilityId = scoreRow['ability_id'] as String?;
      final score = (scoreRow['score'] as num?)?.toInt();
      if (abilityId != null && score != null) {
        scores[abilityId] = score;
      }
    }
    return scores;
  }

  /// Construit un [CharacterDetail] à partir de la ligne brute `characters`
  /// et des noms déjà résolus (`translations`) — clés en `String`, voir
  /// [collectRaceIds]/[collectSubraceIds]/[collectClassIds]/
  /// [collectBackgroundIds]/[collectAlignmentIds].
  static CharacterDetail toCharacterDetail(
    Map<String, dynamic> row, {
    required Map<String, String> raceNames,
    required Map<String, String> subraceNames,
    required Map<String, String> classNames,
    required Map<String, String> backgroundNames,
    required Map<String, String> alignmentNames,
  }) {
    final raceId = row['race_id'];
    final subraceId = row['subrace_id'];
    final backgroundId = row['background_id'];
    final alignmentId = row['alignment_id'];

    return CharacterDetail(
      id: row['id'] as String,
      name: row['name'] as String,
      portraitUrl: row['portrait_url'] as String?,
      raceName: raceId != null ? raceNames[raceId.toString()] : null,
      subraceName: subraceId != null
          ? subraceNames[subraceId.toString()]
          : null,
      raceCustomText: row['race_custom_text'] as String?,
      backgroundName: backgroundId != null
          ? backgroundNames[backgroundId.toString()]
          : null,
      alignmentName: alignmentId != null
          ? alignmentNames[alignmentId.toString()]
          : null,
      classes: parseClasses(row, classNames: classNames),
      xp: (row['xp'] as num?)?.toInt() ?? 0,
      currentHp: (row['current_hp'] as num?)?.toInt() ?? 0,
      maxHp: (row['max_hp'] as num?)?.toInt() ?? 0,
      temporaryHp: (row['temporary_hp'] as num?)?.toInt() ?? 0,
      abilityScores: parseAbilityScores(row),
    );
  }
}
