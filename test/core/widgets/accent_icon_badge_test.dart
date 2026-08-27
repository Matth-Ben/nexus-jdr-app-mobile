// Test de widget de [AccentIconBadge] — couvre spécifiquement la correction
// de contraste apportée en revue direction-artistique de l'onglet
// "Inventaire" (`character_inventory_item_card.dart`, catégorie
// "objet magique" en fond `AppColors.goldEnd`) : l'icône blanche par défaut
// est illisible sur ce fond (~2,7:1, sous le seuil WCAG 3:1 pour les
// composants graphiques).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/widgets/accent_icon_badge.dart';

void main() {
  Future<Icon> pumpAndGetIcon(WidgetTester tester, Color color) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AccentIconBadge(icon: Icons.auto_awesome, color: color),
        ),
      ),
    );
    return tester.widget<Icon>(find.byType(Icon));
  }

  testWidgets('icône assombrie (woodDark) sur fond goldEnd', (tester) async {
    final icon = await pumpAndGetIcon(tester, AppColors.goldEnd);
    expect(icon.color, AppColors.woodDark);
  });

  testWidgets('icône blanche (défaut) sur les autres couleurs de fond', (
    tester,
  ) async {
    final icon = await pumpAndGetIcon(tester, AppColors.accentBrick);
    expect(icon.color, Colors.white);
  });
}
