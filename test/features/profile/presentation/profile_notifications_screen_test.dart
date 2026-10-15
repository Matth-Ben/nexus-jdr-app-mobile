// Tests de widget de l'écran "Préférences de notifications"
// (`presentation/profile_notifications_screen.dart`) : chargement/erreur/
// données, groupe "DÉCLENCHEURS" (3 rangées regroupées dans un
// `SettingsListCard` — voir la doc de classe de
// `ProfileNotificationsScreen`), rangées grisées quand "Notifications push"
// est désactivé, bascule optimiste + revert sur échec, demande de
// permission OS avant d'activer le global (accordée/refusée), et texte
// d'aide en pied d'écran.
//
// `PushNotificationGateway`/`NotificationPreferencesRepository` sont tous
// deux des abstractions injectées via Riverpod — voir la doc de classe de
// `ProfileNotificationsScreen` — donc entièrement remplaçables par des
// doubles factices ici, sans jamais toucher au canal `firebase_messaging`
// réel (indisponible dans `flutter test`, voir `push_notification_gateway
// .dart`).
//
// Activer le switch global lit désormais aussi `pushTokenRegistrarProvider`
// (`core/notifications/push_token_registrar.dart::registerTokenNow`, voir sa
// doc de classe pour le rationale complet du bug corrigé) — ce qui démarre
// pour la première fois (`PushTokenRegistrar.start()`, `keepAlive`)
// l'ensemble de ses abonnements dans CE test, contrairement à l'app réelle où
// `main.dart` l'a déjà fait tôt. `_FakePushNotificationGateway` implémente
// donc entièrement l'interface (plus de `noSuchMethod`) et
// `authStateStreamProvider`/`pushTokenRepositoryProvider` sont overridés ici
// aussi, même si la plupart des tests de ce fichier ne les exercent jamais.

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/notifications/notification_providers.dart';
import 'package:personnages/core/notifications/push_notification_gateway.dart';
import 'package:personnages/core/notifications/push_token_repository.dart';
import 'package:personnages/core/widgets/settings_list_card.dart';
import 'package:personnages/features/auth/data/auth_state_stream.dart';
import 'package:personnages/features/auth/presentation/providers/auth_providers.dart';
import 'package:personnages/features/profile/data/notification_preferences_repository.dart';
import 'package:personnages/features/profile/domain/notification_preferences.dart';
import 'package:personnages/features/profile/presentation/profile_notifications_screen.dart';
import 'package:personnages/features/profile/presentation/providers/notification_preferences_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeNotificationPreferencesRepository
    implements NotificationPreferencesRepository {
  NotificationPreferences current = const NotificationPreferences.defaults();
  Completer<NotificationPreferences>? fetchCompleter;
  Object? fetchErrorToThrow;
  int fetchCallCount = 0;

  Object? updateErrorToThrow;
  Completer<void>? updateCompleter;
  final List<NotificationPreferences> updateCalls = [];

  @override
  Future<NotificationPreferences> fetch() async {
    fetchCallCount++;
    if (fetchCompleter != null) return fetchCompleter!.future;
    final error = fetchErrorToThrow;
    if (error != null) throw error;
    return current;
  }

  @override
  Future<NotificationPreferences> update({
    bool? pushEnabled,
    bool? pushRestReminder,
    bool? pushAccessRevoked,
    bool? pushNewVersionAvailable,
    bool? emailDigestEnabled,
  }) async {
    if (updateCompleter != null) await updateCompleter!.future;
    final merged = current.copyWith(
      pushEnabled: pushEnabled,
      pushRestReminder: pushRestReminder,
      pushAccessRevoked: pushAccessRevoked,
      pushNewVersionAvailable: pushNewVersionAvailable,
      emailDigestEnabled: emailDigestEnabled,
    );
    final error = updateErrorToThrow;
    if (error != null) throw error;
    current = merged;
    updateCalls.add(merged);
    return merged;
  }
}

