import '../../../core/utils/french_text_normalizer.dart';

/// Les huit écoles de magie, identifiées par une clé indépendante de la langue.
///
/// `spells.school` est un texte libre stocké en FRANÇAIS dans les seeds
/// (« Évocation », « Invocation », « Enchantement », « Nécromancie »...), avec
/// quelques variantes (« Conjuration » dans le seed de base pour l'école que le
/// reste du catalogue appelle « Invocation »). Un filtre ne doit donc jamais
/// comparer le libellé brut : il passe par [SpellSchool.fromStored], qui
/// ramène FR et EN (et les variantes d'accent/casse) sur la même valeur.
enum SpellSchool {
  abjuration,
  conjuration,
  divination,
  enchantment,
  evocation,
  illusion,
  necromancy,
  transmutation;

  /// Clés normalisées (sans accent, minuscules) reconnues, FR et EN.
  static const Map<String, SpellSchool> _byNormalizedName = {
    'abjuration': abjuration,
    'invocation': conjuration,
    'conjuration': conjuration,
    'divination': divination,
    'enchantement': enchantment,
    'enchantment': enchantment,
    'evocation': evocation,
    'illusion': illusion,
    'necromancie': necromancy,
    'necromancy': necromancy,
    'transmutation': transmutation,
  };

  /// École correspondant à la valeur stockée [stored] (`spells.school`), ou
  /// `null` si elle est vide ou inconnue (un sort sans école ne correspond
  /// alors à aucun filtre d'école).
  static SpellSchool? fromStored(String? stored) {
    if (stored == null) return null;
    return _byNormalizedName[FrenchTextNormalizer.normalize(stored)];
  }
}
