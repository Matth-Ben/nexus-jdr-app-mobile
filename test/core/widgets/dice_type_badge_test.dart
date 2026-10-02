import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/dice_type_badge.dart';

void main() {
  Future<void> pump(WidgetTester tester, int sides, {String label = '1dX'}) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiceTypeBadge(sides: sides, label: label),
        ),
      ),
    );
  }

  for (final sides in [4, 6, 8, 10, 12, 20]) {
    testWidgets('rendu sans exception pour un dé à $sides faces', (
      tester,
    ) async {
      await pump(tester, sides, label: '1d$sides');
      expect(tester.takeException(), isNull);
      expect(find.byType(DiceTypeBadge), findsOneWidget);
    });
  }

  testWidgets('repli générique sans exception pour 100 faces (hors liste)', (
    tester,
  ) async {
    await pump(tester, 100, label: '1d100');
    expect(tester.takeException(), isNull);
    expect(find.byType(DiceTypeBadge), findsOneWidget);
  });

  testWidgets('repli générique sans exception pour 3 faces (hors liste)', (
    tester,
  ) async {
    await pump(tester, 3, label: '1d3');
    expect(tester.takeException(), isNull);
    expect(find.byType(DiceTypeBadge), findsOneWidget);
  });

  testWidgets('le Semantics porte le bon label', (tester) async {
    await pump(tester, 8, label: '1d8');
    final semanticsNode = tester.getSemantics(find.byType(DiceTypeBadge));
    expect(semanticsNode.label, 'dé à 8 faces, 1d8');
  });

  testWidgets('le Semantics porte le nombre de faces réel même en repli '
      'générique (d100)', (tester) async {
    await pump(tester, 100, label: '1d100');
    final semanticsNode = tester.getSemantics(find.byType(DiceTypeBadge));
    expect(semanticsNode.label, 'dé à 100 faces, 1d100');
  });

  testWidgets('aucune interactivité propre : pas de GestureDetector/InkWell '
      'dans l\'arbre du widget', (tester) async {
    await pump(tester, 8, label: '1d8');

    final diceTypeBadgeFinder = find.byType(DiceTypeBadge);
    expect(
      find.descendant(
        of: diceTypeBadgeFinder,
        matching: find.byType(GestureDetector),
      ),
      findsNothing,
    );
    expect(
      find.descendant(of: diceTypeBadgeFinder, matching: find.byType(InkWell)),
      findsNothing,
    );
  });
}
