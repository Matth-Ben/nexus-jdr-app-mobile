import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/data/inventory_catalog_row_mapper.dart';

void main() {
  group('InventoryCatalogRowMapper.collectIds', () {
    test('collecte les id en Set<String>', () {
      final rows = [
        {'id': 1},
        {'id': 2},
      ];
      expect(InventoryCatalogRowMapper.collectIds(rows), {'1', '2'});
    });
  });

  group('InventoryCatalogRowMapper.parseCostAmount', () {
    test('extrait cost->>amount en double', () {
      expect(
        InventoryCatalogRowMapper.parseCostAmount({
          'amount': 2.5,
          'currency': 'gp',
        }),
        2.5,
      );
    });

    test('null/type inattendu retombe sur 0 (jamais null, un objet du '
        'catalogue d\'ajout a toujours un coût affichable)', () {
      expect(InventoryCatalogRowMapper.parseCostAmount(null), 0);
      expect(InventoryCatalogRowMapper.parseCostAmount({}), 0);
    });
  });

  group('InventoryCatalogRowMapper.parseWeight', () {
    test('extrait weight en double', () {
      expect(InventoryCatalogRowMapper.parseWeight(0.5), 0.5);
    });

    test('null/type inattendu retombe sur null', () {
      expect(InventoryCatalogRowMapper.parseWeight(null), isNull);
    });
  });

  group('InventoryCatalogRowMapper.toInventoryCatalogItem', () {
    test('résout id/nom/catégorie/coût/poids', () {
      final result = InventoryCatalogRowMapper.toInventoryCatalogItem(
        {
          'id': 1,
          'category': 'arme',
          'weight': 0.5,
          'cost': {'amount': 2, 'currency': 'gp'},
        },
        names: const {'1': 'Dague'},
      );

      expect(result.id, 1);
      expect(result.name, 'Dague');
      expect(result.category, 'arme');
      expect(result.costAmount, 2);
      expect(result.weight, 0.5);
    });

    test('un id sans traduction résolue retombe sur un libellé générique', () {
      final result = InventoryCatalogRowMapper.toInventoryCatalogItem({
        'id': 42,
        'category': 'outil',
        'weight': null,
        'cost': null,
      }, names: const {});

      expect(result.name, 'Objet #42');
      expect(result.weight, isNull);
      expect(result.costAmount, 0);
    });

    test('une catégorie manquante/inattendue retombe sur '
        "'equipement_general'", () {
      final result = InventoryCatalogRowMapper.toInventoryCatalogItem({
        'id': 1,
        'weight': null,
        'cost': null,
      }, names: const {});

      expect(result.category, 'equipement_general');
    });
  });

  group('InventoryCatalogRowMapper.toInventoryCatalogItems', () {
    test('mappe une liste complète de lignes', () {
      final rows = [
        {'id': 1, 'category': 'arme', 'weight': 0.5, 'cost': null},
        {'id': 2, 'category': 'outil', 'weight': null, 'cost': null},
      ];

      final result = InventoryCatalogRowMapper.toInventoryCatalogItems(
        rows,
        names: const {'1': 'Dague', '2': 'Kit de crochetage'},
      );

      expect(result, hasLength(2));
      expect(result[0].name, 'Dague');
      expect(result[1].name, 'Kit de crochetage');
    });
  });
}