/// `ProfileNotificationsScreen` n'appelle directement que
/// `requestPermission` (voir sa doc de classe), mais ce double doit aussi
/// satisfaire `PushTokenRegistrar.start()`/`registerTokenNow()` — lus
/// indirectement via `pushTokenRegistrarProvider` dès qu'un test active le
/// switch global avec permission accordée (voir l'en-tête de ce fichier) —
/// d'où une implémentation complète plutôt qu'un `noSuchMethod` partiel.
class _FakePushNotificationGateway implements PushNotificationGateway {
  NotificationSettings? settingsToReturn;
  int requestPermissionCallCount = 0;
  int getTokenCallCount = 0;

  /// Jeton renvoyé par [getToken] — `null` simule l'absence de Google Play
  /// Services (voir [PushNotificationGateway.getToken]).
  String? tokenToReturn = 'fcm-token-widget-test';

  final _tokenRefreshController = StreamController<String>.broadcast();
  final _messageController = StreamController<RemoteMessage>.broadcast();
  final _openedAppController = StreamController<RemoteMessage>.broadcast();

  @override
  Future<NotificationSettings> requestPermission() async {
    requestPermissionCallCount++;
    return settingsToReturn ?? _settings(AuthorizationStatus.authorized);
  }

  @override
  Future<NotificationSettings> getNotificationSettings() async =>
      settingsToReturn ?? _settings(AuthorizationStatus.authorized);

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
  Future<RemoteMessage?> getInitialMessage() async => null;
}

/// Flux d'auth vide — `PushTokenRegistrar.start()` s'y abonne dès la
/// première lecture de `pushTokenRegistrarProvider` (voir l'en-tête de ce
/// fichier), mais aucun test de cet écran n'a besoin d'y émettre quoi que ce
/// soit : seul l'appel explicite `registerTokenNow()` est exercé ici, jamais
/// la détection `signedIn`/`initialSession` (déjà couverte par
/// `push_token_registrar_test.dart`).
class _FakeAuthStateStream implements AuthStateStream {
  @override
  Stream<AuthState> get onAuthStateChange => const Stream.empty();
}

/// Double de `PushTokenRepository` — permet de vérifier qu'activer le
/// switch global enregistre bien un jeton (voir
/// `push_token_registrar_test.dart` pour le double équivalent, même
/// patron).
class _FakePushTokenRepository implements PushTokenRepository {
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

NotificationSettings _settings(AuthorizationStatus status) {
  return NotificationSettings(
    authorizationStatus: status,
    alert: AppleNotificationSetting.notSupported,
    announcement: AppleNotificationSetting.notSupported,
    badge: AppleNotificationSetting.notSupported,
    carPlay: AppleNotificationSetting.notSupported,
    lockScreen: AppleNotificationSetting.notSupported,
    notificationCenter: AppleNotificationSetting.notSupported,
    showPreviews: AppleShowPreviewSetting.notSupported,
    timeSensitive: AppleNotificationSetting.notSupported,
    criticalAlert: AppleNotificationSetting.notSupported,
    sound: AppleNotificationSetting.notSupported,
    providesAppNotificationSettings: AppleNotificationSetting.notSupported,
  );
}

Switch _switchFor(WidgetTester tester, String title) {
  final row = find.ancestor(of: find.text(title), matching: find.byType(Row));
  return tester.widget<Switch>(
    find.descendant(of: row, matching: find.byType(Switch)),
  );
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _FakeNotificationPreferencesRepository repository,
  required _FakePushNotificationGateway gateway,
  // `null` -> un double neuf, jamais interrogé par la plupart des tests de ce
  // fichier (seuls ceux qui activent le switch global avec permission
  // accordée déclenchent `registerTokenNow()`, voir l'en-tête de ce fichier).
  _FakePushTokenRepository? pushTokenRepository,
  // `false` pour le test d'état de chargement : un `CircularProgressIndicator`
  // anime indéfiniment tant que `fetchCompleter` n'est pas résolu, ce qui
  // ferait tourner `pumpAndSettle` à l'infini (jamais "settled").
  bool settle = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        notificationPreferencesRepositoryProvider.overrideWithValue(repository),
        pushNotificationGatewayProvider.overrideWithValue(gateway),
        pushTokenRepositoryProvider.overrideWithValue(
          pushTokenRepository ?? _FakePushTokenRepository(),
        ),
        authStateStreamProvider.overrideWithValue(_FakeAuthStateStream()),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => context.push('/profile/notifications'),
                    child: const Text('Ouvrir'),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: '/profile/notifications',
              builder: (context, state) => const ProfileNotificationsScreen(),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // Laisse la transition de navigation (`GoRoute.push`) se terminer sans
    // attendre l'arrêt de toute animation (voir la doc de [settle]).
    await tester.pump(const Duration(milliseconds: 300));
  }
}

