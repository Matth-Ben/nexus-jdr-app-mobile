import '../domain/class_skill_choices.dart';
import '../domain/race_option.dart';
import '../domain/race_tool_choice.dart';
import '../domain/race_trait.dart';
import '../domain/skill_ability_mapping.dart';
import '../domain/subrace_option.dart';
import '../domain/tool_catalog.dart';

/// Fonctions de mapping pures entre les lignes brutes renvoyées par
/// PostgREST (`races`, `subraces`, `translations`) et les modèles du domaine
/// de l'assistant de création.
///
/// Dédié à `character_creation` plutôt que réutilisé depuis
/// `features/characters/data/character_row_mapper.dart` : le principe de
/// résolution des noms via `translations` est identique (voir ce fichier
/// pour le contexte détaillé du choix), mais dupliqué ici pour ne jamais
/// coupler les deux fonctionnalités entre elles.
abstract final class RaceRowMapper {
  /// Identifiants (`id`) à résoudre via `translations`, normalisés en
  /// `String` (les ids reviennent en `int` de PostgREST, `translations
  /// .entity_id` est `text`).
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
  /// `entity_id`/`value`, PAS `name`) en `{entity_id: value}`. Une ligne sans
  /// `entity_id`/`value` exploitable est ignorée plutôt que de faire
  /// échouer tout le mapping — même règle que
  /// `CharacterRowMapper.parseTranslatedNames`.
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

  /// Parse la colonne jsonb `ability_bonuses` (`{"dex": 2}`, ou avec la clé
  /// spéciale `choice_others`, voir `RaceOption`) en `Map<String, dynamic>`.
  /// `null`/type inattendu retombe sur une map vide plutôt que de crasher.
  static Map<String, dynamic> parseAbilityBonuses(dynamic raw) {
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return const {};
  }

  /// Parse la colonne jsonb `traits` (liste de `{name, description}`) en
  /// `List<RaceTrait>`. Une entrée sans `name` exploitable est ignorée ;
  /// `null`/type inattendu retombe sur une liste vide plutôt que de crasher.
  static List<RaceTrait> parseTraits(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    final traits = <RaceTrait>[];
    for (final item in raw) {
      if (item is Map) {
        final name = item['name'] as String?;
        if (name != null) {
          traits.add(
            RaceTrait(
              name: name,
              description: item['description'] as String? ?? '',
            ),
          );
        }
      }
    }
    return traits;
  }

  /// Construit une [RaceOption] à partir d'une ligne brute `races` et des
  /// noms déjà résolus (`names`, clés en `String`, voir [collectIds]). Un id
  /// sans traduction résolue retombe sur un libellé générique ("Race #12")
  /// plutôt que de crasher ou d'afficher `null`.
  ///
  /// `row['is_incomplete']` absent (cache offline écrit avant l'introduction
  /// de cette colonne) retombe sur `false` — voir [RaceOption.isIncomplete].
  /// `row['source']` absent retombe sur une chaîne vide — voir
  /// [RaceOption.source].
  static RaceOption toRaceOption(
    Map<String, dynamic> row, {
    required Map<String, String> names,

    /// Catalogue d'outils déjà résolu (nom + catégorie), nécessaire pour
    /// développer la forme `categories` — ou l'absence des deux clés
    /// (choix libre) — de `races.tool_choice` en liste plate de noms, voir
    /// [parseToolChoice]. Vide par défaut : un ancien cache offline écrit
    /// avant l'introduction de [RaceOption.toolChoice] n'a jamais ce
    /// catalogue sous la main (voir `data/character_creation_repository.dart
    /// ::_mapRaceCatalogPayload`) — une race avec un vrai `tool_choice` par
    /// catégorie retombe alors sur une liste de candidats vide plutôt que de
    /// crasher (gap assumé, même principe que les autres champs ajoutés
    /// après la première version de ce mapper).
    ToolCatalog toolCatalog = const ToolCatalog(tools: []),
  }) {
    final id = (row['id'] as num).toInt();
    return RaceOption(
      id: id,
      name: names[id.toString()] ?? 'Race #$id',
      abilityBonuses: parseAbilityBonuses(row['ability_bonuses']),
      traits: parseTraits(row['traits']),
      source: row['source'] as String? ?? '',
      isIncomplete: row['is_incomplete'] as bool? ?? false,
      skillChoice: parseSkillChoice(row['skill_choice']),
      toolChoice: parseToolChoice(row['tool_choice'], toolCatalog: toolCatalog),
      skillProficiencies: parseSkillProficiencies(row['skill_proficiencies']),
    );
  }

