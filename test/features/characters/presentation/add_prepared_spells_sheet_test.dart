// Tests de widget de la sheet "Ajouter un sort"
// (`presentation/widgets/add_prepared_spells_sheet.dart`) — ouverte depuis le
// bouton "Ajouter un sort" de l'onglet "Sorts" pour les lanceurs à
// préparation « liste complète » (Clerc/Druide/Paladin, voir
// `character_spells_tab_body_test.dart`). Même patron que
// `spell_info_panel_test.dart` : la sheet est ouverte depuis un `Builder`
// minimal, les callbacks sont de simples enregistreurs d'appels synchrones.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/checkable_option_tile.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/character_spell_slot.dart';
import 'package:personnages/features/characters/domain/spell_grant_source.dart';
import 'package:personnages/features/characters/presentation/widgets/add_prepared_spells_sheet.dart';

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
  }) async {
    toggled = [];
    cast = [];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showAddPreparedSpellsSheet(
                  context,
                  spells: spells,
                  spellSlots: spellSlots,
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

      expect(find.text('AJOUTER UN SORT'), findsOneWidget);
      expect(find.text('Bénédiction'), findsOneWidget);
      expect(find.text('Soins'), findsOneWidget);
      expect(find.text('Garde divine'), findsOneWidget);
      // Sort mineur exclu de cette sheet (toujours visible ailleurs, aucune
      // notion de préparation à cocher).
      expect(find.text('Lumière'), findsNothing);
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
      expect(find.text('AJOUTER UN SORT'), findsOneWidget);
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

  testWidgets(
    'basculer la préparation depuis le panneau "Infos" reste synchronisé '
    'avec la case de la sheet "Ajouter" derrière',
    (tester) async {
      await pumpSheet(tester, spells: const [_unprepared]);

      await tester.tap(find.byIcon(Icons.info_outline_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Préparer ce sort'));
      await tester.pumpAndSettle();

      expect(toggled, [_unprepared]);
      // Retour sur la sheet "Ajouter", la case est maintenant cochée.
      final tile = tester.widget<CheckableOptionTile>(
        find.byType(CheckableOptionTile),
      );
      expect(tile.checked, isTrue);
    },
  );
}
