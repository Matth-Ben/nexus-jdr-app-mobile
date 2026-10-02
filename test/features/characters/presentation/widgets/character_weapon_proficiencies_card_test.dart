// Tests de widget de `CharacterWeaponProficienciesCard` — câblage du tap sur
// une chip vers `onTapToken` (voir sa doc de classe).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/presentation/widgets/character_weapon_proficiencies_card.dart';

void main() {
  testWidgets('affiche un chip par token', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CharacterWeaponProficienciesCard(
            names: const ['courantes', 'martiales'],
            onTapToken: (_) {},
          ),
        ),
      ),
    );

    expect(find.text("MAÎTRISES D'ARMES"), findsOneWidget);
    expect(find.text('courantes'), findsOneWidget);
    expect(find.text('martiales'), findsOneWidget);
  });

  testWidgets('taper un chip appelle onTapToken avec le token exact', (
    tester,
  ) async {
    final tapped = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CharacterWeaponProficienciesCard(
            names: const ['courantes', 'dagues'],
            onTapToken: tapped.add,
          ),
        ),
      ),
    );

    await tester.tap(find.text('dagues'));
    expect(tapped, ['dagues']);

    await tester.tap(find.text('courantes'));
    expect(tapped, ['dagues', 'courantes']);
  });
}
