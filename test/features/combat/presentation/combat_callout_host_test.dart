// `CombatCallout` posé par `CombatCalloutHost` (`docs/combat-grimoire-ui.md`
// §5, §6, §10) : variantes et textes, durée (10 s, sauf navigation
// accessible ; jamais pour le tour), haptique et annonce assertive du tour,
// feuille modale ouverte, absence sur l'écran Combat du groupe concerné,
// ouverture et fermeture, position au-dessus de la barre d'onglets, texte
// ×3,0 sur 320 dp avec le bouton « Fermer ».

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/core/router/app_router.dart';
import 'package:personnages/core/router/route_stack_observer.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/widgets/bottom_bar_inset_reporter.dart';
import 'package:personnages/core/widgets/snack_bar_aware_scaffold_messenger.dart';
import 'package:personnages/features/character_sharing/data/character_sharing_repository.dart';
import 'package:personnages/features/character_sharing/presentation/providers/character_sharing_providers.dart';
import 'package:personnages/features/character_sharing/presentation/shared_character_view_screen.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/presentation/widgets/character_detail_tab_bar.dart';
import 'package:personnages/features/combat/domain/combat_notification.dart';
import 'package:personnages/features/combat/presentation/combat_callout_host.dart';
import 'package:personnages/features/combat/presentation/providers/combat_callout_providers.dart';
import 'package:personnages/features/combat/presentation/providers/combat_providers.dart';
import 'package:personnages/features/combat/presentation/providers/grimoire_combat_providers.dart';
import 'package:personnages/features/combat/presentation/providers/grimoire_groups_providers.dart';
import 'package:personnages/features/combat/presentation/widgets/combat_callout.dart';
import 'package:personnages/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/fake_connectivity_checker.dart';
import '../../../support/fake_current_user.dart';
import '../../../support/fake_grimoire_combat_gateway.dart';
import '../../../support/fake_group_membership_repository.dart';
import '../../../support/grimoire_fixtures.dart';
import 'combat_test_harness.dart' show loadCombatFonts;

const _g1 = '11111111-aaaa-4aaa-8aaa-111111111111';
const _g2 = '22222222-bbbb-4bbb-8bbb-222222222222';

const _start = (type: CombatNotificationType.combatStart, groupId: _g1);
const _turn = (type: CombatNotificationType.yourTurn, groupId: _g1);

