// Tests de widget de l'onglet "Sorts" de la fiche personnage — scindé de
// l'onglet "Compétences" (voir `character_skills_tab_body_test.dart`), spec
// validée par l'agent `direction-artistique`.
//
// `CharacterSpellsTabBody` n'a pas de dépendance Riverpod/réseau (l'état
// interne du champ de recherche mis à part) : même approche que
// `character_skills_tab_body_test.dart`, un simple `MaterialApp(home: ...)`
// suffit à le monter.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/character_spell_slot.dart';
import 'package:personnages/features/characters/presentation/widgets/character_spells_tab_body.dart';

/// Classe de départ par défaut : lanceuse de sorts (Magicien), pour que les
/// tests portant sur le contenu/l'état vide "générique" (`AUCUN SORT`)
/// n'atterrissent jamais sur l'état "cette classe ne lance pas de sorts" par
/// défaut — voir le test dédié à ce second état ci-dessous.
const _defaultClasses = [
  CharacterDetailClassRow(
    classId: 1,
    className: 'Magicien',
    level: 1,
    isPrimary: true,
    savingThrowProficiencies: [],
    hitDie: 6,
  ),
];

CharacterDetail _detail({
  List<CharacterSpellEntry> spells = const [],
  List<CharacterSpellSlot> spellSlots = const [],
  CharacterSpellSlot? pactSpellSlot,
  List<CharacterDetailClassRow> classes = _defaultClasses,
}) {
  return CharacterDetail(
    id: '1',
    name: 'Test',
    classes: classes,
    xp: 0,
    currentHp: 10,
    maxHp: 10,
    temporaryHp: 0,
    abilityScores: const {},
    spells: spells,
    spellSlots: spellSlots,
    pactSpellSlot: pactSpellSlot,
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
    'affiche un état vide distinct pour une classe non lanceuse de sorts '
    '(ex. Guerrier) — voir maquette "État vide — Sorts"',
    (tester) async {
      await _pump(
        tester,
        _detail(
          classes: const [
            CharacterDetailClassRow(
              classId: 2,
              className: 'Guerrier',
              level: 1,
              isPrimary: true,
              savingThrowProficiencies: [],
              hitDie: 10,
            ),
          ],
        ),
      );

      expect(find.text('Cette classe ne lance pas de sorts'), findsOneWidget);
      expect(find.textContaining('Test est Guerrier'), findsOneWidget);
      expect(find.text('AUCUN SORT'), findsNothing);
    },
  );

  testWidgets('un sort est cliquable (chevron affiché) et ouvre directement le '
      'panneau "Infos" (plus de sheet intermédiaire "Infos"/"Lancer")', (
    tester,
  ) async {
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
  });

  testWidgets(
    'bloc "Magie de pacte" affiché quand pactSpellSlot non nul (total > 0), '
    'pips en accentTeal',
    (tester) async {
      final semanticsHandle = tester.ensureSemantics();

      await _pump(
        tester,
        _detail(
          spells: const [
            CharacterSpellEntry(
              id: 1,
              name: 'Malédiction',
              level: 1,
              school: 'Enchantement',
              status: 'connu',
            ),
          ],
          pactSpellSlot: const CharacterSpellSlot(
            level: 2,
            total: 2,
            used: 1,
            isPact: true,
          ),
        ),
      );

      expect(find.text('Magie de pacte — Niveau 2'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Emplacements de pacte : 1 restants sur 2 (niveau 2)',
        ),
        findsOneWidget,
      );

      semanticsHandle.dispose();
    },
  );

  testWidgets('bloc "Magie de pacte" absent quand pactSpellSlot est null', (
    tester,
  ) async {
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

    expect(find.text('Magie de pacte'), findsNothing);
    expect(find.byIcon(Icons.local_fire_department), findsNothing);
  });

  testWidgets(
    'bloc "Magie de pacte" absent quand pactSpellSlot.total vaut 0 (garde '
    'défensive)',
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
          pactSpellSlot: const CharacterSpellSlot(
            level: 1,
            total: 0,
            used: 0,
            isPact: true,
          ),
        ),
      );

      expect(find.byIcon(Icons.local_fire_department), findsNothing);
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

  group('recherche (docs/cahier-des-charges/'
      '11-fonctionnalites-a-ajouter.md section 3)', () {
    const spells = [
      CharacterSpellEntry(
        id: 1,
        name: 'Boule de feu',
        level: 3,
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
    ];

    testWidgets('le champ de recherche est affiché dès qu\'au moins un sort '
        'existe', (tester) async {
      await _pump(tester, _detail(spells: spells));

      expect(
        find.widgetWithText(TextField, 'Rechercher un sort'),
        findsOneWidget,
      );
    });

    testWidgets('le champ de recherche est absent des états vides (aucun '
        'sort du tout)', (tester) async {
      await _pump(tester, _detail());

      expect(find.byType(TextField), findsNothing);
    });

    testWidgets(
      'taper dans le champ ne garde que les sorts dont le nom correspond',
      (tester) async {
        await _pump(tester, _detail(spells: spells));

        await tester.enterText(
          find.widgetWithText(TextField, 'Rechercher un sort'),
          'boule',
        );
        await tester.pumpAndSettle();

        expect(find.text('Boule de feu'), findsOneWidget);
        expect(find.text('Bouclier'), findsNothing);
      },
    );

    testWidgets(
      'aucun sort ne correspond à la recherche : affiche un message dédié, '
      'sans afficher la section "SORTS"',
      (tester) async {
        await _pump(tester, _detail(spells: spells));

        await tester.enterText(
          find.widgetWithText(TextField, 'Rechercher un sort'),
          'zzzzz',
        );
        await tester.pumpAndSettle();

        expect(find.text('Aucun sort pour « zzzzz ».'), findsOneWidget);
        expect(find.text('SORTS'), findsNothing);
      },
    );

    testWidgets('icône "×" efface la recherche et restaure la liste complète', (
      tester,
    ) async {
      await _pump(tester, _detail(spells: spells));

      await tester.enterText(
        find.widgetWithText(TextField, 'Rechercher un sort'),
        'boule',
      );
      await tester.pumpAndSettle();
      expect(find.text('Bouclier'), findsNothing);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Boule de feu'), findsOneWidget);
      expect(find.text('Bouclier'), findsOneWidget);
    });
  });
}
