import '../../characters/domain/currency_kind.dart';
import '../../characters/domain/inventory_stat_box.dart';
import 'group_treasure.dart';

/// Construit les [InventoryStatBox] de tête de l'onglet "Butin" — réutilise
/// le même composant visuel que l'onglet "Inventaire" d'un personnage
/// (`CharacterInventoryStatBoxesRow`, voir la spec de la tâche "Système de
/// groupe" : "réutilisé à l'identique visuellement"), cliquable comme dans
/// l'inventaire depuis la décision 91 (ajout, ajustement, retrait,
/// conversion), sans box "poids" (le butin commun n'a pas de notion de poids
/// porté).
///
/// **Les 5 pièces sont toujours affichées, même à 0** (décision 92) : toucher
/// une tuile est le seul accès à la monnaie du butin, platine et électrum
/// doivent donc rester ajoutables à un butin qui n'en a pas. L'inventaire
/// d'un personnage garde sa propre règle (`InventoryStatBoxesResolver` :
/// platine et électrum seulement si non nulles). Même ordre que l'inventaire
/// : PP, PO, PE, PA, PC.
abstract final class GroupTreasureStatBoxesResolver {
  static List<InventoryStatBox> resolve(GroupTreasure treasure) => [
    InventoryStatBox(
      value: '${treasure.currencyPp}',
      unit: 'PP',
      currency: CurrencyKind.platinum,
    ),
    InventoryStatBox(
      value: '${treasure.currencyGp}',
      unit: 'PO',
      currency: CurrencyKind.gold,
    ),
    InventoryStatBox(
      value: '${treasure.currencyEp}',
      unit: 'PE',
      currency: CurrencyKind.electrum,
    ),
    InventoryStatBox(
      value: '${treasure.currencySp}',
      unit: 'PA',
      currency: CurrencyKind.silver,
    ),
    InventoryStatBox(
      value: '${treasure.currencyCp}',
      unit: 'PC',
      currency: CurrencyKind.copper,
    ),
  ];
}
