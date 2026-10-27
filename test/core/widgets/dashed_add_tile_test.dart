// Tests de `DashedAddTile` : effet de toucher visible (Material transparent
// au-dessus de l'InkWell), libellé sur une ligne avec ellipse.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/dashed_add_tile.dart';

void main() {
  Future<void> pump(WidgetTester tester, {VoidCallback? onTap, String? label}) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ColoredBox(
            color: Colors.white,
            child: Center(
              child: SizedBox(
                width: 200,
                child: DashedAddTile(
                  label: label ?? 'Ajouter',
                  onTap: onTap ?? () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets("l'InkWell est porté par un Material transparent", (
    tester,
  ) async {
    await pump(tester);

    final material = tester.widget<Material>(
      find
          .ancestor(of: find.byType(InkWell), matching: find.byType(Material))
          .first,
    );
    expect(material.color, Colors.transparent);
    expect(
      find.descendant(
        of: find.byType(DashedAddTile),
        matching: find.byType(Material),
      ),
      findsOneWidget,
    );
  });

  testWidgets('le tap déclenche onTap', (tester) async {
    var taps = 0;
    await pump(tester, onTap: () => taps++);

    await tester.tap(find.byType(DashedAddTile));
    expect(taps, 1);
  });

  testWidgets('libellé long : une ligne, ellipse, aucun débordement', (
    tester,
  ) async {
    await pump(tester, label: 'Libellé beaucoup trop long pour la tuile');

    expect(tester.takeException(), isNull);
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
  });
}
