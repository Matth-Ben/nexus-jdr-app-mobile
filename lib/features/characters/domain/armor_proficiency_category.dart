/// Catégorie légère/intermédiaire/lourde d'une armure — dérivée
/// automatiquement de `armor_properties.ac_dex_bonus` (jamais une table
/// codée en dur par nom d'objet, contrairement à
/// `WeaponProficiencyCategoryRules` : cette dérivation est demandée
/// explicitement par le chef de projet plutôt qu'une liste figée).
enum ArmorProficiencyCategory {
  /// `ac_dex_bonus = 'illimite'`.
  legere,

  /// `ac_dex_bonus = 'max_2'`.
  intermediaire,

  /// `ac_dex_bonus = 'aucun'`.
  lourde,
}

/// Dérivation de [ArmorProficiencyCategory] depuis
/// `armor_properties.ac_dex_bonus` — voir [ArmorProficiencyCategory].
abstract final class ArmorProficiencyCategoryRules {
  /// `null` pour une valeur hors de l'ensemble contraint côté base
  /// (`'aucun'`/`'max_2'`/`'illimite'`, voir `InventoryArmorDexBonusFormatter`)
  /// — ne devrait jamais arriver en pratique, traité comme "catégorie
  /// inconnue" plutôt que de deviner une catégorie par défaut.
  static ArmorProficiencyCategory? categoryFor(String acDexBonus) =>
      switch (acDexBonus) {
        'illimite' => ArmorProficiencyCategory.legere,
        'max_2' => ArmorProficiencyCategory.intermediaire,
        'aucun' => ArmorProficiencyCategory.lourde,
        _ => null,
      };
}
