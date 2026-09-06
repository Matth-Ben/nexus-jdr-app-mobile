import '../domain/level_up_feat_option.dart';

/// Fonctions de mapping pures entre les lignes brutes `feats`/`translations`
/// renvoyées par PostgREST et [LevelUpFeatOption], pour l'étape "Choix à
/// faire" de la montée de niveau, sous-mode "don" — voir
/// `SupabaseCharacterRepository.fetchAvailableFeats`.
///
/// Duplicata volontaire de `LevelUpInvocationRowMapper` (même structure
/// `prerequisites` jsonb, même résolution `translations`) — même rationale
/// que le reste de ce dépôt : ne jamais coupler deux entités de référence
/// entre elles pour un bout de logique de mapping partagée.
abstract final class LevelUpFeatRowMapper {
  /// Identifiants (`feats.id`) à résoudre via `translations`, normalisés en
  /// `String` — même principe que `LevelUpChoiceRowMapper.collectSubclassIds`.
  static Set<String> collectFeatIds(List<Map<String, dynamic>> rows) {
    final ids = <String>{};
    for (final row in rows) {
      final id = row['id'];
      if (id != null) {
        ids.add(id.toString());
      }
    }
    return ids;
  }

  /// Extrait `prerequisites->>'text'` d'une ligne `feats` brute — `null` si
  /// la clé `text` est absente, vide, ou si `prerequisites` n'est pas un
  /// objet JSON (défensif, ne devrait jamais arriver : colonne `jsonb not
  /// null default '{}'`).
  static String? prerequisiteTextFor(Map<String, dynamic> row) {
    final prerequisites = row['prerequisites'];
    if (prerequisites is Map) {
      final text = prerequisites['text'];
      if (text is String && text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  /// Construit les [LevelUpFeatOption] à partir des lignes brutes `feats`
  /// (déjà filtrées pour exclure les dons possédés, voir
  /// `SupabaseCharacterRepository.fetchAvailableFeats`) et des
  /// noms/descriptions déjà résolus (`names`/`descriptions`, voir
  /// [collectFeatIds]) — triées alphabétiquement (cohérent avec le catalogue
  /// de sorts, voir la spec visuelle direction-artistique section 2).
  static List<LevelUpFeatOption> toFeatOptions(
    List<Map<String, dynamic>> rows, {
    required Map<String, String> names,
    required Map<String, String> descriptions,
  }) {
    final options = [
      for (final row in rows)
        if (row['id'] != null)
          LevelUpFeatOption(
            id: row['id'] as Object,
            name: names[row['id'].toString()] ?? 'Don #${row['id']}',
            description: descriptions[row['id'].toString()] ?? '',
            prerequisiteText: prerequisiteTextFor(row),
          ),
    ]..sort((a, b) => a.name.compareTo(b.name));
    return options;
  }
}
