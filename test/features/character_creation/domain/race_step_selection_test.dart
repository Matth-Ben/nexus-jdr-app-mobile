import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/race_step_selection.dart';

void main() {
  group('RaceStepSelection.canProceed', () {
    test('aucune race sélectionnée -> false', () {
      expect(
        RaceStepSelection.canProceed(
          isCustomRace: false,
          customRaceText: '',
          selectedRaceId: null,
          selectedRaceHasSubraces: false,
          selectedSubraceId: null,
        ),
        isFalse,
      );
    });

    test('race sans sous-race sélectionnée -> true', () {
      expect(
        RaceStepSelection.canProceed(
          isCustomRace: false,
          customRaceText: '',
          selectedRaceId: 1,
          selectedRaceHasSubraces: false,
          selectedSubraceId: null,
        ),
        isTrue,
      );
    });

    test(
      'race avec sous-races requises mais aucune sous-race choisie -> false',
      () {
        expect(
          RaceStepSelection.canProceed(
            isCustomRace: false,
            customRaceText: '',
            selectedRaceId: 1,
            selectedRaceHasSubraces: true,
            selectedSubraceId: null,
          ),
          isFalse,
        );
      },
    );

    test('race avec sous-races requises et sous-race choisie -> true', () {
      expect(
        RaceStepSelection.canProceed(
          isCustomRace: false,
          customRaceText: '',
          selectedRaceId: 1,
          selectedRaceHasSubraces: true,
          selectedSubraceId: 3,
        ),
        isTrue,
      );
    });

    test('race personnalisée avec texte vide (ou espaces) -> false', () {
      expect(
        RaceStepSelection.canProceed(
          isCustomRace: true,
          customRaceText: '   ',
          selectedRaceId: null,
          selectedRaceHasSubraces: false,
          selectedSubraceId: null,
        ),
        isFalse,
      );
    });

    test('race personnalisée avec texte renseigné -> true', () {
      expect(
        RaceStepSelection.canProceed(
          isCustomRace: true,
          customRaceText: 'Golem vivant',
          selectedRaceId: null,
          selectedRaceHasSubraces: false,
          selectedSubraceId: null,
        ),
        isTrue,
      );
    });
  });
}
