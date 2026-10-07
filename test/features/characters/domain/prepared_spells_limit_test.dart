import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/multiclass_prerequisites.dart';
import 'package:personnages/features/characters/domain/prepared_spells_limit.dart';
import 'package:personnages/features/characters/domain/spellcasting_class_names.dart';

CharacterDetailClassRow _row(String name, int level) => CharacterDetailClassRow(
  classId: name.hashCode,
  className: name,
  level: level,
  isPrimary: true,
  savingThrowProficiencies: const [],
  hitDie: 8,
);

int? _limit(String className, int level, int modifier) =>
    PreparedSpellsLimit.limitFor(
      className: className,
      classLevel: level,
      abilityModifier: modifier,
    );

void main() {
  group('PreparedSpellsLimit.limitFor', () {
    test('Clerc/Druide/Magicien : modificateur + niveau de classe', () {
      expect(_limit('Clerc', 5, 3), 8);
      expect(_limit('Druide', 4, 2), 6);
      expect(_limit('Magicien', 1, 3), 4);
    });

    test(
      'Paladin : modificateur + moitié du niveau arrondie à l inférieur',
      () {
        expect(_limit('Paladin', 5, 3), 5);
        expect(_limit('Paladin', 4, 1), 3);
      },
    );

    test('minimum 1 : Paladin niveau 1 (moitié = 0), modificateur négatif', () {
      expect(_limit('Paladin', 1, 0), 1);
      expect(_limit('Paladin', 2, -3), 1);
      expect(_limit('Magicien', 1, -2), 1);
    });

    test('classes à sorts connus ou non lanceuses : null', () {
      for (final name in [
        'Barde',
        'Ensorceleur',
        'Occultiste',
        'Rôdeur',
        'Guerrier',
        'Roublard',
      ]) {
        expect(_limit(name, 5, 3), isNull, reason: name);
      }
    });
  });

  group('PreparedSpellsLimit.limitForCharacter', () {
    test('utilise la bonne caractéristique par classe', () {
      expect(
        PreparedSpellsLimit.limitForCharacter(
          classes: [_row('Clerc', 3)],
          abilityScores: const {'wis': 16, 'int': 8, 'cha': 8},
        ),
        6,
      );
      expect(
        PreparedSpellsLimit.limitForCharacter(
          classes: [_row('Magicien', 3)],
          abilityScores: const {'wis': 8, 'int': 16},
        ),
        6,
      );
      expect(
        PreparedSpellsLimit.limitForCharacter(
          classes: [_row('Paladin', 6)],
          abilityScores: const {'cha': 14, 'wis': 8},
        ),
        5,
      );
    });

    test('caractéristique absente : score 10 (modificateur nul)', () {
      expect(
        PreparedSpellsLimit.limitForCharacter(
          classes: [_row('Druide', 4)],
          abilityScores: const {},
        ),
        4,
      );
    });

    test(
      'une seule classe qui prépare parmi d autres : limite de celle-là',
      () {
        expect(
          PreparedSpellsLimit.limitForCharacter(
            classes: [_row('Guerrier', 2), _row('Clerc', 2)],
            abilityScores: const {'wis': 14},
          ),
          4,
        );
      },
    );

    test('aucune classe qui prépare : null', () {
      expect(
        PreparedSpellsLimit.limitForCharacter(
          classes: [_row('Barde', 3)],
          abilityScores: const {'cha': 16},
        ),
        isNull,
      );
    });

    test('plusieurs classes qui préparent : null (pas de chiffre faux)', () {
      expect(
        PreparedSpellsLimit.limitForCharacter(
          classes: [_row('Clerc', 3), _row('Paladin', 2)],
          abilityScores: const {'wis': 14, 'cha': 14},
        ),
        isNull,
      );
    });
  });

  group('PreparedSpellsLimit.spellRequiresPreparation', () {
    CharacterDetailClassRow cls(int id, String name) => CharacterDetailClassRow(
      classId: id,
      className: name,
      level: 3,
      isPrimary: id == 1,
      savingThrowProficiencies: const [],
      hitDie: 8,
    );
    final barde = cls(1, 'Barde');
    final clerc = cls(2, 'Clerc');

    bool requires(
      List<CharacterDetailClassRow> classes, [
      List<int> sources = const [],
    ]) => PreparedSpellsLimit.spellRequiresPreparation(
      classes: classes,
      sourceClassIds: sources,
    );

    test('classe unique qui prépare : toujours à préparer', () {
      for (final name in ['Clerc', 'Druide', 'Magicien', 'Paladin']) {
        expect(requires([cls(2, name)], [2]), isTrue, reason: name);
        expect(requires([cls(2, name)]), isTrue, reason: '$name sans origine');
      }
    });

    test('classe unique qui ne prépare pas : jamais à préparer', () {
      for (final name in ['Barde', 'Ensorceleur', 'Occultiste', 'Rôdeur']) {
        expect(requires([cls(1, name)], [1]), isFalse, reason: name);
        expect(requires([cls(1, name)]), isFalse, reason: '$name sans origine');
      }
    });

    test('multiclassé mixte : tranché par la classe d\'origine du sort', () {
      expect(requires([barde, clerc], [1]), isFalse);
      expect(requires([barde, clerc], [2]), isTrue);
    });

    test('origine inconnue : à préparer si une classe du personnage '
        'prépare', () {
      expect(requires([barde, clerc]), isTrue);
      expect(requires([barde, cls(3, 'Ensorceleur')]), isFalse);
    });

    test('origine qui n\'est pas une classe du personnage : traitée comme '
        'inconnue', () {
      expect(requires([barde, clerc], [99]), isTrue);
      expect(requires([barde], [99]), isFalse);
    });

    test('lignes en double d\'origines différentes : une origine qui ne '
        'prépare pas suffit, quel que soit l\'ordre', () {
      expect(requires([barde, clerc], [1, 2]), isFalse);
      expect(requires([barde, clerc], [2, 1]), isFalse);
      expect(requires([clerc, barde], [2, 1]), isFalse);
    });

    test('class_id comparé par valeur, entier ou chaîne', () {
      final stringId = CharacterDetailClassRow(
        classId: '1',
        className: 'Barde',
        level: 3,
        isPrimary: true,
        savingThrowProficiencies: const [],
        hitDie: 8,
      );
      expect(requires([stringId, clerc], [1]), isFalse);
    });

    // Règle sûre par défaut : un sort ne devient « sans préparation » que
    // si son origine, ou à défaut toutes les classes lanceuses du personnage,
    // figurent dans la liste explicite des classes à sorts connus. Tout nom
    // non reconnu retombe sur le comportement historique (« à préparer »).
    test('nom de classe non reconnu ou aucune classe : à préparer '
        '(comportement d\'avant le correctif)', () {
      for (final name in ['Artificier', 'Classe #3', 'Classe', '']) {
        expect(requires([cls(3, name)]), isTrue, reason: name);
        expect(requires([cls(3, name)], [3]), isTrue, reason: name);
      }
      // Aucune classe du tout (JSON partagé sans `classes`).
      expect(requires([]), isTrue);
      expect(requires([], [1]), isTrue);
      expect(requires([cls(3, 'Classe #3'), clerc]), isTrue);
    });

    test('Barde + classe non lanceuse connue : les sorts du Barde restent '
        'lançables sans préparation, origine connue ou non', () {
      for (final name in ['Guerrier', 'Barbare', 'Moine', 'Roublard']) {
        final classes = [barde, cls(3, name)];
        expect(requires(classes, [1]), isFalse, reason: '$name, origine Barde');
        expect(requires(classes), isFalse, reason: '$name, sans origine');
        // Origine « classe non lanceuse » (donnée incohérente) : ignorée,
        // comme une origine inconnue.
        expect(requires(classes, [3]), isFalse, reason: '$name, origine $name');
        expect(
          requires([cls(3, name), barde]),
          isFalse,
          reason: '$name en premier',
        );
      }
    });

    test('classe non lanceuse seule : à préparer (comportement d\'avant), '
        'faute de classe à sorts connus', () {
      for (final name in ['Guerrier', 'Barbare', 'Moine', 'Roublard']) {
        expect(requires([cls(3, name)]), isTrue, reason: name);
        expect(requires([cls(3, name)], [3]), isTrue, reason: name);
      }
    });

    test('Barde + classe inconnue (Artificier, "Classe #id") : origine Barde '
        'lançable, origine inconnue ou de la classe inconnue à préparer', () {
      for (final name in ['Artificier', 'Classe #3', 'Classe', '']) {
        final classes = [barde, cls(3, name)];
        expect(requires(classes, [1]), isFalse, reason: '$name, origine Barde');
        expect(requires(classes), isTrue, reason: '$name, sans origine');
        expect(requires(classes, [3]), isTrue, reason: '$name, origine $name');
        expect(requires(classes, [3, 1]), isFalse, reason: '$name, doublon');
      }
    });

    test('knowsSpellsWithoutPreparing : uniquement Barde, Ensorceleur, '
        'Occultiste, Rôdeur parmi les treize classes de la base', () {
      const known = {'Barde', 'Ensorceleur', 'Occultiste', 'Rôdeur'};
      for (final name in [
        'Barbare',
        'Barde',
        'Clerc',
        'Druide',
        'Guerrier',
        'Moine',
        'Paladin',
        'Rôdeur',
        'Roublard',
        'Occultiste',
        'Magicien',
        'Ensorceleur',
        'Artificier',
      ]) {
        expect(
          PreparedSpellsLimit.knowsSpellsWithoutPreparing(name),
          known.contains(name),
          reason: name,
        );
        // Une classe ne peut pas à la fois préparer et connaître.
        expect(
          PreparedSpellsLimit.preparesSpells(name) &&
              PreparedSpellsLimit.knowsSpellsWithoutPreparing(name),
          isFalse,
          reason: name,
        );
      }
    });

    test('invariant : toute classe lanceuse (spellcastingClassNames) est soit '
        '« prépare », soit « sorts connus », jamais les deux ni aucun', () {
      expect(spellcastingClassNames, hasLength(8));
      for (final name in spellcastingClassNames) {
        expect(
          PreparedSpellsLimit.preparesSpells(name) !=
              PreparedSpellsLimit.knowsSpellsWithoutPreparing(name),
          isTrue,
          reason: name,
        );
        expect(
          MulticlassPrerequisites.isKnownClass(name),
          isTrue,
          reason: name,
        );
      }
    });

    test('invariant : une classe connue de MulticlassPrerequisites absente '
        'de spellcastingClassNames n\'est ni « prépare » ni « sorts '
        'connus »', () {
      final nonCasters = [
        for (final name in _databaseClassNames)
          if (MulticlassPrerequisites.isKnownClass(name) &&
              !spellcastingClassNames.contains(name))
            name,
      ];
      expect(nonCasters, ['Barbare', 'Guerrier', 'Moine', 'Roublard']);
      for (final name in nonCasters) {
        expect(PreparedSpellsLimit.preparesSpells(name), isFalse, reason: name);
        expect(
          PreparedSpellsLimit.knowsSpellsWithoutPreparing(name),
          isFalse,
          reason: name,
        );
      }
    });
  });
}

/// Les treize classes présentes en base (relevé du chef de projet).
const _databaseClassNames = [
  'Barbare',
  'Barde',
  'Clerc',
  'Druide',
  'Guerrier',
  'Moine',
  'Paladin',
  'Rôdeur',
  'Roublard',
  'Occultiste',
  'Magicien',
  'Ensorceleur',
  'Artificier',
];
