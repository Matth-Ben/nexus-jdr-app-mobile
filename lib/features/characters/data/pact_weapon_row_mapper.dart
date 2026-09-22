import '../domain/pact_weapon_option.dart';
import '../domain/pact_weapon_rules.dart';

/// Mapping pur entre les lignes brutes `items` (avec `weapon_properties`
/// embarquée) / `translations` et [PactWeaponOption] — Pacte de la lame.
abstract final class PactWeaponRowMapper {
  /// Identifiants d'objets à résoudre via `translations` (`entity_id` est
  /// `text`).
  static Set<String> collectIds(List<Map<String, dynamic>> rows) => {
    for (final row in rows)
      if (row['id'] != null) row['id'].toString(),
  };

  /// `weapon_properties` : objet direct (relation 1-1) ou liste à un
  /// élément selon la version de PostgREST.
  static Map<String, dynamic>? _weaponProperties(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is List && value.isNotEmpty && value.first is Map) {
      return Map<String, dynamic>.from(value.first as Map);
    }
    return null;
  }

  static List<String> _properties(Object? raw) =>
      raw is List ? raw.whereType<String>().toList() : const <String>[];

  /// Convertit une ligne `items` en option, sans filtrer l'éligibilité (voir
  /// [toEligibleOptions] pour la liste de la feuille). `null` si `id` est
  /// absent.
  static PactWeaponOption? toOption(
    Map<String, dynamic> row, {
    required Map<String, String> names,
  }) {
    final id = (row['id'] as num?)?.toInt();
    if (id == null) return null;
    final weapon = _weaponProperties(row['weapon_properties']);
    return PactWeaponOption(
      id: id,
      name: names[id.toString()] ?? 'Arme #$id',
      damageDice: weapon?['damage_dice'] as String?,
      damageType: weapon?['damage_type'] as String?,
      properties: _properties(weapon?['properties']),
    );
  }

  /// Armes éligibles (voir `PactWeaponRules.isEligible`), triées par nom.
  static List<PactWeaponOption> toEligibleOptions(
    List<Map<String, dynamic>> rows, {
    required Map<String, String> names,
  }) {
    final options = <PactWeaponOption>[];
    for (final row in rows) {
      final option = toOption(row, names: names);
      if (option == null) continue;
      if (!PactWeaponRules.isEligible(
        category: row['category'] as String?,
        damageDice: option.damageDice,
        properties: option.properties,
      )) {
        continue;
      }
      options.add(option);
    }
    return PactWeaponRules.sortByName(options);
  }
}
