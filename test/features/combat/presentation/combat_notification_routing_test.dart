// Notifications push du combat (`docs/combat-grimoire-ui.md` §5 et §8,
// contrat DeepCore §5) traitées par `PushTokenRegistrar` :
// - touchée (`onMessageOpenedApp`, `getInitialMessage`) : écran Groupe puis
//   écran Combat si le compte est membre ; sinon « Ce groupe n'est plus
//   accessible. » ; type inconnu ignoré ;
// - reçue app ouverte : le signal global, jamais la SnackBar générique.

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/core/notifications/notification_providers.dart';
import 'package:personnages/core/notifications/push_notification_gateway.dart';
import 'package:personnages/core/notifications/push_token_registrar.dart';
import 'package:personnages/core/notifications/push_token_repository.dart';
import 'package:personnages/core/router/app_router.dart';
import 'package:personnages/core/router/route_stack_observer.dart';
import 'package:personnages/features/auth/data/auth_state_stream.dart';
import 'package:personnages/features/auth/presentation/providers/auth_providers.dart';
import 'package:personnages/features/combat/presentation/combat_callout_host.dart';
import 'package:personnages/features/combat/presentation/providers/combat_callout_providers.dart';
import 'package:personnages/features/combat/presentation/providers/combat_providers.dart';
import 'package:personnages/features/combat/presentation/providers/grimoire_combat_providers.dart';
import 'package:personnages/features/combat/presentation/providers/grimoire_groups_providers.dart';
import 'package:personnages/features/combat/presentation/widgets/combat_callout.dart';
import 'package:personnages/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../support/fake_connectivity_checker.dart';
import '../../../support/fake_current_user.dart';
import '../../../support/fake_grimoire_combat_gateway.dart';
import '../../../support/fake_group_membership_repository.dart';

const _member = '33333333-cccc-4ccc-8ccc-333333333333';
const _former = '44444444-dddd-4ddd-8ddd-444444444444';

RemoteMessage _combat(String type, String groupId) => RemoteMessage(
  data: {'v': '1', 'type': type, 'group_id': groupId},
  notification: const RemoteNotification(title: 'Combat !', body: 'texte'),
);

class _Gateway implements PushNotificationGateway {
  RemoteMessage? initial;
  final _messages = StreamController<RemoteMessage>.broadcast();
  final _opened = StreamController<RemoteMessage>.broadcast();

  @override
  Future<NotificationSettings> requestPermission() =>
      throw UnimplementedError();

  @override
  Future<NotificationSettings> getNotificationSettings() =>
      throw UnimplementedError();

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Stream<RemoteMessage> get onMessage => _messages.stream;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp => _opened.stream;

  @override
  Future<RemoteMessage?> getInitialMessage() async => initial;

  void receive(RemoteMessage message) => _messages.add(message);

  void open(RemoteMessage message) => _opened.add(message);
}

class _TokenRepository implements PushTokenRepository {
  @override
  Future<void> upsertToken({
    required String token,
    required String platform,
  }) async {}

  @override
  Future<void> releaseToken({required String token}) async {}
}

class _AuthStream implements AuthStateStream {
  @override
  Stream<AuthState> get onAuthStateChange => const Stream.empty();
}

