/// Libellé FR de `armor_properties.ac_dex_bonus` ('aucun'/'max_2'/
/// 'illimite', check constraint côté base — voir
/// `20260825090300_create_reference_spells_items_tables.sql` du dépôt web)
/// — panneau "Infos" d'une armure/d'un bouclier, ligne "Bonus Dex".
abstract final class InventoryArmorDexBonusFormatter {
  static String format(String acDexBonus) => switch (acDexBonus) {
    'aucun' => 'Aucun',
    'max_2' => '+2 max',
    'illimite' => 'Illimité',
    // Ne devrait pas arriver (valeur contrainte côté base) — affiche la
    // valeur brute plutôt que de masquer une donnée inattendue.
    _ => acDexBonus,
  };
}
