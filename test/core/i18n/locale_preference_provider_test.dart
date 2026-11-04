// Tests de `LocalePreferenceController`
// (`lib/core/i18n/locale_preference_provider.dart`) — valeur par défaut
// `null` ("suit la langue du téléphone") si rien en `SharedPreferences`, mise
// à jour immédiate de `state` (avant même l'écriture disque), persistance
// entre deux `ProviderContainer`, retour à `null` (`remove`) quand on
// resélectionne "Langue du téléphone", et revert de `state` si l'écriture
// disque échoue — même patron que
// `test/core/analytics/analytics_preferences_provider_test.dart`.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/i18n/locale_preference_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// Store `SharedPreferences` en mémoire qui échoue sur toute écriture
/// (`setValue`/`remove`) — simule une écriture disque qui échoue (plein,
/// permission refusée...) pour vérifier que `LocalePreferenceController`
/// reverte bien `state` à sa valeur précédente plutôt que de rester
/// désynchronisé du disque (voir docstring de `setLocale`).
class _FailingSharedPreferencesStore extends InMemorySharedPreferencesStore {
  _FailingSharedPreferencesStore() : super.empty();

  @override
  Future<bool> setValue(String valueType, String key, Object value) {
    throw Exception('échec simulé de l\'écriture disque');
  }

  @override
  Future<bool> remove(String key) {
    throw Exception('échec simulé de l\'écriture disque');
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  ProviderContainer buildContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  test(
    'rien de persisté au départ -> suit la langue du téléphone (null)',
    () async {
      final container = buildContainer();
      await container.read(sharedPreferencesProvider.future);

      expect(container.read(localePreferenceControllerProvider), isNull);
    },
  );

  test("setLocale(Locale('en')) met à jour le state immédiatement (sans "
      "attendre l'écriture disque)", () async {
    final container = buildContainer();
    await container.read(sharedPreferencesProvider.future);

    final pending = container
        .read(localePreferenceControllerProvider.notifier)
        .setLocale(const Locale('en'));

    expect(
      container.read(localePreferenceControllerProvider),
      const Locale('en'),
    );

    await pending;
  });

  test('la préférence persiste : un nouveau container relisant les mêmes '
      'SharedPreferences retrouve la langue forcée', () async {
    final firstContainer = buildContainer();
    await firstContainer
        .read(localePreferenceControllerProvider.notifier)
        .setLocale(const Locale('fr'));

    final secondContainer = buildContainer();
    await secondContainer.read(sharedPreferencesProvider.future);

    expect(
      secondContainer.read(localePreferenceControllerProvider),
      const Locale('fr'),
    );
  });

  test('setLocale(null) efface la préférence persistée (retour à "suit la '
      'langue du téléphone")', () async {
    final container = buildContainer();
    await container
        .read(localePreferenceControllerProvider.notifier)
        .setLocale(const Locale('en'));

    await container
        .read(localePreferenceControllerProvider.notifier)
        .setLocale(null);

    expect(container.read(localePreferenceControllerProvider), isNull);

    final secondContainer = buildContainer();
    await secondContainer.read(sharedPreferencesProvider.future);
    expect(secondContainer.read(localePreferenceControllerProvider), isNull);
  });

  test('écriture disque en échec -> state reverté à sa valeur précédente '
      '(pas laissé sur la nouvelle valeur jamais persistée)', () async {
    SharedPreferencesStorePlatform.instance = _FailingSharedPreferencesStore();
    addTearDown(() {
      SharedPreferences.setMockInitialValues({});
    });

    final container = buildContainer();
    await container.read(sharedPreferencesProvider.future);

    expect(container.read(localePreferenceControllerProvider), isNull);

    await expectLater(
      container
          .read(localePreferenceControllerProvider.notifier)
          .setLocale(const Locale('en')),
      throwsException,
    );

    expect(container.read(localePreferenceControllerProvider), isNull);
  });
}
