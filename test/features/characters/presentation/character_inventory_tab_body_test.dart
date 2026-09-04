// Tests de widget de l'onglet "Inventaire" de la fiche personnage — voir
// `docs/cahier-des-charges/09-maquettes-captures.md`, section "Onglet
// Inventaire".
//
// `CharacterInventoryTabBody` reste un `StatelessWidget` pur (pas de
// Riverpod, pas de réseau) : les sheets qu'il ouvre le sont aussi, à
// l'exception de la sheet "Depuis le catalogue" (`add_item_flow.dart`, qui a
// besoin de `inventoryCatalogProvider`) — volontairement pas exercée ici
// (elle a son test dédié), ce fichier se limite au chemin "Objet
// personnalisé" pour rester sans `ProviderScope`, même approche que
// `character_skills_tab_body_test.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/dashed_border_painter.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
import 'package:personnages/features/characters/domain/currency_kind.dart';
import 'package:personnages/features/characters/domain/inventory_catalog_item.dart';
import 'package:personnages/features/characters/presentation/widgets/character_inventory_tab_body.dart';

/// `find` sur un `CustomPaint` peint par [DashedBorderPainter] — plus fiable
/// qu'un `find.byType(CustomPaint)` seul (d'autres `CustomPaint` internes à
/// Flutter peuvent apparaître dans l'arbre) pour vérifier qu'un badge/une
/// tuile est bien rendu en pointillés, pas seulement son texte.
Finder _dashedBorderFinder() => find.byWidgetPredicate(
  (widget) => widget is CustomPaint && widget.painter is DashedBorderPainter,
);

CharacterDetail _detail({
  int currencyGp = 0,
  int currencyPp = 0,
  int currencyEp = 0,
  int currencySp = 0,
  int currencyCp = 0,
  List<CharacterInventoryItem> inventory = const [],
}) {
  return CharacterDetail(
    id: '1',
    name: 'Test',
    classes: const [],
    xp: 0,
    currentHp: 10,
    maxHp: 10,
    temporaryHp: 0,
    abilityScores: const {},
    currencyGp: currencyGp,
    currencyPp: currencyPp,
    currencyEp: currencyEp,
    currencySp: currencySp,
    currencyCp: currencyCp,
    inventory: inventory,
  );
}

class _Recorder {
  final List<CharacterInventoryItem> useCalls = [];
  final List<CharacterInventoryItem> toggleCalls = [];
  final List<CharacterInventoryItem> removeCalls = [];
  final List<(CurrencyKind, int)> adjustCurrencyCalls = [];
  final List<(InventoryCatalogItem, int)> addItemCalls = [];
  final List<(String, int)> addCustomItemCalls = [];
}

Future<_Recorder> _pump(
  WidgetTester tester,
  CharacterDetail detail, {
  bool actionsDisabled = false,
}) async {
  final recorder = _Recorder();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CharacterInventoryTabBody(
          detail: detail,
          actionsDisabled: actionsDisabled,
          onUseItem: recorder.useCalls.add,
          onToggleItemEquipped: recorder.toggleCalls.add,
          onRemoveItem: recorder.removeCalls.add,
          onAdjustCurrency: (currency, amount) =>
              recorder.adjustCurrencyCalls.add((currency, amount)),
          onAddInventoryItem: (item, quantity) =>
              recorder.addItemCalls.add((item, quantity)),
          onAddCustomInventoryItem: (name, quantity) =>
              recorder.addCustomItemCalls.add((name, quantity)),
        ),
      ),
    ),
  );
  return recorder;
}

const _dagger = CharacterInventoryItem(
  id: 'inv-1',
  itemId: 1,
  name: 'Dague',
  category: 'arme',
  quantity: 2,
  equipped: false,
  totalWeight: 1,
);

const _potion = CharacterInventoryItem(
  id: 'inv-2',
  itemId: 2,
  name: 'Potion de soins',
  category: 'equipement_general',
  quantity: 3,
  equipped: false,
  consumable: true,
);

const _customItem = CharacterInventoryItem(
  id: 'inv-3',
  name: 'Petit sac de sable',
  quantity: 1,
  equipped: false,
);

