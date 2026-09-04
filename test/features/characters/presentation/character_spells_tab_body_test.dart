// Tests de widget de l'onglet "Sorts" de la fiche personnage — scindé de
// l'onglet "Compétences" (voir `character_skills_tab_body_test.dart`), spec
// validée par l'agent `direction-artistique`.
//
// `CharacterSpellsTabBody` est un `StatelessWidget` pur (pas de Riverpod, pas
// de réseau) : même approche que `character_skills_tab_body_test.dart`, un
// simple `MaterialApp(home: ...)` suffit à le monter.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/character_spell_slot.dart';
import 'package:personnages/features/characters/presentation/widgets/character_spells_tab_body.dart';

CharacterDetail _detail({
  List<CharacterSpellEntry> spells = const [],
  List<CharacterSpellSlot> spellSlots = const [],
}) {
  return CharacterDetail(
    id: '1',
    name: 'Test',
    classes: const [],
    xp: 0,
    currentHp: 10,
    maxHp: 10,
    temporaryHp: 0,
    abilityScores: const {},
    spells: spells,
    spellSlots: spellSlots,
  );
}

Future<void> _pump(WidgetTester tester, CharacterDetail detail) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CharacterSpellsTabBody(detail: detail, onCastSpell: (_, _) {}),
      ),
    ),
  );
}

void main() {
  testWidgets('la section sorts regroupe par niveau avec les pastilles '
      'd\'emplacement', (tester) async {
    // find.bySemanticsLabel a besoin d'un arbre de sémantique actif — pas
    // construit par défaut dans un test de widget. `dispose()` doit être
    // appelé explicitement en fin de test (pas via `addTearDown`, qui
    // s'exécute trop tard par rapport à la vérification "handle actif" du
    // framework en fin de `testWidgets`).
    final semanticsHandle = tester.ensureSemantics();

    await _pump(
      tester,
      _detail(
        spells: const [
          CharacterSpellEntry(
            id: 1,
            name: 'Lumière',
            level: 0,
            school: 'Évocation',
            status: 'connu',
          ),
          CharacterSpellEntry(
            id: 2,
            name: 'Bouclier',
            level: 1,
            school: 'Abjuration',
            status: 'connu',
          ),
        ],
        spellSlots: const [CharacterSpellSlot(level: 1, total: 3, used: 1)],
      ),
    );

    expect(find.text('SORTS'), findsOneWidget);
    expect(find.text('Sorts mineurs'), findsOneWidget);
    expect(find.text('Lumière'), findsOneWidget);
    expect(find.text('(Évocation)'), findsOneWidget);
    expect(find.text('Niveau 1'), findsOneWidget);
    expect(find.text('Bouclier'), findsOneWidget);
    expect(find.text('(Abjuration)'), findsOneWidget);
    // Les emplacements de sorts sont rendus en pastilles graphiques (cercles
    // pleins/vides), pas en glyphe Unicode coloré (contraste insuffisant,
    // corrigé en revue direction-artistique — voir
    // `character_spells_section.dart::_SpellSlotDots`) : on vérifie le
    // libellé d'accessibilité plutôt qu'un `find.text` sur un caractère.
    expect(
      find.bySemanticsLabel('Emplacements de sorts : 2 restants sur 3'),
      findsOneWidget,
    );

    semanticsHandle.dispose();
  });

  testWidgets('affiche un état vide clair quand la fiche n\'a aucun sort', (
    tester,
  ) async {
    await _pump(tester, _detail());

    expect(find.text('AUCUN SORT'), findsOneWidget);
    expect(find.text('SORTS'), findsNothing);
    expect(find.byIcon(Icons.auto_fix_high_outlined), findsOneWidget);
  });

  testWidgets(
    'un sort est cliquable (chevron affiché) et ouvre directement le '
    'panneau "Infos" (plus de sheet intermédiaire "Infos"/"Lancer")',
    (tester) async {
      await _pump(
        tester,
        _detail(
          spells: const [
            CharacterSpellEntry(
              id: 1,
              name: 'Lumière',
              level: 0,
              school: 'Évocation',
              status: 'connu',
            ),
          ],
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      await tester.tap(find.text('Lumière'));
      await tester.pumpAndSettle();

      expect(find.text('LUMIÈRE'), findsOneWidget);
      expect(find.text('LANCER'), findsOneWidget);
      expect(find.text('Infos'), findsNothing);
    },
  );

  testWidgets(
    'actionsDisabled désactive le tap sur les sorts (repos long en vol)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CharacterSpellsTabBody(
              detail: _detail(
                spells: const [
                  CharacterSpellEntry(
                    id: 1,
                    name: 'Lumière',
                    level: 0,
                    school: 'Évocation',
                    status: 'connu',
                  ),
                ],
              ),
              onCastSpell: (_, _) {},
              actionsDisabled: true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Lumière'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('LUMIÈRE'), findsNothing);
    },
  );
}
