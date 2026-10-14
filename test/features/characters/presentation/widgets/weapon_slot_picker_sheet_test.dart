// Tests de widget de la sheet "Choisir un set"
// (`presentation/widgets/weapon_slot_picker_sheet.dart`) : affichage des deux
// sets, occupant(s) de chacun, choix qui ferme la sheet, fermeture sans
// choix — et non-régression D24 (`docs/dette-technique.md`) : plus de
// débordement à l'échelle de texte 200 %/300 % sur petit écran, et la sheet
// ne force plus 90 % de hauteur pour un contenu aussi court que celui-ci.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/core/widgets/sheet_header_bar.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/domain/weapon_slot.dart';
import 'package:personnages/features/characters/presentation/widgets/weapon_slot_picker_sheet.dart';

CharacterInventoryItem _weapon({
  required String id,
  required String name,
  WeaponSlot? slot,
}) => CharacterInventoryItem(
  id: id,
  itemId: int.parse(id.split('-').last),
  name: name,
  category: 'arme',
  quantity: 1,
  equipped: true,
  weaponSlot: slot,
);

class _SheetResult {
  bool closed = false;
  WeaponSlot? value;
}

Future<_SheetResult> _open(
  WidgetTester tester, {
  List<CharacterInventoryItem> equippedWeapons = const [],
  String currentItemId = 'inv-99',
  double textScale = 1,
  Size screenSize = const Size(800, 600),
}) async {
  tester.view.physicalSize = screenSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final result = _SheetResult();
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result.value = await showWeaponSlotPickerSheet(
                context,
                equippedWeapons: equippedWeapons,
                currentItemId: currentItemId,
              );
              result.closed = true;
            },
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets(
    'affiche les deux sets, « Vide » quand aucune arme ne l\'occupe',
    (tester) async {
      await _open(tester);

      expect(find.text('CHOISIR UN SET'), findsOneWidget);
      expect(find.text('Set principal'), findsOneWidget);
      expect(find.text('Set secondaire'), findsOneWidget);
      expect(find.text('Vide'), findsNWidgets(2));
    },
  );

  testWidgets(
    'affiche le nom de l\'arme déjà équipée dans un set, exclut l\'arme en '
    'cours de réassignation',
    (tester) async {
      await _open(
        tester,
        equippedWeapons: [
          _weapon(id: 'inv-1', name: 'Épée longue', slot: WeaponSlot.principal),
          _weapon(id: 'inv-99', name: 'Dague', slot: WeaponSlot.secondary),
        ],
        currentItemId: 'inv-99',
      );

      expect(find.text('Épée longue'), findsOneWidget);
      // L'arme en cours de réassignation (inv-99) n'apparaît pas comme
      // occupant de son set actuel.
      expect(find.text('Dague'), findsNothing);
      expect(find.text('Vide'), findsOneWidget);
    },
  );

  testWidgets('un tap sur un set ferme la sheet avec ce set', (tester) async {
    final result = await _open(tester);

    await tester.tap(find.text('Set secondaire'));
    await tester.pumpAndSettle();

    expect(result.closed, isTrue);
    expect(result.value, WeaponSlot.secondary);
  });

  testWidgets('fermer sans choisir renvoie null', (tester) async {
    final result = await _open(tester);

    await tester.tapAt(const Offset(400, 10));
    await tester.pumpAndSettle();

    expect(result.closed, isTrue);
    expect(result.value, isNull);
  });

  group('D24 : texte agrandi sur petit écran (320×568)', () {
    // Hauteur réelle occupée par la sheet (du haut de sa barre de tête —
    // toujours son premier élément — au bas de l'écran, où une bottom sheet
    // est toujours ancrée, contenu court ou non).
    double sheetHeight(WidgetTester tester, double screenHeight) =>
        screenHeight - tester.getRect(find.byType(SheetHeaderBar)).top;

    testWidgets(
      'contenu court : la hauteur de la sheet suit son contenu, pas la '
      'hauteur de l\'écran (`ConstrainedBox(maxHeight: 90 %)` n\'étire pas '
      'un contenu court jusqu\'à son plafond)',
      (tester) async {
        await _open(tester, screenSize: const Size(320, 568));
        final heightOnSmallScreen = sheetHeight(tester, 568);

        // Referme proprement la première sheet avant d'en ouvrir une
        // seconde sur un nouvel écran (sans quoi la seconde `pumpWidget`
        // remplace l'arbre pendant qu'une route modale de la première est
        // encore en vol, et le tap sur "Ouvrir" ne retrouve plus le bon
        // bouton).
        await tester.tapAt(const Offset(160, 10));
        await tester.pumpAndSettle();

        await _open(tester, screenSize: const Size(320, 2000));
        final heightOnTallScreen = sheetHeight(tester, 2000);

        // Même contenu, plafonds très différents : une hauteur de sheet
        // identique prouve qu'elle épouse son contenu plutôt que de
        // s'étirer vers son plafond.
        expect(heightOnTallScreen, moreOrLessEquals(heightOnSmallScreen));
      },
    );

    testWidgets(
      'échelle 2 (plafond documenté `AppTypography.maxTextScaleFactor`) : '
      'aucun débordement, les deux sets restent sélectionnables',
      (tester) async {
        final result = await _open(
          tester,
          screenSize: const Size(320, 568),
          textScale: 2,
          equippedWeapons: [
            _weapon(
              id: 'inv-1',
              name: 'Épée longue +1 de la lignée des rois oubliés',
              slot: WeaponSlot.principal,
            ),
          ],
        );

        expect(tester.takeException(), isNull);

        await tester.scrollUntilVisible(
          find.text('Set secondaire'),
          50,
          scrollable: find.descendant(
            of: find.byType(SingleChildScrollView),
            matching: find.byType(Scrollable),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Set secondaire'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(result.closed, isTrue);
        expect(result.value, WeaponSlot.secondary);
      },
    );

    testWidgets('échelle 3 : aucun débordement, les deux sets restent '
        'sélectionnables (défilement si besoin)', (tester) async {
      final result = await _open(
        tester,
        screenSize: const Size(320, 568),
        textScale: 3,
        equippedWeapons: [
          _weapon(
            id: 'inv-1',
            name: 'Épée longue +1 de la lignée des rois oubliés',
            slot: WeaponSlot.principal,
          ),
        ],
      );

      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.text('Set secondaire'),
        50,
        scrollable: find.descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Set secondaire'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(result.closed, isTrue);
      expect(result.value, WeaponSlot.secondary);
    });
  });

  // Garde-fou : ce fichier ne doit jamais devenir mort de code si
  // `PrimaryButton` disparaît de la sheet (elle n'en a pas, contrairement
  // aux sheets autoportantes de `profile/` — gabarit C "liste d'actions").
  testWidgets('aucun PrimaryButton : chaque tap sur une ligne ferme '
      'directement la sheet', (tester) async {
    await _open(tester);
    expect(find.byType(PrimaryButton), findsNothing);
  });
}
