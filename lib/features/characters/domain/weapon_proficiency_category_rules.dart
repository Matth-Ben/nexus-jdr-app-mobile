import 'pact_weapon_rules.dart';

/// Classification RAW 5e des armes "courantes" (simples) vs "de guerre"
/// (martiales), par nom FRANÇAIS EXACT du catalogue `items` (catégorie
/// `'arme'`) — donnée fournie par le chef de projet, autoritaire, non
/// re-dérivée ici (`items` ne porte aucune colonne distinguant les deux
/// catégories côté schéma actuel). Même convention que
/// `MulticlassProficiencies` : encodée telle quelle, non re-vérifiée.
///
/// Utilisée par `ProficiencyTokenResolver.resolveWeapon` pour les tokens
/// `'courantes'`/`'martiales'` de `classes.weapon_proficiencies` (panneau
/// "Infos" ouvert depuis une chip de `CharacterWeaponProficienciesCard`).
///
/// Mousquet/Pistolet (armes à poudre, hors règles standard de maîtrise 5e)
/// sont volontairement absents des deux ensembles ci-dessous — ni
/// [isCommon] ni [isMartial] ne les reconnaît, exclusion "par omission"
/// plutôt qu'une liste de blocage dédiée.
abstract final class WeaponProficiencyCategoryRules {
  static const Set<String> _commonWeaponNames = {
    'Gourdin',
    'Dague',
    'Gourdin à deux mains',
    'Hachette',
    'Javeline',
    'Marteau léger',
    "Masse d'armes",
    'Bâton de combat',
    'Faucille',
    'Épieu',
    'Arbalète légère',
    'Dard',
    'Arc court',
    'Fronde',
  };

  static const Set<String> _martialWeaponNames = {
    "Hache d'armes",
    "Fléau d'armes",
    'Glaive',
    'Grande hache',
    'Épée à deux mains',
    'Hallebarde',
    'Lance de cavalerie',
    'Épée longue',
    'Maillet',
    'Morgenstern',
    'Pique',
    'Rapière',
    'Cimeterre',
    'Épée courte',
    'Trident',
    'Pic de guerre',
    'Marteau de guerre',
    'Fouet',
    'Sarbacane',
    'Arbalète de poing',
    'Arbalète lourde',
    'Arc long',
    'Filet',
  };

  static final Set<String> _normalizedCommonWeaponNames = _commonWeaponNames
      .map(PactWeaponRules.normalize)
      .toSet();

  static final Set<String> _normalizedMartialWeaponNames = _martialWeaponNames
      .map(PactWeaponRules.normalize)
      .toSet();

  /// `true` si [name] (nom de catalogue, ex. « Dague ») est une arme
  /// courante — comparaison sans accents ni casse.
  static bool isCommon(String name) =>
      _normalizedCommonWeaponNames.contains(PactWeaponRules.normalize(name));

  /// Même principe que [isCommon], pour les armes de guerre.
  static bool isMartial(String name) =>
      _normalizedMartialWeaponNames.contains(PactWeaponRules.normalize(name));
}
