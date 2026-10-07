// Tests de widget de la ligne d'un sort inné de niveau >= 1 dans l'onglet
// "Sorts" (`presentation/widgets/character_spells_section.dart`, D08) :
// pastille « INNÉ », marqueur d'usage (pastille pleine / « Épuisé »), mise en
// page sur deux lignes aux grandes polices, sémantique — spec validée par
// l'agent `direction-artistique`.
//
// Monté via `CharacterSpellsTabBody` (la ligne `_SpellRow` est privée), comme
// `character_spells_tab_body_test.dart`. App en portrait uniquement.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/theme/app_spacing.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/character_detail_class_row.dart';
import 'package:personnages/features/characters/domain/character_spell_entry.dart';
import 'package:personnages/features/characters/domain/character_spell_slot.dart';
import 'package:personnages/features/characters/presentation/widgets/character_spells_section.dart';
import 'package:personnages/features/characters/presentation/widgets/character_spells_tab_body.dart';
import 'package:personnages/features/characters/presentation/widgets/spell_action_sheet.dart';

const _availableLabel =
    'Sort inné, sans emplacement, 1 utilisation restante sur 1, repos long';
const _spentLabel = 'Sort inné, épuisé, disponible après un repos long';

const _clerc = CharacterDetailClassRow(
  classId: 5,
  className: 'Clerc',
  level: 3,
  isPrimary: true,
  savingThrowProficiencies: [],
  hitDie: 8,
);

const _innate = CharacterSpellEntry(
  id: 10,
  name: 'Ténèbres',
  level: 2,
  school: 'Évocation',
  status: 'inné',
);
const _innateSpent = CharacterSpellEntry(
  id: 10,
  name: 'Ténèbres',
  level: 2,
  school: 'Évocation',
  status: 'inné',
  innateUsesSpent: 1,
);
const _innateCantrip = CharacterSpellEntry(
  id: 11,
  name: 'Lumières dansantes',
  level: 0,
  school: 'Évocation',
  status: 'inné',
);
// Encadrent « Ténèbres » dans l'ordre alphabétique du niveau 2.
const _preparedBefore = CharacterSpellEntry(
  id: 12,
  name: 'Aide',
  level: 2,
  school: 'Abjuration',
  status: 'préparé',
);
const _preparedAfter = CharacterSpellEntry(
  id: 13,
  name: 'Zone de vérité',
  level: 2,
  school: 'Enchantement',
  status: 'préparé',
);
const _unprepared = CharacterSpellEntry(
  id: 14,
  name: 'Silence',
  level: 2,
  school: 'Illusion',
  status: 'connu',
);

CharacterDetail _detail(
  List<CharacterSpellEntry> spells, {
  List<CharacterSpellSlot> spellSlots = const [],
}) => CharacterDetail(
  id: '1',
  name: 'Test',
  classes: const [_clerc],
  xp: 0,
  currentHp: 10,
  maxHp: 10,
  temporaryHp: 0,
  abilityScores: const {},
  spells: spells,
  spellSlots: spellSlots,
);

Future<void> _pump(
  WidgetTester tester,
  CharacterDetail detail, {
  CastSpellCallback? onCastSpell,
  bool actionsDisabled = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CharacterSpellsTabBody(
          detail: detail,
          onCastSpell: onCastSpell ?? (_, _) {},
          onTogglePrepared: (_) {},
          actionsDisabled: actionsDisabled,
        ),
      ),
    ),
  );
}

void _useScreen(WidgetTester tester, Size size, double textScale) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
}

/// Pastilles pleines `goldEnd` (cercle), où qu'elles soient.
Finder _goldDots() => find.byWidgetPredicate((widget) {
  if (widget is! Container) return false;
  final decoration = widget.decoration;
  return decoration is BoxDecoration &&
      decoration.shape == BoxShape.circle &&
      decoration.color == AppColors.goldEnd;
});

