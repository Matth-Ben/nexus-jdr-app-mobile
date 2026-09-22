/// Set d'armes équipées ("set principal"/"set secondaire") — un personnage
/// peut équiper au plus deux sets simultanément, chacun représentant 2
/// mains (voir `weapon_slot_rules.dart::WeaponSlotRules`). Ne concerne pas
/// l'arme de pacte (Pacte de la lame), système séparé — voir
/// `pact_weapon_rules.dart`.
enum WeaponSlot {
  principal,
  secondary;

  /// Parse la colonne DB (`character_inventory.weapon_slot`) — `null` si
  /// [value] est `null` ou une valeur inconnue (ne devrait pas arriver,
  /// `weapon_slot` a une contrainte `CHECK` côté base, voir la migration).
  /// Méthode statique plutôt qu'une extension : pas de valeur [WeaponSlot]
  /// existante depuis laquelle partir ici, contrairement à [value]/[label].
  static WeaponSlot? fromValue(String? value) => switch (value) {
    'principal' => WeaponSlot.principal,
    'secondaire' => WeaponSlot.secondary,
    _ => null,
  };
}

/// Conversions colonne DB (`character_inventory.weapon_slot`)/libellé UI.
extension WeaponSlotExtension on WeaponSlot {
  /// Valeur stockée en base (`character_inventory.weapon_slot`).
  String get value => switch (this) {
    WeaponSlot.principal => 'principal',
    WeaponSlot.secondary => 'secondaire',
  };

  /// Libellé affiché (sheet de choix de set, panneau "Infos", carte "ARMES
  /// ÉQUIPÉES").
  String get label => switch (this) {
    WeaponSlot.principal => 'Set principal',
    WeaponSlot.secondary => 'Set secondaire',
  };
}
