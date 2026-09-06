import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/multiclass_prerequisites.dart';

void main() {
  group('MulticlassPrerequisites.meetsRequirement — clause unique', () {
    test('Barbare : Force 13 suffit', () {
      expect(
        MulticlassPrerequisites.meetsRequirement('Barbare', {'str': 13}),
        isTrue,
      );
    });

    test('Barbare : Force 12 insuffisant', () {
      expect(
        MulticlassPrerequisites.meetsRequirement('Barbare', {'str': 12}),
        isFalse,
      );
    });

    test('Barde : Charisme 13', () {
      expect(
        MulticlassPrerequisites.meetsRequirement('Barde', {'cha': 13}),
        isTrue,
      );
    });

    test('Clerc : Sagesse 13', () {
      expect(
        MulticlassPrerequisites.meetsRequirement('Clerc', {'wis': 13}),
        isTrue,
      );
    });

    test('Druide : Sagesse 13', () {
      expect(
        MulticlassPrerequisites.meetsRequirement('Druide', {'wis': 13}),
        isTrue,
      );
    });

    test('Roublard : Dextérité 13', () {
      expect(
        MulticlassPrerequisites.meetsRequirement('Roublard', {'dex': 13}),
        isTrue,
      );
    });

    test('Ensorceleur : Charisme 13', () {
      expect(
        MulticlassPrerequisites.meetsRequirement('Ensorceleur', {'cha': 13}),
        isTrue,
      );
    });

    test('Occultiste : Charisme 13', () {
      expect(
        MulticlassPrerequisites.meetsRequirement('Occultiste', {'cha': 13}),
        isTrue,
      );
    });

    test('Magicien : Intelligence 13', () {
      expect(
        MulticlassPrerequisites.meetsRequirement('Magicien', {'int': 13}),
        isTrue,
      );
    });
  });

  group('MulticlassPrerequisites.meetsRequirement — Guerrier (OU réel)', () {
    test('Force 13 seule suffit', () {
      expect(
        MulticlassPrerequisites.meetsRequirement('Guerrier', {
          'str': 13,
          'dex': 8,
        }),
        isTrue,
      );
    });

    test('Dextérité 13 seule suffit (sans Force)', () {
      expect(
        MulticlassPrerequisites.meetsRequirement('Guerrier', {
          'str': 8,
          'dex': 13,
        }),
        isTrue,
      );
    });

    test('ni Force 13 ni Dextérité 13 -> refusé', () {
      expect(
        MulticlassPrerequisites.meetsRequirement('Guerrier', {
          'str': 12,
          'dex': 12,
        }),
        isFalse,
      );
    });
  });

  group('MulticlassPrerequisites.meetsRequirement — clauses ET', () {
    test('Moine : Dextérité 13 ET Sagesse 13, les deux réunies', () {
      expect(
        MulticlassPrerequisites.meetsRequirement('Moine', {
          'dex': 13,
          'wis': 13,
        }),
        isTrue,
      );
    });

    test('Moine : Dextérité 13 seule ne suffit pas (Sagesse manquante)', () {
      expect(
        MulticlassPrerequisites.meetsRequirement('Moine', {
          'dex': 13,
          'wis': 12,
        }),
        isFalse,
      );
    });

    test('Moine : Sagesse 13 seule ne suffit pas (Dextérité manquante)', () {
      expect(
        MulticlassPrerequisites.meetsRequirement('Moine', {
          'dex': 12,
          'wis': 13,
        }),
        isFalse,
      );
    });

    test('Paladin : Force 13 ET Charisme 13, les deux réunies', () {
      expect(
        MulticlassPrerequisites.meetsRequirement('Paladin', {
          'str': 13,
          'cha': 13,
        }),
        isTrue,
      );
    });

    test('Paladin : Force 13 seule ne suffit pas', () {
      expect(
        MulticlassPrerequisites.meetsRequirement('Paladin', {
          'str': 13,
          'cha': 12,
        }),
        isFalse,
      );
    });

    test('Rôdeur : Dextérité 13 ET Sagesse 13, les deux réunies', () {
      expect(
        MulticlassPrerequisites.meetsRequirement('Rôdeur', {
          'dex': 13,
          'wis': 13,
        }),
        isTrue,
      );
    });

    test('Rôdeur : Sagesse 13 seule ne suffit pas', () {
      expect(
        MulticlassPrerequisites.meetsRequirement('Rôdeur', {
          'dex': 12,
          'wis': 13,
        }),
        isFalse,
      );
    });
  });

  group('MulticlassPrerequisites.meetsRequirement — cas défensifs', () {
    test('caractéristique absente de la map -> traitée comme 0, prérequis '
        'non rempli', () {
      expect(MulticlassPrerequisites.meetsRequirement('Barbare', {}), isFalse);
    });

    test('classe absente de la table -> prérequis non rempli, jamais une '
        'exception', () {
      expect(
        MulticlassPrerequisites.meetsRequirement('ClasseInconnue', {
          'str': 20,
          'dex': 20,
          'con': 20,
          'int': 20,
          'wis': 20,
          'cha': 20,
        }),
        isFalse,
      );
    });
  });

  group('MulticlassPrerequisites.satisfiedAbilityIds', () {
    test('Guerrier avec seule la Force remplie -> ne cite que "str", jamais '
        '"dex"', () {
      expect(
        MulticlassPrerequisites.satisfiedAbilityIds('Guerrier', {
          'str': 13,
          'dex': 8,
        }),
        ['str'],
      );
    });

    test('Guerrier avec seule la Dextérité remplie -> ne cite que "dex"', () {
      expect(
        MulticlassPrerequisites.satisfiedAbilityIds('Guerrier', {
          'str': 8,
          'dex': 13,
        }),
        ['dex'],
      );
    });

    test('Guerrier avec Force ET Dextérité remplies -> cite les deux '
        '(union des clauses, chacune remplie indépendamment)', () {
      expect(
        MulticlassPrerequisites.satisfiedAbilityIds('Guerrier', {
          'str': 13,
          'dex': 13,
        }),
        containsAll(['str', 'dex']),
      );
    });

    test('Moine (clause ET) -> cite les deux caractéristiques de la clause '
        'remplie, jamais une seule', () {
      expect(
        MulticlassPrerequisites.satisfiedAbilityIds('Moine', {
          'dex': 13,
          'wis': 13,
        }),
        containsAll(['dex', 'wis']),
      );
    });

    test('prérequis non rempli -> liste vide', () {
      expect(
        MulticlassPrerequisites.satisfiedAbilityIds('Barbare', {'str': 10}),
        isEmpty,
      );
    });

    test('classe absente de la table -> liste vide, jamais une exception', () {
      expect(
        MulticlassPrerequisites.satisfiedAbilityIds('ClasseInconnue', {
          'str': 20,
        }),
        isEmpty,
      );
    });
  });
}
