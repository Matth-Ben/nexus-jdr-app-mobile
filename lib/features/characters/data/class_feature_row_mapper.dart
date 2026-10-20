import '../domain/character_class_feature.dart';

/// Fonctions de mapping pures entre les lignes brutes renvoyées par
/// PostgREST (`class_features`, `character_feature_uses`, `translations`) et
/// [CharacterClassFeature], pour la carte "APTITUDES DE CLASSE" de l'onglet
/// Compétences.
///
/// Voir le commentaire de classe de `CharacterSkillRowMapper` pour le
/// rationale de duplication avec les mappers de `character_creation/data/`,
/// et la documentation de classe de [CharacterClassFeature] pour la portée
/// désormais étendue aux aptitudes de sous-classe (bug architectural corrigé,
/// voir [filterAttained]).
abstract final class ClassFeatureRowMapper {
  /// Identifiants (`id`) à résoudre via `translations`, normalisés en
  /// `String`.
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

  /// Ne garde que les lignes `class_features` dont le niveau est atteint —
  /// par la classe correspondante pour une ligne de classe de base
  /// (`row['class_id']` non nul, [classLevels] associe un `class_id`
  /// normalisé en `String` au niveau de cette classe pour le personnage,
  /// `character_classes.level`), ou par la classe QUI PORTE la sous-classe
  /// pour une ligne de sous-classe (`row['subclass_id']` non nul,
  /// [subclassLevels] associe de même un `subclass_id` normalisé en
  /// `String` au niveau de la classe `character_classes` dont c'est la
  /// sous-classe choisie — jamais un niveau de sous-classe séparé, qui
  /// n'existe pas en base : une sous-classe progresse au même rythme que sa
  /// classe).
  ///
  /// **Bug architectural corrigé** (trouvé par l'agent `regles-dnd` en
  /// investiguant le Guerrier Maître de guerre, périmètre élargi à toutes
  /// les sous-classes) : avant ce correctif, toute ligne sans `class_id`
  /// (donc toute aptitude de sous-classe, `class_id`/`subclass_id` étant
  /// mutuellement exclusifs en base) était ignorée sans condition — la carte
  /// "APTITUDES DE CLASSE" n'affichait alors jamais aucune aptitude de
  /// sous-classe, pour aucune sous-classe du jeu. Ce comportement datait
  /// d'avant l'ajout du choix de sous-classe à la montée de niveau (voir
  /// l'historique de ce fichier) ; [subclassLevels] est vide par défaut pour
  /// ne pas casser un appelant qui ne l'a pas encore mis à jour (même
  /// comportement qu'avant ce correctif dans ce cas).
  ///
  /// Une ligne sans `class_id` NI `subclass_id` exploitable (ne devrait pas
  /// arriver), ou dont la classe/sous-classe correspondante n'est pas
  /// présente dans [classLevels]/[subclassLevels] (ne devrait pas arriver
  /// non plus, les requêtes amont filtrent déjà sur les classes/sous-classes
  /// du personnage), est ignorée par prudence plutôt que de crasher.
  ///
  /// Ne filtre jamais sur `choice_type` : une aptitude de sous-classe qui
  /// représente un choix du joueur (ex. "Supériorité martiale" du Maître de
  /// guerre, qui ouvre le choix de manœuvres) apparaît malgré tout sur cette
  /// carte comme texte informatif — même précédent déjà en place pour les
  /// aptitudes de classe de base portant un `choice_type`
  /// (`style_combat`/`ennemi_jure`/`pacte`...), dont la valeur réellement
  /// choisie par le joueur est résolue séparément sur la carte "CHOIX DE
  /// CLASSE" (`domain/character_class_choice.dart`) sans que cela fasse
  /// doublon.
  static List<Map<String, dynamic>> filterAttained(
    List<Map<String, dynamic>> rows, {
    required Map<String, int> classLevels,
    Map<String, int> subclassLevels = const {},
  }) {
    final result = <Map<String, dynamic>>[];
    for (final row in rows) {
      final classId = row['class_id'];
      final subclassId = row['subclass_id'];
      final int? ownerLevel;
      if (classId != null) {
        ownerLevel = classLevels[classId.toString()];
      } else if (subclassId != null) {
        ownerLevel = subclassLevels[subclassId.toString()];
      } else {
        continue;
      }
      if (ownerLevel == null) continue;
      final featureLevel = (row['level'] as num?)?.toInt() ?? 0;
      if (featureLevel > ownerLevel) continue;
      result.add(row);
    }
    return result;
  }

  /// `{class_feature_id: uses_remaining}` depuis les lignes brutes
  /// `character_feature_uses` embarquées sous `characters`. Une ligne sans
  /// `class_feature_id`/`uses_remaining` exploitable est ignorée.
  static Map<String, int> parseUsesRemaining(List<Map<String, dynamic>> rows) {
    final result = <String, int>{};
    for (final row in rows) {
      final classFeatureId = row['class_feature_id'];
      final usesRemaining = row['uses_remaining'];
      if (classFeatureId != null && usesRemaining is num) {
        result[classFeatureId.toString()] = usesRemaining.toInt();
      }
    }
    return result;
  }

  /// Construit un [CharacterClassFeature] à partir d'une ligne brute
  /// `class_features` (déjà filtrée par [filterAttained]), des noms et
  /// descriptions déjà résolus (`names`/`descriptions`, voir [collectIds] —
  /// ni l'un ni l'autre n'est une colonne directe de `class_features`, les
  /// deux vivent dans `translations`) et des utilisations déjà résolues
  /// (`usesRemaining`, voir [parseUsesRemaining]). `uses_per_rest` absent ou
  /// de forme inattendue retombe sur une aptitude passive plutôt que de
  /// crasher.
  static CharacterClassFeature toCharacterClassFeature(
    Map<String, dynamic> row, {
    required Map<String, String> names,
    required Map<String, String> descriptions,
    required Map<String, int> usesRemaining,
  }) {
    final id = (row['id'] as num).toInt();
    final usesPerRest = row['uses_per_rest'] as Map<String, dynamic>?;
    final usesMax = (usesPerRest?['amount'] as num?)?.toInt();

    return CharacterClassFeature(
      id: id,
      name: names[id.toString()] ?? 'Aptitude #$id',
      level: (row['level'] as num?)?.toInt() ?? 0,
      usesMax: usesMax,
      usesRemaining: usesMax != null ? usesRemaining[id.toString()] : null,
      restType: usesPerRest?['rest_type'] as String?,
      description: descriptions[id.toString()] ?? '',
    );
  }
}
