import '../../../core/utils/french_text_normalizer.dart';
import 'character_detail_class_row.dart';

/// Sous-classes « tiers-lanceurs » dont l'aptitude Incantation existe en
/// règle mais n'est PAS gérée par l'app (ni emplacements, ni liste de sorts) :
/// limitation tracée dans `docs/dette-technique.md`. Sert uniquement à choisir
/// le message de l'onglet « Sorts » (V2-5) ; aucune règle de calcul n'en
/// dépend.
abstract final class UnsupportedCasterSubclasses {
  /// Classe (nom français) -> sous-classe (nom français) tiers-lanceuse.
  static const Map<String, String> byClass = {
    'Guerrier': 'Chevalier occulte',
    'Roublard': 'Escroc arcanique',
  };

  /// `true` si [row] est une classe dont la sous-classe choisie est un
  /// tiers-lanceur non géré (comparaison sans accents ni casse).
  static bool matches(CharacterDetailClassRow row) {
    final subclass = row.subclassName;
    if (subclass == null) return false;
    final className = FrenchTextNormalizer.normalize(row.className);
    final subclassKey = FrenchTextNormalizer.normalize(subclass);
    for (final entry in byClass.entries) {
      if (FrenchTextNormalizer.normalize(entry.key) == className &&
          FrenchTextNormalizer.normalize(entry.value) == subclassKey) {
        return true;
      }
    }
    return false;
  }

  /// `true` si au moins une des [rows] est un tiers-lanceur non géré.
  static bool anyMatches(Iterable<CharacterDetailClassRow> rows) =>
      rows.any(matches);
}
