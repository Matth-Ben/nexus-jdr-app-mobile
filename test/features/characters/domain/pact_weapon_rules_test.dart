import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_class_choice.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/pact_weapon_option.dart';
import 'package:personnages/features/characters/domain/pact_weapon_rules.dart';

PactWeaponOption _option(int id, String name) =>
    PactWeaponOption(id: id, name: name, damageDice: '1d6');

CharacterDetail _detail({
  String className = 'Occultiste',
  String? subclassName,
  List<CharacterClassChoice> choices = const [],
}) => CharacterDetail(
  id: '1',
  name: 'Test',
  classes: [
    CharacterDetailClassRow(
      classId: 1,
      className: className,
      level: 3,
      isPrimary: true,
      savingThrowProficiencies: const [],
      hitDie: 8,
      subclassName: subclassName,
    ),
  ],
  xp: 0,
  currentHp: 1,
  maxHp: 1,
  temporaryHp: 0,
  abilityScores: const {},
  classChoices: choices,
);

const _bladePact = CharacterClassChoice(
  featureName: 'Faveur de pacte',
  chosenValue: 'lame',
);

void main() {
  group('PactWeaponRules.normalize', () {
    test('retire casse et accents', () {
      expect(PactWeaponRules.normalize('  Épée Longue '), 'epee longue');
      expect(
        PactWeaponRules.normalize('Hâche à deux mains'),
        'hache a deux mains',
      );
      expect(PactWeaponRules.normalize('MUNITIONS(24/96)'), 'munitions(24/96)');
    });
  });

  group('PactWeaponRules.isEligible', () {
    bool eligible({
      String? category = 'arme',
      String? dice = '1d8',
      List<String> properties = const [],
    }) => PactWeaponRules.isEligible(
      category: category,
      damageDice: dice,
      properties: properties,
    );

    test('arme de corps à corps avec dés : éligible', () {
      expect(eligible(properties: ['légère', 'finesse']), isTrue);
    });

    test('autre catégorie : non éligible', () {
      expect(eligible(category: 'armure'), isFalse);
      expect(eligible(category: null), isFalse);
    });

    test('sans dé de dégâts (filet) : non éligible', () {
      expect(eligible(dice: null), isFalse);
      expect(eligible(dice: ' '), isFalse);
    });

    test('propriété munitions (suffixée, sans accents ni casse) : exclue', () {
      expect(eligible(properties: ['munitions(24/96)']), isFalse);
      expect(eligible(properties: ['Munitions']), isFalse);
      expect(
        eligible(properties: ['à deux mains', 'MUNITIONS (30/120)']),
        isFalse,
      );
    });

    test('une propriété qui contient munitions sans commencer par : ok', () {
      expect(eligible(properties: ['sans munitions']), isTrue);
    });
  });

  group('PactWeaponRules.sortByName / search', () {
    test('tri sans accents ni casse, sans muter la liste source', () {
      final source = [
        _option(1, 'Rapière'),
        _option(2, 'épée courte'),
        _option(3, 'Dague'),
        _option(4, 'Épée longue'),
      ];
      final sorted = PactWeaponRules.sortByName(source);
      expect(sorted.map((o) => o.name), [
        'Dague',
        'épée courte',
        'Épée longue',
        'Rapière',
      ]);
      expect(source.first.name, 'Rapière');
    });

    test('recherche sans accents ni casse', () {
      final options = [_option(1, 'Épée courte'), _option(2, 'Dague')];
      expect(PactWeaponRules.search(options, 'EPEE').map((o) => o.id), [1]);
      expect(PactWeaponRules.search(options, ''), options);
      expect(PactWeaponRules.search(options, 'xyz'), isEmpty);
    });
  });

  group('PactWeaponRules.isCursedBlade', () {
    test('reconnaît Lame maudite sans accents ni casse', () {
      expect(PactWeaponRules.isCursedBlade('Lame maudite'), isTrue);
      expect(PactWeaponRules.isCursedBlade('lame MAUDITE'), isTrue);
      expect(PactWeaponRules.isCursedBlade('Le Céleste'), isFalse);
      expect(PactWeaponRules.isCursedBlade(null), isFalse);
    });
  });

  group('PactWeaponOption', () {
    test('libellés de dégâts et de propriétés', () {
      const option = PactWeaponOption(
        id: 1,
        name: 'Rapière',
        damageDice: '1d8',
        damageType: 'perforant',
        properties: ['finesse', 'légère'],
      );
      expect(option.damageLabel, '1d8 perforant');
      expect(option.propertiesLabel, 'finesse, légère');
      expect(const PactWeaponOption(id: 2, name: 'X').damageLabel, isNull);
      expect(const PactWeaponOption(id: 2, name: 'X').propertiesLabel, isNull);
    });

    test('égalité par valeur', () {
      expect(_option(1, 'A'), _option(1, 'A'));
      expect(_option(1, 'A'), isNot(_option(2, 'A')));
    });
  });

  group('CharacterDetail.hasBladePact / hasCursedBladeSubclass', () {
    test('Occultiste avec choix lame : carte visible', () {
      expect(_detail(choices: [_bladePact]).hasBladePact, isTrue);
    });

    test('autres pactes ou aucun choix : pas de carte', () {
      expect(_detail().hasBladePact, isFalse);
      expect(
        _detail(
          choices: const [
            CharacterClassChoice(
              featureName: 'Faveur de pacte',
              chosenValue: 'chaine',
            ),
          ],
        ).hasBladePact,
        isFalse,
      );
    });

    test('autre classe : pas de carte même avec la valeur lame', () {
      expect(
        _detail(className: 'Guerrier', choices: [_bladePact]).hasBladePact,
        isFalse,
      );
    });

    test('Lame maudite détectée par le nom de sous-classe', () {
      expect(
        _detail(subclassName: 'Lame maudite').hasCursedBladeSubclass,
        isTrue,
      );
      expect(
        _detail(subclassName: 'Le Fiélon').hasCursedBladeSubclass,
        isFalse,
      );
      expect(_detail().hasCursedBladeSubclass, isFalse);
    });
  });
}
