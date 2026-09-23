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
        ),
        isFalse,
      );
    });

    test('race du catalogue sélectionnée -> true (le choix de sous-race ne '
        'conditionne plus cette étape, voir SubraceStepSelection)', () {
      expect(
        RaceStepSelection.canProceed(
          isCustomRace: false,
          customRaceText: '',
          selectedRaceId: 1,
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
        ),
        isTrue,
      );
    });
  });
}
