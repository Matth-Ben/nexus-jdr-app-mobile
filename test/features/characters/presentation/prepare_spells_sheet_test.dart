// Tests de widget de la sheet "Préparer mes sorts"
// (`presentation/widgets/prepare_spells_sheet.dart`) — proposée à la fin
// d'un repos long quand le joueur choisit de changer ses sorts préparés
// (voir `rest_sheet_test.dart`, `character_detail_screen_test.dart`). Même
// patron que `spell_info_panel_test.dart` : la sheet est ouverte depuis un
// `Builder` minimal, les callbacks sont de simples enregistreurs d'appels
// synchrones.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/rules/spell_status.dart';
import 'package:personnages/core/widgets/checkable_option_tile.dart';
import 'package:personnages/core/widgets/dice_type_badge.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/character_spell_slot.dart';
import 'package:personnages/features/characters/domain/prepared_spells_limit.dart';
import 'package:personnages/features/characters/domain/spell_cast_block_reason.dart';
import 'package:personnages/features/characters/domain/spell_grant_source.dart';
import 'package:personnages/features/characters/presentation/widgets/prepare_spells_sheet.dart';

/// Construit un [ClassPreparedSpells] de test — [preparedCount] est
/// toujours ignoré par la sheet (elle recalcule le décompte localement,
/// voir `_PrepareSpellsSheetContentState._preparedCount`/
/// `_preparedCountForClass`), gardé à 0 par défaut pour ne pas laisser
/// croire qu'il pilote le rendu.
ClassPreparedSpells _classLimit(
  String className,
  int limit, {
  Object classId = 1,
}) => ClassPreparedSpells(
  classId: classId,
  className: className,
  limit: limit,
  preparedCount: 0,
);

const _cantrip = CharacterSpellEntry(
  id: 1,
  name: 'Lumière',
  level: 0,
  school: 'Évocation',
  status: SpellStatus.known,
);
const _prepared = CharacterSpellEntry(
  id: 2,
  name: 'Bénédiction',
  level: 1,
  school: 'Enchantement',
  status: SpellStatus.prepared,
);
const _unprepared = CharacterSpellEntry(
  id: 3,
  name: 'Soins',
  level: 1,
  school: 'Évocation',
  status: SpellStatus.known,
  description: 'Vous infligez 1d8 dégâts de force à la cible.',
);
const _granted = CharacterSpellEntry(
  id: 4,
  name: 'Garde divine',
  level: 1,
  school: 'Abjuration',
  status: SpellStatus.prepared,
  grantSource: SpellGrantSource.domain,
  isPersisted: false,
);

