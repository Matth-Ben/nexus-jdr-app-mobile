// Tests de widget du chip `CharacterNameTagChip` — voir sa doc de classe
// pour le rationale du paramètre `onTap` optionnel (ajouté pour
// `CharacterWeaponProficienciesCard`/`CharacterArmorProficienciesCard`, sans
// changer le rendu des usages existants sans `onTap`).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/presentation/widgets/character_name_tag_chip.dart';

Future<void> _pump(WidgetTester tester, Widget chip) {
  return tester.pumpWidget(MaterialApp(home: Scaffold(body: chip)));
}

void main() {
  testWidgets('sans onTap : aucune zone de tap/sémantique bouton ajoutée '
      '(comportement existant inchangé)', (tester) async {
    await _pump(tester, const CharacterNameTagChip(name: 'légère'));

    expect(find.text('légère'), findsOneWidget);
    // Pas de zone de tap ajoutée (le `Material` ambiant du `Scaffold` ne
    // compte pas) : aucun `InkWell` ne doit entourer le chip.
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('avec onTap : enveloppé dans Material/InkWell, ripple au tap', (
    tester,
  ) async {
    var tapped = 0;
    await _pump(
      tester,
      CharacterNameTagChip(name: 'courantes', onTap: () => tapped++),
    );

    expect(find.byType(InkWell), findsOneWidget);
    await tester.tap(find.text('courantes'));
    expect(tapped, 1);
  });

  testWidgets('avec onTap : zone de tap élargie à >= 44x44', (tester) async {
    await _pump(tester, CharacterNameTagChip(name: 'x', onTap: () {}));

    final size = tester.getSize(find.byType(InkWell));
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
  });

  testWidgets('avec onTap : sémantique bouton avec le libellé attendu', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, CharacterNameTagChip(name: 'boucliers', onTap: () {}));

    expect(
      tester.getSemantics(find.bySemanticsLabel('boucliers, voir le détail')),
      matchesSemantics(
        isButton: true,
        hasTapAction: true,
        label: 'boucliers, voir le détail',
      ),
    );
    handle.dispose();
  });
}
