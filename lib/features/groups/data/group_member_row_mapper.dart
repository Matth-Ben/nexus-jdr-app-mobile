import '../../characters/data/character_inventory_row_mapper.dart';
import '../../characters/domain/armor_class_calculator.dart';
import '../domain/group_member.dart';
import '../domain/group_role.dart';

/// Fonctions de mapping pures entre une ligne brute `group_members`
/// (embarquant `characters(character_classes(...))`) renvoyée par PostgREST
/// et [GroupMember] — même principe que `CharacterRowMapper`
/// (`features/characters/data/character_row_mapper.dart`), dupliqué ici
/// plutôt que réutilisé : cette requête n'expose volontairement qu'un
/// sous-ensemble restreint de `characters` (voir la doc de classe de
/// [GroupMember]), distinct du jeu de colonnes de la liste des personnages.
///
/// **Exception à cette discipline, pour [GroupMember.armorClass] /
/// [GroupMember.armorClassBonus] uniquement** (tuile "CA" de l'onglet
/// "Membres") : `GroupRepository.fetchGroupDetail` embarque aussi
/// `character_ability_scores`/`character_inventory`
/// (avec `items`/`armor_properties`)/`character_class_options`
/// (autorisés en lecture pour un coéquipier par les 3 policies RLS dédiées,
/// même fonction `group_member_can_read_character` que
/// `characters`/`character_classes`) — ce mapper les consomme pour calculer
/// la CA via [ArmorClassCalculator.compute] (source de vérité unique,
/// réutilisée telle quelle), mais ne les expose JAMAIS en tant que champs
/// bruts sur [GroupMember] : seul l'entier déjà calculé est exposé, même
/// discipline "sous-ensemble restreint" que le reste de ce fichier.
abstract final class GroupMemberRowMapper {
  static Map<String, dynamic> _characterOf(Map<String, dynamic> row) =>
      (row['characters'] as Map<String, dynamic>?) ?? const {};

  static List<Map<String, dynamic>> _classRowsOf(
    Map<String, dynamic> character,
  ) {
    final raw = character['character_classes'] as List<dynamic>?;
    return raw?.cast<Map<String, dynamic>>() ?? const [];
  }

  static List<Map<String, dynamic>> _abilityScoreRowsOf(
    Map<String, dynamic> character,
  ) {
    final raw = character['character_ability_scores'] as List<dynamic>?;
    return raw?.cast<Map<String, dynamic>>() ?? const [];
  }

  static List<Map<String, dynamic>> _classOptionRowsOf(
    Map<String, dynamic> character,
  ) {
    final raw = character['character_class_options'] as List<dynamic>?;
    return raw?.cast<Map<String, dynamic>>() ?? const [];
  }

