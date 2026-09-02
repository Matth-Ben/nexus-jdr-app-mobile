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

  testWidgets('les cartes outils/langues n\'apparaissent pas quand vides', (
    tester,
  ) async {
    await _pump(tester, _detail());

    expect(find.text("MAÎTRISES D'OUTILS"), findsNothing);
    expect(find.text('LANGUES CONNUES'), findsNothing);
    expect(find.text('APTITUDES DE CLASSE'), findsNothing);
  });

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

  testWidgets(
    "la scission des onglets \"Compétences\"/\"Sorts\" est étanche : des "
    'sorts non vides sur `detail` ne font fuiter aucun contenu "Sorts" dans '
    'CharacterSkillsTabBody — voir `character_spells_tab_body_test.dart` '
    'pour la contrepartie (les sorts vivent désormais uniquement dans '
    "`CharacterSpellsTabBody`), régression garde-fou pour la scission de "
    "l'onglet \"Compétences\" en 2 (\"Compétences\" + \"Sorts\").",
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
          spellSlots: const [CharacterSpellSlot(level: 1, total: 3, used: 1)],
        ),
      );

      expect(find.text('SORTS'), findsNothing);
      expect(find.text('Lumière'), findsNothing);
      expect(find.text('Sorts mineurs'), findsNothing);
    },
  );

  testWidgets('la carte langues affiche les noms quand non vide', (
    tester,
  ) async {
    await _pump(tester, _detail(knownLanguageNames: const ['Nain']));

    expect(find.text('LANGUES CONNUES'), findsOneWidget);
    expect(find.text('Nain'), findsOneWidget);
  });
}
