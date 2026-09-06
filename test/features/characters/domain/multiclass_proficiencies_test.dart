import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/multiclass_proficiencies.dart';

void main() {
  group('MulticlassProficiencies.multiclassProficienciesFor', () {
    test('Barbare : boucliers + armes courantes et de guerre', () {
      expect(MulticlassProficiencies.multiclassProficienciesFor('Barbare'), [
        'Maîtrise des boucliers',
        'Maîtrise des armes courantes et de guerre',
      ]);
    });

    test('Guerrier : armures légères/intermédiaires + boucliers + armes '
        'courantes et de guerre (3 lignes)', () {
      expect(
        MulticlassProficiencies.multiclassProficienciesFor('Guerrier'),
        hasLength(3),
      );
    });

    test('Roublard : armures légères + compétence + outils de voleur', () {
      expect(
        MulticlassProficiencies.multiclassProficienciesFor('Roublard'),
        hasLength(3),
      );
    });

    test('Ensorceleur : aucune maîtrise de multiclassage', () {
      expect(
        MulticlassProficiencies.multiclassProficienciesFor('Ensorceleur'),
        isEmpty,
      );
    });

    test('Magicien : aucune maîtrise de multiclassage', () {
      expect(
        MulticlassProficiencies.multiclassProficienciesFor('Magicien'),
        isEmpty,
      );
    });

    test('classe absente de la table -> liste vide, jamais une exception', () {
      expect(
        MulticlassProficiencies.multiclassProficienciesFor('ClasseInconnue'),
        isEmpty,
      );
    });
  });

  group('MulticlassProficiencies.multiclassArmorProficiencyTokensFor', () {
    const expectedByClassName = {
      'Barbare': ['boucliers'],
      'Barde': ['légère'],
      'Clerc': ['légère', 'intermédiaire', 'boucliers'],
      'Druide': [
        'légère',
        'intermédiaire (non métallique)',
        'boucliers (non métalliques)',
      ],
      'Guerrier': ['légère', 'intermédiaire', 'boucliers'],
      'Moine': <String>[],
      'Paladin': ['légère', 'intermédiaire', 'boucliers'],
      'Rôdeur': ['légère', 'intermédiaire', 'boucliers'],
      'Roublard': ['légère'],
      'Ensorceleur': <String>[],
      'Occultiste': ['légère'],
      'Magicien': <String>[],
    };

    for (final entry in expectedByClassName.entries) {
      test('${entry.key} -> ${entry.value}', () {
        expect(
          MulticlassProficiencies.multiclassArmorProficiencyTokensFor(
            entry.key,
          ),
          entry.value,
        );
      });
    }

    test('classe absente de la table -> liste vide, jamais une exception', () {
      expect(
        MulticlassProficiencies.multiclassArmorProficiencyTokensFor(
          'ClasseInconnue',
        ),
        isEmpty,
      );
    });
  });

  group('MulticlassProficiencies.multiclassWeaponProficiencyTokensFor', () {
    const expectedByClassName = {
      'Barbare': ['courantes', 'martiales'],
      'Barde': <String>[],
      'Clerc': <String>[],
      'Druide': <String>[],
      'Guerrier': ['courantes', 'martiales'],
      'Moine': ['courantes', 'épées courtes'],
      'Paladin': ['courantes', 'martiales'],
      'Rôdeur': ['courantes', 'martiales'],
      'Roublard': <String>[],
      'Ensorceleur': <String>[],
      'Occultiste': ['courantes'],
      'Magicien': <String>[],
    };

    for (final entry in expectedByClassName.entries) {
      test('${entry.key} -> ${entry.value}', () {
        expect(
          MulticlassProficiencies.multiclassWeaponProficiencyTokensFor(
            entry.key,
          ),
          entry.value,
        );
      });
    }

    test('classe absente de la table -> liste vide, jamais une exception', () {
      expect(
        MulticlassProficiencies.multiclassWeaponProficiencyTokensFor(
          'ClasseInconnue',
        ),
        isEmpty,
      );
    });
  });
}