  static List<Map<String, dynamic>> _inventoryRowsOf(
    Map<String, dynamic> character,
  ) {
    final raw = character['character_inventory'] as List<dynamic>?;
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

  /// Identifiants de sous-classe (`character_classes.subclass_id`) de tous
  /// les membres, pour résoudre les noms de sous-classe nécessaires à
  /// [ArmorClassCalculator.compute] (Résilience draconique, Lignage
  /// draconique) — même principe que [collectClassIds].
  static Set<String> collectSubclassIds(List<Map<String, dynamic>> rows) {
    final ids = <String>{};
    for (final row in rows) {
      for (final classRow in _classRowsOf(_characterOf(row))) {
        final subclassId = classRow['subclass_id'];
        if (subclassId != null) ids.add(subclassId.toString());
      }
    }
    return ids;
  }

  /// Identifiants d'aptitude de classe (`character_class_options
  /// .class_feature_id`) de tous les membres, pour résoudre lesquels
  /// portent le nom "Style de combat" — seul filtre fiable avant de chercher
  /// `chosen_value == 'Défense'` (voir `CharacterDetail.armorClass`, même
  /// garde-fou de régression : `character_class_options` est une table
  /// partagée par de nombreux autres choix de classe qui peuvent aussi
  /// valoir littéralement "Défense").
  static Set<String> collectClassFeatureIds(List<Map<String, dynamic>> rows) {
    final ids = <String>{};
    for (final row in rows) {
      for (final optionRow in _classOptionRowsOf(_characterOf(row))) {
        final classFeatureId = optionRow['class_feature_id'];
        if (classFeatureId != null) ids.add(classFeatureId.toString());
      }
    }
    return ids;
  }

  /// Lit la colonne calculée PostgREST `group_members_display_name` (voir la
  /// doc de classe de [GroupMember]) — résout le nom de compte de
  /// N'IMPORTE QUEL membre, contrairement à l'ancien mécanisme limité au MJ
  /// lui-même. [row] doit porter cette colonne sous la clé `display_name`
  /// (alias posé par `GroupRepository.fetchGroupDetail`).
  static GroupMember toGroupMember(
    Map<String, dynamic> row, {
    required Map<String, String> raceNames,
    required Map<String, String> classNames,
    Map<String, String> subclassNames = const {},
    Map<String, String> classFeatureNames = const {},
  }) {
    final characterId = row['character_id'] as String?;
    final userId = row['user_id'] as String;
    final role = GroupRoleRaw.fromRaw(row['role'] as String?);
    final isGameMaster = row['is_game_master'] as bool? ?? false;

    if (characterId == null) {
      return GroupMember(
        userId: userId,
        role: role,
        isGameMaster: isGameMaster,
        name: _accountDisplayName(row, isGameMaster: isGameMaster),
        accountDisplayName: _trimmedDisplayName(row),
      );
    }

    final character = _characterOf(row);
    final raceId = character['race_id'];
    final classRows = _classRowsOf(character);
    final primaryClassRow = _primaryClassRow(classRows);
    final classId = primaryClassRow?['class_id'];

    final armorClassBonus =
        (character['armor_class_bonus'] as num?)?.toInt() ?? 0;
    final baseArmorClass = ArmorClassCalculator.compute(
      abilityScores: _parseAbilityScores(character),
      inventory: CharacterInventoryRowMapper.toCharacterInventoryItems(
        _inventoryRowsOf(character),
        names: const {},
        descriptions: const {},
      ),
      classNames: {
        for (final classRow in classRows)
          ?classNames[classRow['class_id']?.toString()],
      },
      subclassNames: {
        for (final classRow in classRows)
          ?subclassNames[classRow['subclass_id']?.toString()],
      },
      fightingStyles: _fightingStyles(character, classFeatureNames),
    );

    return GroupMember(
      characterId: characterId,
      userId: userId,
      role: role,
      isGameMaster: isGameMaster,
      name: (character['name'] as String?) ?? '',
      portraitUrl: character['portrait_url'] as String?,
      raceName: raceId != null ? raceNames[raceId.toString()] : null,
      className: classId != null ? classNames[classId.toString()] : null,
      level: _totalLevel(classRows),
      currentHp: (character['current_hp'] as num?)?.toInt() ?? 0,
      maxHp: (character['max_hp'] as num?)?.toInt() ?? 0,
      temporaryHp: (character['temporary_hp'] as num?)?.toInt() ?? 0,
      isDead: (character['is_dead'] as bool?) ?? false,
      armorClass: baseArmorClass + armorClassBonus,
      armorClassBonus: armorClassBonus,
    );
  }

  /// Parse `character_ability_scores` (`ability_id`/`score`) en
  /// `{ability_id: score}` — même règle que
  /// `CharacterDetailRowMapper.parseAbilityScores`, dupliquée ici (voir le
  /// rationale de duplication de la doc de classe de ce fichier).
  static Map<String, int> _parseAbilityScores(Map<String, dynamic> character) {
    final scores = <String, int>{};
    for (final scoreRow in _abilityScoreRowsOf(character)) {
      final abilityId = scoreRow['ability_id'] as String?;
      final score = (scoreRow['score'] as num?)?.toInt();
      if (abilityId != null && score != null) {
        scores[abilityId] = score;
      }
    }
    return scores;
  }

  /// `chosen_value` de tous les `character_class_options` dont
  /// [classFeatureNames] résout `class_feature_id` en "Style de combat" —
  /// voir la doc de [collectClassFeatureIds] pour le rationale de ce filtre
  /// (régression connue de `CharacterDetail.armorClass`).
  static Set<String> _fightingStyles(
    Map<String, dynamic> character,
    Map<String, String> classFeatureNames,
  ) {
    final styles = <String>{};
    for (final optionRow in _classOptionRowsOf(character)) {
      final classFeatureId = optionRow['class_feature_id'];
      final chosenValue = optionRow['chosen_value'] as String?;
      if (classFeatureId == null || chosenValue == null) continue;
      if (classFeatureNames[classFeatureId.toString()] == 'Style de combat') {
        styles.add(chosenValue);
      }
    }
    return styles;
  }

  /// `null`/vide une fois `trim()` -> `null` — jamais une chaîne blanche
  /// exploitée comme un nom résolu.
  static String? _trimmedDisplayName(Map<String, dynamic> row) {
    final raw = row['display_name'] as String?;
    final trimmed = raw?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  /// Nom affiché pour un membre sans personnage ([GroupMember.characterId]
  /// `null`, MJ volontaire ou orphelin) — voir la doc de [toGroupMember].
  /// Replis distincts selon le rôle réel : jamais `'MJ'` pour un orphelin
  /// (sémantiquement faux, voir la doc de classe de [GroupMember]).
  static String _accountDisplayName(
    Map<String, dynamic> row, {
    required bool isGameMaster,
  }) {
    final name = _trimmedDisplayName(row);
    if (name != null) return name;
    return isGameMaster ? 'MJ' : "En attente d'un personnage";
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
