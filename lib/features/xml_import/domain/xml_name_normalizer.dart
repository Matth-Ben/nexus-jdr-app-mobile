import '../../../core/utils/french_text_normalizer.dart';

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
/// Délègue à [FrenchTextNormalizer] (normalisation partagée, voir sa
/// documentation de classe pour le rationale de factorisation) : ne garde
/// qu'un alias dédié à ce besoin de résolution de nom plutôt que de faire
/// migrer tous les appelants de ce fichier.
abstract final class XmlNameNormalizer {
  /// `trim()` + minuscules + accents retirés, espaces multiples réduits à un
  /// seul. Chaîne vide en entrée → chaîne vide en sortie (pas de cas
  /// particulier nécessaire côté appelant).
  static String normalize(String input) =>
      FrenchTextNormalizer.normalize(input);
}
