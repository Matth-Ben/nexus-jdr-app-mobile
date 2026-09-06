import '../domain/group_member.dart';
import '../domain/group_role.dart';

/// Fonctions de mapping pures entre une ligne brute `group_members`
/// (embarquant `characters(character_classes(...))`) renvoyée par PostgREST
/// et [GroupMember] — même principe que `CharacterRowMapper`
/// (`features/characters/data/character_row_mapper.dart`), dupliqué ici
/// plutôt que réutilisé : cette requête n'expose volontairement qu'un
/// sous-ensemble restreint de `characters` (voir la doc de classe de
/// [GroupMember]), distinct du jeu de colonnes de la liste des personnages.
abstract final class GroupMemberRowMapper {
  static Map<String, dynamic> _characterOf(Map<String, dynamic> row) =>
      (row['characters'] as Map<String, dynamic>?) ?? const {};

  static List<Map<String, dynamic>> _classRowsOf(
    Map<String, dynamic> character,
  ) {
    final raw = character['character_classes'] as List<dynamic>?;
    return raw?.cast<Map<String, dynamic>>() ?? const [];
  }

  static Set<String> collectRaceIds(List<Map<String, dynamic>> rows) {
    final ids = <String>{};
    for (final row in rows) {
      final raceId = _characterOf(row)['race_id'];
      if (raceId != null) ids.add(raceId.toString());
    }
    return ids;
  }

  static Set<String> collectClassIds(List<Map<String, dynamic>> rows) {
    final ids = <String>{};
    for (final row in rows) {
      for (final classRow in _classRowsOf(_characterOf(row))) {
        final classId = classRow['class_id'];
        if (classId != null) ids.add(classId.toString());
      }
    }
    return ids;
  }

  static GroupMember toGroupMember(
    Map<String, dynamic> row, {
    required Map<String, String> raceNames,
    required Map<String, String> classNames,
  }) {
    final character = _characterOf(row);
    final raceId = character['race_id'];
    final classRows = _classRowsOf(character);
    final primaryClassRow = _primaryClassRow(classRows);
    final classId = primaryClassRow?['class_id'];

    return GroupMember(
      characterId: row['character_id'] as String,
      userId: row['user_id'] as String,
      role: GroupRoleRaw.fromRaw(row['role'] as String?),
      name: (character['name'] as String?) ?? '',
      portraitUrl: character['portrait_url'] as String?,
      raceName: raceId != null ? raceNames[raceId.toString()] : null,
      className: classId != null ? classNames[classId.toString()] : null,
      level: _totalLevel(classRows),
      currentHp: (character['current_hp'] as num?)?.toInt() ?? 0,
      maxHp: (character['max_hp'] as num?)?.toInt() ?? 0,
      temporaryHp: (character['temporary_hp'] as num?)?.toInt() ?? 0,
      isDead: (character['is_dead'] as bool?) ?? false,
    );
  }

  static int _totalLevel(List<Map<String, dynamic>> classRows) {
    var total = 0;
    for (final row in classRows) {
      total += (row['level'] as num?)?.toInt() ?? 0;
    }
    return total;
  }

  static Map<String, dynamic>? _primaryClassRow(
    List<Map<String, dynamic>> classRows,
  ) {
    if (classRows.isEmpty) return null;
    for (final row in classRows) {
      if (row['is_primary'] == true) return row;
    }
    return classRows.first;
  }
}
