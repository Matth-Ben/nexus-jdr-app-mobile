import 'package:freezed_annotation/freezed_annotation.dart';

part 'pact_weapon_option.freezed.dart';

/// Une arme utilisable comme forme de l'arme de pacte de l'Occultiste (Pacte
/// de la lame) : à la fois une entrée de la feuille « FORME DE L'ARME »
/// (`presentation/widgets/pact_weapon_picker_sheet.dart`) et la forme
/// courante portée par `CharacterDetail.pactWeapon`
/// (`character_pact_weapons`).
///
/// [damageDice]/[damageType] sont nullables : la forme courante lue en base
/// peut, par défensive, désigner une arme sans dégâts directs ; les options
/// proposées par la feuille en ont toujours (voir `PactWeaponRules`).
@freezed
abstract class PactWeaponOption with _$PactWeaponOption {
  const PactWeaponOption._();

  const factory PactWeaponOption({
    /// `items.id`.
    required int id,

    /// Nom français (`translations`, `entity_type = 'item'`).
    required String name,

    /// `weapon_properties.damage_dice` (ex. « 1d8 »).
    String? damageDice,

    /// `weapon_properties.damage_type` (ex. « tranchant »).
    String? damageType,

    /// `weapon_properties.properties` (ex. « légère », « finesse »).
    @Default(<String>[]) List<String> properties,
  }) = _PactWeaponOption;

  /// « {dés} {type} » (format de `item_info_panel.dart`), `null` si l'un des
  /// deux manque.
  String? get damageLabel {
    final dice = damageDice;
    final type = damageType;
    if (dice == null || type == null) return null;
    return '$dice $type';
  }

  /// Propriétés jointes par « , », `null` si aucune.
  String? get propertiesLabel =>
      properties.isEmpty ? null : properties.join(', ');
}
