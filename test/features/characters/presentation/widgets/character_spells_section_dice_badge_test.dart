// Test d'intégration léger : vérifie que `_SpellRow` (via
// `CharacterSpellsSection`) affiche bien un `DiceTypeBadge` quand la
// description du sort contient un dé de dégâts détectable, et rien quand ce
// n'est pas le cas — pas de reconstruction de la suite de tests complète de
// cet écran (aucune suite existante à ce jour pour ce widget).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/dice_type_badge.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/presentation/widgets/character_spells_section.dart';
import 'package:personnages/features/characters/domain/spells_by_level_grouper.dart';

void main() {
  Future<void> pump(WidgetTester tester, List<CharacterSpellEntry> spells) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CharacterSpellsSection(
            groups: SpellsByLevelGrouper.group(spells),
            spellSlots: const [],
            onCastSpell: (_, _) {},
            onTogglePrepared: (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets(
    'un sort avec un dé de dégâts détectable affiche un DiceTypeBadge',
    (tester) async {
      await pump(tester, [
        const CharacterSpellEntry(
          id: 1,
          name: 'Boule de feu',
          level: 3,
          school: 'évocation',
          status: 'connu',
          description: 'La cible subit 8d6 dégâts de feu.',
        ),
      ]);

      expect(find.byType(DiceTypeBadge), findsOneWidget);
    },
  );

  testWidgets('un sort sans dé de dégâts détectable n\'affiche rien', (
    tester,
  ) async {
    await pump(tester, [
      const CharacterSpellEntry(
        id: 2,
        name: 'Lumière',
        level: 0,
        school: 'évocation',
        status: 'connu',
        description: 'Vous créez une lumière vive.',
      ),
    ]);

    expect(find.byType(DiceTypeBadge), findsNothing);
  });
}
