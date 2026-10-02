import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/proficiency_token_title_formatter.dart';

void main() {
  group('ProficiencyTokenTitleFormatter.titleFor', () {
    const expectedByToken = {
      'courantes': 'ARMES COURANTES',
      'martiales': 'ARMES DE GUERRE',
      'légère': 'ARMURES LÉGÈRES',
      'intermédiaire': 'ARMURES INTERMÉDIAIRES',
      'lourde': 'ARMURES LOURDES',
      'boucliers': 'BOUCLIERS',
      'intermédiaire (non métallique)':
          'ARMURES INTERMÉDIAIRES (NON MÉTALLIQUES)',
      'boucliers (non métalliques)': 'BOUCLIERS (NON MÉTALLIQUES)',
    };

    for (final entry in expectedByToken.entries) {
      test('${entry.key} -> ${entry.value}', () {
        expect(ProficiencyTokenTitleFormatter.titleFor(entry.key), entry.value);
      });
    }

    test('insensible à la casse pour le vocabulaire connu', () {
      expect(
        ProficiencyTokenTitleFormatter.titleFor('MARTIALES'),
        'ARMES DE GUERRE',
      );
    });

    test('token déjà spécifique : repli token.toUpperCase() (accents '
        'conservés, jamais le nom d\'un objet résolu)', () {
      expect(ProficiencyTokenTitleFormatter.titleFor('dagues'), 'DAGUES');
      expect(
        ProficiencyTokenTitleFormatter.titleFor('épées courtes'),
        'ÉPÉES COURTES',
      );
    });
  });
}
