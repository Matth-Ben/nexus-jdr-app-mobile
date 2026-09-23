// Tests de `AnalyticsPreferencesController`
// (`lib/core/analytics/analytics_preferences_provider.dart`) — valeur par
// défaut `true` (activé) si rien en `SharedPreferences`, mise à jour
// immédiate de `state` (avant même l'écriture disque), persistance entre
// deux `ProviderContainer`, et notification de l'`AnalyticsService` sous-
// jacent (`setEnabled`) à chaque bascule — mêmes garanties que
// `UpdateBannerDismissalController`
// (`test/features/app_update/presentation/providers/update_banner_dismissal_provider_test.dart`),
// plus la propagation vers `AnalyticsService`.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/analytics/analytics_preferences_provider.dart';
import 'package:personnages/core/analytics/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enregistre les appels reçus pour assertions — voir la doc de classe
/// d'`AnalyticsService` : "FakeAnalyticsService dans les tests si besoin".
class _FakeAnalyticsService implements AnalyticsService {
  final List<bool> setEnabledCalls = [];

  @override
  bool get isInitialized => true;

  @override
  Future<void> trackEvent(
    String name, {
    Map<String, Object?> parameters = const {},
  }) async {}

  @override
  Future<void> trackScreen(String screenName) async {}

  @override
  Future<void> setEnabled(bool enabled) async {
    setEnabledCalls.add(enabled);
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  ProviderContainer buildContainer({AnalyticsService? analyticsService}) {
    final container = ProviderContainer(
      overrides: [
        if (analyticsService != null)
          analyticsServiceProvider.overrideWithValue(analyticsService),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('rien de persisté au départ -> activé par défaut (true)', () async {
    final container = buildContainer();
    await container.read(sharedPreferencesProvider.future);

    expect(container.read(analyticsPreferencesControllerProvider), isTrue);
  });

  test('setEnabled(false) met à jour le state immédiatement (sans attendre '
      "l'écriture disque ni l'appel au SDK)", () async {
    final fake = _FakeAnalyticsService();
    final container = buildContainer(analyticsService: fake);
    await container.read(sharedPreferencesProvider.future);

    final pending = container
        .read(analyticsPreferencesControllerProvider.notifier)
        .setEnabled(false);

    expect(container.read(analyticsPreferencesControllerProvider), isFalse);

    await pending;
  });

  test('la préférence persiste : un nouveau container relisant les mêmes '
      'SharedPreferences retrouve la valeur désactivée', () async {
    final firstContainer = buildContainer(
      analyticsService: _FakeAnalyticsService(),
    );
    await firstContainer
        .read(analyticsPreferencesControllerProvider.notifier)
        .setEnabled(false);

    final secondContainer = buildContainer();
    await secondContainer.read(sharedPreferencesProvider.future);

    expect(
      secondContainer.read(analyticsPreferencesControllerProvider),
      isFalse,
    );
  });

  test('setEnabled répercute la bascule sur AnalyticsService.setEnabled '
      '(pas juste un guard côté Dart)', () async {
    final fake = _FakeAnalyticsService();
    final container = buildContainer(analyticsService: fake);

    await container
        .read(analyticsPreferencesControllerProvider.notifier)
        .setEnabled(false);
    await container
        .read(analyticsPreferencesControllerProvider.notifier)
        .setEnabled(true);

    expect(fake.setEnabledCalls, [false, true]);
  });

  group('analyticsServiceProvider (build réel, pas overrideWithValue de ce '
      'provider lui-même) : reflète bien analyticsAvailabilityProvider', () {
    test('sans surcharge de analyticsAvailabilityProvider -> '
        'CompositeAnalyticsService avec les deux SDK indisponibles '
        '(valeur par défaut AnalyticsAvailability.none)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service =
          container.read(analyticsServiceProvider) as CompositeAnalyticsService;

      expect(service.firebaseAvailable, isFalse);
      expect(service.postHogAvailable, isFalse);
      expect(service.isInitialized, isFalse);
    });

    test('avec analyticsAvailabilityProvider surchargé -> '
        'CompositeAnalyticsService reflète exactement cette disponibilité '
        '(même mécanisme que `AppBootstrap._wrapChild`, `main.dart`)', () {
      final container = ProviderContainer(
        overrides: [
          analyticsAvailabilityProvider.overrideWithValue(
            const AnalyticsAvailability(
              firebaseAnalyticsReady: true,
              postHogReady: false,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final service =
          container.read(analyticsServiceProvider) as CompositeAnalyticsService;

      expect(service.firebaseAvailable, isTrue);
      expect(service.postHogAvailable, isFalse);
      expect(service.isInitialized, isTrue);
    });
  });
}
