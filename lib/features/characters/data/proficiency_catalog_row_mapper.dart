import '../domain/proficiency_catalog.dart';

/// Mapping pur entre les lignes brutes `items` (avec `weapon_properties`/
/// `armor_properties` embarquée) / `translations` et [ProficiencyCatalog] —
/// voir `ProficiencyCatalogRepository`.
abstract final class ProficiencyCatalogRowMapper {
  /// Identifiants d'objets à résoudre via `translations` (`entity_id` est
  /// `text`).
  static Set<String> collectIds(List<Map<String, dynamic>> rows) => {
    for (final row in rows)
      if (row['id'] != null) row['id'].toString(),
  };

  /// `weapon_properties`/`armor_properties` : objet direct (relation 1-1) ou
  /// liste à un élément selon la version de PostgREST — même garde
  /// défensive que `PactWeaponRowMapper`/`CharacterInventoryRowMapper`.
  static Map<String, dynamic>? _singleEmbedded(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is List && value.isNotEmpty && value.first is Map) {
      return Map<String, dynamic>.from(value.first as Map);
    }
    return null;
  }

  static List<String> _stringList(Object? raw) =>
      raw is List ? raw.whereType<String>().toList() : const <String>[];

  /// `null` si `id` est absent.
  static ProficiencyCatalogWeapon? toWeapon(
    Map<String, dynamic> row, {
    required Map<String, String> names,
  }) {
    final id = (row['id'] as num?)?.toInt();
    if (id == null) return null;
    final weapon = _singleEmbedded(row['weapon_properties']);
    return ProficiencyCatalogWeapon(
      id: id,
      name: names[id.toString()] ?? 'Arme #$id',
      damageDice: weapon?['damage_dice'] as String?,
      damageType: weapon?['damage_type'] as String?,
      properties: _stringList(weapon?['properties']),
    );
  }

  static List<ProficiencyCatalogWeapon> toWeapons(
    List<Map<String, dynamic>> rows, {
    required Map<String, String> names,
  }) => [for (final row in rows) ?toWeapon(row, names: names)];

  /// `null` si `id` est absent, ou si `ac_base` est manquant/d'un type
  /// inattendu (`ac_base` est `not null` côté base, ne devrait jamais
  /// arriver en pratique — filet de sécurité plutôt qu'un crash, même
  /// principe que `CharacterInventoryRowMapper.parseArmorProperties`).
  static ProficiencyCatalogArmor? toArmor(
    Map<String, dynamic> row, {
    required Map<String, String> names,
    required String category,
  }) {
    final id = (row['id'] as num?)?.toInt();
    if (id == null) return null;
    final armor = _singleEmbedded(row['armor_properties']);
    final acBase = armor?['ac_base'];
    if (acBase is! num) return null;
    return ProficiencyCatalogArmor(
      id: id,
      name: names[id.toString()] ?? 'Objet #$id',
      category: category,
      acBase: acBase.toInt(),
      acDexBonus: armor?['ac_dex_bonus'] as String? ?? 'aucun',
      strengthRequirement: (armor?['strength_requirement'] as num?)?.toInt(),
      stealthDisadvantage: armor?['stealth_disadvantage'] == true,
    );
  }

  static List<ProficiencyCatalogArmor> toArmors(
    List<Map<String, dynamic>> rows, {
    required Map<String, String> names,
    required String category,
  }) => [
    for (final row in rows) ?toArmor(row, names: names, category: category),
  ];
}
