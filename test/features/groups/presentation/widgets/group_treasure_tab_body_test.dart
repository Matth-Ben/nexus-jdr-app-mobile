// Tests de widget de `GroupTreasureTabBody` (onglet "Butin" de l'écran
// "Groupe") — recettage direction-artistique du 13/09/2026 : sections
// "MONNAIE COMMUNE"/"OBJETS EN ATTENTE", bouton pointillé "Répartir vers mon
// inventaire", ligne d'objet avec vignette et lien "S'attribuer", bouton
// bordé doré "Ajouter au butin du groupe". Voir aussi
// `group_screen_test.dart` (groupe "onglet Butin") pour le comportement
// d'intégration (appels au repository).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/widgets/dashed_button.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/features/groups/domain/group_treasure.dart';
import 'package:personnages/features/groups/domain/group_treasure_item.dart';
import 'package:personnages/features/groups/presentation/widgets/group_treasure_tab_body.dart';

void main() {
  Widget buildWidget({
    required GroupTreasure treasure,
    bool isBusy = false,
    VoidCallback? onClaimCurrency,
    ClaimGroupTreasureItemCallback? onClaimItem,
    VoidCallback? onAddToTreasure,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: GroupTreasureTabBody(
          treasure: treasure,
          isBusy: isBusy,
          onClaimCurrency: onClaimCurrency ?? () {},
          onClaimItem: onClaimItem ?? (_) {},
          onAddToTreasure: onAddToTreasure ?? () {},
        ),
      ),
    );
  }

  testWidgets(
    'affiche les 2 libellés de section et le bouton "Ajouter au butin du '
    'groupe" bordé doré',
    (tester) async {
      await tester.pumpWidget(
        buildWidget(treasure: const GroupTreasure(groupId: 'group-1')),
      );

      expect(find.text('MONNAIE COMMUNE'), findsOneWidget);
      expect(find.text('OBJETS EN ATTENTE'), findsOneWidget);

      expect(find.text('AJOUTER AU BUTIN DU GROUPE'), findsOneWidget);
      expect(find.byIcon(Icons.card_giftcard), findsOneWidget);

      final button = tester.widget<SecondaryButton>(
        find.byType(SecondaryButton),
      );
      expect(button.borderColor, AppColors.goldEnd);
      expect(button.surface, SecondaryButtonSurface.parchment);
    },
  );

  testWidgets('le bouton "Répartir vers mon inventaire" est un DashedButton, '
      'désactivé quand le butin commun n\'a aucune monnaie', (tester) async {
    var claimCurrencyCalled = false;
    await tester.pumpWidget(
      buildWidget(
        treasure: const GroupTreasure(groupId: 'group-1'),
        onClaimCurrency: () => claimCurrencyCalled = true,
      ),
    );

    expect(find.text('Répartir vers mon inventaire'), findsOneWidget);
    final dashedButton = tester.widget<DashedButton>(find.byType(DashedButton));
    expect(dashedButton.onPressed, isNull);

    await tester.tap(find.text('Répartir vers mon inventaire'));
    await tester.pumpAndSettle();
    expect(claimCurrencyCalled, isFalse);
  });

  testWidgets(
    'le bouton "Répartir vers mon inventaire" est actif dès qu\'il y a de '
    'la monnaie, et appelle onClaimCurrency au tap',
    (tester) async {
      var claimCurrencyCalled = false;
      await tester.pumpWidget(
        buildWidget(
          treasure: const GroupTreasure(groupId: 'group-1', currencyGp: 12),
          onClaimCurrency: () => claimCurrencyCalled = true,
        ),
      );

      final dashedButton = tester.widget<DashedButton>(
        find.byType(DashedButton),
      );
      expect(dashedButton.onPressed, isNotNull);

      await tester.tap(find.text('Répartir vers mon inventaire'));
      expect(claimCurrencyCalled, isTrue);
    },
  );

  testWidgets('affiche l\'état vide quand aucun objet n\'est en attente', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildWidget(treasure: const GroupTreasure(groupId: 'group-1')),
    );

    expect(find.text('Aucun objet en attente.'), findsOneWidget);
  });

  testWidgets(
    'affiche une ligne par objet en attente avec vignette, nom, quantité '
    'sur 2 lignes et un lien "S\'attribuer"',
    (tester) async {
      GroupTreasureItem? claimed;
      await tester.pumpWidget(
        buildWidget(
          treasure: const GroupTreasure(
            groupId: 'group-1',
            items: [
              GroupTreasureItem(
                itemId: 7,
                displayName: 'Potion de soins',
                quantity: 3,
              ),
            ],
          ),
          onClaimItem: (item) => claimed = item,
        ),
      );

      expect(find.text('Potion de soins'), findsOneWidget);
      expect(find.text('× 3'), findsOneWidget);
      expect(find.text("S'attribuer"), findsOneWidget);
      // Plus d'IconButton "call_split" — remplacé par le lien texte.
      expect(find.byIcon(Icons.call_split), findsNothing);

      await tester.tap(find.text("S'attribuer"));
      expect(claimed?.displayName, 'Potion de soins');
    },
  );

  testWidgets(
    'isBusy verrouille "Répartir vers mon inventaire", "S\'attribuer" et '
    '"Ajouter au butin du groupe"',
    (tester) async {
      var claimCurrencyCalled = false;
      var claimItemCalled = false;
      var addToTreasureCalled = false;
      await tester.pumpWidget(
        buildWidget(
          treasure: const GroupTreasure(
            groupId: 'group-1',
            currencyGp: 12,
            items: [
              GroupTreasureItem(itemId: 7, displayName: 'Potion', quantity: 1),
            ],
          ),
          isBusy: true,
          onClaimCurrency: () => claimCurrencyCalled = true,
          onClaimItem: (_) => claimItemCalled = true,
          onAddToTreasure: () => addToTreasureCalled = true,
        ),
      );

      await tester.tap(find.text('Répartir vers mon inventaire'));
      await tester.tap(find.text("S'attribuer"));
      await tester.tap(find.text('AJOUTER AU BUTIN DU GROUPE'));
      await tester.pumpAndSettle();

      expect(claimCurrencyCalled, isFalse);
      expect(claimItemCalled, isFalse);
      expect(addToTreasureCalled, isFalse);

      final addButton = tester.widget<SecondaryButton>(
        find.byType(SecondaryButton),
      );
      expect(addButton.onPressed, isNull);
    },
  );
}