void main() {
  List<CharacterSpellEntry> toggled = [];
  List<CharacterSpellEntry> cast = [];

  Future<void> pumpSheet(
    WidgetTester tester, {
    required List<CharacterSpellEntry> spells,
    List<CharacterSpellSlot> spellSlots = const [],
    CharacterSpellSlot? pactSlot,
    List<ClassPreparedSpells> classLimits = const [],
  }) async {
    toggled = [];
    cast = [];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showPrepareSpellsSheet(
                  context,
                  spells: spells,
                  spellSlots: spellSlots,
                  pactSlot: pactSlot,
                  classLimits: classLimits,
                  onTogglePrepared: toggled.add,
                  onCastSpell: (spell, _) => cast.add(spell),
                ),
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'affiche la liste complète (sorts préparés et non préparés), exclut '
    'les sorts mineurs',
    (tester) async {
      await pumpSheet(
        tester,
        spells: const [_cantrip, _prepared, _unprepared, _granted],
      );

      expect(find.text('PRÉPARER MES SORTS'), findsOneWidget);
      expect(find.text('Bénédiction'), findsOneWidget);
      expect(find.text('Soins'), findsOneWidget);
      expect(find.text('Garde divine'), findsOneWidget);
      // Sort mineur exclu de cette sheet (toujours visible ailleurs, aucune
      // notion de préparation à cocher).
      expect(find.text('Lumière'), findsNothing);
    },
  );

  testWidgets(
    'affiche le badge de dé de dégâts à côté du nom d\'un sort qui en a un',
    (tester) async {
      await pumpSheet(tester, spells: const [_unprepared]);

      expect(find.byType(DiceTypeBadge), findsOneWidget);
      expect(find.text('1d8'), findsOneWidget);
    },
  );

  testWidgets(
    'aucun badge de dé pour un sort sans dé de dégâts dans sa description',
    (tester) async {
      await pumpSheet(tester, spells: const [_prepared]);

      expect(find.byType(DiceTypeBadge), findsNothing);
    },
  );

  testWidgets('la recherche filtre la liste par nom', (tester) async {
    await pumpSheet(tester, spells: const [_prepared, _unprepared]);

    await tester.enterText(
      find.widgetWithText(TextField, 'Rechercher un sort'),
      'soins',
    );
    await tester.pumpAndSettle();

    expect(find.text('Soins'), findsOneWidget);
    expect(find.text('Bénédiction'), findsNothing);
  });

  testWidgets(
    'cocher un sort non préparé appelle onTogglePrepared sans fermer la '
    'sheet, et la case reste cochée (état local)',
    (tester) async {
      await pumpSheet(tester, spells: const [_unprepared]);

      final tileFinder = find.byType(CheckableOptionTile);
      expect(tileFinder, findsOneWidget);
      expect(tester.widget<CheckableOptionTile>(tileFinder).checked, isFalse);

      await tester.tap(find.text('Soins'));
      await tester.pumpAndSettle();

      expect(toggled, [_unprepared]);
      // La sheet reste ouverte.
      expect(find.text('PRÉPARER MES SORTS'), findsOneWidget);
      expect(tester.widget<CheckableOptionTile>(tileFinder).checked, isTrue);
    },
  );

  testWidgets(
    'basculer deux fois le même sort alterne correctement la direction '
    'transmise à onTogglePrepared (régression : status figé au snapshot '
    "d'ouverture de la sheet)",
    (tester) async {
      await pumpSheet(tester, spells: const [_unprepared]);

      await tester.tap(find.text('Soins'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Soins'));
      await tester.pumpAndSettle();

      expect(toggled, hasLength(2));
      // 1er appel : avant préparation, status 'connu' -> l'appelant dérive
      // prepared: true.
      expect(toggled[0].status, SpellStatus.known);
      // 2e appel : avant dé-préparation, status doit refléter 'préparé' (pas
      // à nouveau 'connu') -> l'appelant dérive prepared: false. Sans le
      // correctif, les deux appels auraient porté 'connu'.
      expect(toggled[1].status, SpellStatus.prepared);
      final tile = tester.widget<CheckableOptionTile>(
        find.byType(CheckableOptionTile),
      );
      expect(tile.checked, isFalse);
    },
  );

  testWidgets('un sort accordé par une sous-classe est coché, non interactif', (
    tester,
  ) async {
    await pumpSheet(tester, spells: const [_granted]);

    final tile = tester.widget<CheckableOptionTile>(
      find.byType(CheckableOptionTile),
    );
    expect(tile.checked, isTrue);
    expect(tile.enabled, isFalse);

    await tester.tap(find.text('Garde divine'));
    await tester.pumpAndSettle();

    expect(toggled, isEmpty);
  });

  testWidgets('le bouton ⓘ ouvre le panneau "Infos" du sort', (tester) async {
    await pumpSheet(tester, spells: const [_unprepared]);

    await tester.tap(find.byIcon(Icons.info_outline_rounded));
    await tester.pumpAndSettle();

    expect(find.text('SOINS'), findsOneWidget);
  });

  testWidgets('basculer la préparation depuis le panneau "Infos" reste synchronisé '
      'avec la case de la sheet "Préparer mes sorts" derrière', (tester) async {
    await pumpSheet(tester, spells: const [_unprepared]);

    await tester.tap(find.byIcon(Icons.info_outline_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Préparer ce sort'));
    await tester.pumpAndSettle();

    expect(toggled, [_unprepared]);
    // Retour sur la sheet "Préparer mes sorts", la case est maintenant cochée.
    final tile = tester.widget<CheckableOptionTile>(
      find.byType(CheckableOptionTile),
    );
    expect(tile.checked, isTrue);
  });

  testWidgets(
    'compteur "SORTS PRÉPARÉS X / Y" affiché avec une limite, mis à jour à '
    'chaque case cochée (sorts accordés non comptés)',
    (tester) async {
      await pumpSheet(
        tester,
        spells: const [_prepared, _unprepared, _granted],
        classLimits: [_classLimit('Clerc', 2)],
      );

      expect(find.text('SORTS PRÉPARÉS'), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);

      await tester.tap(find.text('Soins'));
      await tester.pumpAndSettle();

      expect(find.text('2 / 2'), findsOneWidget);
      expect(find.text('Limite atteinte'), findsOneWidget);
    },
  );

  testWidgets('sans classe qui prépare (classLimits vide) : aucun compteur', (
    tester,
  ) async {
    await pumpSheet(tester, spells: const [_prepared, _unprepared]);

    expect(find.text('SORTS PRÉPARÉS'), findsNothing);
  });

  group(
    'multiclassé : deux classes qui préparent (plus de masquage total)',
    () {
      const clercSpell = CharacterSpellEntry(
        id: 40,
        name: 'Bénédiction',
        level: 1,
        school: 'Enchantement',
        status: SpellStatus.known,
        sourceClassIds: {10},
      );
      const paladinSpell = CharacterSpellEntry(
        id: 41,
        name: 'Protection contre le mal',
        level: 1,
        school: 'Abjuration',
        status: SpellStatus.known,
        sourceClassIds: {20},
      );
      final classLimits = [
        _classLimit('Clerc', 2, classId: 10),
        _classLimit('Paladin', 1, classId: 20),
      ];

      testWidgets('affiche un compteur par classe, avec son nom en libellé', (
        tester,
      ) async {
        await pumpSheet(
          tester,
          spells: [clercSpell, paladinSpell],
          classLimits: classLimits,
        );

        expect(find.text('SORTS PRÉPARÉS — CLERC'), findsOneWidget);
        expect(find.text('0 / 2'), findsOneWidget);
        expect(find.text('SORTS PRÉPARÉS — PALADIN'), findsOneWidget);
        expect(find.text('0 / 1'), findsOneWidget);
      });

      testWidgets(
        'cocher un sort de Clerc ne met à jour que le compteur de Clerc',
        (tester) async {
          await pumpSheet(
            tester,
            spells: [clercSpell, paladinSpell],
            classLimits: classLimits,
          );

          await tester.tap(find.text('Bénédiction'));
          await tester.pumpAndSettle();

          expect(find.text('1 / 2'), findsOneWidget);
          expect(find.text('0 / 1'), findsOneWidget);
        },
      );

      testWidgets(
        'limite de Paladin atteinte : son sort non cochable, celui de Clerc '
        'reste cochable',
        (tester) async {
          await pumpSheet(
            tester,
            spells: [clercSpell, paladinSpell],
            classLimits: [
              _classLimit('Clerc', 2, classId: 10),
              _classLimit('Paladin', 0, classId: 20),
            ],
          );

          final clercTile = tester.widget<CheckableOptionTile>(
            find.ancestor(
              of: find.text('Bénédiction'),
              matching: find.byType(CheckableOptionTile),
            ),
          );
          final paladinTile = tester.widget<CheckableOptionTile>(
            find.ancestor(
              of: find.text('Protection contre le mal'),
              matching: find.byType(CheckableOptionTile),
            ),
          );
          expect(clercTile.enabled, isTrue);
          expect(paladinTile.enabled, isFalse);

          await tester.tap(find.text('Protection contre le mal'));
          await tester.pumpAndSettle();
          expect(toggled, isEmpty);

          await tester.tap(find.text('Bénédiction'));
          await tester.pumpAndSettle();
          expect(toggled, [clercSpell]);
        },
      );
    },
  );

  group(
    'limite mono-classe atteinte : les cases non cochées se désactivent',
    () {
      testWidgets('un sort non préparé devient non cochable une fois la limite '
          'atteinte, un sort déjà préparé reste toujours décochable', (
        tester,
      ) async {
        await pumpSheet(
          tester,
          spells: const [_prepared, _unprepared],
          // Limite déjà atteinte par `_prepared` seul (1 sort préparé déjà
          // compté par `_preparedCount`, voir sa doc).
          classLimits: [_classLimit('Clerc', 1)],
        );

        final preparedTile = tester.widget<CheckableOptionTile>(
          find.ancestor(
            of: find.text('Bénédiction'),
            matching: find.byType(CheckableOptionTile),
          ),
        );
        final unpreparedTile = tester.widget<CheckableOptionTile>(
          find.ancestor(
            of: find.text('Soins'),
            matching: find.byType(CheckableOptionTile),
          ),
        );
        expect(preparedTile.enabled, isTrue, reason: 'toujours décochable');
        expect(unpreparedTile.enabled, isFalse, reason: 'limite atteinte');

        await tester.tap(find.text('Soins'));
        await tester.pumpAndSettle();
        expect(toggled, isEmpty);

        // Dé-cocher le sort déjà préparé reste permis, aucune limite ne
        // s'applique à la baisse.
        await tester.tap(find.text('Bénédiction'));
        await tester.pumpAndSettle();
        expect(toggled, [_prepared]);
      });
    },
  );

  // La raison sous "Lancer" elle-même est testée dans
  // `spell_info_panel_test.dart` : ici, seulement la propagation de l'état
  // de préparation local de la sheet vers le panneau "Infos".
  group('panneau "Infos" ouvert depuis la sheet : raison sous "Lancer"', () {
    final unpreparedMessage = SpellCastBlockReason.unprepared.message;
    final noSlotMessage = SpellCastBlockReason.noSlotAvailable.message;
    const slots = [CharacterSpellSlot(level: 1, total: 2, used: 0)];

    bool castEnabled(WidgetTester tester) =>
        tester
            .widget<PrimaryButton>(find.widgetWithText(PrimaryButton, 'LANCER'))
            .onPressed !=
        null;

    Future<void> openInfo(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.info_outline_rounded));
      await tester.pumpAndSettle();
    }

    // Deux causes d'échec distinctes, signalées séparément : la préparation
    // locale non propagée (raison "non préparé") et, seul un emplacement de
    // pacte étant disponible, `pactSlot` non transmis au panneau (raison
    // "plus d'emplacement").
    testWidgets('sort coché dans la sheet puis ⓘ, seul un emplacement de pacte '
        'disponible : le panneau reflète la préparation en cours (plus de '
        'raison "non préparé", "Lancer" actif)', (tester) async {
      await pumpSheet(
        tester,
        spells: const [_unprepared],
        pactSlot: const CharacterSpellSlot(
          level: 1,
          total: 1,
          used: 0,
          isPact: true,
        ),
      );

      await tester.tap(find.text('Soins'));
      await tester.pumpAndSettle();
      await openInfo(tester);

      expect(
        find.text(unpreparedMessage),
        findsNothing,
        reason: 'préparation locale de la sheet non propagée au panneau ?',
      );
      expect(
        find.text(noSlotMessage),
        findsNothing,
        reason: 'pactSlot non transmis au panneau ?',
      );
      expect(
        castEnabled(tester),
        isTrue,
        reason:
            '"Lancer" désactivé sans raison affichée : préparation ou '
            'pactSlot non pris en compte par le bouton ?',
      );
      expect(find.text('Ne plus préparer'), findsOneWidget);
    });

    testWidgets('sort décoché dans la sheet puis ⓘ : la raison "non préparé" '
        'apparaît et "Lancer" est désactivé', (tester) async {
      await pumpSheet(tester, spells: const [_prepared], spellSlots: slots);

      await tester.tap(find.text('Bénédiction'));
      await tester.pumpAndSettle();
      await openInfo(tester);

      expect(find.text(unpreparedMessage), findsOneWidget);
      expect(castEnabled(tester), isFalse);
    });

    testWidgets('préparer depuis le panneau puis le rouvrir : la raison "non '
        'préparé" a disparu', (tester) async {
      await pumpSheet(tester, spells: const [_unprepared], spellSlots: slots);
      await openInfo(tester);
      expect(find.text(unpreparedMessage), findsOneWidget);

      await tester.tap(find.text('Préparer ce sort'));
      await tester.pumpAndSettle();
      await openInfo(tester);

      expect(find.text(unpreparedMessage), findsNothing);
      expect(castEnabled(tester), isTrue);
    });
  });

  // Barde + Clerc : la sheet de préparation ne concerne que les sorts qui se
  // préparent (`CharacterSpellEntry.requiresPreparation`).
  group('sorts qui ne se préparent pas (classe à sorts connus)', () {
    const bardKnown = CharacterSpellEntry(
      id: 10,
      name: 'Charme-personne',
      level: 1,
      school: 'Enchantement',
      status: SpellStatus.known,
      requiresPreparation: false,
    );
    const bardStoredPrepared = CharacterSpellEntry(
      id: 11,
      name: 'Héroïsme',
      level: 1,
      school: 'Enchantement',
      status: SpellStatus.prepared,
      requiresPreparation: false,
    );
    const all = [
      _cantrip,
      _prepared,
      _unprepared,
      _granted,
      bardKnown,
      bardStoredPrepared,
    ];

    testWidgets('ne sont pas listés ; les sorts à préparer et les sorts '
        'accordés le restent', (tester) async {
      await pumpSheet(tester, spells: all);

      expect(find.text('Charme-personne'), findsNothing);
      expect(find.text('Héroïsme'), findsNothing);
      expect(find.text('Bénédiction'), findsOneWidget);
      expect(find.text('Soins'), findsOneWidget);
      expect(find.text('Garde divine'), findsOneWidget);
      expect(find.byType(CheckableOptionTile), findsNWidgets(3));
    });

    testWidgets('ne sont pas comptés, même au statut "préparé" en base', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        spells: all,
        classLimits: [_classLimit('Clerc', 4)],
      );

      expect(find.text('1 / 4'), findsOneWidget);

      await tester.tap(find.text('Soins'));
      await tester.pumpAndSettle();

      expect(find.text('2 / 4'), findsOneWidget);
      expect(toggled.map((spell) => spell.name), ['Soins']);
    });

    testWidgets('introuvables par la recherche', (tester) async {
      await pumpSheet(tester, spells: all);

      await tester.enterText(find.byType(TextField), 'Charme');
      await tester.pumpAndSettle();

      expect(find.text('Charme-personne'), findsNothing);
      expect(find.text('Aucun sort pour « Charme ».'), findsOneWidget);
    });

    // D24 (`docs/dette-technique.md`) : l'état vide "Aucun sort..." est
    // maintenant rendu dans un `SingleChildScrollView`
    // (`_NoMatchState.build`) plutôt que directement `Center`, pour pouvoir
    // défiler au lieu de déborder avec un texte agrandi sur un petit écran.
    //
    // Échelle 2 (le plafond documenté `AppTypography.maxTextScaleFactor`,
    // voir `10-design-system.md` section 7), pas 3 : à 3,
    // `_SheetSpellLevelGroup` (l'en-tête "Niveau N" + pastilles
    // d'emplacements, ligne 488 de `prepare_spells_sheet.dart`) déborde déjà
    // à l'ouverture de la sheet — défaut préexistant, distinct de celui
    // corrigé ici (voir l'entrée ajoutée à `docs/dette-technique.md`), qui
    // ferait échouer ce test pour une raison étrangère à [_NoMatchState].
    testWidgets('introuvable par la recherche, texte agrandi à 200 % sur '
        'petit écran (320×568) : toujours affiché, aucun débordement', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await pumpSheet(tester, spells: all);

      await tester.enterText(find.byType(TextField), 'Charme');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Aucun sort pour « Charme ».'), findsOneWidget);
    });
    // La sheet entière est à hauteur fixe (`FractionallySizedBox
    // (heightFactor: 0.9)`, voir `showPrepareSpellsSheet`) : à 568 dp et
    // échelle 2, l'espace disponible pour [_NoMatchState] suffit déjà même
    // sans le correctif D24 (vérifié empiriquement en rejouant ce test
    // contre la version pré-correctif : aucun débordement). Le test
    // précédent ne discrimine donc pas vraiment le correctif pour ce
    // contenu-là. Un clavier ouvert (le champ de recherche a le focus,
    // comme ici) réduit en réalité la hauteur disponible de la sheet sur un
    // vrai appareil ; ce test le simule par un écran plus bas plutôt que par
    // `viewInsets.bottom` — rejoué contre la version pré-correctif, il
    // déborde bien de 66px, confirmant qu'il détecte la régression que
    // [_NoMatchState] a corrigée.
    testWidgets(
      'introuvable par la recherche, texte agrandi à 200 %, clavier ouvert '
      '(écran réduit à 320×400) : toujours affiché, aucun débordement',
      (tester) async {
        tester.view.physicalSize = const Size(320, 400);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearAllTestValues);

        await pumpSheet(tester, spells: all);

        await tester.enterText(find.byType(TextField), 'Charme');
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Aucun sort pour « Charme ».'), findsOneWidget);
      },
    );
  });

  // Caractérisation d'un défaut connu, antérieur au correctif D03 (rapport
  // QA) : la sheet ne distingue pas un sort inné d'un sort à préparer. À
  // inverser quand la sheet exclura les sorts 'inné'.
  group('sort inné de niveau >= 1 (défaut connu)', () {
    // Tel que la lecture le produit pour un Clerc : 'inné', origine inconnue,
    // donc `requiresPreparation` vrai (une classe du personnage prépare).
    const innate = CharacterSpellEntry(
      id: 20,
      name: 'Représailles infernales',
      level: 2,
      school: 'Évocation',
      status: SpellStatus.innate,
    );

    testWidgets('personnage qui prépare : non listé, donc ni case à cocher '
        'ni panneau "Infos" proposant "Préparer ce sort"', (tester) async {
      await pumpSheet(tester, spells: const [_prepared, innate]);

      expect(find.text('Représailles infernales'), findsNothing);
      expect(find.byType(CheckableOptionTile), findsOneWidget);
      expect(find.text('Préparer ce sort'), findsNothing);
      expect(toggled, isEmpty);
    });

    testWidgets('jamais compté dans "SORTS PRÉPARÉS X / Y"', (tester) async {
      await pumpSheet(
        tester,
        spells: const [_prepared, innate],
        classLimits: [_classLimit('Clerc', 4)],
      );

      expect(find.text('1 / 4'), findsOneWidget);
    });

    testWidgets('introuvable par la recherche', (tester) async {
      await pumpSheet(tester, spells: const [_prepared, innate]);

      await tester.enterText(find.byType(TextField), 'Représailles');
      await tester.pumpAndSettle();

      expect(find.text('Représailles infernales'), findsNothing);
    });

    testWidgets('personnage qui ne prépare pas (requiresPreparation faux) : '
        'non listé', (tester) async {
      const bardInnate = CharacterSpellEntry(
        id: 20,
        name: 'Représailles infernales',
        level: 2,
        school: 'Évocation',
        status: SpellStatus.innate,
        requiresPreparation: false,
      );
      await pumpSheet(tester, spells: const [_prepared, bardInnate]);

      expect(find.text('Représailles infernales'), findsNothing);
    });
  });

  // D43 du registre de dette technique (`docs/dette-technique.md`) : un sort
  // à la fois inné (trait racial) et connu/préparé (classe), listé ici
  // puisque sa route ordinaire se prépare. `hasInnateRoute` doit survivre à
  // la reconstruction de `_withCurrentStatus` (bascule de préparation) pour
  // que le panneau "Infos" rouvert depuis cette sheet garde son bouton
  // "Lancer (sort inné)".
  group('sort à double route (D43 : inné ET connu/préparé)', () {
    const dualRouteUnprepared = CharacterSpellEntry(
      id: 30,
      name: 'Protection contre le mal',
      level: 2,
      school: 'Abjuration',
      status: SpellStatus.known,
      hasInnateRoute: true,
      innateUsesSpent: 1,
    );

    testWidgets('listé (préparable via sa route ordinaire), le ⓘ ouvre un '
        'panneau avec le second bouton "Lancer (sort inné)"', (tester) async {
      await pumpSheet(tester, spells: const [dualRouteUnprepared]);

      expect(find.text('Protection contre le mal'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.info_outline_rounded));
      await tester.pumpAndSettle();

      expect(
        // `SecondaryButton` affiche son libellé en majuscules.
        find.widgetWithText(SecondaryButton, 'LANCER (SORT INNÉ)'),
        findsOneWidget,
      );
      // L'usage inné dépensé (1) est bien reporté lui aussi.
      expect(
        find.text(SpellCastBlockReason.innateUseSpent.message),
        findsOneWidget,
      );
    });

    testWidgets('après une bascule de préparation (reconstruction de '
        'status par _withCurrentStatus) : hasInnateRoute survit, le second '
        'bouton reste présent sur le panneau "Infos" rouvert', (tester) async {
      await pumpSheet(tester, spells: const [dualRouteUnprepared]);

      // Coche le sort (status local reconstruit à 'préparé', différent du
      // status original 'connu' transmis à pumpSheet).
      await tester.tap(find.text('Protection contre le mal'));
      await tester.pumpAndSettle();
      expect(toggled, [dualRouteUnprepared]);

      await tester.tap(find.byIcon(Icons.info_outline_rounded));
      await tester.pumpAndSettle();

      // Toujours présent : hasInnateRoute n'a pas été effacé par la
      // reconstruction (sans le correctif, le repli par défaut du
      // constructeur de `CharacterSpellEntry`, basé sur `status ==
      // SpellStatus.innate`, l'aurait mis à `false`).
      expect(
        find.widgetWithText(SecondaryButton, 'LANCER (SORT INNÉ)'),
        findsOneWidget,
      );
      expect(
        find.text(SpellCastBlockReason.innateUseSpent.message),
        findsOneWidget,
      );
    });
  });
}