class _App {
  /// [authRedirect] : la vraie redirection d'authentification de l'app
  /// (`computeAuthRedirect`), avec la session et la présentation simulées.
  _App({this.authRedirect = false}) {
    container = ProviderContainer(
      overrides: [
        currentUserFromTestOverride,
        pushNotificationGatewayProvider.overrideWithValue(gateway),
        pushTokenRepositoryProvider.overrideWithValue(_TokenRepository()),
        authStateStreamProvider.overrideWithValue(_AuthStream()),
        appRouterProvider.overrideWith((ref) => router),
        groupMembershipRepositoryProvider.overrideWithValue(memberships),
        connectivityCheckerProvider.overrideWithValue(connectivity),
        grimoireCombatGatewayProvider.overrideWithValue(
          FakeGrimoireCombatGateway(),
        ),
        combatClockProvider.overrideWithValue(() => DateTime(2026, 11, 23, 21)),
      ],
    );
    router = GoRouter(
      initialLocation: '/',
      observers: [container.read(routeStackObserverProvider)],
      redirect: authRedirect
          ? (context, state) => computeAuthRedirect(
              isLoggedIn: container.read(currentUserProvider) != null,
              location: state.uri.toString(),
              needsOnboarding: needsOnboarding,
            )
          : null,
      routes: [
        GoRoute(path: '/', builder: (context, state) => _page('ACCUEIL')),
        GoRoute(
          path: '/login',
          builder: (context, state) => _page('CONNEXION'),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => _page('PRÉSENTATION'),
        ),
        GoRoute(
          path: '/groups/:id',
          builder: (context, state) =>
              _page('GROUPE ${state.pathParameters['id']}'),
        ),
        GoRoute(
          name: kGroupCombatRouteName,
          path: '/groups/:id/combat',
          builder: (context, state) =>
              _page('COMBAT ${state.pathParameters['id']}'),
        ),
      ],
    );
  }

  static Widget _page(String text) => Scaffold(body: Center(child: Text(text)));

  final bool authRedirect;

  /// Présentation de l'app pas encore vue (`onboarding_completed` absent).
  bool needsOnboarding = false;

  final _Gateway gateway = _Gateway();
  final FakeGroupMembershipRepository memberships =
      FakeGroupMembershipRepository([membership(_member, name: 'Les Braves')]);
  final FakeConnectivityChecker connectivity = FakeConnectivityChecker();
  late final ProviderContainer container;
  late final GoRouter router;

  String get location => router.state.uri.toString();

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          scaffoldMessengerKey: container.read(scaffoldMessengerKeyProvider),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          builder: (context, child) => CombatCalloutHost(
            assertiveAnnouncer: (context, text) {},
            child: child!,
          ),
        ),
      ),
    );
    container.read(pushTokenRegistrarProvider);
    await settle(tester);
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.pump(Duration.zero);
    }
    await tester.pumpAndSettle();
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await connectivity.close();
  }
}

