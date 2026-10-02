import 'package:freezed_annotation/freezed_annotation.dart';

part 'proficiency_catalog.freezed.dart';

/// Une arme du catalogue de référence (`items` catégorie `'arme'` +
/// `weapon_properties` + `translations`), TOUTES les armes (corps à corps ET
/// à distance) — alimente le panneau "Infos" d'un token de maîtrise d'armes
/// (`proficiency_detail_panel.dart`) via `ProficiencyTokenResolver`.
///
/// Contrairement à `PactWeaponOption` (armes de corps à corps éligibles
/// uniquement, feuille « FORME DE L'ARME »), ce modèle ne filtre rien :
/// c'est `ProficiencyTokenResolver` qui applique le filtre propre à chaque
/// token (`'courantes'`/`'martiales'`/nom déjà spécifique).
@freezed
abstract class ProficiencyCatalogWeapon with _$ProficiencyCatalogWeapon {
  const factory ProficiencyCatalogWeapon({
    /// `items.id`.
    required int id,

    /// Nom français (`translations`, `entity_type = 'item'`).
    required String name,

    /// `weapon_properties.damage_dice` (ex. « 1d8 »), `null` pour une arme
    /// sans dé de dégâts direct (ex. le filet).
    String? damageDice,

    /// `weapon_properties.damage_type` (ex. « tranchant »).
    String? damageType,

    /// `weapon_properties.properties` (ex. « légère », « finesse »).
    @Default(<String>[]) List<String> properties,
  }) = _ProficiencyCatalogWeapon;
}

/// Une armure OU un bouclier du catalogue de référence (`items` catégorie
/// `'armure'`/`'bouclier'` + `armor_properties` + `translations`, catégorie
/// `'objet_magique'` explicitement exclue par le filtre de la requête — voir
/// `ProficiencyCatalogRepository`) — alimente le panneau "Infos" d'un token
/// de maîtrise d'armures (`proficiency_detail_panel.dart`).
@freezed
abstract class ProficiencyCatalogArmor with _$ProficiencyCatalogArmor {
  const factory ProficiencyCatalogArmor({
    /// `items.id`.
    required int id,

    /// Nom français (`translations`, `entity_type = 'item'`).
    required String name,

    /// `items.category` ('armure' ou 'bouclier') — distingue le gabarit
    /// d'affichage du panneau "Infos" (armure complète vs bouclier "CA"
    /// seule), voir `proficiency_detail_panel.dart::_ArmorDetailRow`.
    required String category,

    /// `armor_properties.ac_base` — pour un bouclier, un bonus (+2) plutôt
    /// qu'une CA de base à proprement parler, même convention que
    /// `CharacterInventoryArmorProperties.acBase`.
    required int acBase,

    /// `armor_properties.ac_dex_bonus` ('aucun'/'max_2'/'illimite') — voir
    /// `ArmorProficiencyCategoryRules.categoryFor` pour la dérivation de
    /// catégorie, `InventoryArmorDexBonusFormatter` pour son libellé FR.
    required String acDexBonus,

    /// `armor_properties.strength_requirement`, `null` si aucune force
    /// minimale requise — omis du panneau "Infos" dans ce cas.
    int? strengthRequirement,

    @Default(false) bool stealthDisadvantage,
  }) = _ProficiencyCatalogArmor;
}

/// Catalogue complet lu par [ProficiencyCatalogRepository] — toutes les
/// armes ([weapons]), toutes les armures ordinaires ([armors], catégorie
/// `'armure'`) et tous les boucliers ordinaires ([shields], catégorie
/// `'bouclier'`) du contenu peuplé, objets magiques exclus.
@freezed
abstract class ProficiencyCatalog with _$ProficiencyCatalog {
  const factory ProficiencyCatalog({
    @Default(<ProficiencyCatalogWeapon>[])
    List<ProficiencyCatalogWeapon> weapons,
    @Default(<ProficiencyCatalogArmor>[]) List<ProficiencyCatalogArmor> armors,
    @Default(<ProficiencyCatalogArmor>[]) List<ProficiencyCatalogArmor> shields,
  }) = _ProficiencyCatalog;
}
