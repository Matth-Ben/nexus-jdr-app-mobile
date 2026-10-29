import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/domain/inventory_stat_boxes_resolver.dart';

CharacterDetail _detail({
  int currencyGp = 0,
  int currencyPp = 0,
  int currencyEp = 0,
  int currencySp = 0,
  int currencyCp = 0,
  List<CharacterInventoryItem> inventory = const [],
}) {
  return CharacterDetail(
    id: '1',
    name: 'Test',
    classes: const [],
    xp: 0,
    currentHp: 10,
    maxHp: 10,
    temporaryHp: 0,
    abilityScores: const {},
    currencyGp: currencyGp,
    currencyPp: currencyPp,
    currencyEp: currencyEp,
    currencySp: currencySp,
    currencyCp: currencyCp,
    inventory: inventory,
  );
}

void main() {
  group('InventoryStatBoxesResolver.resolve', () {
    test('or/argent/cuivre toujours affichés (même à 0), platine/électrum '
        'jamais quand nuls', () {
      final boxes = InventoryStatBoxesResolver.resolve(
        _detail(currencyGp: 42, currencySp: 6, currencyCp: 14),
      );

      expect(boxes.map((b) => b.unit).toList(), ['PO', 'PA', 'PC']);
      expect(boxes[0].value, '42');
      expect(boxes[1].value, '6');
      expect(boxes[2].value, '14');
    });

    test('platine non nulle insérée avant l\'or, électrum non nulle entre or '
        'et argent', () {
      final boxes = InventoryStatBoxesResolver.resolve(
        _detail(currencyPp: 2, currencyGp: 42, currencyEp: 3, currencySp: 6),
      );

      expect(boxes.map((b) => b.unit).toList(), [
        'PP',
        'PO',
        'PE',
        'PA',
        'PC',
      ]);
      expect(boxes[0].value, '2');
      expect(boxes[2].value, '3');
    });

    test(
      'aucune box "KG" (poids total) : doublon avec la jauge "CHARGE" '
      'affichée juste en dessous, quel que soit le contenu de l\'inventaire',
      () {
        final boxes = InventoryStatBoxesResolver.resolve(
          _detail(
            inventory: const [
              CharacterInventoryItem(
                id: '1',
                itemId: 1,
                name: 'Dague',
                category: 'arme',
                quantity: 2,
                equipped: false,
                totalWeight: 1,
              ),
              CharacterInventoryItem(
                id: '2',
                itemId: 2,
                name: 'Sac à dos',
                category: 'equipement_general',
                quantity: 1,
                equipped: false,
                totalWeight: 5,
              ),
            ],
          ),
        );

        expect(boxes.where((b) => b.unit == 'KG'), isEmpty);
      },
    );

    test('box "HARM." absente sans objet harmonisable dans l\'inventaire', () {
      final boxes = InventoryStatBoxesResolver.resolve(
        _detail(
          inventory: const [
            CharacterInventoryItem(
              id: '1',
              itemId: 1,
              name: 'Dague',
              category: 'arme',
              quantity: 1,
              equipped: false,
            ),
          ],
        ),
      );

      expect(boxes.where((b) => b.unit == 'HARM.'), isEmpty);
    });

    test('box "HARM." affichée dès qu\'un objet harmonisable existe, compte '
        'sur 3 (plafond RAW 5e)', () {
      final boxes = InventoryStatBoxesResolver.resolve(
        _detail(
          inventory: const [
            CharacterInventoryItem(
              id: '1',
              itemId: 1,
              name: 'Anneau',
              category: 'objet_magique',
              quantity: 1,
              equipped: false,
              requiresAttunement: true,
              isAttuned: true,
            ),
            CharacterInventoryItem(
              id: '2',
              itemId: 2,
              name: 'Amulette',
              category: 'objet_magique',
              quantity: 1,
              equipped: false,
              requiresAttunement: true,
            ),
          ],
        ),
      );

      final harmBox = boxes.singleWhere((b) => b.unit == 'HARM.');
      expect(harmBox.value, '1/3');
      // Toujours en dernier (il n'y a plus de box "KG" après elle).
      expect(boxes.last.unit, 'HARM.');
    });
  });
}
