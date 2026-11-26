// Composants de l'inventaire partagés avec le butin de groupe (décision
// 91) : corps du panneau Infos (`ItemInfoBody`, variante sans personnage),
// sheet de quantité (`showItemQuantitySheet`, bornes), confirmation de
// retrait (titre et texte en paramètres) et pied « Objet » seul.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/dashed_add_tile.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
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

  group('showItemQuantitySheet', () {
    Future<int?> open(
      WidgetTester tester, {
      int initialValue = 1,
      int? max,
    }) async {
      int? result;
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
      return result;
    }

    testWidgets('plafonnée au maximum', (tester) async {
      expect(await open(tester, max: 3), 3);
    });

    testWidgets('sans maximum, à partir de la valeur de départ', (
      tester,
    ) async {
      expect(await open(tester, initialValue: 5), 9);
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
