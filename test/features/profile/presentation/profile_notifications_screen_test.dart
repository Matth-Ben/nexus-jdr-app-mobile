// Tests de widget de l'écran "Préférences de notifications"
// (`presentation/profile_notifications_screen.dart`) : chargement/erreur/
// données, sous-interrupteurs grisés quand le global push est désactivé,
// bascule optimiste + revert sur échec, et demande de permission OS avant
// d'activer le global (accordée/refusée).
//
// `PushNotificationGateway`/`NotificationPreferencesRepository` sont tous
// deux des abstractions injectées via Riverpod — voir la doc de classe de
// `ProfileNotificationsScreen` — donc entièrement remplaçables par des
// doubles factices ici, sans jamais toucher au canal `firebase_messaging`
// réel (indisponible dans `flutter test`, voir `push_notification_gateway
// .dart`).

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:personnages/core/notifications/notification_providers.dart';
import 'package:personnages/core/notifications/push_notification_gateway.dart';
import 'package:personnages/features/profile/data/notification_preferences_repository.dart';
import 'package:personnages/features/profile/domain/notification_preferences.dart';
import 'package:personnages/features/profile/presentation/profile_notifications_screen.dart';
import 'package:personnages/features/profile/presentation/providers/notification_preferences_providers.dart';

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
    bool? emailDigestEnabled,
  }) async {
    if (updateCompleter != null) await updateCompleter!.future;
    final merged = current.copyWith(
      pushEnabled: pushEnabled,
      pushRestReminder: pushRestReminder,
      pushAccessRevoked: pushAccessRevoked,
      emailDigestEnabled: emailDigestEnabled,
    );
    final error = updateErrorToThrow;
    if (error != null) throw error;
    current = merged;
    updateCalls.add(merged);
    return merged;
  }
}

/// Double minimal — seul `requestPermission` est exercé par
/// `ProfileNotificationsScreen` (voir sa doc de classe : jamais aucun autre
/// membre de [PushNotificationGateway] appelé depuis cet écran).
class _FakePushNotificationGateway implements PushNotificationGateway {
  NotificationSettings? settingsToReturn;
  int requestPermissionCallCount = 0;

  @override
  Future<NotificationSettings> requestPermission() async {
    requestPermissionCallCount++;
    return settingsToReturn ?? _settings(AuthorizationStatus.authorized);
  }

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
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
    expect(find.text('NOTIFICATIONS PUSH'), findsNothing);
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
      expect(find.text('NOTIFICATIONS PUSH'), findsOneWidget);
    },
  );

  testWidgets('affiche les 2 groupes et les 4 rangées avec leurs valeurs', (
    tester,
  ) async {
    repository.current = const NotificationPreferences(
      pushEnabled: true,
      pushRestReminder: false,
      pushAccessRevoked: true,
      emailDigestEnabled: true,
    );

    await _pumpScreen(tester, repository: repository, gateway: gateway);

    expect(find.text('NOTIFICATIONS PUSH'), findsOneWidget);
    expect(find.text('EMAIL'), findsOneWidget);
    expect(find.text('Activer les notifications push'), findsOneWidget);
    expect(find.text('Rappel de repos long'), findsOneWidget);
    expect(find.text('Accès à une histoire retiré'), findsOneWidget);
    expect(find.text('Recevoir un résumé par email'), findsOneWidget);

    expect(_switchFor(tester, 'Activer les notifications push').value, isTrue);
    expect(_switchFor(tester, 'Rappel de repos long').value, isFalse);
    expect(_switchFor(tester, 'Accès à une histoire retiré').value, isTrue);
    expect(_switchFor(tester, 'Recevoir un résumé par email').value, isTrue);
  });

  testWidgets(
    'grise les 2 sous-interrupteurs push (onChanged null) quand le global '
    'push est désactivé, sans affecter le switch email',
    (tester) async {
      repository.current = const NotificationPreferences(pushEnabled: false);

      await _pumpScreen(tester, repository: repository, gateway: gateway);

      expect(_switchFor(tester, 'Rappel de repos long').onChanged, isNull);
      expect(
        _switchFor(tester, 'Accès à une histoire retiré').onChanged,
        isNull,
      );
      expect(
        _switchFor(tester, 'Recevoir un résumé par email').onChanged,
        isNotNull,
      );
    },
  );

  testWidgets(
    'bascule optimiste : le switch email reflète immédiatement le nouvel '
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
      expect(_switchFor(tester, 'Recevoir un résumé par email').value, isTrue);

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
      expect(_switchFor(tester, 'Recevoir un résumé par email').value, isTrue);

      repository.updateCompleter!.complete();
      await tester.pumpAndSettle();

      expect(_switchFor(tester, 'Recevoir un résumé par email').value, isFalse);
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
    expect(_switchFor(tester, 'Activer les notifications push').value, isTrue);
    expect(find.byType(Icon), findsWidgets);
    expect(
      find.textContaining('désactivées au niveau du téléphone'),
      findsNothing,
    );
  });

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
      expect(
        _switchFor(tester, 'Activer les notifications push').value,
        isFalse,
      );
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
