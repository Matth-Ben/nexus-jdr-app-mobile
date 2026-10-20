// Tests unitaires de la résolution des sorts choisis (mineurs + niveau 1) à
// l'étape 9/9 "Récapitulatif"
// (`lib/features/character_creation/domain/spell_selection_resolver.dart`).

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/rules/spell_status.dart';
import 'package:personnages/features/character_creation/domain/spell_catalog.dart';
import 'package:personnages/features/character_creation/domain/spell_option.dart';
import 'package:personnages/features/character_creation/domain/spell_selection_resolver.dart';

void main() {
  const lumiere = SpellOption(
    id: 1,
    name: 'Lumière',
    level: 0,
    school: 'Évocation',
    castingTime: '1 action',
  );
  const bouclier = SpellOption(
    id: 2,
    name: 'Bouclier',
    level: 1,
    school: 'Abjuration',
    castingTime: '1 réaction',
  );

  final catalog = const SpellCatalog(spells: [lumiere, bouclier]);

  test('résout cantrips et sorts de niveau 1 avec le même statut', () {
    final rows = SpellSelectionResolver.resolve(
      cantripNames: const ['Lumière'],
      levelOneSpellNames: const ['Bouclier'],
      catalog: catalog,
      className: 'Magicien',
    );

    expect(rows, hasLength(2));
    expect(rows.map((r) => r.spellId).toSet(), {lumiere.id, bouclier.id});
    expect(rows.every((r) => r.status == SpellStatus.prepared), isTrue);
  });

  test('utilise le statut "connu" pour une classe lanceuse "connue"', () {
    final rows = SpellSelectionResolver.resolve(
      cantripNames: const ['Lumière'],
      levelOneSpellNames: const [],
      catalog: catalog,
      className: 'Barde',
    );

    expect(rows.single.status, SpellStatus.known);
  });

  test('ignore silencieusement un nom sans correspondance dans le '
      'catalogue', () {
    final rows = SpellSelectionResolver.resolve(
      cantripNames: const ['Sort inconnu'],
      levelOneSpellNames: const ['Bouclier'],
      catalog: catalog,
      className: 'Magicien',
    );

    expect(rows, hasLength(1));
    expect(rows.single.spellId, bouclier.id);
  });

  test('listes vides -> aucune ligne', () {
    final rows = SpellSelectionResolver.resolve(
      cantripNames: const [],
      levelOneSpellNames: const [],
      catalog: catalog,
      className: 'Magicien',
    );

    expect(rows, isEmpty);
  });

  group('SpellSelectionResolver.capToPreparedLimit (D79)', () {
    const soins = SpellOption(
      id: 101,
      name: 'Soins',
      level: 1,
      school: '',
      castingTime: '',
    );
    const benediction = SpellOption(
      id: 102,
      name: 'Bénédiction',
      level: 1,
      school: '',
      castingTime: '',
    );
    const aide = SpellOption(
      id: 103,
      name: 'Aide',
      level: 1,
      school: '',
      castingTime: '',
    );
    final clercCatalog = const SpellCatalog(
      spells: [lumiere, soins, benediction, aide],
    );

    test('Magicien à faible Intelligence : seul le quota RAW reste préparé, '
        "l'excédent devient 'connu'", () {
      // Intelligence 8 (mod -1) : limite = niveau 1 + (-1) -> plancher 1
      // (`PreparedSpellsLimit.limitFor`), alors que le quota de SÉLECTION
      // du Magicien (`SpellcastingRules.levelOneSpellQuotaFor`) reste 6,
      // indépendant de l'Intelligence.
      final resolved = SpellSelectionResolver.resolve(
        cantripNames: const ['Lumière'],
        levelOneSpellNames: const ['Soins', 'Bénédiction', 'Aide'],
        catalog: clercCatalog,
        className: 'Magicien',
      );

      final capped = SpellSelectionResolver.capToPreparedLimit(
        rows: resolved,
        catalog: clercCatalog,
        className: 'Magicien',
        classLevel: 1,
        abilityScores: const {'int': 8},
      );

      // Même jeu de sorts (quota de sélection inchangé), même ordre.
      expect(
        capped.map((row) => row.spellId),
        resolved.map((row) => row.spellId),
      );
      // Le cantrip reste 'préparé' (jamais compté dans la limite).
      expect(
        capped.firstWhere((row) => row.spellId == lumiere.id).status,
        SpellStatus.prepared,
      );
      // Un seul sort de niveau 1 reste préparé (limite = 1) : le premier
      // choisi (Soins) ; les deux autres passent à 'connu'.
      expect(
        capped.firstWhere((row) => row.spellId == soins.id).status,
        SpellStatus.prepared,
      );
      expect(
        capped.firstWhere((row) => row.spellId == benediction.id).status,
        SpellStatus.known,
      );
      expect(
        capped.firstWhere((row) => row.spellId == aide.id).status,
        SpellStatus.known,
      );
    });

    test('Clerc : modificateur de Sagesse positif suffisant, aucune '
        'rétrogradation', () {
      // Sagesse 16 (mod +3) : limite = niveau 1 + 3 = 4, >= aux 2 sorts de
      // niveau 1 sélectionnés -> aucun n'est rétrogradé.
      final resolved = SpellSelectionResolver.resolve(
        cantripNames: const [],
        levelOneSpellNames: const ['Soins', 'Bénédiction'],
        catalog: clercCatalog,
        className: 'Clerc',
      );

      final capped = SpellSelectionResolver.capToPreparedLimit(
        rows: resolved,
        catalog: clercCatalog,
        className: 'Clerc',
        classLevel: 1,
        abilityScores: const {'wis': 16},
      );

      expect(capped.every((row) => row.status == SpellStatus.prepared), isTrue);
    });

    test('modificateur très négatif : la limite plancher à 1, jamais à 0 ni '
        'négative', () {
      // Intelligence 1 (mod -5) : base niveau 1 + (-5) = -4 -> plancher 1.
      final resolved = SpellSelectionResolver.resolve(
        cantripNames: const [],
        levelOneSpellNames: const ['Soins', 'Bénédiction', 'Aide'],
        catalog: clercCatalog,
        className: 'Magicien',
      );

      final capped = SpellSelectionResolver.capToPreparedLimit(
        rows: resolved,
        catalog: clercCatalog,
        className: 'Magicien',
        classLevel: 1,
        abilityScores: const {'int': 1},
      );

      expect(
        capped.where((row) => row.status == SpellStatus.prepared).length,
        1,
      );
    });

    test("classe à sorts connus (Barde) : jamais touchée, même avec un "
        'modificateur très négatif', () {
      final resolved = SpellSelectionResolver.resolve(
        cantripNames: const [],
        levelOneSpellNames: const ['Soins', 'Bénédiction', 'Aide'],
        catalog: clercCatalog,
        className: 'Barde',
      );

      final capped = SpellSelectionResolver.capToPreparedLimit(
        rows: resolved,
        catalog: clercCatalog,
        className: 'Barde',
        classLevel: 1,
        abilityScores: const {'cha': 1},
      );

      expect(capped, resolved);
      expect(capped.every((row) => row.status == SpellStatus.known), isTrue);
    });

    test("demi-lanceur (Paladin) niveau 1 : base nulle (niveau ~/ 2), la "
        'limite tient uniquement au modificateur, plancher 1', () {
      // Charisme 14 (mod +2) : base = 1 ~/ 2 = 0, limite = 0 + 2 = 2.
      final resolved = SpellSelectionResolver.resolve(
        cantripNames: const [],
        levelOneSpellNames: const ['Soins', 'Bénédiction'],
        catalog: clercCatalog,
        className: 'Paladin',
      );

      final capped = SpellSelectionResolver.capToPreparedLimit(
        rows: resolved,
        catalog: clercCatalog,
        className: 'Paladin',
        classLevel: 1,
        abilityScores: const {'cha': 14},
      );

      expect(capped.every((row) => row.status == SpellStatus.prepared), isTrue);
    });
  });
}
