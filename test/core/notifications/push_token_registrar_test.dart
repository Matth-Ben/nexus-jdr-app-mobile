// Tests de `PushTokenRegistrar` (core/notifications/push_token_registrar.dart)
// — trouvé en revue de code comme le seul point sensible de ce chantier sans
// couverture dédiée (permission jamais redemandée au démarrage, jeton
// enregistré seulement si déjà accordée, routage sur tap de notification).
// Même patron que `character_creation_catalog_preloader_test.dart` :
// `authStateStreamProvider` overridé avec un `StreamController` piloté à la
// main, `PushNotificationGateway`/`PushTokenRepository` overridés avec des
// doubles minimaux, jamais un vrai canal Firebase (indisponible en `flutter
// test`, voir la doc de classe de `PushNotificationGateway`).

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/notifications/notification_providers.dart';
import 'package:personnages/core/notifications/push_notification_gateway.dart';
import 'package:personnages/core/notifications/push_token_registrar.dart';
import 'package:personnages/core/notifications/push_token_repository.dart';
import 'package:personnages/core/router/app_router.dart';
import 'package:personnages/features/auth/data/auth_state_stream.dart';
import 'package:personnages/features/auth/presentation/providers/auth_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('PushTokenRegistrar', () {
    late _FakeGateway gateway;
    late _FakeRepository repository;
    late StreamController<AuthState> authStateController;
    late ProviderContainer container;

    setUp(() {
      gateway = _FakeGateway();
      repository = _FakeRepository();
      authStateController = StreamController<AuthState>.broadcast();
      container = ProviderContainer(
        overrides: [
          pushNotificationGatewayProvider.overrideWithValue(gateway),
          pushTokenRepositoryProvider.overrideWithValue(repository),
          authStateStreamProvider.overrideWithValue(
            _FakeAuthStateStream(authStateController.stream),
          ),
          appRouterProvider.overrideWithValue(_testRouter()),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(authStateController.close);
    });

    test('au démarrage, ne demande JAMAIS la permission OS (requestPermission) '
        '— seulement une lecture passive (getNotificationSettings)', () async {
      container.read(pushTokenRegistrarProvider);
      authStateController.add(
        AuthState(AuthChangeEvent.initialSession, _fakeSession()),
      );
      await pumpEventQueue();

      expect(gateway.requestPermissionCallCount, 0);
      expect(gateway.getNotificationSettingsCallCount, 1);
    });

    test('permission déjà accordée : enregistre le jeton (upsertToken) à la '
        'reprise de session ET à la connexion', () async {
      gateway.settingsToReturn = _settings(AuthorizationStatus.authorized);
      container.read(pushTokenRegistrarProvider);

      authStateController.add(
        AuthState(AuthChangeEvent.initialSession, _fakeSession()),
      );
      await pumpEventQueue();
      expect(repository.upsertedTokens, ['fcm-token-1']);

      authStateController.add(
        AuthState(AuthChangeEvent.signedIn, _fakeSession()),
      );
      await pumpEventQueue();
      expect(repository.upsertedTokens, ['fcm-token-1', 'fcm-token-1']);
    });

    test('permission refusée (denied) : ne récupère ni n\'enregistre aucun '
        'jeton', () async {
      gateway.settingsToReturn = _settings(AuthorizationStatus.denied);
      container.read(pushTokenRegistrarProvider);

      authStateController.add(
        AuthState(AuthChangeEvent.initialSession, _fakeSession()),
      );
      await pumpEventQueue();

      expect(gateway.getTokenCallCount, 0);
      expect(repository.upsertedTokens, isEmpty);
    });

    test(
      'permission provisional (iOS silencieux) traitée comme accordée',
      () async {
        gateway.settingsToReturn = _settings(AuthorizationStatus.provisional);
        container.read(pushTokenRegistrarProvider);

        authStateController.add(
          AuthState(AuthChangeEvent.initialSession, _fakeSession()),
        );
        await pumpEventQueue();

        expect(repository.upsertedTokens, ['fcm-token-1']);
      },
    );

    test('initialSession sans session (non connecté au lancement) ne '
        'déclenche rien', () async {
      gateway.settingsToReturn = _settings(AuthorizationStatus.authorized);
      container.read(pushTokenRegistrarProvider);

      authStateController.add(
        const AuthState(AuthChangeEvent.initialSession, null),
      );
      await pumpEventQueue();

      expect(gateway.getNotificationSettingsCallCount, 0);
      expect(repository.upsertedTokens, isEmpty);
    });

    test('rotation du jeton (onTokenRefresh) ré-enregistre sans revérifier la '
        'permission', () async {
      container.read(pushTokenRegistrarProvider);

      gateway.emitTokenRefresh('fcm-token-rotated');
      await pumpEventQueue();

      expect(repository.upsertedTokens, ['fcm-token-rotated']);
      expect(
        gateway.getNotificationSettingsCallCount,
        0,
        reason:
            'la rotation de jeton ne repasse jamais par la vérification '
            'de permission — voir la doc de classe.',
      );
    });

    test('un jeton FCM null (Google Play Services indisponible) n\'appelle '
        'jamais le repository', () async {
      gateway.settingsToReturn = _settings(AuthorizationStatus.authorized);
      gateway.tokenToReturn = null;
      container.read(pushTokenRegistrarProvider);

      authStateController.add(
        AuthState(AuthChangeEvent.initialSession, _fakeSession()),
      );
      await pumpEventQueue();

      expect(repository.upsertedTokens, isEmpty);
    });

    test('un échec du repository (RLS/réseau) reste silencieux, aucune '
        'exception ne remonte', () async {
      gateway.settingsToReturn = _settings(AuthorizationStatus.authorized);
      repository.errorToThrow = Exception('échec simulé (double de test)');
      container.read(pushTokenRegistrarProvider);

      authStateController.add(
        AuthState(AuthChangeEvent.initialSession, _fakeSession()),
      );
      // N'échoue jamais avec une exception non gérée : le simple fait que
      // ce pumpEventQueue() se termine sans lever prouve l'essentiel.
      await pumpEventQueue();
    });

    testWidgets(
      'tap sur une notification (onMessageOpenedApp) avec characterId '
      'route vers /characters/:id',
      (tester) async {
        final router = container.read(appRouterProvider);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        final registrar = container.read(pushTokenRegistrarProvider);
        addTearDown(registrar.dispose);

        gateway.emitMessageOpenedApp(
          const RemoteMessage(data: {'characterId': 'char-42'}),
        );
        await tester.pumpAndSettle();

        expect(find.text('character:char-42'), findsOneWidget);
      },
    );

    testWidgets('message reçu sans characterId dans data ne déclenche aucun '
        'routage', (tester) async {
      final router = container.read(appRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      container.read(pushTokenRegistrarProvider);

      gateway.emitMessageOpenedApp(const RemoteMessage(data: {}));
      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
    });

    testWidgets(
      'app lancée depuis une notification (getInitialMessage) route aussi '
      'vers /characters/:id',
      (tester) async {
        gateway.initialMessageToReturn = const RemoteMessage(
          data: {'characterId': 'char-7'},
        );
        final router = container.read(appRouterProvider);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        container.read(pushTokenRegistrarProvider);
        await tester.pumpAndSettle();

        expect(find.text('character:char-7'), findsOneWidget);
      },
    );

    test('dispose() annule tous les abonnements : plus aucun enregistrement '
        'déclenché après', () async {
      gateway.settingsToReturn = _settings(AuthorizationStatus.authorized);
      final registrar = container.read(pushTokenRegistrarProvider);

      registrar.dispose();
      authStateController.add(
        AuthState(AuthChangeEvent.signedIn, _fakeSession()),
      );
      gateway.emitTokenRefresh('fcm-token-after-dispose');
      await pumpEventQueue();

      expect(repository.upsertedTokens, isEmpty);
    });
  });
}

