// Tests unitaires de `EditionContentResolver` — logique pure, aucun mock
// réseau nécessaire. Voir sa documentation de classe pour le rationale RAW
// (chantier "choix d'édition 2014/2024 par personnage").

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/edition_content_resolver.dart';

void main() {
  group('EditionContentResolver.resolve', () {
    test('préfère la ligne dont edition correspond exactement à celle du '
        'personnage, pour une clé partagée par les deux éditions (ex. '
        'Métamagie Ensorceleur, niveau 10 commun aux deux éditions)', () {
      final rows = [
        {'id': 214, 'level': 10, 'edition': '2014'},
        {'id': 9999, 'level': 10, 'edition': '2024'},
      ];

      expect(
        EditionContentResolver.resolve(
          rows,
          edition: '2014',
          keyOf: (row) => row['level'],
        ),
        [rows[0]],
      );
      expect(
        EditionContentResolver.resolve(
          rows,
          edition: '2024',
          keyOf: (row) => row['level'],
        ),
        [rows[1]],
      );
    });

    test('retombe sur la ligne edition IS NULL quand aucune ligne ne '
        'correspond exactement à l\'édition demandée (ex. Expertise '
        'Roublard, applicable aux deux éditions)', () {
      final rows = [
        {'id': 33, 'level': 1, 'edition': null},
      ];

      expect(
        EditionContentResolver.resolve(
          rows,
          edition: '2014',
          keyOf: (row) => row['level'],
        ),
        [rows[0]],
      );
      expect(
        EditionContentResolver.resolve(
          rows,
          edition: '2024',
          keyOf: (row) => row['level'],
        ),
        [rows[0]],
      );
    });

    test('ne retient JAMAIS une ligne d\'une AUTRE édition que celle demandée '
        'quand aucune ligne edition IS NULL n\'existe en secours (jamais de '
        'règle d\'une édition non choisie)', () {
      final rows = [
        {'id': 1, 'level': 2, 'edition': '2024'},
      ];

      expect(
        EditionContentResolver.resolve(
          rows,
          edition: '2014',
          keyOf: (row) => row['level'],
        ),
        isEmpty,
      );
    });

    test('résout chaque niveau indépendamment (Métamagie : niveaux 3/10/17 en '
        '2014 contre 2/10/17 en 2024, un seul set par personnage, jamais les '
        '6 lignes à la fois)', () {
      final rows = [
        {'id': 211, 'level': 3, 'edition': '2014'},
        {'id': 214, 'level': 10, 'edition': '2014'},
        {'id': 217, 'level': 17, 'edition': '2014'},
        {'id': 1001, 'level': 2, 'edition': '2024'},
        {'id': 1002, 'level': 10, 'edition': '2024'},
        {'id': 1003, 'level': 17, 'edition': '2024'},
      ];

      final resolved2014 = EditionContentResolver.resolve(
        rows,
        edition: '2014',
        keyOf: (row) => row['level'],
      );
      expect(resolved2014, hasLength(3));
      expect(resolved2014.map((row) => row['id']).toSet(), {211, 214, 217});

      final resolved2024 = EditionContentResolver.resolve(
        rows,
        edition: '2024',
        keyOf: (row) => row['level'],
      );
      expect(resolved2024, hasLength(3));
      expect(resolved2024.map((row) => row['id']).toSet(), {1001, 1002, 1003});
    });

    test('liste vide en entrée -> liste vide en sortie', () {
      expect(
        EditionContentResolver.resolve(
          const [],
          edition: '2014',
          keyOf: (row) => row['level'],
        ),
        isEmpty,
      );
    });
  });
}
