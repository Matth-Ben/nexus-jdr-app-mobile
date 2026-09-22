// Tests de widget de la carte « ARMES ÉQUIPÉES » de l'onglet « Personnage »
// — voir `character_detail_screen_test.dart`/`shared_character_view_screen_test.dart`
// pour son intégration.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/presentation/widgets/character_equipped_weapons_card.dart';

const _longbow = CharacterInventoryItem(
  id: 'inv-1',
  itemId: 10,
  name: 'Arc long',
  category: 'arme',
  quantity: 1,
  equipped: true,
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
      'une arme : nom, dégâts, propriétés, portée avec max, pas de séparateur',
      (tester) async {
        await _pumpCard(tester, const [_longbow]);

        expect(find.text('Arc long'), findsOneWidget);
        expect(find.text('1d8 perforant'), findsOneWidget);
        expect(find.text('lourde, munitions'), findsOneWidget);
        expect(find.text('Portée : 150 m (max 600 m)'), findsOneWidget);
        expect(find.text('Aucune arme équipée'), findsNothing);
      },
    );

    testWidgets('arme sans portée : aucune ligne "Portée"', (tester) async {
      await _pumpCard(tester, const [_dagger]);

      expect(find.text('Dague'), findsOneWidget);
      expect(find.text('1d4 perforant'), findsOneWidget);
      expect(find.text('légère, finesse'), findsOneWidget);
      expect(find.textContaining('Portée'), findsNothing);
    });

    testWidgets('deux armes : séparateur entre les deux, pas après la '
        'dernière', (tester) async {
      await _pumpCard(tester, const [_longbow, _dagger]);

      expect(find.text('Arc long'), findsOneWidget);
      expect(find.text('Dague'), findsOneWidget);
      expect(find.byType(Divider), findsOneWidget);
    });

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
