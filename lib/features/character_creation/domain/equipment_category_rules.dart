import 'package:flutter/material.dart';

/// Règles d'affichage par catégorie `items.category`, partagées par les deux
/// onglets de l'étape 7/9 "Équipement de départ"
/// (`presentation/equipment_step_screen.dart`) — précédent déjà établi par
/// `domain/ability_score_definitions.dart` (domaine important `IconData`
/// pour rester la source de vérité unique d'un mapping catégorie/icône,
/// plutôt que de le dupliquer dans le widget).
///
/// Icônes Material provisoires, mappées par [ItemOption.category] plutôt que
/// par un sous-type qui n'existe pas dans le schéma (dette de polish DA,
/// même rationale que `AccentIconBadge`) — décision du chef de projet suite
/// à la revue `direction-artistique` de cette étape.
abstract final class EquipmentCategoryRules {
  /// Ordre fixe d'affichage des sections de l'onglet "Acheter" — catégories
  /// non peuplées (ex. `objet_magique`/`monture_vehicule`, aucune ligne dans
  /// le contenu actuel) simplement absentes du groupement, jamais affichées
  /// comme section vide (voir `presentation/equipment_step_screen.dart`).
  static const List<String> shopSectionOrder = [
    'arme',
    'armure',
    'bouclier',
    'outil',
    'equipement_general',
    'objet_magique',
    'monture_vehicule',
  ];

  static const Map<String, String> _frenchLabels = {
    'arme': 'Arme',
    'armure': 'Armure',
    'bouclier': 'Bouclier',
    'outil': 'Outil',
    'equipement_general': 'Équipement',
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

  /// Libellé FR affiché en sous-titre de carte (onglet "Historique") ou en
  /// titre de section (onglet "Acheter"). `null`/catégorie inconnue ->
  /// "Équipement", un libellé générique neutre plutôt qu'un texte du type
  /// "Non répertorié" (objet de `backgrounds.equipment` non résolu vers un
  /// `items.id`, voir `domain/background_equipment_resolver.dart` : aucune
  /// catégorie n'est alors connue) — correction demandée par le chef de
  /// projet après revue `qa-testeur`/`direction-artistique` : un libellé
  /// explicite comme "Non répertorié" révélait au joueur qu'un objet de son
  /// historique n'avait pas matché la base, alors que la consigne d'origine
  /// exige un rendu **strictement identique** à un objet résolu (voir
  /// `domain/background_equipment_entry.dart`). "Équipement" a été choisi
  /// plutôt qu'un texte vide : la carte garde sa structure à deux lignes
  /// (nom + sous-titre catégorie) pour tous les objets, résolus ou non.
  static String labelFor(String? category) =>
      _frenchLabels[category] ?? 'Équipement';

  /// Icône affichée dans l'[AccentIconBadge] de la carte, `Icons.inventory_2`
  /// pour un objet non résolu (`category` `null`) ou une catégorie inconnue
  /// — conservée telle quelle (moins "parlante" à elle seule qu'un texte
  /// explicite, et il faut bien une icône par défaut), seul [labelFor] a été
  /// corrigé (voir sa documentation).
  static IconData iconFor(String? category) =>
      _icons[category] ?? Icons.inventory_2;
}
