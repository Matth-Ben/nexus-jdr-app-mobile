import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/spell_subtitle_formatter.dart';

CharacterSpellEntry _spell({required int level, String school = ''}) {
  return CharacterSpellEntry(
    id: 1,
    name: 'Test',
    level: level,
    school: school,
    status: 'connu',
  );
}

void main() {
  group('SpellSubtitleFormatter.format', () {
    test('sort mineur avec école -> "École · Sort mineur"', () {
      expect(
        SpellSubtitleFormatter.format(_spell(level: 0, school: 'Évocation')),
        'Évocation · Sort mineur',
      );
    });

    test('sort niveau >= 1 avec école -> "École · Niveau N"', () {
      expect(
        SpellSubtitleFormatter.format(_spell(level: 3, school: 'Abjuration')),
        'Abjuration · Niveau 3',
      );
    });

    test('école vide -> repli sur juste le niveau', () {
      expect(SpellSubtitleFormatter.format(_spell(level: 2)), 'Niveau 2');
      expect(SpellSubtitleFormatter.format(_spell(level: 0)), 'Sort mineur');
    });
  });
}
