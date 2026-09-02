import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/data/class_feature_row_mapper.dart';

void main() {
  group('ClassFeatureRowMapper.collectIds', () {
    test('collecte les id en Set<String>', () {
      final rows = [
        {'id': 10, 'class_id': 1, 'level': 1},
        {'id': 11, 'class_id': 1, 'level': 2},
      ];
      expect(ClassFeatureRowMapper.collectIds(rows), {'10', '11'});
    });
  });

  group('ClassFeatureRowMapper.filterAttained', () {
    test('ne garde que les aptitudes dont le niveau est atteint', () {
      final rows = [
        {'id': 1, 'class_id': 5, 'level': 1},
        {'id': 2, 'class_id': 5, 'level': 2},
        {'id': 3, 'class_id': 5, 'level': 5}, // pas encore atteint
      ];

      final result = ClassFeatureRowMapper.filterAttained(
        rows,
        classLevels: const {'5': 3},
      );

      expect(result.map((r) => r['id']), [1, 2]);
    });

    test('filtre par classe : une classe absente de classLevels est ignorée '
        '(ne devrait pas arriver, sécurité)', () {
      final rows = [
        {'id': 1, 'class_id': 5, 'level': 1},
        {'id': 2, 'class_id': 7, 'level': 1},
      ];

      final result = ClassFeatureRowMapper.filterAttained(
        rows,
        classLevels: const {'5': 3},
      );

      expect(result.map((r) => r['id']), [1]);
    });

    test('une ligne sans class_id (aptitude de sous-classe) est ignorée', () {
      final rows = [
        {'id': 1, 'class_id': null, 'subclass_id': 9, 'level': 1},
      ];

      final result = ClassFeatureRowMapper.filterAttained(
        rows,
        classLevels: const {'5': 3},
      );

      expect(result, isEmpty);
    });

    test('préserve l\'ordre des lignes reçues (ne trie jamais lui-même) : '
        'l\'affichage déterministe repose entièrement sur `.order(\'level\')` '
        'côté requête (SupabaseCharacterRepository._buildCharacterDetailPayload'
        '/_mapCharacterDetailPayload), pas '
        'sur ce mapper — un personnage multiclassé (plusieurs class_id '
        'mélangés dans une même requête) dépend de cette garantie pour ne pas '
        'afficher un ordre différent à chaque rechargement', () {
      // Deux classes mélangées, déjà pré-triées par niveau croissant comme
      // le ferait `.order('level')` — filterAttained ne doit ni re-trier
      // ni regrouper par classe.
      final rows = [
        {'id': 10, 'class_id': 5, 'level': 1},
        {'id': 20, 'class_id': 7, 'level': 1},
        {'id': 11, 'class_id': 5, 'level': 2},
        {'id': 21, 'class_id': 7, 'level': 3},
      ];

      final result = ClassFeatureRowMapper.filterAttained(
        rows,
        classLevels: const {'5': 5, '7': 5},
      );

      expect(result.map((r) => r['id']), [10, 20, 11, 21]);
    });
  });

  group('ClassFeatureRowMapper.parseUsesRemaining', () {
    test('construit {class_feature_id: uses_remaining}', () {
      final rows = [
        {'class_feature_id': 1, 'uses_remaining': 2},
        {'class_feature_id': 3, 'uses_remaining': 0},
      ];
      expect(ClassFeatureRowMapper.parseUsesRemaining(rows), {'1': 2, '3': 0});
    });

    test(
      'ignore une ligne sans class_feature_id/uses_remaining exploitable',
      () {
        final rows = [
          {'class_feature_id': null, 'uses_remaining': 2},
          {'class_feature_id': 2, 'uses_remaining': null},
        ];
        expect(ClassFeatureRowMapper.parseUsesRemaining(rows), isEmpty);
      },
    );
  });

  group('ClassFeatureRowMapper.toCharacterClassFeature', () {
    test('aptitude à usage limité : résout usesMax/restType/usesRemaining', () {
      final row = {
        'id': 1,
        'class_id': 5,
        'level': 2,
        'uses_per_rest': {'amount': 1, 'rest_type': 'repos_court'},
      };

      final feature = ClassFeatureRowMapper.toCharacterClassFeature(
        row,
        names: const {'1': 'Conduit divin'},
        usesRemaining: const {'1': 0},
      );

      expect(feature.id, 1);
      expect(feature.name, 'Conduit divin');
      expect(feature.level, 2);
      expect(feature.usesMax, 1);
      expect(feature.usesRemaining, 0);
      expect(feature.restType, 'repos_court');
      expect(feature.isPassive, isFalse);
    });

    test('aptitude passive : uses_per_rest nul', () {
      final row = {'id': 2, 'class_id': 5, 'level': 1, 'uses_per_rest': null};

      final feature = ClassFeatureRowMapper.toCharacterClassFeature(
        row,
        names: const {'2': 'Défense sans armure'},
        usesRemaining: const {},
      );

      expect(feature.usesMax, isNull);
      expect(feature.usesRemaining, isNull);
      expect(feature.isPassive, isTrue);
    });

    test('un id sans nom résolu retombe sur un libellé générique', () {
      final row = {'id': 42, 'class_id': 5, 'level': 1};

      final feature = ClassFeatureRowMapper.toCharacterClassFeature(
        row,
        names: const {},
        usesRemaining: const {},
      );

      expect(feature.name, 'Aptitude #42');
    });

    test('résout description quand présente, chaîne vide sinon', () {
      final withDescription = ClassFeatureRowMapper.toCharacterClassFeature(
        {
          'id': 1,
          'class_id': 5,
          'level': 1,
          'description': 'Une description complète.',
        },
        names: const {},
        usesRemaining: const {},
      );
      expect(withDescription.description, 'Une description complète.');

      final withoutDescription = ClassFeatureRowMapper.toCharacterClassFeature(
        {'id': 2, 'class_id': 5, 'level': 1},
        names: const {},
        usesRemaining: const {},
      );
      expect(withoutDescription.description, '');
    });
  });
}
