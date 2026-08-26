// Tests de widget de `SegmentedToggle` (design système section 4, "Bascule
// segmentée").

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/segmented_toggle.dart';

enum _Method { a, b, c }

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('affiche un segment par option, en majuscules', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        SegmentedToggle<_Method>(
          options: const [
            SegmentedToggleOption(value: _Method.a, label: 'Tableau'),
            SegmentedToggleOption(value: _Method.b, label: 'Points'),
            SegmentedToggleOption(value: _Method.c, label: 'Dés'),
          ],
          value: _Method.a,
          onChanged: (_) {},
        ),
      ),
    );

    expect(find.text('TABLEAU'), findsOneWidget);
    expect(find.text('POINTS'), findsOneWidget);
    expect(find.text('DÉS'), findsOneWidget);
  });

  testWidgets('taper un segment appelle onChanged avec sa valeur', (
    WidgetTester tester,
  ) async {
    _Method? selected;

    await tester.pumpWidget(
      _wrap(
        SegmentedToggle<_Method>(
          options: const [
            SegmentedToggleOption(value: _Method.a, label: 'Tableau'),
            SegmentedToggleOption(value: _Method.b, label: 'Points'),
          ],
          value: _Method.a,
          onChanged: (value) => selected = value,
        ),
      ),
    );

    await tester.tap(find.text('POINTS'));
    await tester.pumpAndSettle();

    expect(selected, _Method.b);
  });

  testWidgets('la zone de tap de chaque segment atteint 44px de haut '
      '(design système section 7, accessibilité)', (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(
        SegmentedToggle<_Method>(
          options: const [
            SegmentedToggleOption(value: _Method.a, label: 'Tableau'),
            SegmentedToggleOption(value: _Method.b, label: 'Points'),
            SegmentedToggleOption(value: _Method.c, label: 'Dés'),
          ],
          value: _Method.a,
          onChanged: (_) {},
        ),
      ),
    );

    final inkWellSize = tester.getSize(find.byType(InkWell).first);

    expect(inkWellSize.height, greaterThanOrEqualTo(44));
  });

  testWidgets(
    'le libellé des segments respecte la taille de police minimale de '
    '11px (design système section 7, accessibilité)',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          SegmentedToggle<_Method>(
            options: const [
              SegmentedToggleOption(value: _Method.a, label: 'Tableau'),
              SegmentedToggleOption(value: _Method.b, label: 'Points'),
              SegmentedToggleOption(value: _Method.c, label: 'Dés'),
            ],
            value: _Method.a,
            onChanged: (_) {},
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('TABLEAU'));

      expect(textWidget.style?.fontSize, greaterThanOrEqualTo(11));
    },
  );
}
