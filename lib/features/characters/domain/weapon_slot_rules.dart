import 'character_inventory_item.dart';
import 'pact_weapon_rules.dart';
import 'weapon_slot.dart';

/// Règles pures de capacité des sets d'armes équipées ("set principal"/"set
/// secondaire", voir `weapon_slot.dart::WeaponSlot`) — même gabarit que
/// [PactWeaponRules]/`armor_class_calculator.dart::ArmorClassCalculator`.
///
/// Un set représente 2 "mains" ([slotCapacity]) : une arme à une main coûte
/// 1 main, une arme à deux mains coûte les 2 mains du set (une seule arme à
/// deux mains par set, jamais mélangée avec une autre arme dans ce même
/// set). Le joueur choisit explicitement dans quel set équiper une arme
/// (aucun calcul automatique de placement ici) — voir
/// `presentation/widgets/weapon_slot_picker_sheet.dart`. Ne concerne jamais
/// l'arme de pacte (système séparé, [PactWeaponRules]).
abstract final class WeaponSlotRules {
  /// Nombre de "mains" disponibles par set.
  static const int slotCapacity = 2;

  /// `true` si une des [properties] (normalisée via [PactWeaponRules
  /// .normalize]) vaut exactement « à deux mains ».
  static bool isTwoHanded(List<String> properties) => properties.any(
    (property) => PactWeaponRules.normalize(property) == 'a deux mains',
  );

  /// Coût en "mains" (voir [slotCapacity]) d'une arme depuis ses
  /// [weaponProperties] — `2` pour une arme à deux mains, `1` sinon (y
  /// compris `null`, ex. objet personnalisé jamais éligible à un set en
  /// pratique mais traité comme une arme à une main par sécurité).
  static int handCost(CharacterInventoryWeaponProperties? weaponProperties) =>
      isTwoHanded(weaponProperties?.properties ?? const []) ? 2 : 1;

  /// Détermine quelles armes actuellement équipées dans [slot] doivent être
  /// déséquipées pour que [candidate] y tienne, en ne touchant jamais
  /// l'autre set.
  ///
  /// Algorithme : accumule le coût des armes actuellement dans [slot] (dans
  /// l'ordre de [inventory], sans tri) jusqu'à libérer assez de "mains" pour
  /// [candidate] — peut libérer plus de mains que nécessaire si une seule
  /// arme à déséquiper suffit à elle seule à dépasser le besoin (on ne peut
  /// pas couper une arme en deux). Retourne une liste vide si [candidate]
  /// tient déjà sans rien déséquiper.
  static List<CharacterInventoryItem> itemsToAutoUnequip({
    required List<CharacterInventoryItem> inventory,
    required WeaponSlot slot,
    required CharacterInventoryItem candidate,
  }) {
    final inSlot = [
      for (final item in inventory)
        if (item.category == 'arme' &&
            item.equipped &&
            item.weaponSlot == slot &&
            item.id != candidate.id)
          item,
    ];

    final usedCost = inSlot.fold<int>(
      0,
      (total, item) => total + handCost(item.weaponProperties),
    );
    final candidateCost = handCost(candidate.weaponProperties);
    var needed = usedCost + candidateCost - slotCapacity;
    if (needed <= 0) return const [];

    final toUnequip = <CharacterInventoryItem>[];
    for (final item in inSlot) {
      if (needed <= 0) break;
      toUnequip.add(item);
      needed -= handCost(item.weaponProperties);
    }
    return toUnequip;
  }
}
