import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/character_creation/data/item_row_mapper.dart';

void main() {
  group('collectIds', () {
    test('normalise les ids int en String et déduplique', () {
      final rows = [
        {'id': 1},
        {'id': 2},
        {'id': 1},
      ];
      expect(ItemRowMapper.collectIds(rows), {'1', '2'});
    });

    test('ignore les ids nuls', () {
      expect(ItemRowMapper.collectIds([{}]), isEmpty);
    });
  });

  group('parseTranslatedValues', () {
    test('lit les colonnes réelles entity_id/value', () {
      final values = ItemRowMapper.parseTranslatedValues([
        {'entity_id': '1', 'value': 'Gourdin'},
        {'entity_id': '2', 'value': 'Dague'},
      ]);
      expect(values, {'1': 'Gourdin', '2': 'Dague'});
    });

    test('ignore une ligne sans entity_id ou sans value exploitable', () {
      final values = ItemRowMapper.parseTranslatedValues([
        {'entity_id': '1', 'value': null},
        {'entity_id': null, 'value': 'Orphelin'},
        {'entity_id': '3', 'value': 'Bâton de combat'},
      ]);
      expect(values, {'3': 'Bâton de combat'});
    });
  });

  group('parseCostAmount', () {
    test('extrait le montant numérique de la clé "amount"', () {
      expect(ItemRowMapper.parseCostAmount({'amount': 2, 'currency': 'gp'}), 2);
      expect(
        ItemRowMapper.parseCostAmount({'amount': 0.05, 'currency': 'gp'}),
        0.05,
      );
    });

    test('type inattendu (null, liste au lieu de map) -> 0', () {
      expect(ItemRowMapper.parseCostAmount(null), 0);
      expect(ItemRowMapper.parseCostAmount(['amount']), 0);
    });

    test('clé "amount" absente ou de type inattendu -> 0', () {
      expect(ItemRowMapper.parseCostAmount({'currency': 'gp'}), 0);
      expect(
        ItemRowMapper.parseCostAmount({'amount': 'beaucoup', 'currency': 'gp'}),
        0,
      );
    });
  });

  group('toItemOption', () {
    test('résout le nom via la map de traductions et le coût via `cost`', () {
      final item = ItemRowMapper.toItemOption(
        {
          'id': 1,
          'category': 'arme',
          'cost': {'amount': 2, 'currency': 'gp'},
        },
        names: {'1': 'Dague'},
      );

      expect(item.id, 1);
      expect(item.name, 'Dague');
      expect(item.category, 'arme');
      expect(item.costAmount, 2);
    });

    test('id sans traduction résolue -> libellé générique plutôt que '
        'crash', () {
      final item = ItemRowMapper.toItemOption({
        'id': 99,
        'category': 'outil',
      }, names: const {});

      expect(item.name, 'Objet #99');
      expect(item.category, 'outil');
      expect(item.costAmount, 0);
    });

    test('catégorie manquante -> retombe sur "equipement_general"', () {
      final item = ItemRowMapper.toItemOption(
        {'id': 5},
        names: {'5': 'Sac à dos'},
      );

      expect(item.category, 'equipement_general');
    });

    test('weapon_properties.properties contient "à deux mains" -> '
        'isTwoHanded true', () {
      final item = ItemRowMapper.toItemOption(
        {
          'id': 14,
          'category': 'arme',
          'weapon_properties': {
            'properties': ['à deux mains', 'lourde'],
          },
        },
        names: {'14': 'Épée à deux mains'},
      );

      expect(item.isTwoHanded, isTrue);
    });

    test('weapon_properties sans "à deux mains" -> isTwoHanded false', () {
      final item = ItemRowMapper.toItemOption(
        {
          'id': 1,
          'category': 'arme',
          'weapon_properties': {
            'properties': ['légère', 'finesse'],
          },
        },
        names: {'1': 'Dague'},
      );

      expect(item.isTwoHanded, isFalse);
    });

    test('weapon_properties absente (objet non-arme) -> isTwoHanded false '
        'plutôt que de crasher', () {
      final item = ItemRowMapper.toItemOption(
        {'id': 2, 'category': 'equipement_general'},
        names: {'2': 'Sac à dos'},
      );

      expect(item.isTwoHanded, isFalse);
    });

    test('weapon_properties renvoyée en liste à un élément (variante '
        'PostgREST) -> gérée comme un objet direct', () {
      final item = ItemRowMapper.toItemOption(
        {
          'id': 14,
          'category': 'arme',
          'weapon_properties': [
            {
              'properties': ['à deux mains'],
            },
          ],
        },
        names: {'14': 'Épée à deux mains'},
      );

      expect(item.isTwoHanded, isTrue);
    });
  });
}
