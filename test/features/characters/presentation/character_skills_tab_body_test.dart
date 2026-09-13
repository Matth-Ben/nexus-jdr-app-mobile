// Tests de widget de l'onglet "Compétences" de la fiche personnage — voir
// `docs/cahier-des-charges/04-fonctionnalites-app-mobile.md`, section
// "Onglet Compétences".
//
// `CharacterSkillsTabBody` est un `StatefulWidget` (depuis l'ajout du champ
// de recherche, recettage direction-artistique du 13/09) mais sans
// dépendance Riverpod/réseau : contrairement à `character_detail_screen_test.dart`,
// un simple `MaterialApp(home: ...)` suffit à le monter.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_class_feature.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_skill_row.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/character_spell_slot.dart';
import 'package:personnages/features/characters/presentation/widgets/character_skills_tab_body.dart';

CharacterDetail _detail({
  List<CharacterDetailClassRow> classes = const [],
  List<CharacterSkillRow> skills = const [],
  List<CharacterClassFeature> classFeatures = const [],
  List<String> armorProficiencyNames = const [],
  List<String> weaponProficiencyNames = const [],
  List<String> toolProficiencyNames = const [],
  List<String> knownLanguageNames = const [],
  List<String> knownInvocationNames = const [],
  List<CharacterSpellEntry> spells = const [],
  List<CharacterSpellSlot> spellSlots = const [],
}) {
  return CharacterDetail(
    id: '1',
    name: 'Test',
    classes: classes,
    xp: 0,
    currentHp: 10,
    maxHp: 10,
    temporaryHp: 0,
    abilityScores: const {'dex': 16, 'int': 10},
    skills: skills,
    classFeatures: classFeatures,
    armorProficiencyNames: armorProficiencyNames,
    weaponProficiencyNames: weaponProficiencyNames,
    toolProficiencyNames: toolProficiencyNames,
    knownLanguageNames: knownLanguageNames,
    knownInvocationNames: knownInvocationNames,
    spells: spells,
    spellSlots: spellSlots,
  );
}

