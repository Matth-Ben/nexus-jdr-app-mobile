import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/groups/domain/group_treasure.dart';
import 'package:personnages/features/groups/domain/group_treasure_stat_boxes_resolver.dart';

void main() {
  group('GroupTreasureStatBoxesResolver.resolve', () {
    test('les 5 pièces toujours affichées, même à 0 (décision 92 : platine '
        'et électrum ajoutables à un butin qui n\'en a pas)', () {
      const treasure = GroupTreasure(
        groupId: 'group-1',
        currencyGp: 12,
        currencySp: 3,
        currencyCp: 7,
      );

      final boxes = GroupTreasureStatBoxesResolver.resolve(treasure);

      expect(boxes.map((box) => box.unit), ['PP', 'PO', 'PE', 'PA', 'PC']);
      expect(boxes.map((box) => box.value), ['0', '12', '0', '3', '7']);
      expect(boxes.map((box) => box.currency), [
        CurrencyKind.platinum,
        CurrencyKind.gold,
        CurrencyKind.electrum,
        CurrencyKind.silver,
        CurrencyKind.copper,
      ]);
    });

    test('butin vide : 5 tuiles à 0', () {
      final boxes = GroupTreasureStatBoxesResolver.resolve(
        const GroupTreasure(groupId: 'group-1'),
      );
      expect(boxes, hasLength(5));
      expect(boxes.every((box) => box.value == '0'), isTrue);
    });

    test('aucune box "poids" (contrairement à InventoryStatBoxesResolver)', () {
      const treasure = GroupTreasure(groupId: 'group-1');
      final boxes = GroupTreasureStatBoxesResolver.resolve(treasure);
      expect(boxes.any((box) => box.unit == 'KG'), isFalse);
    });
  });
}
