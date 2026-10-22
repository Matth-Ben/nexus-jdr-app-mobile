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
        characterEdition: '2014',
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
        characterEdition: '2014',
      );

      expect(result.map((r) => r['id']), [1]);
    });

    test('une ligne de sous-classe (class_id nul) est ignorée tant que '
        'subclassLevels n\'est pas fourni (compatibilité arrière, appelant '
        'non mis à jour)', () {
      final rows = [
        {'id': 1, 'class_id': null, 'subclass_id': 9, 'level': 1},
      ];

      final result = ClassFeatureRowMapper.filterAttained(
        rows,
        classLevels: const {'5': 3},
        characterEdition: '2014',
      );

      expect(result, isEmpty);
    });

    test('bug architectural corrigé : une ligne de sous-classe '
        '(class_id nul, subclass_id non nul) est désormais incluse si son '
        'niveau est atteint par la classe qui porte cette sous-classe '
        '(subclassLevels)', () {
      final rows = [
        {'id': 1, 'class_id': null, 'subclass_id': 9, 'level': 3},
        // Pas encore atteint par le niveau de la classe porteuse (5).
        {'id': 2, 'class_id': null, 'subclass_id': 9, 'level': 7},
      ];

      final result = ClassFeatureRowMapper.filterAttained(
        rows,
        classLevels: const {},
        subclassLevels: const {'9': 5},
        characterEdition: '2014',
      );

      expect(result.map((r) => r['id']), [1]);
    });

    test('aptitudes de classe de base ET de sous-classe mélangées : chacune '
        'filtrée par la bonne map (classLevels pour class_id, '
        'subclassLevels pour subclass_id), sans interférence entre les '
        'deux', () {
      final rows = [
        {'id': 1, 'class_id': 5, 'subclass_id': null, 'level': 1},
        {'id': 2, 'class_id': null, 'subclass_id': 9, 'level': 3},
        // Classe de base niveau 10, pas encore atteint par la classe (3).
        {'id': 3, 'class_id': 5, 'subclass_id': null, 'level': 10},
      ];

      final result = ClassFeatureRowMapper.filterAttained(
        rows,
        classLevels: const {'5': 3},
        subclassLevels: const {'9': 3},
        characterEdition: '2014',
      );

      expect(result.map((r) => r['id']), [1, 2]);
    });

    test('une ligne de sous-classe dont la sous-classe est absente de '
        'subclassLevels (ne devrait pas arriver, sécurité) est ignorée', () {
      final rows = [
        {'id': 1, 'class_id': null, 'subclass_id': 9, 'level': 1},
      ];

      final result = ClassFeatureRowMapper.filterAttained(
        rows,
        classLevels: const {},
        subclassLevels: const {'99': 10},
        characterEdition: '2014',
      );

      expect(result, isEmpty);
    });

    test('une ligne sans class_id NI subclass_id exploitable est ignorée '
        '(ne devrait pas arriver)', () {
      final rows = [
        {'id': 1, 'class_id': null, 'subclass_id': null, 'level': 1},
      ];

      final result = ClassFeatureRowMapper.filterAttained(
        rows,
        classLevels: const {'5': 3},
        subclassLevels: const {'9': 3},
        characterEdition: '2014',
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
        characterEdition: '2014',
      );

      expect(result.map((r) => r['id']), [10, 20, 11, 21]);
    });

    // Non-régression : contenu pilote "choix d'édition 2014/2024 par
    // personnage" — une mécanique dont le contenu diffère entre éditions
    // (ex. Métamagie de l'Ensorceleur) peut désormais avoir 2 lignes
    // `class_features` sous le même nom, une par édition, potentiellement
    // au même niveau. Sans le filtre `edition` de `filterAttained`, un
    // personnage `edition: '2014'` verrait les DEUX lignes retenues (même
    // niveau atteint pour les deux) et donc l'aptitude affichée EN DOUBLE
    // sur la carte "APTITUDES DE CLASSE" — même bug que D94/D110
    // (doublon multiclasse), mais pour la dimension édition.
    test('exclut une ligne class_features dont `edition` diffère de celle '
        'du personnage, même niveau atteint pour les deux (régression '
        'doublon "Métamagie" 2014/2024)', () {
      final rows = [
        {'id': 1, 'class_id': 5, 'level': 3, 'edition': '2014'},
        {'id': 2, 'class_id': 5, 'level': 3, 'edition': '2024'},
      ];

      final result = ClassFeatureRowMapper.filterAttained(
        rows,
        classLevels: const {'5': 3},
        characterEdition: '2014',
      );

      expect(result.map((r) => r['id']), [1]);
    });

    test('exclut une ligne class_features dont `edition` diffère de celle '
        'du personnage — symétrique, personnage `edition: \'2024\'`', () {
      final rows = [
        {'id': 1, 'class_id': 5, 'level': 3, 'edition': '2014'},
        {'id': 2, 'class_id': 5, 'level': 3, 'edition': '2024'},
      ];

      final result = ClassFeatureRowMapper.filterAttained(
        rows,
        classLevels: const {'5': 3},
        characterEdition: '2024',
      );

      expect(result.map((r) => r['id']), [2]);
    });

    test('une ligne `edition IS NULL` (contenu inchangé entre les deux '
        'éditions) n\'est jamais exclue par ce filtre, quelle que soit '
        'characterEdition', () {
      final rows = [
        {'id': 1, 'class_id': 5, 'level': 3, 'edition': null},
      ];

      expect(
        ClassFeatureRowMapper.filterAttained(
          rows,
          classLevels: const {'5': 3},
          characterEdition: '2014',
        ).map((r) => r['id']),
        [1],
      );
      expect(
        ClassFeatureRowMapper.filterAttained(
          rows,
          classLevels: const {'5': 3},
          characterEdition: '2024',
        ).map((r) => r['id']),
        [1],
      );
    });

    test('une ligne sans clé `edition` du tout (select ne l\'a pas '
        'demandée) est traitée comme `edition IS NULL`, jamais exclue', () {
      final rows = [
        {'id': 1, 'class_id': 5, 'level': 3},
      ];

      final result = ClassFeatureRowMapper.filterAttained(
        rows,
        classLevels: const {'5': 3},
        characterEdition: '2024',
      );

      expect(result.map((r) => r['id']), [1]);
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
        descriptions: const {},
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
        descriptions: const {},
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
        descriptions: const {},
        usesRemaining: const {},
      );

      expect(feature.name, 'Aptitude #42');
    });

    test('résout description depuis la map résolue (translations), chaîne '
        'vide sinon — pas de colonne `description` directe sur '
        '`class_features` (voir SupabaseCharacterRepository, régression '
        '42703 corrigée)', () {
      final withDescription = ClassFeatureRowMapper.toCharacterClassFeature(
        {'id': 1, 'class_id': 5, 'level': 1},
        names: const {},
        descriptions: const {'1': 'Une description complète.'},
        usesRemaining: const {},
      );
      expect(withDescription.description, 'Une description complète.');

      final withoutDescription = ClassFeatureRowMapper.toCharacterClassFeature(
        {'id': 2, 'class_id': 5, 'level': 1},
        names: const {},
        descriptions: const {},
        usesRemaining: const {},
      );
      expect(withoutDescription.description, '');
    });

    test(
      'override "Supériorité martiale" (Guerrier Maître de guerre, '
      'choice_type == manoeuvre) : usesMax suit la table RAW du niveau '
      'EFFECTIF (ownerLevel), jamais la valeur statique de uses_per_rest',
      () {
        // Niveau 7 : RAW 5 dés, alors que la base stocke statiquement 4
        // (valeur RAW-exacte seulement pour les niveaux 3-6).
        final feature = ClassFeatureRowMapper.toCharacterClassFeature(
          {
            'id': 747,
            'subclass_id': 48,
            'level': 3,
            'uses_per_rest': {'amount': 4, 'rest_type': 'repos_court'},
            'choice_type': 'manoeuvre',
          },
          names: const {'747': 'Supériorité martiale'},
          descriptions: const {},
          usesRemaining: const {},
          ownerLevel: 7,
        );

        expect(feature.usesMax, 5);
        expect(feature.restType, 'repos_court');
      },
    );

    test('override "Supériorité martiale" : retombe sur la valeur statique '
        'quand ownerLevel est null (comportement historique, ex. '
        '`fetchLevelUpLevelData` qui ne le fournit jamais)', () {
      final feature = ClassFeatureRowMapper.toCharacterClassFeature(
        {
          'id': 747,
          'subclass_id': 48,
          'level': 3,
          'uses_per_rest': {'amount': 4, 'rest_type': 'repos_court'},
          'choice_type': 'manoeuvre',
        },
        names: const {},
        descriptions: const {},
        usesRemaining: const {},
      );

      expect(feature.usesMax, 4);
    });

    test('une aptitude dont choice_type n\'est pas "manoeuvre" n\'est jamais '
        'affectée par l\'override, même avec un ownerLevel fourni', () {
      final feature = ClassFeatureRowMapper.toCharacterClassFeature(
        {
          'id': 1,
          'class_id': 5,
          'level': 2,
          'uses_per_rest': {'amount': 1, 'rest_type': 'repos_court'},
          'choice_type': 'sous_classe',
        },
        names: const {},
        descriptions: const {},
        usesRemaining: const {},
        ownerLevel: 15,
      );

      expect(feature.usesMax, 1);
    });
  });

  group('ClassFeatureRowMapper.ownerLevelOf', () {
    test('résout via classLevels quand class_id est non nul', () {
      final level = ClassFeatureRowMapper.ownerLevelOf(
        {'id': 1, 'class_id': 5, 'level': 1},
        classLevels: const {'5': 4},
        subclassLevels: const {},
      );
      expect(level, 4);
    });

    test('résout via subclassLevels quand class_id est nul et subclass_id '
        'non nul', () {
      final level = ClassFeatureRowMapper.ownerLevelOf(
        {'id': 1, 'class_id': null, 'subclass_id': 48, 'level': 3},
        classLevels: const {},
        subclassLevels: const {'48': 7},
      );
      expect(level, 7);
    });

    test(
      'null quand ni class_id ni subclass_id ne sont résolus (défensif)',
      () {
        final level = ClassFeatureRowMapper.ownerLevelOf(
          {'id': 1, 'class_id': null, 'subclass_id': null, 'level': 1},
          classLevels: const {},
          subclassLevels: const {},
        );
        expect(level, isNull);
      },
    );
  });

  group('ClassFeatureRowMapper.effectiveUsesMax', () {
    test('une aptitude passive (uses_per_rest nul) reste passive même avec '
        'choice_type == manoeuvre et un ownerLevel fourni (défensif : ne '
        'devrait jamais arriver en pratique pour id747)', () {
      final usesMax = ClassFeatureRowMapper.effectiveUsesMax({
        'id': 747,
        'subclass_id': 48,
        'level': 3,
        'uses_per_rest': null,
        'choice_type': 'manoeuvre',
      }, ownerLevel: 10);
      expect(usesMax, isNull);
    });

    test('override exact aux 5 paliers RAW de la réserve de dés de '
        'supériorité (4/5/5/6/6)', () {
      const row = {
        'id': 747,
        'subclass_id': 48,
        'level': 3,
        'uses_per_rest': {'amount': 4, 'rest_type': 'repos_court'},
        'choice_type': 'manoeuvre',
      };
      expect(ClassFeatureRowMapper.effectiveUsesMax(row, ownerLevel: 3), 4);
      expect(ClassFeatureRowMapper.effectiveUsesMax(row, ownerLevel: 6), 4);
      expect(ClassFeatureRowMapper.effectiveUsesMax(row, ownerLevel: 7), 5);
      expect(ClassFeatureRowMapper.effectiveUsesMax(row, ownerLevel: 10), 5);
      expect(ClassFeatureRowMapper.effectiveUsesMax(row, ownerLevel: 15), 6);
      expect(ClassFeatureRowMapper.effectiveUsesMax(row, ownerLevel: 18), 6);
    });
  });
}
