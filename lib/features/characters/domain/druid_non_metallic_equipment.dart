import 'pact_weapon_rules.dart';

/// Restriction RAW 5e "pas de métal" du Druide, appliquée aux tokens
/// `'intermédiaire (non métallique)'`/`'boucliers (non métalliques)'` de
/// `classes.armor_proficiencies` (panneau "Infos" ouvert depuis une chip de
/// `CharacterArmorProficienciesCard`) : parmi les armures/boucliers du
/// catalogue, lesquels sont effectivement non métalliques.
///
/// Donnée fournie par le chef de projet, autoritaire : encodée telle quelle
/// ci-dessous, non re-vérifiée ici — même convention qu'
/// `MulticlassProficiencies`/`WeaponProficiencyCategoryRules`. Aucune colonne
/// `items`/`armor_properties` ne porte cette information côté schéma actuel,
/// d'où la liste blanche plutôt qu'une dérivation automatique.
abstract final class DruidNonMetallicEquipment {
  /// Seule armure intermédiaire non métallique du catalogue actuel.
  static const Set<String> _nonMetallicArmorNames = {'Armure de peau'};

  /// Toujours vide dans le catalogue actuel (aucun bouclier non métallique
  /// peuplé) — conservé comme ensemble nommé plutôt qu'un simple `false`/
  /// liste vide en dur dans `ProficiencyTokenResolver`, pour documenter
  /// explicitement cette donnée et pouvoir l'étendre le jour où un bouclier
  /// non métallique serait ajouté au catalogue.
  static const Set<String> _nonMetallicShieldNames = <String>{};

  /// `true` si [name] (nom de catalogue) désigne une armure non métallique
  /// — comparaison sans accents ni casse.
  static bool isNonMetallicArmor(String name) => _nonMetallicArmorNames
      .map(PactWeaponRules.normalize)
      .contains(PactWeaponRules.normalize(name));

  /// Même principe que [isNonMetallicArmor], pour les boucliers — toujours
  /// `false` dans le catalogue actuel (voir [_nonMetallicShieldNames]).
  static bool isNonMetallicShield(String name) => _nonMetallicShieldNames
      .map(PactWeaponRules.normalize)
      .contains(PactWeaponRules.normalize(name));
}
