// Tests de widget de `CheckableOptionTile` (design système section 4,
// "Case à cocher / élément de liste sélectionnable à choix multiple"),
// composant introduit pour l'étape 5/9 "Compétences et outils" de
// l'assistant de création.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/checkable_option_tile.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('affiche le titre et le libellé secondaire fournis', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const CheckableOptionTile(
          title: 'Arcanes',
          trailingLabel: 'Int',
          checked: false,
        ),
      ),
    );

    expect(find.text('Arcanes'), findsOneWidget);
    expect(find.text('Int'), findsOneWidget);
  });

  testWidgets('sans trailingLabel, aucun libellé secondaire n\'est affiché', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const CheckableOptionTile(title: 'Outils de voleur', checked: true),
      ),
    );

    expect(find.text('Outils de voleur'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('état décoché : pas de coche affichée, pleine opacité', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const CheckableOptionTile(title: 'Athlétisme', checked: false)),
    );

    expect(find.byIcon(Icons.check), findsNothing);
    final opacity = tester.widget<Opacity>(find.byType(Opacity));
    expect(opacity.opacity, 1);
  });

  testWidgets('état coché : la coche est affichée, pleine opacité', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const CheckableOptionTile(title: 'Athlétisme', checked: true)),
    );

    expect(find.byIcon(Icons.check), findsOneWidget);
    final opacity = tester.widget<Opacity>(find.byType(Opacity));
    expect(opacity.opacity, 1);
  });

  testWidgets('taper une option décochée et activée (enabled) appelle onTap', (
    WidgetTester tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      _wrap(
        CheckableOptionTile(
          title: 'Discrétion',
          checked: false,
          onTap: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.text('Discrétion'));

    expect(tapped, isTrue);
  });

  testWidgets(
    'option verrouillée (enabled: false, checked: false, quota atteint) : '
    'estompée et non cliquable',
    (WidgetTester tester) async {
      var tapped = false;

      await tester.pumpWidget(
        _wrap(
          CheckableOptionTile(
            title: 'Nature',
            checked: false,
            enabled: false,
            onTap: () => tapped = true,
          ),
        ),
      );

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, lessThan(1));

      await tester.tap(find.text('Nature'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(tapped, isFalse);
    },
  );

  testWidgets(
    'octroi automatique non interactif (enabled: false, checked: true) : '
    'PAS estompé, mais non cliquable (maquette 06_étape_5)',
    (WidgetTester tester) async {
      var tapped = false;

      await tester.pumpWidget(
        _wrap(
          CheckableOptionTile(
            title: "Kit d'herboriste",
            checked: true,
            enabled: false,
            onTap: () => tapped = true,
          ),
        ),
      );

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 1);
      expect(find.byIcon(Icons.check), findsOneWidget);

      await tester.tap(find.text("Kit d'herboriste"), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(tapped, isFalse);
    },
  );

  testWidgets('sans onTap fourni, taper la ligne ne crashe pas', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const CheckableOptionTile(title: 'Survie', checked: false)),
    );

    await tester.tap(find.text('Survie'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Survie'), findsOneWidget);
  });

  testWidgets('la zone de tap atteint 44x44px (design système section 7, '
      'accessibilité), même si la case visuelle ne fait que 18x18px', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        CheckableOptionTile(title: 'Perception', checked: false, onTap: () {}),
      ),
    );

    final size = tester.getSize(find.byType(InkWell));
    expect(size.height, greaterThanOrEqualTo(44));
  });

  testWidgets('les tailles de police du titre et du libellé secondaire restent '
      '≥ 11px (design système section 7, accessibilité)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const CheckableOptionTile(
          title: 'Représentation',
          trailingLabel: 'Cha',
          checked: false,
        ),
      ),
    );

    final titleStyle = tester.widget<Text>(find.text('Représentation')).style;
    final trailingStyle = tester.widget<Text>(find.text('Cha')).style;

    expect(titleStyle?.fontSize, isNotNull);
    expect(titleStyle!.fontSize!, greaterThanOrEqualTo(11));
    expect(trailingStyle?.fontSize, isNotNull);
    expect(trailingStyle!.fontSize!, greaterThanOrEqualTo(11));
  });
}
