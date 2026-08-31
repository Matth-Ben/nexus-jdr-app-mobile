// Tests unitaires de `CharacterCreationReturnRouteController` — voir sa
// documentation de classe pour le rationale (route de retour paramétrable de
// l'assistant de création, consommée par `summary_step_screen.dart`).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_return_route_provider.dart';

void main() {
  test('null par défaut', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(characterCreationReturnRouteControllerProvider),
      isNull,
    );
  });

  test('set() met à jour la valeur exposée', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(characterCreationReturnRouteControllerProvider.notifier)
        .set('/join/step-3?code=AB3F7K');

    expect(
      container.read(characterCreationReturnRouteControllerProvider),
      '/join/step-3?code=AB3F7K',
    );
  });

  test('consume() retourne la valeur puis la remet à null', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(
      characterCreationReturnRouteControllerProvider.notifier,
    );
    notifier.set('/join/step-3?code=AB3F7K');

    final consumed = notifier.consume();

    expect(consumed, '/join/step-3?code=AB3F7K');
    expect(
      container.read(characterCreationReturnRouteControllerProvider),
      isNull,
    );
  });

  test('consume() sur une valeur déjà null retourne null sans planter', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(
      characterCreationReturnRouteControllerProvider.notifier,
    );

    expect(notifier.consume(), isNull);
    expect(
      container.read(characterCreationReturnRouteControllerProvider),
      isNull,
    );
  });
}
