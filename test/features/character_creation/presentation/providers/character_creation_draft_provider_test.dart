// Tests unitaires de `CharacterCreationDraftController`, sur le contrôleur
// directement via un `ProviderContainer` (pas besoin de monter d'écran).
//
// Couvre en particulier la régression où `setRace` reconstruisait un
// brouillon entièrement neuf au lieu de fusionner via `copyWith` : un
// utilisateur revenant à l'étape 1 "Race" après avoir déjà choisi une classe
// à l'étape 2, puis retapant "Suivant" (même sans rien changer), perdait
// silencieusement `classId`.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/ability_score_method.dart';
import 'package:personnages/features/character_creation/presentation/providers/character_creation_draft_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  test('setRace après setClass conserve le classId déjà choisi '
      '(non-régression)', () {
    final controller = container.read(
      characterCreationDraftControllerProvider.notifier,
    );

    controller.setClass(classId: 42);
    controller.setRace(raceId: 7, subraceId: null, raceCustomText: null);

    final draft = container.read(characterCreationDraftControllerProvider);
    expect(draft.classId, 42);
    expect(draft.raceId, 7);
  });

  test('setRace efface bien subraceId et raceCustomText quand non fournis', () {
    final controller = container.read(
      characterCreationDraftControllerProvider.notifier,
    );

    controller.setRace(raceId: 1, subraceId: 2, raceCustomText: null);
    controller.setRace(raceId: 3, subraceId: null, raceCustomText: null);

    final draft = container.read(characterCreationDraftControllerProvider);
    expect(draft.raceId, 3);
    expect(draft.subraceId, isNull);
  });

  test('reset remet tout le brouillon à zéro, y compris classId', () {
    final controller = container.read(
      characterCreationDraftControllerProvider.notifier,
    );

    controller.setClass(classId: 1);
    controller.setRace(raceId: 2, subraceId: null, raceCustomText: null);
    controller.reset();

    final draft = container.read(characterCreationDraftControllerProvider);
    expect(draft.classId, isNull);
    expect(draft.raceId, isNull);
  });

  test('setRace puis setClass puis setBackground conservent les trois choix '
      '(non-régression, étape 3 "Historique")', () {
    final controller = container.read(
      characterCreationDraftControllerProvider.notifier,
    );

    controller.setRace(raceId: 7, subraceId: 3, raceCustomText: null);
    controller.setClass(classId: 42);
    controller.setBackground(backgroundId: 5);

    final draft = container.read(characterCreationDraftControllerProvider);
    expect(draft.raceId, 7);
    expect(draft.subraceId, 3);
    expect(draft.classId, 42);
    expect(draft.backgroundId, 5);
  });

  test('reset remet aussi backgroundId à zéro', () {
    final controller = container.read(
      characterCreationDraftControllerProvider.notifier,
    );

    controller.setBackground(backgroundId: 1);
    controller.reset();

    final draft = container.read(characterCreationDraftControllerProvider);
    expect(draft.backgroundId, isNull);
  });

  test(
    'setAbilityScores après setRace/setClass/setBackground conserve les '
    'choix déjà faits aux étapes précédentes (étape 4 "Caractéristiques")',
    () {
      final controller = container.read(
        characterCreationDraftControllerProvider.notifier,
      );

      controller.setRace(raceId: 7, subraceId: 3, raceCustomText: null);
      controller.setClass(classId: 42);
      controller.setBackground(backgroundId: 5);
      controller.setAbilityScores(
        method: AbilityScoreMethod.pointBuy,
        scores: const {
          'str': 15,
          'dex': 14,
          'con': 13,
          'int': 12,
          'wis': 10,
          'cha': 8,
        },
      );

      final draft = container.read(characterCreationDraftControllerProvider);
      expect(draft.raceId, 7);
      expect(draft.subraceId, 3);
      expect(draft.classId, 42);
      expect(draft.backgroundId, 5);
      expect(draft.abilityScoreMethod, AbilityScoreMethod.pointBuy);
      expect(draft.abilityScores, {
        'str': 15,
        'dex': 14,
        'con': 13,
        'int': 12,
        'wis': 10,
        'cha': 8,
      });
    },
  );

  test('reset remet aussi abilityScoreMethod/abilityScores à zéro', () {
    final controller = container.read(
      characterCreationDraftControllerProvider.notifier,
    );

    controller.setAbilityScores(
      method: AbilityScoreMethod.diceRoll,
      scores: const {'str': 10},
    );
    controller.reset();

    final draft = container.read(characterCreationDraftControllerProvider);
    expect(draft.abilityScoreMethod, isNull);
    expect(draft.abilityScores, isNull);
  });
}
