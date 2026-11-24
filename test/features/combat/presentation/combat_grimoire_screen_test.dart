// Écran Combat d'un combat mené depuis Grimoire (`docs/combat-grimoire-ui.md`) :
// préparation, initiative, ordre en lecture seule, « À toi de jouer », MJ hors
// ligne, expiration, aucun combat, fin, meneur, texte ×3,0 sur 320 dp.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/presentation/providers/character_detail_provider.dart';
import 'package:personnages/features/combat/domain/grimoire_combat_view.dart';
import 'package:personnages/features/combat/domain/grimoire_failure.dart';
import 'package:personnages/features/groups/domain/group_detail.dart';
import 'package:personnages/features/groups/domain/group_member.dart';
import 'package:personnages/features/groups/domain/group_role.dart';

import '../../../support/combat_fixtures.dart';
import '../../../support/grimoire_fixtures.dart';
import 'combat_test_harness.dart';

CharacterDetail _aria() => CharacterDetail(
  id: 'c-player',
  name: 'Aria',
  classes: const [],
  xp: 0,
  currentHp: 10,
  maxHp: 10,
  temporaryHp: 0,
  abilityScores: const {'dex': 14},
  inventory: const [],
  spells: const [],
  classChoices: const [],
);

/// Heure affichée d'un `sent_at` (« 21:04 », heure locale).
String _clock(String sentAt) =>
    DateFormat.Hm('fr').format(DateTime.parse(sentAt).toLocal());

/// Joueur Aria ; Brun (autre joueur) mort si [brunDead].
GroupDetail _detail({bool brunDead = false}) => GroupDetail(
  id: groupId,
  name: 'Les Braves',
  ownerId: ownerId,
  inviteCode: 'ABC123',
  currentUserId: playerId,
  members: [
    fakeMember(
      userId: ownerId,
      isGameMaster: true,
      name: 'MJ',
      role: GroupRole.owner,
    ),
    fakeMember(userId: playerId, characterId: 'c-player', name: 'Aria'),
    GroupMember(
      userId: 'player-2',
      characterId: 'c-brun',
      role: GroupRole.membre,
      name: 'Brun',
      isGameMaster: false,
      isDead: brunDead,
    ),
  ],
);

