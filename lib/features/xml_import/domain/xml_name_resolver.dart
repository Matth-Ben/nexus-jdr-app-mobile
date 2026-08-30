import 'xml_field_resolution.dart';
import 'xml_name_normalizer.dart';

/// Résout un champ "en clair" de l'import XML aidedd.org (race, classe,
/// sous-classe, historique, sorts, invocations, langues, outils) par
/// recherche du nom dans une liste de candidats d'une table de référence
/// interne de l'app déjà chargée par ailleurs (`RaceCatalog.races`,
/// `ClassCatalog.classes`, etc. — voir `XmlCharacterImportResolver`), plutôt
/// que par une nouvelle requête dédiée : voir
/// `docs/cahier-des-charges/03-import-xml-aidedd.md`, point 3 du
/// "Comportement attendu de l'import".
///
/// Comparaison insensible à la casse et aux accents (voir
/// [XmlNameNormalizer]) ; en cas d'ambiguïté (deux candidats normalisés
/// identiques — ne devrait pas arriver avec des données de référence
/// propres, mais pas garanti), le premier candidat de [candidates] dans son
/// ordre d'origine est retenu, jamais une exception.
abstract final class XmlNameResolver {
  static XmlFieldResolution<T> resolveByName<T>({
    required String? rawName,
    required Iterable<T> candidates,
    required String Function(T candidate) nameOf,
  }) {
    final trimmed = rawName?.trim() ?? '';
    if (trimmed.isEmpty) {
      return XmlFieldResolution<T>.unrecognized(trimmed);
    }

    final normalizedTarget = XmlNameNormalizer.normalize(trimmed);
    for (final candidate in candidates) {
      if (XmlNameNormalizer.normalize(nameOf(candidate)) == normalizedTarget) {
        return XmlFieldResolution<T>.recognized(candidate);
      }
    }
    return XmlFieldResolution<T>.unrecognized(trimmed);
  }
}
