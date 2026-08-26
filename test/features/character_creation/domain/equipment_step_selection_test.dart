import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/equipment_choice_tab.dart';
import 'package:personnages/features/character_creation/domain/equipment_step_selection.dart';
import 'package:personnages/features/character_creation/domain/item_option.dart';

const _dague = ItemOption(
  id: 2,
  name: 'Dague',
  category: 'arme',
  costAmount: 2,
);
const _fleche = ItemOption(
  id: 3,
  name: 'Flèche',
  category: 'arme',
  costAmount: 0.05,
);

void main() {
  group('totalCost', () {
    test('somme le coût unitaire * quantité pour chaque entrée du panier', () {
      final total = EquipmentStepSelection.totalCost(
        cart: {'Dague': 2, 'Flèche': 20},
        items: [_dague, _fleche],
      );

      expect(total, 5); // 2*2 + 20*0.05
    });

    test('panier vide -> 0', () {
      expect(EquipmentStepSelection.totalCost(cart: {}, items: [_dague]), 0);
    });

    test('une entrée du panier sans correspondance dans le catalogue ne '
        'contribue rien (plutôt que de crasher)', () {
      final total = EquipmentStepSelection.totalCost(
        cart: {'Objet inconnu': 3},
        items: [_dague],
      );

      expect(total, 0);
    });

    test('arrondit le résultat à 2 décimales (imprécision binaire '
        'résiduelle)', () {
      final total = EquipmentStepSelection.totalCost(
        cart: {'Flèche': 3},
        items: [_fleche],
      );

      expect(total, 0.15);
    });
  });

  group('remainingGold', () {
    test('budget - dépensé', () {
      expect(
        EquipmentStepSelection.remainingGold(startingGold: 15, spent: 4),
        11,
      );
    });

    test('peut devenir négatif (budget dépassé)', () {
      expect(
        EquipmentStepSelection.remainingGold(startingGold: 10, spent: 12),
        -2,
      );
    });
  });

  group('isOverBudget', () {
    test('négatif -> dépassé', () {
      expect(EquipmentStepSelection.isOverBudget(-0.01), isTrue);
    });

    test('nul ou positif -> pas dépassé', () {
      expect(EquipmentStepSelection.isOverBudget(0), isFalse);
      expect(EquipmentStepSelection.isOverBudget(5), isFalse);
    });
  });

  group('canProceed', () {
    test('onglet "Historique" -> toujours actif, quel que soit le solde', () {
      expect(
        EquipmentStepSelection.canProceed(
          activeTab: EquipmentChoiceTab.background,
          remainingGold: -999,
        ),
        isTrue,
      );
    });

    test('onglet "Acheter" avec budget non dépassé -> actif même si rien '
        "n'est acheté (solde égal au budget de départ)", () {
      expect(
        EquipmentStepSelection.canProceed(
          activeTab: EquipmentChoiceTab.purchase,
          remainingGold: 15,
        ),
        isTrue,
      );
    });

    test('onglet "Acheter" avec budget dépassé -> bloqué', () {
      expect(
        EquipmentStepSelection.canProceed(
          activeTab: EquipmentChoiceTab.purchase,
          remainingGold: -0.01,
        ),
        isFalse,
      );
    });

    test('onglet "Acheter" avec solde pile à zéro -> actif (dépassement '
        'strict requis pour bloquer)', () {
      expect(
        EquipmentStepSelection.canProceed(
          activeTab: EquipmentChoiceTab.purchase,
          remainingGold: 0,
        ),
        isTrue,
      );
    });
  });

  group('setQuantity', () {
    test('ajoute une nouvelle entrée', () {
      expect(
        EquipmentStepSelection.setQuantity(
          current: {},
          name: 'Dague',
          quantity: 1,
        ),
        {'Dague': 1},
      );
    });

    test('met à jour la quantité d\'une entrée déjà présente', () {
      expect(
        EquipmentStepSelection.setQuantity(
          current: {'Dague': 1},
          name: 'Dague',
          quantity: 3,
        ),
        {'Dague': 3},
      );
    });

    test('quantité à 0 retire l\'entrée plutôt que de garder une clé à 0', () {
      expect(
        EquipmentStepSelection.setQuantity(
          current: {'Dague': 1, 'Flèche': 5},
          name: 'Dague',
          quantity: 0,
        ),
        {'Flèche': 5},
      );
    });

    test('quantité négative retire aussi l\'entrée', () {
      expect(
        EquipmentStepSelection.setQuantity(
          current: {'Dague': 1},
          name: 'Dague',
          quantity: -1,
        ),
        isEmpty,
      );
    });

    test('ne mute jamais la map fournie (copie défensive)', () {
      final original = {'Dague': 1};
      EquipmentStepSelection.setQuantity(
        current: original,
        name: 'Flèche',
        quantity: 2,
      );

      expect(original, {'Dague': 1});
    });
  });
}
