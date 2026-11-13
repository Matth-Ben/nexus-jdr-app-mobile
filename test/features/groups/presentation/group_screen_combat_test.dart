// Écran Groupe : bandeau « Combat en cours » (3 onglets, tappable, hors zone
// défilante) et entrée « Lancer un combat » de l'onglet Membres.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/features/combat/presentation/providers/combat_providers.dart';
import 'package:personnages/features/combat/presentation/widgets/combat_banner.dart';
import 'package:personnages/features/groups/domain/group_detail.dart';
import 'package:personnages/features/groups/domain/group_note_entry.dart';
import 'package:personnages/features/groups/domain/group_treasure.dart';
import 'package:personnages/features/groups/presentation/group_screen.dart';
import 'package:personnages/features/groups/presentation/providers/group_providers.dart';
import 'package:personnages/l10n/app_localizations.dart';

import '../../../support/combat_fixtures.dart';
import '../../../support/fake_combat_repository.dart';
import '../../../support/fake_connectivity_checker.dart';
import '../../../support/fake_current_user.dart';
import '../../combat/presentation/combat_test_harness.dart';

Widget _app({
  required FakeCombatRepository repo,
  required GroupDetail detail,
  bool disableAnimations = false,
  double scale = 1,
}) {
  final List<Override> overrides = [
    currentUserFromTestOverride,
    combatRepositoryProvider.overrideWithValue(repo),
    connectivityCheckerProvider.overrideWithValue(FakeConnectivityChecker()),
    combatRefetchDebounceProvider.overrideWithValue(
      const Duration(milliseconds: 10),
    ),
    groupDetailProvider(groupId).overrideWith((ref) async => detail),
    groupMembersRealtimeWatcherProvider(groupId).overrideWith((ref) {}),
    groupTreasureProvider(groupId)
        .overrideWith((ref) async => const GroupTreasure(groupId: groupId)),
    groupNoteEntriesProvider(groupId)
        .overrideWith((ref) async => const <GroupNoteEntry>[]),
  ];
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: disableAnimations,
          textScaler: TextScaler.linear(scale),
        ),
        child: child!,
      ),
      routerConfig: GoRouter(
        initialLocation: '/groups/$groupId',
        routes: [
          GoRoute(
            path: '/groups/:id',
            builder: (context, state) =>
                GroupScreen(groupId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/groups/:id/combat',
            builder: (context, state) =>
                const Scaffold(body: Text('ÉCRAN COMBAT')),
          ),
          GoRoute(
            path: '/groups/:id/settings',
            builder: (context, state) =>
                const Scaffold(body: Text('PARAMÈTRES')),
          ),
        ],
      ),
    ),
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget app, {
  Size size = const Size(360, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadCombatFonts);

  late FakeCombatRepository repo;

  setUp(() => repo = FakeCombatRepository());

  testWidgets('sans combat actif : ni bandeau ni écran Combat', (tester) async {
    await _pump(tester, _app(repo: repo, detail: fakeGroupDetail()));
    expect(find.byKey(const Key('combatBanner')), findsNothing);
    expect(find.textContaining('Combat en cours'), findsNothing);
  });

  testWidgets('combat actif : bandeau visible sur les trois onglets', (
    tester,
  ) async {
    repo.snapshot = fakeSnapshot(
      combat: fakeCombat(round: 2, currentParticipantId: 'gob'),
      participants: [fakeParticipant('gob', name: 'Gobelin', initiative: 9)],
    );
    await _pump(tester, _app(repo: repo, detail: fakeGroupDetail()));
    for (final tab in ['MEMBRES', 'BUTIN', 'NOTES']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      expect(
        find.text('Combat en cours · round 2'),
        findsOneWidget,
        reason: tab,
      );
      expect(
        find.text('Tour de Gobelin · Ouvrir le combat'),
        findsOneWidget,
        reason: tab,
      );
    }
  });

  testWidgets('bandeau hors de la zone défilante', (tester) async {
    repo.snapshot = fakeSnapshot();
    await _pump(tester, _app(repo: repo, detail: fakeGroupDetail()));
    expect(
      find.descendant(
        of: find.byType(Scrollable),
        matching: find.byType(CombatBannerView),
      ),
      findsNothing,
    );
    expect(find.byType(CombatBannerView), findsOneWidget);
  });

  testWidgets('appui sur le bandeau : ouvre /groups/:id/combat', (
    tester,
  ) async {
    repo.snapshot = fakeSnapshot();
    await _pump(tester, _app(repo: repo, detail: fakeGroupDetail()));
    await tester.tap(find.byKey(const Key('combatBanner')));
    await tester.pumpAndSettle();
    expect(find.text('ÉCRAN COMBAT'), findsOneWidget);
  });

  testWidgets('MJ absent : le bandeau affiche « En attente du MJ »', (
    tester,
  ) async {
    repo.snapshot = fakeSnapshot();
    await _pump(
      tester,
      _app(repo: repo, detail: fakeGroupDetail(masterAbsent: true)),
    );
    expect(find.text('En attente du MJ'), findsOneWidget);
  });

  testWidgets('le bandeau disparaît à la fin du combat (évènement reçu)', (
    tester,
  ) async {
    repo.snapshot = fakeSnapshot();
    await _pump(tester, _app(repo: repo, detail: fakeGroupDetail()));
    expect(find.byKey(const Key('combatBanner')), findsOneWidget);
    repo.snapshot = null;
    repo.lastChannel.emitChange();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('combatBanner')), findsNothing);
  });

  testWidgets('apparition animée (AnimatedSize), directe en reduce motion', (
    tester,
  ) async {
    repo.snapshot = fakeSnapshot();
    await _pump(tester, _app(repo: repo, detail: fakeGroupDetail()));
    expect(
      find.descendant(
        of: find.byType(CombatGroupBanner),
        matching: find.byType(AnimatedSize),
      ),
      findsOneWidget,
    );

    await _pump(
      tester,
      _app(repo: repo, detail: fakeGroupDetail(), disableAnimations: true),
    );
    expect(find.byKey(const Key('combatBanner')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(CombatGroupBanner),
        matching: find.byType(AnimatedSize),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'bandeau Groupe à ×1,0 : 64 à 76 dp (×2,0/×3,0 : voir combat_header_banner_test)',
    (tester) async {
      repo.snapshot = fakeSnapshot(
        combat: fakeCombat(currentParticipantId: 'gob'),
        participants: [fakeParticipant('gob', name: 'Gobelin', initiative: 9)],
      );
      await _pump(
        tester,
        _app(repo: repo, detail: fakeGroupDetail()),
        size: const Size(320, 800),
      );
      expect(
        tester.getSize(find.byKey(const Key('combatBanner'))).height,
        inInclusiveRange(64, 76),
      );
    },
  );

  group('« Lancer un combat »', () {
    testWidgets('MJ : présent sur l\'onglet Membres seulement', (tester) async {
      await _pump(tester, _app(repo: repo, detail: fakeGroupDetail()));
      expect(find.text('LANCER UN COMBAT'), findsOneWidget);
      await tester.tap(find.text('BUTIN'));
      await tester.pumpAndSettle();
      expect(find.text('LANCER UN COMBAT'), findsNothing);
    });

    testWidgets('joueur : jamais de bouton', (tester) async {
      await _pump(
        tester,
        _app(repo: repo, detail: fakeGroupDetail(asPlayer: true)),
      );
      expect(find.text('LANCER UN COMBAT'), findsNothing);
      expect(find.text('Pas de combat sans MJ dans l\'app.'), findsNothing);
    });

    testWidgets('propriétaire sans rôle MJ : bandeau, pas de bouton', (
      tester,
    ) async {
      await _pump(
        tester,
        _app(repo: repo, detail: fakeGroupDetail(ownerPlaysCharacter: true)),
      );
      expect(find.text('LANCER UN COMBAT'), findsNothing);
      expect(find.text('Pas de combat sans MJ dans l\'app.'), findsOneWidget);
      await tester.tap(find.text('Paramètres du groupe'));
      await tester.pumpAndSettle();
      expect(find.text('PARAMÈTRES'), findsOneWidget);
    });

    testWidgets('lancer ouvre l\'écran Combat', (tester) async {
      await _pump(tester, _app(repo: repo, detail: fakeGroupDetail()));
      await tester.tap(find.text('LANCER UN COMBAT'));
      await tester.pumpAndSettle();
      expect(repo.calls, ['start:group-1']);
      expect(find.text('ÉCRAN COMBAT'), findsOneWidget);
    });
  });
}
