// Test d'intégration léger : vérifie que `_SpellRow` (via
// `CharacterSpellsSection`) affiche bien un `DiceTypeBadge` quand la
// description du sort contient un dé de dégâts détectable, et rien quand ce
// n'est pas le cas — pas de reconstruction de la suite de tests complète de
// cet écran (aucune suite existante à ce jour pour ce widget). Vérifie aussi
// que l'écran applique la table d'exceptions par nom
// (`SpellDamageDiceExceptions`, un cas par catégorie ; chaque entrée est
// couverte par `spell_damage_dice_extractor_test.dart`).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/rules/spell_status.dart';
import 'package:personnages/core/widgets/dice_type_badge.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/presentation/widgets/character_spells_section.dart';
import 'package:personnages/features/characters/domain/spells_by_level_grouper.dart';
import 'package:personnages/l10n/app_localizations.dart';

void main() {
  Future<void> pump(WidgetTester tester, List<CharacterSpellEntry> spells) {
    return tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
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
          status: SpellStatus.known,
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
        status: SpellStatus.known,
        description: 'Vous créez une lumière vive.',
      ),
    ]);

    expect(find.byType(DiceTypeBadge), findsNothing);
  });

  group('table d\'exceptions (spec pastille-degats-sorts)', () {
    testWidgets('un sort sans pastille n\'en affiche aucune malgré le NdM de '
        'sa description', (tester) async {
      await pump(tester, [
        const CharacterSpellEntry(
          id: 3,
          name: 'Sommeil',
          level: 1,
          school: 'enchantement',
          status: SpellStatus.known,
          description:
              'Lancez 5d8 : le total est le nombre de points de vie '
              'de créatures que ce sort peut affecter.',
        ),
      ]);

      expect(find.text('Sommeil'), findsOneWidget);
      expect(find.byType(DiceTypeBadge), findsNothing);
    });

    testWidgets('un sort remplacé affiche le dé imposé, pas le premier NdM', (
      tester,
    ) async {
      await pump(tester, [
        const CharacterSpellEntry(
          id: 4,
          name: 'Main de Bigby',
          level: 5,
          school: 'évocation',
          status: SpellStatus.known,
          description: 'Main interposée : 2d6 dégâts. Poing serré : 4d8.',
        ),
      ]);

      expect(find.byType(DiceTypeBadge), findsOneWidget);
      expect(find.text('4d8'), findsOneWidget);
      expect(find.text('2d6'), findsNothing);
    });

    testWidgets('un sort ajouté affiche un dé malgré un texte sans NdM', (
      tester,
    ) async {
      await pump(tester, [
        const CharacterSpellEntry(
          id: 5,
          name: 'Trique noueuse',
          level: 0,
          school: 'transmutation',
          status: SpellStatus.known,
          description: 'Le dé de dégâts de l\'arme devient un d8.',
        ),
      ]);

      expect(find.byType(DiceTypeBadge), findsOneWidget);
      expect(find.text('1d8'), findsOneWidget);
    });
  });
}
