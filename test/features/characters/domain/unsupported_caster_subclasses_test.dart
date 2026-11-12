import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/unsupported_caster_subclasses.dart';

CharacterDetailClassRow _row(String className, {String? subclass}) =>
    CharacterDetailClassRow(
      classId: 1,
      className: className,
      subclassName: subclass,
      level: 3,
      isPrimary: true,
      savingThrowProficiencies: const [],
      hitDie: 8,
    );

void main() {
  group('UnsupportedCasterSubclasses', () {
    test('Chevalier occulte et Escroc arcanique sont reconnus', () {
      expect(
        UnsupportedCasterSubclasses.matches(
          _row('Guerrier', subclass: 'Chevalier occulte'),
        ),
        isTrue,
      );
      expect(
        UnsupportedCasterSubclasses.matches(
          _row('Roublard', subclass: 'Escroc arcanique'),
        ),
        isTrue,
      );
    });

    test('sans accents ni casse', () {
      expect(
        UnsupportedCasterSubclasses.matches(
          _row('guerrier', subclass: 'CHEVALIER OCCULTE'),
        ),
        isTrue,
      );
    });

    test('Guerrier ou Roublard hors sous-classe lanceuse : non', () {
      expect(UnsupportedCasterSubclasses.matches(_row('Guerrier')), isFalse);
      expect(
        UnsupportedCasterSubclasses.matches(
          _row('Guerrier', subclass: 'Champion'),
        ),
        isFalse,
      );
      expect(
        UnsupportedCasterSubclasses.matches(
          _row('Roublard', subclass: 'Voleur'),
        ),
        isFalse,
      );
    });

    test('la sous-classe doit correspondre à sa classe', () {
      expect(
        UnsupportedCasterSubclasses.matches(
          _row('Roublard', subclass: 'Chevalier occulte'),
        ),
        isFalse,
      );
    });

    test('anyMatches : multiclassage', () {
      expect(
        UnsupportedCasterSubclasses.anyMatches([
          _row('Barbare'),
          _row('Roublard', subclass: 'Escroc arcanique'),
        ]),
        isTrue,
      );
      expect(
        UnsupportedCasterSubclasses.anyMatches([_row('Barbare')]),
        isFalse,
      );
    });
  });
}
