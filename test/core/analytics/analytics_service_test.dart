// Tests de `NoopAnalyticsService`/`CompositeAnalyticsService`
// (`lib/core/analytics/analytics_service.dart`) — résilience : aucune
// exception ne doit jamais remonter à l'appelant, que le SDK correspondant
// soit indisponible (flag à `false`) ou réellement invoqué sans avoir été
// configuré (`Firebase.initializeApp`/`Posthog().setup` jamais appelés dans
// ce harnais de test, donc `FirebaseAnalytics.instance`/`Posthog()` lèvent ou
// échouent silencieusement côté plateforme — exactement le cas que `_guard`
// doit absorber).
//
// Volontairement des `test()` simples (pas `testWidgets`) : `FlutterError
// .reportError` (appelé par `_guard` en cas d'échec SDK) ne fait échouer un
// test que sous le binding `flutter_test` d'un `testWidgets` (`tearDown`
// dédié) — en `test()` nu, il se contente de journaliser, ce qui permet
// d'exercer pour de vrai le chemin `firebaseAvailable`/`postHogAvailable:
// true` (donc un appel réel à `FirebaseAnalytics.instance`/`Posthog()`) sans
// faire échouer la suite. `TestWidgetsFlutterBinding.ensureInitialized()`
// (voir plus bas) reste nécessaire malgré tout : PostHog enregistre un
// gestionnaire de canal de plateforme dès son premier appel, qui a besoin
// d'un binding déjà initialisé pour ne pas lever en dehors du `try`/`catch`
// de `_guard`.

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/analytics/analytics_service.dart';

void main() {
  // Requis par le SDK PostHog (`posthog_flutter`), qui enregistre un
  // gestionnaire de canal de plateforme dès son premier appel — sans ce
  // binding, l'appel échoue avant même d'atteindre `_guard` (exception "the
  // binary messenger has been initialized" hors du `try`/`catch` couvert par
  // ce fichier). Avec le binding initialisé mais sans `Posthog().setup()`
  // réel, l'appel échoue proprement en `MissingPluginException` (aucun canal
  // enregistré), bien à l'intérieur du `try`/`catch` de `_guard` cette fois.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NoopAnalyticsService', () {
    const service = NoopAnalyticsService();

    test('isInitialized est toujours false', () {
      expect(service.isInitialized, isFalse);
    });

    test('trackEvent/trackScreen/setEnabled sont des no-op qui ne lèvent '
        'jamais', () async {
      await service.trackEvent('test_event', parameters: {'k': 'v'});
      await service.trackEvent('test_event_sans_parametres');
      await service.trackScreen('EcranDeTest');
      await service.setEnabled(false);
      await service.setEnabled(true);
    });
  });

  group('CompositeAnalyticsService', () {
    test('isInitialized reflète firebaseAvailable/postHogAvailable', () {
      expect(
        const CompositeAnalyticsService(
          firebaseAvailable: false,
          postHogAvailable: false,
        ).isInitialized,
        isFalse,
      );
      expect(
        const CompositeAnalyticsService(
          firebaseAvailable: true,
          postHogAvailable: false,
        ).isInitialized,
        isTrue,
      );
      expect(
        const CompositeAnalyticsService(
          firebaseAvailable: false,
          postHogAvailable: true,
        ).isInitialized,
        isTrue,
      );
    });

    test('aucun SDK disponible -> trackEvent/trackScreen/setEnabled sont des '
        'no-op qui ne lèvent jamais', () async {
      const service = CompositeAnalyticsService(
        firebaseAvailable: false,
        postHogAvailable: false,
      );

      await service.trackEvent('test_event', parameters: {'k': 'v'});
      await service.trackScreen('EcranDeTest');
      await service.setEnabled(false);
    });

    test(
      'firebaseAvailable: true sans Firebase.initializeApp réel -> échec '
      'de FirebaseAnalytics.instance absorbé par le guard, jamais propagé',
      () async {
        // Aucun `Firebase.initializeApp` n'a été appelé dans ce harnais de
        // test : `FirebaseAnalytics.instance` lève une `FirebaseException`
        // ("No Firebase App '[DEFAULT]' has been created") de façon
        // synchrone au premier accès — exactement le cas que `_guard` doit
        // intercepter sans jamais laisser remonter d'exception à l'appelant.
        const service = CompositeAnalyticsService(
          firebaseAvailable: true,
          postHogAvailable: false,
        );

        await service.trackEvent('test_event');
        await service.trackScreen('EcranDeTest');
        await service.setEnabled(true);
      },
    );

    test('postHogAvailable: true sans Posthog().setup réel -> échec de canal '
        'de plateforme absorbé par le guard, jamais propagé', () async {
      // Aucun `Posthog().setup` n'a été appelé : les appels natifs sous-
      // jacents échouent (`MissingPluginException` ou équivalent, aucun
      // canal de plateforme enregistré dans `flutter test`) — même
      // garantie de résilience que pour Firebase ci-dessus.
      const service = CompositeAnalyticsService(
        firebaseAvailable: false,
        postHogAvailable: true,
      );

      await service.trackEvent('test_event', parameters: {'k': 'v'});
      await service.trackScreen('EcranDeTest');
      await service.setEnabled(false);
    });
  });
}
