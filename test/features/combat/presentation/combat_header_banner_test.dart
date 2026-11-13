// En-tête de l'écran Combat et bandeau « Combat en cours » : contenu et
// recettage mesurable à 320 dp (`docs/combat-groupe-ui.md` §6).

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/combat/presentation/widgets/combat_banner.dart';
import 'package:personnages/features/combat/presentation/widgets/combat_header.dart';
import 'package:personnages/l10n/app_localizations.dart';

import 'combat_test_harness.dart';

const _longName = 'Capitaine Gobelin des Montagnes Brumeuses';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double scale = 1,
  Size size = const Size(320, 700),
  Locale locale = const Locale('fr'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: c!,
      ),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

CombatHeader _header({
  String? turn = 'Gobelin 1',
  bool kebab = true,
  bool reorder = false,
  bool jump = false,
}) => CombatHeader(
  round: 3,
  turnName: turn,
  initiativeEntered: 2,
  initiativeTotal: 4,
  showKebab: kebab,
  onKebab: () {},
  reorderMode: reorder,
  onReorderDone: () {},
  showJumpToTurn: jump,
  onJumpToTurn: () {},
);

void main() {
  setUpAll(loadCombatFonts);

  group('en-tête', () {
    testWidgets('round, tour, kebab MJ', (tester) async {
      await _pump(tester, _header());
      expect(find.text('Round 3'), findsOneWidget);
      expect(find.text('Tour de Gobelin 1'), findsOneWidget);
      expect(find.byKey(const Key('combatHeaderMenu')), findsOneWidget);
    });

    testWidgets('sans tour actif : progression des initiatives', (
      tester,
    ) async {
      await _pump(tester, _header(turn: null, kebab: false));
      expect(find.text('Aucun tour actif · initiatives 2/4'), findsOneWidget);
      expect(find.byKey(const Key('combatHeaderMenu')), findsNothing);
    });

    testWidgets('mode Réordonner : « Terminé » remplace le kebab', (
      tester,
    ) async {
      await _pump(tester, _header(reorder: true));
      expect(find.text('Terminé'), findsOneWidget);
      expect(find.byKey(const Key('combatHeaderMenu')), findsNothing);
    });

    testWidgets('« Voir le tour en cours » : 44 de haut minimum', (
      tester,
    ) async {
      await _pump(tester, _header(jump: true));
      final size = tester.getSize(find.text('Voir le tour en cours'));
      expect(size.height, greaterThan(0));
      final tap = tester.getSize(
        find.ancestor(
          of: find.text('Voir le tour en cours'),
          matching: find.byType(InkWell),
        ),
      );
      expect(tap.height, greaterThanOrEqualTo(44));
    });

    testWidgets('« Round N » est un titre sémantique', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, _header());
      expect(
        tester.getSemantics(find.text('Round 3')),
        matchesSemantics(label: 'Round 3', isHeader: true),
      );
      handle.dispose();
    });

    for (final scale in [1.0, 2.0, 3.0]) {
      testWidgets('×$scale : hauteur, kebab 44, aucun débordement', (
        tester,
      ) async {
        await _pump(
          tester,
          _header(turn: _longName, jump: scale > 1),
          scale: scale,
        );
        expect(tester.takeException(), isNull);
        final height = tester
            .getSize(find.byKey(const Key('combatHeader')))
            .height;
        if (scale == 1.0) {
          expect(height, inInclusiveRange(72, 140));
        } else {
          // 40 % du viewport (700) au plus, quel que soit le texte.
          expect(height, lessThanOrEqualTo(700 * 0.4));
        }
        final kebab = tester.getSize(find.byKey(const Key('combatHeaderMenu')));
        expect(kebab.width, greaterThanOrEqualTo(44));
        expect(kebab.height, greaterThanOrEqualTo(44));
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text('Tour de $_longName'),
        );
        expect(paragraph.didExceedMaxLines, isFalse);
      });

      testWidgets('×$scale : en-tête simple dans la fourchette de la spec', (
        tester,
      ) async {
        await _pump(tester, _header(kebab: true), scale: scale);
        final height = tester
            .getSize(find.byKey(const Key('combatHeader')))
            .height;
        if (scale == 1.0) {
          expect(height, inInclusiveRange(72, 96));
        } else {
          expect(height, lessThanOrEqualTo(700 * 0.4));
        }
      });
    }

    testWidgets('plafonné à 40 % d\'un petit viewport', (tester) async {
      await _pump(
        tester,
        _header(turn: _longName, jump: true),
        scale: 3,
        size: const Size(320, 480),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byKey(const Key('combatHeader'))).height,
        lessThanOrEqualTo(480 * 0.4),
      );
    });
  });

  group('bandeau', () {
    var taps = 0;
    Widget banner({
      String? turn = 'Gobelin 1',
      DateTime? offline,
      bool absent = false,
    }) => CombatBannerView(
      round: 3,
      turnName: turn,
      offlineSince: offline,
      masterAbsent: absent,
      onTap: () => taps++,
    );

    setUp(() => taps = 0);

    testWidgets('titre, tour, appui', (tester) async {
      await _pump(tester, banner());
      expect(find.text('Combat en cours · round 3'), findsOneWidget);
      expect(find.text('Tour de Gobelin 1 · Ouvrir le combat'), findsOneWidget);
      await tester.tap(find.byKey(const Key('combatBanner')));
      expect(taps, 1);
    });

    testWidgets('sans tour actif', (tester) async {
      await _pump(tester, banner(turn: null));
      expect(find.text('Aucun tour actif · Ouvrir le combat'), findsOneWidget);
    });

    testWidgets('MJ absent : « En attente du MJ »', (tester) async {
      await _pump(tester, banner(absent: true));
      expect(find.text('En attente du MJ'), findsOneWidget);
    });

    testWidgets('hors ligne : heure du dernier état, un seul « Hors ligne »', (
      tester,
    ) async {
      await _pump(tester, banner(offline: DateTime(2026, 11, 14, 9, 5)));
      expect(find.text('Hors ligne · état de 09:05'), findsOneWidget);
      expect(find.textContaining('Hors ligne'), findsOneWidget);
    });

    testWidgets('anglais', (tester) async {
      await _pump(tester, banner(), locale: const Locale('en'));
      expect(find.text('Combat in progress · round 3'), findsOneWidget);
      expect(find.text('Gobelin 1\'s turn · Open combat'), findsOneWidget);
    });

    testWidgets('sémantique : un bouton fusionné', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, banner());
      expect(
        find.bySemanticsLabel(RegExp('Combat en cours · round 3')),
        findsOneWidget,
      );
      final node = tester.getSemantics(find.byKey(const Key('combatBanner')));
      expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
      handle.dispose();
    });

    for (final scale in [1.0, 2.0, 3.0]) {
      testWidgets('×$scale : hauteur, cible, aucun débordement', (
        tester,
      ) async {
        await _pump(tester, banner(), scale: scale);
        expect(tester.takeException(), isNull);
        final size = tester.getSize(find.byKey(const Key('combatBanner')));
        if (scale == 1.0) {
          expect(size.height, inInclusiveRange(64, 76));
        } else {
          expect(size.height, lessThanOrEqualTo(150));
        }
        expect(size.height, greaterThanOrEqualTo(44));
        expect(size.width, greaterThanOrEqualTo(44));
      });

      testWidgets('×$scale : nom de participant complet, sans ellipse', (
        tester,
      ) async {
        await _pump(tester, banner(turn: _longName), scale: scale);
        expect(tester.takeException(), isNull);
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text('Tour de $_longName · Ouvrir le combat'),
        );
        expect(paragraph.didExceedMaxLines, isFalse);
      });
    }
  });
}
