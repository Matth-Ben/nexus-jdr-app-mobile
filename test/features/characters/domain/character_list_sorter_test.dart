import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_list_sort.dart';
import 'package:personnages/features/characters/domain/character_list_sorter.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';

CharacterSummary _character(
  String id, {
  String? name,
  bool isDead = false,
  bool isArchived = false,
}) {
  return CharacterSummary(
    id: id,
    name: name ?? id,
    level: 1,
    xp: 0,
    isDead: isDead,
    isArchived: isArchived,
  );
}

void main() {
  group('CharacterListSorter.sort', () {
    test('place les personnages en jeu avant les archives, eux-memes avant '
        'les morts', () {
      final dead = _character('dead', isDead: true);
      final archived = _character('archived', isArchived: true);
      final active = _character('active');

      final result = CharacterListSorter.sort([dead, archived, active]);

      expect(result.map((c) => c.id), ['active', 'archived', 'dead']);
    });

    test('un personnage mort ET archive est classe avec les morts (statut le '
        'plus definitif)', () {
      final deadAndArchived = _character(
        'dead-and-archived',
        isDead: true,
        isArchived: true,
      );
      final archived = _character('archived', isArchived: true);

      final result = CharacterListSorter.sort([deadAndArchived, archived]);

      expect(result.map((c) => c.id), ['archived', 'dead-and-archived']);
    });

    test('conserve l\'ordre relatif d\'origine au sein d\'un meme groupe', () {
      final active1 = _character('active-1');
      final active2 = _character('active-2');
      final archived1 = _character('archived-1', isArchived: true);
      final archived2 = _character('archived-2', isArchived: true);

      final result = CharacterListSorter.sort([
        archived2,
        active2,
        archived1,
        active1,
      ]);

      expect(result.map((c) => c.id), [
        'active-2',
        'active-1',
        'archived-2',
        'archived-1',
      ]);
    });

    test('liste vide -> liste vide', () {
      expect(CharacterListSorter.sort(const []), isEmpty);
    });

    test('un seul personnage -> renvoye tel quel', () {
      final only = _character('only');

      expect(CharacterListSorter.sort([only]), [only]);
    });

    test('tous les personnages dans le meme groupe -> ordre inchange', () {
      final active1 = _character('active-1');
      final active2 = _character('active-2');
      final active3 = _character('active-3');

      final result = CharacterListSorter.sort([active1, active2, active3]);

      expect(result, [active1, active2, active3]);
    });
  });

  group('CharacterListSorter.sortBy (P18)', () {
    List<String> ids(List<CharacterSummary> list) =>
        list.map((c) => c.id).toList();

    test('par défaut : identique à sort (groupes + ordre de création)', () {
      final list = [
        _character('d', isDead: true),
        _character('a', isArchived: true),
        _character('x'),
        _character('y'),
      ];
      expect(
        ids(
          CharacterListSorter.sortBy(list, CharacterListSort.defaultOrder, {}),
        ),
        ids(CharacterListSorter.sort(list)),
      );
      expect(
        ids(
          CharacterListSorter.sortBy(list, CharacterListSort.defaultOrder, {}),
        ),
        ['x', 'y', 'a', 'd'],
      );
    });

    test('nom : insensible à la casse et aux accents', () {
      final list = [
        _character('1', name: 'zoé'),
        _character('2', name: 'Émile'),
        _character('3', name: 'adèle'),
        _character('4', name: 'Eric'),
        _character('5', name: 'Zara'),
      ];
      final sorted = CharacterListSorter.sortBy(
        list,
        CharacterListSort.name,
        {},
      );
      expect(sorted.map((c) => c.name), [
        'adèle',
        'Émile',
        'Eric',
        'Zara',
        'zoé',
      ]);
    });

    test(
      'nom : tri stable (égalité après normalisation = ordre d\'origine)',
      () {
        final list = [
          _character('first', name: 'Élise'),
          _character('second', name: 'elise'),
          _character('third', name: 'ÉLISE'),
        ];
        expect(
          ids(CharacterListSorter.sortBy(list, CharacterListSort.name, {})),
          ['first', 'second', 'third'],
        );
      },
    );

    test('nom : les trois groupes restent en jeu / archivés / morts', () {
      final list = [
        _character('d1', name: 'Aaron', isDead: true),
        _character('a1', name: 'Bob', isArchived: true),
        _character('x1', name: 'Zed'),
        _character('x2', name: 'Abel'),
        _character('a2', name: 'Alice', isArchived: true),
        _character('d2', name: 'Zoe', isDead: true),
        _character('both', name: 'Aa', isDead: true, isArchived: true),
      ];
      expect(
        ids(CharacterListSorter.sortBy(list, CharacterListSort.name, {})),
        ['x2', 'x1', 'a2', 'a1', 'both', 'd1', 'd2'],
      );
    });

    test('dernière ouverture : plus récent d\'abord, au sein de chaque '
        'groupe', () {
      final list = [
        _character('x1'),
        _character('x2'),
        _character('a1', isArchived: true),
        _character('a2', isArchived: true),
        _character('d1', isDead: true),
      ];
      final result = CharacterListSorter.sortBy(
        list,
        CharacterListSort.lastOpened,
        {'x1': 100, 'x2': 300, 'a1': 900, 'a2': 50, 'd1': 1},
      );
      // `a1` (900) reste après les en jeu malgré l'horodatage le plus récent.
      expect(ids(result), ['x2', 'x1', 'a1', 'a2', 'd1']);
    });

    test('dernière ouverture : jamais ouvert = dernier de son groupe, ordre '
        'de création conservé', () {
      final list = [
        _character('never1'),
        _character('opened'),
        _character('never2'),
        _character('never3', isArchived: true),
        _character('opened-archived', isArchived: true),
      ];
      final result = CharacterListSorter.sortBy(
        list,
        CharacterListSort.lastOpened,
        {'opened': 10, 'opened-archived': 20},
      );
      expect(ids(result), [
        'opened',
        'never1',
        'never2',
        'opened-archived',
        'never3',
      ]);
    });

    test('dernière ouverture : horodatages égaux = ordre d\'origine', () {
      final list = [_character('a'), _character('b'), _character('c')];
      expect(
        ids(
          CharacterListSorter.sortBy(list, CharacterListSort.lastOpened, {
            'a': 5,
            'b': 5,
            'c': 5,
          }),
        ),
        ['a', 'b', 'c'],
      );
    });

    test('liste vide', () {
      expect(
        CharacterListSorter.sortBy(const [], CharacterListSort.name, {}),
        isEmpty,
      );
    });
  });
}
