// Tests de widget de `StepperCounter` (design système section 4, "Compteur
// +/-").

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/stepper_counter.dart';
import 'package:personnages/l10n/app_localizations.dart';

Widget _wrap(Widget child, {Locale locale = const Locale('fr')}) {
  // `StepperCounter` lit `AppLocalizations.of(context)!` (libellés
  // d'accessibilité "Diminuer"/"Augmenter", D160) — sans ces delegates, le
  // `!` planterait.
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('affiche la valeur centrale', (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(StepperCounter(value: 15, onIncrement: () {}, onDecrement: () {})),
    );

    expect(find.text('15'), findsOneWidget);
  });

  testWidgets('taper "+" appelle onIncrement, taper "-" appelle '
      'onDecrement', (WidgetTester tester) async {
    var incremented = false;
    var decremented = false;

    await tester.pumpWidget(
      _wrap(
        StepperCounter(
          value: 10,
          onIncrement: () => incremented = true,
          onDecrement: () => decremented = true,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.tap(find.byIcon(Icons.remove));

    expect(incremented, isTrue);
    expect(decremented, isTrue);
  });

  testWidgets('onIncrement null désactive le bouton "+"', (
    WidgetTester tester,
  ) async {
    var incremented = false;

    await tester.pumpWidget(
      _wrap(StepperCounter(value: 15, onIncrement: null, onDecrement: () {})),
    );

    await tester.tap(find.byIcon(Icons.add), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(incremented, isFalse);
  });

  testWidgets('onDecrement null désactive le bouton "-"', (
    WidgetTester tester,
  ) async {
    var decremented = false;

    await tester.pumpWidget(
      _wrap(StepperCounter(value: 8, onIncrement: () {}, onDecrement: null)),
    );

    await tester.tap(find.byIcon(Icons.remove), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(decremented, isFalse);
  });

  testWidgets(
    'la zone de tap de chaque bouton +/- atteint 44x44px alors que le '
    'rendu visuel reste 28x28px (design système section 7, accessibilité)',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          StepperCounter(value: 15, onIncrement: () {}, onDecrement: () {}),
        ),
      );

      final inkWellFinder = find.byType(InkWell);
      expect(inkWellFinder, findsNWidgets(2));

      for (var i = 0; i < 2; i++) {
        final size = tester.getSize(inkWellFinder.at(i));
        expect(size.width, greaterThanOrEqualTo(44));
        expect(size.height, greaterThanOrEqualTo(44));
      }
    },
  );

  testWidgets(
    'les libellés d\'accessibilité "Diminuer"/"Augmenter" suivent la locale '
    '(D160, docs/dette-technique.md)',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          StepperCounter(value: 15, onIncrement: () {}, onDecrement: () {}),
        ),
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.remove)).semanticLabel,
        'Diminuer',
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.add)).semanticLabel,
        'Augmenter',
      );

      await tester.pumpWidget(
        _wrap(
          StepperCounter(value: 15, onIncrement: () {}, onDecrement: () {}),
          locale: const Locale('en'),
        ),
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.remove)).semanticLabel,
        'Decrease',
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.add)).semanticLabel,
        'Increase',
      );
    },
  );
}
