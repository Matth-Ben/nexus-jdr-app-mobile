// Tests de widget de `SegmentedTabBar` (recettage direction-artistique du
// 13/09, écran "Groupe" — voir `group_screen.dart`).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/widgets/segmented_tab_bar.dart';

enum _Tab { members, treasure }

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  testWidgets('affiche un onglet par option, en majuscules', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SegmentedTabBar<_Tab>(
          options: const [
            SegmentedTabBarOption(value: _Tab.members, label: 'Membres'),
            SegmentedTabBarOption(value: _Tab.treasure, label: 'Butin'),
          ],
          value: _Tab.members,
          onChanged: (_) {},
        ),
      ),
    );

    expect(find.text('MEMBRES'), findsOneWidget);
    expect(find.text('BUTIN'), findsOneWidget);
  });

  testWidgets('taper un onglet appelle onChanged avec sa valeur', (
    tester,
  ) async {
    _Tab? selected;

    await tester.pumpWidget(
      _wrap(
        SegmentedTabBar<_Tab>(
          options: const [
            SegmentedTabBarOption(value: _Tab.members, label: 'Membres'),
            SegmentedTabBarOption(value: _Tab.treasure, label: 'Butin'),
          ],
          value: _Tab.members,
          onChanged: (value) => selected = value,
        ),
      ),
    );

    await tester.tap(find.text('BUTIN'));
    await tester.pumpAndSettle();

    expect(selected, _Tab.treasure);
  });

  testWidgets('la zone de tap de chaque onglet atteint 44px de haut '
      '(design système section 7, accessibilité)', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SegmentedTabBar<_Tab>(
          options: const [
            SegmentedTabBarOption(value: _Tab.members, label: 'Membres'),
            SegmentedTabBarOption(value: _Tab.treasure, label: 'Butin'),
          ],
          value: _Tab.members,
          onChanged: (_) {},
        ),
      ),
    );

    final inkWellSize = tester.getSize(find.byType(InkWell).first);

    expect(inkWellSize.height, greaterThanOrEqualTo(44));
  });

  testWidgets(
    "l'onglet actif a un soulignement gold-end, l'onglet inactif transparent",
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          SegmentedTabBar<_Tab>(
            options: const [
              SegmentedTabBarOption(value: _Tab.members, label: 'Membres'),
              SegmentedTabBarOption(value: _Tab.treasure, label: 'Butin'),
            ],
            value: _Tab.members,
            onChanged: (_) {},
          ),
        ),
      );

      final underlines = tester
          .widgetList<Container>(find.byType(Container))
          .where((container) => container.decoration is BoxDecoration)
          .toList();

      final activeUnderline = underlines.firstWhere(
        (container) =>
            (container.decoration! as BoxDecoration).color == AppColors.goldEnd,
      );
      final inactiveUnderline = underlines.firstWhere(
        (container) =>
            (container.decoration! as BoxDecoration).color ==
            Colors.transparent,
      );

      expect(activeUnderline, isNotNull);
      expect(inactiveUnderline, isNotNull);
    },
  );
}
