// Écran Combat : états, rôles, hors ligne, défilement, annonces. Spec :
// `docs/combat-groupe-ui.md`.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/combat/domain/combat_enums.dart';
import 'package:personnages/features/combat/domain/combat_failure.dart';
import 'package:personnages/features/combat/presentation/providers/combat_providers.dart';
import 'package:personnages/features/combat/presentation/widgets/initiative_row.dart';

import '../../../support/combat_fixtures.dart';
import 'combat_test_harness.dart';

void main() {
  setUpAll(loadCombatFonts);

  final roster = [
    fakeParticipant(
      'aria',
      name: 'Aria',
      initiative: 18,
      sortOrder: 1,
      characterId: 'c-player',
    ).copyWith(userId: playerId),
    fakeParticipant(
      'gob1',
      name: 'Gobelin 1',
      initiative: 12,
      sortOrder: 2,
      kind: ParticipantKind.npc,
    ),
    fakeParticipant(
      'gob2',
      name: 'Gobelin 2',
      initiative: 12,
      sortOrder: 3,
      kind: ParticipantKind.npc,
    ),
    fakeParticipant('brun', name: 'Brun', sortOrder: 4, characterId: 'c-brun'),
  ];

  group('états', () {
    testWidgets('chargement : indicateur avec libellé sémantique', (
      tester,
    ) async {
      final h = CombatHarness();
      h.repo.snapshot = fakeSnapshot(participants: roster);
      h.repo.fetchGate = Completer<void>();
      await h.pumpScreen(tester, settle: false);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Chargement du combat'), findsOneWidget);
      h.repo.fetchGate!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('erreur : message et Réessayer relance le chargement', (
      tester,
    ) async {
      final h = CombatHarness();
      h.repo.fetchFailure = const CombatFailure.network();
      await h.pumpScreen(tester);
      expect(find.text('Impossible de charger le combat.'), findsOneWidget);
      h.repo
        ..fetchFailure = null
        ..snapshot = fakeSnapshot(participants: roster);
      await tester.tap(find.text('RÉESSAYER'));
      await tester.pumpAndSettle();
      expect(find.text('Round 1'), findsOneWidget);
    });

    testWidgets('actif : en-tête, lignes triées, attente d\'initiatives', (
      tester,
    ) async {
      final h = CombatHarness();
      h.repo.snapshot = fakeSnapshot(participants: roster);
      await h.pumpScreen(tester);
      expect(find.text('Round 1'), findsOneWidget);
      expect(find.text('Aucun tour actif · initiatives 3/4'), findsOneWidget);
      final names = tester
          .widgetList<InitiativeRow>(find.byType(InitiativeRow))
          .map((row) => row.participant.id)
          .toList();
      expect(names, ['aria', 'gob1', 'gob2', 'brun']);
      expect(find.text('Initiative à saisir'), findsOneWidget);
    });

    testWidgets('l\'ordre affiché suit sortedForDisplay, pas l\'ordre reçu', (
      tester,
    ) async {
      final h = CombatHarness();
      final received = combatRoster().reversed.toList();
      expect(received.first.id, 'brun');
      h.repo.snapshot = fakeSnapshot(participants: received);
      await h.pumpScreen(tester);
      final rows = tester
          .widgetList<InitiativeRow>(find.byType(InitiativeRow))
          .toList();
      // Initiative décroissante, égalité par `sort_order`, sans initiative
      // en dernier.
      expect(rows.map((row) => row.participant.id), [
        'aria',
        'gob1',
        'gob2',
        'brun',
      ]);
      expect(rows.map((row) => row.rank), [1, 2, 3, null]);
    });

    testWidgets('tour en cours : en-tête et ligne marquée', (tester) async {
      final h = CombatHarness();
      h.repo.snapshot = fakeSnapshot(
        combat: fakeCombat(round: 2, currentParticipantId: 'gob1'),
        participants: roster,
      );
      await h.pumpScreen(tester);
      expect(find.text('Round 2'), findsOneWidget);
      expect(find.text('Tour de Gobelin 1'), findsOneWidget);
      expect(find.text('Tour en cours'), findsOneWidget);
    });

    testWidgets('vide MJ', (tester) async {
      final mj = CombatHarness();
      mj.repo.snapshot = fakeSnapshot();
      await mj.pumpScreen(tester);
      expect(find.text('Le combat est lancé'), findsOneWidget);
      expect(
        find.text('Ajoute des monstres et attends les initiatives.'),
        findsOneWidget,
      );
    });

    testWidgets('vide joueur', (tester) async {
      final joueur = CombatHarness(detail: fakeGroupDetail(asPlayer: true));
      joueur.repo.snapshot = fakeSnapshot();
      await joueur.pumpScreen(tester);
      expect(find.text('Le MJ prépare le combat.'), findsOneWidget);
      expect(find.text('Ajouter un monstre'), findsNothing);
    });

    testWidgets('aucun combat actif : message et retour au groupe', (
      tester,
    ) async {
      final h = CombatHarness();
      await h.pumpScreen(tester);
      expect(find.text('Aucun combat actif.'), findsOneWidget);
      await tester.tap(find.text('RETOUR AU GROUPE'));
      await tester.pumpAndSettle();
      expect(find.text('ouvrir'), findsOneWidget);
    });

    testWidgets('combat terminé : résumé et retour au groupe', (tester) async {
      final h = CombatHarness();
      h.repo.snapshot = fakeSnapshot(
        combat: fakeCombat(round: 3),
        participants: roster,
      );
      await h.pumpScreen(tester);
      h.repo.snapshot = null;
      await h.container.read(combatProvider(groupId).notifier).refresh();
      await tester.pumpAndSettle();
      expect(
        find.text('Combat terminé · 3 rounds · 4 participants'),
        findsOneWidget,
      );
      expect(find.text('RETOUR AU GROUPE'), findsOneWidget);
    });
  });

  group('rôles', () {
    testWidgets('MJ : kebab, menus de ligne et pied « Ajouter un monstre »', (
      tester,
    ) async {
      final h = CombatHarness();
      h.repo.snapshot = fakeSnapshot(participants: roster);
      await h.pumpScreen(tester);
      expect(find.byKey(const Key('combatHeaderMenu')), findsOneWidget);
      expect(find.byKey(const Key('combatRowMenu-gob1')), findsOneWidget);
      expect(find.text('AJOUTER UN MONSTRE'), findsOneWidget);
      expect(find.text('Renseigner'), findsOneWidget);
    });

    testWidgets('joueur : aucun contrôle MJ, ligne « Toi » visible', (
      tester,
    ) async {
      final h = CombatHarness(detail: fakeGroupDetail(asPlayer: true));
      h.repo.snapshot = fakeSnapshot(participants: roster);
      await h.pumpScreen(tester);
      expect(find.byKey(const Key('combatHeaderMenu')), findsNothing);
      expect(find.byType(PopupMenuButton), findsNothing);
      expect(find.byKey(const Key('combatRowMenu-gob1')), findsNothing);
      expect(find.text('AJOUTER UN MONSTRE'), findsNothing);
      expect(find.text('Renseigner'), findsNothing);
      expect(find.text('Toi'), findsOneWidget);
      // L'état « Initiative à saisir » reste lisible pour tous.
      expect(find.text('Initiative à saisir'), findsOneWidget);
    });

    testWidgets('retirés : section visible au MJ seulement', (tester) async {
      final withRemoved = [
        ...roster,
        fakeParticipant(
          'gone',
          name: 'Parti',
          initiative: 3,
          sortOrder: 9,
          kind: ParticipantKind.npc,
          status: ParticipantStatus.removed,
        ),
      ];
      final mj = CombatHarness();
      mj.repo.snapshot = fakeSnapshot(participants: withRemoved);
      await mj.pumpScreen(tester);
      expect(find.text('Retirés (1)'), findsOneWidget);
      expect(find.text('Parti'), findsNothing);
      await tester.tap(find.byKey(const Key('combatRemovedToggle')));
      await tester.pumpAndSettle();
      expect(find.text('Parti'), findsOneWidget);
      expect(find.text('Retiré'), findsOneWidget);
      expect(find.byKey(const Key('combatRowMenu-gone')), findsNothing);
    });

    testWidgets('retirés : jamais visibles pour un joueur', (tester) async {
      final withRemoved = [
        ...roster,
        fakeParticipant(
          'gone',
          name: 'Parti',
          initiative: 3,
          sortOrder: 9,
          kind: ParticipantKind.npc,
          status: ParticipantStatus.removed,
        ),
      ];
      final joueur = CombatHarness(detail: fakeGroupDetail(asPlayer: true));
      joueur.repo.snapshot = fakeSnapshot(participants: withRemoved);
      await joueur.pumpScreen(tester);
      expect(find.textContaining('Retirés'), findsNothing);
      expect(find.text('Parti'), findsNothing);
    });

    testWidgets('joueur retiré : message clair', (tester) async {
      final h = CombatHarness(detail: fakeGroupDetail(asPlayer: true));
      h.repo.snapshot = fakeSnapshot(
        participants: [
          fakeParticipant(
            'aria',
            name: 'Aria',
            initiative: 5,
            status: ParticipantStatus.removed,
          ).copyWith(userId: playerId),
        ],
      );
      await h.pumpScreen(tester);
      expect(
        find.text(
          "Le MJ t'a retiré de ce combat. Tu ne peux pas le rejoindre à nouveau.",
        ),
        findsOneWidget,
      );
    });
  });

  group('hors ligne et MJ absent', () {
    testWidgets('hors ligne : lecture seule, actions désactivées avec hint', (
      tester,
    ) async {
      final h = CombatHarness();
      h.repo.snapshot = fakeSnapshot(participants: roster);
      await h.pumpScreen(tester);
      h.connectivity.goOffline();
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Hors ligne · dernier état connu à'),
        findsOneWidget,
      );
      final add = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(add.onPressed, isNull);
      final kebab = tester.widget<IconButton>(
        find.byKey(const Key('combatHeaderMenu')),
      );
      expect(kebab.onPressed, isNull);
      final rowKebab = tester.widget<IconButton>(
        find.byKey(const Key('combatRowMenu-gob1')),
      );
      expect(rowKebab.onPressed, isNull);
      expect(find.byTooltip('Indisponible hors ligne'), findsWidgets);
      expect(h.repo.calls, isEmpty);
    });

    testWidgets('échec de refetch : état périmé = lecture seule', (
      tester,
    ) async {
      final h = CombatHarness();
      h.repo.snapshot = fakeSnapshot(participants: roster);
      await h.pumpScreen(tester);
      h.repo.fetchFailure = const CombatFailure.network();
      await h.emitChange(tester);
      expect(
        find.textContaining('Hors ligne · dernier état connu à'),
        findsOneWidget,
      );
      // Les lignes restent affichées (dernier état connu).
      expect(find.text('Aria'), findsOneWidget);
    });

    testWidgets('retour du réseau : refetch complet, lecture seule levée', (
      tester,
    ) async {
      final h = CombatHarness();
      h.repo.snapshot = fakeSnapshot(participants: roster);
      await h.pumpScreen(tester);
      h.repo.fetchFailure = const CombatFailure.network();
      h.connectivity.goOffline();
      await h.emitChange(tester);
      final before = h.repo.fetchCount;
      h.repo.fetchFailure = null;
      h.connectivity.goOnline();
      await tester.pumpAndSettle();
      expect(h.repo.fetchCount, greaterThan(before));
      expect(find.textContaining('Hors ligne'), findsNothing);
    });

    testWidgets('MJ absent : état lisible, terminer reste possible', (
      tester,
    ) async {
      final h = CombatHarness(detail: fakeGroupDetail(masterAbsent: true));
      h.repo.snapshot = fakeSnapshot(participants: roster);
      await h.pumpScreen(tester);
      expect(
        find.text('En attente du MJ. Seul le MJ peut terminer le combat.'),
        findsOneWidget,
      );
      final add = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(add.onPressed, isNull);
      final kebab = tester.widget<IconButton>(
        find.byKey(const Key('combatHeaderMenu')),
      );
      expect(kebab.onPressed, isNotNull);
    });
  });
}
