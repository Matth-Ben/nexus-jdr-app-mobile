// Composants de l'inventaire partagés avec le butin de groupe (décision
// 91) : corps du panneau Infos (`ItemInfoBody`, variante sans personnage),
// sheet de quantité (`showItemQuantitySheet`, bornes), confirmation de
// retrait (titre et texte en paramètres) et pied « Objet » seul.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/dashed_add_tile.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/characters/domain/weapon_slot.dart';
import 'package:personnages/features/characters/presentation/widgets/add_item_flow.dart';
import 'package:personnages/features/characters/presentation/widgets/character_inventory_tab_body.dart';
import 'package:personnages/features/characters/presentation/widgets/item_action_sheet.dart';
import 'package:personnages/features/characters/presentation/widgets/item_info_panel.dart';
import 'package:personnages/l10n/app_localizations.dart';

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('fr'),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

const _sword = CharacterInventoryItem(
  id: 'inv-1',
  itemId: 12,
  name: 'Épée longue',
  category: 'arme',
  quantity: 1,
  equipped: true,
  weaponSlot: WeaponSlot.principal,
  requiresAttunement: true,
  description: 'Une lame droite.',
  weaponProperties: CharacterInventoryWeaponProperties(
    damageDice: '1d8',
    damageType: 'tranchant',
    properties: ['polyvalente(1d10)'],
  ),
);

