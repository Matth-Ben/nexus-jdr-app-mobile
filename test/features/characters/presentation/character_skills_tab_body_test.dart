// Tests de widget de l'onglet "Compétences" de la fiche personnage — voir
// `docs/cahier-des-charges/04-fonctionnalites-app-mobile.md`, section
// "Onglet Compétences".
//
// `CharacterSkillsTabBody` est un `StatelessWidget` pur (pas de Riverpod, pas
// de réseau) : contrairement à `character_detail_screen_test.dart`, un
// simple `MaterialApp(home: ...)` suffit à le monter.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_class_feature.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_skill_row.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/character_spell_slot.dart';
import 'package:personnages/features/characters/presentation/widgets/character_skills_tab_body.dart';

CharacterDetail _detail({
  List<CharacterSkillRow> skills = const [],
  List<CharacterClassFeature> classFeatures = const [],
  List<String> toolProficiencyNames = const [],
  List<String> knownLanguageNames = const [],
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
    abilityScores: const {'dex': 16, 'int': 10},
    skills: skills,
    classFeatures: classFeatures,
    toolProficiencyNames: toolProficiencyNames,
    knownLanguageNames: knownLanguageNames,
    spells: spells,
    spellSlots: spellSlots,
  );
}

Future<void> _pump(WidgetTester tester, CharacterDetail detail) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: CharacterSkillsTabBody(detail: detail)),
    ),
  );
}

void main() {
  testWidgets('affiche la liste de compétences avec le bon bonus', (
    tester,
  ) async {
    await _pump(
      tester,
      _detail(
        skills: const [
          CharacterSkillRow(
            id: 1,
            name: 'Acrobaties',
            abilityId: 'dex',
            proficiency: 'competente',
          ),
        ],
      ),
    );

    expect(find.text('LES 18 COMPÉTENCES'), findsOneWidget);
    expect(find.text('Acrobaties'), findsOneWidget);
    expect(find.text('Dex'), findsOneWidget);
    // Score dex 16 -> mod +3, niveau total 0 -> proficiencyBonus niveau 1
    // (clampé) = +2, maîtrisée -> +3 + 2 = +5.
    expect(find.text('+5'), findsOneWidget);
  });

  testWidgets('affiche une aptitude à usage limité avec son compteur', (
    tester,
  ) async {
    await _pump(
      tester,
      _detail(
        classFeatures: const [
          CharacterClassFeature(
            id: 1,
            name: 'Conduit divin',
            level: 2,
            usesMax: 1,
            usesRemaining: 0,
            restType: 'repos_court',
          ),
        ],
      ),
    );

    expect(find.text('APTITUDES DE CLASSE'), findsOneWidget);
    expect(find.text('Conduit divin'), findsOneWidget);
    expect(find.text('0 / 1 · repos court'), findsOneWidget);
  });

  testWidgets('affiche plusieurs aptitudes de classe (classes mélangées) dans '
      'l\'ordre reçu, sans les retrier ni les regrouper par classe — l\'ordre '
      'déterministe repose sur `.order(\'level\')` côté requête '
      '(SupabaseCharacterRepository._buildCharacterDetailPayload/'
      '_mapCharacterDetailPayload), ce widget ne fait '
      'que refléter la liste telle que reçue', (tester) async {
    await _pump(
      tester,
      _detail(
        classFeatures: const [
          CharacterClassFeature(id: 1, name: 'Aptitude A (niv. 1)', level: 1),
          CharacterClassFeature(id: 2, name: 'Aptitude B (niv. 1)', level: 1),
          CharacterClassFeature(id: 3, name: 'Aptitude C (niv. 2)', level: 2),
        ],
      ),
    );

    final dyA = tester.getTopLeft(find.text('Aptitude A (niv. 1)')).dy;
    final dyB = tester.getTopLeft(find.text('Aptitude B (niv. 1)')).dy;
    final dyC = tester.getTopLeft(find.text('Aptitude C (niv. 2)')).dy;

    expect(dyA, lessThan(dyB));
    expect(dyB, lessThan(dyC));
  });

  testWidgets('affiche une aptitude passive "Passive"', (tester) async {
    await _pump(
      tester,
      _detail(
        classFeatures: const [
          CharacterClassFeature(id: 2, name: 'Défense sans armure', level: 1),
        ],
      ),
    );

    expect(find.text('Défense sans armure'), findsOneWidget);
    expect(find.text('Passive'), findsOneWidget);
  });

  testWidgets(
    'les cartes outils/langues/sorts n\'apparaissent pas quand vides',
    (tester) async {
      await _pump(tester, _detail());

      expect(find.text("MAÎTRISES D'OUTILS"), findsNothing);
      expect(find.text('LANGUES CONNUES'), findsNothing);
      expect(find.text('SORTS'), findsNothing);
      expect(find.text('APTITUDES DE CLASSE'), findsNothing);
    },
  );

  testWidgets('la carte outils affiche les noms quand non vide', (
    tester,
  ) async {
    await _pump(
      tester,
      _detail(toolProficiencyNames: const ['Outils de forgeron']),
    );

    expect(find.text("MAÎTRISES D'OUTILS"), findsOneWidget);
    expect(find.text('Outils de forgeron'), findsOneWidget);
  });

  testWidgets('la carte langues affiche les noms quand non vide', (
    tester,
  ) async {
    await _pump(tester, _detail(knownLanguageNames: const ['Nain']));

    expect(find.text('LANGUES CONNUES'), findsOneWidget);
    expect(find.text('Nain'), findsOneWidget);
  });

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
}
