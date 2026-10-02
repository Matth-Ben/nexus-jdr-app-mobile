import 'pact_weapon_rules.dart';

/// Titre du panneau "Infos" ouvert depuis une chip de
/// `CharacterWeaponProficienciesCard`/`CharacterArmorProficienciesCard`
/// (`proficiency_detail_panel.dart`) — spec direction-artistique : majuscules,
/// table de correspondance pour le vocabulaire RAW connu, repli
/// `token.toUpperCase()` (tel qu'affiché par le chip, jamais le nom d'un
/// objet trouvé) pour un token déjà spécifique (ex. « dagues »).
///
/// Même esprit que `InventoryArmorDexBonusFormatter`/`SignedModifierFormatter` :
/// un petit formateur pur dédié, pas de dépendance au résultat de
/// `ProficiencyTokenResolver`.
abstract final class ProficiencyTokenTitleFormatter {
  /// Titre en majuscules pour [token] — comparaison sans accents ni casse
  /// (le token de recherche peut porter des accents, ex.
  /// « intermédiaire »), mais le repli final renvoie [token] tel quel
  /// (accents conservés), seulement mis en majuscules.
  static String titleFor(String token) {
    final normalized = PactWeaponRules.normalize(token);
    return switch (normalized) {
      'courantes' => 'ARMES COURANTES',
      'martiales' => 'ARMES DE GUERRE',
      'legere' => 'ARMURES LÉGÈRES',
      'intermediaire' => 'ARMURES INTERMÉDIAIRES',
      'lourde' => 'ARMURES LOURDES',
      'boucliers' => 'BOUCLIERS',
      'intermediaire (non metallique)' =>
        'ARMURES INTERMÉDIAIRES (NON MÉTALLIQUES)',
      'boucliers (non metalliques)' => 'BOUCLIERS (NON MÉTALLIQUES)',
      _ => token.toUpperCase(),
    };
  }
}
