/// Type de repos applicable à un personnage (onglet "Personnage", lien
/// "Prendre un repos" — `presentation/widgets/rest_sheet.dart`) — voir
/// `data/character_repository.dart::CharacterRepository.applyRest` pour
/// l'effet exact de chaque valeur, tranché par le chef de projet (spec
/// fonctionnelle `docs/cahier-des-charges/04-fonctionnalites-app-mobile.md`
/// section 5, "Points de vie").
enum RestType {
  /// Repos court : réinitialise uniquement les `character_feature_uses`
  /// dont la `class_features.uses_per_rest->>'rest_type'` correspondante
  /// vaut `'repos_court'`, pour les aptitudes de **toutes** les classes du
  /// personnage (multiclassage inclus) atteintes par leur niveau respectif.
  /// Peut aussi restaurer des PV via la règle RAW "dépenser un(des) dé(s)
  /// de vie" (`character_classes.hit_dice_spent`, un pool par classe — voir
  /// `domain/hit_dice_pool.dart`/`presentation/widgets/rest_sheet.dart`),
  /// au choix du joueur.
  short,

  /// Repos long : restaure `characters.current_hp` au maximum, remet
  /// `characters.temporary_hp` à 0 (règle 5e RAW : les PV temporaires ne
  /// survivent pas à un repos long — décision chef de projet), réinitialise
  /// tous les `character_spell_slots.slots_used` du personnage, et
  /// réinitialise tous les `character_feature_uses.uses_remaining` des
  /// aptitudes de **toutes** les classes du personnage (multiclassage
  /// inclus) atteintes par leur niveau respectif, quel que soit leur
  /// `rest_type` (règle 5e RAW : un repos long recharge tout ce qu'un repos
  /// court recharge, et plus). Récupère aussi la moitié (arrondie à
  /// l'inférieur, au moins 1) du nombre total de dés de vie du personnage
  /// (toutes classes confondues, voir
  /// `domain/hit_dice_recovery_calculator.dart`), répartie entre les pools
  /// dépensés — automatiquement si un seul pool est concerné ou si la
  /// récupération suffit à tout restaurer, au choix du joueur sinon.
  long,
}