/// Marqueur « disponible » d'un sort inné : les pastilles pleines `goldEnd`
/// hors pastilles d'emplacements du titre de groupe ([SpellSlotDots]).
Finder _usageDotsOutsideSlotDots(WidgetTester tester) {
  final insideSlotDots = find
      .descendant(of: find.byType(SpellSlotDots), matching: _goldDots())
      .evaluate()
      .toSet();
  return find.byElementPredicate(
    (element) =>
        _goldDots().evaluate().contains(element) &&
        !insideSlotDots.contains(element),
  );
}

void main() {
  group('ligne d\'un sort inné de niveau >= 1', () {
    testWidgets('disponible : pastille « INNÉ » aux tokens de la pastille '
        'd\'octroi, pastille pleine 8x8 goldEnd à 4 px, pas de « Épuisé »', (
      tester,
    ) async {
      await _pump(tester, _detail(const [_innate]));

      final badgeText = tester.widget<Text>(find.text('INNÉ'));
      expect(badgeText.style!.fontSize, 10);
      expect(badgeText.style!.color, AppColors.textSecondary);
      final badge = tester.widget<Container>(
        find
            .ancestor(of: find.text('INNÉ'), matching: find.byType(Container))
            .first,
      );
      final decoration = badge.decoration! as BoxDecoration;
      expect(decoration.color, AppColors.parchmentCardAlt);
      expect(decoration.borderRadius, BorderRadius.circular(AppRadius.sm));
      expect(
        decoration.border,
        Border.all(color: AppColors.woodLight, width: 1),
      );
      expect(
        badge.padding,
        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      );
      // Sans icône (contrairement à la pastille d'octroi et son cadenas).
      expect(find.byIcon(Icons.lock_outline), findsNothing);

      final dots = _usageDotsOutsideSlotDots(tester);
      expect(dots, findsOneWidget);
      expect(tester.getSize(dots), const Size(8, 8));
      final badgeRect = tester.getRect(
        find
            .ancestor(of: find.text('INNÉ'), matching: find.byType(Container))
            .first,
      );
      expect(tester.getRect(dots).left - badgeRect.right, AppSpacing.xs);
      // À droite, en face du nom.
      expect(
        badgeRect.left,
        greaterThan(tester.getRect(find.text('Ténèbres')).right),
      );
      expect(find.text('Épuisé'), findsNothing);
      // Aucun libellé de préparation pour un sort inné.
      expect(find.text('PRÉPARÉ'), findsNothing);
      expect(find.text('NON PRÉPARÉ'), findsNothing);
    });

    testWidgets('épuisé : « Épuisé » en accentBrick 11/600 à la place de la '
        'pastille, ligne non atténuée', (tester) async {
      await _pump(tester, _detail(const [_innateSpent]));

      expect(find.text('INNÉ'), findsOneWidget);
      expect(_usageDotsOutsideSlotDots(tester), findsNothing);
      final spent = tester.widget<Text>(find.text('Épuisé'));
      expect(spent.style!.fontSize, 11);
      expect(spent.style!.fontWeight, FontWeight.w600);
      expect(spent.style!.color, AppColors.accentBrick);
      final badgeRect = tester.getRect(
        find
            .ancestor(of: find.text('INNÉ'), matching: find.byType(Container))
            .first,
      );
      expect(
        tester.getRect(find.text('Épuisé')).left - badgeRect.right,
        AppSpacing.xs,
      );

      // L'opacité à 50 % reste réservée à « non préparé ».
      final opacity = tester.widget<Opacity>(
        find
            .ancestor(of: find.text('Ténèbres'), matching: find.byType(Opacity))
            .first,
      );
      expect(opacity.opacity, 1);
    });

    testWidgets('épuisé : garde sa place alphabétique dans son groupe, entre '
        'les sorts préparés (pas relégué avec les sorts non préparés)', (
      tester,
    ) async {
      await _pump(
        tester,
        _detail(const [
          _preparedAfter,
          _unprepared,
          _innateSpent,
          _preparedBefore,
        ]),
      );

      double topOf(String name) => tester.getRect(find.text(name)).top;
      expect(topOf('Aide'), lessThan(topOf('Ténèbres')));
      expect(topOf('Ténèbres'), lessThan(topOf('Zone de vérité')));
      expect(topOf('Zone de vérité'), lessThan(topOf('Silence')));
    });

    testWidgets('sort mineur inné : ni pastille « INNÉ », ni marqueur', (
      tester,
    ) async {
      await _pump(tester, _detail(const [_innateCantrip]));

      expect(find.text('Lumières dansantes'), findsOneWidget);
      expect(find.text('INNÉ'), findsNothing);
      expect(find.text('Épuisé'), findsNothing);
      expect(_usageDotsOutsideSlotDots(tester), findsNothing);
    });

    testWidgets('sort ordinaire : ni pastille « INNÉ », ni marqueur', (
      tester,
    ) async {
      await _pump(tester, _detail(const [_preparedBefore]));

      expect(find.text('INNÉ'), findsNothing);
      expect(_usageDotsOutsideSlotDots(tester), findsNothing);
    });

    testWidgets('les pastilles d\'emplacements du titre de groupe sont les '
        'mêmes que le sort inné soit disponible ou épuisé', (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      const slots = [CharacterSpellSlot(level: 2, total: 2, used: 1)];

      for (final spell in const [_innate, _innateSpent]) {
        await _pump(tester, _detail([spell], spellSlots: slots));
        expect(
          find.bySemanticsLabel('Emplacements de sorts : 1 restants sur 2'),
          findsOneWidget,
        );
      }

      semanticsHandle.dispose();
    });
  });

  group('sémantique', () {
    testWidgets('disponible : un seul nœud pour pastille + marqueur', (
      tester,
    ) async {
      final semanticsHandle = tester.ensureSemantics();
      await _pump(tester, _detail(const [_innate]));

      expect(find.bySemanticsLabel(RegExp(_availableLabel)), findsOneWidget);
      // Le texte « INNÉ » n'est pas annoncé en plus (excludeSemantics).
      expect(find.bySemanticsLabel(RegExp('INNÉ')), findsNothing);

      semanticsHandle.dispose();
    });

    testWidgets('épuisé : libellé dédié, « Épuisé » non annoncé en double', (
      tester,
    ) async {
      final semanticsHandle = tester.ensureSemantics();
      await _pump(tester, _detail(const [_innateSpent]));

      expect(find.bySemanticsLabel(RegExp(_spentLabel)), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(_availableLabel)), findsNothing);
      expect(find.bySemanticsLabel(RegExp('INNÉ')), findsNothing);
      expect(find.bySemanticsLabel(RegExp('^Épuisé')), findsNothing);

      semanticsHandle.dispose();
    });
  });

  group('filtre de préparation', () {
    for (final spell in const [_innate, _innateSpent]) {
      final state = spell.innateUsesSpent == 0 ? 'disponible' : 'épuisé';

      testWidgets('sort inné $state : présent dans « Tous » et « Préparés », '
          'absent de « Non préparés »', (tester) async {
        await _pump(tester, _detail([spell, _preparedBefore, _unprepared]));

        expect(find.text('Ténèbres'), findsOneWidget);

        await tester.tap(find.text('PRÉPARÉS'));
        await tester.pumpAndSettle();
        expect(find.text('Ténèbres'), findsOneWidget);
        expect(find.text('Silence'), findsNothing);

        await tester.tap(find.text('NON PRÉPARÉS'));
        await tester.pumpAndSettle();
        expect(find.text('Ténèbres'), findsNothing);
        expect(find.text('Silence'), findsOneWidget);
      });
    }
  });

  group('grandes polices', () {
    const longNamed = CharacterSpellEntry(
      id: 20,
      name: 'Protection contre le mal et le bien et toutes les autres choses',
      level: 2,
      school: 'Abjuration',
      status: 'inné',
      description: 'Inflige 8d6 dégâts de feu.',
    );
    const longNamedSpent = CharacterSpellEntry(
      id: 20,
      name: 'Protection contre le mal et le bien et toutes les autres choses',
      level: 2,
      school: 'Abjuration',
      status: 'inné',
      description: 'Inflige 8d6 dégâts de feu.',
      innateUsesSpent: 1,
    );

    Finder badgeOf() => find
        .ancestor(of: find.text('INNÉ'), matching: find.byType(Container))
        .first;

    testWidgets('échelle 1.0 : une seule ligne, pastille en face du nom', (
      tester,
    ) async {
      _useScreen(tester, const Size(320, 568), 1);
      await _pump(tester, _detail(const [_innate]));
      expect(tester.takeException(), isNull);

      final name = tester.getRect(find.text('Ténèbres'));
      final badge = tester.getRect(badgeOf());
      expect(badge.left, greaterThan(name.right));
      expect(badge.center.dy, closeTo(name.center.dy, 2));
      expect(tester.widget<Text>(find.text('Ténèbres')).maxLines, 1);
    });

    testWidgets('échelle 1.29 : encore une seule ligne (seuil à 1.3)', (
      tester,
    ) async {
      _useScreen(tester, const Size(320, 568), 1.29);
      await _pump(tester, _detail(const [_innate]));
      expect(tester.takeException(), isNull);

      expect(
        tester.getRect(badgeOf()).left,
        greaterThan(tester.getRect(find.text('Ténèbres')).right),
      );
    });

    // Pas d'échelle 3.0 ici : sur 320 px de large, le TITRE du groupe
    // (« Niveau 2 », hors périmètre) déborde déjà avec la police de test,
    // indépendamment de la ligne de sort — voir le test du plafond à 2.0
    // ci-dessous pour l'échelle 3.0.
    for (final textScale in [1.3, 2.0]) {
      for (final spell in const [longNamed, longNamedSpent]) {
        final state = spell.innateUsesSpent == 0 ? 'disponible' : 'épuisé';

        testWidgets('320x568, échelle $textScale, $state, nom très long avec '
            'dé : deux lignes sans débordement — nom sur 2 lignes max avec '
            'ellipse, pastille et marqueur dessous, alignés à gauche', (
          tester,
        ) async {
          _useScreen(tester, const Size(320, 568), textScale);
          await _pump(tester, _detail([spell]));
          expect(tester.takeException(), isNull);

          final nameText = tester.widget<Text>(find.text(spell.name));
          expect(nameText.maxLines, 2);
          expect(nameText.overflow, TextOverflow.ellipsis);

          final name = tester.getRect(find.text(spell.name));
          final badge = tester.getRect(badgeOf());
          expect(badge.left, name.left);
          expect(badge.top, greaterThanOrEqualTo(name.bottom));
          expect(badge.right, lessThanOrEqualTo(320));
          // Le dé reste sur la première ligne, avec le nom.
          final dice = tester.getRect(find.text('8d6'));
          expect(dice.bottom, lessThanOrEqualTo(badge.top));
          expect(dice.right, lessThanOrEqualTo(320));

          if (spell.innateUsesSpent > 0) {
            final spent = tester.getRect(find.text('Épuisé'));
            expect(spent.left - badge.right, AppSpacing.xs);
            expect(spent.right, lessThanOrEqualTo(320));
          } else {
            final dot = tester.getRect(_usageDotsOutsideSlotDots(tester));
            expect(dot.left - badge.right, AppSpacing.xs);
          }
        });
      }
    }

    testWidgets('deux lignes : la pastille est à AppSpacing.xs sous la ligne '
        'du nom', (tester) async {
      _useScreen(tester, const Size(320, 568), 1.3);
      await _pump(tester, _detail(const [_innate]));

      final name = tester.getRect(find.text('Ténèbres'));
      final badge = tester.getRect(badgeOf());
      expect(badge.top - name.bottom, AppSpacing.xs);
    });

    testWidgets('pastille et marqueur plafonnés à l\'échelle 2.0, le nom '
        'continue de suivre l\'échelle système', (tester) async {
      // Écran portrait large : à 390 px, le titre du groupe (hors
      // périmètre) déborde de 4 px à l'échelle 3.0 avec la police de test.
      _useScreen(tester, const Size(430, 932), 3);
      await _pump(tester, _detail(const [_innateSpent]));
      expect(tester.takeException(), isNull);

      double scaled(Finder finder, double fontSize) =>
          MediaQuery.textScalerOf(tester.element(finder)).scale(fontSize);
      expect(scaled(find.text('INNÉ'), 10), 20);
      expect(scaled(find.text('Épuisé'), 11), 22);
      expect(scaled(find.text('Ténèbres'), 13), 39);
    });

    testWidgets('un sort ordinaire reste sur une seule ligne à l\'échelle '
        '1.3 (mise en page propre aux sorts innés)', (tester) async {
      _useScreen(tester, const Size(320, 568), 1.3);
      await _pump(tester, _detail(const [_preparedBefore]));
      expect(tester.takeException(), isNull);

      expect(tester.widget<Text>(find.text('Aide')).maxLines, 1);
      expect(
        tester.getRect(find.text('PRÉPARÉ')).left,
        greaterThan(tester.getRect(find.text('Aide')).right),
      );
    });
  });

  group('lancer depuis la ligne', () {
    testWidgets('tap puis « Lancer » : aucun choix d\'emplacement malgré des '
        'emplacements éligibles, lancer sans emplacement', (tester) async {
      final casts = <(CharacterSpellEntry, CharacterSpellSlot?)>[];
      await _pump(
        tester,
        _detail(
          const [_innate],
          spellSlots: const [
            CharacterSpellSlot(level: 2, total: 2, used: 0),
            CharacterSpellSlot(level: 3, total: 1, used: 0),
          ],
        ),
        onCastSpell: (spell, slot) => casts.add((spell, slot)),
      );

      await tester.tap(find.text('Ténèbres'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PrimaryButton, 'LANCER'));
      await tester.pumpAndSettle();

      expect(
        find.text("Choisissez le niveau d'emplacement à utiliser."),
        findsNothing,
      );
      expect(casts, [(_innate, null)]);
    });

    testWidgets('lecture seule (vue partagée, actionsDisabled) : pastille et '
        'marqueur affichés, aucun tap', (tester) async {
      final casts = <CharacterSpellEntry>[];
      await _pump(
        tester,
        _detail(const [_innateSpent]),
        onCastSpell: (spell, slot) => casts.add(spell),
        actionsDisabled: true,
      );

      expect(find.text('INNÉ'), findsOneWidget);
      expect(find.text('Épuisé'), findsOneWidget);

      await tester.tap(find.text('Ténèbres'));
      await tester.pumpAndSettle();
      expect(find.text('TÉNÈBRES'), findsNothing);
      expect(casts, isEmpty);
    });
  });

  testWidgets('note d\'aide de la carte de préparation : entrée « Sans '
      'préparation » complétée pour les sorts innés', (tester) async {
    await _pump(tester, _detail(const [_innate, _unprepared]));

    await tester.tap(
      find.byTooltip('Comment fonctionne la préparation des sorts ?'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sans préparation'), findsOneWidget);
    expect(find.text('Toujours disponibles'), findsNothing);
    expect(
      find.textContaining(
        'Un sort inné de niveau 1 ou plus se lance sans emplacement, une '
        'fois par repos long.',
      ),
      findsOneWidget,
    );
  });
}
