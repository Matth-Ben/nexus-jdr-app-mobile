import '../domain/character_class_feature.dart';
import '../domain/character_detail.dart';
import '../domain/character_detail_class_row.dart';
import '../domain/character_inventory_item.dart';
import '../domain/character_skill_row.dart';
import '../domain/character_spell_entry.dart';
import '../domain/character_spell_slot.dart';

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

  /// Identifiants de classe en `int` (pas stringifiés), pour interroger
  /// `class_features.class_id` (`.inFilter`) — distinct de [collectClassIds]
  /// qui stringifie pour `translations.entity_id` (`text`). Une ligne sans
  /// `class_id` exploitable est ignorée.
  static Set<int> collectClassIdsRaw(Map<String, dynamic> row) {
    final ids = <int>{};
    for (final classRow in classRowsOf(row)) {
      final id = classRow['class_id'];
      if (id is num) {
        ids.add(id.toInt());
      }
    }
    return ids;
  }

  /// `{class_id (stringifié): level}` — sert à
  /// `ClassFeatureRowMapper.filterAttained` pour ne garder que les aptitudes
  /// dont le niveau est atteint par la classe correspondante du personnage.
  /// Une classe apparaissant deux fois (ne devrait pas arriver) garde le
  /// niveau de sa dernière occurrence.
  static Map<String, int> collectClassLevels(Map<String, dynamic> row) {
    final levels = <String, int>{};
    for (final classRow in classRowsOf(row)) {
      final classId = classRow['class_id'];
      if (classId == null) continue;
      levels[classId.toString()] = (classRow['level'] as num?)?.toInt() ?? 0;
    }
    return levels;
  }

  static List<Map<String, dynamic>> skillProficiencyRowsOf(
    Map<String, dynamic> row,
  ) {
    final raw = row['character_skill_proficiencies'] as List<dynamic>?;
    return raw?.cast<Map<String, dynamic>>() ?? const [];
  }

  static List<Map<String, dynamic>> toolProficiencyRowsOf(
    Map<String, dynamic> row,
  ) {
    final raw = row['character_tool_proficiencies'] as List<dynamic>?;
    return raw?.cast<Map<String, dynamic>>() ?? const [];
  }

  /// Identifiants d'outils (`character_tool_proficiencies.tool_id`) à
  /// résoudre via `translations`, en `int` (pour `.inFilter`) — une ligne de
  /// maîtrise d'outil personnalisée (`tool_id` nul, `custom_text` renseigné)
  /// n'a rien à résoudre et est donc ignorée ici.
  static Set<int> collectToolIds(List<Map<String, dynamic>> rows) {
    final ids = <int>{};
    for (final row in rows) {
      final toolId = row['tool_id'];
      if (toolId is num) {
        ids.add(toolId.toInt());
      }
    }
    return ids;
  }

  /// Noms d'outils affichables : `custom_text` si renseigné (maîtrise
  /// d'outil hors catalogue), sinon le nom résolu via `translations`
  /// (`toolNames`, voir [collectToolIds]), sinon un libellé générique. Une
  /// ligne sans `tool_id` ni `custom_text` exploitable (ne devrait pas
  /// arriver, contrainte `character_tool_proficiencies_tool_or_custom` côté
  /// base) est ignorée plutôt que de crasher.
  static List<String> parseToolProficiencyNames(
    List<Map<String, dynamic>> rows, {
    required Map<String, String> toolNames,
  }) {
    final names = <String>[];
    for (final row in rows) {
      final customText = row['custom_text'] as String?;
      if (customText != null) {
        names.add(customText);
        continue;
      }
      final toolId = row['tool_id'];
      if (toolId is num) {
        names.add(toolNames[toolId.toInt().toString()] ?? 'Outil #$toolId');
      }
    }
    return names;
  }

  static List<Map<String, dynamic>> languageRowsOf(Map<String, dynamic> row) {
    final raw = row['character_languages'] as List<dynamic>?;
    return raw?.cast<Map<String, dynamic>>() ?? const [];
  }

  /// Identifiants de langues (`character_languages.language_id`) à résoudre
  /// via `translations`, en `int`.
  static Set<int> collectLanguageIds(List<Map<String, dynamic>> rows) {
    final ids = <int>{};
    for (final row in rows) {
      final languageId = row['language_id'];
      if (languageId is num) {
        ids.add(languageId.toInt());
      }
    }
    return ids;
  }

  /// Noms de langues déjà résolus (`languageNames`, voir
  /// [collectLanguageIds]). Une ligne sans `language_id` exploitable est
  /// ignorée.
  static List<String> parseLanguageNames(
    List<Map<String, dynamic>> rows, {
    required Map<String, String> languageNames,
  }) {
    final names = <String>[];
    for (final row in rows) {
      final languageId = row['language_id'];
      if (languageId is num) {
        names.add(
          languageNames[languageId.toInt().toString()] ?? 'Langue #$languageId',
        );
      }
    }
    return names;
  }

  static List<Map<String, dynamic>> characterSpellRowsOf(
    Map<String, dynamic> row,
  ) {
    final raw = row['character_spells'] as List<dynamic>?;
    return raw?.cast<Map<String, dynamic>>() ?? const [];
  }

  static List<Map<String, dynamic>> featureUsesRowsOf(
    Map<String, dynamic> row,
  ) {
    final raw = row['character_feature_uses'] as List<dynamic>?;
    return raw?.cast<Map<String, dynamic>>() ?? const [];
  }

  /// Parse les lignes brutes `character_spell_slots` (slot_level,
  /// slots_total, slots_used) embarquées sous `characters`. Une ligne sans
  /// `slot_level` exploitable est ignorée.
  static List<CharacterSpellSlot> parseSpellSlots(Map<String, dynamic> row) {
    final raw = row['character_spell_slots'] as List<dynamic>?;
    final rows = raw?.cast<Map<String, dynamic>>() ?? const [];
    final slots = <CharacterSpellSlot>[];
    for (final slotRow in rows) {
      final level = (slotRow['slot_level'] as num?)?.toInt();
      if (level == null) continue;
      slots.add(
        CharacterSpellSlot(
          level: level,
          total: (slotRow['slots_total'] as num?)?.toInt() ?? 0,
          used: (slotRow['slots_used'] as num?)?.toInt() ?? 0,
        ),
      );
    }
    return slots;
  }

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
  ///
  /// Les listes de l'onglet "Compétences" ([skills]/[classFeatures]/
  /// [toolProficiencyNames]/[knownLanguageNames]/[spells]/[spellSlots]) et
  /// [inventory] (onglet "Inventaire") sont déjà entièrement construites par
  /// l'appelant (voir `SupabaseCharacterRepository.fetchCharacterDetail`,
  /// `CharacterSkillRowMapper`/`ClassFeatureRowMapper`/
  /// `CharacterSpellRowMapper`/`CharacterInventoryRowMapper`) : elles ont
  /// chacune besoin d'une requête PostgREST supplémentaire
  /// (`skills`/`class_features`/`spells`/résolution des noms d'objets via
  /// `translations`) que ce mapper pur, sans accès réseau, ne peut pas faire
  /// lui-même — toutes optionnelles (défaut liste vide) pour ne pas casser
  /// les tests existants de [toCharacterDetail] qui ne les fournissent pas
  /// encore. La monnaie (`currency_gp`/`pp`/`ep`/`sp`/`cp`) et les 9 champs
  /// texte de l'onglet "Histoire" (`appearance_text`/`traits_text`/...), à
  /// l'inverse, sont de simples colonnes de `characters` : résolues
  /// directement ici, même règle que [xp]/[currentHp].
  static CharacterDetail toCharacterDetail(
    Map<String, dynamic> row, {
    required Map<String, String> raceNames,
    required Map<String, String> subraceNames,
    required Map<String, String> classNames,
    required Map<String, String> backgroundNames,
    required Map<String, String> alignmentNames,
    List<CharacterSkillRow> skills = const [],
    List<CharacterClassFeature> classFeatures = const [],
    List<String> toolProficiencyNames = const [],
    List<String> knownLanguageNames = const [],
    List<CharacterSpellEntry> spells = const [],
    List<CharacterSpellSlot> spellSlots = const [],
    List<CharacterInventoryItem> inventory = const [],
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
      skills: skills,
      classFeatures: classFeatures,
      toolProficiencyNames: toolProficiencyNames,
      knownLanguageNames: knownLanguageNames,
      spells: spells,
      spellSlots: spellSlots,
      currencyGp: (row['currency_gp'] as num?)?.toInt() ?? 0,
      currencyPp: (row['currency_pp'] as num?)?.toInt() ?? 0,
      currencyEp: (row['currency_ep'] as num?)?.toInt() ?? 0,
      currencySp: (row['currency_sp'] as num?)?.toInt() ?? 0,
      currencyCp: (row['currency_cp'] as num?)?.toInt() ?? 0,
      inventory: inventory,
      appearanceText: (row['appearance_text'] as String?) ?? '',
      traitsText: (row['traits_text'] as String?) ?? '',
      idealsText: (row['ideals_text'] as String?) ?? '',
      bondsText: (row['bonds_text'] as String?) ?? '',
      flawsText: (row['flaws_text'] as String?) ?? '',
      backstoryText: (row['backstory_text'] as String?) ?? '',
      alliesText: (row['allies_text'] as String?) ?? '',
      featuresText: (row['features_text'] as String?) ?? '',
      treasureText: (row['treasure_text'] as String?) ?? '',
    );
  }
}
