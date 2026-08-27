import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_spell_slot.dart';
import 'package:personnages/features/characters/domain/spell_slot_pips_formatter.dart';

void main() {
  group('CharacterSpellSlot.remaining', () {
    test('total - used', () {
      const slot = CharacterSpellSlot(level: 1, total: 3, used: 1);
      expect(slot.remaining, 2);
    });

    test('jamais négatif même si used > total (donnée incohérente)', () {
      const slot = CharacterSpellSlot(level: 1, total: 2, used: 5);
      expect(slot.remaining, 0);
    });

    test('0 emplacement total -> 0 restant', () {
      const slot = CharacterSpellSlot(level: 1, total: 0, used: 0);
      expect(slot.remaining, 0);
    });
  });

  group('SpellSlotPipsFormatter.format', () {
    test('"●●○" pour 2 restants sur 3', () {
      const slot = CharacterSpellSlot(level: 1, total: 3, used: 1);
      expect(SpellSlotPipsFormatter.format(slot), '●●○');
    });

    test('tous pleins quand aucun emplacement utilisé', () {
      const slot = CharacterSpellSlot(level: 2, total: 2, used: 0);
      expect(SpellSlotPipsFormatter.format(slot), '●●');
    });

    test('tous vides quand tous les emplacements sont utilisés', () {
      const slot = CharacterSpellSlot(level: 3, total: 2, used: 2);
      expect(SpellSlotPipsFormatter.format(slot), '○○');
    });

    test('chaîne vide si aucun emplacement total', () {
      const slot = CharacterSpellSlot(level: 1, total: 0, used: 0);
      expect(SpellSlotPipsFormatter.format(slot), '');
    });
  });
}
