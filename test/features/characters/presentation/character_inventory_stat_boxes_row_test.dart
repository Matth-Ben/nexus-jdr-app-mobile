// Tests de widget de `CharacterInventoryStatBoxesRow` — recettage utilisateur
// (2026-09-15) : quand les boxes tiennent toutes à largeur fixe sur l'écran
// courant (cas courant, 3-4 boxes), elles doivent maintenant s'étirer pour
// occuper toute la largeur disponible au lieu de laisser un espace vide à
// droite, sans perdre le défilement horizontal nécessaire quand 6 boxes ne
// tiennent pas sur un écran étroit.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/characters/domain/inventory_stat_box.dart';
import 'package:personnages/features/characters/presentation/widgets/character_inventory_stat_boxes_row.dart';

const _threeBoxes = [
  InventoryStatBox(value: '42', unit: 'PO', currency: CurrencyKind.gold),
  InventoryStatBox(value: '6', unit: 'PA', currency: CurrencyKind.silver),
  InventoryStatBox(value: '0', unit: 'KG'),
];

const _sixBoxes = [
  InventoryStatBox(value: '1', unit: 'PP', currency: CurrencyKind.platinum),
  InventoryStatBox(value: '42', unit: 'PO', currency: CurrencyKind.gold),
  InventoryStatBox(value: '2', unit: 'PE', currency: CurrencyKind.electrum),
  InventoryStatBox(value: '6', unit: 'PA', currency: CurrencyKind.silver),
  InventoryStatBox(value: '14', unit: 'PC', currency: CurrencyKind.copper),
  InventoryStatBox(value: '0', unit: 'KG'),
];

Future<void> _pump(
  WidgetTester tester,
  List<InventoryStatBox> boxes, {
  double width = 400,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: CharacterInventoryStatBoxesRow(boxes: boxes)),
    ),
  );
}

void main() {
  testWidgets(
    'peu de boxes (largeur fixe totale sous la largeur d\'écran) : chaque '
    'box est étirée (Expanded) pour occuper toute la largeur, pas de '
    'SingleChildScrollView ni d\'espace vide à droite',
    (tester) async {
      await _pump(tester, _threeBoxes, width: 400);

      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(find.byType(Expanded), findsNWidgets(_threeBoxes.length));

      final rowWidth = tester.getSize(find.byType(Row).first).width;
      // La `Row` occupe toute la largeur disponible (contrainte imposée par
      // `Expanded` au lieu de se limiter à la largeur intrinsèque des boxes,
      // ce qui laissait un espace vide à droite avant ce correctif).
      expect(rowWidth, greaterThan(300));
    },
  );

  testWidgets(
    'beaucoup de boxes sur un écran étroit (largeur fixe totale au-delà de '
    'la largeur d\'écran) : retombe sur le défilement horizontal à largeur '
    'fixe, aucune box n\'est rognée',
    (tester) async {
      await _pump(tester, _sixBoxes, width: 360);

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(Expanded), findsNothing);
      for (final box in _sixBoxes) {
        expect(find.text(box.unit), findsOneWidget);
      }
    },
  );

  testWidgets(
    'beaucoup de boxes mais écran large : tiennent sans défilement, étirées',
    (tester) async {
      await _pump(tester, _sixBoxes, width: 1200);

      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(find.byType(Expanded), findsNWidgets(_sixBoxes.length));
    },
  );

  testWidgets('la box "KG" reste non cliquable dans les deux variantes', (
    tester,
  ) async {
    await _pump(tester, _threeBoxes, width: 400);

    await tester.tap(find.text('KG'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
