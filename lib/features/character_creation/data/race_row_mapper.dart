import '../domain/race_option.dart';
import '../domain/race_trait.dart';
import '../domain/subrace_option.dart';

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
  static RaceOption toRaceOption(
    Map<String, dynamic> row, {
    required Map<String, String> names,
  }) {
    final id = (row['id'] as num).toInt();
    return RaceOption(
      id: id,
      name: names[id.toString()] ?? 'Race #$id',
      abilityBonuses: parseAbilityBonuses(row['ability_bonuses']),
      traits: parseTraits(row['traits']),
    );
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
