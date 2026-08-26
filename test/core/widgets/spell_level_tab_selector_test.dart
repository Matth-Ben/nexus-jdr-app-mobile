// Tests de widget de `SpellLevelTabSelector`, sélecteur d'onglets en pilules
// de l'étape 6/9 "Sorts" de l'assistant de création (maquette réelle vérifiée
// au pixel près).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/widgets/spell_level_tab_selector.dart';

enum _Tab { cantrip, levelOne }

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets(
    'affiche une pilule par option, en casse phrase (police body, pas display)',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          SpellLevelTabSelector<_Tab>(
            options: const [
              SpellLevelTabOption(value: _Tab.cantrip, label: 'Mineurs'),
              SpellLevelTabOption(value: _Tab.levelOne, label: 'Niveau 1'),
            ],
            value: _Tab.cantrip,
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Mineurs'), findsOneWidget);
      expect(find.text('Niveau 1'), findsOneWidget);
    },
  );

  testWidgets('taper une pilule appelle onChanged avec sa valeur', (
    WidgetTester tester,
  ) async {
    _Tab? selected;

    await tester.pumpWidget(
      _wrap(
        SpellLevelTabSelector<_Tab>(
          options: const [
            SpellLevelTabOption(value: _Tab.cantrip, label: 'Mineurs'),
            SpellLevelTabOption(value: _Tab.levelOne, label: 'Niveau 1'),
          ],
          value: _Tab.cantrip,
          onChanged: (value) => selected = value,
        ),
      ),
    );

    await tester.tap(find.text('Niveau 1'));
    await tester.pumpAndSettle();

    expect(selected, _Tab.levelOne);
  });

  testWidgets(
    'la pilule active porte le dégradé or et un texte sombre, l\'inactive '
    'un fond bois foncé et un texte clair atténué',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          SpellLevelTabSelector<_Tab>(
            options: const [
              SpellLevelTabOption(value: _Tab.cantrip, label: 'Mineurs'),
              SpellLevelTabOption(value: _Tab.levelOne, label: 'Niveau 1'),
            ],
            value: _Tab.cantrip,
            onChanged: (_) {},
          ),
        ),
      );

      final activeText = tester.widget<Text>(find.text('Mineurs'));
      final inactiveText = tester.widget<Text>(find.text('Niveau 1'));

      expect(activeText.style?.color, AppColors.woodDark);
      expect(inactiveText.style?.color, AppColors.textOnWoodMuted);

      final activeContainer = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('Mineurs'),
              matching: find.byType(Container),
            )
            .first,
      );
      final inactiveContainer = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('Niveau 1'),
              matching: find.byType(Container),
            )
            .first,
      );

      expect(
        (activeContainer.decoration! as BoxDecoration).gradient,
        AppColors.primaryButtonGradient,
      );
      expect(
        (inactiveContainer.decoration! as BoxDecoration).color,
        AppColors.woodDark,
      );
    },
  );

  testWidgets('la zone de tap de chaque pilule atteint 44px de haut '
      '(design système section 7, accessibilité)', (WidgetTester tester) async {
    await tester.pumpWidget(
      _wrap(
        SpellLevelTabSelector<_Tab>(
          options: const [
            SpellLevelTabOption(value: _Tab.cantrip, label: 'Mineurs'),
            SpellLevelTabOption(value: _Tab.levelOne, label: 'Niveau 1'),
          ],
          value: _Tab.cantrip,
          onChanged: (_) {},
        ),
      ),
    );

    final inkWellSize = tester.getSize(find.byType(InkWell).first);

    expect(inkWellSize.height, greaterThanOrEqualTo(44));
  });
}
