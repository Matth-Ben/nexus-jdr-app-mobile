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
import 'package:personnages/features/characters/domain/spell_cast_block_reason.dart';
import 'package:personnages/features/characters/data/character_spell_row_mapper.dart';
import 'package:personnages/core/widgets/primary_button.dart';
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

    // Magicien avec un sort à préparer : carte de préparation en tête ; la
    // carte "SORTS" ne porte plus que la magie de pacte (absente ici).
    expect(find.text('PRÉPARATION DES SORTS'), findsOneWidget);
    expect(find.text('SORTS'), findsNothing);
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

    testWidgets('état "PRÉPARÉ"/"NON PRÉPARÉ" en face du nom, ligne non '
        'préparée atténuée, sorts préparés en premier', (tester) async {
      await _pump(
        tester,
        _detail(
          spells: const [
            CharacterSpellEntry(
              id: 1,
              name: 'Armure de mage',
              level: 1,
              school: 'Abjuration',
              status: 'connu',
            ),
            CharacterSpellEntry(
              id: 2,
              name: 'Bouclier',
              level: 1,
              school: 'Abjuration',
              status: 'préparé',
            ),
            CharacterSpellEntry(
              id: 3,
              name: 'Lumière',
              level: 0,
              school: 'Évocation',
              status: 'connu',
            ),
          ],
        ),
      );

      // Un seul libellé de chaque : le sort mineur n'en porte aucun.
      expect(find.text('PRÉPARÉ'), findsOneWidget);
      expect(find.text('NON PRÉPARÉ'), findsOneWidget);

      double opacityOf(String name) => tester
          .widget<Opacity>(
            find.ancestor(of: find.text(name), matching: find.byType(Opacity)),
          )
          .opacity;
      expect(opacityOf('Bouclier'), 1);
      expect(opacityOf('Lumière'), 1);
      expect(opacityOf('Armure de mage'), lessThan(1));

      // "Bouclier" (préparé) avant "Armure de mage" (non préparé), malgré
      // l'ordre alphabétique.
      expect(
        tester.getTopLeft(find.text('Bouclier')).dy,
        lessThan(tester.getTopLeft(find.text('Armure de mage')).dy),
      );
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

  group('compteur "SORTS PRÉPARÉS X / Y"', () {
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

      expect(find.text('SORTS PRÉPARÉS'), findsOneWidget);
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
      // Le sort est construit par le mapper, comme à la lecture de la fiche :
      // pour un Barde, `requiresPreparation` est faux (le défaut `true` du
      // constructeur décrirait un cas que la lecture ne produit plus).
      final classes = [classRow(2, 'Barde', 3)];
      final spells = CharacterSpellRowMapper.toCharacterSpellEntries(
        const [
          {'id': 12, 'level': 1, 'school': 'Évocation'},
        ],
        names: const {'12': 'Projectile magique'},
        descriptions: const {},
        statuses: const {12: 'connu'},
        classes: classes,
      );
      expect(spells.single.requiresPreparation, isFalse);

      await _pump(tester, _detail(classes: classes, spells: spells));

      expect(find.text('Projectile magique'), findsOneWidget);
      expect(find.text('PRÉPARATION DES SORTS'), findsNothing);
      expect(find.text('SORTS PRÉPARÉS'), findsNothing);
      // Ni magie de pacte : la carte "SORTS" ne porterait plus que son titre
      // tout seul, elle est donc entièrement masquée (demande utilisateur du
      // 23/09/2026).
      expect(find.text('SORTS'), findsNothing);
    });

    testWidgets('limite dépassée : phrase d\'état dédiée', (tester) async {
      const second = CharacterSpellEntry(
        id: 13,
        name: 'Sommeil',
        level: 1,
        school: 'Enchantement',
        status: 'préparé',
      );
      await _pump(
        tester,
        _detail(
          abilityScores: const {'int': 10},
          spells: const [prepared, second],
        ),
      );

      expect(find.text('2 / 1'), findsOneWidget);
      expect(find.text('Limite dépassée de 1'), findsOneWidget);
    });

    testWidgets('sous la limite : nombre de sorts restant à préparer', (
      tester,
    ) async {
      await _pump(
        tester,
        _detail(
          classes: [classRow(1, 'Magicien', 3)],
          abilityScores: const {'int': 16},
          spells: const [prepared],
        ),
      );

      expect(find.text('Encore 5 sorts à préparer'), findsOneWidget);
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

      expect(find.text('SORTS PRÉPARÉS'), findsNothing);
    });
  });

  group('préparation : tous les sorts affichés, filtre et note', () {
    CharacterDetailClassRow clerc() => const CharacterDetailClassRow(
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
    const all = [cantrip, preparedSpell, unpreparedSpell, grantedSpell];

    testWidgets('par défaut ("Tous") : sorts non préparés affichés aussi, '
        'plus de bouton "Ajouter un sort"', (tester) async {
      await _pump(tester, _detail(classes: [clerc()], spells: all));

      expect(find.text('PRÉPARATION DES SORTS'), findsOneWidget);
      expect(find.text('Lumière'), findsOneWidget);
      expect(find.text('Bénédiction'), findsOneWidget);
      expect(find.text('Garde divine'), findsOneWidget);
      expect(find.text('Soins'), findsOneWidget);
      expect(find.text('Ajouter un sort'), findsNothing);
    });

    testWidgets('filtre "Préparés" : masque les sorts restant à préparer, '
        'garde sorts mineurs et sorts accordés', (tester) async {
      await _pump(tester, _detail(classes: [clerc()], spells: all));

      await tester.tap(find.text('PRÉPARÉS'));
      await tester.pumpAndSettle();

      expect(find.text('Soins'), findsNothing);
      expect(find.text('Lumière'), findsOneWidget);
      expect(find.text('Bénédiction'), findsOneWidget);
      expect(find.text('Garde divine'), findsOneWidget);
    });

    testWidgets('filtre "Non préparés" : uniquement les sorts restant à '
        'préparer', (tester) async {
      await _pump(tester, _detail(classes: [clerc()], spells: all));

      await tester.tap(find.text('NON PRÉPARÉS'));
      await tester.pumpAndSettle();

      expect(find.text('Soins'), findsOneWidget);
      expect(find.text('Lumière'), findsNothing);
      expect(find.text('Bénédiction'), findsNothing);
      expect(find.text('Garde divine'), findsNothing);
    });

    testWidgets('filtre sans résultat : message dédié, la carte de '
        'préparation reste affichée pour revenir en arrière', (tester) async {
      await _pump(
        tester,
        _detail(classes: [clerc()], spells: const [cantrip, preparedSpell]),
      );

      await tester.tap(find.text('NON PRÉPARÉS'));
      await tester.pumpAndSettle();

      expect(find.text('Aucun sort non préparé.'), findsOneWidget);
      expect(find.text('PRÉPARATION DES SORTS'), findsOneWidget);

      await tester.tap(find.text('TOUS'));
      await tester.pumpAndSettle();

      expect(find.text('Bénédiction'), findsOneWidget);
    });

    testWidgets('l\'icône ⓘ ouvre la note "PRÉPARATION DES SORTS" avec la '
        'limite actuelle du personnage', (tester) async {
      await _pump(
        tester,
        _detail(
          classes: [clerc()],
          abilityScores: const {'wis': 14},
          spells: all,
        ),
      );

      await tester.tap(
        find.byTooltip('Comment fonctionne la préparation des sorts ?'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Préparer pour lancer'), findsOneWidget);
      expect(find.text('Changer sa liste'), findsOneWidget);
      // Clerc niveau 1, Sagesse 14 (+2) : limite 3.
      expect(find.textContaining('Votre limite actuelle : 3.'), findsOneWidget);
    });

    testWidgets('personnage sans aucun sort à préparer (sorts mineurs/innés '
        'uniquement) : ni carte de préparation ni filtre', (tester) async {
      await _pump(tester, _detail(spells: const [cantrip]));

      expect(find.text('PRÉPARATION DES SORTS'), findsNothing);
      expect(find.text('NON PRÉPARÉS'), findsNothing);
      expect(find.text('Lumière'), findsOneWidget);
    });
  });

  // Barde, Ensorceleur, Occultiste, Rôdeur : sorts connus, lançables sans
  // préparation. Les sorts sont construits par le vrai mapper
  // (`CharacterSpellRowMapper.toCharacterSpellEntries`) à partir des classes
  // et de `source_class_id`, pour que ces tests couvrent la dérivation de
  // `requiresPreparation` et pas seulement son effet à l'écran.
  group('classes à sorts connus : lancer sans préparer', () {
    CharacterDetailClassRow cls(int id, String name, {bool primary = false}) =>
        CharacterDetailClassRow(
          classId: id,
          className: name,
          level: 3,
          isPrimary: primary,
          savingThrowProficiencies: const [],
          hitDie: 8,
        );
    final barde = cls(1, 'Barde', primary: true);
    final clerc = cls(2, 'Clerc');

    const spellRows = [
      {'id': 10, 'level': 0, 'school': ''},
      {'id': 11, 'level': 1, 'school': ''},
      {'id': 12, 'level': 1, 'school': ''},
      {'id': 13, 'level': 1, 'school': ''},
      {'id': 14, 'level': 1, 'school': ''},
    ];
    const names = {
      '10': 'Moquerie cruelle',
      '11': 'Charme-personne',
      '12': 'Héroïsme',
      '13': 'Soins',
      '14': 'Bénédiction',
    };
    // 11 : sort de Barde 'connu'. 12 : sort de Barde passé à 'préparé' par le
    // joueur (contournement de l'ancien défaut). 13/14 : sorts de Clerc.
    const statuses = {
      10: 'connu',
      11: 'connu',
      12: 'préparé',
      13: 'connu',
      14: 'préparé',
    };
    const slots = [CharacterSpellSlot(level: 1, total: 4, used: 0)];

    CharacterDetail detailFor(
      List<CharacterDetailClassRow> classes, {
      required Map<int, Set<int>> sources,
      Set<int> only = const {10, 11, 12, 13, 14},
    }) => _detail(
      classes: classes,
      abilityScores: const {'wis': 14},
      spellSlots: slots,
      spells: CharacterSpellRowMapper.toCharacterSpellEntries(
        [
          for (final row in spellRows)
            if (only.contains(row['id'])) row,
        ],
        names: names,
        descriptions: const {},
        statuses: {
          for (final entry in statuses.entries)
            if (only.contains(entry.key)) entry.key: entry.value,
        },
        classes: classes,
        sourceClassIds: sources,
      ),
    );

    double opacityOf(WidgetTester tester, String name) => tester
        .widget<Opacity>(
          find.ancestor(of: find.text(name), matching: find.byType(Opacity)),
        )
        .opacity;

    testWidgets('Barde seul : ni carte de préparation, ni filtre, ni '
        'compteur, ni note, ni libellé, ni ligne atténuée', (tester) async {
      await _pump(
        tester,
        detailFor(
          [barde],
          // 12 sans origine : un Barde seul n'a de toute façon rien à
          // préparer.
          sources: const {
            11: {1},
          },
          only: const {10, 11, 12},
        ),
      );

      expect(find.text('PRÉPARATION DES SORTS'), findsNothing);
      expect(find.text('SORTS PRÉPARÉS'), findsNothing);
      expect(find.text('TOUS'), findsNothing);
      expect(find.text('PRÉPARÉS'), findsNothing);
      expect(find.text('NON PRÉPARÉS'), findsNothing);
      expect(
        find.byTooltip('Comment fonctionne la préparation des sorts ?'),
        findsNothing,
      );
      expect(find.text('PRÉPARÉ'), findsNothing);
      expect(find.text('NON PRÉPARÉ'), findsNothing);

      expect(find.text('Moquerie cruelle'), findsOneWidget);
      expect(opacityOf(tester, 'Charme-personne'), 1);
      expect(opacityOf(tester, 'Héroïsme'), 1);
      // Ordre alphabétique simple : plus de bloc "non préparés" en fin de
      // niveau.
      expect(
        tester.getTopLeft(find.text('Charme-personne')).dy,
        lessThan(tester.getTopLeft(find.text('Héroïsme')).dy),
      );
    });

    testWidgets('Barde seul, panneau "Infos" d\'un sort "connu" : "Lancer" '
        'actif, ni lien de préparation ni ligne de raison', (tester) async {
      final cast = <CharacterSpellEntry>[];
      final toggled = <CharacterSpellEntry>[];
      await _pump(
        tester,
        detailFor(
          [barde],
          sources: const {
            11: {1},
          },
          only: const {10, 11, 12},
        ),
        onCastSpell: (spell, _) => cast.add(spell),
        onTogglePrepared: toggled.add,
      );

      await tester.tap(find.text('Charme-personne'));
      await tester.pumpAndSettle();

      expect(find.text('Préparer ce sort'), findsNothing);
      expect(find.text('Ne plus préparer'), findsNothing);
      expect(find.text(SpellCastBlockReason.unprepared.message), findsNothing);
      expect(
        find.text(SpellCastBlockReason.noSlotAvailable.message),
        findsNothing,
      );
      final button = tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, 'LANCER'),
      );
      expect(button.onPressed, isNotNull);

      await tester.tap(find.widgetWithText(PrimaryButton, 'LANCER'));
      await tester.pumpAndSettle();

      expect(cast.map((spell) => spell.name), ['Charme-personne']);
      expect(toggled, isEmpty);
    });

    testWidgets('Barde seul, sort déjà passé à "préparé" en base : lançable, '
        'sans bascule "Ne plus préparer"', (tester) async {
      await _pump(
        tester,
        detailFor([barde], sources: const {}, only: const {10, 11, 12}),
      );

      await tester.tap(find.text('Héroïsme'));
      await tester.pumpAndSettle();

      expect(find.text('Ne plus préparer'), findsNothing);
      expect(find.text('Préparer ce sort'), findsNothing);
      expect(
        tester
            .widget<PrimaryButton>(find.widgetWithText(PrimaryButton, 'LANCER'))
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('Barde seul sans emplacement : seule la raison "plus '
        'd\'emplacement" est affichée', (tester) async {
      final detail = detailFor([barde], sources: const {}, only: const {11})
          .copyWith(
            spellSlots: const [CharacterSpellSlot(level: 1, total: 4, used: 4)],
          );
      await _pump(tester, detail);

      await tester.tap(find.text('Charme-personne'));
      await tester.pumpAndSettle();

      expect(
        find.text(SpellCastBlockReason.noSlotAvailable.message),
        findsOneWidget,
      );
      expect(find.text(SpellCastBlockReason.unprepared.message), findsNothing);
    });

    const mixedSources = {
      11: {1},
      12: {1},
      13: {2},
      14: {2},
    };

    testWidgets('Barde + Clerc : la carte reste, le compteur ne compte que '
        'les sorts de Clerc, les sorts de Barde sont sans libellé', (
      tester,
    ) async {
      final detail = detailFor([barde, clerc], sources: mixedSources);
      await _pump(tester, detail);

      expect(find.text('PRÉPARATION DES SORTS'), findsOneWidget);
      expect(find.text('SORTS PRÉPARÉS'), findsOneWidget);
      // Clerc niveau 3, Sag 14 : limite 5. Un seul sort compté
      // ("Bénédiction") : "Héroïsme" (Barde, 'préparé' en base) est exclu.
      expect(detail.preparedSpellCount, 1);
      expect(find.text('1 / 5'), findsOneWidget);
      // Un seul libellé de chaque : ceux des deux sorts de Clerc.
      expect(find.text('PRÉPARÉ'), findsOneWidget);
      expect(find.text('NON PRÉPARÉ'), findsOneWidget);
      expect(opacityOf(tester, 'Charme-personne'), 1);
      expect(opacityOf(tester, 'Héroïsme'), 1);
      expect(opacityOf(tester, 'Bénédiction'), 1);
      expect(opacityOf(tester, 'Soins'), lessThan(1));
    });

    testWidgets('Barde + Clerc, filtre "Préparés" : les sorts de Barde sont '
        'rangés avec ce qui est lançable', (tester) async {
      await _pump(tester, detailFor([barde, clerc], sources: mixedSources));

      await tester.tap(find.text('PRÉPARÉS'));
      await tester.pumpAndSettle();

      expect(find.text('Charme-personne'), findsOneWidget);
      expect(find.text('Héroïsme'), findsOneWidget);
      expect(find.text('Bénédiction'), findsOneWidget);
      expect(find.text('Moquerie cruelle'), findsOneWidget);
      expect(find.text('Soins'), findsNothing);

      await tester.tap(find.text('NON PRÉPARÉS'));
      await tester.pumpAndSettle();

      expect(find.text('Soins'), findsOneWidget);
      expect(find.text('Charme-personne'), findsNothing);
      expect(find.text('Héroïsme'), findsNothing);
      expect(find.text('Bénédiction'), findsNothing);
    });

    testWidgets('Barde + Clerc, panneau "Infos" : sort de Barde lançable '
        'sans bascule', (tester) async {
      await _pump(tester, detailFor([barde, clerc], sources: mixedSources));

      await tester.tap(find.text('Charme-personne'));
      await tester.pumpAndSettle();
      expect(find.text('Préparer ce sort'), findsNothing);
      expect(find.text(SpellCastBlockReason.unprepared.message), findsNothing);
      expect(
        tester
            .widget<PrimaryButton>(find.widgetWithText(PrimaryButton, 'LANCER'))
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('Barde + Clerc, panneau "Infos" : sort de Clerc "connu" '
        'toujours à préparer', (tester) async {
      await _pump(tester, detailFor([barde, clerc], sources: mixedSources));

      await tester.tap(find.text('Soins'));
      await tester.pumpAndSettle();
      expect(find.text('Préparer ce sort'), findsOneWidget);
      expect(
        find.text(SpellCastBlockReason.unprepared.message),
        findsOneWidget,
      );
      expect(
        tester
            .widget<PrimaryButton>(find.widgetWithText(PrimaryButton, 'LANCER'))
            .onPressed,
        isNull,
      );
    });

    testWidgets('Barde + Clerc, sort sans origine connue : à préparer '
        '(comportement antérieur conservé)', (tester) async {
      await _pump(tester, detailFor([barde, clerc], sources: const {}));

      // 11 et 13 'connu' : tous deux "NON PRÉPARÉ" faute d'origine.
      expect(find.text('NON PRÉPARÉ'), findsNWidgets(2));
      expect(opacityOf(tester, 'Charme-personne'), lessThan(1));
    });
  });
}
