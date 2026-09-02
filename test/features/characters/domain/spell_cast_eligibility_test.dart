import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_spell_slot.dart';
import 'package:personnages/features/characters/domain/spell_cast_eligibility.dart';

void main() {
  const slots = [
    CharacterSpellSlot(level: 1, total: 4, used: 4), // épuisé
    CharacterSpellSlot(level: 2, total: 3, used: 1),
    CharacterSpellSlot(level: 3, total: 2, used: 2), // épuisé
  ];

  group('SpellCastEligibility.eligibleSlots', () {
    test('retient tous les niveaux >= spellLevel, triés croissant', () {
      final result = SpellCastEligibility.eligibleSlots(
        spellSlots: slots,
        spellLevel: 1,
      );
      expect(result.map((s) => s.level), [1, 2, 3]);
    });

    test('un niveau épuisé reste listé, jamais masqué', () {
      final result = SpellCastEligibility.eligibleSlots(
        spellSlots: slots,
        spellLevel: 3,
      );
      expect(result, hasLength(1));
      expect(result.single.level, 3);
      expect(result.single.remaining, 0);
    });

    test('aucun niveau éligible -> liste vide', () {
      final result = SpellCastEligibility.eligibleSlots(
        spellSlots: slots,
        spellLevel: 5,
      );
      expect(result, isEmpty);
    });
  });

  group('SpellCastEligibility.hasAvailableSlot', () {
    test('sort niveau 0 -> toujours vrai, jamais désactivé', () {
      expect(
        SpellCastEligibility.hasAvailableSlot(
          spellSlots: const [],
          spellLevel: 0,
        ),
        isTrue,
      );
    });

    test('au moins un niveau éligible avec remaining > 0 -> vrai', () {
      expect(
        SpellCastEligibility.hasAvailableSlot(spellSlots: slots, spellLevel: 1),
        isTrue,
      );
    });

    test('tous les niveaux éligibles épuisés -> faux', () {
      expect(
        SpellCastEligibility.hasAvailableSlot(spellSlots: slots, spellLevel: 3),
        isFalse,
      );
    });

    test('aucun niveau éligible du tout -> faux', () {
      expect(
        SpellCastEligibility.hasAvailableSlot(spellSlots: slots, spellLevel: 5),
        isFalse,
      );
    });
  });

  group('SpellCastEligibility.defaultSelectedLevel', () {
    test('le plus petit niveau éligible avec remaining > 0', () {
      expect(
        SpellCastEligibility.defaultSelectedLevel(
          spellSlots: slots,
          spellLevel: 1,
        ),
        2,
      );
    });

    test('aucun niveau disponible -> null', () {
      expect(
        SpellCastEligibility.defaultSelectedLevel(
          spellSlots: slots,
          spellLevel: 3,
        ),
        isNull,
      );
    });
  });
}