void main() {
  group('ItemInfoBody', () {
    testWidgets('avec personnage : Attaque, Set et modificateur de dégâts', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const ItemInfoBody(
            item: _sword,
            weaponAttackBonus: 5,
            weaponDamageModifier: 3,
          ),
        ),
      );

      expect(find.text('Attaque'), findsOneWidget);
      expect(find.text('Set'), findsOneWidget);
      expect(find.text('1d8+3 tranchant'), findsOneWidget);
      expect(find.text('Une lame droite.'), findsOneWidget);
    });

    testWidgets('sans personnage (butin) : ni Attaque ni Set ni modificateur, '
        'harmonisation « Requise », lignes de tête et description remplacée', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const ItemInfoBody(
            item: _sword,
            withoutCharacter: true,
            weaponAttackBonus: 5,
            weaponDamageModifier: 3,
            leadingRows: [(label: 'Provenance', value: 'Catalogue')],
            descriptionOverride: Text('Chargement…'),
          ),
        ),
      );

      expect(find.text('Attaque'), findsNothing);
      expect(find.text('Set'), findsNothing);
      expect(find.text('1d8 tranchant'), findsOneWidget);
      expect(find.text('Harmonisation'), findsOneWidget);
      expect(find.text('Requise'), findsOneWidget);
      expect(find.text('Provenance'), findsOneWidget);
      expect(find.text('Catalogue'), findsOneWidget);
      expect(find.text('Chargement…'), findsOneWidget);
      expect(find.text('Une lame droite.'), findsNothing);
    });
  });

  group('ItemInfoBody — ligne « Prix » (spec du prix d\'un objet '
      'modifiable)', () {
    testWidgets('prix officiel sans surcharge : devise-agnostique, pas de '
        'pastille', (tester) async {
      await tester.pumpWidget(
        _app(
          const ItemInfoBody(
            item: CharacterInventoryItem(
              id: 'inv-2',
              itemId: 5,
              name: 'Dague',
              quantity: 1,
              equipped: false,
              costAmount: 2.5,
            ),
          ),
        ),
      );

      expect(find.text('Prix'), findsOneWidget);
      expect(find.text('2,5 PO'), findsOneWidget);
      expect(find.text('Modifié'), findsNothing);
      expect(find.text('Non estimé'), findsNothing);
    });

    testWidgets('surcharge d\'un objet du catalogue : valeur dans la '
        'nouvelle devise + pastille « Modifié »', (tester) async {
      await tester.pumpWidget(
        _app(
          const ItemInfoBody(
            item: CharacterInventoryItem(
              id: 'inv-3',
              itemId: 5,
              name: 'Dague',
              quantity: 1,
              equipped: false,
              costAmount: 2,
              priceOverrideAmount: 15,
              priceOverrideCurrency: CurrencyKind.silver,
            ),
          ),
        ),
      );

      expect(find.text('15 PA'), findsOneWidget);
      expect(find.text('Modifié'), findsOneWidget);
    });

    testWidgets('prix fixé d\'un objet personnalisé : jamais de pastille '
        '« Modifié » (aucun prix officiel à surcharger)', (tester) async {
      await tester.pumpWidget(
        _app(
          const ItemInfoBody(
            item: CharacterInventoryItem(
              id: 'inv-4',
              name: 'Amulette',
              quantity: 1,
              equipped: false,
              priceOverrideAmount: 250,
              priceOverrideCurrency: CurrencyKind.gold,
            ),
          ),
        ),
      );

      expect(find.text('250 PO'), findsOneWidget);
      expect(find.text('Modifié'), findsNothing);
    });

    testWidgets('aucun prix connu, lecture seule : « Non estimé » sans '
        'lien', (tester) async {
      await tester.pumpWidget(
        _app(
          const ItemInfoBody(
            item: CharacterInventoryItem(
              id: 'inv-5',
              name: 'Objet magique',
              quantity: 1,
              equipped: false,
            ),
          ),
        ),
      );

      expect(find.text('Non estimé'), findsOneWidget);
      expect(find.text('Fixer un prix'), findsNothing);
    });

    testWidgets('aucun prix connu, écriture possible : lien « Fixer un '
        'prix » qui ferme le panneau et appelle le callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _app(
          ItemInfoBody(
            item: const CharacterInventoryItem(
              id: 'inv-6',
              name: 'Objet magique',
              quantity: 1,
              equipped: false,
            ),
            onEditPrice: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Non estimé'), findsOneWidget);
      expect(find.text('Fixer un prix'), findsOneWidget);
      await tester.tap(find.text('Fixer un prix'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('butin de groupe : lien tutoyé « Fixe un prix »', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          ItemInfoBody(
            item: const CharacterInventoryItem(
              id: 'inv-7',
              name: 'Objet magique',
              quantity: 1,
              equipped: false,
            ),
            withoutCharacter: true,
            onEditPrice: () {},
            priceSetLinkLabel: 'Fixe un prix',
          ),
        ),
      );

      expect(find.text('Fixe un prix'), findsOneWidget);
    });
  });

  group('showItemQuantitySheet', () {
    Future<int?> open(
      WidgetTester tester, {
      int initialValue = 1,
      int? max,
    }) async {
      ItemQuantitySheetResult? result;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async => result = await showItemQuantitySheet(
                context,
                title: 'Quantité de Corde',
                buttonLabel: 'Enregistrer',
                initialValue: initialValue,
                max: max,
              ),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      expect(find.text('Quantité de Corde'), findsOneWidget);
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byIcon(Icons.add));
        await tester.pump();
      }
      await tester.tap(find.text('ENREGISTRER'));
      await tester.pumpAndSettle();
      return result?.quantity;
    }

    testWidgets('plafonnée au maximum', (tester) async {
      expect(await open(tester, max: 3), 3);
    });

    testWidgets('sans maximum, à partir de la valeur de départ', (
      tester,
    ) async {
      expect(await open(tester, initialValue: 5), 9);
    });

    testWidgets('showPrice : section « Prix » optionnelle sous le stepper '
        'de quantité (spec du prix d\'un objet modifiable, §4)', (
      tester,
    ) async {
      ItemQuantitySheetResult? result;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async => result = await showItemQuantitySheet(
                context,
                title: 'Quantité de Bouclier',
                buttonLabel: 'Enregistrer',
                showPrice: true,
                initialPriceAmount: 15,
                initialPriceCurrency: CurrencyKind.silver,
              ),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      expect(find.text('Prix'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('Retire la surcharge'), findsOneWidget);

      await tester.tap(find.text('ENREGISTRER'));
      await tester.pumpAndSettle();
      expect(result?.priceAmount, 15);
      expect(result?.priceCurrency, CurrencyKind.silver);
      expect(result?.removedViaLink, isFalse);
    });

    testWidgets('showPrice : « Retire la surcharge » ferme directement '
        'avec un prix nul', (tester) async {
      ItemQuantitySheetResult? result;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async => result = await showItemQuantitySheet(
                context,
                title: 'Quantité de Bouclier',
                buttonLabel: 'Enregistrer',
                showPrice: true,
                initialPriceAmount: 15,
                initialPriceCurrency: CurrencyKind.silver,
              ),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Retire la surcharge'));
      await tester.pumpAndSettle();

      expect(result?.priceAmount, isNull);
      expect(result?.priceCurrency, isNull);
      expect(result?.removedViaLink, isTrue);
    });

    testWidgets('showPrice sans surcharge existante : pas de lien « Retire '
        'la surcharge »', (tester) async {
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async => showItemQuantitySheet(
                context,
                title: 'Quantité de Bouclier',
                buttonLabel: 'Enregistrer',
                showPrice: true,
              ),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      expect(find.text('Retire la surcharge'), findsNothing);
    });
  });

  testWidgets('confirmation de retrait : titre et texte en paramètres', (
    tester,
  ) async {
    bool? confirmed;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async =>
                confirmed = await showRemoveInventoryItemConfirmationDialog(
                  context,
                  itemName: 'Corde',
                  title: 'Retirer Corde du butin ?',
                  body: 'Texte du butin.',
                ),
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Retirer Corde du butin ?'), findsOneWidget);
    expect(find.text('Texte du butin.'), findsOneWidget);
    expect(find.text('Cette action est définitive.'), findsNothing);
    await tester.tap(find.text('Retirer'));
    await tester.pumpAndSettle();
    expect(confirmed, isTrue);
  });

  testWidgets('pied « Objet » seul (butin) : pas de bouton Récompense', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(InventoryAddRowButtons(onAddItem: () {}, showRewardButton: false)),
    );

    expect(find.byType(DashedAddTile), findsOneWidget);
    expect(find.byIcon(Icons.card_giftcard), findsNothing);
  });
}
