import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/subrace_step_selection.dart';

void main() {
  group('SubraceStepSelection.canProceed', () {
    test('aucune sous-race sélectionnée -> false', () {
      expect(SubraceStepSelection.canProceed(selectedSubraceId: null), isFalse);
    });

    test('une sous-race sélectionnée -> true', () {
      expect(SubraceStepSelection.canProceed(selectedSubraceId: 10), isTrue);
    });
  });
}