class _Host {
  _Host() {
    container = ProviderContainer(
      overrides: [
        currentUserFromTestOverride,
        grimoireCombatGatewayProvider.overrideWithValue(
          FakeGrimoireCombatGateway(),
        ),
        connectivityCheckerProvider.overrideWithValue(connectivity),
        combatClockProvider.overrideWithValue(() => now),
        appRouterProvider.overrideWith((ref) => router),
        groupMembershipRepositoryProvider.overrideWithValue(
          FakeGroupMembershipRepository([
            membership(_g1, name: 'Les Braves de la Marche du Nord'),
            membership(_g2, name: 'La Compagnie'),
          ]),
        ),
        characterSharingRepositoryProvider.overrideWithValue(
          _SharingRepository(),
        ),
      ],
    );
    router = GoRouter(
      initialLocation: '/',
      observers: [container.read(routeStackObserverProvider)],
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    builder: (context) => const SizedBox(
                      height: 200,
                      child: Center(child: Text('FEUILLE')),
                    ),
                  ),
                  child: const Text('ACCUEIL'),
                ),
                TextButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Objet retiré'),
                      action: SnackBarAction(
                        label: 'Annuler',
                        onPressed: () => undone++,
                      ),
                    ),
                  ),
                  child: const Text('SNACK'),
                ),
              ],
            ),
          ),
        ),
        GoRoute(
          // Écran scène (accueil de l'app).
          name: 'character-list',
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('SCÈNE')),
        ),
        GoRoute(
          path: '/p/:token',
          builder: (context, state) =>
              SharedCharacterViewScreen(token: state.pathParameters['token']!),
        ),
        GoRoute(
          path: '/sheet',
          builder: (context, state) => const Scaffold(
            body: Text('FICHE'),
            bottomNavigationBar: BottomBarInsetReporter(
              child: SizedBox(
                height: 80,
                child: ColoredBox(color: Colors.brown),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/groups/:id',
          builder: (context, state) =>
              Scaffold(body: Text('GROUPE ${state.pathParameters['id']}')),
        ),
        GoRoute(
          name: kGroupCombatRouteName,
          path: '/groups/:id/combat',
          builder: (context, state) =>
              Scaffold(body: Text('COMBAT ${state.pathParameters['id']}')),
        ),
      ],
    );
  }

  late final ProviderContainer container;
  late final GoRouter router;
  final FakeConnectivityChecker connectivity = FakeConnectivityChecker();
  DateTime now = DateTime(2026, 11, 23, 21);
  final List<String> assertive = [];
  final List<String> haptics = [];
  double scale = 1;
  bool accessibleNavigation = false;

  /// Hauteur du clavier simulé (`viewInsets.bottom`).
  double keyboard = 0;
  int undone = 0;

  CombatCalloutController get controller =>
      container.read(combatCalloutControllerProvider.notifier);

  Future<void> pump(
    WidgetTester tester, {
    Size size = const Size(320, 700),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
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
    // Les noms des groupes viennent de la liste des groupes du joueur.
    container.read(myGroupMembershipsProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              accessibleNavigation: accessibleNavigation,
              viewInsets: EdgeInsets.only(bottom: keyboard),
              viewPadding: const EdgeInsets.only(top: 24),
              padding: const EdgeInsets.only(top: 24),
            ),
            // Comme `main.dart` : le messager des `SnackBar` de l'app, puis
            // le signal.
            child: SnackBarAwareScaffoldMessenger(
              child: CombatCalloutHost(
                assertiveAnnouncer: (context, text) => assertive.add(text),
                child: child!,
              ),
            ),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.pump(Duration.zero);
    }
    await tester.pumpAndSettle();
  }

  Future<void> elapse(WidgetTester tester, Duration duration) async {
    now = now.add(duration);
    await tester.pump(duration);
    await tester.pumpAndSettle();
  }

  /// État connu du combat de [_g1] : ordre dévoilé, round [round], tour du
  /// joueur (Aria).
  void knownTurn({int round = 3}) {
    container.read(grimoireCombatProvider(_g1).notifier)
      ..setIdentity(kMe)
      ..receive(
        gState(
          1,
          participants: grimoireRoster(),
          current: 'p-aria',
          round: round,
        ),
      );
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await connectivity.close();
  }
}

Finder _callout() => find.byType(CombatCalloutView);

class _SharingRepository implements CharacterSharingRepository {
  @override
  Future<CharacterDetail?> fetchSharedCharacter(String token) async =>
      const CharacterDetail(
        id: 'char-1',
        name: 'Halltesse',
        raceName: 'Elfe',
        classes: [],
        xp: 0,
        currentHp: 10,
        maxHp: 10,
        temporaryHp: 0,
        abilityScores: {
          'str': 10,
          'dex': 10,
          'con': 10,
          'int': 10,
          'wis': 10,
          'cha': 10,
        },
      );

  @override
  Future<CharacterDetail?> fetchGroupMemberCharacter({
    required String groupId,
    required String characterId,
  }) => throw UnimplementedError();

  @override
  Future<String> regenerateShareToken(String characterId) =>
      throw UnimplementedError();

  @override
  Future<void> disableShareToken(String characterId) =>
      throw UnimplementedError();
}

/// Libellés lus de la carte (bouton) et présence de la région vivante.
({String label, bool liveRegion}) _semanticsOf(WidgetTester tester) {
  final button = tester.widget<Semantics>(
    find
        .ancestor(
          of: find.byKey(const Key('combatCallout')),
          matching: find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.button == true,
          ),
        )
        .first,
  );
  return (
    label: button.properties.label ?? '',
    liveRegion: find
        .descendant(
          of: _callout(),
          matching: find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.liveRegion == true,
          ),
        )
        .evaluate()
        .isNotEmpty,
  );
}

