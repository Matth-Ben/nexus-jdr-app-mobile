// Tests unitaires de `core/rules/character_class.dart` — la clé stable de
// classe introduite par la dette D04 (`docs/dette-technique.md`), mappée 1:1
// sur `public.classes.id` (dépôt web).

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/rules/character_class.dart';

void main() {
  group('CharacterClass : 13 valeurs, mapping id <-> nom français', () {
    // Relevé en direct sur la base de prod par dev-backend-supabase le
    // 10/10/2026 (lecture seule, catalogue public) — voir
    // docs/dette-technique.md, D04.
    const expected = {
      1: 'Barbare',
      2: 'Barde',
      3: 'Clerc',
      4: 'Druide',
      5: 'Guerrier',
      6: 'Moine',
      7: 'Paladin',
      8: 'Rôdeur',
      9: 'Roublard',
      10: 'Occultiste',
      11: 'Magicien',
      12: 'Ensorceleur',
      13: 'Artificier',
    };

    test('exactement 13 valeurs', () {
      expect(CharacterClass.values, hasLength(13));
    });

    test('chaque id/nom attendu correspond à une CharacterClass unique', () {
      for (final entry in expected.entries) {
        final byId = CharacterClass.fromId(entry.key);
        expect(byId, isNotNull, reason: 'id ${entry.key}');
        expect(byId!.frenchName, entry.value, reason: 'id ${entry.key}');

        final byName = CharacterClass.fromFrenchName(entry.value);
        expect(byName, isNotNull, reason: entry.value);
        expect(byName!.id, entry.key, reason: entry.value);

        expect(byId, byName, reason: entry.value);
      }
    });

    test('aucun id ni nom dupliqué parmi les 13 valeurs', () {
      final ids = CharacterClass.values.map((c) => c.id).toSet();
      final names = CharacterClass.values.map((c) => c.frenchName).toSet();
      expect(ids, hasLength(13));
      expect(names, hasLength(13));
    });
  });

  group('CharacterClass.fromId', () {
    test('accepte un int, un num (double sans décimale) ou une chaîne', () {
      expect(CharacterClass.fromId(3), CharacterClass.cleric);
      expect(CharacterClass.fromId(3.0), CharacterClass.cleric);
      expect(CharacterClass.fromId('3'), CharacterClass.cleric);
    });

    test('null, id inconnu ou chaîne non numérique -> null', () {
      expect(CharacterClass.fromId(null), isNull);
      expect(CharacterClass.fromId(999), isNull);
      expect(CharacterClass.fromId('abc'), isNull);
    });
  });

  group('CharacterClass.fromFrenchName', () {
    test('null ou nom non reconnu -> null', () {
      expect(CharacterClass.fromFrenchName(null), isNull);
      expect(CharacterClass.fromFrenchName('Classe #14'), isNull);
      expect(CharacterClass.fromFrenchName(''), isNull);
    });

    test('sensible à la casse/aux accents exacts (pas de normalisation)', () {
      expect(CharacterClass.fromFrenchName('barde'), isNull);
      expect(CharacterClass.fromFrenchName('Rodeur'), isNull);
      expect(CharacterClass.fromFrenchName('Rôdeur'), CharacterClass.ranger);
    });
  });
}
