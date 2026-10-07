// Tests de widget de la sheet "Préparer mes sorts"
// (`presentation/widgets/prepare_spells_sheet.dart`) — proposée à la fin
// d'un repos long quand le joueur choisit de changer ses sorts préparés
// (voir `rest_sheet_test.dart`, `character_detail_screen_test.dart`). Même
// patron que `spell_info_panel_test.dart` : la sheet est ouverte depuis un
// `Builder` minimal, les callbacks sont de simples enregistreurs d'appels
// synchrones.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/checkable_option_tile.dart';
import 'package:personnages/core/widgets/dice_type_badge.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/character_spell_slot.dart';
import 'package:personnages/features/characters/domain/spell_cast_block_reason.dart';
import 'package:personnages/features/characters/domain/spell_grant_source.dart';
import 'package:personnages/features/characters/presentation/widgets/prepare_spells_sheet.dart';

const _cantrip = CharacterSpellEntry(
  id: 1,
  name: 'Lumière',
  level: 0,
  school: 'Évocation',
  status: 'connu',
);
const _prepared = CharacterSpellEntry(
  id: 2,
  name: 'Bénédiction',
  level: 1,
  school: 'Enchantement',
  status: 'préparé',
);
const _unprepared = CharacterSpellEntry(
  id: 3,
  name: 'Soins',
  level: 1,
  school: 'Évocation',
  status: 'connu',
  description: 'Vous infligez 1d8 dégâts de force à la cible.',
);
const _granted = CharacterSpellEntry(
  id: 4,
  name: 'Garde divine',
  level: 1,
  school: 'Abjuration',
  status: 'préparé',
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
    int? preparedLimit,
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
                  preparedLimit: preparedLimit,
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
      expect(toggled[0].status, 'connu');
      // 2e appel : avant dé-préparation, status doit refléter 'préparé' (pas
      // à nouveau 'connu') -> l'appelant dérive prepared: false. Sans le
      // correctif, les deux appels auraient porté 'connu'.
      expect(toggled[1].status, 'préparé');
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
        preparedLimit: 2,
      );

      expect(find.text('SORTS PRÉPARÉS'), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);

      await tester.tap(find.text('Soins'));
      await tester.pumpAndSettle();

      expect(find.text('2 / 2'), findsOneWidget);
      expect(find.text('Limite atteinte'), findsOneWidget);
    },
  );

  testWidgets('sans limite (preparedLimit null) : aucun compteur', (
    tester,
  ) async {
    await pumpSheet(tester, spells: const [_prepared, _unprepared]);

    expect(find.text('SORTS PRÉPARÉS'), findsNothing);
  });

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
      status: 'connu',
      requiresPreparation: false,
    );
    const bardStoredPrepared = CharacterSpellEntry(
      id: 11,
      name: 'Héroïsme',
      level: 1,
      school: 'Enchantement',
      status: 'préparé',
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
      await pumpSheet(tester, spells: all, preparedLimit: 4);

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
      status: 'inné',
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
        preparedLimit: 4,
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
        status: 'inné',
        requiresPreparation: false,
      );
      await pumpSheet(tester, spells: const [_prepared, bardInnate]);

      expect(find.text('Représailles infernales'), findsNothing);
    });
  });
}
