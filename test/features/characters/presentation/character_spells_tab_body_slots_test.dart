// Tests de widget de l'onglet "Sorts" (décisions du 09/11/2026, F15/P14 et
// P11) : carte "Emplacements de sorts" listant chaque niveau disponible,
// et état "sans sorts" d'un non-lanceur avec ses ressources.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/rules/spell_status.dart';
import 'package:personnages/features/characters/domain/character_class_feature.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/character_spell_slot.dart';
import 'package:personnages/features/characters/presentation/widgets/character_spells_section.dart';
import 'package:personnages/features/characters/presentation/widgets/character_spells_tab_body.dart';
import 'package:personnages/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

CharacterDetailClassRow _class(String name, int level) =>
    CharacterDetailClassRow(
      classId: 1,
      className: name,
      level: level,
      isPrimary: true,
      savingThrowProficiencies: const [],
      hitDie: 8,
    );

const _cantrip = CharacterSpellEntry(
  id: 1,
  name: 'Lumière',
  level: 0,
  school: 'Évocation',
  status: SpellStatus.known,
);
const _level1Spell = CharacterSpellEntry(
  id: 2,
  name: 'Bouclier',
  level: 1,
  school: 'Abjuration',
  status: SpellStatus.known,
);

CharacterDetail _detail({
  required List<CharacterDetailClassRow> classes,
  List<CharacterSpellEntry> spells = const [],
  List<CharacterSpellSlot> spellSlots = const [],
  CharacterSpellSlot? pactSpellSlot,
  List<CharacterClassFeature> classFeatures = const [],
}) => CharacterDetail(
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

Future<void> _pump(
  WidgetTester tester,
  CharacterDetail detail, {
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: CharacterSpellsTabBody(
            detail: detail,
            onCastSpell: (_, _) {},
            onTogglePrepared: (_) {},
            onUseFeature: (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('carte "Emplacements de sorts"', () {
    testWidgets('Magicien niveau 3 sans sort de niveau 2 : lignes niveaux 1 '
        'et 2 (pas de 3)', (tester) async {
      await _pump(
        tester,
        _detail(
          classes: [_class('Magicien', 3)],
          spells: const [_cantrip, _level1Spell],
          spellSlots: const [
            CharacterSpellSlot(level: 1, total: 4, used: 0),
            CharacterSpellSlot(level: 2, total: 2, used: 2),
          ],
        ),
      );

      expect(find.text('EMPLACEMENTS DE SORTS'), findsOneWidget);
      // « Niveau 1 » : ligne de la carte + titre du groupe du sort connu.
      expect(find.text('Niveau 1'), findsNWidgets(2));
      expect(find.text('Niveau 2'), findsOneWidget);
      expect(find.text('Niveau 3'), findsNothing);
      expect(find.byType(SpellSlotDots), findsNWidgets(2));
    });

    testWidgets('Magicien niveau 1 : un seul niveau', (tester) async {
      await _pump(
        tester,
        _detail(
          classes: [_class('Magicien', 1)],
          spells: const [_level1Spell],
          spellSlots: const [CharacterSpellSlot(level: 1, total: 2, used: 0)],
        ),
      );

      expect(find.text('Niveau 1'), findsNWidgets(2));
      expect(find.text('Niveau 2'), findsNothing);
      expect(find.byType(SpellSlotDots), findsOneWidget);
    });

    testWidgets('niveau sans emplacement (total 0) : pas de ligne', (
      tester,
    ) async {
      await _pump(
        tester,
        _detail(
          classes: [_class('Magicien', 1)],
          spells: const [_level1Spell],
          spellSlots: const [
            CharacterSpellSlot(level: 1, total: 2, used: 0),
            CharacterSpellSlot(level: 2, total: 0, used: 0),
          ],
        ),
      );

      expect(find.text('Niveau 2'), findsNothing);
    });

    testWidgets('multiclasse : la table combinée fournie est affichée telle '
        'quelle', (tester) async {
      await _pump(
        tester,
        _detail(
          classes: [_class('Magicien', 3), _class('Clerc', 2)],
          spells: const [_level1Spell],
          spellSlots: const [
            CharacterSpellSlot(level: 1, total: 4, used: 1),
            CharacterSpellSlot(level: 2, total: 3, used: 0),
            CharacterSpellSlot(level: 3, total: 2, used: 0),
          ],
        ),
      );

      expect(find.text('Niveau 1'), findsNWidgets(2));
      expect(find.text('Niveau 2'), findsOneWidget);
      expect(find.text('Niveau 3'), findsOneWidget);
      expect(find.byType(SpellSlotDots), findsNWidgets(3));
    });

    testWidgets('Occultiste : pacte séparé, pas de ligne de niveau classique '
        'pour le pacte', (tester) async {
      await _pump(
        tester,
        _detail(
          classes: [_class('Occultiste', 3)],
          spells: const [_level1Spell],
          pactSpellSlot: const CharacterSpellSlot(
            level: 2,
            total: 2,
            used: 0,
            isPact: true,
          ),
        ),
      );

      expect(find.text('EMPLACEMENTS DE SORTS'), findsNothing);
      expect(find.text('Magie de pacte — Niveau 2'), findsOneWidget);
      expect(find.byType(SpellSlotDots), findsOneWidget);
    });

    testWidgets('9 niveaux, 320 px et texte x2 : aucun débordement', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await _pump(
        tester,
        _detail(
          classes: [_class('Magicien', 20)],
          spells: const [_level1Spell],
          spellSlots: [
            for (var level = 1; level <= 9; level++)
              CharacterSpellSlot(
                level: level,
                total: level == 1 ? 4 : 3,
                used: 1,
              ),
          ],
        ),
        textScale: 2,
      );

      expect(find.byType(SpellSlotDots), findsNWidgets(9));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Magicien sans sort mais avec emplacements : état vide + '
        'carte', (tester) async {
      await _pump(
        tester,
        _detail(
          classes: [_class('Magicien', 1)],
          spellSlots: const [CharacterSpellSlot(level: 1, total: 2, used: 0)],
        ),
      );

      expect(find.text('AUCUN SORT'), findsOneWidget);
      expect(find.text('Niveau 1'), findsOneWidget);
    });
  });

  group('non-lanceur', () {
    const rage = CharacterClassFeature(
      id: 1,
      name: 'Rage',
      level: 1,
      usesMax: 2,
      usesRemaining: 2,
      restType: 'repos_long',
    );

    testWidgets('Barbare : message simple puis ressources', (tester) async {
      await _pump(
        tester,
        _detail(classes: [_class('Barbare', 1)], classFeatures: const [rage]),
      );

      const message = 'Ce personnage ne lance pas de sorts.';
      expect(find.text(message), findsOneWidget);
      expect(find.textContaining('archétype'), findsNothing);
      expect(find.text('RESSOURCES'), findsOneWidget);
      expect(find.text('Rage'), findsOneWidget);
      // Message court d'abord, puis la carte de ressources.
      expect(
        tester.getTopLeft(find.text(message)).dy,
        lessThan(tester.getTopLeft(find.text('RESSOURCES')).dy),
      );
      expect(find.text('AUCUN SORT'), findsNothing);
    });

    testWidgets('Barbare sans aptitude limitée : message seul', (tester) async {
      await _pump(tester, _detail(classes: [_class('Barbare', 1)]));

      expect(find.text('Ce personnage ne lance pas de sorts.'), findsOneWidget);
      expect(find.text('RESSOURCES'), findsNothing);
    });

    testWidgets('Guerrier niveau 3 Chevalier occulte (emplacements, aucun '
        'sort) : comportement de lanceur', (tester) async {
      await _pump(
        tester,
        _detail(
          classes: [_class('Guerrier', 3)],
          spellSlots: const [CharacterSpellSlot(level: 1, total: 2, used: 0)],
          classFeatures: const [rage],
        ),
      );

      expect(find.text('AUCUN SORT'), findsOneWidget);
      expect(find.text('Ce personnage ne lance pas de sorts.'), findsNothing);
      expect(find.text('Niveau 1'), findsOneWidget);
      expect(find.text('RESSOURCES'), findsNothing);
    });
  });

  group('compteur restants/total du titre de groupe', () {
    CharacterDetail detailWith(int used) => _detail(
      classes: [_class('Magicien', 3)],
      spells: const [_cantrip, _level1Spell],
      spellSlots: [
        CharacterSpellSlot(level: 1, total: 3, used: used),
        const CharacterSpellSlot(level: 2, total: 2, used: 0),
      ],
    );

    testWidgets('présent pour un niveau avec emplacements, sans pastilles '
        'en double', (tester) async {
      await _pump(tester, detailWith(1));

      expect(find.text('2/3'), findsOneWidget);
      // Les pastilles ne vivent que dans la carte : une par niveau.
      expect(find.byType(SpellSlotDots), findsNWidgets(2));
    });

    testWidgets("absent quand le niveau du groupe n'a pas d'emplacement", (
      tester,
    ) async {
      await _pump(
        tester,
        _detail(
          classes: [_class('Magicien', 1)],
          spells: const [_cantrip, _level1Spell],
          spellSlots: const [CharacterSpellSlot(level: 1, total: 0, used: 0)],
        ),
      );

      expect(find.textContaining(RegExp(r'\d/\d')), findsNothing);
    });

    testWidgets("mis à jour après consommation d'un emplacement", (
      tester,
    ) async {
      await _pump(tester, detailWith(1));
      expect(find.text('2/3'), findsOneWidget);

      await _pump(tester, detailWith(2));
      expect(find.text('1/3'), findsOneWidget);
      expect(find.text('2/3'), findsNothing);
    });

    testWidgets('surclassement : un sort de niveau 1 lancé avec un '
        'emplacement de niveau 3 ne décrémente que le niveau 3', (
      tester,
    ) async {
      // Le flux de lancer (feuille de choix d'emplacement puis écriture) est
      // porté par l'écran de fiche ; l'onglet ne fait qu'afficher
      // `detail.spellSlots`. On teste donc l'affichage avant/après la
      // consommation d'un emplacement de niveau 3 (`used` du niveau 3 passe
      // de 0 à 1, celui du niveau 1 reste à 0), ce que produit le lancer
      // d'un sort de niveau 1 avec cet emplacement.
      const level3Spell = CharacterSpellEntry(
        id: 3,
        name: 'Boule de feu',
        level: 3,
        school: 'Évocation',
        status: SpellStatus.known,
      );
      CharacterDetail detailWith(int level3Used) => _detail(
        classes: [_class('Magicien', 5)],
        spells: const [_level1Spell, level3Spell],
        spellSlots: [
          const CharacterSpellSlot(level: 1, total: 4, used: 0),
          CharacterSpellSlot(level: 3, total: 3, used: level3Used),
        ],
      );

      final handle = tester.ensureSemantics();
      String label(int level, int remaining, int total) =>
          'Niveau $level : $remaining sur $total emplacements disponibles';

      // Compteur texte du titre de groupe + annonce sémantique (ligne de la
      // carte et compteur du groupe : deux occurrences par niveau).
      await _pump(tester, detailWith(0));
      expect(find.text('4/4'), findsOneWidget);
      expect(find.text('3/3'), findsOneWidget);
      expect(find.bySemanticsLabel(label(3, 3, 3)), findsNWidgets(2));

      await _pump(tester, detailWith(1));
      expect(find.text('4/4'), findsOneWidget);
      expect(find.text('2/3'), findsOneWidget);
      expect(find.text('3/3'), findsNothing);
      expect(find.bySemanticsLabel(label(1, 4, 4)), findsNWidgets(2));
      expect(find.bySemanticsLabel(label(3, 2, 3)), findsNWidgets(2));
      handle.dispose();
    });

    testWidgets('sémantique : une annonce par ligne et pour le compteur', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, detailWith(1));

      // Carte (ligne niveau 1) + compteur du groupe niveau 1.
      expect(
        find.bySemanticsLabel('Niveau 1 : 2 sur 3 emplacements disponibles'),
        findsNWidgets(2),
      );
      expect(
        find.bySemanticsLabel('Niveau 2 : 2 sur 2 emplacements disponibles'),
        findsOneWidget,
      );
      // Pastilles exclues de l'arbre sémantique de la carte.
      expect(
        find.bySemanticsLabel('Emplacements de sorts : 2 restants sur 3'),
        findsNothing,
      );
      handle.dispose();
    });

    testWidgets('titre de carte long à 320 px et texte x2 : sans exception', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await _pump(tester, detailWith(1), textScale: 2);

      expect(find.text('EMPLACEMENTS DE SORTS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('Occultiste avec seulement des emplacements de pacte et aucun '
      'sort : lanceur, pas de message non-lanceur', (tester) async {
    await _pump(
      tester,
      _detail(
        classes: [_class('Occultiste', 3)],
        pactSpellSlot: const CharacterSpellSlot(
          level: 2,
          total: 2,
          used: 0,
          isPact: true,
        ),
      ),
    );

    expect(find.text('AUCUN SORT'), findsOneWidget);
    expect(find.text('Ce personnage ne lance pas de sorts.'), findsNothing);
  });
}
