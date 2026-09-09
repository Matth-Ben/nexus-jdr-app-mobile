// Tests de widget du "mini lancer de dé virtuel"
// (docs/cahier-des-charges/11-fonctionnalites-a-ajouter.md, section "Onglet
// Compétences").

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/presentation/widgets/dice_roll_sheet.dart';

Future<void> _open(
  WidgetTester tester, {
  required String label,
  required int modifier,
  Random? random,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDiceRollSheet(
              context,
              label: label,
              modifier: modifier,
              random: random,
            ),
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
}

/// Lit le résultat brut du d20 actuellement affiché (pastille de
/// [_DieFace]) — seul le total dans la ligne de détail dépend du
/// modificateur, ce nombre-ci est directement `_rollResult`.
int _currentDieValue(WidgetTester tester) {
  final texts = tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data)
      .whereType<String>();
  for (final text in texts) {
    final value = int.tryParse(text);
    if (value != null && value >= 1 && value <= 20) return value;
  }
  fail('Aucune valeur de dé (1-20) trouvée parmi les Text affichés.');
}

void main() {
  testWidgets('affiche le libellé en titre et un résultat entre 1 et 20', (
    tester,
  ) async {
    await _open(tester, label: 'Athlétisme', modifier: 3);

    expect(find.text('ATHLÉTISME'), findsOneWidget);
    expect(_currentDieValue(tester), inInclusiveRange(1, 20));
  });

  testWidgets(
    'affiche la ligne de détail "d20 (X) + modificateur = total" cohérente '
    'avec le résultat affiché (Random(1) fixe, résultat déterministe)',
    (tester) async {
      await _open(
        tester,
        label: 'Force',
        modifier: 3,
        random: Random(1),
      );

      final rolled = _currentDieValue(tester);
      final total = rolled + 3;

      expect(find.text('d20 ($rolled) +3 = $total'), findsOneWidget);
    },
  );

  testWidgets('modificateur négatif : signe moins Unicode dans le détail', (
    tester,
  ) async {
    await _open(tester, label: 'Force', modifier: -2, random: Random(7));

    final rolled = _currentDieValue(tester);
    final total = rolled - 2;

    expect(find.text('d20 ($rolled) −2 = $total'), findsOneWidget);
  });

  testWidgets(
    '20 naturel : bandeau "RÉUSSITE CRITIQUE" affiché',
    (tester) async {
      // Recherche d'une seed dont le premier tirage est 20 (Random.nextInt(20)
      // renvoie 19, formule DiceRoller +1) — évite de dépendre d'un tirage
      // non déterministe pour ce cas précis.
      var seed = 0;
      while (Random(seed).nextInt(20) + 1 != 20) {
        seed++;
      }

      await _open(tester, label: 'Force', modifier: 0, random: Random(seed));

      expect(_currentDieValue(tester), 20);
      expect(find.text('RÉUSSITE CRITIQUE'), findsOneWidget);
      expect(find.text('ÉCHEC CRITIQUE'), findsNothing);
    },
  );

  testWidgets('1 naturel : bandeau "ÉCHEC CRITIQUE" affiché', (tester) async {
    var seed = 0;
    while (Random(seed).nextInt(20) + 1 != 1) {
      seed++;
    }

    await _open(tester, label: 'Force', modifier: 0, random: Random(seed));

    expect(_currentDieValue(tester), 1);
    expect(find.text('ÉCHEC CRITIQUE'), findsOneWidget);
    expect(find.text('RÉUSSITE CRITIQUE'), findsNothing);
  });

  testWidgets(
    'résultat intermédiaire (ni 1 ni 20) : aucun bandeau critique affiché',
    (tester) async {
      var seed = 0;
      while (true) {
        final rolled = Random(seed).nextInt(20) + 1;
        if (rolled != 1 && rolled != 20) break;
        seed++;
      }

      await _open(tester, label: 'Force', modifier: 0, random: Random(seed));

      expect(find.text('RÉUSSITE CRITIQUE'), findsNothing);
      expect(find.text('ÉCHEC CRITIQUE'), findsNothing);
    },
  );

  testWidgets(
    '"Relancer" tire un nouveau résultat sans fermer la sheet',
    (tester) async {
      await _open(tester, label: 'Athlétisme', modifier: 3);
      expect(find.text('ATHLÉTISME'), findsOneWidget);

      // Sur un grand nombre de relances, au moins une doit différer du
      // résultat initial (Random() non déterministe) — vérifie que
      // "Relancer" tire vraiment un nouveau nombre plutôt que de rester figé,
      // sans dépendre d'une seed précise (probabilité de rester bloqué sur
      // la même valeur 30 fois de suite : (1/20)^29, négligeable).
      final initial = _currentDieValue(tester);
      var changed = false;
      for (var i = 0; i < 30; i++) {
        await tester.tap(find.text('RELANCER'));
        await tester.pumpAndSettle();
        if (_currentDieValue(tester) != initial) {
          changed = true;
          break;
        }
      }

      expect(changed, isTrue);
      // La sheet reste ouverte tout du long.
      expect(find.text('ATHLÉTISME'), findsOneWidget);
      expect(find.text('RELANCER'), findsOneWidget);
    },
  );

  testWidgets('bouton fermer (X) de la barre de tête ferme la sheet', (
    tester,
  ) async {
    await _open(tester, label: 'Athlétisme', modifier: 3);
    expect(find.text('ATHLÉTISME'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('ATHLÉTISME'), findsNothing);
  });
}
