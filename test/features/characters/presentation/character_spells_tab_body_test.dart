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
          onToggleFavorite: (_) {},
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
    // "Niveau 1" apparaît deux fois depuis le recettage direction-artistique
    // du 13/09 : une fois dans la carte de synthèse "EMPLACEMENTS DE
    // SORTS" en tête d'onglet, une fois comme titre du groupe par niveau.
    expect(find.text('Niveau 1'), findsNWidgets(2));
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
    // Deux occurrences depuis le recettage du 13/09 : la carte de synthèse
    // "EMPLACEMENTS DE SORTS" en tête d'onglet porte les mêmes pastilles que
    // le groupe par niveau plus bas.
    expect(
      find.bySemanticsLabel('Emplacements de sorts : 2 restants sur 3'),
      findsNWidgets(2),
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

  testWidgets('un sort porte deux boutons inline "Infos"/"Lancer" (recettage '
      'direction-artistique du 13/09, remplace le chevron) ; taper la ligne '
      'ouvre toujours directement le panneau "Infos" (plus de sheet '
      'intermédiaire "Infos"/"Lancer")', (tester) async {
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
    expect(find.text('INFOS'), findsOneWidget);
    expect(find.text('LANCER'), findsOneWidget);

    await tester.tap(find.text('Lumière'));
    await tester.pumpAndSettle();

    expect(find.text('LUMIÈRE'), findsOneWidget);
    expect(find.text('Infos'), findsNothing);
  });

  testWidgets('bouton inline "Lancer" d\'un sort niveau 0 appelle directement '
      'onCastSpell(spell, null), sans ouvrir le panneau "Infos"', (
    tester,
  ) async {
    CharacterSpellEntry? castSpell;
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
            onCastSpell: (spell, slot) => castSpell = spell,
            onToggleFavorite: (_) {},
            onTogglePrepared: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('LANCER'));
    await tester.pumpAndSettle();

    expect(castSpell?.name, 'Lumière');
    expect(find.text('LUMIÈRE'), findsNothing);
  });

  testWidgets(
    'bouton inline "Lancer" visuellement désactivé (opacité réduite) pour '
    'un sort \'connu\' non préparé (niveau >= 1, pas encore castable) — un '
    'tap dessus n\'appelle jamais onCastSpell directement (le `InkWell` '
    'désactivé ne consomme pas le geste, qui remonte au `InkWell` de la '
    'ligne elle-même, ouvrant alors le panneau "Infos" comme n\'importe où '
    'ailleurs sur la ligne — comportement standard Flutter, pas un bug : le '
    'panneau "Infos" désactive lui aussi correctement "Lancer" dans ce cas, '
    'voir `spell_info_panel_test.dart`)',
    (tester) async {
      CharacterSpellEntry? castSpell;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CharacterSpellsTabBody(
              detail: _detail(
                spells: const [
                  CharacterSpellEntry(
                    id: 1,
                    name: 'Bouclier',
                    level: 1,
                    school: 'Abjuration',
                    status: 'connu',
                  ),
                ],
                spellSlots: const [
                  CharacterSpellSlot(level: 1, total: 2, used: 0),
                ],
              ),
              onCastSpell: (spell, slot) => castSpell = spell,
              onToggleFavorite: (_) {},
              onTogglePrepared: (_) {},
            ),
          ),
        ),
      );

      final lancerFinder = find.text('LANCER');
      expect(lancerFinder, findsOneWidget);
      final opacity = tester.widget<Opacity>(
        find.ancestor(of: lancerFinder, matching: find.byType(Opacity)).first,
      );
      expect(opacity.opacity, lessThan(1));

      await tester.tap(lancerFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(castSpell, isNull);
    },
  );

  group('favoris de sorts, distinction connu/préparé (docs/cahier-des-charges/'
      '11-fonctionnalites-a-ajouter.md section "Onglet Sorts")', () {
    Future<List<CharacterSpellEntry>> pumpWithFavoriteCallback(
      WidgetTester tester, {
      required List<CharacterSpellEntry> spells,
    }) async {
      final toggled = <CharacterSpellEntry>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CharacterSpellsTabBody(
              detail: _detail(spells: spells),
              onCastSpell: (_, _) {},
              onToggleFavorite: toggled.add,
              onTogglePrepared: (_) {},
            ),
          ),
        ),
      );
      return toggled;
    }

    testWidgets(
      'aucun favori épinglé : pas de section "FAVORIS", le sort n\'apparaît '
      'qu\'une fois (dans son groupe de niveau)',
      (tester) async {
        await pumpWithFavoriteCallback(
          tester,
          spells: const [
            CharacterSpellEntry(
              id: 1,
              name: 'Bouclier',
              level: 1,
              school: 'Abjuration',
              status: 'préparé',
            ),
          ],
        );

        expect(find.text('FAVORIS'), findsNothing);
        expect(find.text('Bouclier'), findsOneWidget);
      },
    );

    testWidgets(
      'un sort épinglé (isFavorite) apparaît dans la section "FAVORIS" en '
      'tête, en plus de son groupe de niveau habituel',
      (tester) async {
        await pumpWithFavoriteCallback(
          tester,
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
        );

        expect(find.text('FAVORIS'), findsOneWidget);
        // Une fois dans "FAVORIS", une fois dans le groupe "Niveau 1".
        expect(find.text('Bouclier'), findsNWidgets(2));
        // Dans la section "FAVORIS", le niveau est précisé dans le
        // sous-titre (plusieurs niveaux peuvent s'y mélanger) — voir
        // `character_spells_section.dart::_SpellRow.showLevelInSubtitle`.
        expect(find.textContaining('niv. 1'), findsOneWidget);
      },
    );

    testWidgets(
      'taper l\'étoile d\'un sort non favori appelle onToggleFavorite sans '
      'ouvrir le panneau "Infos" (zone de tap indépendante de la ligne)',
      (tester) async {
        final toggled = await pumpWithFavoriteCallback(
          tester,
          spells: const [
            CharacterSpellEntry(
              id: 1,
              name: 'Bouclier',
              level: 1,
              school: 'Abjuration',
              status: 'préparé',
            ),
          ],
        );

        await tester.tap(find.byIcon(Icons.star_border));
        await tester.pumpAndSettle();

        expect(toggled, hasLength(1));
        expect(toggled.single.id, 1);
        expect(find.text('BOUCLIER'), findsNothing);
      },
    );

    testWidgets('un sort déjà favori affiche une étoile pleine (Icons.star)', (
      tester,
    ) async {
      await pumpWithFavoriteCallback(
        tester,
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
      );

      // Une étoile pleine par occurrence (FAVORIS + groupe de niveau), plus
      // l'icône d'en-tête "★ FAVORIS" (`_FavoritesSection`), qui réutilise
      // aussi `Icons.star`.
      expect(find.byIcon(Icons.star), findsNWidgets(3));
      expect(find.byIcon(Icons.star_border), findsNothing);
    });

    testWidgets(
      'sous-titre "connu, non préparé" affiché pour un sort niveau >= 1 '
      '\'connu\', absent pour un sort mineur',
      (tester) async {
        await pumpWithFavoriteCallback(
          tester,
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
              name: 'Lumière',
              level: 0,
              school: 'Évocation',
              status: 'connu',
            ),
          ],
        );

        expect(find.text('connu, non préparé'), findsOneWidget);
      },
    );
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

  group('carte "EMPLACEMENTS DE SORTS" (recettage direction-artistique du '
      '13/09)', () {
    testWidgets(
      'affiche une ligne par niveau d\'emplacement en tête d\'onglet, avec '
      'la mention de réinitialisation au repos long',
      (tester) async {
        final semanticsHandle = tester.ensureSemantics();

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
            spellSlots: const [
              CharacterSpellSlot(level: 1, total: 3, used: 1),
              CharacterSpellSlot(level: 2, total: 2, used: 0),
            ],
          ),
        );

        expect(find.text('EMPLACEMENTS DE SORTS'), findsOneWidget);
        expect(find.text('Niveau 1'), findsWidgets);
        expect(find.text('Niveau 2'), findsOneWidget);
        expect(
          find.text('Se réinitialisent lors d\'un repos long.'),
          findsOneWidget,
        );

        semanticsHandle.dispose();
      },
    );

    testWidgets(
      'absente quand aucun niveau n\'a d\'emplacement réel (total > 0)',
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

        expect(find.text('EMPLACEMENTS DE SORTS'), findsNothing);
      },
    );
  });

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
      await tester.tap(find.text('Utiliser'));
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
              onToggleFavorite: (_) {},
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
        'uniquement, avec sous-titre "toujours préparé"', (tester) async {
      await _pump(
        tester,
        _detail(spells: const [ordinary, granted, oath], spellSlots: slots),
      );

      expect(find.text('DOMAINE'), findsOneWidget);
      expect(find.text('SERMENT'), findsOneWidget);
      expect(find.text('toujours préparé · Domaine'), findsOneWidget);
      expect(find.text('toujours préparé · Serment'), findsOneWidget);
      expect(find.text('connu, non préparé'), findsOneWidget);
    });

    testWidgets('pas d’étoile de favori sur un sort accordé sans ligne '
        'character_spells (étoile conservée sur un sort ordinaire)', (
      tester,
    ) async {
      await _pump(
        tester,
        _detail(spells: const [ordinary, granted], spellSlots: slots),
      );

      // Une seule étoile (vide) : celle du sort ordinaire.
      expect(find.byIcon(Icons.star_border), findsOneWidget);
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
}
