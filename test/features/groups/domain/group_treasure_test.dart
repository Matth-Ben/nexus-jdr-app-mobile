import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/groups/domain/group_treasure.dart';

void main() {
  group('GroupTreasure.hasNoCurrency', () {
    test('vrai quand toutes les monnaies sont à 0', () {
      const treasure = GroupTreasure(groupId: 'group-1');
      expect(treasure.hasNoCurrency, isTrue);
    });

    test('faux dès qu\'une monnaie est non nulle', () {
      const treasure = GroupTreasure(groupId: 'group-1', currencyGp: 12);
      expect(treasure.hasNoCurrency, isFalse);
    });

    test('faux même pour une monnaie rare (platine/électrum) seule', () {
      const treasure = GroupTreasure(groupId: 'group-1', currencyPp: 1);
      expect(treasure.hasNoCurrency, isFalse);
    });
  });
}
