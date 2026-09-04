// Tests de widget de la sheet "Actions d'objet"
// (`presentation/widgets/item_action_sheet.dart`) et du panneau "Infos"
// qu'elle peut ouvrir — même patron que `spell_action_sheet_test.dart` : la
// sheet est ouverte depuis un `Builder` minimal, les callbacks sont de
// simples closures enregistrant leurs appels (toute la logique d'écriture
// réseau vit dans `character_detail_screen.dart`, hors périmètre de ce
// fichier).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/presentation/widgets/item_action_sheet.dart';

const _customItem = CharacterInventoryItem(
  id: 'inv-custom',
  name: 'Petit sac de sable',
  quantity: 1,
  equipped: false,
);

const _sword = CharacterInventoryItem(
  id: 'inv-sword',
  itemId: 1,
  name: 'Épée longue',
  category: 'arme',
  quantity: 1,
  equipped: false,
  unitWeight: 1.5,
  costAmount: 15,
  description: 'Une lame affûtée.',
  weaponProperties: CharacterInventoryWeaponProperties(
    damageDice: '1d8',
    damageType: 'tranchant',
    properties: ['polyvalente(1d10)'],
    rangeNormal: null,
    rangeMax: null,
  ),
);

const _armor = CharacterInventoryItem(
  id: 'inv-armor',
  itemId: 2,
  name: 'Chemise de mailles',
  category: 'armure',
  quantity: 1,
  equipped: true,
  armorProperties: CharacterInventoryArmorProperties(
    acBase: 13,
    acDexBonus: 'max_2',
    strengthRequirement: null,
    stealthDisadvantage: false,
  ),
);

const _potion = CharacterInventoryItem(
  id: 'inv-potion',
  itemId: 3,
  name: 'Potion de soins',
  category: 'equipement_general',
  quantity: 3,
  equipped: false,
  consumable: true,
);

const _magicItem = CharacterInventoryItem(
  id: 'inv-magic',
  itemId: 4,
  name: 'Amulette de vitalité',
  category: 'objet_magique',
  quantity: 1,
  equipped: false,
  rarity: 'rare',
  requiresAttunement: true,
);

