// Tests de widget de `CharacterArmorProficienciesCard` — câblage du tap sur
// une chip vers `onTapToken` (voir sa doc de classe).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/presentation/widgets/character_armor_proficiencies_card.dart';

void main() {
  testWidgets('affiche un chip par token', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CharacterArmorProficienciesCard(
            names: const ['légère', 'boucliers'],
            onTapToken: (_) {},
          ),
        ),
      ),
    );

    expect(find.text("MAÎTRISES D'ARMURES"), findsOneWidget);
    expect(find.text('légère'), findsOneWidget);
    expect(find.text('boucliers'), findsOneWidget);
  });

  testWidgets('taper un chip appelle onTapToken avec le token exact', (
    tester,
  ) async {
    final tapped = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CharacterArmorProficienciesCard(
            names: const ['légère', 'boucliers (non métalliques)'],
            onTapToken: tapped.add,
          ),
        ),
      ),
    );

    await tester.tap(find.text('boucliers (non métalliques)'));
    expect(tapped, ['boucliers (non métalliques)']);
  });
}
