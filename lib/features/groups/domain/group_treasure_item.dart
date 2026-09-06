/// Une entrée d'objet en attente d'attribution dans le butin commun
/// (`group_treasure.items`, jsonb) — voir `data/group_repository.dart` pour
/// la lecture/écriture de ce tableau.
///
/// Volontairement une classe simple (pas `freezed`), même précédent que
/// `RewardItemDraft`/`InventoryCatalogItem` : donnée déjà résolue,
/// sérialisée telle quelle dans le jsonb.
///
/// [displayName] est dénormalisé (jamais résolu à la lecture via une
/// jointure `translations`) : contrairement à `character_inventory`, cette
/// entrée n'a pas de ligne dédiée en base pouvant porter un `item_id` fiable
/// à tout moment (un objet du catalogue peut être ajouté au butin par
/// n'importe quel membre) — le nom est donc figé au moment de l'ajout, une
/// fois pour toutes, plutôt que résolu à chaque lecture.
class GroupTreasureItem {
  const GroupTreasureItem({
    this.itemId,
    this.customName,
    required this.displayName,
    required this.quantity,
  });

  final int? itemId;
  final String? customName;
  final String displayName;
  final int quantity;

  bool get isCustom => itemId == null;

  GroupTreasureItem copyWith({int? quantity}) => GroupTreasureItem(
    itemId: itemId,
    customName: customName,
    displayName: displayName,
    quantity: quantity ?? this.quantity,
  );

  /// Identifie la "même" entrée pour une réclamation (voir
  /// `GroupRepository.claimTreasureItem`) — par `itemId` s'il est non nul,
  /// sinon par `customName`+[displayName]. Risque documenté d'ambiguïté si
  /// deux entrées personnalisées strictement identiques coexistent (même
  /// principe de risque de course accepté que le reste de cette écriture,
  /// voir la doc de classe de `GroupRepository`).
  bool matches(GroupTreasureItem other) {
    if (itemId != null || other.itemId != null) return itemId == other.itemId;
    return customName == other.customName && displayName == other.displayName;
  }

  Map<String, dynamic> toJson() => {
    if (itemId != null) 'item_id': itemId,
    if (customName != null) 'custom_name': customName,
    'display_name': displayName,
    'quantity': quantity,
  };

  static GroupTreasureItem fromJson(Map<String, dynamic> json) {
    return GroupTreasureItem(
      itemId: (json['item_id'] as num?)?.toInt(),
      customName: json['custom_name'] as String?,
      displayName: (json['display_name'] as String?) ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GroupTreasureItem &&
      other.itemId == itemId &&
      other.customName == customName &&
      other.displayName == displayName &&
      other.quantity == quantity;

  @override
  int get hashCode => Object.hash(itemId, customName, displayName, quantity);
}
