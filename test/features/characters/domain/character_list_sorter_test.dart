import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_list_sorter.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';

CharacterSummary _character(
  String id, {
  bool isDead = false,
  bool isArchived = false,
}) {
  return CharacterSummary(
    id: id,
    name: id,
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
}