void main() {
  group('notification touchée', () {
    for (final type in ['combat_start', 'your_turn']) {
      testWidgets('$type, membre : écran Groupe puis écran Combat (le retour '
          'mène au groupe)', (tester) async {
        final app = _App();
        await app.pump(tester);
        app.gateway.open(_combat(type, _member));
        await app.settle(tester);
        expect(find.text('COMBAT $_member'), findsOneWidget);
        expect(app.location, '/groups/$_member/combat');
        app.router.pop();
        await app.settle(tester);
        expect(find.text('GROUPE $_member'), findsOneWidget);
        await app.dispose(tester);
      });
    }

    testWidgets('compte qui n\'est plus membre : rien ne s\'ouvre, « Ce '
        'groupe n\'est plus accessible. »', (tester) async {
      final app = _App();
      await app.pump(tester);
      app.gateway.open(_combat('your_turn', _former));
      await app.settle(tester);
      expect(app.location, '/');
      expect(find.text('ACCUEIL'), findsOneWidget);
      expect(find.text('Ce groupe n\'est plus accessible.'), findsOneWidget);
      await app.dispose(tester);
    });

    testWidgets('appartenance inconnue (hors ligne) : le combat s\'ouvre', (
      tester,
    ) async {
      final app = _App();
      app.memberships.error = Exception('hors ligne');
      await app.pump(tester);
      app.gateway.open(_combat('combat_start', _former));
      await app.settle(tester);
      expect(app.location, '/groups/$_former/combat');
      await app.dispose(tester);
    });

    testWidgets('type inconnu du format versionné (reveal) : ignoré', (
      tester,
    ) async {
      final app = _App();
      await app.pump(tester);
      app.gateway.open(
        const RemoteMessage(
          data: {
            'v': '1',
            'type': 'reveal',
            'group_id': _member,
            'characterId': 'c-1',
          },
        ),
      );
      await app.settle(tester);
      expect(app.location, '/');
      expect(find.byType(SnackBar), findsNothing);
      await app.dispose(tester);
    });

    testWidgets('app froide (getInitialMessage) : écran Combat du groupe', (
      tester,
    ) async {
      final app = _App();
      app.gateway.initial = _combat('your_turn', _member);
      await app.pump(tester);
      await app.settle(tester);
      expect(app.location, '/groups/$_member/combat');
      expect(find.text('COMBAT $_member'), findsOneWidget);
      await app.dispose(tester);
    });
  });

  group('démarrage à froid avec la vraie redirection d\'authentification', () {
    testWidgets('session restaurée, présentation vue : écran Combat, le '
        'retour mène au groupe', (tester) async {
      final app = _App(authRedirect: true);
      app.gateway.initial = _combat('your_turn', _member);
      await app.pump(tester);
      await app.settle(tester);
      expect(app.location, '/groups/$_member/combat');
      app.router.pop();
      await app.settle(tester);
      expect(find.text('GROUPE $_member'), findsOneWidget);
      await app.dispose(tester);
    });

    testWidgets('présentation pas encore vue : la redirection l\'emporte, '
        'aucun combat empilé par-dessus', (tester) async {
      final app = _App(authRedirect: true)..needsOnboarding = true;
      app.gateway.initial = _combat('combat_start', _member);
      await app.pump(tester);
      await app.settle(tester);
      expect(app.location, '/onboarding');
      expect(app.router.canPop(), isFalse);
      expect(find.textContaining('COMBAT'), findsNothing);
      await app.dispose(tester);
    });

    testWidgets('aucune session : rien ne s\'ouvre (écran de connexion)', (
      tester,
    ) async {
      final app = _App(authRedirect: true);
      app.container.read(testUserIdProvider.notifier).set(null);
      app.gateway.initial = _combat('your_turn', _member);
      await app.pump(tester);
      await app.settle(tester);
      expect(app.location, '/login');
      expect(find.text('CONNEXION'), findsOneWidget);
      expect(app.memberships.reads, 0);
      await app.dispose(tester);
    });
  });

  group('notification reçue app ouverte', () {
    testWidgets('combat : le signal global, jamais la SnackBar générique', (
      tester,
    ) async {
      final app = _App();
      await app.pump(tester);
      app.gateway.receive(_combat('combat_start', _member));
      await app.settle(tester);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(CombatCalloutView), findsOneWidget);
      expect(find.text('Les Braves · Ouvrir le combat'), findsOneWidget);
      final callout = app.container.read(combatCalloutControllerProvider)!;
      expect(callout.kind, CombatCalloutKind.combatStart);

      // La même notification en double : un seul signal.
      app.gateway.receive(_combat('combat_start', _member));
      await app.settle(tester);
      expect(app.container.read(combatCalloutControllerProvider), callout);
      await app.dispose(tester);
    });

    testWidgets('your_turn : variante tour', (tester) async {
      final app = _App();
      await app.pump(tester);
      app.gateway.receive(_combat('your_turn', _member));
      await app.settle(tester);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.text('À toi de jouer'), findsOneWidget);
      await app.dispose(tester);
    });

    testWidgets('autre notification : SnackBar générique inchangée', (
      tester,
    ) async {
      final app = _App();
      await app.pump(tester);
      app.gateway.receive(
        const RemoteMessage(
          data: {'characterId': 'c-1'},
          notification: RemoteNotification(title: 'Repos', body: 'Long'),
        ),
      );
      await app.settle(tester);
      expect(find.text('Repos — Long'), findsOneWidget);
      expect(find.byType(CombatCalloutView), findsNothing);
      await app.dispose(tester);
    });
  });
}