  /// Parse la colonne jsonb `skill_choice` (`races.skill_choice`) — étape
  /// 5/9 "Compétences et outils", carte "CHOIX DE RACE" de la fiche. `null`
  /// si cette race n'a pas de choix de compétence (la grande majorité).
  /// `choices: null` (choix libre, ex. Demi-elfe/Forgelier/Kenku) est
  /// développée en la liste complète des 18 compétences
  /// ([SkillAbilityMapping.allSkillNames]) — même principe que la forme
  /// `"toutes"` du Barde, voir `ClassRowMapper.parseSkillChoices`. `count`
  /// absent/type inattendu retombe sur `null` (pas de choix affiché) plutôt
  /// que de crasher.
  static ClassSkillChoices? parseSkillChoice(dynamic raw) {
    if (raw is! Map) {
      return null;
    }
    final count = (raw['count'] as num?)?.toInt();
    if (count == null) {
      return null;
    }
    final rawChoices = raw['choices'];
    final choices = rawChoices is List
        ? rawChoices.whereType<String>().toList()
        : SkillAbilityMapping.allSkillNames;
    return ClassSkillChoices(count: count, choices: choices);
  }

  /// Parse la colonne jsonb `tool_choice` (`races.tool_choice`) — même étape/
  /// carte que [parseSkillChoice]. `null` si cette race n'a pas de choix
  /// d'outil (la grande majorité). Trois formes brutes réelles (voir la
  /// documentation de classe de [RaceToolChoice]), toutes développées ici en
  /// liste plate de noms candidats contre [toolCatalog] :
  /// - `choices` (liste de noms exacts, ex. Nain) : reportée telle quelle ;
  /// - `categories` (liste de `tools.category`, ex. Satyre) : tous les outils
  ///   de [toolCatalog] dont la catégorie est dans cette liste ;
  /// - ni l'un ni l'autre (choix libre, ex. Forgelier) : tout [toolCatalog].
  /// `count` absent/type inattendu retombe sur `null`.
  static RaceToolChoice? parseToolChoice(
    dynamic raw, {
    required ToolCatalog toolCatalog,
  }) {
    if (raw is! Map) {
      return null;
    }
    final count = (raw['count'] as num?)?.toInt();
    if (count == null) {
      return null;
    }
    final rawChoices = raw['choices'];
    if (rawChoices is List) {
      return RaceToolChoice(
        count: count,
        choices: rawChoices.whereType<String>().toList(),
      );
    }
    final rawCategories = raw['categories'];
    if (rawCategories is List) {
      final categories = rawCategories.whereType<String>().toSet();
      return RaceToolChoice(
        count: count,
        choices: [
          for (final tool in toolCatalog.tools)
            if (categories.contains(tool.category)) tool.name,
        ],
      );
    }
    return RaceToolChoice(
      count: count,
      choices: [for (final tool in toolCatalog.tools) tool.name],
    );
  }

  /// Parse la colonne `skill_proficiencies` (`races.skill_proficiencies`,
  /// `text[]`) — octroi automatique, PAS un choix (Satyre uniquement à ce
  /// jour). `null`/type inattendu retombe sur une liste vide.
  static List<String> parseSkillProficiencies(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    return raw.whereType<String>().toList();
  }

  /// Construit une [SubraceOption] à partir d'une ligne brute `subraces` et
  /// des noms déjà résolus, mêmes règles que [toRaceOption].
  static SubraceOption toSubraceOption(
    Map<String, dynamic> row, {
    required Map<String, String> names,
  }) {
    final id = (row['id'] as num).toInt();
    return SubraceOption(
      id: id,
      raceId: (row['race_id'] as num).toInt(),
      name: names[id.toString()] ?? 'Sous-race #$id',
      abilityBonuses: parseAbilityBonuses(row['ability_bonuses']),
      traits: parseTraits(row['traits']),
    );
  }
}
