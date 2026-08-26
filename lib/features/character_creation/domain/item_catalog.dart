import 'package:freezed_annotation/freezed_annotation.dart';

import 'item_option.dart';

part 'item_catalog.freezed.dart';

/// Catalogue complet des objets de `items`, récupéré en une fois au
/// chargement de l'étape 7/9 "Équipement de départ"
/// (`data/character_creation_repository.dart`) — même rationale que
/// [ToolCatalog]/[LanguageCatalog] des étapes précédentes (volume faible,
/// ~86 objets peuplés au moment de l'écriture, pas besoin de pagination).
///
/// Réutilisé pour les deux onglets de l'étape : la résolution des chaînes de
/// `backgrounds.equipment` (onglet "Historique",
/// `domain/background_equipment_resolver.dart`) ET le catalogue d'achat
/// libre groupé par catégorie (onglet "Acheter",
/// `presentation/equipment_step_screen.dart`) — un seul fetch réseau plutôt
/// que deux.
@freezed
abstract class ItemCatalog with _$ItemCatalog {
  const factory ItemCatalog({required List<ItemOption> items}) = _ItemCatalog;
}
