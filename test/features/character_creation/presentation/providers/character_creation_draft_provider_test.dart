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
import 'package:personnages/features/character_creation/domain/equipment_choice_tab.dart';
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

  test('setEquipment après setBackground conserve backgroundId (étape 7 '
      '"Équipement de départ")', () {
    final controller = container.read(
      characterCreationDraftControllerProvider.notifier,
    );

    controller.setBackground(backgroundId: 5);
    controller.setEquipment(
      activeTab: EquipmentChoiceTab.purchase,
      purchasedEquipment: const {'Dague': 2},
    );

    final draft = container.read(characterCreationDraftControllerProvider);
    expect(draft.backgroundId, 5);
    expect(draft.equipmentChoiceTab, EquipmentChoiceTab.purchase);
    expect(draft.purchasedEquipment, {'Dague': 2});
  });

  test('setEquipment avec l\'onglet "Historique" retenu conserve quand même '
      'un panier "Acheter" non vide (choix mutuellement exclusif porté par '
      'equipmentChoiceTab, pas par la présence du panier)', () {
    final controller = container.read(
      characterCreationDraftControllerProvider.notifier,
    );

    controller.setEquipment(
      activeTab: EquipmentChoiceTab.background,
      purchasedEquipment: const {'Dague': 1},
    );

    final draft = container.read(characterCreationDraftControllerProvider);
    expect(draft.equipmentChoiceTab, EquipmentChoiceTab.background);
    expect(draft.purchasedEquipment, {'Dague': 1});
  });

  test('reset remet aussi equipmentChoiceTab/purchasedEquipment à zéro', () {
    final controller = container.read(
      characterCreationDraftControllerProvider.notifier,
    );

    controller.setEquipment(
      activeTab: EquipmentChoiceTab.purchase,
      purchasedEquipment: const {'Dague': 1},
    );
    controller.reset();

    final draft = container.read(characterCreationDraftControllerProvider);
    expect(draft.equipmentChoiceTab, isNull);
    expect(draft.purchasedEquipment, isEmpty);
  });

  test('setAppearanceAndBackstory après setClass/setBackground conserve les '
      'choix déjà faits aux étapes précédentes (étape 8 "Apparence, histoire '
      'et portrait")', () {
    final controller = container.read(
      characterCreationDraftControllerProvider.notifier,
    );

    controller.setClass(classId: 42);
    controller.setBackground(backgroundId: 5);
    controller.setAppearanceAndBackstory(
      appearanceText: 'Grand et mince',
      traitsText: 'Curieux',
      idealsText: 'La justice',
      bondsText: 'Sa famille',
      flawsText: 'Trop confiant',
      backstoryText: 'Né dans un village isolé',
      alliesText: 'La guilde des marchands',
      featuresText: 'Une cicatrice au visage',
      treasureText: 'Une amulette ancienne',
    );

    final draft = container.read(characterCreationDraftControllerProvider);
    expect(draft.classId, 42);
    expect(draft.backgroundId, 5);
    expect(draft.appearanceText, 'Grand et mince');
    expect(draft.traitsText, 'Curieux');
    expect(draft.idealsText, 'La justice');
    expect(draft.bondsText, 'Sa famille');
    expect(draft.flawsText, 'Trop confiant');
    expect(draft.backstoryText, 'Né dans un village isolé');
    expect(draft.alliesText, 'La guilde des marchands');
    expect(draft.featuresText, 'Une cicatrice au visage');
    expect(draft.treasureText, 'Une amulette ancienne');
  });

  test('setAppearanceAndBackstory accepte des valeurs null (champ jamais '
      'renseigné) sans planter', () {
    final controller = container.read(
      characterCreationDraftControllerProvider.notifier,
    );

    controller.setAppearanceAndBackstory(
      appearanceText: null,
      traitsText: null,
      idealsText: null,
      bondsText: null,
      flawsText: null,
      backstoryText: null,
      alliesText: null,
      featuresText: null,
      treasureText: null,
    );

    final draft = container.read(characterCreationDraftControllerProvider);
    expect(draft.appearanceText, isNull);
    expect(draft.treasureText, isNull);
  });

  test('reset remet aussi les 9 champs texte de l\'étape 8 à zéro', () {
    final controller = container.read(
      characterCreationDraftControllerProvider.notifier,
    );

    controller.setAppearanceAndBackstory(
      appearanceText: 'Grand et mince',
      traitsText: 'Curieux',
      idealsText: 'La justice',
      bondsText: 'Sa famille',
      flawsText: 'Trop confiant',
      backstoryText: 'Né dans un village isolé',
      alliesText: 'La guilde des marchands',
      featuresText: 'Une cicatrice au visage',
      treasureText: 'Une amulette ancienne',
    );
    controller.reset();

    final draft = container.read(characterCreationDraftControllerProvider);
    expect(draft.appearanceText, isNull);
    expect(draft.traitsText, isNull);
    expect(draft.idealsText, isNull);
    expect(draft.bondsText, isNull);
    expect(draft.flawsText, isNull);
    expect(draft.backstoryText, isNull);
    expect(draft.alliesText, isNull);
    expect(draft.featuresText, isNull);
    expect(draft.treasureText, isNull);
  });

  test('setCharacterName après setClass/setBackground conserve les choix '
      'déjà faits aux étapes précédentes (étape 9 "Récapitulatif")', () {
    final controller = container.read(
      characterCreationDraftControllerProvider.notifier,
    );

    controller.setClass(classId: 42);
    controller.setBackground(backgroundId: 5);
    controller.setCharacterName('Halltesse Ambrelune');

    final draft = container.read(characterCreationDraftControllerProvider);
    expect(draft.classId, 42);
    expect(draft.backgroundId, 5);
    expect(draft.characterName, 'Halltesse Ambrelune');
  });

  test('setCharacterName accepte null (champ jamais renseigné) sans '
      'planter', () {
    final controller = container.read(
      characterCreationDraftControllerProvider.notifier,
    );

    controller.setCharacterName(null);

    final draft = container.read(characterCreationDraftControllerProvider);
    expect(draft.characterName, isNull);
  });

  test('reset remet aussi characterName à zéro', () {
    final controller = container.read(
      characterCreationDraftControllerProvider.notifier,
    );

    controller.setCharacterName('Halltesse Ambrelune');
    controller.reset();

    final draft = container.read(characterCreationDraftControllerProvider);
    expect(draft.characterName, isNull);
  });
}
