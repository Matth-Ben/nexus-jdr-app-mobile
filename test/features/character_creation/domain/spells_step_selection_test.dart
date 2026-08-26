import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/domain/spells_step_selection.dart';

void main() {
  group('isChoiceLocked', () {
    test('verrouille une option non cochée quand le quota est atteint', () {
      expect(
        SpellsStepSelection.isChoiceLocked(
          isSelected: false,
          selectedCount: 2,
          quota: 2,
        ),
        isTrue,
      );
    });

    test('ne verrouille jamais une option déjà cochée', () {
      expect(
        SpellsStepSelection.isChoiceLocked(
          isSelected: true,
          selectedCount: 2,
          quota: 2,
        ),
        isFalse,
      );
    });

    test('ne verrouille pas une option non cochée tant que le quota n\'est '
        'pas atteint', () {
      expect(
        SpellsStepSelection.isChoiceLocked(
          isSelected: false,
          selectedCount: 1,
          quota: 2,
        ),
        isFalse,
      );
    });
  });

  group('toggle', () {
    test('ajoute une valeur absente si le quota n\'est pas atteint', () {
      expect(
        SpellsStepSelection.toggle(
          current: const ['Trait de feu'],
          value: 'Lumières dansantes',
          quota: 2,
        ),
        ['Trait de feu', 'Lumières dansantes'],
      );
    });

    test('retire une valeur déjà présente, même quota atteint', () {
      expect(
        SpellsStepSelection.toggle(
          current: const ['Trait de feu', 'Lumières dansantes'],
          value: 'Trait de feu',
          quota: 2,
        ),
        ['Lumières dansantes'],
      );
    });

    test('n\'ajoute rien de plus une fois le quota atteint (garde-fou)', () {
      expect(
        SpellsStepSelection.toggle(
          current: const ['Trait de feu', 'Lumières dansantes'],
          value: 'Réparation',
          quota: 2,
        ),
        ['Trait de feu', 'Lumières dansantes'],
      );
    });

    test('ne mute jamais la liste fournie en entrée', () {
      final current = ['Trait de feu'];
      SpellsStepSelection.toggle(
        current: current,
        value: 'Lumières dansantes',
        quota: 2,
      );
      expect(current, ['Trait de feu']);
    });
  });

  group('canProceed', () {
    test('actif quand l\'unique onglet visible a atteint son quota exact '
        '(l\'autre est masqué, quota nul)', () {
      expect(
        SpellsStepSelection.canProceed(
          cantripQuota: 0,
          selectedCantrips: const [],
          levelOneSpellQuota: 2,
          selectedLevelOneSpells: const ['Bénédiction', 'Soin des blessures'],
        ),
        isTrue,
      );
    });

    test('bloqué tant que le quota de sorts mineurs n\'est pas exactement '
        'atteint', () {
      expect(
        SpellsStepSelection.canProceed(
          cantripQuota: 2,
          selectedCantrips: const ['Trait de feu'],
          levelOneSpellQuota: 0,
          selectedLevelOneSpells: const [],
        ),
        isFalse,
      );
    });

    test('bloqué tant que le quota de sorts de niveau 1 n\'est pas '
        'exactement atteint, même si les sorts mineurs sont au quota', () {
      expect(
        SpellsStepSelection.canProceed(
          cantripQuota: 2,
          selectedCantrips: const ['Trait de feu', 'Lumières dansantes'],
          levelOneSpellQuota: 4,
          selectedLevelOneSpells: const ['Bénédiction'],
        ),
        isFalse,
      );
    });

    test('actif quand les deux onglets visibles ont atteint leur quota '
        'exact', () {
      expect(
        SpellsStepSelection.canProceed(
          cantripQuota: 2,
          selectedCantrips: const ['Trait de feu', 'Lumières dansantes'],
          levelOneSpellQuota: 2,
          selectedLevelOneSpells: const ['Bénédiction', 'Soin des blessures'],
        ),
        isTrue,
      );
    });
  });
}
