import 'pact_weapon_option.dart';

/// Règles pures de la feuille « FORME DE L'ARME » (Pacte de la lame) :
/// éligibilité, tri et recherche — comparaisons sans accents ni casse.
abstract final class PactWeaponRules {
  static const Map<String, String> _accents = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a', //
    'ç': 'c', //
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', //
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', //
    'ñ': 'n', //
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o', //
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', //
    'ý': 'y', 'ÿ': 'y', //
    'œ': 'oe', 'æ': 'ae', //
  };

  /// Minuscule et sans diacritiques (ex. « Épée » -> « epee »).
  static String normalize(String value) {
    final lower = value.trim().toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_accents[char] ?? char);
    }
    return buffer.toString();
  }

  /// Une arme de pacte est une arme de corps à corps : `category == 'arme'`,
  /// un dé de dégâts, et aucune propriété « munitions » (peut être suffixée,
  /// ex. « munitions(24/96) ») — exclut arcs, arbalètes, fronde, sarbacane
  /// et filet.
  static bool isEligible({
    required String? category,
    required String? damageDice,
    required List<String> properties,
  }) {
    if (category != 'arme') return false;
    if (damageDice == null || damageDice.trim().isEmpty) return false;
    return !properties.any(
      (property) => normalize(property).startsWith('munitions'),
    );
  }

  /// Copie triée par nom (sans accents ni casse).
  static List<PactWeaponOption> sortByName(List<PactWeaponOption> options) {
    final sorted = [...options];
    sorted.sort((a, b) {
      final byName = normalize(a.name).compareTo(normalize(b.name));
      return byName != 0 ? byName : a.id.compareTo(b.id);
    });
    return sorted;
  }

  /// Options dont le nom contient [query] (sans accents ni casse) ; toutes si
  /// [query] est vide.
  static List<PactWeaponOption> search(
    List<PactWeaponOption> options,
    String query,
  ) {
    final needle = normalize(query);
    if (needle.isEmpty) return options;
    return [
      for (final option in options)
        if (normalize(option.name).contains(needle)) option,
    ];
  }

  /// Nom de la sous-classe d'Occultiste qui donne la Lame maudite.
  static const String cursedBladeSubclassName = 'Lame maudite';

  /// `true` si [subclassName] désigne la Lame maudite (sans accents/casse).
  static bool isCursedBlade(String? subclassName) =>
      subclassName != null &&
      normalize(subclassName) == normalize(cursedBladeSubclassName);
}
