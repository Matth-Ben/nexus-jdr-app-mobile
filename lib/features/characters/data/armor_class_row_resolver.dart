import '../domain/armor_class_resolver.dart';
import 'character_inventory_row_mapper.dart';

/// Résout la Classe d'Armure depuis une ligne `characters` PostgREST brute
/// embarquant `character_classes`, `character_ability_scores`,
/// `character_class_options`, `character_inventory(... items(...
/// armor_properties(...)))` et `armor_class_bonus` — partagé par
/// `GroupMemberRowMapper` (onglet « Membres ») et `CharacterRowMapper` (liste
/// des personnages, P18) pour ne jamais copier cette logique (la fiche passe
/// par `ArmorClassResolver` directement, avec des données déjà typées).
abstract final class ArmorClassRowResolver {
  /// `armor_class_bonus`, 0 si absent.
  static int bonusOf(Map<String, dynamic> character) =>
      (character['armor_class_bonus'] as num?)?.toInt() ?? 0;

  /// `true` si [character] embarque les données nécessaires au calcul (les
  /// scores de caractéristiques). Absent d'un ancien payload de cache de la
  /// liste, écrit avant P18 : la CA est alors inconnue, jamais devinée.
  static bool hasData(Map<String, dynamic> character) =>
      character['character_ability_scores'] is List;

  /// CA finale (calcul RAW + bonus manuel). [classNames]/[subclassNames]/
  /// [classFeatureNames] : noms déjà résolus (clés `String`, voir
  /// `translations`).
  static int fromCharacterRow(
    Map<String, dynamic> character, {
    required Map<String, String> classNames,
    required Map<String, String> subclassNames,
    required Map<String, String> classFeatureNames,
  }) {
    final classRows = _rows(character['character_classes']);
    return ArmorClassResolver.resolve(
      abilityScores: _abilityScores(character),
      inventory: CharacterInventoryRowMapper.toCharacterInventoryItems(
        _rows(character['character_inventory']),
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
      bonus: bonusOf(character),
    );
  }

  static List<Map<String, dynamic>> _rows(Object? raw) =>
      (raw as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? const [];

  /// `{ability_id: score}` depuis `character_ability_scores`.
  static Map<String, int> _abilityScores(Map<String, dynamic> character) {
    final scores = <String, int>{};
    for (final row in _rows(character['character_ability_scores'])) {
      final abilityId = row['ability_id'] as String?;
      final score = (row['score'] as num?)?.toInt();
      if (abilityId != null && score != null) scores[abilityId] = score;
    }
    return scores;
  }

  /// `chosen_value` des `character_class_options` dont l'aptitude est
  /// « Style de combat » — seul filtre fiable avant de chercher « Défense »
  /// (`character_class_options` sert aussi à de nombreux autres choix).
  static Set<String> _fightingStyles(
    Map<String, dynamic> character,
    Map<String, String> classFeatureNames,
  ) {
    final styles = <String>{};
    for (final row in _rows(character['character_class_options'])) {
      final classFeatureId = row['class_feature_id'];
      final chosenValue = row['chosen_value'] as String?;
      if (classFeatureId == null || chosenValue == null) continue;
      if (classFeatureNames[classFeatureId.toString()] == 'Style de combat') {
        styles.add(chosenValue);
      }
    }
    return styles;
  }
}
