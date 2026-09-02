import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Règles d'affichage (icône/libellé/couleur) par `items.category`, pour le
/// badge et le sous-titre de chaque carte de l'onglet "Inventaire" —
/// `presentation/widgets/character_inventory_item_card.dart`.
///
/// Dédié à cet onglet plutôt que réutilisé depuis
/// `character_creation/domain/equipment_category_rules.dart` : même
/// mapping icône/libellé (voir sa documentation de classe pour le
/// rationale de cette duplication systématique dans ce dépôt), mais avec
/// une couleur d'accent par catégorie en plus (spec de l'onglet Inventaire,
/// `09-maquettes-captures.md` : badge carré coloré selon la catégorie —
/// besoin absent de l'étape 7/9 "Équipement de départ", qui utilise un
/// [AccentIconBadge] cyclé, pas une couleur dédiée par catégorie).
///
/// `category == null` (objet personnalisé, `item_id` nul) n'est PAS traité
/// ici : ce cas a son propre rendu dédié (badge en pointillés, voir
/// `_CustomItemBadge`) plutôt qu'une entrée de plus dans ces maps — voir
/// [labelFor] pour son seul besoin partagé (le libellé de sous-titre).
abstract final class InventoryCategoryRules {
  static const Map<String, String> _frenchLabels = {
    'arme': 'Arme',
    'armure': 'Armure',
    'bouclier': 'Bouclier',
    'outil': 'Outil',
    'equipement_general': 'Équipement général',
    'objet_magique': 'Objet magique',
    'monture_vehicule': 'Monture/Véhicule',
  };

  static const Map<String, IconData> _icons = {
    'arme': Icons.gavel,
    'armure': Icons.security,
    'bouclier': Icons.shield,
    'outil': Icons.build,
    'equipement_general': Icons.backpack,
    'objet_magique': Icons.auto_awesome,
    'monture_vehicule': Icons.pets,
  };

  /// Couleurs d'accent : `arme` en brique (teinte "arme"/danger, cohérent
  /// avec `AppColors.accentBrick` déjà utilisé pour les valeurs négatives
  /// ailleurs dans la fiche), `outil` en sarcelle, `equipement_general` en
  /// bois (teinte neutre, catégorie la plus courante), `objet_magique` en
  /// or (seule couleur volontairement "plus distinctive/claire" que les
  /// autres, spec de la maquette) — `armure`/`bouclier`/`monture_vehicule`
  /// n'apparaissent pas dans la maquette de cet onglet (aucune ligne
  /// `items` de ces catégories dans le contenu peuplé pour l'onglet
  /// Équipement, voir `equipment_category_rules.dart`) : couleurs choisies
  /// par extension raisonnable pour rester distinctes du reste de la
  /// palette plutôt que de laisser un objet de ces catégories retomber sur
  /// [_fallbackColor].
  static const Map<String, Color> _colors = {
    'arme': AppColors.accentBrick,
    'armure': AppColors.accentBlue,
    'bouclier': AppColors.accentViolet,
    'outil': AppColors.accentTeal,
    'equipement_general': AppColors.woodMedium,
    'objet_magique': AppColors.goldEnd,
    'monture_vehicule': AppColors.woodLight,
  };

  static const Color _fallbackColor = AppColors.woodMedium;

  /// Ordre d'affichage des sections de la sheet "Depuis le catalogue"
  /// (`presentation/widgets/add_item_flow.dart`) — mêmes clés que
  /// [_frenchLabels], dans le même ordre que celui-ci (pas d'ordre distinct
  /// à maintenir). Une catégorie sans objet correspondant dans le contenu
  /// peuplé (ex. `objet_magique`) est simplement absente de la sheet, jamais
  /// affichée comme section vide — même principe que
  /// `EquipmentCategoryRules.shopSectionOrder`.
  static const List<String> categoryOrder = [
    'arme',
    'armure',
    'bouclier',
    'outil',
    'equipement_general',
    'objet_magique',
    'monture_vehicule',
  ];

  /// Libellé FR affiché en sous-titre de carte ("{libellé} · x{quantité}").
  /// `null` (objet personnalisé) -> "Objet personnalisé", distinct du
  /// libellé générique "Équipement" utilisé par
  /// `equipment_category_rules.dart` pour un objet non résolu : ici `null`
  /// ne signifie jamais "pas encore résolu", mais bien "cet objet n'existe
  /// pas dans le catalogue `items`" (voir
  /// `domain/character_inventory_item.dart::category`).
  static String labelFor(String? category) => category == null
      ? 'Objet personnalisé'
      : (_frenchLabels[category] ?? 'Équipement');

  /// Icône affichée dans l'[AccentIconBadge] du badge de catégorie —
  /// n'est jamais appelée pour `category == null` (voir la documentation de
  /// classe), donc pas de valeur de repli à documenter pour ce cas ; une
  /// catégorie inconnue (ne devrait pas arriver, contrainte
  /// `items_category_check` côté base) retombe sur `Icons.inventory_2`.
  static IconData iconFor(String category) =>
      _icons[category] ?? Icons.inventory_2;

  /// Couleur d'accent du badge — mêmes règles de repli que [iconFor].
  static Color colorFor(String category) => _colors[category] ?? _fallbackColor;
}