void main() {
  testWidgets('affiche la rangée de monnaie/poids (or/argent/cuivre '
      'toujours visibles)', (tester) async {
    await _pump(tester, _detail(currencyGp: 42, currencySp: 6, currencyCp: 14));

    expect(find.text('42'), findsOneWidget);
    expect(find.text('PO'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('PA'), findsOneWidget);
    expect(find.text('14'), findsOneWidget);
    expect(find.text('PC'), findsOneWidget);
    // Poids total à 0 (aucun objet) : la box "KG" reste affichée.
    expect(find.text('KG'), findsOneWidget);
  });

  testWidgets('la box PP n\'apparaît que si la platine est non nulle', (
    tester,
  ) async {
    await _pump(tester, _detail(currencyGp: 10));
    expect(find.text('PP'), findsNothing);

    await _pump(tester, _detail(currencyGp: 10, currencyPp: 3));
    expect(find.text('PP'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('affiche un objet du catalogue avec sa catégorie et sa '
      'quantité', (tester) async {
    await _pump(tester, _detail(inventory: const [_dagger]));

    expect(find.text('Dague'), findsOneWidget);
    expect(find.text('Arme · x2'), findsOneWidget);
    expect(find.text('1 kg'), findsOneWidget);
  });

  testWidgets('un objet équipé affiche le badge ÉQUIPÉ plutôt que son poids', (
    tester,
  ) async {
    await _pump(
      tester,
      _detail(
        inventory: const [
          CharacterInventoryItem(
            id: 'inv-1',
            itemId: 2,
            name: 'Grimoire',
            category: 'objet_magique',
            quantity: 1,
            equipped: true,
            totalWeight: 3,
          ),
        ],
      ),
    );

    expect(find.text('ÉQUIPÉ'), findsOneWidget);
    expect(find.text('3 kg'), findsNothing);
  });

  testWidgets(
    'un objet personnalisé (sans item_id) affiche son nom libre et le '
    'libellé "Objet personnalisé", sans poids (inconnu côté schéma)',
    (tester) async {
      await _pump(tester, _detail(inventory: const [_customItem]));

      expect(find.text('Petit sac de sable'), findsOneWidget);
      expect(find.text('Objet personnalisé · x1'), findsOneWidget);
    },
  );

  testWidgets('un objet personnalisé rend bien un badge en pointillés '
      '(CustomPaint/DashedBorderPainter), pas seulement le libellé "Objet '
      'personnalisé"', (tester) async {
    // Repère : sans objet personnalisé, seule la tuile "Ajouter un objet"
    // (en bas de liste) est peinte en pointillés.
    await _pump(tester, _detail());
    expect(_dashedBorderFinder(), findsOneWidget);

    await _pump(tester, _detail(inventory: const [_customItem]));

    // Un deuxième `CustomPaint`/`DashedBorderPainter` apparaît : le badge
    // de catégorie de l'objet personnalisé, en plus de la tuile
    // "Ajouter un objet".
    expect(_dashedBorderFinder(), findsNWidgets(2));
  });

  testWidgets(
    'un objet du catalogue dont items.weight est nul en base n\'affiche '
    'aucun texte de poids ("kg")',
    (tester) async {
      await _pump(
        tester,
        _detail(
          inventory: const [
            CharacterInventoryItem(
              id: 'inv-1',
              itemId: 3,
              name: 'Objet sans poids connu',
              category: 'equipement_general',
              quantity: 1,
              equipped: false,
              totalWeight: null,
            ),
          ],
        ),
      );

      expect(find.text('Objet sans poids connu'), findsOneWidget);
      expect(find.textContaining('kg'), findsNothing);
      expect(find.text('ÉQUIPÉ'), findsNothing);
    },
  );

  testWidgets('inventaire vide : état "INVENTAIRE VIDE", tuile "Ajouter un '
      'objet" et stat boxes restent visibles', (tester) async {
    await _pump(tester, _detail(currencyGp: 5));

    expect(find.text('INVENTAIRE VIDE'), findsOneWidget);
    expect(find.text('Ajouter un objet'), findsOneWidget);
    expect(find.text('PO'), findsOneWidget);
  });

  group('carte objet cliquable -> sheet d\'actions', () {
    testWidgets('un objet personnalisé n\'a que "Infos" et "Retirer"', (
      tester,
    ) async {
      await _pump(tester, _detail(inventory: const [_customItem]));

      await tester.tap(find.text('Petit sac de sable'));
      await tester.pumpAndSettle();

      expect(find.text('Infos'), findsOneWidget);
      expect(find.text('Utiliser'), findsNothing);
      expect(find.text('Équiper'), findsNothing);
      expect(find.text('Retirer'), findsOneWidget);
    });

    testWidgets('"Utiliser" (objet consommable) appelle onUseItem', (
      tester,
    ) async {
      final recorder = await _pump(tester, _detail(inventory: const [_potion]));

      await tester.tap(find.text('Potion de soins'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Utiliser'));
      await tester.pumpAndSettle();

      expect(recorder.useCalls, [_potion]);
    });

    testWidgets('"Équiper" (arme non équipée) appelle onToggleItemEquipped', (
      tester,
    ) async {
      final recorder = await _pump(tester, _detail(inventory: const [_dagger]));

      await tester.tap(find.text('Dague'));
      await tester.pumpAndSettle();
      expect(find.text('Équiper'), findsOneWidget);

      await tester.tap(find.text('Équiper'));
      await tester.pumpAndSettle();

      expect(recorder.toggleCalls, [_dagger]);
    });

    testWidgets(
      '"Retirer" ouvre une confirmation, "Retirer" du dialogue appelle '
      'onRemoveItem',
      (tester) async {
        final recorder = await _pump(
          tester,
          _detail(inventory: const [_dagger]),
        );

        await tester.tap(find.text('Dague'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Retirer'));
        await tester.pumpAndSettle();

        expect(find.text('Retirer Dague ?'), findsOneWidget);
        expect(recorder.removeCalls, isEmpty);

        await tester.tap(find.text('Retirer'));
        await tester.pumpAndSettle();

        expect(recorder.removeCalls, [_dagger]);
      },
    );

    testWidgets('actionsDisabled: le tap sur une carte n\'ouvre rien', (
      tester,
    ) async {
      await _pump(
        tester,
        _detail(inventory: const [_dagger]),
        actionsDisabled: true,
      );

      await tester.tap(find.text('Dague'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Infos'), findsNothing);
    });
  });

  group('stat box de monnaie cliquable -> sheet d\'ajustement', () {
    testWidgets('tap sur la box PO ouvre la sheet, "Appliquer" appelle '
        'onAdjustCurrency avec le nouveau montant absolu', (tester) async {
      final recorder = await _pump(tester, _detail(currencyGp: 10));

      await tester.tap(find.text('PO'));
      await tester.pumpAndSettle();

      expect(find.text("Ajuster les pièces d'or"), findsOneWidget);

      final incrementButton = find.byWidgetPredicate(
        (widget) => widget is Icon && widget.semanticLabel == 'Augmenter',
      );
      await tester.tap(incrementButton);
      await tester.tap(incrementButton);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PrimaryButton, 'APPLIQUER'));
      await tester.pumpAndSettle();

      expect(recorder.adjustCurrencyCalls, [(CurrencyKind.gold, 12)]);
    });

    testWidgets('actionsDisabled: le tap sur une stat box n\'ouvre rien', (
      tester,
    ) async {
      await _pump(tester, _detail(currencyGp: 10), actionsDisabled: true);

      await tester.tap(find.text('PO'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text("Ajuster les pièces d'or"), findsNothing);
    });
  });

  group('"+ Ajouter un objet" -> flux "Objet personnalisé"', () {
    testWidgets('ouvre la sheet à 2 choix, "Objet personnalisé" -> saisie -> '
        'onAddCustomInventoryItem', (tester) async {
      final recorder = await _pump(tester, _detail());

      await tester.tap(find.text('Ajouter un objet'));
      await tester.pumpAndSettle();

      expect(find.text('Depuis le catalogue'), findsOneWidget);
      expect(find.text('Objet personnalisé'), findsOneWidget);

      await tester.tap(find.text('Objet personnalisé'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'Amulette de famille');
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'AJOUTER'));
      await tester.pumpAndSettle();

      expect(recorder.addCustomItemCalls, [('Amulette de famille', 1)]);
    });

    testWidgets('actionsDisabled: le tap sur la tuile n\'ouvre rien', (
      tester,
    ) async {
      await _pump(tester, _detail(), actionsDisabled: true);

      await tester.tap(find.text('Ajouter un objet'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Depuis le catalogue'), findsNothing);
    });
  });
}
