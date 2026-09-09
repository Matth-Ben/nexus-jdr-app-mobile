import 'character_detail.dart';
import 'currency_kind.dart';
import 'inventory_stat_box.dart';
import 'inventory_weight_calculator.dart';
import 'weight_formatter.dart';

/// Construit les [InventoryStatBox] de la rangée en tête de l'onglet
/// "Inventaire" — voir `docs/cahier-des-charges/09-maquettes-captures.md`,
/// section "Onglet Inventaire".
///
/// Le personnage porte en réalité 5 monnaies (`currency_gp`/`pp`/`ep`/`sp`/
/// `cp`), mais la maquette n'en montre que 3 (or/argent/cuivre) + le poids
/// total, dans cet ordre. Décision prise pour cette itération (à valider par
/// le chef de projet si elle doit changer) :
/// - or/argent/cuivre sont **toujours** affichés, dans l'ordre de la
///   maquette, même à 0 (ce sont les monnaies les plus courantes ; les
///   masquer à 0 ferait disparaître des boxes en cours de partie, ce qui
///   serait plus déroutant qu'utile) ;
/// - platine/électrum ne sont affichés que s'ils sont non nuls, pour ne pas
///   surcharger l'écran dans le cas courant (un personnage qui n'en a
///   jamais eu) tout en ne perdant jamais l'information s'ils sont utilisés ;
/// - quand affichées, platine et électrum sont insérées respectivement
///   avant l'or et entre l'or et l'argent — ordre de valeur décroissante
///   standard D&D (pp > gp > ep > sp > cp), pas explicitement montré par la
///   maquette (qui n'affiche jamais les deux) mais le plus prévisible pour
///   un joueur habitué au jeu ;
/// - la box "poids" est toujours affichée en dernier, sauf si au moins un
///   objet harmonisable existe dans l'inventaire, auquel cas une box
///   "HARM." (nombre d'objets harmonisés / [CharacterDetail.attunementCap])
///   la suit — même logique d'affichage conditionnel que platine/électrum,
///   mais sur la présence d'un objet harmonisable plutôt que sur une valeur
///   non nulle (voir `docs/cahier-des-charges/`
///   11-fonctionnalites-a-ajouter.md, section "Onglet Inventaire").
///
/// La rangée peut dépasser 4 boxes (jusqu'à 7 : pp, gp, ep, sp, cp, poids,
/// harm.) — c'est au widget de rendu
/// (`character_inventory_stat_boxes_row.dart`) de la rendre défilable
/// horizontalement dans ce cas, pas à ce resolver.
abstract final class InventoryStatBoxesResolver {
  static List<InventoryStatBox> resolve(CharacterDetail detail) {
    final boxes = <InventoryStatBox>[];

    if (detail.currencyPp != 0) {
      boxes.add(
        InventoryStatBox(
          value: '${detail.currencyPp}',
          unit: 'PP',
          currency: CurrencyKind.platinum,
        ),
      );
    }
    boxes.add(
      InventoryStatBox(
        value: '${detail.currencyGp}',
        unit: 'PO',
        currency: CurrencyKind.gold,
      ),
    );
    if (detail.currencyEp != 0) {
      boxes.add(
        InventoryStatBox(
          value: '${detail.currencyEp}',
          unit: 'PE',
          currency: CurrencyKind.electrum,
        ),
      );
    }
    boxes.add(
      InventoryStatBox(
        value: '${detail.currencySp}',
        unit: 'PA',
        currency: CurrencyKind.silver,
      ),
    );
    boxes.add(
      InventoryStatBox(
        value: '${detail.currencyCp}',
        unit: 'PC',
        currency: CurrencyKind.copper,
      ),
    );

    // "KG", pas "LBS" comme la maquette : `items.weight` est stocké en
    // kilogrammes côté base, voir la documentation de
    // `CharacterInventoryItem.totalWeight`.
    final totalWeight = InventoryWeightCalculator.totalOf(detail.inventory);
    boxes.add(
      InventoryStatBox(value: WeightFormatter.format(totalWeight), unit: 'KG'),
    );

    // "HARM." (objets harmonisés) : seulement si au moins un objet de
    // l'inventaire peut être harmonisé — même principe que platine/électrum
    // ci-dessus ("ne pas surcharger l'écran d'un compteur toujours à 0/0
    // pour un personnage qui ne croise jamais d'objet magique").
    final attunableCount = detail.inventory
        .where((item) => item.requiresAttunement)
        .length;
    if (attunableCount > 0) {
      boxes.add(
        InventoryStatBox(
          value: '${detail.attunedItemCount}/${CharacterDetail.attunementCap}',
          unit: 'HARM.',
        ),
      );
    }

    return boxes;
  }
}