Future<void> _pump(
  WidgetTester tester,
  CharacterDetail detail, {
  VoidCallback? onNavigateToSpells,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CharacterSkillsTabBody(
          detail: detail,
          onUseFeature: (_) {},
          onNavigateToSpells: onNavigateToSpells,
        ),
      ),
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

  testWidgets('chaque ligne de compétence porte un chip "D20" (recettage '
      'direction-artistique du 13/09, remplace l\'icône dé) en bout de ligne', (
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

    expect(find.text('D20'), findsOneWidget);
    expect(find.byIcon(Icons.casino_outlined), findsNothing);
  });

  testWidgets(
    'taper une ligne de compétence ouvre le mini lancer de dé virtuel avec '
    'le nom de la compétence et son bonus déjà calculé (docs/'
    'cahier-des-charges/11-fonctionnalites-a-ajouter.md, section "Onglet '
    'Compétences") — le chip "D20" ne change pas ce comportement, toute la '
    'ligne reste tappable',
    (tester) async {
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

      await tester.tap(find.text('Acrobaties'));
      await tester.pumpAndSettle();

      expect(find.text('ACROBATIES'), findsOneWidget);
      // Même bonus +5 que la ligne (mod dex +3 + maîtrise +2), retrouvé dans
      // la ligne de détail du jet ("d20 (X) +5 = ...").
      expect(find.textContaining('+5 ='), findsOneWidget);
    },
  );

  group(
    'recherche de compétence (recettage direction-artistique du 13/09)',
    () {
      const skills = [
        CharacterSkillRow(
          id: 1,
          name: 'Acrobaties',
          abilityId: 'dex',
          proficiency: 'competente',
        ),
        CharacterSkillRow(
          id: 2,
          name: 'Arcanes',
          abilityId: 'int',
          proficiency: 'aucune',
        ),
      ];

      testWidgets('le champ de recherche est toujours affiché', (tester) async {
        await _pump(tester, _detail(skills: skills));

        expect(
          find.widgetWithText(TextField, 'Rechercher une compétence'),
          findsOneWidget,
        );
      });

      testWidgets(
        'taper dans le champ ne garde que les compétences dont le nom '
        'correspond, sans masquer les autres cartes de l\'onglet',
        (tester) async {
          await _pump(
            tester,
            _detail(skills: skills, knownLanguageNames: const ['Nain']),
          );

          await tester.enterText(
            find.widgetWithText(TextField, 'Rechercher une compétence'),
            'acro',
          );
          await tester.pumpAndSettle();

          expect(find.text('Acrobaties'), findsOneWidget);
          expect(find.text('Arcanes'), findsNothing);
          // Carte "LANGUES CONNUES" non affectée par la recherche (spec de la
          // tâche : le champ ne filtre que "LES 18 COMPÉTENCES").
          expect(find.text('LANGUES CONNUES'), findsOneWidget);
        },
      );

      testWidgets(
        'aucune compétence ne correspond à la recherche : affiche un message '
        'dédié à la place de "LES 18 COMPÉTENCES"',
        (tester) async {
          await _pump(tester, _detail(skills: skills));

          await tester.enterText(
            find.widgetWithText(TextField, 'Rechercher une compétence'),
            'zzzzz',
          );
          await tester.pumpAndSettle();

          expect(
            find.text('Aucune compétence pour « zzzzz ».'),
            findsOneWidget,
          );
          expect(find.text('LES 18 COMPÉTENCES'), findsNothing);
        },
      );

      testWidgets(
        'icône "×" efface la recherche et restaure la liste complète',
        (tester) async {
          await _pump(tester, _detail(skills: skills));

          await tester.enterText(
            find.widgetWithText(TextField, 'Rechercher une compétence'),
            'acro',
          );
          await tester.pumpAndSettle();
          expect(find.text('Arcanes'), findsNothing);

          await tester.tap(find.byIcon(Icons.close));
          await tester.pumpAndSettle();

          expect(find.text('Acrobaties'), findsOneWidget);
          expect(find.text('Arcanes'), findsOneWidget);
        },
      );
    },
  );

  group('bandeau "SORTS →" (recettage direction-artistique du 13/09)', () {
    testWidgets('toujours affiché, entre "APTITUDES DE CLASSE" et "LES 18 '
        'COMPÉTENCES"', (tester) async {
      await _pump(
        tester,
        _detail(
          classFeatures: const [
            CharacterClassFeature(id: 1, name: 'Rage', level: 1),
          ],
        ),
      );

      expect(
        find.text('Les sorts et emplacements sont dans l\'onglet dédié.'),
        findsOneWidget,
      );
      expect(find.text('SORTS →'), findsOneWidget);

      final featuresY = tester.getTopLeft(find.text('APTITUDES DE CLASSE')).dy;
      final bannerY = tester
          .getTopLeft(
            find.text(
              'Les sorts et emplacements sont dans '
              'l\'onglet dédié.',
            ),
          )
          .dy;
      final skillsY = tester.getTopLeft(find.text('LES 18 COMPÉTENCES')).dy;

      expect(featuresY, lessThan(bannerY));
      expect(bannerY, lessThan(skillsY));
    });

    testWidgets('taper le bandeau appelle onNavigateToSpells', (tester) async {
      var navigateCount = 0;
      await _pump(tester, _detail(), onNavigateToSpells: () => navigateCount++);

      await tester.tap(find.text('SORTS →'));
      await tester.pumpAndSettle();

      expect(navigateCount, 1);
    });
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
    'une aptitude passive n\'est pas cliquable (pas de chevron, tap sans '
    'effet)',
    (tester) async {
      await _pump(
        tester,
        _detail(
          classFeatures: const [
            CharacterClassFeature(id: 2, name: 'Défense sans armure', level: 1),
          ],
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsNothing);

      await tester.tap(find.text('Défense sans armure'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Infos'), findsNothing);
    },
  );

  testWidgets(
    'une aptitude à usage limité est cliquable (chevron affiché) et ouvre '
    'la sheet d\'actions',
    (tester) async {
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

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      await tester.tap(find.text('Conduit divin'));
      await tester.pumpAndSettle();

      expect(find.text('Infos'), findsOneWidget);
      expect(find.text('Utiliser'), findsOneWidget);
      // Épuisée (0 restant) : "Utiliser" désactivée.
      expect(find.text('Épuisée'), findsOneWidget);
    },
  );

  testWidgets(
    'actionsDisabled désactive le tap sur les aptitudes à usage limité '
    '(repos en vol)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CharacterSkillsTabBody(
              detail: _detail(
                classFeatures: const [
                  CharacterClassFeature(
                    id: 1,
                    name: 'Conduit divin',
                    level: 2,
                    usesMax: 1,
                    usesRemaining: 1,
                    restType: 'repos_court',
                  ),
                ],
              ),
              onUseFeature: (_) {},
              actionsDisabled: true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Conduit divin'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Infos'), findsNothing);
    },
  );

  testWidgets(
    'les cartes armures/armes/outils/langues/invocations n\'apparaissent '
    'pas quand vides ; "CHOIX DE CLASSE" n\'apparaît plus jamais sur cet '
    'onglet depuis le recettage direction-artistique du 13/09 (widget '
    'conservé, juste son insertion retirée — voir '
    '`character_skills_tab_body.dart`)',
    (tester) async {
      await _pump(tester, _detail());

      expect(find.text("MAÎTRISES D'ARMURES"), findsNothing);
      expect(find.text("MAÎTRISES D'ARMES"), findsNothing);
      expect(find.text("MAÎTRISES D'OUTILS"), findsNothing);
      expect(find.text('LANGUES CONNUES'), findsNothing);
      expect(find.text('APTITUDES DE CLASSE'), findsNothing);
      expect(find.text('CHOIX DE CLASSE'), findsNothing);
      expect(find.text('INVOCATIONS CONNUES'), findsNothing);
    },
  );

  testWidgets(
    'la carte "INVOCATIONS CONNUES" affiche les noms quand non vide — même '
    'gap de lecture (occultiste)',
    (tester) async {
      await _pump(
        tester,
        _detail(
          knownInvocationNames: const ['Vue démoniaque', 'Décharge agonisante'],
        ),
      );

      expect(find.text('INVOCATIONS CONNUES'), findsOneWidget);
      expect(find.text('Vue démoniaque'), findsOneWidget);
      expect(find.text('Décharge agonisante'), findsOneWidget);
    },
  );

  testWidgets('la carte armures affiche les tokens quand non vide', (
    tester,
  ) async {
    await _pump(
      tester,
      _detail(armorProficiencyNames: const ['légère', 'boucliers']),
    );

    expect(find.text("MAÎTRISES D'ARMURES"), findsOneWidget);
    expect(find.text('légère'), findsOneWidget);
    expect(find.text('boucliers'), findsOneWidget);
  });

  testWidgets('la carte armes affiche les tokens quand non vide', (
    tester,
  ) async {
    await _pump(
      tester,
      _detail(weaponProficiencyNames: const ['courantes', 'martiales']),
    );

    expect(find.text("MAÎTRISES D'ARMES"), findsOneWidget);
    expect(find.text('courantes'), findsOneWidget);
    expect(find.text('martiales'), findsOneWidget);
  });

  testWidgets(
    'les cartes s\'affichent dans l\'ordre Compétences -> Armures -> Armes '
    '-> Outils -> Langues -> Invocations',
    (tester) async {
      // Viewport agrandi (même technique que
      // `character_inventory_tab_body_test.dart`) : avec les 6 cartes de ce
      // test simultanément non vides, le contenu dépasse la hauteur de test
      // par défaut — `ListView` (SliverList) ne construit que les enfants
      // visibles/dans le cacheExtent, `getTopLeft` échouerait sinon sur les
      // dernières cartes jamais montées.
      final originalSize = tester.view.physicalSize;
      final originalRatio = tester.view.devicePixelRatio;
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.physicalSize = originalSize;
        tester.view.devicePixelRatio = originalRatio;
      });

      await _pump(
        tester,
        _detail(
          armorProficiencyNames: const ['légère'],
          weaponProficiencyNames: const ['courantes'],
          toolProficiencyNames: const ['Outils de forgeron'],
          knownLanguageNames: const ['Nain'],
          knownInvocationNames: const ['Vue démoniaque'],
        ),
      );

      final skillsY = tester.getTopLeft(find.text('LES 18 COMPÉTENCES')).dy;
      final armorY = tester.getTopLeft(find.text("MAÎTRISES D'ARMURES")).dy;
      final weaponY = tester.getTopLeft(find.text("MAÎTRISES D'ARMES")).dy;
      final toolY = tester.getTopLeft(find.text("MAÎTRISES D'OUTILS")).dy;
      final languageY = tester.getTopLeft(find.text('LANGUES CONNUES')).dy;
      final invocationY = tester
          .getTopLeft(find.text('INVOCATIONS CONNUES'))
          .dy;

      expect(skillsY, lessThan(armorY));
      expect(armorY, lessThan(weaponY));
      expect(weaponY, lessThan(toolY));
      expect(toolY, lessThan(languageY));
      expect(languageY, lessThan(invocationY));
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

  testWidgets(
    "la scission des onglets \"Compétences\"/\"Sorts\" est étanche : des "
    'sorts non vides sur `detail` ne font fuiter aucun contenu "Sorts" dans '
    'CharacterSkillsTabBody (hors le bandeau "SORTS →", volontairement '
    'toujours affiché) — voir `character_spells_tab_body_test.dart` pour la '
    'contrepartie (les sorts vivent désormais uniquement dans '
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
