/// Une ligne d'objet en cours de composition dans la sheet "Ajouter une
/// récompense" (`presentation/widgets/add_reward_sheet.dart`), avant tout
/// appel réseau — voir `CharacterRepository.addReward`, qui insère toutes
/// les lignes en un seul appel `insert` batché à la validation.
///
/// Représente soit un objet du catalogue ([itemId] non nul), soit un objet
/// personnalisé ([customName] non nul) — jamais les deux, jamais aucun des
/// deux (garanti par construction côté sheet, voir [isCustom]).
///
/// [customDescription]/[customDamageDice]/[customDamageType]/
/// [customProperties] : propagés depuis [PickedInventoryAddition] pour un
/// objet personnalisé (voir `presentation/widgets/add_item_flow.dart`),
/// toujours `null`/vide pour un objet du catalogue — mêmes règles que sur
/// `PickedInventoryAddition`.
class RewardItemDraft {
  const RewardItemDraft({
    this.itemId,
    this.customName,
    required this.displayName,
    required this.quantity,
    this.customDescription,
    this.customDamageDice,
    this.customDamageType,
    this.customProperties = const [],
  });

  final int? itemId;
  final String? customName;

  /// Nom déjà résolu, affiché tel quel dans la liste "en cours" de la sheet
  /// (nom du catalogue déjà traduit pour [itemId], ou [customName] lui-même)
  /// — évite de porter une map de résolution de noms jusque dans cette
  /// sheet pour un simple affichage local.
  final String displayName;

  final int quantity;

  final String? customDescription;
  final String? customDamageDice;
  final String? customDamageType;
  final List<String> customProperties;

  bool get isCustom => itemId == null;
}
