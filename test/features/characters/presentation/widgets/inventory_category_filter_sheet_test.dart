// Tests de widget de la sheet "Filtrer par catégorie" de l'onglet
// "Inventaire" (`presentation/widgets/inventory_category_filter_sheet.dart`) :
// choix exclusif qui ferme la sheet, et tenue de la mise en page quand la
// barre de tête grandit (texte agrandi) sur un petit écran avec les marges
// système d'un vrai appareil.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/selectable_option_tile.dart';
import 'package:personnages/core/widgets/sheet_header_bar.dart';
import 'package:personnages/features/characters/domain/inventory_category_filter.dart';
import 'package:personnages/features/characters/presentation/widgets/inventory_category_filter_sheet.dart';

/// Résultat de la sheet, renseigné quand elle se referme.
class _SheetResult {
  bool closed = false;
  InventoryCategoryFilter? value;
}

Future<_SheetResult> _open(
  WidgetTester tester, {
  InventoryCategoryFilter current = InventoryCategoryFilter.all,
}) async {
  final result = _SheetResult();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result.value = await showInventoryCategoryFilterSheet(
                context,
                current: current,
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

Finder _option(InventoryCategoryFilter filter) =>
    find.widgetWithText(SelectableOptionTile, filter.label);

void main() {
  testWidgets('affiche le titre et une option par catégorie, la catégorie '
      'courante sélectionnée', (tester) async {
    await _open(tester, current: InventoryCategoryFilter.armor);

    expect(find.text('FILTRER PAR CATÉGORIE'), findsOneWidget);
    for (final filter in InventoryCategoryFilter.values) {
      expect(
        tester.widget<SelectableOptionTile>(_option(filter)).selected,
        filter == InventoryCategoryFilter.armor,
      );
    }
  });

  testWidgets('un tap sur une option ferme la sheet avec cette catégorie', (
    tester,
  ) async {
    final result = await _open(tester);

    await tester.tap(_option(InventoryCategoryFilter.weapons));
    await tester.pumpAndSettle();

    expect(result.closed, isTrue);
    expect(result.value, InventoryCategoryFilter.weapons);
    expect(find.byType(SheetHeaderBar), findsNothing);
  });

  testWidgets('la croix ferme la sheet sans choix', (tester) async {
    final result = await _open(tester, current: InventoryCategoryFilter.misc);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(result.closed, isTrue);
    expect(result.value, isNull);
  });

  testWidgets('texte agrandi à 200 % sur petit écran (320×568) avec marges '
      'système (barre d\'état, barre de navigation à 3 boutons) : pas de '
      'débordement, barre de tête fixe, dernière option atteignable par '
      'défilement et sélectionnable', (tester) async {
    const systemPadding = FakeViewPadding(top: 24, bottom: 48);
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = systemPadding;
    tester.view.viewPadding = systemPadding;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    // Tout débordement lèverait une exception, qui ferait échouer ce test.
    final result = await _open(tester);

    // La barre de tête a grandi avec son titre.
    final header = tester.getRect(find.byType(SheetHeaderBar));
    expect(header.height, greaterThan(56));

    // Les options ne tiennent plus toutes entre la barre de tête et la barre
    // de navigation : la dernière est ramenée à l'écran par défilement.
    const visibleBottom = 568.0 - 48;
    final lastOption = _option(InventoryCategoryFilter.values.last);
    expect(tester.getRect(lastOption).bottom, greaterThan(visibleBottom));

    await tester.scrollUntilVisible(
      lastOption,
      50,
      scrollable: find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();

    final visibleLastOption = tester.getRect(lastOption);
    expect(visibleLastOption.top, greaterThanOrEqualTo(header.bottom));
    expect(visibleLastOption.bottom, lessThanOrEqualTo(visibleBottom));
    // La barre de tête ne défile pas avec les options.
    expect(tester.getRect(find.byType(SheetHeaderBar)), header);

    await tester.tap(lastOption);
    await tester.pumpAndSettle();

    expect(result.closed, isTrue);
    expect(result.value, InventoryCategoryFilter.values.last);
  });
}
