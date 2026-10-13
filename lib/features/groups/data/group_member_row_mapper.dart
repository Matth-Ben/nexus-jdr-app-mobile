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

  /// [currentUserId]/[currentUserDisplayName] ne servent qu'à résoudre le
  /// [GroupMember.name] d'un membre MJ sans personnage (`character_id`
  /// `null`, voir la doc de classe de [GroupMember]) — **limitation
  /// documentée** : aucune colonne/fonction Postgres n'expose aujourd'hui le
  /// nom de compte d'un AUTRE utilisateur à ce dépôt (contrairement à
  /// `stories_gm_display_name`, propre aux histoires de l'app web) ; un MJ
  /// ne peut donc résoudre son propre nom de compte réel
  /// ([currentUserDisplayName], tiré de `auth.currentUser` côté appelant)
  /// que sur SA PROPRE ligne (`row['user_id'] == currentUserId`) — toute
  /// autre ligne MJ retombe sur le repli `'MJ'`. Signalé au chef de projet
  /// plutôt que résolu silencieusement : une future colonne calculée
  /// analogue à `stories_gm_display_name` (sécurité definer sur
  /// `group_members`) permettrait d'exposer le vrai nom de compte à tous les
  /// membres.
  static GroupMember toGroupMember(
    Map<String, dynamic> row, {
    required Map<String, String> raceNames,
    required Map<String, String> classNames,
    required String currentUserId,
    String? currentUserDisplayName,
  }) {
    final characterId = row['character_id'] as String?;
    final userId = row['user_id'] as String;
    final role = GroupRoleRaw.fromRaw(row['role'] as String?);

    if (characterId == null) {
      return GroupMember(
        userId: userId,
        role: role,
        name: _gameMasterDisplayName(
          userId: userId,
          currentUserId: currentUserId,
          currentUserDisplayName: currentUserDisplayName,
        ),
      );
    }

    final character = _characterOf(row);
    final raceId = character['race_id'];
    final classRows = _classRowsOf(character);
    final primaryClassRow = _primaryClassRow(classRows);
    final classId = primaryClassRow?['class_id'];

    return GroupMember(
      characterId: characterId,
      userId: userId,
      role: role,
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

  /// Voir la doc de [toGroupMember] pour le rationale complet de cette
  /// limitation.
  static String _gameMasterDisplayName({
    required String userId,
    required String currentUserId,
    String? currentUserDisplayName,
  }) {
    if (userId != currentUserId) return 'MJ';
    final trimmed = currentUserDisplayName?.trim();
    return (trimmed == null || trimmed.isEmpty) ? 'MJ' : trimmed;
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
