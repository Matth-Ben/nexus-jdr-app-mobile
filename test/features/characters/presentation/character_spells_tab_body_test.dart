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
import 'package:personnages/core/widgets/dashed_add_tile.dart';
import 'package:personnages/core/widgets/dice_type_badge.dart';
import 'package:personnages/features/characters/domain/character_class_feature.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/character_spell_slot.dart';
import 'package:personnages/features/characters/domain/spell_grant_source.dart';
import 'package:personnages/features/characters/presentation/widgets/character_spells_tab_body.dart';
import 'package:personnages/features/characters/presentation/widgets/class_feature_action_sheet.dart';
import 'package:personnages/features/characters/presentation/widgets/spell_action_sheet.dart';

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
  List<CharacterClassFeature> classFeatures = const [],
  Map<String, int> abilityScores = const {},
}) {
  return CharacterDetail(
    id: '1',
    name: 'Test',
    classes: classes,
    xp: 0,
    currentHp: 10,
    maxHp: 10,
    temporaryHp: 0,
    abilityScores: abilityScores,
    spells: spells,
    spellSlots: spellSlots,
    pactSpellSlot: pactSpellSlot,
    classFeatures: classFeatures,
  );
}

Future<void> _pump(
  WidgetTester tester,
  CharacterDetail detail, {
  UseClassFeatureCallback? onUseFeature,
  CastSpellCallback? onCastSpell,
  ToggleSpellFlagCallback? onTogglePrepared,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CharacterSpellsTabBody(
          detail: detail,
          onCastSpell: onCastSpell ?? (_, _) {},
          onTogglePrepared: onTogglePrepared ?? (_) {},
          onUseFeature: onUseFeature,
        ),
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
    expect(find.text('Niveau 1'), findsOneWidget);
    expect(find.text('Bouclier'), findsOneWidget);
    // L'école ("(Évocation)"/"(Abjuration)") n'est plus affichée en bout de
    // ligne depuis le recettage direction-artistique du 13/09.
    expect(find.text('(Évocation)'), findsNothing);
    expect(find.text('(Abjuration)'), findsNothing);
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

  testWidgets(
    'une ligne de sort ne porte plus de boutons inline "Infos"/"Lancer" '
    '(redondants avec le panneau) ; taper la ligne ouvre directement le '
    'panneau "Infos", qui porte son propre bouton "Lancer" en pied (voir '
    '`spell_info_panel_test.dart`)',
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

      expect(find.byIcon(Icons.chevron_right), findsNothing);
      expect(find.text('INFOS'), findsNothing);
      expect(find.text('LANCER'), findsNothing);

      await tester.tap(find.text('Lumière'));
      await tester.pumpAndSettle();

      expect(find.text('LUMIÈRE'), findsOneWidget);
    },
  );

  group('ligne de sort : nom + dé, sans sous-titre de statut ni favori', () {
    testWidgets('ni section "FAVORIS" ni étoile, même pour un sort marqué '
        'isFavorite en base (donnée héritée)', (tester) async {
      await _pump(
        tester,
        _detail(
          spells: const [
            CharacterSpellEntry(
              id: 1,
              name: 'Bouclier',
              level: 1,
              school: 'Abjuration',
              status: 'préparé',
              isFavorite: true,
            ),
          ],
        ),
      );

      expect(find.text('FAVORIS'), findsNothing);
      expect(find.text('Bouclier'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsNothing);
      expect(find.byIcon(Icons.star_border), findsNothing);
    });

    testWidgets('aucun sous-titre "connu, non préparé"/"préparé" sous le nom '
        'd\'un sort', (tester) async {
      await _pump(
        tester,
        _detail(
          spells: const [
            CharacterSpellEntry(
              id: 1,
              name: 'Bouclier',
              level: 1,
              school: 'Abjuration',
              status: 'connu',
            ),
            CharacterSpellEntry(
              id: 2,
              name: 'Armure de mage',
              level: 1,
              school: 'Abjuration',
              status: 'préparé',
            ),
          ],
        ),
      );

      expect(find.text('connu, non préparé'), findsNothing);
      expect(find.text('préparé'), findsNothing);
    });

    testWidgets('le dé de dégâts est collé au nom du sort, la pastille '
        '"DOMAINE" en face à droite', (tester) async {
      await _pump(
        tester,
        _detail(
          spells: const [
            CharacterSpellEntry(
              id: 1,
              name: 'Éclair traçant',
              level: 1,
              school: 'Évocation',
              status: 'préparé',
              description: 'La cible subit 4d6 dégâts radiants.',
              grantSource: SpellGrantSource.domain,
              isPersisted: false,
            ),
          ],
        ),
      );

      final nameRight = tester.getTopRight(find.text('Éclair traçant')).dx;
      final diceRect = tester.getRect(find.byType(DiceTypeBadge));
      final badgeLeft = tester.getTopLeft(find.text('DOMAINE')).dx;

      // Dé immédiatement après le nom (simple gouttière), jamais repoussé à
      // l'autre bout de la ligne.
      expect(diceRect.left - nameRight, lessThan(16));
      expect(badgeLeft, greaterThan(diceRect.right));
    });
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

  group('carte "INVOCATIONS & APTITUDES À USAGE LIMITÉ" (recettage '
      'direction-artistique du 13/09)', () {
    testWidgets(
      'affichée en pied d\'onglet, ne liste que les aptitudes non passives, '
      'quand onUseFeature est fourni',
      (tester) async {
        await _pump(
          tester,
          _detail(
            spells: const [
              CharacterSpellEntry(
                id: 1,
                name: 'Bouclier',
                level: 1,
                school: 'Abjuration',
                status: 'connu',
              ),
            ],
            classFeatures: const [
              CharacterClassFeature(
                id: 1,
                name: 'Invocation occulte',
                level: 1,
                usesMax: 1,
                usesRemaining: 1,
                restType: 'repos_long',
              ),
              CharacterClassFeature(id: 2, name: 'Aptitude passive', level: 1),
            ],
          ),
          onUseFeature: (_) {},
        );

        expect(
          find.text('INVOCATIONS & APTITUDES À USAGE LIMITÉ'),
          findsOneWidget,
        );
        expect(find.text('Invocation occulte'), findsOneWidget);
        expect(find.text('Aptitude passive'), findsNothing);
      },
    );

    testWidgets(
      'absente quand onUseFeature est null (ex. vue en lecture seule)',
      (tester) async {
        await _pump(
          tester,
          _detail(
            classFeatures: const [
              CharacterClassFeature(
                id: 1,
                name: 'Invocation occulte',
                level: 1,
                usesMax: 1,
                usesRemaining: 1,
                restType: 'repos_long',
              ),
            ],
          ),
        );

        expect(
          find.text('INVOCATIONS & APTITUDES À USAGE LIMITÉ'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'absente quand aucune aptitude non passive n\'existe, même avec '
      'onUseFeature fourni',
      (tester) async {
        await _pump(
          tester,
          _detail(
            classFeatures: const [
              CharacterClassFeature(id: 1, name: 'Aptitude passive', level: 1),
            ],
          ),
          onUseFeature: (_) {},
        );

        expect(
          find.text('INVOCATIONS & APTITUDES À USAGE LIMITÉ'),
          findsNothing,
        );
      },
    );

    testWidgets('taper "Utiliser" appelle onUseFeature avec l\'aptitude', (
      tester,
    ) async {
      CharacterClassFeature? used;
      await _pump(
        tester,
        _detail(
          classFeatures: const [
            CharacterClassFeature(
              id: 1,
              name: 'Invocation occulte',
              level: 1,
              usesMax: 1,
              usesRemaining: 1,
              restType: 'repos_long',
            ),
          ],
        ),
        onUseFeature: (feature) => used = feature,
      );

      await tester.tap(find.text('Invocation occulte'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('UTILISER'));
      await tester.pumpAndSettle();

      expect(used?.id, 1);
    });
  });

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
              onTogglePrepared: (_) {},
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

  group('sorts accordés par une sous-classe', () {
    const ordinary = CharacterSpellEntry(
      id: 1,
      name: 'Bouclier',
      level: 1,
      school: 'Abjuration',
      status: 'connu',
    );
    const granted = CharacterSpellEntry(
      id: 2,
      name: 'Bénédiction',
      level: 1,
      school: 'Enchantement',
      status: 'préparé',
      grantSource: SpellGrantSource.domain,
      isPersisted: false,
    );
    const oath = CharacterSpellEntry(
      id: 3,
      name: 'Faveur divine',
      level: 1,
      school: 'Évocation',
      status: 'préparé',
      grantSource: SpellGrantSource.oath,
      isPersisted: false,
    );
    const slots = [CharacterSpellSlot(level: 1, total: 2, used: 0)];

    testWidgets('badge DOMAINE/SERMENT visible sur les sorts accordés '
        'uniquement, sans sous-titre "toujours préparé"', (tester) async {
      await _pump(
        tester,
        _detail(spells: const [ordinary, granted, oath], spellSlots: slots),
      );

      expect(find.text('DOMAINE'), findsOneWidget);
      expect(find.text('SERMENT'), findsOneWidget);
      expect(find.textContaining('toujours préparé'), findsNothing);
    });

    testWidgets('non retirable : le panneau Infos d’un sort accordé ne '
        'propose ni "Préparer" ni "Ne plus préparer"', (tester) async {
      var toggled = 0;
      await _pump(
        tester,
        _detail(spells: const [granted], spellSlots: slots),
        onTogglePrepared: (_) => toggled++,
      );

      await tester.tap(find.text('Bénédiction'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Toujours préparé — sort de domaine'),
        findsOneWidget,
      );
      expect(find.text('Ne plus préparer'), findsNothing);
      expect(find.text('Préparer ce sort'), findsNothing);
      expect(toggled, 0);
    });

    testWidgets('un sort ordinaire "connu" garde la bascule "Préparer ce '
        'sort" (contrôle négatif)', (tester) async {
      await _pump(tester, _detail(spells: const [ordinary], spellSlots: slots));

      await tester.tap(find.text('Bouclier'));
      await tester.pumpAndSettle();

      expect(find.text('Préparer ce sort'), findsOneWidget);
    });

    testWidgets('lancer un sort accordé fonctionne comme un sort préparé', (
      tester,
    ) async {
      final cast = <CharacterSpellEntry>[];
      await _pump(
        tester,
        _detail(spells: const [granted], spellSlots: slots),
        onCastSpell: (spell, slot) => cast.add(spell),
      );

      await tester.tap(find.text('Bénédiction'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('LANCER'));
      await tester.pumpAndSettle();

      expect(cast, [granted]);
    });

    testWidgets('la fiche n’affiche jamais de décompte préparés qui '
        'inclurait un sort accordé (le décompte vit dans '
        'CharacterDetail.preparedSpellCount)', (tester) async {
      final detail = _detail(spells: const [ordinary, granted, oath]);
      expect(detail.preparedSpellCount, 0);
      expect(detail.grantedSpells, hasLength(2));
    });
  });

  group('compteur "PRÉPARÉS X / Y"', () {
    const prepared = CharacterSpellEntry(
      id: 10,
      name: 'Bouclier',
      level: 1,
      school: 'Abjuration',
      status: 'préparé',
    );
    const cantrip = CharacterSpellEntry(
      id: 11,
      name: 'Lumière',
      level: 0,
      school: 'Évocation',
      status: 'préparé',
    );
    const known = CharacterSpellEntry(
      id: 12,
      name: 'Projectile magique',
      level: 1,
      school: 'Évocation',
      status: 'connu',
    );

    CharacterDetailClassRow classRow(
      int id,
      String name,
      int level, {
      bool primary = true,
    }) => CharacterDetailClassRow(
      classId: id,
      className: name,
      level: level,
      isPrimary: primary,
      savingThrowProficiencies: const [],
      hitDie: 8,
    );

    testWidgets('Magicien niveau 3, Int 16 : limite 6, sorts mineurs et '
        'sorts connus non comptés', (tester) async {
      await _pump(
        tester,
        _detail(
          classes: [classRow(1, 'Magicien', 3)],
          abilityScores: const {'int': 16},
          spells: const [prepared, cantrip, known],
        ),
      );

      expect(find.text('PRÉPARÉS'), findsOneWidget);
      expect(find.text('1 / 6'), findsOneWidget);
    });

    testWidgets('limite atteinte : le compteur reste affiché et l action '
        '"Préparer" n est pas bloquée', (tester) async {
      final toggled = <CharacterSpellEntry>[];
      await _pump(
        tester,
        _detail(
          abilityScores: const {'int': 10},
          spells: const [prepared, known],
        ),
        onTogglePrepared: toggled.add,
      );
      // Magicien niveau 1, Int 10 : limite 1, déjà atteinte.
      expect(find.text('1 / 1'), findsOneWidget);

      await tester.tap(find.text('Projectile magique'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Préparer ce sort'));
      await tester.pumpAndSettle();

      expect(toggled, [known]);
    });

    testWidgets('classe à sorts connus : aucun compteur', (tester) async {
      await _pump(
        tester,
        _detail(classes: [classRow(2, 'Barde', 3)], spells: const [known]),
      );

      expect(find.text('PRÉPARÉS'), findsNothing);
      // Ni compteur "PRÉPARÉS", ni favori, ni magie de pacte : la carte
      // "SORTS" ne porterait plus que son titre tout seul, elle est donc
      // entièrement masquée (demande utilisateur du 23/09/2026) — chaque
      // niveau de sort reste identifié par son propre titre de carte
      // ("Niveau 1"), pas besoin d'un bloc "SORTS" vide au-dessus.
      expect(find.text('SORTS'), findsNothing);
    });

    testWidgets('plusieurs classes qui préparent : aucun compteur', (
      tester,
    ) async {
      await _pump(
        tester,
        _detail(
          classes: [
            classRow(1, 'Magicien', 3),
            classRow(3, 'Clerc', 2, primary: false),
          ],
          spells: const [prepared],
        ),
      );

      expect(find.text('PRÉPARÉS'), findsNothing);
    });
  });

  group('filtrage par défaut des lanceurs à préparation « liste complète » '
      '(Clerc/Druide/Paladin)', () {
    CharacterDetailClassRow clerc({int level = 1}) =>
        const CharacterDetailClassRow(
          classId: 5,
          className: 'Clerc',
          level: 1,
          isPrimary: true,
          savingThrowProficiencies: [],
          hitDie: 8,
        );

    const cantrip = CharacterSpellEntry(
      id: 1,
      name: 'Lumière',
      level: 0,
      school: 'Évocation',
      status: 'connu',
    );
    const preparedSpell = CharacterSpellEntry(
      id: 2,
      name: 'Bénédiction',
      level: 1,
      school: 'Enchantement',
      status: 'préparé',
    );
    const unpreparedSpell = CharacterSpellEntry(
      id: 3,
      name: 'Soins',
      level: 1,
      school: 'Évocation',
      status: 'connu',
    );
    const grantedSpell = CharacterSpellEntry(
      id: 4,
      name: 'Garde divine',
      level: 1,
      school: 'Abjuration',
      status: 'préparé',
      grantSource: SpellGrantSource.domain,
      isPersisted: false,
    );

    testWidgets(
      'masque un sort connu jamais préparé, garde les cantrips/sorts de '
      'sous-classe/préparés visibles, affiche le bouton "Ajouter un sort"',
      (tester) async {
        await _pump(
          tester,
          _detail(
            classes: [clerc()],
            spells: const [
              cantrip,
              preparedSpell,
              unpreparedSpell,
              grantedSpell,
            ],
          ),
        );

        expect(find.text('Lumière'), findsOneWidget);
        expect(find.text('Bénédiction'), findsOneWidget);
        expect(find.text('Garde divine'), findsOneWidget);
        expect(find.text('Soins'), findsNothing);
        expect(
          find.widgetWithText(DashedAddTile, 'Ajouter un sort'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'aucun sort préparé : affiche l\'état "AUCUN SORT PRÉPARÉ" à la '
      'place des groupes de niveau >= 1, cantrip toujours visible '
      'au-dessus, bouton "Ajouter un sort" toujours affiché',
      (tester) async {
        await _pump(
          tester,
          _detail(classes: [clerc()], spells: const [cantrip, unpreparedSpell]),
        );

        expect(find.text('AUCUN SORT PRÉPARÉ'), findsOneWidget);
        expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
        expect(find.text('Lumière'), findsOneWidget);
        expect(find.text('Soins'), findsNothing);
        expect(
          find.widgetWithText(DashedAddTile, 'Ajouter un sort'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'groupe de niveau >= 1 avec seulement un sort accordé par sous-classe '
      '(aucun sort réellement préparé) : "AUCUN SORT PRÉPARÉ" ne s\'affiche '
      'pas, le sort accordé reste visible dans son groupe',
      (tester) async {
        await _pump(
          tester,
          _detail(classes: [clerc()], spells: const [cantrip, grantedSpell]),
        );

        expect(find.text('AUCUN SORT PRÉPARÉ'), findsNothing);
        expect(find.text('Garde divine'), findsOneWidget);
      },
    );

    testWidgets(
      'une classe à sorts connus (Magicien, classe de départ par défaut) '
      'n\'est jamais filtrée ni dotée du bouton "Ajouter un sort"',
      (tester) async {
        await _pump(tester, _detail(spells: const [unpreparedSpell]));

        expect(find.text('Soins'), findsOneWidget);
        expect(find.byType(DashedAddTile), findsNothing);
        expect(find.text('AUCUN SORT PRÉPARÉ'), findsNothing);
      },
    );

    testWidgets('multiclassage Clerc + Magicien : tout l\'onglet passe en mode '
        'filtré (comportement le plus simple, pas de distinction par classe '
        'd\'origine du sort)', (tester) async {
      await _pump(
        tester,
        _detail(
          classes: [
            clerc(),
            const CharacterDetailClassRow(
              classId: 1,
              className: 'Magicien',
              level: 1,
              isPrimary: false,
              savingThrowProficiencies: [],
              hitDie: 6,
            ),
          ],
          spells: const [unpreparedSpell],
        ),
      );

      expect(find.text('Soins'), findsNothing);
      expect(find.byType(DashedAddTile), findsOneWidget);
    });

    testWidgets('taper "Ajouter un sort" ouvre la sheet "AJOUTER UN SORT"', (
      tester,
    ) async {
      await _pump(
        tester,
        _detail(
          classes: [clerc()],
          spells: const [cantrip, preparedSpell, unpreparedSpell],
        ),
      );

      await tester.tap(find.text('Ajouter un sort'));
      await tester.pumpAndSettle();

      expect(find.text('AJOUTER UN SORT'), findsOneWidget);
      // La sheet affiche la liste complète (dont le sort masqué par
      // défaut dans l'onglet).
      expect(find.text('Soins'), findsOneWidget);
    });
  });
}
