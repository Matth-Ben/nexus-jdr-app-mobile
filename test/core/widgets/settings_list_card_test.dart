// Tests de widget de `SettingsListCard` (design système section 4, "Liste de
// réglages") — composant introduit pour le recettage direction-artistique du
// 13/09/2026 : groupe de lignes dans une même carte, séparées par un
// `SheetActionDivider` 1px, jamais de séparateur après la dernière ligne.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/widgets/menu_tile.dart';
import 'package:personnages/core/widgets/settings_list_card.dart';
import 'package:personnages/core/widgets/sheet_action_row.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  testWidgets('affiche toutes les lignes fournies', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SettingsListCard(
          children: [
            MenuTile(
              standalone: false,
              icon: Icons.person_outline,
              label: 'Modifier le profil',
              onTap: () {},
            ),
            MenuTile(
              standalone: false,
              icon: Icons.notifications_none,
              label: 'Notifications',
              onTap: () {},
            ),
          ],
        ),
      ),
    );

    expect(find.text('Modifier le profil'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
  });

  testWidgets('3 lignes -> 2 séparateurs (jamais après la dernière ligne)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        SettingsListCard(
          children: [
            MenuTile(
              standalone: false,
              icon: Icons.download_outlined,
              label: 'Exporter mes données',
              onTap: () {},
            ),
            MenuTile(
              standalone: false,
              icon: Icons.description_outlined,
              label: 'Politique de confidentialité',
              onTap: () {},
            ),
            MenuTile(
              standalone: false,
              icon: Icons.admin_panel_settings_outlined,
              label: "Autorisations de l'appareil",
              onTap: () {},
            ),
          ],
        ),
      ),
    );

    expect(find.byType(SheetActionDivider), findsNWidgets(2));
  });

  testWidgets('1 seule ligne -> aucun séparateur', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SettingsListCard(
          children: [
            MenuTile(
              standalone: false,
              icon: Icons.download_outlined,
              label: 'Exporter mes données',
              onTap: () {},
            ),
          ],
        ),
      ),
    );

    expect(find.byType(SheetActionDivider), findsNothing);
  });

  testWidgets('porte une carte unique (bordure) englobant toutes les lignes', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        SettingsListCard(
          children: [
            MenuTile(
              standalone: false,
              icon: Icons.download_outlined,
              label: 'Exporter mes données',
              onTap: () {},
            ),
            MenuTile(
              standalone: false,
              icon: Icons.description_outlined,
              label: 'Politique de confidentialité',
              onTap: () {},
            ),
          ],
        ),
      ),
    );

    // La carte englobante (la `DecoratedBox` de `SettingsListCard`, fond
    // `parchmentCard`) — distincte du `DecoratedBox` interne du séparateur
    // (`SheetActionDivider`/`Divider`, sans fond) : les lignes elles-mêmes
    // (`MenuTile(standalone: false)`) n'en dessinent aucune (voir
    // `menu_tile_test.dart`).
    final cardDecoratedBox = find.byWidgetPredicate(
      (widget) =>
          widget is DecoratedBox &&
          (widget.decoration as BoxDecoration).color == AppColors.parchmentCard,
    );
    expect(cardDecoratedBox, findsOneWidget);
    final decoratedBox = tester.widget<DecoratedBox>(cardDecoratedBox);
    final decoration = decoratedBox.decoration as BoxDecoration;
    expect(decoration.border, isNotNull);
  });

  testWidgets('taper une ligne appelle bien son propre onTap', (tester) async {
    var firstTapped = false;
    var secondTapped = false;

    await tester.pumpWidget(
      _wrap(
        SettingsListCard(
          children: [
            MenuTile(
              standalone: false,
              icon: Icons.download_outlined,
              label: 'Exporter mes données',
              onTap: () => firstTapped = true,
            ),
            MenuTile(
              standalone: false,
              icon: Icons.description_outlined,
              label: 'Politique de confidentialité',
              onTap: () => secondTapped = true,
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Politique de confidentialité'));

    expect(firstTapped, isFalse);
    expect(secondTapped, isTrue);
  });
}