void main() {
  setUpAll(loadCombatFonts);

  group('variantes', () {
    testWidgets('annonce « Combat ! » : nom complet du groupe, cadre doré, '
        'en bas de l\'écran ; retirée après 10 s', (tester) async {
      final h = _Host();
      await h.pump(tester);
      h.controller.showFromPush(_start);
      await h.settle(tester);
      expect(find.text('Combat !'), findsOneWidget);
      expect(
        find.text('Les Braves de la Marche du Nord · Ouvrir le combat'),
        findsOneWidget,
      );
      final view = tester.widget<CombatCalloutView>(_callout());
      expect(view.variant, CombatCalloutVariant.announce);
      final material = tester.widget<Material>(
        find.descendant(of: _callout(), matching: find.byType(Material)).first,
      );
      expect(material.color, AppColors.parchmentCard);
      final rect = tester.getRect(_callout());
      expect(rect.top, greaterThan(350));
      expect(rect.left, 22);
      expect(rect.right, 320 - 22);
      expect(rect.height, inInclusiveRange(56, 88));
      expect(h.haptics, isEmpty);
      expect(h.assertive, isEmpty);

      await h.elapse(tester, const Duration(seconds: 9));
      expect(_callout(), findsOneWidget);
      await h.elapse(tester, const Duration(seconds: 1));
      expect(_callout(), findsNothing);
      await h.dispose(tester);
    });

    testWidgets('annonce avec initiative à envoyer : « Envoie ton '
        'initiative »', (tester) async {
      final h = _Host();
      await h.pump(tester);
      h.container.read(grimoireCombatProvider(_g1).notifier)
        ..setIdentity(kMe)
        ..receive(gState(1, requested: ['c-player']));
      h.controller.showFromPush(_start);
      await h.settle(tester);
      expect(
        find.text('Les Braves de la Marche du Nord · Envoie ton initiative'),
        findsOneWidget,
      );
      await h.dispose(tester);
    });

    testWidgets('navigation accessible : l\'annonce ne disparaît pas seule', (
      tester,
    ) async {
      final h = _Host()..accessibleNavigation = true;
      await h.pump(tester);
      h.controller.showFromPush(_start);
      await h.settle(tester);
      await h.elapse(tester, const Duration(minutes: 1));
      expect(_callout(), findsOneWidget);
      await h.dispose(tester);
    });

    testWidgets('tour : « À toi de jouer », round, fond turn-fill ; jamais '
        'retiré par une minuterie ; haptique et annonce assertive une fois', (
      tester,
    ) async {
      final h = _Host();
      await h.pump(tester);
      h
        ..knownTurn()
        ..controller.showFromPush(_turn);
      await h.settle(tester);
      expect(find.text('À toi de jouer'), findsOneWidget);
      expect(
        find.text(
          'Les Braves de la Marche du Nord · round 3 · Ouvrir le combat',
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<CombatCalloutView>(_callout()).variant,
        CombatCalloutVariant.turn,
      );
      expect(h.haptics, ['HapticFeedbackType.mediumImpact']);
      expect(h.assertive, ['C\'est ton tour.']);
      await h.elapse(tester, const Duration(minutes: 5));
      expect(_callout(), findsOneWidget);
      expect(h.haptics, hasLength(1));
      expect(h.assertive, hasLength(1));
      await h.dispose(tester);
    });

    testWidgets('sémantique : région vivante, bouton « Ouvrir le combat », '
        'action « Fermer »', (tester) async {
      final h = _Host();
      await h.pump(tester);
      h.controller.showFromPush(_start);
      await h.settle(tester);
      expect(
        find.descendant(
          of: _callout(),
          matching: find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.liveRegion == true,
          ),
        ),
        findsOneWidget,
      );
      final button = tester.widget<Semantics>(
        find
            .ancestor(
              of: find.byKey(const Key('combatCallout')),
              matching: find.byWidgetPredicate(
                (w) => w is Semantics && w.properties.button == true,
              ),
            )
            .first,
      );
      expect(button.properties.hintOverrides?.onTapHint, 'Ouvrir le combat');
      expect(
        button.properties.customSemanticsActions!.keys.single.label,
        'Fermer',
      );
      await h.dispose(tester);
    });
  });

  group('revue visuelle du 24/11/2026', () {
    testWidgets('région vivante sur l\'annonce seulement ; libellé sans « . » '
        'après « Combat ! »', (tester) async {
      final h = _Host();
      await h.pump(tester);
      h.controller.showFromPush(_start);
      await h.settle(tester);
      var semantics = _semanticsOf(tester);
      expect(semantics.liveRegion, isTrue);
      expect(
        semantics.label,
        'Combat ! Les Braves de la Marche du Nord · Ouvrir le combat',
      );

      h.knownTurn();
      h.controller.showFromPush(_turn);
      await h.settle(tester);
      semantics = _semanticsOf(tester);
      expect(semantics.liveRegion, isFalse);
      expect(semantics.label, startsWith('À toi de jouer. '));
      expect(h.assertive, ['C\'est ton tour.']);
      await h.dispose(tester);
    });

    testWidgets('écran scène : cadre emphasis et ombre diffuse ; écran '
        'parchemin : cadre doré, sans ombre', (tester) async {
      final h = _Host();
      await h.pump(tester);
      h.controller.showFromPush(_start);
      await h.settle(tester);
      CombatCalloutView view() => tester.widget<CombatCalloutView>(_callout());
      BorderSide side() {
        final material = tester.widget<Material>(
          find
              .descendant(of: _callout(), matching: find.byType(Material))
              .first,
        );
        return (material.shape! as RoundedRectangleBorder).side;
      }

      List<BoxShadow> shadows() => [
        for (final box in tester.widgetList<Container>(
          find.descendant(of: _callout(), matching: find.byType(Container)),
        ))
          ...?(box.decoration as BoxDecoration?)?.boxShadow,
      ];

      expect(view().onScene, isFalse);
      expect(side().color, AppColors.goldEnd);
      expect(shadows(), isEmpty);

      h.router.go('/home');
      await h.settle(tester);
      h.controller.showFromPush((
        type: CombatNotificationType.combatStart,
        groupId: _g2,
      ));
      await h.settle(tester);
      expect(view().onScene, isTrue);
      expect(side().color, AppColors.woodMedium);
      expect(side().width, 3);
      expect(
        shadows().map((shadow) => shadow.color),
        containsAll([AppColors.woodDark, AppColors.cardDiffuseShadow]),
      );
      final diffuse = shadows().singleWhere(
        (shadow) => shadow.color == AppColors.cardDiffuseShadow,
      );
      expect(diffuse.blurRadius, 6);
      expect(diffuse.offset, const Offset(0, 3));
      await h.dispose(tester);
    });

    testWidgets('SnackBar affichée : le signal se pose au-dessus (space.sm), '
        '« Annuler » reste touchable, puis il redescend', (tester) async {
      final h = _Host();
      await h.pump(tester);
      h.controller.showFromPush(_turn);
      await h.settle(tester);
      final alone = tester.getRect(_callout());

      await tester.tap(find.text('SNACK'));
      await h.settle(tester);
      final snackBar = tester.getRect(find.byType(SnackBar));
      final raised = tester.getRect(_callout());
      expect(raised.bottom, closeTo(snackBar.top - 10, 1));
      expect(raised.overlaps(snackBar), isFalse);
      await tester.tap(find.text('Annuler'));
      await h.settle(tester);
      expect(h.undone, 1);

      // SnackBar partie : retour à sa place.
      await h.elapse(tester, const Duration(seconds: 5));
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.getRect(_callout()).bottom, closeTo(alone.bottom, 0.5));
      await h.dispose(tester);
    });

    testWidgets('clavier ouvert : le signal se place en haut, puis redescend '
        'à la fermeture ; haptique et annonce immédiates', (tester) async {
      final h = _Host()..keyboard = 300;
      await h.pump(tester);
      h.controller.showFromPush(_turn);
      await h.settle(tester);
      expect(tester.getRect(_callout()).top, closeTo(24 + 10, 1.5));
      expect(h.haptics, hasLength(1));
      expect(h.assertive, hasLength(1));

      h.keyboard = 0;
      await h.pump(tester);
      expect(tester.getRect(_callout()).bottom, closeTo(700 - 22, 1.5));
      await h.dispose(tester);
    });

    testWidgets('fiche partagée : le bas du signal est au haut de la barre '
        'd\'onglets + space.lg', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final h = _Host();
      await h.pump(tester, size: const Size(400, 800));
      unawaited(h.router.push('/p/tok-abc'));
      await h.settle(tester);
      expect(find.byType(BottomBarInsetReporter), findsOneWidget);
      h.controller.showFromPush(_start);
      await h.settle(tester);
      final tabBar = tester.getRect(find.byType(CharacterDetailTabBar));
      expect(tester.getRect(_callout()).bottom, closeTo(tabBar.top - 22, 0.5));
      await h.dispose(tester);
    });
  });

  group('interactions', () {
    testWidgets('« Fermer » retire le signal', (tester) async {
      final h = _Host();
      await h.pump(tester);
      h.controller.showFromPush(_turn);
      await h.settle(tester);
      final close = tester.getSize(find.byKey(const Key('combatCalloutClose')));
      expect(close, const Size(44, 44));
      await tester.tap(find.byKey(const Key('combatCalloutClose')));
      await h.settle(tester);
      expect(_callout(), findsNothing);
      expect(h.container.read(combatCalloutControllerProvider), isNull);
      await h.dispose(tester);
    });

    testWidgets('toucher la carte ouvre l\'écran Combat (le retour ramène à '
        'l\'écran d\'avant) ; aucun signal sur cet écran pour ce groupe, '
        'celui d\'un autre groupe s\'affiche', (tester) async {
      final h = _Host();
      await h.pump(tester);
      h.controller.showFromPush(_turn);
      await h.settle(tester);
      await tester.tap(find.byKey(const Key('combatCallout')));
      await h.settle(tester);
      expect(find.text('COMBAT $_g1'), findsOneWidget);
      expect(_callout(), findsNothing);

      h.now = h.now.add(const Duration(minutes: 2));
      h.controller.showFromPush(_start);
      await h.settle(tester);
      expect(_callout(), findsNothing);
      h.controller.showFromPush((
        type: CombatNotificationType.combatStart,
        groupId: _g2,
      ));
      await h.settle(tester);
      expect(find.text('La Compagnie · Ouvrir le combat'), findsOneWidget);

      h.router.pop();
      await h.settle(tester);
      expect(find.text('ACCUEIL'), findsOneWidget);
      await h.dispose(tester);
    });

    testWidgets('feuille modale ouverte : haptique et annonce tout de suite, '
        'signal affiché à la fermeture de la feuille', (tester) async {
      final h = _Host();
      await h.pump(tester);
      await tester.tap(find.text('ACCUEIL'));
      await h.settle(tester);
      expect(find.text('FEUILLE'), findsOneWidget);
      h.controller.showFromPush(_turn);
      await h.settle(tester);
      expect(h.haptics, hasLength(1));
      expect(h.assertive, ['C\'est ton tour.']);
      expect(_callout(), findsNothing);

      h.router.pop();
      await h.settle(tester);
      expect(find.text('FEUILLE'), findsNothing);
      expect(_callout(), findsOneWidget);
      expect(h.haptics, hasLength(1));
      await h.dispose(tester);
    });

    testWidgets('au-dessus de la barre d\'onglets de la page', (tester) async {
      final h = _Host();
      await h.pump(tester);
      unawaited(h.router.push('/sheet'));
      await h.settle(tester);
      h.controller.showFromPush(_start);
      await h.settle(tester);
      final rect = tester.getRect(_callout());
      expect(rect.bottom, lessThanOrEqualTo(700 - 80 - 22 + 0.5));
      expect(rect.bottom, greaterThan(700 - 80 - 22 - 8));
      await h.dispose(tester);
    });
  });

  group('texte ×3,0 sur 320 dp, bouton « Fermer » présent', () {
    for (final turn in [false, true]) {
      testWidgets(turn ? 'variante tour' : 'variante annonce', (tester) async {
        final h = _Host()..scale = 3;
        await h.pump(tester);
        if (turn) h.knownTurn(round: 12);
        h.controller.showFromPush(turn ? _turn : _start);
        await h.settle(tester);
        expect(tester.takeException(), isNull);
        final rect = tester.getRect(_callout());
        expect(rect.height, lessThanOrEqualTo(700 * 0.25 + 0.5));
        expect(rect.width, lessThanOrEqualTo(320));
        expect(
          find.byKey(const Key('combatCalloutClose')).hitTestable(),
          findsOneWidget,
        );
        expect(
          tester.getSize(find.byKey(const Key('combatCalloutClose'))),
          const Size(44, 44),
        );
        // Nom du groupe jamais coupé : aucun texte limité en lignes.
        for (final text in tester.widgetList<Text>(
          find.descendant(of: _callout(), matching: find.byType(Text)),
        )) {
          expect(text.maxLines, isNull);
          expect(text.overflow, isNull);
        }
        await h.dispose(tester);
      });
    }
  });
}
