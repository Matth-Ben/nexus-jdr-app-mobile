import '../../characters/domain/currency_kind.dart';
import '../../characters/domain/inventory_stat_box.dart';
import 'group_treasure.dart';

/// Construit les [InventoryStatBox] de tête de l'onglet "Butin" — réutilise
/// le même composant visuel que l'onglet "Inventaire" d'un personnage
/// (`CharacterInventoryStatBoxesRow`, voir la spec de la tâche "Système de
/// groupe" : "réutilisé à l'identique visuellement"), mais jamais cliquable
/// ici (pas de tap pour ajuster une monnaie individuellement — seulement
/// "Ajouter"/"S'attribuer", voir `presentation/group_screen.dart`) et sans
/// box "poids" (le butin commun n'a pas de notion de poids porté).
///
/// Même règle d'affichage que `InventoryStatBoxesResolver` pour
/// or/argent/cuivre (toujours affichées) et platine/électrum (seulement si
/// non nulles).
abstract final class GroupTreasureStatBoxesResolver {
  static List<InventoryStatBox> resolve(GroupTreasure treasure) {
    final boxes = <InventoryStatBox>[];

    if (treasure.currencyPp != 0) {
      boxes.add(
        InventoryStatBox(
          value: '${treasure.currencyPp}',
          unit: 'PP',
          currency: CurrencyKind.platinum,
        ),
      );
    }
    boxes.add(
      InventoryStatBox(
        value: '${treasure.currencyGp}',
        unit: 'PO',
        currency: CurrencyKind.gold,
      ),
    );
    if (treasure.currencyEp != 0) {
      boxes.add(
        InventoryStatBox(
          value: '${treasure.currencyEp}',
          unit: 'PE',
          currency: CurrencyKind.electrum,
        ),
      );
    }
    boxes.add(
      InventoryStatBox(
        value: '${treasure.currencySp}',
        unit: 'PA',
        currency: CurrencyKind.silver,
      ),
    );
    boxes.add(
      InventoryStatBox(
        value: '${treasure.currencyCp}',
        unit: 'PC',
        currency: CurrencyKind.copper,
      ),
    );

    return boxes;
  }
}
