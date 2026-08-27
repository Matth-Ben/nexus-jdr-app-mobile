import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/data/character_inventory_row_mapper.dart';

void main() {
  group('CharacterInventoryRowMapper.rowsOf', () {
    test('extrait la liste character_inventory embarquée', () {
      final row = {
        'character_inventory': [
          {'id': 'a'},
        ],
      };
      expect(CharacterInventoryRowMapper.rowsOf(row), hasLength(1));
    });

    test('retombe sur une liste vide quand absent/nul', () {
      expect(CharacterInventoryRowMapper.rowsOf({}), isEmpty);
    });
  });

  group('CharacterInventoryRowMapper.collectItemIds', () {
    test('collecte les item_id non nuls en Set<String>', () {
      final rows = [
        {'item_id': 1},
        {'item_id': 2},
        {'item_id': null, 'custom_name': 'Petit sac de sable'},
      ];
      expect(CharacterInventoryRowMapper.collectItemIds(rows), {'1', '2'});
    });
  });

  group('CharacterInventoryRowMapper.parseUnitWeight', () {
    test('extrait items.weight en double', () {
      expect(CharacterInventoryRowMapper.parseUnitWeight({'weight': 1.5}), 1.5);
    });

    test('null/type inattendu retombe sur null', () {
      expect(CharacterInventoryRowMapper.parseUnitWeight(null), isNull);
      expect(
        CharacterInventoryRowMapper.parseUnitWeight({'weight': null}),
        isNull,
      );
    });
  });

  group('CharacterInventoryRowMapper.toCharacterInventoryItems', () {
    test('résout un objet du catalogue : nom via translations, poids = '
        'poids unitaire × quantité', () {
      final rows = [
        {
          'id': 'inv-1',
          'item_id': 1,
          'custom_name': null,
          'quantity': 2,
          'equipped': false,
          'items': {'category': 'arme', 'weight': 0.5},
        },
      ];

      final result = CharacterInventoryRowMapper.toCharacterInventoryItems(
        rows,
        names: const {'1': 'Dague'},
      );

      expect(result, hasLength(1));
      expect(result.single.id, 'inv-1');
      expect(result.single.itemId, 1);
      expect(result.single.name, 'Dague');
      expect(result.single.category, 'arme');
      expect(result.single.quantity, 2);
      expect(result.single.equipped, isFalse);
      expect(result.single.totalWeight, 1.0);
      expect(result.single.isCustom, isFalse);
    });

    test('un item_id sans traduction résolue retombe sur un libellé '
        'générique', () {
      final rows = [
        {
          'id': 'inv-1',
          'item_id': 99,
          'quantity': 1,
          'equipped': false,
          'items': {'category': 'outil', 'weight': null},
        },
      ];

      final result = CharacterInventoryRowMapper.toCharacterInventoryItems(
        rows,
        names: const {},
      );

      expect(result.single.name, 'Objet #99');
      // items.weight nul en base -> poids total inconnu, pas 0.
      expect(result.single.totalWeight, isNull);
    });

    test('un objet personnalisé (item_id nul) affiche custom_name, catégorie '
        'et poids inconnus (aucune ligne items à résoudre)', () {
      final rows = [
        {
          'id': 'inv-2',
          'item_id': null,
          'custom_name': 'Petit sac de sable',
          'quantity': 1,
          'equipped': false,
        },
      ];

      final result = CharacterInventoryRowMapper.toCharacterInventoryItems(
        rows,
        names: const {},
      );

      expect(result.single.name, 'Petit sac de sable');
      expect(result.single.category, isNull);
      expect(result.single.totalWeight, isNull);
      expect(result.single.isCustom, isTrue);
    });

    test('equipped == true est reflété tel quel', () {
      final rows = [
        {
          'id': 'inv-3',
          'item_id': 1,
          'quantity': 1,
          'equipped': true,
          'items': {'category': 'objet_magique', 'weight': null},
        },
      ];

      final result = CharacterInventoryRowMapper.toCharacterInventoryItems(
        rows,
        names: const {'1': 'Grimoire'},
      );

      expect(result.single.equipped, isTrue);
    });

    test('quantity == 0 -> poids de ligne inconnu (null), pas "0 kg" '
        'trompeur (character_inventory.quantity n\'a aucune contrainte '
        'CHECK côté base)', () {
      final rows = [
        {
          'id': 'inv-4',
          'item_id': 1,
          'quantity': 0,
          'equipped': false,
          'items': {'category': 'arme', 'weight': 0.5},
        },
      ];

      final result = CharacterInventoryRowMapper.toCharacterInventoryItems(
        rows,
        names: const {'1': 'Dague'},
      );

      expect(result.single.quantity, 0);
      expect(result.single.totalWeight, isNull);
    });

    test('quantity négative -> poids de ligne inconnu (null), jamais un '
        'poids négatif qui fausserait le total agrégé', () {
      final rows = [
        {
          'id': 'inv-5',
          'item_id': 1,
          'quantity': -3,
          'equipped': false,
          'items': {'category': 'arme', 'weight': 0.5},
        },
      ];

      final result = CharacterInventoryRowMapper.toCharacterInventoryItems(
        rows,
        names: const {'1': 'Dague'},
      );

      expect(result.single.quantity, -3);
      expect(result.single.totalWeight, isNull);
    });

    test('une ligne sans id exploitable est ignorée', () {
      final rows = [
        {'id': null, 'item_id': 1, 'quantity': 1, 'equipped': false},
      ];
      expect(
        CharacterInventoryRowMapper.toCharacterInventoryItems(
          rows,
          names: const {},
        ),
        isEmpty,
      );
    });
  });
}
