import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/wood_back_header.dart';

void main() {
  testWidgets('sans trailing (comportement existant inchangé) : titre '
      'affiché, retour fonctionnel', (tester) async {
    var backTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WoodBackHeader(
            title: 'FICHE',
            onBack: () => backTapped = true,
          ),
        ),
      ),
    );

    expect(find.text('FICHE'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    expect(backTapped, isTrue);
  });

  testWidgets('avec trailing : le widget est rendu et reste cliquable', (
    tester,
  ) async {
    var trailingTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WoodBackHeader(
            title: 'INVENTAIRE',
            onBack: () {},
            trailing: IconButton(
              tooltip: 'Ajouter une récompense',
              onPressed: () => trailingTapped = true,
              icon: const Icon(Icons.card_giftcard),
            ),
          ),
        ),
      ),
    );

    expect(find.text('INVENTAIRE'), findsOneWidget);
    expect(find.byTooltip('Ajouter une récompense'), findsOneWidget);

    await tester.tap(find.byTooltip('Ajouter une récompense'));
    expect(trailingTapped, isTrue);
  });
}
