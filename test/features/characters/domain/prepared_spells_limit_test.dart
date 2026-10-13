import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/rules/character_class.dart';
import 'package:personnages/core/rules/class_spellcasting_rule.dart';
import 'package:personnages/core/rules/spell_status.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/multiclass_prerequisites.dart';
import 'package:personnages/features/characters/domain/prepared_spells_limit.dart';
import 'package:personnages/features/characters/domain/spell_grant_source.dart';

CharacterDetailClassRow _row(String name, int level, {Object? classId}) =>
    CharacterDetailClassRow(
      classId: classId ?? name.hashCode,
      className: name,
      level: level,
      isPrimary: true,
      savingThrowProficiencies: const [],
      hitDie: 8,
    );

CharacterSpellEntry _spell({
  int id = 1,
  int level = 1,
  SpellStatus status = SpellStatus.prepared,
  Set<int> sourceClassIds = const {},
  bool requiresPreparation = true,
  SpellGrantSource? grantSource,
}) => CharacterSpellEntry(
  id: id,
  name: 'Sort $id',
  level: level,
  school: '',
  status: status,
  sourceClassIds: sourceClassIds,
  requiresPreparation: requiresPreparation,
  grantSource: grantSource,
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

    test('Artificier (D41, demi-lanceur qui prépare) : même formule que '
        'Paladin — modificateur + moitié du niveau arrondie à l inférieur', () {
      expect(_limit('Artificier', 5, 3), 5);
      expect(_limit('Artificier', 4, 1), 3);
    });

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

  group('PreparedSpellsLimit.limitsByClass (mono-classe)', () {
    test('utilise la bonne caractéristique par classe', () {
      expect(
        PreparedSpellsLimit.limitsByClass(
          classes: [_row('Clerc', 3)],
          abilityScores: const {'wis': 16, 'int': 8, 'cha': 8},
          spells: const [],
        ).single.limit,
        6,
      );
      expect(
        PreparedSpellsLimit.limitsByClass(
          classes: [_row('Magicien', 3)],
          abilityScores: const {'wis': 8, 'int': 16},
          spells: const [],
        ).single.limit,
        6,
      );
      expect(
        PreparedSpellsLimit.limitsByClass(
          classes: [_row('Paladin', 6)],
          abilityScores: const {'cha': 14, 'wis': 8},
          spells: const [],
        ).single.limit,
        5,
      );
    });

    test('caractéristique absente : score 10 (modificateur nul)', () {
      expect(
        PreparedSpellsLimit.limitsByClass(
          classes: [_row('Druide', 4)],
          abilityScores: const {},
          spells: const [],
        ).single.limit,
        4,
      );
    });

    test('une seule classe qui prépare parmi d autres : limite de celle-là, '
        'un seul élément', () {
      final result = PreparedSpellsLimit.limitsByClass(
        classes: [_row('Guerrier', 2), _row('Clerc', 2)],
        abilityScores: const {'wis': 14},
        spells: const [],
      );
      expect(result, hasLength(1));
      expect(result.single.className, 'Clerc');
      expect(result.single.limit, 4);
    });

    test('aucune classe qui prépare : liste vide', () {
      expect(
        PreparedSpellsLimit.limitsByClass(
          classes: [_row('Barde', 3)],
          abilityScores: const {'cha': 16},
          spells: const [],
        ),
        isEmpty,
      );
    });

    test('décompte mono-classe : compte TOUS les sorts qualifiants, sans '
        'filtrer par sourceClassIds (comportement historique inchangé)', () {
      final result = PreparedSpellsLimit.limitsByClass(
        classes: [_row('Clerc', 3)],
        abilityScores: const {'wis': 14},
        spells: [
          _spell(id: 1, sourceClassIds: const {}), // origine inconnue
          _spell(id: 2, sourceClassIds: const {999}), // origine étrangère
          _spell(id: 3, level: 0), // sort mineur exclu
          _spell(id: 4, status: SpellStatus.known), // non préparé
          _spell(id: 5, grantSource: SpellGrantSource.domain), // accordé
          _spell(id: 6, requiresPreparation: false), // sorts connus
        ],
      );
      expect(result.single.preparedCount, 2);
      expect(result.single.isAtLimit, isFalse);
    });
  });

  group('PreparedSpellsLimit.limitsByClass (multiclassé)', () {
    test('plusieurs classes qui préparent : un élément par classe, jamais '
        'null (RAW : chaque classe calcule sa propre limite séparément)', () {
      final result = PreparedSpellsLimit.limitsByClass(
        classes: [_row('Clerc', 3), _row('Paladin', 2)],
        abilityScores: const {'wis': 14, 'cha': 14},
        spells: const [],
      );
      expect(result, hasLength(2));
      expect(result[0].className, 'Clerc');
      expect(result[0].limit, 5);
      expect(result[1].className, 'Paladin');
      expect(result[1].limit, 3);
    });

    test('ventile le décompte par classe via sourceClassIds', () {
      final clerc = _row('Clerc', 3, classId: 10);
      final paladin = _row('Paladin', 2, classId: 20);
      final result = PreparedSpellsLimit.limitsByClass(
        classes: [clerc, paladin],
        abilityScores: const {'wis': 14, 'cha': 14},
        spells: [
          _spell(id: 1, sourceClassIds: const {10}),
          _spell(id: 2, sourceClassIds: const {10}),
          _spell(id: 3, sourceClassIds: const {20}),
        ],
      );
      final clercLimit = result.firstWhere((c) => c.className == 'Clerc');
      final paladinLimit = result.firstWhere((c) => c.className == 'Paladin');
      expect(clercLimit.preparedCount, 2);
      expect(paladinLimit.preparedCount, 1);
    });

    test('sort sans origine connue : compté dans AUCUNE classe (sous-compte '
        'assumé, jamais deviné)', () {
      final clerc = _row('Clerc', 3, classId: 10);
      final paladin = _row('Paladin', 2, classId: 20);
      final result = PreparedSpellsLimit.limitsByClass(
        classes: [clerc, paladin],
        abilityScores: const {'wis': 14, 'cha': 14},
        spells: [_spell(id: 1, sourceClassIds: const {})],
      );
      expect(result.every((c) => c.preparedCount == 0), isTrue);
    });

    test(
      'sort présent sur la liste de deux classes préparantes : compté dans '
      'les deux (signal d\'affichage, l\'écriture tranche une seule classe)',
      () {
        final clerc = _row('Clerc', 3, classId: 10);
        final paladin = _row('Paladin', 2, classId: 20);
        final result = PreparedSpellsLimit.limitsByClass(
          classes: [clerc, paladin],
          abilityScores: const {'wis': 14, 'cha': 14},
          spells: [
            _spell(id: 1, sourceClassIds: const {10, 20}),
          ],
        );
        expect(result.every((c) => c.preparedCount == 1), isTrue);
      },
    );

    test('sorts mineurs/non préparés/accordés/sans préparation exclus, comme '
        'en mono-classe', () {
      final clerc = _row('Clerc', 3, classId: 10);
      final paladin = _row('Paladin', 2, classId: 20);
      final result = PreparedSpellsLimit.limitsByClass(
        classes: [clerc, paladin],
        abilityScores: const {'wis': 14, 'cha': 14},
        spells: [
          _spell(id: 1, level: 0, sourceClassIds: const {10}),
          _spell(id: 2, status: SpellStatus.known, sourceClassIds: const {10}),
          _spell(
            id: 3,
            grantSource: SpellGrantSource.domain,
            sourceClassIds: const {10},
          ),
          _spell(id: 4, requiresPreparation: false, sourceClassIds: const {10}),
        ],
      );
      expect(result.every((c) => c.preparedCount == 0), isTrue);
    });

    test('isAtLimit vrai dès que le décompte atteint ou dépasse la limite', () {
      final clerc = _row('Clerc', 1, classId: 10);
      final result = PreparedSpellsLimit.limitsByClass(
        classes: [clerc, _row('Paladin', 1, classId: 20)],
        abilityScores: const {'wis': 10, 'cha': 10},
        spells: [
          _spell(id: 1, sourceClassIds: const {10}),
        ],
      );
      final clercLimit = result.firstWhere((c) => c.className == 'Clerc');
      // Niveau 1 + modificateur nul (score 10) = 1, minimum RAW.
      expect(clercLimit.limit, 1);
      expect(clercLimit.preparedCount, 1);
      expect(clercLimit.isAtLimit, isTrue);
    });

    test('TROIS classes qui préparent (Clerc/Druide/Paladin) : un élément par classe, ventilation générique au-delà de deux classes', () {
      final clerc = _row('Clerc', 3, classId: 10);
      final druide = _row('Druide', 2, classId: 20);
      final paladin = _row('Paladin', 4, classId: 30);
      final result = PreparedSpellsLimit.limitsByClass(
        classes: [clerc, druide, paladin],
        abilityScores: const {'wis': 14, 'cha': 10},
        spells: [
          _spell(id: 1, sourceClassIds: const {10}),
          _spell(id: 2, sourceClassIds: const {10}),
          _spell(id: 3, sourceClassIds: const {20}),
          _spell(id: 4, sourceClassIds: const {30}),
          _spell(id: 5, sourceClassIds: const {30}),
          _spell(id: 6, sourceClassIds: const {30}),
        ],
      );

      expect(result, hasLength(3));
      // Clerc niveau 3 + mod Sagesse (14 -> +2) = 5.
      final clercLimit = result.firstWhere((c) => c.className == 'Clerc');
      expect(clercLimit.limit, 5);
      expect(clercLimit.preparedCount, 2);
      expect(clercLimit.isAtLimit, isFalse);
      // Druide niveau 2 + mod Sagesse (14 -> +2) = 4.
      final druideLimit = result.firstWhere((c) => c.className == 'Druide');
      expect(druideLimit.limit, 4);
      expect(druideLimit.preparedCount, 1);
      expect(druideLimit.isAtLimit, isFalse);
      // Paladin niveau 4, demi-lanceur (4 ~/ 2 = 2) + mod Charisme (10 -> +0) = 2, atteinte par les 3 sorts ventilés à Paladin.
      final paladinLimit = result.firstWhere((c) => c.className == 'Paladin');
      expect(paladinLimit.limit, 2);
      expect(paladinLimit.preparedCount, 3);
      expect(paladinLimit.isAtLimit, isTrue);
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
    //
    // L'Artificier n'est PLUS un exemple de nom non reconnu depuis D41 (il
    // est désormais un demi-lanceur qui prépare, voir
    // `core/rules/class_spellcasting_rule.dart`) — voir le groupe de tests
    // dédié plus bas.
    test('nom de classe non reconnu ou aucune classe : à préparer '
        '(comportement d\'avant le correctif)', () {
      for (final name in ['Classe #3', 'Classe', '']) {
        expect(requires([cls(3, name)]), isTrue, reason: name);
        expect(requires([cls(3, name)], [3]), isTrue, reason: name);
      }
      // Aucune classe du tout (JSON partagé sans `classes`).
      expect(requires([]), isTrue);
      expect(requires([], [1]), isTrue);
      expect(requires([cls(3, 'Classe #3'), clerc]), isTrue);
    });

    test('Artificier (D41) : classe reconnue qui prépare, comme Clerc — '
        'toujours à préparer', () {
      final artificier = cls(3, 'Artificier');
      expect(requires([artificier], [3]), isTrue);
      expect(requires([artificier]), isTrue);
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

    test('Barde + classe inconnue ("Classe #id") : origine Barde '
        'lançable, origine inconnue ou de la classe inconnue à préparer', () {
      for (final name in ['Classe #3', 'Classe', '']) {
        final classes = [barde, cls(3, name)];
        expect(requires(classes, [1]), isFalse, reason: '$name, origine Barde');
        expect(requires(classes), isTrue, reason: '$name, sans origine');
        expect(requires(classes, [3]), isTrue, reason: '$name, origine $name');
        expect(requires(classes, [3, 1]), isFalse, reason: '$name, doublon');
      }
    });

    test('Barde + Artificier (D41, classe reconnue qui prépare) : origine '
        "Barde lançable, origine Artificier ou inconnue à préparer — même "
        'comportement que Barde + Clerc', () {
      final artificier = cls(3, 'Artificier');
      final classes = [barde, artificier];
      expect(requires(classes, [1]), isFalse);
      expect(requires(classes), isTrue);
      expect(requires(classes, [3]), isTrue);
      expect(requires(classes, [3, 1]), isFalse);
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

    test('invariant : toute classe lanceuse (registre unique, dette D04) est '
        'soit « prépare », soit « sorts connus », jamais les deux ni aucun — '
        '9 classes depuis D41 (Artificier ajouté)', () {
      final casterNames = [
        for (final characterClass in CharacterClass.values)
          if (ClassSpellcastingRegistry.ruleFor(characterClass).isCaster)
            characterClass.frenchName,
      ];
      expect(casterNames, hasLength(9));
      for (final name in casterNames) {
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

    test('invariant : une classe connue de MulticlassPrerequisites non '
        'lanceuse n\'est ni « prépare » ni « sorts connus »', () {
      final casterNames = {
        for (final characterClass in CharacterClass.values)
          if (ClassSpellcastingRegistry.ruleFor(characterClass).isCaster)
            characterClass.frenchName,
      };
      final nonCasters = [
        for (final characterClass in CharacterClass.values)
          if (MulticlassPrerequisites.isKnownClass(characterClass.frenchName) &&
              !casterNames.contains(characterClass.frenchName))
            characterClass.frenchName,
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
