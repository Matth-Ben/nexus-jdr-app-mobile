// Tests de `UpdateBannerDismissalController` — persistance
// `SharedPreferences` (mockée via `setMockInitialValues`, store en mémoire
// remis à zéro à chaque test) de la version de bannière refermée.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/app_update/presentation/providers/update_banner_dismissal_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  ProviderContainer buildContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  test('rien de refermé au départ -> state null', () async {
    final container = buildContainer();

    // Laisse `sharedPreferencesProvider` (async) résoudre avant de lire
    // `build()`, qui retombe sinon momentanément sur `null` de toute façon
    // (voir sa doc) — ici on veut vérifier l'état stabilisé.
    await container.read(sharedPreferencesProvider.future);

    expect(container.read(updateBannerDismissalControllerProvider), isNull);
  });

  test('dismiss(version) met à jour le state immédiatement (sans attendre '
      'l\'écriture disque)', () async {
    final container = buildContainer();
    await container.read(sharedPreferencesProvider.future);

    // Volontairement pas d'`await` ici : `state` doit déjà refléter la
    // fermeture avant même que l'écriture asynchrone ne se termine (voir
    // la doc de `dismiss`).
    final pending = container
        .read(updateBannerDismissalControllerProvider.notifier)
        .dismiss('0.5.0');

    expect(container.read(updateBannerDismissalControllerProvider), '0.5.0');

    await pending;
  });

  test('la fermeture persiste : un nouveau container relisant les mêmes '
      'SharedPreferences retrouve la version refermée', () async {
    final firstContainer = buildContainer();
    await firstContainer
        .read(updateBannerDismissalControllerProvider.notifier)
        .dismiss('0.5.0');

    final secondContainer = buildContainer();
    await secondContainer.read(sharedPreferencesProvider.future);

    expect(
      secondContainer.read(updateBannerDismissalControllerProvider),
      '0.5.0',
    );
  });

  test('une NOUVELLE version différente de celle refermée n\'est pas '
      'considérée comme refermée (comparaison stricte par version)', () async {
    final container = buildContainer();
    await container
        .read(updateBannerDismissalControllerProvider.notifier)
        .dismiss('0.5.0');

    expect(
      container.read(updateBannerDismissalControllerProvider),
      isNot('0.6.0'),
    );
  });
}
