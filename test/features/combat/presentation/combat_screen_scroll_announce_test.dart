// Écran Combat : défilement (jamais automatique sur évènement) et annonces
// sémantiques (jamais au chargement).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/combat/domain/combat_participant.dart';

import '../../../support/combat_fixtures.dart';
import 'combat_test_harness.dart';

void main() {
  setUpAll(loadCombatFonts);

  List<CombatParticipant> many() => [
    for (var i = 0; i < 30; i++)
      fakeParticipant(
        'p$i',
        name: 'Participant $i',
        initiative: 40 - i,
        sortOrder: i,
      ),
  ];

  double offset(WidgetTester tester) => tester
      .state<ScrollableState>(
        find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      )
      .position
      .pixels;

  group('défilement', () {
    testWidgets('un seul défilement initial vers le tour actif', (
      tester,
    ) async {
      final h = CombatHarness();
      h.repo.snapshot = fakeSnapshot(
        combat: fakeCombat(currentParticipantId: 'p25'),
        participants: many(),
      );
      await h.pumpScreen(tester);
      expect(offset(tester), greaterThan(0));
    });

    testWidgets('aucun saut de défilement à la réception d\'un évènement', (
      tester,
    ) async {
      final h = CombatHarness();
      h.repo.snapshot = fakeSnapshot(
        combat: fakeCombat(currentParticipantId: 'p25'),
        participants: many(),
      );
      await h.pumpScreen(tester);
      // L'utilisateur relit le haut de la liste.
      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pumpAndSettle();
      final before = offset(tester);

      // Évènement reçu : le tour passe ailleurs, le round avance et une
      // initiative change.
      h.repo.snapshot = fakeSnapshot(
        combat: fakeCombat(round: 2, currentParticipantId: 'p3'),
        participants: [
          for (final p in many()) p.id == 'p1' ? p.copyWith(initiative: 39) : p,
        ],
      );
      await h.emitChange(tester);
      expect(find.text('Round 2'), findsOneWidget);
      expect(offset(tester), before);

      // Un second évènement ne déplace pas non plus la liste.
      h.repo.snapshot = fakeSnapshot(
        combat: fakeCombat(round: 3, currentParticipantId: 'p27'),
        participants: many(),
      );
      await h.emitChange(tester);
      expect(offset(tester), before);
    });

    testWidgets('une bannière qui apparaît au-dessus de la liste ne change '
        'pas l\'offset de défilement', (tester) async {
      final h = CombatHarness();
      h.repo.snapshot = fakeSnapshot(
        combat: fakeCombat(currentParticipantId: 'p25'),
        participants: many(),
      );
      await h.pumpScreen(tester);
      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pumpAndSettle();
      final before = offset(tester);
      expect(before, greaterThan(0));
      expect(find.textContaining('Hors ligne'), findsNothing);

      // Hors ligne : une bannière s'insère au-dessus de la liste.
      h.connectivity.goOffline();
      await tester.pumpAndSettle();
      expect(find.textContaining('Hors ligne'), findsOneWidget);
      expect(offset(tester), before);

      // Retour en ligne : la bannière disparaît, l'offset reste.
      h.connectivity.goOnline();
      await tester.pumpAndSettle();
      expect(find.textContaining('Hors ligne'), findsNothing);
      expect(offset(tester), before);
    });

    testWidgets('« Voir le tour en cours » : seul son appui fait défiler', (
      tester,
    ) async {
      final h = CombatHarness();
      h.repo.snapshot = fakeSnapshot(
        combat: fakeCombat(currentParticipantId: 'p25'),
        participants: many(),
      );
      await h.pumpScreen(tester);
      expect(find.text('Voir le tour en cours'), findsNothing);
      await tester.drag(find.byType(ListView), const Offset(0, 5000));
      await tester.pumpAndSettle();
      expect(offset(tester), 0);
      expect(find.text('Voir le tour en cours'), findsOneWidget);
      await tester.tap(find.text('Voir le tour en cours'));
      await tester.pumpAndSettle();
      expect(offset(tester), greaterThan(0));
      expect(find.text('Voir le tour en cours'), findsNothing);
    });
  });

  group('annonces sémantiques', () {
    testWidgets('jamais au chargement, même avec un tour actif', (
      tester,
    ) async {
      final h = CombatHarness();
      h.repo.snapshot = fakeSnapshot(
        combat: fakeCombat(currentParticipantId: 'gob1'),
        participants: combatRoster(),
      );
      await h.pumpScreen(tester);
      await tester.pump(const Duration(seconds: 2));
      expect(h.announcements, isEmpty);
    });

    testWidgets('changement de tour reçu : annonce polie unique', (
      tester,
    ) async {
      final h = CombatHarness();
      h.repo.snapshot = fakeSnapshot(
        combat: fakeCombat(currentParticipantId: 'aria'),
        participants: combatRoster(),
      );
      await h.pumpScreen(tester);
      h.repo.snapshot = fakeSnapshot(
        combat: fakeCombat(round: 2, currentParticipantId: 'gob1'),
        participants: combatRoster(),
      );
      await h.emitChange(tester);
      expect(h.announcements, ['Round 2. Tour de Gobelin 1.']);
    });

    testWidgets('à soi : « C\'est ton tour. »', (tester) async {
      final h = CombatHarness(detail: fakeGroupDetail(asPlayer: true));
      h.repo.snapshot = fakeSnapshot(
        combat: fakeCombat(currentParticipantId: 'gob1'),
        participants: combatRoster(),
      );
      await h.pumpScreen(tester);
      h.repo.snapshot = fakeSnapshot(
        combat: fakeCombat(currentParticipantId: 'aria'),
        participants: combatRoster(),
      );
      await h.emitChange(tester);
      expect(h.announcements, ['C\'est ton tour.']);
    });

    testWidgets('changements rapprochés : fusionnés, un par seconde', (
      tester,
    ) async {
      final h = CombatHarness();
      h.repo.snapshot = fakeSnapshot(
        combat: fakeCombat(currentParticipantId: 'aria'),
        participants: combatRoster(),
      );
      await h.pumpScreen(tester);
      for (final id in ['gob1', 'gob2', 'brun']) {
        h.repo.snapshot = fakeSnapshot(
          combat: fakeCombat(currentParticipantId: id),
          participants: combatRoster(),
        );
        await h.emitChange(tester);
      }
      expect(h.announcements, ['Round 1. Tour de Gobelin 1.']);
      await tester.pump(const Duration(seconds: 2));
      expect(h.announcements, [
        'Round 1. Tour de Gobelin 1.',
        'Round 1. Tour de Brun.',
      ]);
    });

    testWidgets('une initiative modifiée ne déclenche aucune annonce', (
      tester,
    ) async {
      final h = CombatHarness();
      h.repo.snapshot = fakeSnapshot(
        combat: fakeCombat(currentParticipantId: 'aria'),
        participants: combatRoster(),
      );
      await h.pumpScreen(tester);
      final changed = combatRoster();
      h.repo.snapshot = fakeSnapshot(
        combat: fakeCombat(currentParticipantId: 'aria'),
        participants: [
          changed[0],
          changed[1].copyWith(initiative: 15),
          ...changed.skip(2),
        ],
      );
      await h.emitChange(tester);
      await tester.pump(const Duration(seconds: 2));
      expect(h.announcements, isEmpty);
    });

    testWidgets('fin du combat : une annonce', (tester) async {
      final h = CombatHarness();
      h.repo.snapshot = fakeSnapshot(participants: combatRoster());
      await h.pumpScreen(tester);
      h.repo.snapshot = null;
      await h.emitChange(tester);
      expect(h.announcements, ['Le combat est terminé.']);
    });
  });
}
