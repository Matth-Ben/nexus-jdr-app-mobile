// Tests de widget de `DestructiveMenuTile` — "ligne destructive" introduite
// pour le recettage direction-artistique du 13/09/2026 ("Supprimer mon
// compte" sur `ProfilePrivacyScreen`, zone "ZONE DANGEREUSE") : palette
// dédiée `accent.brick` (fond `#FDECE0`, bordure/icônes/texte `accent.brick`),
// icône poubelle à gauche, chevron à droite.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/widgets/destructive_menu_tile.dart';

void main() {
  testWidgets(
    'affiche le libellé fourni, l\'icône poubelle et un chevron, tous en '
    'accent.brick',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DestructiveMenuTile(
              label: 'Supprimer mon compte',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Supprimer mon compte'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      final leadingIcon = tester.widget<Icon>(
        find.byIcon(Icons.delete_outline),
      );
      final trailingIcon = tester.widget<Icon>(
        find.byIcon(Icons.chevron_right),
      );
      expect(leadingIcon.color, AppColors.accentBrick);
      expect(trailingIcon.color, AppColors.accentBrick);

      final labelStyle = tester
          .widget<Text>(find.text('Supprimer mon compte'))
          .style;
      expect(labelStyle?.color, AppColors.accentBrick);
      expect(labelStyle?.fontWeight, FontWeight.w700);
    },
  );

  testWidgets('la carte utilise la bordure/le fond dédiés accent.brick', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DestructiveMenuTile(
            label: 'Supprimer mon compte',
            onTap: () {},
          ),
        ),
      ),
    );

    final decoratedBox = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final decoration = decoratedBox.decoration as BoxDecoration;
    expect(decoration.color, AppColors.alertBannerBackground);
    expect(decoration.border?.top.color, AppColors.accentBrick);
  });

  testWidgets('taper la ligne appelle onTap', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DestructiveMenuTile(
            label: 'Supprimer mon compte',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Supprimer mon compte'));

    expect(tapped, isTrue);
  });
}
