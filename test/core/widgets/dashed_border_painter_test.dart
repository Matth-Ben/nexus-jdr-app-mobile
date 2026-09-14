// Tests unitaires de `DashedBorderPainter`, en particulier son paramètre
// `shape` (recettage direction-artistique du 13/09, ajouté pour les
// médaillons circulaires en pointillés des états vides de
// `character_list_screen.dart`/`group_list_screen.dart`).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/dashed_border_painter.dart';

void main() {
  test('shape par défaut : BoxShape.rectangle (comportement historique '
      'inchangé pour les appelants existants, ex. PortraitFrame/'
      'DashedAddTile/DashedButton)', () {
    const painter = DashedBorderPainter(color: Colors.black);
    expect(painter.shape, BoxShape.rectangle);
  });

  group('shouldRepaint', () {
    test('renvoie false quand rien ne change', () {
      const a = DashedBorderPainter(color: Colors.black);
      const b = DashedBorderPainter(color: Colors.black);
      expect(a.shouldRepaint(b), isFalse);
    });

    test('renvoie true quand shape change (rectangle -> circle)', () {
      const rectangle = DashedBorderPainter(color: Colors.black);
      const circle = DashedBorderPainter(
        color: Colors.black,
        shape: BoxShape.circle,
      );
      expect(circle.shouldRepaint(rectangle), isTrue);
    });

    test('renvoie true quand la couleur change (shape inchangée)', () {
      const a = DashedBorderPainter(color: Colors.black);
      const b = DashedBorderPainter(color: Colors.white);
      expect(a.shouldRepaint(b), isTrue);
    });
  });

  testWidgets(
    'shape: BoxShape.circle ne lève aucune exception au rendu (tracé via '
    'Path.addOval plutôt que Path.addRect)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 88,
                height: 88,
                child: CustomPaint(
                  painter: const DashedBorderPainter(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(CustomPaint), findsWidgets);
    },
  );
}
