/// Résout, parmi plusieurs lignes de contenu (`class_features`/
/// `class_options`...) potentiellement dupliquées par édition de règles
/// (chantier "choix d'édition 2014/2024 par personnage", voir
/// `character_creation/domain/character_creation_draft.dart::edition` et
/// `CharacterDetail.edition`), celle qui s'applique à un personnage d'une
/// édition donnée.
///
/// Convention DB (dépôt web, migration de ce chantier) : `edition` est
/// `NULL` sur une ligne qui s'applique aux DEUX éditions (contenu
/// inchangé — ex. Expertise du Roublard), ou vaut `'2014'`/`'2024'` sur une
/// ligne spécifique à cette édition SEULEMENT (contenu qui diffère — ex.
/// Métamagie de l'Ensorceleur, Expertise du Barde). Pour un regroupement de
/// lignes qui partagent une même clé (typiquement `level`), au plus UNE
/// ligne doit rester applicable à un personnage donné : la ligne dont
/// `edition` correspond exactement à la sienne si elle existe, sinon la
/// ligne `edition IS NULL` si elle existe, sinon aucune — une ligne d'une
/// AUTRE édition que la sienne ne doit jamais être retenue par défaut
/// (sans quoi un personnage verrait une règle d'une édition qu'il n'a pas
/// choisie).
abstract final class EditionContentResolver {
  /// [rows] : lignes brutes PostgREST portant au moins une clé `'edition'`
  /// (`String?`). [keyOf] extrait la clé de regroupement (ex.
  /// `row['level']`) — deux lignes de la même clé sont considérées comme des
  /// alternatives l'une de l'autre (une par édition), jamais cumulées :
  /// sans cette étape, un personnage verrait les deux lignes à la fois (ex.
  /// aptitude "Métamagie" dupliquée sur la carte des aptitudes de classe, ou
  /// quota de Métamagie doublé). Résultat non trié (voir l'appelant pour un
  /// tri éventuel, ex. par niveau croissant).
  static List<Map<String, dynamic>> resolve(
    List<Map<String, dynamic>> rows, {
    required String edition,
    required Object? Function(Map<String, dynamic> row) keyOf,
  }) {
    final byKey = <Object?, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      byKey.putIfAbsent(keyOf(row), () => []).add(row);
    }
    final resolved = <Map<String, dynamic>>[];
    for (final group in byKey.values) {
      final matching = group.where((row) => row['edition'] == edition);
      if (matching.isNotEmpty) {
        resolved.add(matching.first);
        continue;
      }
      final fallback = group.where((row) => row['edition'] == null);
      if (fallback.isNotEmpty) resolved.add(fallback.first);
    }
    return resolved;
  }
}