NotificationSettings _settings(AuthorizationStatus status) =>
    NotificationSettings(
      authorizationStatus: status,
      alert: AppleNotificationSetting.notSupported,
      announcement: AppleNotificationSetting.notSupported,
      badge: AppleNotificationSetting.notSupported,
      carPlay: AppleNotificationSetting.notSupported,
      criticalAlert: AppleNotificationSetting.notSupported,
      lockScreen: AppleNotificationSetting.notSupported,
      notificationCenter: AppleNotificationSetting.notSupported,
      showPreviews: AppleShowPreviewSetting.notSupported,
      timeSensitive: AppleNotificationSetting.notSupported,
      sound: AppleNotificationSetting.notSupported,
      providesAppNotificationSettings: AppleNotificationSetting.notSupported,
    );

Session _fakeSession() {
  return Session(
    accessToken: 'fake-access-token',
    tokenType: 'bearer',
    user: User(
      id: 'fake-user-id',
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: '2026-01-01T00:00:00Z',
    ),
  );
}

/// Routeur de test minimal — seule `/characters/:id` importe pour ces tests
/// (page vide en cible), route `/` comme accueil pour observer "aucun
/// routage déclenché" via `currentConfiguration.uri`.
GoRouter _testRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const Text('home')),
      GoRoute(
        path: '/characters/:id',
        builder: (context, state) =>
            Text('character:${state.pathParameters['id']}'),
      ),
    ],
  );
}

class _FakeAuthStateStream implements AuthStateStream {
  const _FakeAuthStateStream(this.onAuthStateChange);

  @override
  final Stream<AuthState> onAuthStateChange;
}

class _FakeGateway implements PushNotificationGateway {
  int requestPermissionCallCount = 0;
  int getNotificationSettingsCallCount = 0;
  int getTokenCallCount = 0;

  NotificationSettings settingsToReturn = _settings(AuthorizationStatus.denied);
  String? tokenToReturn = 'fcm-token-1';
  RemoteMessage? initialMessageToReturn;

  final _tokenRefreshController = StreamController<String>.broadcast();
  final _messageController = StreamController<RemoteMessage>.broadcast();
  final _openedAppController = StreamController<RemoteMessage>.broadcast();

  @override
  Future<NotificationSettings> requestPermission() async {
    requestPermissionCallCount++;
    return settingsToReturn;
  }

  @override
  Future<NotificationSettings> getNotificationSettings() async {
    getNotificationSettingsCallCount++;
    return settingsToReturn;
  }

  @override
  Future<String?> getToken() async {
    getTokenCallCount++;
    return tokenToReturn;
  }

  @override
  Stream<String> get onTokenRefresh => _tokenRefreshController.stream;

  @override
  Stream<RemoteMessage> get onMessage => _messageController.stream;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp => _openedAppController.stream;

  @override
  Future<RemoteMessage?> getInitialMessage() async => initialMessageToReturn;

  void emitTokenRefresh(String token) => _tokenRefreshController.add(token);

  void emitMessageOpenedApp(RemoteMessage message) =>
      _openedAppController.add(message);
}

class _FakeRepository implements PushTokenRepository {
  final List<String> upsertedTokens = [];
  Object? errorToThrow;

  @override
  Future<void> upsertToken({
    required String token,
    required String platform,
  }) async {
    final error = errorToThrow;
    if (error != null) throw error;
    upsertedTokens.add(token);
  }
}
