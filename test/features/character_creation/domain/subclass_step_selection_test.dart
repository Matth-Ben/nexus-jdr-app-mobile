import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/subclass_choice_catalog.dart';
import 'package:personnages/features/character_creation/domain/subclass_choice_option.dart';
import 'package:personnages/features/character_creation/domain/subclass_step_selection.dart';

void main() {
  const vie = SubclassChoiceOption(id: 31, name: 'Domaine de la Vie');
  const guerre = SubclassChoiceOption(id: 32, name: 'Domaine de la Guerre');

  group('SubclassStepSelection.canProceed', () {
    test('catalogue en chargement -> false', () {
      expect(
        SubclassStepSelection.canProceed(
          catalogAsync: const AsyncValue.loading(),
          classId: 3,
          selectedSubclassId: null,
        ),
        isFalse,
      );
    });

    test('catalogue en erreur -> false', () {
      expect(
        SubclassStepSelection.canProceed(
          catalogAsync: AsyncValue.error('x', StackTrace.empty),
          classId: 3,
          selectedSubclassId: null,
        ),
        isFalse,
      );
    });

    test('liste d\'options vide (cas défensif) -> true, jamais bloquant', () {
      expect(
        SubclassStepSelection.canProceed(
          catalogAsync: const AsyncValue.data(
            SubclassChoiceCatalog(optionsByClassId: {3: []}),
          ),
          classId: 3,
          selectedSubclassId: null,
        ),
        isTrue,
      );
    });

    test('options disponibles mais aucune sélectionnée -> false', () {
      expect(
        SubclassStepSelection.canProceed(
          catalogAsync: const AsyncValue.data(
            SubclassChoiceCatalog(
              optionsByClassId: {
                3: [vie, guerre],
              },
            ),
          ),
          classId: 3,
          selectedSubclassId: null,
        ),
        isFalse,
      );
    });

    test('option sélectionnée présente dans la liste -> true', () {
      expect(
        SubclassStepSelection.canProceed(
          catalogAsync: const AsyncValue.data(
            SubclassChoiceCatalog(
              optionsByClassId: {
                3: [vie, guerre],
              },
            ),
          ),
          classId: 3,
          selectedSubclassId: 31,
        ),
        isTrue,
      );
    });
  });
}
