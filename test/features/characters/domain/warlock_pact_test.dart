import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_class_choice.dart';
import 'package:personnages/features/characters/domain/level_up_choice_selection.dart';
import 'package:personnages/features/characters/domain/level_up_choice_kind.dart';
import 'package:personnages/features/characters/domain/warlock_pact.dart';

void main() {
  group('WarlockPact', () {
    test('clés stockées en base et libellés français', () {
      expect(WarlockPact.chain.key, 'chaine');
      expect(WarlockPact.blade.key, 'lame');
      expect(WarlockPact.tome.key, 'grimoire');
      expect(WarlockPact.chain.label, 'Pacte de la chaîne');
      expect(WarlockPact.blade.label, 'Pacte de la lame');
      expect(WarlockPact.tome.label, 'Pacte du grimoire');
    });

    test('chaque pacte a une description non vide', () {
      for (final pact in WarlockPact.values) {
        expect(pact.description, isNotEmpty);
      }
    });

    test('fromKey : connu, inconnu, null', () {
      expect(WarlockPact.fromKey('lame'), WarlockPact.blade);
      expect(WarlockPact.fromKey('epee'), isNull);
      expect(WarlockPact.fromKey(null), isNull);
    });

    test('displayLabelFor : traduit les pactes, laisse le reste tel quel', () {
      expect(WarlockPact.displayLabelFor('chaine'), 'Pacte de la chaîne');
      expect(WarlockPact.displayLabelFor('Archerie'), 'Archerie');
    });
  });

  group('CharacterClassChoice.displayValue', () {
    test('traduit le pacte choisi', () {
      const choice = CharacterClassChoice(
        featureName: 'Faveur de pacte',
        chosenValue: 'grimoire',
      );
      expect(choice.displayValue, 'Pacte du grimoire');
      expect(choice.pact, WarlockPact.tome);
    });

    test('laisse un style de combat tel quel', () {
      const choice = CharacterClassChoice(
        featureName: 'Style de combat',
        chosenValue: 'Duel',
      );
      expect(choice.displayValue, 'Duel');
      expect(choice.pact, isNull);
    });
  });

  test('LevelUpChoiceSelection.pact porte kind, classFeatureId et clé', () {
    const selection = LevelUpChoiceSelection.pact(
      classFeatureId: 261,
      chosenValue: 'lame',
    );
    expect(selection.kind, LevelUpChoiceKind.pact);
    expect(selection.classFeatureId, 261);
    expect(selection.chosenValue, 'lame');
    expect(selection.subclassId, isNull);
    expect(selection.abilityAllocations, isNull);
    expect(selection.featId, isNull);
  });
}
