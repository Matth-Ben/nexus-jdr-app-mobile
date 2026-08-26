// Tests unitaires de la résolution des sorts choisis (mineurs + niveau 1) à
// l'étape 9/9 "Récapitulatif"
// (`lib/features/character_creation/domain/spell_selection_resolver.dart`).

import 'package:flutter_test/flutter_test.dart';
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
    expect(rows.every((r) => r.status == 'préparé'), isTrue);
  });

  test('utilise le statut "connu" pour une classe lanceuse "connue"', () {
    final rows = SpellSelectionResolver.resolve(
      cantripNames: const ['Lumière'],
      levelOneSpellNames: const [],
      catalog: catalog,
      className: 'Barde',
    );

    expect(rows.single.status, 'connu');
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
}
