// Tests unitaires de `domain/spell_status_formatter.dart` — voir
// `docs/cahier-des-charges/11-fonctionnalites-a-ajouter.md`, section "Onglet
// Sorts" : "Distinction claire entre sorts connus et sorts préparés".

import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/spell_status_formatter.dart';

CharacterSpellEntry _spell({required int level, required String status}) {
  return CharacterSpellEntry(
    id: 1,
    name: 'Test',
    level: level,
    school: '',
    status: status,
  );
}

void main() {
  group('SpellStatusFormatter.subtitle', () {
    test('sort mineur (niveau 0) -> jamais de sous-titre', () {
      expect(SpellStatusFormatter.subtitle(_spell(level: 0, status: 'connu')), isNull);
      expect(SpellStatusFormatter.subtitle(_spell(level: 0, status: 'inné')), isNull);
    });

    test("sort niveau >= 1 'connu' -> \"connu, non préparé\"", () {
      expect(
        SpellStatusFormatter.subtitle(_spell(level: 1, status: 'connu')),
        'connu, non préparé',
      );
    });

    test("sort niveau >= 1 'préparé' -> \"préparé\"", () {
      expect(
        SpellStatusFormatter.subtitle(_spell(level: 3, status: 'préparé')),
        'préparé',
      );
    });

    test("sort niveau >= 1 'inné' (toujours disponible) -> aucun sous-titre", () {
      expect(SpellStatusFormatter.subtitle(_spell(level: 2, status: 'inné')), isNull);
    });
  });

  group('SpellStatusFormatter.canCast', () {
    test('sort mineur -> toujours lançable, quel que soit le statut', () {
      expect(SpellStatusFormatter.canCast(_spell(level: 0, status: 'connu')), isTrue);
      expect(SpellStatusFormatter.canCast(_spell(level: 0, status: 'préparé')), isTrue);
    });

    test("sort niveau >= 1 'connu' (non préparé) -> pas lançable", () {
      expect(SpellStatusFormatter.canCast(_spell(level: 1, status: 'connu')), isFalse);
    });

    test("sort niveau >= 1 'préparé' -> lançable", () {
      expect(SpellStatusFormatter.canCast(_spell(level: 1, status: 'préparé')), isTrue);
    });

    test("sort niveau >= 1 'inné' -> toujours lançable", () {
      expect(SpellStatusFormatter.canCast(_spell(level: 5, status: 'inné')), isTrue);
    });
  });

  group('SpellStatusFormatter.canTogglePrepared', () {
    test('sort mineur -> jamais de bascule de préparation', () {
      expect(
        SpellStatusFormatter.canTogglePrepared(_spell(level: 0, status: 'connu')),
        isFalse,
      );
    });

    test("sort inné -> jamais de bascule de préparation", () {
      expect(
        SpellStatusFormatter.canTogglePrepared(_spell(level: 2, status: 'inné')),
        isFalse,
      );
    });

    test("sort 'connu' niveau >= 1 -> bascule possible", () {
      expect(
        SpellStatusFormatter.canTogglePrepared(_spell(level: 1, status: 'connu')),
        isTrue,
      );
    });

    test("sort 'préparé' niveau >= 1 -> bascule possible", () {
      expect(
        SpellStatusFormatter.canTogglePrepared(_spell(level: 1, status: 'préparé')),
        isTrue,
      );
    });
  });
}
