/// Normalise une chaîne pour une comparaison de nom insensible à la casse et
/// aux accents, utilisée par `XmlNameResolver.resolveByName` — nécessaire
/// car les noms exportés par aidedd.org ne sont pas garantis d'utiliser
/// exactement la même casse/accentuation que les tables de référence
/// internes de l'app (contrairement aux résolveurs de
/// `character_creation`, ex. `SkillProficiencyResolver`, qui comparent par
/// égalité stricte car leurs deux côtés viennent de la même base Supabase :
/// voir `docs/cahier-des-charges/03-import-xml-aidedd.md`, point 3 du
/// "Comportement attendu de l'import", qui demande explicitement une
/// "recherche dans les tables de référence internes ; si aucune
/// correspondance n'est trouvée [...] gestion des accents/casse").
///
/// Aucune dépendance externe ajoutée pour ce besoin ponctuel (pas de
/// package `diacritic`) : une table de correspondance couvrant les
/// caractères accentués français usuels suffit très largement au périmètre
/// de ce format (noms de races/classes/historiques/sorts/langues/outils
/// D&D 5e en français).
abstract final class XmlNameNormalizer {
  /// `trim()` + minuscules + accents retirés, espaces multiples réduits à un
  /// seul. Chaîne vide en entrée → chaîne vide en sortie (pas de cas
  /// particulier nécessaire côté appelant).
  static String normalize(String input) {
    final lower = input.trim().toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      buffer.write(_withoutDiacritic(rune));
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _withoutDiacritic(int rune) {
    final replacement = _diacriticsByRune[rune];
    if (replacement != null) {
      return replacement;
    }
    return String.fromCharCode(rune);
  }

  static final Map<int, String> _diacriticsByRune = {
    for (final entry in _diacriticGroups.entries)
      for (final char in entry.key.runes) char: entry.value,
  };

  /// Groupé par lettre de destination plutôt qu'une entrée par caractère,
  /// pour rester lisible/vérifiable à l'œil.
  static const Map<String, String> _diacriticGroups = {
    'àâäáãå': 'a',
    'éèêë': 'e',
    'îïìí': 'i',
    'ôöòóõ': 'o',
    'ùûüú': 'u',
    'ç': 'c',
    'ñ': 'n',
    'ÿý': 'y',
    'œ': 'oe',
    'æ': 'ae',
  };
}
