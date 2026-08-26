import 'background_equipment_parser.dart';
import 'background_equipment_resolver.dart';
import 'background_option.dart';
import 'equipment_choice_tab.dart';
import 'equipment_step_selection.dart';
import 'item_catalog.dart';

/// Une ligne prête pour `character_inventory` (`item_id` nullable +
/// `custom_name`, `quantity` — `equipped`/`notes` sont des constantes à
/// l'écriture, voir `data/character_creation_repository.dart`), produite par
/// [CharacterCreationEquipmentResolver.resolve].
typedef InventoryLineDraft = ({int? itemId, String? customName, int quantity});

/// Résout l'équipement de départ ET la devise `characters.currency_gp` selon
/// l'onglet retenu à l'étape 7/9 (`CharacterCreationDraft.equipmentChoiceTab`),
/// à l'étape 9/9 "Récapitulatif" de l'assistant de création — un seul point
/// d'entrée pour les deux onglets, puisque leurs règles de calcul de devise
/// diffèrent (voir le détail par cas ci-dessous) mais partagent le même type
/// de sortie.
///
/// Le budget d'achat de l'onglet "Acheter" est **toujours** dérivé de la
/// "Bourse" de l'historique choisi à l'étape 3/9 (décision déjà actée à
/// l'étape 7/9, voir `presentation/equipment_step_screen.dart`) : [resolve]
/// a donc toujours besoin de [backgroundOption], même sur cet onglet.
abstract final class CharacterCreationEquipmentResolver {
  static ({List<InventoryLineDraft> inventory, int currencyGp}) resolve({
    required EquipmentChoiceTab tab,
    required BackgroundOption backgroundOption,
    required Map<String, int> purchasedEquipment,
    required ItemCatalog itemCatalog,
  }) {
    final startingGold =
        BackgroundEquipmentParser.extractStartingGold(
          backgroundOption.equipment,
        ) ??
        0;

    if (tab == EquipmentChoiceTab.purchase) {
      return _resolvePurchase(
        purchasedEquipment: purchasedEquipment,
        itemCatalog: itemCatalog,
        startingGold: startingGold,
      );
    }
    return _resolveBackground(
      backgroundOption: backgroundOption,
      itemCatalog: itemCatalog,
      startingGold: startingGold,
    );
  }

  /// Onglet "Historique" : réutilise `BackgroundEquipmentResolver` (étape
  /// 7/9) tel quel, une ligne `character_inventory` par entrée résolue
  /// (`quantity: 1` — même rationale que la maquette de l'onglet, qui ne
  /// montre jamais de quantité multiple pour l'équipement d'historique).
  /// `currency_gp` = la "Bourse" extraite telle quelle (arrondi entier —
  /// c'est déjà un entier dans les données réelles, voir
  /// `domain/background_equipment_parser.dart`).
  static ({List<InventoryLineDraft> inventory, int currencyGp})
  _resolveBackground({
    required BackgroundOption backgroundOption,
    required ItemCatalog itemCatalog,
    required int startingGold,
  }) {
    final equipmentLines = BackgroundEquipmentParser.withoutStartingGoldLine(
      backgroundOption.equipment,
    );
    final resolvedEntries = BackgroundEquipmentResolver.resolve(
      equipmentLines: equipmentLines,
      catalog: itemCatalog,
    );

    final inventory = [
      for (final entry in resolvedEntries)
        (
          itemId: entry.itemId,
          customName: entry.itemId == null ? entry.name : null,
          quantity: 1,
        ),
    ];

    return (inventory: inventory, currencyGp: startingGold);
  }

  /// Onglet "Acheter" : résout le panier `{nom: quantité}` contre [catalog]
  /// (une entrée sans correspondance est ignorée plutôt que de crasher — ne
  /// devrait normalement jamais arriver, le panier n'est peuplé qu'à partir
  /// de ce même catalogue à l'étape 7/9). `currency_gp` = `startingGold -
  /// coût total du panier`, arrondi à l'entier le plus proche (aucune
  /// ventilation pa/po/pc n'est modélisée ailleurs dans ce dépôt,
  /// `currency_gp` est `int not null`).
  static ({List<InventoryLineDraft> inventory, int currencyGp})
  _resolvePurchase({
    required Map<String, int> purchasedEquipment,
    required ItemCatalog itemCatalog,
    required int startingGold,
  }) {
    final itemByName = {for (final item in itemCatalog.items) item.name: item};

    final inventory = <InventoryLineDraft>[];
    for (final entry in purchasedEquipment.entries) {
      final item = itemByName[entry.key];
      if (item == null) continue;
      inventory.add((itemId: item.id, customName: null, quantity: entry.value));
    }

    final spent = EquipmentStepSelection.totalCost(
      cart: purchasedEquipment,
      items: itemCatalog.items,
    );
    final currencyGp = (startingGold - spent).round();

    return (inventory: inventory, currencyGp: currencyGp);
  }
}
