// Écran Combat : contrôles du MJ (terminer, retirer, éditer, ajouter,
// réordonner) et leurs confirmations.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/destructive_button.dart';
import 'package:personnages/features/combat/domain/combat_failure.dart';

import '../../../support/combat_fixtures.dart';
import 'combat_test_harness.dart';

void main() {
  setUpAll(loadCombatFonts);

  Future<CombatHarness> open(WidgetTester tester) async {
    final h = CombatHarness();
    h.repo.snapshot = fakeSnapshot(participants: combatRoster());
    await h.pumpScreen(tester);
    return h;
  }

  Future<void> openHeaderMenu(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('combatHeaderMenu')));
    await tester.pumpAndSettle();
  }

  testWidgets('terminer : confirmation, focus sur Annuler, puis appel', (
    tester,
  ) async {
    final h = await open(tester);
    await openHeaderMenu(tester);
    await tester.tap(find.text('Terminer le combat'));
    await tester.pumpAndSettle();
    expect(find.text('Terminer le combat ?'), findsOneWidget);
    expect(
      find.text(
        'Le combat disparaît pour tous les joueurs. Round atteint : 1.',
      ),
      findsOneWidget,
    );
    final focused = FocusManager.instance.primaryFocus!.context!;
    expect(
      find.descendant(
        of: find.byElementPredicate((element) => element == focused),
        matching: find.text('ANNULER'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('ANNULER'));
    await tester.pumpAndSettle();
    expect(h.repo.calls, isEmpty);

    await openHeaderMenu(tester);
    await tester.tap(find.text('Terminer le combat'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DestructiveButton));
    await tester.pumpAndSettle();
    expect(h.repo.calls, ['end:combat-1']);
  });

  testWidgets('retirer : confirmation nominative puis appel', (tester) async {
    final h = await open(tester);
    await tester.tap(find.byKey(const Key('combatRowMenu-gob1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retirer du combat'));
    await tester.pumpAndSettle();
    expect(find.text('Retirer Gobelin 1 du combat ?'), findsOneWidget);
    await tester.tap(find.text('ANNULER'));
    await tester.pumpAndSettle();
    expect(h.repo.calls, isEmpty);

    await tester.tap(find.byKey(const Key('combatRowMenu-gob1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retirer du combat'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DestructiveButton));
    await tester.pumpAndSettle();
    expect(h.repo.calls, ['remove:gob1']);
  });

  testWidgets('éditer l\'initiative : feuille puis appel', (tester) async {
    final h = await open(tester);
    await tester.tap(find.byKey(const Key('combatRowMenu-gob1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Éditer l\'initiative'));
    await tester.pumpAndSettle();
    expect(find.text('Initiative de Gobelin 1'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('combatInitiativeField')),
      '15',
    );
    await tester.pump();
    await tester.tap(find.text('ENREGISTRER'));
    await tester.pumpAndSettle();
    expect(h.repo.calls, ['set:gob1:15']);
  });

  testWidgets('« Renseigner » ouvre la feuille d\'initiative', (tester) async {
    final h = await open(tester);
    await tester.tap(find.text('Renseigner'));
    await tester.pumpAndSettle();
    expect(find.text('Initiative de Brun'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('combatInitiativeField')),
      '-3',
    );
    await tester.pump();
    await tester.tap(find.text('ENREGISTRER'));
    await tester.pumpAndSettle();
    expect(h.repo.calls, ['set:brun:-3']);
  });

  testWidgets('ajouter un monstre ×N puis « Ajouter »', (tester) async {
    final h = await open(tester);
    await tester.tap(find.text('AJOUTER UN MONSTRE'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('combatMonsterName')), 'Orc');
    await tester.enterText(
      find.byKey(const Key('combatInitiativeField')),
      '14',
    );
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Augmenter la quantité'));
    await tester.pump();
    expect(find.text('Sera ajouté : Orc 1, Orc 2'), findsOneWidget);
    await tester.tap(find.text('AJOUTER'));
    await tester.pumpAndSettle();
    expect(h.repo.calls, ['add:combat-1:Orc:14:2']);
    expect(find.byKey(const Key('combatMonsterName')), findsNothing);
  });

  testWidgets('échec serveur : message localisé en snackbar', (tester) async {
    final h = await open(tester);
    h.repo.writeFailure = const CombatFailure(CombatFailureKind.notGroupOwner);
    await tester.tap(find.byKey(const Key('combatRowMenu-gob1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retirer du combat'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DestructiveButton));
    await tester.pumpAndSettle();
    expect(find.text('Seul le MJ peut faire cela.'), findsOneWidget);
  });

  testWidgets('réordonner : seulement vers un voisin de même initiative', (
    tester,
  ) async {
    final h = await open(tester);
    await openHeaderMenu(tester);
    await tester.tap(find.text('Réordonner les égalités'));
    await tester.pumpAndSettle();
    expect(find.text('Terminé'), findsOneWidget);

    IconButton arrow(String key) =>
        tester.widget<IconButton>(find.byKey(Key(key)));
    expect(arrow('combatMoveUp-gob1').onPressed, isNull);
    expect(arrow('combatMoveDown-gob1').onPressed, isNotNull);
    expect(arrow('combatMoveUp-gob2').onPressed, isNotNull);
    expect(arrow('combatMoveDown-gob2').onPressed, isNull);
    expect(arrow('combatMoveUp-aria').onPressed, isNull);
    expect(arrow('combatMoveDown-aria').onPressed, isNull);
    expect(find.byTooltip('Limite de l\'égalité'), findsWidgets);

    await tester.tap(find.byKey(const Key('combatMoveDown-gob1')));
    await tester.pumpAndSettle();
    expect(h.repo.calls, ['reorder:gob1:3']);

    await tester.tap(find.text('Terminé'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('combatMoveUp-gob1')), findsNothing);
  });

  testWidgets('réordonner absent du menu sans égalité', (tester) async {
    final h = CombatHarness();
    h.repo.snapshot = fakeSnapshot(
      participants: [
        fakeParticipant('a', name: 'A', initiative: 9),
        fakeParticipant('b', name: 'B', initiative: 7, sortOrder: 2),
      ],
    );
    await h.pumpScreen(tester);
    await openHeaderMenu(tester);
    expect(find.text('Réordonner les égalités'), findsNothing);
    expect(find.text('Terminer le combat'), findsOneWidget);
  });
}
