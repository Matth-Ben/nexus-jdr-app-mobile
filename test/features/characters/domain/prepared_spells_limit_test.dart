import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/prepared_spells_limit.dart';

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
}
