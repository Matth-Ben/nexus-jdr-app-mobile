import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/destructive_button.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('affiche le libellé, appelle onPressed au tap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        DestructiveButton(label: 'Supprimer', onPressed: () => tapped = true),
      ),
    );

    expect(find.text('Supprimer'), findsOneWidget);
    expect(find.byIcon(Icons.block), findsNothing);

    await tester.tap(find.text('Supprimer'));
    expect(tapped, isTrue);
  });

  testWidgets('icon affiche l\'icône fournie avant le libellé', (tester) async {
    await tester.pumpWidget(
      wrap(
        DestructiveButton(
          label: 'Désactiver le partage',
          icon: Icons.block,
          onPressed: () {},
        ),
      ),
    );

    expect(find.byIcon(Icons.block), findsOneWidget);
    expect(find.text('Désactiver le partage'), findsOneWidget);
  });

  testWidgets('onPressed null désactive le bouton (pas de tap possible)', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(const DestructiveButton(label: 'Supprimer', onPressed: null)),
    );

    await tester.tap(find.text('Supprimer'), warnIfMissed: false);
    expect(tapped, isFalse);
  });

  testWidgets(
    'libellé long dans une largeur contrainte ne provoque pas de débordement '
    '(régression : Row sans Flexible autour du Text)',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 160,
            child: DestructiveButton(
              label: 'Dissoudre le groupe définitivement maintenant',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('filled: true affiche le libellé en majuscules', (tester) async {
    await tester.pumpWidget(
      wrap(
        DestructiveButton(
          label: 'Supprimer définitivement',
          filled: true,
          onPressed: () {},
        ),
      ),
    );

    expect(find.text('SUPPRIMER DÉFINITIVEMENT'), findsOneWidget);
    expect(find.text('Supprimer définitivement'), findsNothing);
  });
}