void main() {
  List<CharacterInventoryItem> useCalls = [];
  List<CharacterInventoryItem> toggleCalls = [];
  List<CharacterInventoryItem> removeCalls = [];

  Future<void> pumpSheet(
    WidgetTester tester, {
    required CharacterInventoryItem item,
  }) async {
    useCalls = [];
    toggleCalls = [];
    removeCalls = [];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showItemActionSheet(
                  context,
                  item: item,
                  onUseItem: useCalls.add,
                  onToggleEquipped: toggleCalls.add,
                  onRemoveItem: removeCalls.add,
                ),
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
  }

  group('sheet d\'actions', () {
    testWidgets('un objet personnalisé n\'a que "Infos" et "Retirer"', (
      tester,
    ) async {
      await pumpSheet(tester, item: _customItem);

      expect(find.text('Petit sac de sable'), findsOneWidget);
      expect(find.text('Objet personnalisé · x1'), findsOneWidget);
      expect(find.text('Infos'), findsOneWidget);
      expect(find.text('Utiliser'), findsNothing);
      expect(find.text('Équiper'), findsNothing);
      expect(find.text('Déséquiper'), findsNothing);
      expect(find.text('Retirer'), findsOneWidget);
    });

    testWidgets(
      'une arme non équipée : "Équiper" (pas "Utiliser", pas consommable)',
      (tester) async {
        await pumpSheet(tester, item: _sword);

        expect(find.text('Équiper'), findsOneWidget);
        expect(find.text('Utiliser'), findsNothing);

        await tester.tap(find.text('Équiper'));
        await tester.pumpAndSettle();

        expect(toggleCalls, [_sword]);
      },
    );

    testWidgets('une armure déjà équipée : libellé "Déséquiper"', (
      tester,
    ) async {
      await pumpSheet(tester, item: _armor);

      expect(find.text('Déséquiper'), findsOneWidget);
      expect(find.text('Équiper'), findsNothing);

      await tester.tap(find.text('Déséquiper'));
      await tester.pumpAndSettle();

      expect(toggleCalls, [_armor]);
    });

    testWidgets(
      'un objet consommable : "Utiliser" (pas "Équiper"/"Déséquiper", '
      'catégorie non équipable)',
      (tester) async {
        await pumpSheet(tester, item: _potion);

        expect(find.text('Utiliser'), findsOneWidget);
        expect(find.text('Équiper'), findsNothing);

        await tester.tap(find.text('Utiliser'));
        await tester.pumpAndSettle();

        expect(useCalls, [_potion]);
      },
    );

    testWidgets(
      '"Retirer" ouvre le dialogue de confirmation ; "Annuler" ne déclenche '
      'rien',
      (tester) async {
        await pumpSheet(tester, item: _sword);

        await tester.tap(find.text('Retirer'));
        await tester.pumpAndSettle();

        expect(find.text('Retirer Épée longue ?'), findsOneWidget);
        expect(find.text('Cette action est définitive.'), findsOneWidget);

        await tester.tap(find.text('ANNULER'));
        await tester.pumpAndSettle();

        expect(removeCalls, isEmpty);
      },
    );

    testWidgets('"Retirer" confirmé appelle onRemoveItem', (tester) async {
      await pumpSheet(tester, item: _sword);

      await tester.tap(find.text('Retirer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retirer'));
      await tester.pumpAndSettle();

      expect(removeCalls, [_sword]);
    });
  });

  group('panneau "Infos"', () {
    testWidgets('une arme : poids unitaire, coût, dégâts, propriétés, '
        'description, footer "Équiper"', (tester) async {
      await pumpSheet(tester, item: _sword);

      await tester.tap(find.text('Infos'));
      await tester.pumpAndSettle();

      expect(find.text('ÉPÉE LONGUE'), findsOneWidget);
      expect(find.text('Poids unitaire'), findsOneWidget);
      expect(find.text('1,5 kg'), findsOneWidget);
      expect(find.text('Coût'), findsOneWidget);
      expect(find.text('15 po'), findsOneWidget);
      expect(find.text('Dégâts'), findsOneWidget);
      expect(find.text('1d8 tranchant'), findsOneWidget);
      expect(find.text('Propriétés'), findsOneWidget);
      expect(find.text('polyvalente(1d10)'), findsOneWidget);
      // Pas de portée (arme de corps à corps, rangeNormal nul).
      expect(find.text('Portée'), findsNothing);
      expect(find.text('DESCRIPTION'), findsOneWidget);
      expect(find.text('Une lame affûtée.'), findsOneWidget);

      final button = tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, 'ÉQUIPER'),
      );
      expect(button.onPressed, isNotNull);

      await tester.tap(find.widgetWithText(PrimaryButton, 'ÉQUIPER'));
      await tester.pumpAndSettle();

      expect(toggleCalls, [_sword]);
    });

    testWidgets('une armure : CA de base, bonus Dex, désavantage discrétion, '
        'force requise omise si nulle', (tester) async {
      await pumpSheet(tester, item: _armor);

      await tester.tap(find.text('Infos'));
      await tester.pumpAndSettle();

      expect(find.text('CA de base'), findsOneWidget);
      expect(find.text('13'), findsOneWidget);
      expect(find.text('Bonus Dex'), findsOneWidget);
      expect(find.text('+2 max'), findsOneWidget);
      expect(find.text('Force requise'), findsNothing);
      expect(find.text('Désavantage discrétion'), findsOneWidget);
      expect(find.text('Non'), findsOneWidget);

      // Déjà équipée -> le footer propose "Déséquiper".
      expect(find.widgetWithText(PrimaryButton, 'DÉSÉQUIPER'), findsOneWidget);
    });

    testWidgets('un objet magique : rareté et attunement affichés, jamais '
        'en doré (texte textPrimary)', (tester) async {
      await pumpSheet(tester, item: _magicItem);

      await tester.tap(find.text('Infos'));
      await tester.pumpAndSettle();

      expect(find.text('Rareté'), findsOneWidget);
      expect(find.text('Rare'), findsOneWidget);
      expect(find.text('Attunement requis'), findsOneWidget);
      expect(find.text('Oui'), findsOneWidget);
      // Ni consommable ni équipable -> aucun bouton en pied.
      expect(find.byType(PrimaryButton), findsNothing);
    });

    testWidgets('description absente affiche un texte de repli', (
      tester,
    ) async {
      await pumpSheet(tester, item: _customItem);

      await tester.tap(find.text('Infos'));
      await tester.pumpAndSettle();

      expect(find.text('Aucune description disponible.'), findsOneWidget);
      // Objet personnalisé : ni poids ni coût connus, aucune ligne affichée
      // avant la description.
      expect(find.text('Poids unitaire'), findsNothing);
      expect(find.text('Coût'), findsNothing);
    });

    testWidgets(
      "un objet consommable : le bouton 'Utiliser' du panneau délègue à "
      'onUseItem',
      (tester) async {
        await pumpSheet(tester, item: _potion);

        await tester.tap(find.text('Infos'));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(PrimaryButton, 'UTILISER'));
        await tester.pumpAndSettle();

        expect(useCalls, [_potion]);
      },
    );
  });
}
