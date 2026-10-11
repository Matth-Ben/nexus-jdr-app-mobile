// Tests unitaires de `domain/spell_preparation_filter.dart` — filtre
// "Tous"/"Préparés"/"Non préparés" de l'onglet "Sorts".

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/rules/spell_status.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/spell_grant_source.dart';
import 'package:personnages/features/characters/domain/spell_preparation_filter.dart';

const _cantrip = CharacterSpellEntry(
  id: 1,
  name: 'Lumière',
  level: 0,
  school: '',
  status: SpellStatus.known,
);
const _prepared = CharacterSpellEntry(
  id: 2,
  name: 'Bénédiction',
  level: 1,
  school: '',
  status: SpellStatus.prepared,
);
const _unprepared = CharacterSpellEntry(
  id: 3,
  name: 'Soins',
  level: 1,
  school: '',
  status: SpellStatus.known,
);
const _granted = CharacterSpellEntry(
  id: 4,
  name: 'Garde divine',
  level: 1,
  school: '',
  status: SpellStatus.prepared,
  grantSource: SpellGrantSource.domain,
  isPersisted: false,
);
const _innate = CharacterSpellEntry(
  id: 5,
  name: 'Ténèbres',
  level: 2,
  school: '',
  status: SpellStatus.innate,
);

const _all = [_cantrip, _prepared, _unprepared, _granted, _innate];

void main() {
  test('all : aucun sort retiré', () {
    expect(SpellPreparationFilter.all.apply(_all), _all);
  });

  test('prepared : tout ce qui est lançable en l\'état (préparés, sorts '
      'mineurs, innés, accordés)', () {
    expect(SpellPreparationFilter.prepared.apply(_all), [
      _cantrip,
      _prepared,
      _granted,
      _innate,
    ]);
  });

  test('unprepared : uniquement les sorts restant à préparer', () {
    expect(SpellPreparationFilter.unprepared.apply(_all), [_unprepared]);
  });

  group('sort qui ne se prépare pas (classe à sorts connus)', () {
    const knownSpell = CharacterSpellEntry(
      id: 6,
      name: 'Mot de guérison',
      level: 1,
      school: '',
      status: SpellStatus.known,
      requiresPreparation: false,
    );
    const withKnown = [..._all, knownSpell];

    test('prepared : rangé avec ce qui est lançable', () {
      expect(
        SpellPreparationFilter.prepared.apply(withKnown),
        contains(knownSpell),
      );
    });

    test('unprepared : jamais listé', () {
      expect(SpellPreparationFilter.unprepared.apply(withKnown), [_unprepared]);
    });
  });
}
