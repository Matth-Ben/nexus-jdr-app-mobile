import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/subclass_feature_choice.dart';
import 'package:personnages/features/character_creation/domain/subclass_feature_choice_selection.dart';
import 'package:personnages/features/character_creation/domain/subclass_feature_option.dart';

void main() {
  const rouge = SubclassFeatureOption(id: 1, name: 'Dragon rouge');
  const bleu = SubclassFeatureOption(id: 2, name: 'Dragon bleu');

  group('SubclassFeatureChoiceSelection.canProceed', () {
    test('catalogue en chargement -> false', () {
      expect(
        SubclassFeatureChoiceSelection.canProceed(
          catalogAsync: const AsyncValue.loading(),
          selectedOptionName: null,
        ),
        isFalse,
      );
    });

    test('catalogue en erreur -> false', () {
      expect(
        SubclassFeatureChoiceSelection.canProceed(
          catalogAsync: AsyncValue.error('x', StackTrace.empty),
          selectedOptionName: null,
        ),
        isFalse,
      );
    });

    test('sous-classe sans second choix (choice == null) -> true, jamais '
        'bloquant', () {
      expect(
        SubclassFeatureChoiceSelection.canProceed(
          catalogAsync: const AsyncValue.data(null),
          selectedOptionName: null,
        ),
        isTrue,
      );
    });

    test('choix existant mais options vides (cas défensif D95) -> true', () {
      expect(
        SubclassFeatureChoiceSelection.canProceed(
          catalogAsync: const AsyncValue.data(
            SubclassFeatureChoice(
              classFeatureId: 368,
              featureName: 'Ancêtre draconique',
              options: [],
            ),
          ),
          selectedOptionName: null,
        ),
        isTrue,
      );
    });

    test('options disponibles mais aucune sélectionnée -> false', () {
      expect(
        SubclassFeatureChoiceSelection.canProceed(
          catalogAsync: const AsyncValue.data(
            SubclassFeatureChoice(
              classFeatureId: 368,
              featureName: 'Ancêtre draconique',
              options: [rouge, bleu],
            ),
          ),
          selectedOptionName: null,
        ),
        isFalse,
      );
    });

    test('option sélectionnée présente dans la liste -> true', () {
      expect(
        SubclassFeatureChoiceSelection.canProceed(
          catalogAsync: const AsyncValue.data(
            SubclassFeatureChoice(
              classFeatureId: 368,
              featureName: 'Ancêtre draconique',
              options: [rouge, bleu],
            ),
          ),
          selectedOptionName: 'Dragon rouge',
        ),
        isTrue,
      );
    });

    test('option sélectionnée absente de la liste -> false', () {
      expect(
        SubclassFeatureChoiceSelection.canProceed(
          catalogAsync: const AsyncValue.data(
            SubclassFeatureChoice(
              classFeatureId: 368,
              featureName: 'Ancêtre draconique',
              options: [rouge, bleu],
            ),
          ),
          selectedOptionName: 'Dragon vert',
        ),
        isFalse,
      );
    });
  });
}
