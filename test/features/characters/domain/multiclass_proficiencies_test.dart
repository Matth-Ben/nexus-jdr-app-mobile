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
}
