// Tests de widget de `SelectionCheckbox`, extraite de `CheckableOptionTile`
// (`_Checkbox`) pour son second usage par `CharacterCard` — voir la
// documentation de classe de `selection_checkbox.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/widgets/selection_checkbox.dart';

Future<void> _pump(WidgetTester tester, {required bool checked}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SelectionCheckbox(checked: checked)),
    ),
  );
}

void main() {
  testWidgets('non cochée : pas d\'icône de coche, bordure wood.light', (
    tester,
  ) async {
    await _pump(tester, checked: false);

    expect(find.byIcon(Icons.check), findsNothing);
    final container = tester.widget<Container>(find.byType(Container));
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.border, isA<Border>());
    final border = decoration.border! as Border;
    expect(border.top.color, AppColors.woodLight);
    expect(decoration.color, Colors.transparent);
  });

  testWidgets(
    'cochée : icône de coche blanche, fond gold-end, bordure wood.dark',
    (tester) async {
      await _pump(tester, checked: true);

      final icon = tester.widget<Icon>(find.byIcon(Icons.check));
      expect(icon.color, Colors.white);
      expect(icon.size, 13);

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, AppColors.goldEnd);
      final border = decoration.border! as Border;
      expect(border.top.color, AppColors.woodDark);
    },
  );

  testWidgets('taille fixe 18×18px', (tester) async {
    await _pump(tester, checked: false);

    final size = tester.getSize(find.byType(SelectionCheckbox));
    expect(size, const Size(18, 18));
  });
}
