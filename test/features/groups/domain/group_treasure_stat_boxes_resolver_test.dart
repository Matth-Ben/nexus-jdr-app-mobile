import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/groups/domain/group_treasure.dart';
import 'package:personnages/features/groups/domain/group_treasure_stat_boxes_resolver.dart';

void main() {
  group('GroupTreasureStatBoxesResolver.resolve', () {
    test(
      'or/argent/cuivre toujours affichées, platine/électrum omises si nulles',
      () {
        const treasure = GroupTreasure(
          groupId: 'group-1',
          currencyGp: 12,
          currencySp: 3,
          currencyCp: 7,
        );

        final boxes = GroupTreasureStatBoxesResolver.resolve(treasure);

        expect(boxes.map((box) => box.unit), ['PO', 'PA', 'PC']);
        expect(boxes.map((box) => box.value), ['12', '3', '7']);
        expect(boxes.map((box) => box.currency), [
          CurrencyKind.gold,
          CurrencyKind.silver,
          CurrencyKind.copper,
        ]);
      },
    );

    test('platine affichée en tête si non nulle, électrum avant PA/PC si non nulle', () {
      const treasure = GroupTreasure(
        groupId: 'group-1',
        currencyPp: 2,
        currencyGp: 10,
        currencyEp: 1,
        currencySp: 0,
        currencyCp: 0,
      );

      final boxes = GroupTreasureStatBoxesResolver.resolve(treasure);

      expect(boxes.map((box) => box.unit), ['PP', 'PO', 'PE', 'PA', 'PC']);
    });

    test('aucune box "poids" (contrairement à InventoryStatBoxesResolver)', () {
      const treasure = GroupTreasure(groupId: 'group-1');
      final boxes = GroupTreasureStatBoxesResolver.resolve(treasure);
      expect(boxes.any((box) => box.unit == 'KG'), isFalse);
    });
  });
}
