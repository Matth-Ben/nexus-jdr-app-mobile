// Tests de widget de la feuille "Ajouter de l'XP"
// (`presentation/widgets/add_xp_sheet.dart`) — même patron que
// `hp_adjustment_sheet_test.dart` (feuille dans un `MaterialApp` minimal,
// aucun dépôt à injecter : `onApply` est un simple callback synchrone).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/characters/presentation/widgets/add_xp_sheet.dart';

void main() {
  Future<void> pumpSheet(
    WidgetTester tester, {
    required int currentXp,
    required int? nextLevelXpThreshold,
    required ValueChanged<int> onApply,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showAddXpSheet(
                  context,
                  currentXp: currentXp,
                  nextLevelXpThreshold: nextLevelXpThreshold,
                  onApply: onApply,
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

  testWidgets(
    'affiche l\'XP actuelle/seuil, "Ajouter" désactivé tant qu\'aucun '
    'montant valide n\'est saisi',
    (tester) async {
      await pumpSheet(
        tester,
        currentXp: 900,
        nextLevelXpThreshold: 2700,
        onApply: (_) {},
      );

      expect(find.text("Ajouter de l'XP"), findsOneWidget);
      expect(find.text('XP actuelle : 900 / 2700'), findsOneWidget);
      expect(find.text('XP GAGNÉE'), findsOneWidget);
      expect(
        find.text('Montant remis par le MJ en fin de séance, par exemple.'),
        findsOneWidget,
      );
      expect(find.textContaining('Nouveau total'), findsNothing);

      final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(button.onPressed, isNull);
    },
  );

  testWidgets('saisir un montant affiche l\'aperçu "Nouveau total" et active '
      '"Ajouter" ; le tap ferme la feuille et transmet le montant tel quel', (
    tester,
  ) async {
    int? applied;
    await pumpSheet(
      tester,
      currentXp: 900,
      nextLevelXpThreshold: 2700,
      onApply: (amount) => applied = amount,
    );

    await tester.enterText(find.byType(TextFormField), '250');
    await tester.pumpAndSettle();

    expect(find.text('Nouveau total : 1150 XP'), findsOneWidget);
    final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
    expect(button.onPressed, isNotNull);

    await tester.tap(find.text('AJOUTER'));
    await tester.pumpAndSettle();

    expect(applied, 250);
    expect(find.text("Ajouter de l'XP"), findsNothing);
  });

  testWidgets('le champ ne filtre que les chiffres (FilteringTextInputFormatter'
      '.digitsOnly) : une saisie non numérique est ignorée', (tester) async {
    await pumpSheet(
      tester,
      currentXp: 0,
      nextLevelXpThreshold: 300,
      onApply: (_) {},
    );

    await tester.enterText(find.byType(TextFormField), 'abc12def3');
    await tester.pumpAndSettle();

    expect(find.text('Nouveau total : 123 XP'), findsOneWidget);
  });

  testWidgets('"Annuler" ferme la feuille sans appeler onApply', (
    tester,
  ) async {
    var applyCallCount = 0;
    await pumpSheet(
      tester,
      currentXp: 0,
      nextLevelXpThreshold: 300,
      onApply: (_) => applyCallCount++,
    );

    await tester.enterText(find.byType(TextFormField), '100');
    await tester.pumpAndSettle();

    await tester.tap(find.text('ANNULER'));
    await tester.pumpAndSettle();

    expect(applyCallCount, 0);
    expect(find.text("Ajouter de l'XP"), findsNothing);
  });

  testWidgets(
    'au niveau maximum (nextLevelXpThreshold nul), le seuil affiché retombe '
    'sur l\'XP actuelle',
    (tester) async {
      await pumpSheet(
        tester,
        currentXp: 355000,
        nextLevelXpThreshold: null,
        onApply: (_) {},
      );

      expect(find.text('XP actuelle : 355000 / 355000'), findsOneWidget);
    },
  );
}
