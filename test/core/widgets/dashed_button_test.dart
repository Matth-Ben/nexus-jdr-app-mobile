import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/dashed_button.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('affiche l\'icône et le libellé, appelle onPressed au tap', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        DashedButton(
          icon: Icons.savings_outlined,
          label: 'Répartir vers mon inventaire',
          onPressed: () => tapped = true,
        ),
      ),
    );

    expect(find.byIcon(Icons.savings_outlined), findsOneWidget);
    expect(find.text('Répartir vers mon inventaire'), findsOneWidget);

    await tester.tap(find.text('Répartir vers mon inventaire'));
    expect(tapped, isTrue);
  });

  testWidgets('onPressed null désactive le bouton (pas de tap possible)', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        DashedButton(
          icon: Icons.savings_outlined,
          label: 'Répartir vers mon inventaire',
          onPressed: null,
        ),
      ),
    );

    await tester.tap(
      find.text('Répartir vers mon inventaire'),
      warnIfMissed: false,
    );
    expect(tapped, isFalse);
  });

  testWidgets('libellé long dans une largeur contrainte ne provoque pas de '
      'débordement', (tester) async {
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 160,
          child: DashedButton(
            icon: Icons.savings_outlined,
            label: 'Répartir vers mon inventaire et celui de mes alliés',
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
