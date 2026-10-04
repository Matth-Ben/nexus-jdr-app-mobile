import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/lineage_step_selection.dart';

void main() {
  group('LineageStepSelection.canProceed', () {
    test('aucune lignée sélectionnée -> false', () {
      expect(LineageStepSelection.canProceed(selectedLineageId: null), isFalse);
    });

    test('une lignée sélectionnée -> true', () {
      expect(LineageStepSelection.canProceed(selectedLineageId: 31), isTrue);
    });
  });
}
