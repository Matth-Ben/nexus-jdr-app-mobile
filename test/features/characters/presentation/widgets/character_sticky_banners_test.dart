// Bloc sticky de la fiche : bandeau de synchro puis bandeau « Combat en cours »
// (priorité, forme compacte, navigation, hors ligne, mesures à 320 dp).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/core/sync/sync_banner_engine.dart';
import 'package:personnages/core/sync/sync_status_providers.dart';
import 'package:personnages/core/widgets/alert_banner.dart';
import 'package:personnages/core/widgets/info_banner.dart';
import 'package:personnages/features/characters/presentation/widgets/character_sticky_banners.dart';
import 'package:personnages/features/combat/presentation/providers/combat_providers.dart';
import 'package:personnages/features/groups/presentation/providers/group_providers.dart';
import 'package:personnages/l10n/app_localizations.dart';

import '../../../../support/combat_fixtures.dart';
import '../../../../support/fake_combat_repository.dart';
import '../../../../support/fake_connectivity_checker.dart';
import '../../../../support/fake_current_user.dart';
import '../../../../support/fake_group_character_lookup.dart';

const _character = 'c-1';
const _headerHeight = 60.0;

Future<void> _loadFont(String family, String path) async {
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(File(path).readAsBytesSync())));
  await loader.load();
}

/// État de synchro piloté par le test.
class _SyncState extends Notifier<SyncBannerState> {
  @override
  SyncBannerState build() => SyncBannerState.none;

  // ignore: use_setters_to_change_properties
  void set(SyncBannerState value) => state = value;
}

final _syncStateProvider = NotifierProvider<_SyncState, SyncBannerState>(
  _SyncState.new,
);

