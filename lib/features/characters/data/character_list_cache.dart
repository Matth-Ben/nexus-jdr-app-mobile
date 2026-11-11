/// Point unique de connaissance de l'entrée de cache de la liste des
/// personnages (`SupabaseCharacterRepository.fetchCharacters`) : sa clé, et
/// l'emplacement des champs de son payload — même rôle que
/// `CharacterDetailCache` (`character_detail_cache.dart`) pour la fiche
/// ouverte, voir la doc de classe de `SupabaseCharacterRepository` ("Cache
/// hors-ligne de la liste des personnages") pour le rationale complet.
///
/// Contrairement à `CharacterDetailCache`, aucune méthode d'instance n'est
/// nécessaire ici (pas d'équivalent de `applyConfirmedColumns` : une liste
/// n'a pas de colonne confirmée à reporter) — classe utilitaire sans état,
/// même convention que `CharacterRowMapper`/`CharacterListSorter`.
///
/// Cache indépendant de `CharacterDetailCache` : préfixe de clé différent
/// (`character_list:` contre `character_detail:`), jamais de confusion entre
/// les deux.
abstract final class CharacterListCache {
  /// Clé du payload sous laquelle sont rangées les lignes `characters`
  /// brutes (retour PostgREST tel quel) — voir
  /// `SupabaseCharacterRepository.fetchCharacters`.
  static const String characterRowsKey = 'characterRows';

  /// Clé du payload sous laquelle est rangée la map des noms de race déjà
  /// résolue (`{race_id: name}`) — mise en cache déjà résolue (plutôt que
  /// les lignes `translations` brutes) pour éviter de refaire les requêtes
  /// `_fetchTranslatedNames` en cas de repli cache, qui échoueraient aussi
  /// hors-ligne.
  static const String raceNamesKey = 'raceNames';

  /// Clé du payload sous laquelle est rangée la map des noms de classe déjà
  /// résolue (`{class_id: name}`), même rationale que [raceNamesKey].
  static const String classNamesKey = 'classNames';

  /// Noms de sous-classe déjà résolus (`{subclass_id: name}`) — pour la CA
  /// de la carte (P18). Absent d'un ancien payload.
  static const String subclassNamesKey = 'subclassNames';

  /// Noms d'aptitude de classe déjà résolus (`{class_feature_id: name}`) —
  /// pour repérer « Style de combat » (P18). Absent d'un ancien payload.
  static const String classFeatureNamesKey = 'classFeatureNames';

  /// Clé de cache de la liste des personnages du compte [ownerId]. Scopée
  /// par `ownerId` : même rationale ("Isolation par utilisateur") que
  /// `CharacterDetailCache.keyFor` — la liste est une donnée privée
  /// protégée par RLS, jamais une donnée de référence publique.
  static String keyFor({required String ownerId}) => 'character_list:$ownerId';
}
