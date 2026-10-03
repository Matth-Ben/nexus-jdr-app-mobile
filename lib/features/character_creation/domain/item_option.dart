import 'package:freezed_annotation/freezed_annotation.dart';

part 'item_option.freezed.dart';

/// Un objet du catalogue `items` (`docs/cahier-des-charges/02-modele-donnees.md`),
/// utilisé à l'étape 7/9 "Équipement de départ" de l'assistant de création,
/// à la fois pour résoudre les chaînes de `backgrounds.equipment` (onglet
/// "Historique") et pour peupler le catalogue d'achat libre (onglet
/// "Acheter").
///
/// [category] est une colonne réelle de `items` ('arme'/'armure'/'bouclier'/
/// 'outil'/'equipement_general'/'objet_magique'/'monture_vehicule', vérifié
/// contre le schéma Supabase local) — voir `domain/equipment_category_rules.dart`
/// pour son libellé FR et son icône affichés.
///
/// [costAmount] est le montant de `items.cost` (jsonb `{"amount", "currency"}`)
/// — `currency` toujours `"gp"` pour ce MVP (décision du chef de projet, voir
/// la consigne d'origine), donc pas de champ dédié pour la devise. `double`
/// plutôt que `int` : vérifié contre le contenu peuplé, certains coûts sont
/// fractionnaires (ex. 0.05 gp pour une flèche) — voir
/// `domain/gold_amount_formatter.dart` pour leur affichage.
///
/// [isTwoHanded] : `true` si [category] vaut `'arme'` et que
/// `weapon_properties.properties` contient « à deux mains » (calculé une
/// fois pour toutes au mapping via `WeaponSlotRules.isTwoHanded`,
/// `features/characters/domain/weapon_slot_rules.dart` — même règle que
/// l'équipement manuel d'une arme depuis la fiche personnage). Choix du
/// champ déjà calculé plutôt que de porter `properties: List<String>` brut
/// comme `CharacterInventoryWeaponProperties` : le seul besoin de ce
/// catalogue est de savoir combien de "mains" une arme de départ occupe
/// (voir `domain/character_creation_equipment_resolver.dart`), jamais
/// d'afficher ses propriétés. Toujours `false` pour un objet qui n'est pas
/// une arme.
@freezed
abstract class ItemOption with _$ItemOption {
  const factory ItemOption({
    required int id,
    required String name,
    required String category,
    required double costAmount,
    @Default(false) bool isTwoHanded,
  }) = _ItemOption;
}
