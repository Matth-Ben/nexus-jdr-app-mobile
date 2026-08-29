/// Type de repos applicable à un personnage (onglet "Personnage", lien
/// "Prendre un repos" — `presentation/widgets/rest_sheet.dart`) — voir
/// `data/character_repository.dart::CharacterRepository.applyRest` pour
/// l'effet exact de chaque valeur, tranché par le chef de projet (spec
/// fonctionnelle `docs/cahier-des-charges/04-fonctionnalites-app-mobile.md`
/// section 5, "Points de vie").
enum RestType {
  /// Repos court : réinitialise uniquement les `character_feature_uses`
  /// dont la `class_features.uses_per_rest->>'rest_type'` correspondante
  /// vaut `'repos_court'`, pour les aptitudes de classe atteintes par le
  /// niveau de la classe primaire. Ne restaure aucun PV — le mécanisme RAW
  /// "dépenser des dés de vie" n'est pas pris en charge (aucune colonne de
  /// suivi des dés de vie dans le schéma actuel, gap vérifié, hors
  /// périmètre de cette tâche).
  short,

  /// Repos long : restaure `characters.current_hp` au maximum, remet
  /// `characters.temporary_hp` à 0 (règle 5e RAW : les PV temporaires ne
  /// survivent pas à un repos long — décision chef de projet), réinitialise
  /// tous les `character_spell_slots.slots_used` du personnage, et
  /// réinitialise tous les `character_feature_uses.uses_remaining` des
  /// aptitudes atteintes par le niveau de la classe primaire, quel que soit
  /// leur `rest_type` (règle 5e RAW : un repos long recharge tout ce qu'un
  /// repos court recharge, et plus).
  long,
}