void main() {
  late _FakeNotificationPreferencesRepository repository;
  late _FakePushNotificationGateway gateway;

  setUp(() {
    repository = _FakeNotificationPreferencesRepository();
    gateway = _FakePushNotificationGateway();
  });

  testWidgets('affiche un indicateur de chargement pendant la récupération', (
    tester,
  ) async {
    repository.fetchCompleter = Completer<NotificationPreferences>();

    await _pumpScreen(
      tester,
      repository: repository,
      gateway: gateway,
      settle: false,
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('DÉCLENCHEURS'), findsNothing);
  });

  testWidgets(
    'affiche un état d\'erreur avec un bouton "Réessayer" qui relance la '
    'requête',
    (tester) async {
      repository.fetchErrorToThrow = Exception('boom');

      await _pumpScreen(tester, repository: repository, gateway: gateway);

      expect(
        find.text(
          'Impossible de charger tes préférences de notifications. '
          'Réessaie.',
        ),
        findsOneWidget,
      );
      expect(repository.fetchCallCount, 1);

      repository.fetchErrorToThrow = null;
      await tester.tap(find.text('RÉESSAYER'));
      await tester.pumpAndSettle();

      expect(repository.fetchCallCount, 2);
      expect(find.text('DÉCLENCHEURS'), findsOneWidget);
    },
  );

  testWidgets(
    'affiche les 2 groupes ("DÉCLENCHEURS"/"E-MAIL") et les 5 rangées avec '
    'leurs valeurs, sans en-tête ni icône sur "Notifications push"',
    (tester) async {
      repository.current = const NotificationPreferences(
        pushEnabled: true,
        pushRestReminder: false,
        pushAccessRevoked: true,
        pushNewVersionAvailable: false,
        emailDigestEnabled: true,
      );

      await _pumpScreen(tester, repository: repository, gateway: gateway);

      expect(find.text('DÉCLENCHEURS'), findsOneWidget);
      expect(find.text('E-MAIL'), findsOneWidget);
      expect(find.text('NOTIFICATIONS PUSH'), findsNothing);
      expect(find.text('EMAIL'), findsNothing);
      expect(find.text('Notifications push'), findsOneWidget);
      expect(find.text('Invitation à rejoindre une histoire'), findsNothing);
      expect(find.text('Repos long non pris depuis longtemps'), findsOneWidget);
      expect(find.text('Accès retiré ou modifié par le MJ'), findsOneWidget);
      expect(find.text('Nouvelle mise à jour disponible'), findsOneWidget);
      expect(find.text('Recevoir un résumé par e-mail'), findsOneWidget);

      // Icônes dédiées des 3 rangées "DÉCLENCHEURS", dans cet ordre — le
      // groupe ne contient plus "Invitation à rejoindre une histoire"
      // (retrait, décision chef de projet du 13/09/2026).
      expect(find.byIcon(Icons.arrow_forward), findsNothing);
      expect(find.byIcon(Icons.star_outline), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_outlined), findsOneWidget);
      expect(find.byIcon(Icons.file_download_outlined), findsOneWidget);
      final settingsListCard = find.byType(SettingsListCard);
      expect(settingsListCard, findsOneWidget);
      expect(
        find.descendant(of: settingsListCard, matching: find.byType(Switch)),
        findsNWidgets(3),
      );

      expect(_switchFor(tester, 'Notifications push').value, isTrue);
      expect(
        _switchFor(tester, 'Repos long non pris depuis longtemps').value,
        isFalse,
      );
      expect(
        _switchFor(tester, 'Accès retiré ou modifié par le MJ').value,
        isTrue,
      );
      expect(
        _switchFor(tester, 'Nouvelle mise à jour disponible').value,
        isFalse,
      );
      expect(_switchFor(tester, 'Recevoir un résumé par e-mail').value, isTrue);
    },
  );

  testWidgets(
    'affiche le texte d\'aide centré sur les autorisations système en pied '
    'd\'écran',
    (tester) async {
      await _pumpScreen(tester, repository: repository, gateway: gateway);

      expect(
        find.text(
          'Les autorisations système (notifications) se gèrent aussi '
          'depuis les réglages du téléphone.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('grise les 3 rangées "DÉCLENCHEURS" adossées à une préférence '
      '(onChanged null) quand "Notifications push" est désactivé, sans '
      'affecter le switch e-mail', (tester) async {
    repository.current = const NotificationPreferences(pushEnabled: false);

    await _pumpScreen(tester, repository: repository, gateway: gateway);

    expect(
      _switchFor(tester, 'Repos long non pris depuis longtemps').onChanged,
      isNull,
    );
    expect(
      _switchFor(tester, 'Accès retiré ou modifié par le MJ').onChanged,
      isNull,
    );
    expect(
      _switchFor(tester, 'Nouvelle mise à jour disponible').onChanged,
      isNull,
    );
    expect(
      _switchFor(tester, 'Recevoir un résumé par e-mail').onChanged,
      isNotNull,
    );
  });

  testWidgets(
    '"Nouvelle mise à jour disponible" bascule pushNewVersionAvailable '
    'quand "Notifications push" est activé',
    (tester) async {
      repository.current = const NotificationPreferences(
        pushNewVersionAvailable: false,
      );

      await _pumpScreen(tester, repository: repository, gateway: gateway);

      await tester.tap(
        find.descendant(
          of: find.ancestor(
            of: find.text('Nouvelle mise à jour disponible'),
            matching: find.byType(Row),
          ),
          matching: find.byType(Switch),
        ),
      );
      await tester.pumpAndSettle();

      expect(repository.updateCalls.single.pushNewVersionAvailable, isTrue);
      expect(
        _switchFor(tester, 'Nouvelle mise à jour disponible').value,
        isTrue,
      );
    },
  );

  testWidgets(
    'bascule optimiste : le switch e-mail reflète immédiatement le nouvel '
    'état, avant même la réponse du repository',
    (tester) async {
      repository.current = const NotificationPreferences(
        emailDigestEnabled: false,
      );
      repository.updateCompleter = Completer<void>();
      await _pumpScreen(tester, repository: repository, gateway: gateway);

      await tester.tap(find.byType(Switch).last);
      await tester.pump();

      // `update` n'est pas encore résolu (complété plus bas) : le switch
      // reflète déjà `true` grâce à `_optimistic`, jamais la valeur fetchée.
      expect(_switchFor(tester, 'Recevoir un résumé par e-mail').value, isTrue);

      repository.updateCompleter!.complete();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'un échec du repository fait revenir le switch à sa valeur précédente '
    'et affiche un SnackBar générique',
    (tester) async {
      repository.current = const NotificationPreferences(
        emailDigestEnabled: false,
      );
      repository.updateErrorToThrow = Exception('network down');
      // Bloque `update` le temps de vérifier l'état optimiste : sinon le
      // rejet (déjà résolu, aucun `await` réel dans le double) traverserait
      // entièrement `_toggle` (`setState` optimiste + `catch` + revert)
      // pendant les micro-tâches internes de `tester.tap`, avant qu'aucune
      // assertion n'ait la moindre chance de voir l'état intermédiaire.
      repository.updateCompleter = Completer<void>();
      await _pumpScreen(tester, repository: repository, gateway: gateway);

      await tester.tap(find.byType(Switch).last);
      await tester.pump();
      expect(_switchFor(tester, 'Recevoir un résumé par e-mail').value, isTrue);

      repository.updateCompleter!.complete();
      await tester.pumpAndSettle();

      expect(
        _switchFor(tester, 'Recevoir un résumé par e-mail').value,
        isFalse,
      );
      expect(
        find.text("Impossible d'enregistrer ce réglage. Réessaie."),
        findsOneWidget,
      );
    },
  );

  testWidgets('activer le global push demande la permission OS puis écrit '
      'push_enabled: true si accordée', (tester) async {
    repository.current = const NotificationPreferences(pushEnabled: false);
    gateway.settingsToReturn = _settings(AuthorizationStatus.authorized);
    await _pumpScreen(tester, repository: repository, gateway: gateway);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(gateway.requestPermissionCallCount, 1);
    expect(repository.updateCalls.single.pushEnabled, isTrue);
    expect(_switchFor(tester, 'Notifications push').value, isTrue);
    expect(find.byType(Icon), findsWidgets);
    expect(
      find.textContaining('désactivées au niveau du téléphone'),
      findsNothing,
    );
  });

  testWidgets(
    'activer le global push accordé enregistre aussi le jeton FCM tout de '
    "suite — sans attendre un redémarrage de l'app (bug corrigé, voir la "
    'doc de classe de PushTokenRegistrar.registerTokenNow)',
    (tester) async {
      repository.current = const NotificationPreferences(pushEnabled: false);
      gateway.settingsToReturn = _settings(AuthorizationStatus.authorized);
      final tokenRepository = _FakePushTokenRepository();

      await _pumpScreen(
        tester,
        repository: repository,
        gateway: gateway,
        pushTokenRepository: tokenRepository,
      );

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(repository.updateCalls.single.pushEnabled, isTrue);
      expect(gateway.getTokenCallCount, 1);
      expect(tokenRepository.upsertedTokens, ['fcm-token-widget-test']);
    },
  );

  testWidgets(
    "un échec de l'enregistrement du jeton FCM n'empêche pas la préférence "
    "push_enabled de s'enregistrer, ni n'affiche d'erreur pour ce point "
    'précis (best-effort)',
    (tester) async {
      repository.current = const NotificationPreferences(pushEnabled: false);
      gateway.settingsToReturn = _settings(AuthorizationStatus.authorized);
      final tokenRepository = _FakePushTokenRepository()
        ..errorToThrow = Exception('RPC indisponible (double de test)');

      await _pumpScreen(
        tester,
        repository: repository,
        gateway: gateway,
        pushTokenRepository: tokenRepository,
      );

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(repository.updateCalls.single.pushEnabled, isTrue);
      expect(_switchFor(tester, 'Notifications push').value, isTrue);
      expect(tokenRepository.upsertedTokens, isEmpty);
      expect(
        find.text("Impossible d'enregistrer ce réglage. Réessaie."),
        findsNothing,
      );
    },
  );

  testWidgets(
    'activer le global push avec permission refusée : rien écrit en base, '
    'un AlertBanner explicatif apparaît',
    (tester) async {
      repository.current = const NotificationPreferences(pushEnabled: false);
      gateway.settingsToReturn = _settings(AuthorizationStatus.denied);
      await _pumpScreen(tester, repository: repository, gateway: gateway);

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(gateway.requestPermissionCallCount, 1);
      expect(repository.updateCalls, isEmpty);
      expect(_switchFor(tester, 'Notifications push').value, isFalse);
      expect(
        find.textContaining('désactivées au niveau du téléphone'),
        findsOneWidget,
      );
    },
  );

  testWidgets('désactiver le global push ne demande jamais la permission OS', (
    tester,
  ) async {
    repository.current = const NotificationPreferences(pushEnabled: true);
    await _pumpScreen(tester, repository: repository, gateway: gateway);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(gateway.requestPermissionCallCount, 0);
    expect(repository.updateCalls.single.pushEnabled, isFalse);
  });
}
