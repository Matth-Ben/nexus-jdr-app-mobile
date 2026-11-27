// Tests de widget de `GroupTreasureTabBody` (onglet "Butin" de l'écran
// "Groupe"), aligné sur l'onglet « Inventaire » par la décision 91 : tuiles
// de monnaie cliquables, cartes d'objet de l'inventaire (toucher = fiche,
// plus de raccourci « S'attribuer »), tuile « Objet » en pied de liste.
// Voir aussi `group_screen_test.dart` (groupe "onglet Butin") pour le
// comportement d'intégration (appels au repository).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/accent_icon_badge.dart';
import 'package:personnages/core/widgets/dashed_add_tile.dart';
import 'package:personnages/core/widgets/dashed_button.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/characters/presentation/widgets/character_inventory_item_card.dart';
import 'package:personnages/features/groups/domain/group_treasure.dart';
import 'package:personnages/features/groups/domain/group_treasure_item.dart';
import 'package:personnages/features/groups/presentation/widgets/group_treasure_tab_body.dart';
import 'package:personnages/l10n/app_localizations.dart';

void main() {
  Widget buildWidget({
    required GroupTreasure treasure,
    bool isBusy = false,
    bool canClaim = true,
    bool isOffline = false,
    VoidCallback? onClaimCurrency,
    ValueChanged<GroupTreasureItem>? onOpenItem,
    VoidCallback? onAddItems,
    void Function(CurrencyKind, int)? onAdjustCurrency,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      home: Scaffold(
        body: GroupTreasureTabBody(
          treasure: treasure,
          isBusy: isBusy,
          canClaim: canClaim,
          isOffline: isOffline,
          onClaimCurrency: onClaimCurrency ?? () {},
          onOpenItem: onOpenItem ?? (_) {},
          onAddItems: onAddItems ?? () {},
          onAdjustCurrency: onAdjustCurrency ?? (_, _) {},
        ),
      ),
    );
  }

  testWidgets('affiche les 2 libellés de section et la tuile « Objet » de '
      'l\'inventaire, sans l\'ancien bouton « Ajouter au butin »', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildWidget(treasure: const GroupTreasure(groupId: 'group-1')),
    );

    expect(find.text('MONNAIE COMMUNE'), findsOneWidget);
    expect(find.text('OBJETS EN ATTENTE'), findsOneWidget);
    expect(find.byType(DashedAddTile), findsOneWidget);
    expect(find.text('Objet'), findsOneWidget);
    expect(find.text('AJOUTER AU BUTIN DU GROUPE'), findsNothing);
    // Pas de bouton « Récompense » dans le butin.
    expect(find.byIcon(Icons.card_giftcard), findsNothing);
  });

  testWidgets('le bouton "Répartir vers mon inventaire" est un DashedButton, '
      'désactivé quand le butin commun n\'a aucune monnaie', (tester) async {
    var claimCurrencyCalled = false;
    await tester.pumpWidget(
      buildWidget(
        treasure: const GroupTreasure(groupId: 'group-1'),
        onClaimCurrency: () => claimCurrencyCalled = true,
      ),
    );

    final dashedButton = tester.widget<DashedButton>(find.byType(DashedButton));
    expect(dashedButton.onPressed, isNull);
    await tester.tap(find.text('Répartir vers mon inventaire'));
    await tester.pumpAndSettle();
    expect(claimCurrencyCalled, isFalse);
  });

  testWidgets('chaque objet est une carte de l\'inventaire : toucher la carte '
      'ouvre la fiche (même pendant isBusy), aucun lien « S\'attribuer »', (
    tester,
  ) async {
    GroupTreasureItem? opened;
    const potion = GroupTreasureItem.catalog(
      itemId: 7,
      displayName: 'Potion de soins',
      quantity: 3,
      category: 'equipement_general',
      weight: 0.5,
    );
    await tester.pumpWidget(
      buildWidget(
        treasure: const GroupTreasure(groupId: 'group-1', items: [potion]),
        isBusy: true,
        onOpenItem: (item) => opened = item,
      ),
    );

    expect(find.byType(CharacterInventoryItemCard), findsOneWidget);
    expect(find.text('Potion de soins'), findsOneWidget);
    expect(find.text('Équipement général · x3'), findsOneWidget);
    expect(find.text('1,5 kg'), findsOneWidget);
    expect(find.text("S'attribuer"), findsNothing);

    await tester.tap(find.text('Potion de soins'));
    expect(opened, potion);
  });

  testWidgets('entrée ancienne sans catégorie : badge générique, libellé '
      'générique (jamais « Objet personnalisé »)', (tester) async {
    await tester.pumpWidget(
      buildWidget(
        treasure: const GroupTreasure(
          groupId: 'group-1',
          items: [
            GroupTreasureItem(itemId: 7, displayName: 'Potion', quantity: 2),
          ],
        ),
      ),
    );

    final badge = tester.widget<AccentIconBadge>(find.byType(AccentIconBadge));
    expect(badge.icon, Icons.inventory_2_outlined);
    expect(find.text('Équipement · x2'), findsOneWidget);
  });

  testWidgets('toucher une tuile de monnaie ouvre l\'ajustement de '
      'l\'inventaire et relaie le nouveau solde absolu', (tester) async {
    CurrencyKind? adjusted;
    int? newAmount;
    await tester.pumpWidget(
      buildWidget(
        treasure: const GroupTreasure(groupId: 'group-1', currencyGp: 10),
        onAdjustCurrency: (currency, amount) {
          adjusted = currency;
          newAmount = amount;
        },
      ),
    );

    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();
    // Mode « Retirer », 4 pièces.
    await tester.tap(find.text('RETIRER'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '4');
    await tester.pumpAndSettle();
    await tester.tap(find.text('APPLIQUER'));
    await tester.pumpAndSettle();

    expect(adjusted, CurrencyKind.gold);
    expect(newAmount, 6);
  });

  testWidgets('isBusy : monnaie, « Répartir » et « Objet » désactivés', (
    tester,
  ) async {
    var addCalled = false;
    await tester.pumpWidget(
      buildWidget(
        treasure: const GroupTreasure(groupId: 'group-1', currencyGp: 10),
        isBusy: true,
        onAddItems: () => addCalled = true,
      ),
    );

    expect(
      tester.widget<DashedButton>(find.byType(DashedButton)).onPressed,
      isNull,
    );
    expect(
      tester.widget<DashedAddTile>(find.byType(DashedAddTile)).onTap,
      isNull,
    );
    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();
    expect(find.text('APPLIQUER'), findsNothing);
    expect(addCalled, isFalse);
  });

  testWidgets('hors connexion : bandeau et écritures désactivées', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildWidget(
        treasure: const GroupTreasure(groupId: 'group-1', currencyGp: 10),
        isOffline: true,
      ),
    );

    expect(
      find.text(
        "Pas de connexion : le butin est en lecture seule jusqu'au retour "
        'du réseau.',
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<DashedButton>(find.byType(DashedButton)).onPressed,
      isNull,
    );
    expect(
      tester.widget<DashedAddTile>(find.byType(DashedAddTile)).onTap,
      isNull,
    );
  });

  testWidgets('canClaim faux (MJ sans personnage) : bandeau dédié, '
      '« Répartir » assourdi, « Objet » et la monnaie restent actifs', (
    tester,
  ) async {
    var addCalled = false;
    await tester.pumpWidget(
      buildWidget(
        treasure: const GroupTreasure(groupId: 'group-1', currencyGp: 10),
        canClaim: false,
        onAddItems: () => addCalled = true,
      ),
    );

    expect(
      find.textContaining('tu peux gérer le butin commun mais pas'),
      findsOneWidget,
    );
    expect(
      tester.widget<DashedButton>(find.byType(DashedButton)).onPressed,
      isNull,
    );
    await tester.tap(find.text('Objet'));
    expect(addCalled, isTrue);
    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();
    expect(find.text('APPLIQUER'), findsOneWidget);
  });

  testWidgets('canClaim vrai (défaut) : pas de bandeau dédié', (tester) async {
    await tester.pumpWidget(
      buildWidget(treasure: const GroupTreasure(groupId: 'group-1')),
    );

    expect(
      find.textContaining('tu peux gérer le butin commun mais pas'),
      findsNothing,
    );
  });
}
