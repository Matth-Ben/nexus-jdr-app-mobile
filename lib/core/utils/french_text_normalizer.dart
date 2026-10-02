/// Normalisation de chaîne partagée pour les comparaisons/tris
/// insensibles à la casse et aux accents (noms de races/classes/sorts/objets
/// D&D en français, listes codées en dur...).
///
/// Avant l'introduction de ce helper, la même logique existait en double :
/// `XmlNameNormalizer.normalize` (résolution "en clair" de l'import XML
/// aidedd.org) et `PactWeaponRules.normalize` (feuille "FORME DE L'ARME" du
/// Pacte de la lame) — signalé plusieurs fois en revue de code comme une
/// duplication à résorber. Les deux délèguent maintenant à [normalize] pour
/// ne jamais risquer de diverger ; voir leur documentation de classe pour
/// leurs usages propres au-delà du tri alphabétique (recherche, égalité de
/// nom...), qui restent légitimement sur place plutôt que migrés ici.
///
/// Aucune dépendance externe ajoutée (pas de package `diacritic`) : une
/// table de correspondance couvrant les caractères accentués français usuels
/// suffit très largement au périmètre de ce dépôt (contenu D&D 5e en
/// français) — même rationale que `XmlNameNormalizer` d'origine.
abstract final class FrenchTextNormalizer {
  /// `trim()` + minuscules + accents/diacritiques retirés, espaces
  /// multiples réduits à un seul. Chaîne vide en entrée → chaîne vide en
  /// sortie (pas de cas particulier nécessaire côté appelant).
  ///
  /// Exemples : « Épée » -> « epee », «  Œil-de-dragon  » -> « oeil-de-dragon »,
  /// « À » -> « a ».
  static String normalize(String value) {
    final lower = value.trim().toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      buffer.write(_withoutDiacritic(rune));
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Compare [a] et [b] après [normalize] — à utiliser dans tout
  /// `List.sort` qui doit trier par ordre alphabétique français (insensible
  /// aux accents/casse) plutôt qu'un `String.compareTo` direct (sensible à
  /// la casse, et qui classe les lettres accentuées après les lettres non
  /// accentuées).
  static int compare(String a, String b) =>
      normalize(a).compareTo(normalize(b));

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