void main() {
  setUpAll(() async {
    await _loadFont('WorkSans', 'assets/fonts/WorkSans-VariableFont_wght.ttf');
    await _loadFont('PressStart2P', 'assets/fonts/PressStart2P-Regular.ttf');
  });

  late FakeCombatRepository combats;
  late FakeGroupCharacterLookup groups;
  late FakeConnectivityChecker connectivity;
  late ProviderContainer container;
  late String location;
  var builds = 0;

  setUp(() {
    combats = FakeCombatRepository()
      ..snapshotsByGroup['g1'] = fakeSnapshot(
        combat: fakeCombat(groupId: 'g1', round: 3),
        participants: [fakeParticipant('a', initiative: 5)],
      );
    groups = FakeGroupCharacterLookup()..groupsByCharacter[_character] = ['g1'];
    connectivity = FakeConnectivityChecker();
    location = '/fiche';
    builds = 0;
  });

  Future<void> pump(
    WidgetTester tester, {
    double scale = 1,
    Locale locale = const Locale('fr'),
    bool withCombat = true,
    Size size = const Size(320, 640),
  }) async {
    if (!withCombat) combats.snapshotsByGroup['g1'] = null;
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final overrides = <Override>[
      currentUserFromTestOverride,
      combatRepositoryProvider.overrideWithValue(combats),
      groupRepositoryProvider.overrideWithValue(groups),
      connectivityCheckerProvider.overrideWithValue(connectivity),
      combatRefetchDebounceProvider.overrideWithValue(
        const Duration(milliseconds: 10),
      ),
      syncBannerProvider(characterId: _character)
          .overrideWithBuild((ref, notifier) => ref.watch(_syncStateProvider)),
    ];
    container = ProviderContainer(overrides: overrides);
    addTearDown(connectivity.close);
    addTearDown(container.dispose);
    final router = GoRouter(
      initialLocation: '/fiche',
      routes: [
        GoRoute(
          path: '/fiche',
          builder: (context, state) => Scaffold(
            body: Column(
              children: [
                const SizedBox(height: _headerHeight, width: double.infinity),
                // Parent « fiche » : compte ses reconstructions.
                Builder(
                  builder: (context) {
                    builds++;
                    return const CharacterStickyBanners(
                      characterId: _character,
                    );
                  },
                ),
                const Expanded(
                  child: SizedBox(key: Key('content'), width: double.infinity),
                ),
              ],
            ),
          ),
        ),
        GoRoute(
          path: '/groups/:id/combat',
          builder: (context, state) {
            location = state.uri.path;
            return const Scaffold(body: Text('ECRAN COMBAT'));
          },
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  void setSync(WidgetTester tester, SyncBannerState state) {
    container.read(_syncStateProvider.notifier).set(state);
  }

  Finder banner() => find.byKey(const Key('combatSheetBanner'));

  group('présence', () {
    testWidgets('combat actif : bandeau d\'une ligne, 48 à 56 dp à ×1,0', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text('Combat en cours · round 3'), findsOneWidget);
      final height = tester.getSize(banner()).height;
      expect(height, inInclusiveRange(48, 56));
    });

    testWidgets('aucun combat actif : aucun bandeau, aucune marge', (
      tester,
    ) async {
      await pump(tester, withCombat: false);
      expect(banner(), findsNothing);
      expect(find.textContaining('Combat en cours'), findsNothing);
      // Rien d'autre qu'un bloc vide : le contenu démarre sous l'en-tête.
      expect(tester.getTopLeft(find.byKey(const Key('content'))).dy, 60);
    });

    testWidgets('personnage dans aucun groupe : aucun bandeau', (tester) async {
      groups.groupsByCharacter[_character] = [];
      await pump(tester);
      expect(banner(), findsNothing);
    });

    testWidgets('le combat se termine : le bandeau disparaît', (tester) async {
      await pump(tester);
      expect(banner(), findsOneWidget);
      combats.snapshotsByGroup['g1'] = null;
      combats.lastChannel.emitChange();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(banner(), findsNothing);
    });

    testWidgets('tap : ouvre l\'écran Combat du groupe', (tester) async {
      await pump(tester);
      await tester.tap(banner());
      await tester.pumpAndSettle();
      expect(find.text('ECRAN COMBAT'), findsOneWidget);
      expect(location, '/groups/g1/combat');
    });

    testWidgets('bouton, libellé lecteur d\'écran', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);
      expect(
        find.bySemanticsLabel('Combat en cours, round 3. Ouvrir le combat.'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('anglais', (tester) async {
      await pump(tester, locale: const Locale('en'));
      expect(find.text('Combat in progress · round 3'), findsOneWidget);
    });
  });

  group('priorité avec le bandeau de synchro', () {
    final kinds = <SyncBannerKind, SyncBannerState>{
      SyncBannerKind.alert: const SyncBannerState(
        SyncBannerKind.alert,
        alertCount: 2,
      ),
      SyncBannerKind.offline: const SyncBannerState(
        SyncBannerKind.offline,
        pendingCount: 1,
      ),
      SyncBannerKind.syncing: const SyncBannerState(SyncBannerKind.syncing),
      SyncBannerKind.pending: const SyncBannerState(
        SyncBannerKind.pending,
        pendingCount: 2,
      ),
      SyncBannerKind.synced: const SyncBannerState(SyncBannerKind.synced),
    };

    for (final entry in kinds.entries) {
      testWidgets('${entry.key.name} : le bandeau de synchro est au-dessus '
          'du bandeau de combat, qui ne disparaît pas', (tester) async {
        await pump(tester);
        setSync(tester, entry.value);
        await tester.pumpAndSettle();
        expect(banner(), findsOneWidget);
        final syncFinder = entry.key == SyncBannerKind.alert
            ? find.byType(AlertBanner)
            : find.byType(InfoBanner);
        expect(syncFinder, findsOneWidget);
        final syncBottom = tester.getBottomLeft(syncFinder).dy;
        final combatTop = tester.getTopLeft(banner()).dy;
        expect(
          combatTop,
          greaterThanOrEqualTo(syncBottom),
          reason: 'synchro avant combat',
        );
      });
    }

    testWidgets('marges : 10 sous l\'en-tête, 10 entre bandeaux, 10 sous le '
        'dernier', (tester) async {
      await pump(tester);
      setSync(tester, kinds[SyncBannerKind.syncing]!);
      await tester.pumpAndSettle();
      final sync = find.byType(InfoBanner);
      expect(tester.getTopLeft(sync).dy, _headerHeight + 10);
      expect(
        tester.getTopLeft(banner()).dy,
        tester.getBottomLeft(sync).dy + 10,
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('content'))).dy,
        tester.getBottomLeft(banner()).dy + 10,
      );
    });

    testWidgets('seul : 10 sous l\'en-tête et 10 sous le bandeau', (
      tester,
    ) async {
      await pump(tester);
      expect(tester.getTopLeft(banner()).dy, _headerHeight + 10);
      expect(
        tester.getTopLeft(find.byKey(const Key('content'))).dy,
        tester.getBottomLeft(banner()).dy + 10,
      );
    });

    testWidgets('sans combat : le bandeau de synchro garde ses marges '
        'd\'origine (10 / 10)', (tester) async {
      await pump(tester, withCombat: false);
      setSync(tester, kinds[SyncBannerKind.syncing]!);
      await tester.pumpAndSettle();
      final sync = find.byType(InfoBanner);
      expect(tester.getTopLeft(sync).dy, _headerHeight + 10);
      expect(
        tester.getTopLeft(find.byKey(const Key('content'))).dy,
        tester.getBottomLeft(sync).dy + 10,
      );
    });
  });

  group('forme compacte (D211)', () {
    testWidgets('alerte ou hors ligne : 44 dp ; sinon 48 dp minimum', (
      tester,
    ) async {
      await pump(tester);
      final normal = tester.getSize(banner()).height;
      expect(normal, greaterThanOrEqualTo(48));
      for (final kind in [SyncBannerKind.alert, SyncBannerKind.offline]) {
        setSync(tester, SyncBannerState(kind, alertCount: 1, pendingCount: 1));
        await tester.pumpAndSettle();
        expect(tester.getSize(banner()).height, 44, reason: kind.name);
      }
      for (final kind in [
        SyncBannerKind.syncing,
        SyncBannerKind.pending,
        SyncBannerKind.synced,
        SyncBannerKind.none,
      ]) {
        setSync(tester, SyncBannerState(kind, pendingCount: 1));
        await tester.pumpAndSettle();
        expect(
          tester.getSize(banner()).height,
          greaterThanOrEqualTo(48),
          reason: kind.name,
        );
      }
    });
  });

  group('hors ligne', () {
    testWidgets('« · état de HH:MM » sans second « Hors ligne »', (
      tester,
    ) async {
      await pump(tester);
      connectivity.goOffline();
      await tester.pumpAndSettle();
      final text = tester.widget<Text>(
        find.descendant(of: banner(), matching: find.byType(Text)),
      );
      expect(
        text.data,
        matches(RegExp(r'^Combat en cours · round 3 · état de \d{2}:\d{2}$')),
      );
      expect(text.data, isNot(contains('Hors ligne')));
      // Le groupe de la fiche reste connu hors ligne : le bandeau demeure.
      expect(banner(), findsOneWidget);
    });
  });

  group('mesures à 320 dp', () {
    for (final scale in [1.0, 2.0, 3.0]) {
      testWidgets('×$scale : bandeau et bloc dans les bornes', (tester) async {
        await pump(tester, scale: scale);
        final height = tester.getSize(banner()).height;
        if (scale == 1) {
          expect(height, inInclusiveRange(48, 56));
        } else {
          expect(height, lessThanOrEqualTo(112));
        }
        expect(tester.takeException(), isNull);
        // Bloc combiné (synchro en alerte + combat) plafonné à 40 %.
        setSync(
          tester,
          const SyncBannerState(SyncBannerKind.alert, alertCount: 3),
        );
        await tester.pumpAndSettle();
        final block = tester.getSize(
          find.byKey(const Key('characterStickyBannersScroll')),
        );
        expect(block.height, lessThanOrEqualTo(640 * 0.4 + 0.01));
        expect(tester.takeException(), isNull);
      });

      testWidgets('×$scale : hors ligne, le bandeau reste ≤ 112', (
        tester,
      ) async {
        await pump(tester, scale: scale);
        connectivity.goOffline();
        await tester.pumpAndSettle();
        if (scale > 1) {
          expect(tester.getSize(banner()).height, lessThanOrEqualTo(112));
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('à ×3,0 le bloc défile en interne quand il dépasse 40 %', (
      tester,
    ) async {
      await pump(tester, scale: 3, size: const Size(320, 480));
      setSync(
        tester,
        const SyncBannerState(SyncBannerKind.alert, alertCount: 3),
      );
      await tester.pumpAndSettle();
      final scroll = find.byKey(const Key('characterStickyBannersScroll'));
      expect(
        tester.getSize(scroll).height,
        lessThanOrEqualTo(480 * 0.4 + 0.01),
      );
      final position = tester
          .state<ScrollableState>(
            find.descendant(of: scroll, matching: find.byType(Scrollable)),
          )
          .position;
      expect(position.maxScrollExtent, greaterThan(0));
      // Le bandeau de combat reste atteignable en défilant.
      await tester.drag(scroll, const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(banner(), findsOneWidget);
    });
  });

  group('reconstructions', () {
    testWidgets('un évènement de combat sans rapport ne reconstruit pas le '
        'parent (la fiche)', (tester) async {
      await pump(tester);
      final before = builds;
      combats.snapshotsByGroup['g1'] = fakeSnapshot(
        combat: fakeCombat(groupId: 'g1', round: 3),
        participants: [fakeParticipant('a', initiative: 19)],
      );
      combats.lastChannel.emitChange();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(builds, before);
      // Un changement de round met le bandeau à jour, pas le parent.
      combats.snapshotsByGroup['g1'] = fakeSnapshot(
        combat: fakeCombat(groupId: 'g1', round: 4),
      );
      combats.lastChannel.emitChange();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text('Combat en cours · round 4'), findsOneWidget);
      expect(builds, before);
    });

    testWidgets('requêtes du groupe : une seule, pas une par rebuild', (
      tester,
    ) async {
      await pump(tester);
      expect(groups.calls, 1);
      setSync(tester, const SyncBannerState(SyncBannerKind.syncing));
      await tester.pumpAndSettle();
      setSync(tester, SyncBannerState.none);
      await tester.pumpAndSettle();
      combats.lastChannel.emitChange();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(groups.calls, 1);
    });
  });
}
