// Tests de widget de l'onglet "Inventaire" de la fiche personnage — voir
// `docs/cahier-des-charges/09-maquettes-captures.md`, section "Onglet
// Inventaire".
//
// `CharacterInventoryTabBody` est un `StatelessWidget` pur (pas de
// Riverpod, pas de réseau) : même approche que
// `character_skills_tab_body_test.dart`, un simple `MaterialApp(home: ...)`
// suffit à le monter.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/dashed_border_painter.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_inventory_item.dart';
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

Future<void> _pump(WidgetTester tester, CharacterDetail detail) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: CharacterInventoryTabBody(detail: detail)),
    ),
  );
}

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
    await _pump(
      tester,
      _detail(
        inventory: const [
          CharacterInventoryItem(
            id: 'inv-1',
            itemId: 1,
            name: 'Dague',
            category: 'arme',
            quantity: 2,
            equipped: false,
            totalWeight: 1,
          ),
        ],
      ),
    );

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
      await _pump(
        tester,
        _detail(
          inventory: const [
            CharacterInventoryItem(
              id: 'inv-1',
              name: 'Petit sac de sable',
              quantity: 1,
              equipped: false,
            ),
          ],
        ),
      );

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

    await _pump(
      tester,
      _detail(
        inventory: const [
          CharacterInventoryItem(
            id: 'inv-1',
            name: 'Petit sac de sable',
            quantity: 1,
            equipped: false,
          ),
        ],
      ),
    );

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
              // items.weight nul en base -> CharacterInventoryRowMapper
              // résout totalWeight à null (voir
              // character_inventory_row_mapper_test.dart).
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

  testWidgets(
    'affiche la tuile "Ajouter un objet", dont le tap affiche un message '
    '"à venir" sans naviguer ni écrire',
    (tester) async {
      await _pump(tester, _detail());

      expect(find.text('Ajouter un objet'), findsOneWidget);

      await tester.tap(find.text('Ajouter un objet'));
      await tester.pump();

      expect(find.text('Bientôt disponible'), findsOneWidget);
    },
  );
}
