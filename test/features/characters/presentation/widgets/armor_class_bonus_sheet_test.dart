// Tests de widget de la sheet "Ajustement de CA" (bonus/malus manuel de
// Classe d'Armure, voir la doc de classe de
// `CharacterDetail.armorClassBonus`).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/presentation/widgets/armor_class_bonus_sheet.dart';

Future<int?> _open(WidgetTester tester, {required int currentBonus}) async {
  int? applied;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showArmorClassBonusSheet(
              context,
              currentBonus: currentBonus,
              onApply: (value) => applied = value,
            ),
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
  // Retourne un getter différé : la valeur n'est connue qu'après interaction
  // avec la sheet, voir les appels `applied` dans chaque test.
  return applied;
}

void main() {
  testWidgets('titre "Ajustement de CA" et bascule Bonus/Malus affichées', (
    tester,
  ) async {
    await _open(tester, currentBonus: 0);

    expect(find.text('Ajustement de CA'), findsOneWidget);
    expect(find.text('BONUS'), findsOneWidget);
    expect(find.text('MALUS'), findsOneWidget);
  });

  testWidgets(
    'currentBonus == 0 : toggle pré-rempli sur "Bonus", magnitude à 0',
    (tester) async {
      await _open(tester, currentBonus: 0);

      expect(find.text('0'), findsOneWidget);
    },
  );

  testWidgets('currentBonus positif : toggle pré-rempli sur "Bonus", magnitude '
      'affichée', (tester) async {
    await _open(tester, currentBonus: 2);

    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('currentBonus négatif : toggle pré-rempli sur "Malus", magnitude '
      'affichée en valeur positive', (tester) async {
    await _open(tester, currentBonus: -3);

    // La magnitude affichée par le StepperCounter est toujours positive,
    // jamais "-3" brut.
    expect(find.text('3'), findsOneWidget);
    expect(find.text('-3'), findsNothing);
  });

  testWidgets('"Effacer" appelle onApply(0) et ferme la sheet', (tester) async {
    int? applied;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showArmorClassBonusSheet(
                context,
                currentBonus: 2,
                onApply: (value) => applied = value,
              ),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('EFFACER'));
    await tester.pumpAndSettle();

    expect(applied, 0);
    expect(find.text('Ajustement de CA'), findsNothing);
  });

  testWidgets(
    '"Valider" sur le segment "Bonus" après avoir augmenté la magnitude '
    'appelle onApply avec une valeur positive',
    (tester) async {
      int? applied;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showArmorClassBonusSheet(
                  context,
                  currentBonus: 0,
                  onApply: (value) => applied = value,
                ),
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      // Deux taps sur "+" du StepperCounter -> magnitude 2.
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.tap(find.text('VALIDER'));
      await tester.pumpAndSettle();

      expect(applied, 2);
    },
  );

  testWidgets(
    '"Valider" après avoir basculé sur "Malus" et augmenté la magnitude '
    'appelle onApply avec une valeur négative',
    (tester) async {
      int? applied;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showArmorClassBonusSheet(
                  context,
                  currentBonus: 0,
                  onApply: (value) => applied = value,
                ),
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('MALUS'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.tap(find.text('VALIDER'));
      await tester.pumpAndSettle();

      expect(applied, -1);
    },
  );

  testWidgets(
    'currentBonus négatif pré-rempli : "Valider" sans y toucher réaffirme '
    'la même valeur négative',
    (tester) async {
      int? applied;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showArmorClassBonusSheet(
                  context,
                  currentBonus: -2,
                  onApply: (value) => applied = value,
                ),
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('VALIDER'));
      await tester.pumpAndSettle();

      expect(applied, -2);
    },
  );

  testWidgets(
    '"Valider" avec une magnitude nulle est accepté (0 est une valeur '
    'valide, pas de bouton désactivé)',
    (tester) async {
      int? applied;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showArmorClassBonusSheet(
                  context,
                  currentBonus: 0,
                  onApply: (value) => applied = value,
                ),
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('VALIDER'));
      await tester.pumpAndSettle();

      expect(applied, 0);
    },
  );
}
