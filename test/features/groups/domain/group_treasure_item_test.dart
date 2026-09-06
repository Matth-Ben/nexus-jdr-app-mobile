import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/groups/domain/group_treasure_item.dart';

void main() {
  group('GroupTreasureItem.matches', () {
    test('deux entrées catalogue avec le même itemId correspondent', () {
      const a = GroupTreasureItem(itemId: 42, displayName: 'Épée', quantity: 1);
      const b = GroupTreasureItem(itemId: 42, displayName: 'Épée', quantity: 3);
      expect(a.matches(b), isTrue);
    });

    test('itemId différents ne correspondent jamais', () {
      const a = GroupTreasureItem(itemId: 42, displayName: 'Épée', quantity: 1);
      const b = GroupTreasureItem(itemId: 43, displayName: 'Épée', quantity: 1);
      expect(a.matches(b), isFalse);
    });

    test(
      'objets personnalisés : correspondance par customName + displayName',
      () {
        const a = GroupTreasureItem(
          customName: 'Amulette de famille',
          displayName: 'Amulette de famille',
          quantity: 1,
        );
        const b = GroupTreasureItem(
          customName: 'Amulette de famille',
          displayName: 'Amulette de famille',
          quantity: 2,
        );
        expect(a.matches(b), isTrue);
      },
    );

    test('un objet catalogue et un objet personnalisé ne correspondent '
        'jamais (itemId non nul vs nul)', () {
      const a = GroupTreasureItem(itemId: 42, displayName: 'Épée', quantity: 1);
      const b = GroupTreasureItem(
        customName: 'Épée',
        displayName: 'Épée',
        quantity: 1,
      );
      expect(a.matches(b), isFalse);
    });
  });

  group('GroupTreasureItem.isCustom', () {
    test('vrai sans itemId', () {
      const item = GroupTreasureItem(
        customName: 'Babiole',
        displayName: 'Babiole',
        quantity: 1,
      );
      expect(item.isCustom, isTrue);
    });

    test('faux avec itemId', () {
      const item = GroupTreasureItem(
        itemId: 1,
        displayName: 'Épée',
        quantity: 1,
      );
      expect(item.isCustom, isFalse);
    });
  });

  group('GroupTreasureItem JSON round-trip', () {
    test('objet catalogue', () {
      const item = GroupTreasureItem(
        itemId: 7,
        displayName: 'Bouclier',
        quantity: 2,
      );
      final json = item.toJson();
      expect(json, {'item_id': 7, 'display_name': 'Bouclier', 'quantity': 2});
      expect(GroupTreasureItem.fromJson(json), item);
    });

    test('objet personnalisé', () {
      const item = GroupTreasureItem(
        customName: 'Amulette',
        displayName: 'Amulette',
        quantity: 1,
      );
      final json = item.toJson();
      expect(json, {
        'custom_name': 'Amulette',
        'display_name': 'Amulette',
        'quantity': 1,
      });
      expect(GroupTreasureItem.fromJson(json), item);
    });

    test('fromJson tolère les champs manquants (défauts sûrs)', () {
      final item = GroupTreasureItem.fromJson(const {});
      expect(item.itemId, isNull);
      expect(item.customName, isNull);
      expect(item.displayName, '');
      expect(item.quantity, 0);
    });
  });

  test('copyWith ne change que la quantité', () {
    const item = GroupTreasureItem(itemId: 1, displayName: 'Épée', quantity: 2);
    final updated = item.copyWith(quantity: 5);
    expect(updated.quantity, 5);
    expect(updated.itemId, 1);
    expect(updated.displayName, 'Épée');
  });
}
