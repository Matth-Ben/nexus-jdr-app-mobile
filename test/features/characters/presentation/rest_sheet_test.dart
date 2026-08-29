// Tests de widget de la feuille "Repos"
// (`presentation/widgets/rest_sheet.dart`) — même patron que
// `add_xp_sheet_test.dart` (feuille dans un `MaterialApp` minimal, aucun
// dépôt à injecter : `onApply` est un simple callback synchrone).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/characters/domain/rest_type.dart';
import 'package:personnages/features/characters/presentation/widgets/rest_sheet.dart';

void main() {
  Future<void> pumpSheet(
    WidgetTester tester, {
    required int currentHp,
    required int maxHp,
    required ValueChanged<RestType> onApply,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showRestSheet(
                  context,
                  currentHp: currentHp,
                  maxHp: maxHp,
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
    'affiche le titre, les PV actuels, et "Repos long" sélectionné par '
    'défaut avec son bloc d\'aide (PV après repos inclus)',
    (tester) async {
      await pumpSheet(tester, currentHp: 12, maxHp: 30, onApply: (_) {});

      expect(find.text('Repos'), findsOneWidget);
      expect(find.text('PV actuels : 12 / 30'), findsOneWidget);
      expect(find.text('REPOS COURT'), findsOneWidget);
      expect(find.text('REPOS LONG'), findsOneWidget);

      expect(
        find.text(
          'Restaure les PV au maximum, réinitialise les emplacements de '
          'sorts et recharge toutes les aptitudes rechargeables (repos '
          'court comme repos long).',
        ),
        findsOneWidget,
      );
      expect(find.text('PV après repos : 30 / 30'), findsOneWidget);
      // Bloc d'aide "repos court" pas affiché tant que ce segment n'est pas
      // sélectionné.
      expect(find.textContaining('la dépense de dés de vie'), findsNothing);
    },
  );

  testWidgets(
    'basculer sur "Repos court" remplace le bloc d\'aide, sans "PV après '
    'repos"',
    (tester) async {
      await pumpSheet(tester, currentHp: 12, maxHp: 30, onApply: (_) {});

      await tester.tap(find.text('REPOS COURT'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Recharge les aptitudes rechargeables au repos court. Ne '
          "restaure pas de PV : la dépense de dés de vie n'est pas encore "
          'prise en charge par la fiche.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('PV après repos'), findsNothing);
      expect(find.textContaining('emplacements de sorts'), findsNothing);
    },
  );

  testWidgets(
    '"Appliquer" est toujours activé (aucune saisie à valider), ferme la '
    'feuille et transmet le type sélectionné',
    (tester) async {
      RestType? applied;
      await pumpSheet(
        tester,
        currentHp: 12,
        maxHp: 30,
        onApply: (type) => applied = type,
      );

      final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(button.onPressed, isNotNull);

      await tester.tap(find.text('REPOS COURT'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('APPLIQUER'));
      await tester.pumpAndSettle();

      expect(applied, RestType.short);
      expect(find.text('Repos'), findsNothing);
    },
  );

  testWidgets(
    '"Appliquer" sans changer de segment transmet RestType.long (valeur '
    'par défaut)',
    (tester) async {
      RestType? applied;
      await pumpSheet(
        tester,
        currentHp: 12,
        maxHp: 30,
        onApply: (type) => applied = type,
      );

      await tester.tap(find.text('APPLIQUER'));
      await tester.pumpAndSettle();

      expect(applied, RestType.long);
    },
  );

  testWidgets('"Annuler" ferme la feuille sans appeler onApply', (
    tester,
  ) async {
    var applyCallCount = 0;
    await pumpSheet(
      tester,
      currentHp: 12,
      maxHp: 30,
      onApply: (_) => applyCallCount++,
    );

    await tester.tap(find.text('ANNULER'));
    await tester.pumpAndSettle();

    expect(applyCallCount, 0);
    expect(find.text('Repos'), findsNothing);
  });
}
