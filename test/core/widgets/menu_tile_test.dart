// Tests de widget de `MenuTile` (design système section 4, "Tuile de menu"),
// premier test dédié à ce composant (jusqu'ici couvert seulement en creux par
// les tests des écrans qui l'utilisent) — couvre le comportement historique
// (`standalone: true`, carte bordée propre) ainsi que les 2 extensions du
// recettage direction-artistique du 13/09/2026 : `standalone: false` (pensé
// pour `SettingsListCard`) et `trailingIcon` (icône de fin alternative au
// chevron par défaut).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/menu_tile.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  testWidgets('affiche l\'icône, le libellé et le chevron par défaut', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        MenuTile(
          icon: Icons.person_outline,
          label: 'Modifier le profil',
          onTap: () {},
        ),
      ),
    );

    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(find.text('Modifier le profil'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('taper la tuile appelle onTap', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      _wrap(
        MenuTile(
          icon: Icons.person_outline,
          label: 'Modifier le profil',
          onTap: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.text('Modifier le profil'));

    expect(tapped, isTrue);
  });

  testWidgets(
    'standalone (par défaut) : porte sa propre carte (`DecoratedBox` avec '
    'bordure)',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          MenuTile(icon: Icons.person_outline, label: 'Profil', onTap: () {}),
        ),
      );

      final decoratedBox = tester.widget<DecoratedBox>(
        find.byType(DecoratedBox),
      );
      final decoration = decoratedBox.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    },
  );

  testWidgets('standalone: false : aucune carte/bordure propre (pensé pour '
      'SettingsListCard)', (tester) async {
    await tester.pumpWidget(
      _wrap(
        MenuTile(
          standalone: false,
          icon: Icons.person_outline,
          label: 'Profil',
          onTap: () {},
        ),
      ),
    );

    expect(find.byType(DecoratedBox), findsNothing);
    expect(find.text('Profil'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('trailingIcon remplace le chevron par défaut', (tester) async {
    await tester.pumpWidget(
      _wrap(
        MenuTile(
          icon: Icons.description_outlined,
          label: 'Politique de confidentialité',
          trailingIcon: Icons.north_east,
          onTap: () {},
        ),
      ),
    );

    expect(find.byIcon(Icons.north_east), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('sous-libellé, badge chiffré et libellé d\'accessibilité '
      'unique (ligne « Alertes de synchronisation »)', (tester) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      _wrap(
        MenuTile(
          standalone: false,
          icon: Icons.sync_problem,
          iconColor: const Color(0xFFA13D2B),
          label: 'Alertes',
          subtitle: 'Aucune',
          badgeText: '3',
          semanticsLabel: '3 alertes. Ouvrir la liste.',
          onTap: () => taps++,
        ),
      ),
    );

    expect(find.text('Aucune'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.sync_problem)).color,
      const Color(0xFFA13D2B),
    );
    expect(
      find.bySemanticsLabel('3 alertes. Ouvrir la liste.'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Alertes'), findsNothing);
    expect(
      tester.getSize(find.byType(InkWell)).height,
      greaterThanOrEqualTo(44),
    );

    await tester.tap(find.text('Alertes'));
    expect(taps, 1);
    semantics.dispose();
  });

  testWidgets('sans sous-libellé ni badge : rendu historique inchangé', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(MenuTile(icon: Icons.language, label: 'Langue', onTap: () {})),
    );
    expect(find.byType(DecoratedBox), findsWidgets);
    expect(find.text('Langue'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });
}
