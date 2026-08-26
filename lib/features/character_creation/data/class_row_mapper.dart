import '../domain/class_option.dart';
import '../domain/class_skill_choices.dart';
import '../domain/class_tool_choice.dart';
import '../domain/skill_ability_mapping.dart';

/// Fonctions de mapping pures entre les lignes brutes renvoyées par
/// PostgREST (`classes`, `translations`) et [ClassOption].
///
/// Dédié à l'étape 2/9 (Classe) plutôt que réutilisé depuis
/// `race_row_mapper.dart` : même principe de résolution des noms via
/// `translations` (colonnes réelles `entity_id`/`field_name`/`value`, PAS
/// `name`), mais dupliqué pour ne jamais coupler les deux étapes entre elles
/// — voir le commentaire de classe de `RaceRowMapper` pour le rationale
/// détaillé.
abstract final class ClassRowMapper {
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
  /// `entity_id`/`value` exploitable est ignorée plutôt que de faire échouer
  /// tout le mapping — même règle que `RaceRowMapper.parseTranslatedNames`.
  /// Réutilisé à la fois pour `field_name='name'` et `field_name='description'`
  /// (deux requêtes séparées côté dépôt, voir
  /// `data/character_creation_repository.dart`).
  static Map<String, String> parseTranslatedValues(
    List<Map<String, dynamic>> rawRows,
  ) {
    final values = <String, String>{};
    for (final row in rawRows) {
      final entityId = row['entity_id'] as String?;
      final value = row['value'] as String?;
      if (entityId != null && value != null) {
        values[entityId] = value;
      }
    }
    return values;
  }

  /// Construit une [ClassOption] à partir d'une ligne brute `classes` et des
  /// noms/descriptions déjà résolus (`names`/`descriptions`, clés en
  /// `String`, voir [collectIds]). Un id sans nom résolu retombe sur un
  /// libellé générique ("Classe #12") plutôt que de crasher ou d'afficher
  /// `null` ; une description manquante retombe sur une chaîne vide (même
  /// règle que `RaceRowMapper.parseTraits` pour une description de trait
  /// manquante).
  static ClassOption toClassOption(
    Map<String, dynamic> row, {
    required Map<String, String> names,
    required Map<String, String> descriptions,
  }) {
    final id = (row['id'] as num).toInt();
    return ClassOption(
      id: id,
      name: names[id.toString()] ?? 'Classe #$id',
      description: descriptions[id.toString()] ?? '',
      hitDie: (row['hit_die'] as num).toInt(),
      skillChoices: parseSkillChoices(row['skill_choices']),
      toolChoice: parseToolChoice(row['tool_proficiencies']),
      grantedToolNames: parseGrantedToolNames(row['tool_proficiencies']),
    );
  }

  /// Parse la colonne jsonb `skill_choices` — étape 5/9 "Compétences et
  /// outils". Deux formes réelles constatées en base (voir
  /// `domain/class_skill_choices.dart`) : `{"count": N, "choices": [...]}`
  /// pour la plupart des classes, `{"count": 3, "choices": "toutes"}` pour
  /// le Barde uniquement — dans ce second cas, `choices` est développée ici
  /// en la liste complète des 18 compétences
  /// ([SkillAbilityMapping.allSkillNames]). `null`/type inattendu retombe
  /// sur `count: 0, choices: []` plutôt que de crasher (aucune compétence de
  /// classe ne sera alors proposée, "Suivant" reste atteignable puisque le
  /// quota est 0).
  static ClassSkillChoices parseSkillChoices(dynamic raw) {
    if (raw is! Map) {
      return const ClassSkillChoices(count: 0, choices: []);
    }
    final count = (raw['count'] as num?)?.toInt() ?? 0;
    final rawChoices = raw['choices'];
    final choices = switch (rawChoices) {
      'toutes' => SkillAbilityMapping.allSkillNames,
      List<dynamic> list => list.whereType<String>().toList(),
      _ => const <String>[],
    };
    return ClassSkillChoices(count: count, choices: choices);
  }

  /// `tool_proficiencies.type` -> vraies valeurs de `tools.category`.
  /// `outils_artisan_ou_instrument` n'est *pas* une catégorie réelle de
  /// `tools` (vérifié contre
  /// `supabase/migrations/20260825090500_seed_reference_core_data.sql` du
  /// dépôt web, qui n'a que `outils_artisan`/`instrument`/`jeu`/`autre`) :
  /// c'est une union de deux catégories réelles, d'où la liste.
  static const Map<String, List<String>> _toolTypeToCategories = {
    'instrument': ['instrument'],
    'jeu': ['jeu'],
    'outils_artisan': ['outils_artisan'],
    'outils_artisan_ou_instrument': ['outils_artisan', 'instrument'],
  };

  /// Parse la forme interactive `{"count": N, "type": "..."}` de
  /// `tool_proficiencies` en [ClassToolChoice]. Renvoie `null` pour les deux
  /// autres formes réelles constatées en base (`[]` vide, ou une liste de
  /// noms d'outils précis) — voir [parseGrantedToolNames] pour cette
  /// dernière, et le commentaire de classe de `ClassOption` pour le détail
  /// des trois formes. Un type jsonb inconnu retombe sur une liste de
  /// catégories vide plutôt que de crasher (aucun outil ne sera alors
  /// proposé pour ce choix).
  static ClassToolChoice? parseToolChoice(dynamic raw) {
    if (raw is! Map) {
      return null;
    }
    final count = (raw['count'] as num?)?.toInt();
    final type = raw['type'] as String?;
    if (count == null || type == null) {
      return null;
    }
    return ClassToolChoice(
      count: count,
      categories: _toolTypeToCategories[type] ?? const [],
    );
  }

  /// Parse la forme "liste de noms d'outils précis" de `tool_proficiencies`
  /// (ex. Druide : `["outils d'herboriste"]`, Roublard : `["outils de
  /// voleur"]`) — un octroi automatique, pas un choix, contrairement à la
  /// forme `{"count", "type"}` de [parseToolChoice]. Cette troisième forme
  /// n'était pas anticipée dans la consigne d'origine de la tâche qui a
  /// ajouté ce parsing (qui n'en documentait que deux) : constatée en
  /// relisant `supabase/migrations/20260825090700_seed_classes_subclasses_features.sql`
  /// du dépôt web avant d'écrire ce code, et signalée au chef de projet
  /// plutôt que silencieusement ignorée. `null`/type inattendu (y compris un
  /// objet `{"count", "type"}`, qui n'est pas une `List`) retombe sur une
  /// liste vide.
  static List<String> parseGrantedToolNames(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    return raw.whereType<String>().toList();
  }
}
