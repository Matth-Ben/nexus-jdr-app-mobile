// Test d'intégration léger : vérifie que `CharacterInventoryItemCard`
// affiche un `DiceTypeBadge` pour une arme avec `damage_dice`, et rien pour
// un objet sans caractéristiques d'arme (ou une arme sans dé de dégâts,
// ex. le filet) — pas de reconstruction de la suite de tests complète de ce
// widget (aucune suite existante à ce jour).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/dice_type_badge.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/presentation/widgets/character_inventory_item_card.dart';

void main() {
  Future<void> pump(WidgetTester tester, CharacterInventoryItem item) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CharacterInventoryItemCard(item: item)),
      ),
    );
  }

  testWidgets('une arme avec damage_dice affiche un DiceTypeBadge', (
    tester,
  ) async {
    await pump(
      tester,
      const CharacterInventoryItem(
        id: 'inv-1',
        itemId: 1,
        name: 'Épée longue',
        category: 'arme',
        quantity: 1,
        equipped: false,
        weaponProperties: CharacterInventoryWeaponProperties(
          damageDice: '1d8',
          damageType: 'tranchant',
          properties: [],
        ),
      ),
    );

    expect(find.byType(DiceTypeBadge), findsOneWidget);
  });

  testWidgets('une arme sans damage_dice (ex. le filet) n\'affiche rien', (
    tester,
  ) async {
    await pump(
      tester,
      const CharacterInventoryItem(
        id: 'inv-2',
        itemId: 2,
        name: 'Filet',
        category: 'arme',
        quantity: 1,
        equipped: false,
        weaponProperties: CharacterInventoryWeaponProperties(
          damageDice: null,
          damageType: null,
          properties: [],
        ),
      ),
    );

    expect(find.byType(DiceTypeBadge), findsNothing);
  });

  testWidgets('un objet non-arme n\'affiche rien', (tester) async {
    await pump(
      tester,
      const CharacterInventoryItem(
        id: 'inv-3',
        itemId: 3,
        name: 'Corde (15 mètres)',
        category: 'equipement_general',
        quantity: 1,
        equipped: false,
      ),
    );

    expect(find.byType(DiceTypeBadge), findsNothing);
  });
}
