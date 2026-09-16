import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_list_filter.dart';
import 'package:personnages/features/characters/domain/character_status_filter.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';

CharacterSummary _summary({
  required String id,
  required String name,
  String? className,
  bool isDead = false,
  bool isArchived = false,
}) => CharacterSummary(
  id: id,
  name: name,
  className: className,
  level: 1,
  xp: 0,
  isDead: isDead,
  isArchived: isArchived,
);

void main() {
  group('CharacterListFilter.apply', () {
    final characters = [
      _summary(id: '1', name: 'Halltesse Ambrelune', className: 'Magicien'),
      _summary(id: '2', name: 'Borgan Pierrefort', className: 'Guerrier'),
      _summary(id: '3', name: 'Sylvi Aubefeuille', className: 'Roublard'),
      _summary(id: '4', name: 'Kastor Ivrelin'),
    ];

    test('sans requête ni filtre, renvoie tous les personnages tels quels', () {
      final result = CharacterListFilter.apply(
        characters: characters,
        query: '',
        classNames: {},
      );

      expect(result, characters);
    });

    test(
      'requête vide après trim (espaces seuls) équivaut à aucune requête',
      () {
        final result = CharacterListFilter.apply(
          characters: characters,
          query: '   ',
          classNames: {},
        );

        expect(result, characters);
      },
    );

    test('filtre par sous-chaîne du nom, insensible à la casse', () {
      final result = CharacterListFilter.apply(
        characters: characters,
        query: 'BORGAN',
        classNames: {},
      );

      expect(result, [characters[1]]);
    });

    test('sous-chaîne au milieu du nom (pas seulement en préfixe)', () {
      final result = CharacterListFilter.apply(
        characters: characters,
        query: 'efeuille',
        classNames: {},
      );

      expect(result, [characters[2]]);
    });

    test('filtre par classe : un ensemble non vide exclut les personnages '
        'sans classe enregistrée', () {
      final result = CharacterListFilter.apply(
        characters: characters,
        query: '',
        classNames: {'Guerrier'},
      );

      expect(result, [characters[1]]);
    });

    test('filtre par classe : plusieurs classes sélectionnées (union)', () {
      final result = CharacterListFilter.apply(
        characters: characters,
        query: '',
        classNames: {'Guerrier', 'Roublard'},
      );

      expect(result, [characters[1], characters[2]]);
    });

    test('requête ET filtre de classe combinés (intersection)', () {
      final result = CharacterListFilter.apply(
        characters: characters,
        query: 'a',
        classNames: {'Roublard'},
      );

      expect(result, [characters[2]]);
    });

    test('aucun résultat renvoie une liste vide, pas une erreur', () {
      final result = CharacterListFilter.apply(
        characters: characters,
        query: 'zzzzz',
        classNames: {},
      );

      expect(result, isEmpty);
    });
  });

  group('CharacterListFilter.apply — filtre par statut (16/09/2026, hors '
      'cahier des charges)', () {
    final alive = _summary(id: '1', name: 'Halltesse Ambrelune');
    final archived = _summary(
      id: '2',
      name: 'Borgan Pierrefort',
      isArchived: true,
    );
    final dead = _summary(id: '3', name: 'Sylvi Aubefeuille', isDead: true);
    final archivedAndDead = _summary(
      id: '4',
      name: 'Kastor Ivrelin',
      isArchived: true,
      isDead: true,
    );
    final all = [alive, archived, dead, archivedAndDead];

    test('ensemble vide -> aucun filtre, tous les personnages passent', () {
      final result = CharacterListFilter.apply(
        characters: all,
        query: '',
        classNames: {},
      );

      expect(result, all);
    });

    test('{alive} ne garde que les personnages ni morts ni archivés', () {
      final result = CharacterListFilter.apply(
        characters: all,
        query: '',
        classNames: {},
        statuses: {CharacterStatusFilter.alive},
      );

      expect(result, [alive]);
    });

    test('{archived} garde un personnage archivé même mort par ailleurs '
        '(intersection, pas égalité stricte)', () {
      final result = CharacterListFilter.apply(
        characters: all,
        query: '',
        classNames: {},
        statuses: {CharacterStatusFilter.archived},
      );

      expect(result, [archived, archivedAndDead]);
    });

    test('{dead} garde un personnage mort même archivé par ailleurs', () {
      final result = CharacterListFilter.apply(
        characters: all,
        query: '',
        classNames: {},
        statuses: {CharacterStatusFilter.dead},
      );

      expect(result, [dead, archivedAndDead]);
    });

    test('{archived, dead} combinés (union) : tout sauf les vivants', () {
      final result = CharacterListFilter.apply(
        characters: all,
        query: '',
        classNames: {},
        statuses: {CharacterStatusFilter.archived, CharacterStatusFilter.dead},
      );

      expect(result, [archived, dead, archivedAndDead]);
    });

    test('statut ET classe combinés (intersection)', () {
      final gunner = _summary(
        id: '5',
        name: 'Nael',
        className: 'Guerrier',
        isDead: true,
      );
      final result = CharacterListFilter.apply(
        characters: [...all, gunner],
        query: '',
        classNames: {'Guerrier'},
        statuses: {CharacterStatusFilter.dead},
      );

      expect(result, [gunner]);
    });
  });

  group('CharacterListFilter.statusesOf', () {
    test('ni mort ni archivé -> {alive} seul', () {
      expect(CharacterListFilter.statusesOf(_summary(id: '1', name: 'A')), {
        CharacterStatusFilter.alive,
      });
    });

    test('archivé seul -> {archived}', () {
      expect(
        CharacterListFilter.statusesOf(
          _summary(id: '1', name: 'A', isArchived: true),
        ),
        {CharacterStatusFilter.archived},
      );
    });

    test('mort seul -> {dead}', () {
      expect(
        CharacterListFilter.statusesOf(
          _summary(id: '1', name: 'A', isDead: true),
        ),
        {CharacterStatusFilter.dead},
      );
    });

    test('mort ET archivé -> {archived, dead}, jamais alive', () {
      expect(
        CharacterListFilter.statusesOf(
          _summary(id: '1', name: 'A', isDead: true, isArchived: true),
        ),
        {CharacterStatusFilter.archived, CharacterStatusFilter.dead},
      );
    });
  });

  group('CharacterListFilter.distinctClassNames', () {
    test('classes distinctes triées alphabétiquement, sans doublon ni '
        'personnage sans classe', () {
      final result = CharacterListFilter.distinctClassNames([
        _summary(id: '1', name: 'A', className: 'Roublard'),
        _summary(id: '2', name: 'B', className: 'Guerrier'),
        _summary(id: '3', name: 'C', className: 'Guerrier'),
        _summary(id: '4', name: 'D'),
      ]);

      expect(result, ['Guerrier', 'Roublard']);
    });

    test('liste vide en entrée renvoie une liste vide', () {
      expect(CharacterListFilter.distinctClassNames([]), isEmpty);
    });
  });
}
