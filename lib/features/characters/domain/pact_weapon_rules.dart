import '../../../core/utils/french_text_normalizer.dart';
import 'pact_weapon_option.dart';

/// Règles pures de la feuille « FORME DE L'ARME » (Pacte de la lame) :
/// éligibilité, tri et recherche — comparaisons sans accents ni casse.
abstract final class PactWeaponRules {
  /// Minuscule et sans diacritiques (ex. « Épée » -> « epee »). Délègue à
  /// [FrenchTextNormalizer] (normalisation partagée, voir sa documentation
  /// de classe pour le rationale de factorisation) : ne garde qu'un alias
  /// dédié à ce besoin d'éligibilité/recherche plutôt que de faire migrer
  /// tous les appelants de ce fichier.
  static String normalize(String value) =>
      FrenchTextNormalizer.normalize(value);

  /// Une arme de pacte est une arme de corps à corps : `category == 'arme'`,
  /// un dé de dégâts, et aucune propriété « munitions » (peut être suffixée,
  /// ex. « munitions(24/96) ») — exclut arcs, arbalètes, fronde, sarbacane
  /// et filet. Exclut aussi toute arme portant la propriété « naturelle »
  /// (Serre/Sabots/Morsure/Cornes/Griffes félines/Griffes, voir
  /// `character_creation_equipment_resolver.dart`) : ce sont des parties du
  /// corps propres à une race précise, jamais une arme que n'importe quel
  /// Occultiste pourrait choisir comme forme de son pacte — trouvé en revue
  /// de code sur le chantier qui a introduit cette propriété.
  static bool isEligible({
    required String? category,
    required String? damageDice,
    required List<String> properties,
  }) {
    if (category != 'arme') return false;
    if (damageDice == null || damageDice.trim().isEmpty) return false;
    return !properties.any(
      (property) =>
          normalize(property).startsWith('munitions') ||
          normalize(property) == 'naturelle',
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
