// Tests de widget de la carte « ARMES ÉQUIPÉES » de l'onglet « Personnage »
// — voir `character_detail_screen_test.dart`/`shared_character_view_screen_test.dart`
// pour son intégration.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/domain/weapon_slot.dart';
import 'package:personnages/features/characters/presentation/widgets/character_equipped_weapons_card.dart';

const _longbow = CharacterInventoryItem(
  id: 'inv-1',
  itemId: 10,
  name: 'Arc long',
  category: 'arme',
  quantity: 1,
  equipped: true,
  weaponSlot: WeaponSlot.principal,
  weaponProperties: CharacterInventoryWeaponProperties(
    damageDice: '1d8',
    damageType: 'perforant',
    properties: ['lourde', 'munitions'],
    rangeNormal: 150,
    rangeMax: 600,
  ),
);

const _dagger = CharacterInventoryItem(
  id: 'inv-2',
  itemId: 11,
  name: 'Dague',
  category: 'arme',
  quantity: 1,
  equipped: true,
  weaponSlot: WeaponSlot.principal,
  weaponProperties: CharacterInventoryWeaponProperties(
    damageDice: '1d4',
    damageType: 'perforant',
    properties: ['légère', 'finesse'],
  ),
);

Future<void> _pumpCard(
  WidgetTester tester,
  List<CharacterInventoryItem> weapons,
) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: CharacterEquippedWeaponsCard(weapons: weapons),
      ),
    ),
  ),
);

void main() {
  group('CharacterEquippedWeaponsCard', () {
    testWidgets('liste vide : état vide, pas de titre d\'arme', (tester) async {
      await _pumpCard(tester, const []);

      expect(find.text('ARMES ÉQUIPÉES'), findsOneWidget);
      expect(find.text('Aucune arme équipée'), findsOneWidget);
      expect(
        find.text(
          "Équipez une arme depuis l'onglet Inventaire pour qu'elle "
          'apparaisse ici.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'une arme (set principal) : nom, dégâts, propriétés, portée avec max, '
      'set secondaire affiche "Aucune arme dans ce set."',
      (tester) async {
        await _pumpCard(tester, const [_longbow]);

        expect(find.text('Arc long'), findsOneWidget);
        expect(find.text('1d8 perforant'), findsOneWidget);
        expect(find.text('lourde, munitions'), findsOneWidget);
        expect(find.text('Portée : 150 m (max 600 m)'), findsOneWidget);
        expect(find.text('Aucune arme équipée'), findsNothing);
        expect(find.text('SET PRINCIPAL'), findsOneWidget);
        expect(find.text('SET SECONDAIRE'), findsOneWidget);
        expect(find.text('Aucune arme dans ce set.'), findsOneWidget);
      },
    );

    testWidgets('arme sans portée : aucune ligne "Portée"', (tester) async {
      await _pumpCard(tester, const [_dagger]);

      expect(find.text('Dague'), findsOneWidget);
      expect(find.text('1d4 perforant'), findsOneWidget);
      expect(find.text('légère, finesse'), findsOneWidget);
      expect(find.textContaining('Portée'), findsNothing);
    });

    testWidgets(
      'deux armes du même set (principal) : séparateur entre les deux, pas '
      'après la dernière, set secondaire vide',
      (tester) async {
        await _pumpCard(tester, const [_longbow, _dagger]);

        expect(find.text('Arc long'), findsOneWidget);
        expect(find.text('Dague'), findsOneWidget);
        // Un seul séparateur intra-groupe (set principal) : le séparateur
        // entre les deux sous-sections utilise le même widget
        // `SheetActionDivider`/`Divider` — total 2 (intra-groupe +
        // inter-groupes).
        expect(find.byType(Divider), findsNWidgets(2));
        expect(find.text('Aucune arme dans ce set.'), findsOneWidget);
      },
    );

    testWidgets(
      'une arme par set : chaque sous-section affiche son arme, aucun '
      'message "Aucune arme dans ce set."',
      (tester) async {
        const secondaryDagger = CharacterInventoryItem(
          id: 'inv-2b',
          itemId: 11,
          name: 'Dague de réserve',
          category: 'arme',
          quantity: 1,
          equipped: true,
          weaponSlot: WeaponSlot.secondary,
        );
        await _pumpCard(tester, const [_longbow, secondaryDagger]);

        expect(find.text('SET PRINCIPAL'), findsOneWidget);
        expect(find.text('SET SECONDAIRE'), findsOneWidget);
        expect(find.text('Arc long'), findsOneWidget);
        expect(find.text('Dague de réserve'), findsOneWidget);
        expect(find.text('Aucune arme dans ce set.'), findsNothing);
      },
    );

    testWidgets(
      'une arme sans weaponSlot (null) est traitée comme principale, par '
      'sécurité d\'affichage (ne devrait pas arriver après le backfill de '
      'migration)',
      (tester) async {
        const noSlot = CharacterInventoryItem(
          id: 'inv-4',
          itemId: 13,
          name: 'Masse ancienne',
          category: 'arme',
          quantity: 1,
          equipped: true,
        );
        await _pumpCard(tester, const [noSlot]);

        expect(find.text('SET PRINCIPAL'), findsOneWidget);
        expect(find.text('Masse ancienne'), findsOneWidget);
      },
    );

    testWidgets('aucune puce "Maîtrisée"/"Arme magique"', (tester) async {
      await _pumpCard(tester, const [_longbow]);

      expect(find.text('Maîtrisée'), findsNothing);
      expect(find.text('Arme magique'), findsNothing);
    });

    testWidgets(
      'libellé sémantique « Arme équipée : nom, dés type, Portée : ... »',
      (tester) async {
        final handle = tester.ensureSemantics();
        await _pumpCard(tester, const [_longbow]);

        expect(
          find.bySemanticsLabel(
            'Arme équipée : Arc long, 1d8 perforant, '
            'Portée : 150 m (max 600 m)',
          ),
          findsOneWidget,
        );
        handle.dispose();
      },
    );

    testWidgets('libellé sémantique sans dégâts/portée : nom seul', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      const bareItem = CharacterInventoryItem(
        id: 'inv-3',
        itemId: 12,
        name: 'Objet contondant maison',
        category: 'arme',
        quantity: 1,
        equipped: true,
      );
      await _pumpCard(tester, const [bareItem]);

      expect(
        find.bySemanticsLabel('Arme équipée : Objet contondant maison'),
        findsOneWidget,
      );
      handle.dispose();
    });
  });
}
