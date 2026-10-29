// Tests de `SpellPreparationFilterPreferenceController` — persistance
// `SharedPreferences` (mockée via `setMockInitialValues`, store en mémoire
// remis à zéro à chaque test) du filtre "Tous"/"Préparés"/"Non préparés" de
// l'onglet "Sorts" — même structure que
// `app_update/presentation/providers/update_banner_dismissal_provider_test.dart`,
// dont ce provider reprend le pattern.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/app_update/presentation/providers/update_banner_dismissal_provider.dart';
import 'package:personnages/features/characters/domain/spell_preparation_filter.dart';
import 'package:personnages/features/characters/presentation/providers/spell_preparation_filter_preference_provider.dart';
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

  test('rien de mémorisé au départ -> "Tous" (comportement antérieur '
      'inchangé)', () async {
    final container = buildContainer();

    // Laisse `sharedPreferencesProvider` (async) résoudre avant de lire
    // `build()`, qui retombe sinon momentanément sur `SpellPreparationFilter.all`
    // de toute façon (voir sa doc) — ici on veut vérifier l'état stabilisé.
    await container.read(sharedPreferencesProvider.future);

    expect(
      container.read(spellPreparationFilterPreferenceControllerProvider),
      SpellPreparationFilter.all,
    );
  });

  test(
    'setFilter met à jour le state immédiatement (sans attendre l\'écriture '
    'disque)',
    () async {
      final container = buildContainer();
      await container.read(sharedPreferencesProvider.future);

      // Volontairement pas d'`await` ici : `state` doit déjà refléter le
      // nouveau filtre avant même que l'écriture asynchrone ne se termine
      // (voir la doc de `setFilter`).
      final pending = container
          .read(spellPreparationFilterPreferenceControllerProvider.notifier)
          .setFilter(SpellPreparationFilter.prepared);

      expect(
        container.read(spellPreparationFilterPreferenceControllerProvider),
        SpellPreparationFilter.prepared,
      );

      await pending;
    },
  );

  test(
    'le choix persiste : un nouveau container relisant les mêmes '
    'SharedPreferences retrouve le même filtre',
    () async {
      final firstContainer = buildContainer();
      await firstContainer
          .read(spellPreparationFilterPreferenceControllerProvider.notifier)
          .setFilter(SpellPreparationFilter.unprepared);

      final secondContainer = buildContainer();
      await secondContainer.read(sharedPreferencesProvider.future);

      expect(
        secondContainer.read(spellPreparationFilterPreferenceControllerProvider),
        SpellPreparationFilter.unprepared,
      );
    },
  );

  test(
    'une valeur stockée invalide/inconnue (ex. ancienne version de l\'app) '
    'retombe sur "Tous" plutôt que de planter',
    () async {
      SharedPreferences.setMockInitialValues({
        'spell_preparation_filter_preference': 'valeur_inconnue',
      });
      final container = buildContainer();
      await container.read(sharedPreferencesProvider.future);

      expect(
        container.read(spellPreparationFilterPreferenceControllerProvider),
        SpellPreparationFilter.all,
      );
    },
  );
}