void main() {
  setUpAll(loadCombatFonts);

  List<Override> dex() => [
    characterDetailProvider('c-player').overrideWith((ref) async => _aria()),
  ];

  Future<CombatHarness> open(
    WidgetTester tester, {
    GroupDetail? detail,
    double scale = 1,
    bool leader = false,
  }) async {
    final h = CombatHarness(detail: detail ?? _detail(), extraOverrides: dex())
      ..scale = scale;
    if (leader) {
      h.grimoire.topics = (
        epoch: 1,
        gmTopic: 'grimoire:v1:group:group-1:e1:gm',
        isLeader: true,
      );
    }
    await h.pumpScreen(tester);
    return h;
  }

  Future<void> emit(
    WidgetTester tester,
    CombatHarness h,
    List<Map<String, dynamic>> messages,
  ) async {
    for (final message in messages) {
      h.grimoire.lastLink.emit(message);
    }
    await tester.pumpAndSettle();
  }

  /// Avance l'horloge injectée et les minuteries simulées.
  Future<void> elapse(
    WidgetTester tester,
    CombatHarness h,
    Duration duration,
  ) async {
    h.now = h.now.add(duration);
    await tester.pump(duration);
    await tester.pumpAndSettle();
  }

  /// Fin de test : écran démonté, puis conteneur libéré (le démontage de la
  /// portée de test ne libère pas les fournisseurs `autoDispose`) : les
  /// minuteries du suivi s'arrêtent.
  Future<void> close(WidgetTester tester, CombatHarness h) async {
    await tester.pumpWidget(const SizedBox());
    h.container.dispose();
    await tester.pump(const Duration(milliseconds: 1));
  }

  group('préparation', () {
    testWidgets('annonce sans contenu, ligne de source, attente', (
      tester,
    ) async {
      final h = await open(tester);
      await emit(tester, h, [gCombatStart(1)]);
      expect(find.text('Combat !'), findsOneWidget);
      expect(find.text('En préparation'), findsOneWidget);
      expect(
        find.text('L\'ordre d\'initiative apparaîtra au premier tour.'),
        findsOneWidget,
      );
      expect(find.text('Mené depuis Grimoire'), findsOneWidget);
      expect(find.text('Le MJ prépare le combat.'), findsOneWidget);
      expect(find.textContaining('Round'), findsNothing);
      expect(find.textContaining('initiatives'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        h.announcements,
        contains('Combat ! Le MJ lance un combat dans Les Braves.'),
      );
      await close(tester, h);
    });

    testWidgets('initiative demandée → envoyée → reçue', (tester) async {
      final h = await open(tester);
      await emit(tester, h, [
        gCombatStart(1),
        gInitiativeRequest(2, ['c-player']),
      ]);
      expect(find.text('Le MJ demande ton initiative'), findsOneWidget);
      expect(find.text('Pour Aria'), findsOneWidget);

      await tester.tap(find.text('ENVOYER MON INITIATIVE'));
      await tester.pumpAndSettle();
      expect(find.text('ENVOYER AU MJ'), findsOneWidget);
      expect(
        find.text('Une fois reçue, seul le MJ peut la modifier.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const Key('combatInitiativeField')),
        '15',
      );
      await tester.pump();
      await tester.tap(find.text('ENVOYER AU MJ'));
      await tester.pumpAndSettle();

      expect(h.grimoire.initiatives.single.payload, {
        'combat_id': kCombatA,
        'initiative': 15,
      });
      expect(find.text('15 · envoyée au MJ'), findsOneWidget);
      expect(find.text('En attente de confirmation du MJ…'), findsOneWidget);
      expect(find.text('ENVOYER MON INITIATIVE'), findsNothing);

      // Accusé de réception rapide : `state_request` 2 s après l'envoi.
      final requests = h.grimoire.stateRequests.length;
      await elapse(tester, h, const Duration(seconds: 2));
      expect(h.grimoire.stateRequests.length, requests + 1);

      await emit(tester, h, [gState(3)]);
      expect(find.text('15 · reçue par le MJ'), findsOneWidget);
      expect(
        find.text(
          'Le MJ peut l\'ajuster : la valeur retenue s\'affichera au premier '
          'tour.',
        ),
        findsOneWidget,
      );
      await close(tester, h);
    });

    testWidgets('échec rate_limited : motif visible, bouton réactivé', (
      tester,
    ) async {
      final h = await open(tester);
      h.grimoire.failures['initiative'] = const GrimoireFailure(
        GrimoireFailureKind.rateLimited,
        retryAfterSeconds: 42,
      );
      await emit(tester, h, [
        gCombatStart(1),
        gInitiativeRequest(2, ['c-player']),
      ]);
      await tester.tap(find.text('ENVOYER MON INITIATIVE'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('combatInitiativeField')),
        '9',
      );
      await tester.pump();
      await tester.tap(find.text('ENVOYER AU MJ'));
      await tester.pumpAndSettle();
      expect(find.text('Trop d\'envois. Réessaie dans 42 s.'), findsOneWidget);
      final button = tester.widget<PrimaryButton>(
        find.byKey(const Key('combatSendInitiative')),
      );
      expect(button.onPressed, isNotNull);
      await close(tester, h);
    });

    testWidgets('dévoilement : fondu, annonce, la ligne prend le relais', (
      tester,
    ) async {
      final h = await open(tester);
      await emit(tester, h, [gCombatStart(1)]);
      h.grimoire.lastLink.emit(gOrder(2, grimoireRoster(), current: 'p-gob'));
      await tester.pump(const Duration(milliseconds: 100));
      // Fondu en cours : les deux états coexistent.
      expect(find.text('Round 1'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Combat !'), findsNothing);
      expect(find.text('Round 1'), findsOneWidget);
      expect(find.text('Tour de Gobelin'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(h.announcements, contains('L\'ordre d\'initiative est dévoilé.'));
      await close(tester, h);
    });
  });

  group('ordre en lecture seule', () {
    testWidgets('ordre du MJ tel quel, « Toi », aucun contrôle', (
      tester,
    ) async {
      final h = await open(tester);
      await emit(tester, h, [
        gCombatStart(1),
        gOrder(2, grimoireRoster(), current: 'p-gob', round: 2),
      ]);
      final aria = tester.getTopLeft(find.text('Aria')).dy;
      final gob = tester.getTopLeft(find.text('Gobelin')).dy;
      final brun = tester.getTopLeft(find.text('Brun')).dy;
      expect(aria < gob && gob < brun, isTrue);
      expect(find.text('Round 2'), findsOneWidget);
      expect(find.text('Mené depuis Grimoire'), findsOneWidget);
      expect(find.text('Toi'), findsOneWidget);
      expect(find.byKey(const Key('combatHeaderMenu')), findsNothing);
      expect(find.byIcon(Icons.more_vert), findsNothing);
      expect(find.text('AJOUTER UN MONSTRE'), findsNothing);
      // Brun, sans initiative : rang « – » et « Initiative à saisir », sans
      // bouton (ce n'est pas la ligne du joueur).
      expect(find.text('Initiative à saisir'), findsOneWidget);
      expect(find.text('Renseigner'), findsNothing);
      await close(tester, h);
    });

    testWidgets('aucun tour : « Aucun tour actif · initiatives N/M »', (
      tester,
    ) async {
      final h = await open(tester);
      await emit(tester, h, [gCombatStart(1), gOrder(2, grimoireRoster())]);
      expect(find.text('Aucun tour actif · initiatives 2/3'), findsOneWidget);
      await close(tester, h);
    });

    testWidgets('héros mort : badge, « Tour sauté », lu par le lecteur', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final h = await open(tester, detail: _detail(brunDead: true));
      await emit(tester, h, [
        gCombatStart(1),
        gOrder(2, grimoireRoster(), current: 'p-gob'),
      ]);
      expect(find.text('Mort'), findsOneWidget);
      expect(find.text('Tour sauté'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Brun.*mort, tour sauté')),
        findsOneWidget,
      );
      handle.dispose();
      await close(tester, h);
    });

    testWidgets('valeur corrigée par le MJ : libellé et annonce', (
      tester,
    ) async {
      final h = await open(tester);
      await emit(tester, h, [
        gCombatStart(1),
        gInitiativeRequest(2, ['c-player']),
      ]);
      await tester.tap(find.text('ENVOYER MON INITIATIVE'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('combatInitiativeField')),
        '15',
      );
      await tester.pump();
      await tester.tap(find.text('ENVOYER AU MJ'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      await emit(tester, h, [gOrder(3, grimoireRoster(), current: 'p-gob')]);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Corrigée par le MJ (envoyé : 15)'), findsOneWidget);
      expect(h.announcements, contains('Le MJ a retenu 18.'));
      await close(tester, h);
    });

    testWidgets('retrait du joueur : bandeau, ligne repliée', (tester) async {
      final h = await open(tester);
      await emit(tester, h, [
        gCombatStart(1),
        gOrder(2, grimoireRoster(), current: 'p-gob'),
        gRemoved(3, 'p-aria'),
      ]);
      expect(find.text('Le MJ t\'a retiré de ce combat.'), findsOneWidget);
      expect(find.text('Aria'), findsNothing);
      await close(tester, h);
    });

    testWidgets('meneur : information, aucun contrôle de MJ', (tester) async {
      final h = await open(tester, detail: fakeGroupDetail(), leader: true);
      await emit(tester, h, [
        gCombatStart(1),
        gOrder(2, grimoireRoster(), current: 'p-gob'),
      ]);
      expect(
        find.text(
          'Tu mènes ce combat depuis Grimoire. Ici, tu le suis comme les '
          'joueurs.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('combatHeaderMenu')), findsNothing);
      expect(find.text('AJOUTER UN MONSTRE'), findsNothing);
      await close(tester, h);
    });

    testWidgets('zéro saut de défilement à la réception d\'un message', (
      tester,
    ) async {
      final h = await open(tester);
      final many = [
        ...grimoireRoster(),
        for (var i = 0; i < 12; i++)
          grimoireParticipant('n$i', kind: 'npc', name: 'Ombre $i'),
      ];
      await emit(tester, h, [
        gCombatStart(1),
        gOrder(2, many, current: 'p-gob'),
      ]);
      final list = find.byType(Scrollable).last;
      await tester.drag(list, const Offset(0, -200));
      await tester.pumpAndSettle();
      final before = tester.state<ScrollableState>(list).position.pixels;
      expect(before, greaterThan(0));
      await emit(tester, h, [gTurn(3, 'p-brun')]);
      expect(tester.state<ScrollableState>(list).position.pixels, before);
      await close(tester, h);
    });
  });

  group('« À toi de jouer »', () {
    testWidgets('turn qui désigne le joueur : en-tête, haptique, annonce '
        'assertive, même hauteur', (tester) async {
      final haptics = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final h = await open(tester);
      await emit(tester, h, [
        gCombatStart(1),
        gOrder(2, grimoireRoster(), current: 'p-gob'),
      ]);
      final header = find.byKey(const Key('combatHeader'));
      final before = tester.getSize(header).height;
      await emit(tester, h, [gTurn(3, 'p-aria', round: 2)]);
      expect(find.text('À toi de jouer').hitTestable(), findsOneWidget);
      expect(tester.getSize(header).height, before);
      expect(h.assertiveAnnouncements, ['C\'est ton tour.']);
      expect(haptics, ['HapticFeedbackType.mediumImpact']);
      await emit(tester, h, [gTurn(4, 'p-brun', round: 2)]);
      expect(find.text('À toi de jouer').hitTestable(), findsNothing);
      expect(find.text('Tour de Brun'), findsOneWidget);
      await close(tester, h);
    });

    testWidgets('jamais sur order ni state, même désignant le joueur', (
      tester,
    ) async {
      final h = await open(tester);
      await emit(tester, h, [
        gCombatStart(1),
        gOrder(2, grimoireRoster(), current: 'p-aria'),
        gState(3, participants: grimoireRoster(), current: 'p-aria'),
      ]);
      expect(find.text('À toi de jouer').hitTestable(), findsNothing);
      expect(find.text('Tour de Aria'), findsOneWidget);
      expect(h.assertiveAnnouncements, isEmpty);
      await close(tester, h);
    });
  });

  group('MJ hors ligne et expiration (horloge injectée)', () {
    testWidgets('90 s : bandeau, envoi désactivé, annonce ; retour du MJ', (
      tester,
    ) async {
      final h = await open(tester);
      await emit(tester, h, [
        gCombatStart(1),
        gInitiativeRequest(2, ['c-player']),
      ]);
      await elapse(tester, h, const Duration(seconds: 89));
      expect(find.byKey(const Key('combatGrimoireGmOffline')), findsNothing);
      await elapse(tester, h, const Duration(seconds: 1));
      final time = _clock(kSentAt);
      expect(
        find.text(
          'Le MJ semble hors ligne. Dernier état reçu à $time ; le combat '
          'reprendra dès son retour.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Indisponible tant que le MJ est hors ligne.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<PrimaryButton>(
              find.byKey(const Key('combatSendInitiative')),
            )
            .onPressed,
        isNull,
      );
      // La dernière vue reste affichée.
      expect(find.text('Combat !'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(
        h.announcements,
        contains('Le MJ semble hors ligne. La dernière vue reste affichée.'),
      );

      await emit(tester, h, [
        gState(3, requested: ['c-player']),
      ]);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const Key('combatGrimoireGmOffline')), findsNothing);
      expect(h.announcements, contains('Le MJ est de retour.'));
      await close(tester, h);
    });

    testWidgets('téléphone hors ligne : carte « Indisponible hors ligne », '
        'bouton désactivé', (tester) async {
      final h = await open(tester);
      await emit(tester, h, [
        gCombatStart(1),
        gInitiativeRequest(2, ['c-player']),
      ]);
      h.connectivity.goOffline();
      await tester.pumpAndSettle();
      expect(find.text('Le MJ demande ton initiative'), findsOneWidget);
      expect(find.text('Indisponible hors ligne'), findsOneWidget);
      expect(
        tester
            .widget<PrimaryButton>(
              find.byKey(const Key('combatSendInitiative')),
            )
            .onPressed,
        isNull,
      );
      expect(find.textContaining('MJ semble hors ligne'), findsNothing);
      await close(tester, h);
    });

    testWidgets('téléphone hors ligne : jamais « MJ hors ligne »', (
      tester,
    ) async {
      final h = await open(tester);
      await emit(tester, h, [
        gCombatStart(1),
        gOrder(2, grimoireRoster(), current: 'p-gob'),
      ]);
      h.connectivity.goOffline();
      await tester.pumpAndSettle();
      await elapse(tester, h, const Duration(seconds: 120));
      final time = _clock(kSentAt);
      expect(
        find.text('Hors ligne · dernier état connu à $time. Lecture seule.'),
        findsOneWidget,
      );
      expect(find.textContaining('MJ semble hors ligne'), findsNothing);
      await close(tester, h);
    });

    testWidgets('10 min : « Pas de nouvelles du MJ », reprise en fondu', (
      tester,
    ) async {
      final h = await open(tester);
      await emit(tester, h, [
        gCombatStart(1),
        gOrder(2, grimoireRoster(), current: 'p-gob'),
        gTurn(3, 'p-aria'),
      ]);
      await elapse(tester, h, const Duration(minutes: 10));
      expect(find.text('Pas de nouvelles du MJ'), findsOneWidget);
      expect(
        find.text(
          'Dernier état reçu à ${_clock(kSentAt)}. Le combat réapparaîtra '
          'ici s\'il reprend.',
        ),
        findsOneWidget,
      );
      expect(find.text('RETOUR AU GROUPE'), findsOneWidget);
      expect(find.textContaining('Combat terminé'), findsNothing);
      await emit(tester, h, [
        gState(4, participants: grimoireRoster(), current: 'p-gob'),
      ]);
      expect(find.text('Pas de nouvelles du MJ'), findsNothing);
      expect(find.text('Tour de Gobelin'), findsOneWidget);
      await close(tester, h);
    });
  });

  group('joueur exclu (décision 50)', () {
    testWidgets('group_not_found à l\'envoi : état final neutre, annonce, '
        'retour à l\'accueil', (tester) async {
      final h = await open(tester);
      h.grimoire.failures['initiative'] = const GrimoireFailure(
        GrimoireFailureKind.groupNotFound,
      );
      await emit(tester, h, [
        gCombatStart(1),
        gInitiativeRequest(2, ['c-player']),
      ]);
      final link = h.grimoire.lastLink;
      await tester.tap(find.text('ENVOYER MON INITIATIVE'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('combatInitiativeField')),
        '9',
      );
      await tester.pump();
      await tester.tap(find.text('ENVOYER AU MJ'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('combatExcluded')), findsOneWidget);
      expect(find.text('Tu ne fais plus partie de ce groupe.'), findsOneWidget);
      expect(find.byIcon(Icons.group_off_outlined), findsOneWidget);
      // Ton neutre : ni brique, ni texte dessous, ni ancienne vue.
      expect(find.byIcon(Icons.error_outline), findsNothing);
      expect(find.text('Combat !'), findsNothing);
      expect(find.text('Mené depuis Grimoire'), findsNothing);
      expect(link.closeRequested, isTrue);
      await tester.pump(const Duration(seconds: 1));
      expect(h.announcements, contains('Tu ne fais plus partie de ce groupe.'));

      await tester.tap(find.text('Retour à l\'accueil'.toUpperCase()));
      await tester.pumpAndSettle();
      expect(find.text('ACCUEIL'), findsOneWidget);
      await close(tester, h);
    });

    testWidgets('group_not_found à la lecture des sujets : état final', (
      tester,
    ) async {
      final h = CombatHarness(detail: _detail(), extraOverrides: dex());
      h.grimoire.topicsFailure = const GrimoireFailure(
        GrimoireFailureKind.groupNotFound,
      );
      await h.pumpScreen(tester);
      expect(find.text('Tu ne fais plus partie de ce groupe.'), findsOneWidget);
      expect(h.grimoire.links, isEmpty);
      await close(tester, h);
    });
  });

  group('aucun combat et fin', () {
    testWidgets('« Connexion au combat… » puis « Aucun combat en cours », '
        'toujours à l\'écoute', (tester) async {
      final h = CombatHarness(detail: _detail(), extraOverrides: dex());
      await h.pumpScreen(tester, settle: false);
      expect(find.text('Connexion au combat…'), findsOneWidget);
      await tester.pump(kGrimoireConnectingWindow);
      await tester.pumpAndSettle();
      expect(find.text('Aucun combat en cours'), findsOneWidget);
      expect(
        find.text(
          'Le combat est peut-être terminé, ou le MJ n\'est pas connecté. Il '
          's\'affichera ici dès qu\'il reprend.',
        ),
        findsOneWidget,
      );
      await emit(tester, h, [
        gState(9, participants: grimoireRoster(), current: 'p-gob'),
      ]);
      expect(find.text('Aucun combat en cours'), findsNothing);
      expect(find.text('Tour de Gobelin'), findsOneWidget);
      await close(tester, h);
    });

    testWidgets('fin : résumé existant', (tester) async {
      final h = await open(tester);
      await emit(tester, h, [
        gCombatStart(1),
        gOrder(2, grimoireRoster(), current: 'p-gob'),
        gEnd(3, rounds: 3, count: 4),
      ]);
      expect(
        find.text('Combat terminé · 3 rounds · 4 participants'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 1));
      expect(h.announcements, contains('Le combat est terminé.'));
      await close(tester, h);
    });

    testWidgets('fin à 0 participant : formulation dédiée', (tester) async {
      final h = await open(tester);
      await emit(tester, h, [gCombatStart(1), gEnd(2, rounds: 1, count: 0)]);
      expect(find.text('Combat terminé'), findsOneWidget);
      expect(
        find.text('Le combat s\'est terminé avant que l\'ordre soit dévoilé.'),
        findsOneWidget,
      );
      expect(find.textContaining('0 participant'), findsNothing);
      await close(tester, h);
    });

    testWidgets('combat natif lancé puis terminé après une expiration '
        'Grimoire : résumé natif, puis fin Grimoire plus récente', (
      tester,
    ) async {
      final h = await open(tester);
      await emit(tester, h, [gCombatStart(1)]);
      await elapse(tester, h, const Duration(minutes: 10));
      expect(find.text('Pas de nouvelles du MJ'), findsOneWidget);

      h.repo.snapshot = fakeSnapshot(participants: combatRoster());
      h.now = h.now.add(const Duration(minutes: 1));
      await h.emitChange(tester);
      expect(find.text('Round 1'), findsOneWidget);
      h.repo.snapshot = null;
      h.now = h.now.add(const Duration(minutes: 1));
      await h.emitChange(tester);
      expect(
        find.text('Combat terminé · 1 round · 4 participants'),
        findsOneWidget,
      );
      expect(find.text('Pas de nouvelles du MJ'), findsNothing);

      // Un combat Grimoire reçu après la fin native reprend la main.
      h.now = h.now.add(const Duration(minutes: 1));
      await emit(tester, h, [
        gCombatStart(1, combatId: kCombatB),
        gEnd(2, rounds: 1, count: 0, combatId: kCombatB),
      ]);
      expect(find.text('Combat terminé'), findsOneWidget);
      expect(
        find.text('Le combat s\'est terminé avant que l\'ordre soit dévoilé.'),
        findsOneWidget,
      );
      await close(tester, h);
    });

    testWidgets('API absente (PGRST106) : « Aucun combat en cours », sans '
        'écran d\'erreur ni attente', (tester) async {
      final h = CombatHarness(detail: _detail(), extraOverrides: dex());
      h.grimoire.topicsFailure = const GrimoireFailure(
        GrimoireFailureKind.unavailable,
        rawMessage: 'PGRST106',
      );
      await h.pumpScreen(tester, settle: false);
      await tester.pump(const Duration(milliseconds: 10));
      expect(find.text('Aucun combat en cours'), findsOneWidget);
      expect(find.text('Connexion au combat…'), findsNothing);
      expect(find.textContaining('Impossible'), findsNothing);
      expect(h.grimoire.links, isEmpty);
      await close(tester, h);
    });

    testWidgets('combat natif actif : Grimoire vivant affiché en priorité', (
      tester,
    ) async {
      final h = CombatHarness(detail: _detail(), extraOverrides: dex());
      h.repo.snapshot = fakeSnapshot(participants: combatRoster());
      await h.pumpScreen(tester);
      expect(find.text('Round 1'), findsOneWidget);
      expect(find.text('Mené depuis Grimoire'), findsNothing);
      await emit(tester, h, [gCombatStart(1)]);
      expect(find.text('Combat !'), findsOneWidget);
      expect(find.text('Mené depuis Grimoire'), findsOneWidget);
      await close(tester, h);
    });
  });

  group('texte ×3,0 sur 320 dp, boutons présents', () {
    testWidgets('préparation avec la carte et son bouton', (tester) async {
      final h = await open(tester, scale: 3);
      await emit(tester, h, [
        gCombatStart(1),
        gInitiativeRequest(2, ['c-player']),
      ]);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('combatSendInitiative')), findsOneWidget);
      final button = tester.getSize(
        find.byKey(const Key('combatSendInitiative')),
      );
      expect(button.height, greaterThanOrEqualTo(44));
      final header = tester.getSize(find.byKey(const Key('combatHeader')));
      expect(header.height, lessThanOrEqualTo(700 * 0.4));
      await close(tester, h);
    });

    testWidgets('ordre avec héros mort, carte en zone fixe ≤ 30 %', (
      tester,
    ) async {
      final h = await open(tester, scale: 3, detail: _detail(brunDead: true));
      await emit(tester, h, [
        gCombatStart(1),
        gInitiativeRequest(2, ['c-player']),
        gOrder(3, grimoireRoster(ariaInitiative: null), current: 'p-gob'),
      ]);
      expect(tester.takeException(), isNull);
      final card = tester.getSize(
        find.byKey(const Key('combatInitiativeCard')),
      );
      expect(card.width, lessThanOrEqualTo(320));
      final zone = tester.getSize(
        find.ancestor(
          of: find.byKey(const Key('combatInitiativeCard')),
          matching: find.byType(SingleChildScrollView),
        ),
      );
      expect(zone.height, lessThanOrEqualTo(700 * 0.3 + 0.5));
      // La ligne « morte » garde ses badges, nom complet.
      await tester.scrollUntilVisible(
        find.text('Mort'),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Mort'), findsOneWidget);
      expect(find.text('Brun'), findsOneWidget);
      await close(tester, h);
    });

    testWidgets('« Pas de nouvelles du MJ » et anglais', (tester) async {
      final h = CombatHarness(detail: _detail(), extraOverrides: dex())
        ..scale = 3
        ..locale = const Locale('en');
      await h.pumpScreen(tester);
      await emit(tester, h, [gCombatStart(1)]);
      await elapse(tester, h, const Duration(minutes: 10));
      expect(tester.takeException(), isNull);
      expect(find.text('No news from the GM'), findsOneWidget);
      await close(tester, h);
    });
  });
}
