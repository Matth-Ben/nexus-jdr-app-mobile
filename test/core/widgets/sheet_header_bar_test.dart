// Tests de widget de la barre de tête de bottom sheet
// (`core/widgets/sheet_header_bar.dart`) : hauteur minimale 56 px, barre qui
// grandit avec le titre, agrandissement du texte plafonné, bouton de
// fermeture ancré en haut.
//
// Police : `google_fonts` ne charge rien en test (voir
// `test/flutter_test_config.dart`), le titre est donc rendu avec la police de
// test de Flutter. Elle a la même chasse que Press Start 2P (1 em par
// caractère), et la hauteur de ligne ne dépend pas de la police : elle vient
// du style de texte par défaut de Material (1,43 × la taille : 1,43 × 11 =
// 15,73, arrondi au pixel par Flutter — 16 px par ligne à l'échelle 1, 31 px
// à l'échelle 2, soit 93 px pour 3 lignes). Les titres ci-dessous sont choisis
// pour un écran de 360 dp de large : 24 caractères par ligne à l'échelle 1,
// 12 à l'échelle 2.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/sheet_header_bar.dart';

/// Une ligne à l'échelle 1, une ligne aussi à l'échelle 2.
const _shortTitle = 'FILTRER';

/// Libellé réel de `device_permissions_sheet.dart` : 2 lignes à l'échelle 1
/// sur 360 dp, 3 lignes à l'échelle 2.
const _twoLineTitle = 'GESTION DES AUTORISATIONS APPAREIL';

/// Trois lignes à l'échelle 1 sur 360 dp (trois mots de 23 caractères).
const _threeLineTitle =
    'AAAAAAAAAAAAAAAAAAAAAAA BBBBBBBBBBBBBBBBBBBBBBB CCCCCCCCCCCCCCCCCCCCCCC';

/// Bien plus de trois lignes, à toutes les échelles.
const _veryLongTitle =
    'BOULE DE FEU À RETARDEMENT ET AUTRES SORTS TRÈS LONGS DU GRIMOIRE DE '
    'MAÎTRE ELMINSTER LE SAGE, ÉDITION REVUE ET AUGMENTÉE';

const _screenSize = Size(360, 640);

/// Marge verticale minimale du titre (`AppSpacing.xs`).
const _titleVerticalMargin = 4.0;

/// Position du bouton de fermeture dans la barre d'origine, à hauteur fixe de
/// 56 px (mesurée sur le composant avant modification, écran de 360 dp).
const _referenceCloseButtonRect = Rect.fromLTWH(306, 6, 44, 44);

Future<void> _pumpBar(
  WidgetTester tester, {
  required String title,
  double textScale = 1,
  bool closeEnabled = true,
}) async {
  tester.view.physicalSize = _screenSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Column(
          children: [
            SheetHeaderBar(
              key: ValueKey('$title@$textScale'),
              title: title,
              closeEnabled: closeEnabled,
            ),
          ],
        ),
      ),
    ),
  );
}

Rect _barRect(WidgetTester tester) =>
    tester.getRect(find.byType(SheetHeaderBar));

Rect _titleRect(WidgetTester tester, String title) =>
    tester.getRect(find.text(title));

Rect _closeButtonRect(WidgetTester tester) =>
    tester.getRect(find.byType(IconButton));

/// Nombre de lignes réellement mises en page pour le titre.
int _lineCount(WidgetTester tester, String title) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(title));
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: title.length),
  );
  return boxes.map((box) => box.top.round()).toSet().length;
}

void main() {
  group('non-régression à l\'échelle 1 (références mesurées sur la barre '
      'd\'origine à hauteur fixe)', () {
    testWidgets('titre court : barre de 56 px, titre et croix aux mêmes '
        'positions', (tester) async {
      await _pumpBar(tester, title: _shortTitle);

      expect(_lineCount(tester, _shortTitle), 1);
      expect(_barRect(tester), const Rect.fromLTWH(0, 0, 360, 56));
      expect(
        _titleRect(tester, _shortTitle),
        const Rect.fromLTRB(20, 20, 296, 36),
      );
      expect(_closeButtonRect(tester), _referenceCloseButtonRect);
    });

    testWidgets('libellé sur 2 lignes : barre de 56 px, titre et croix aux '
        'mêmes positions', (tester) async {
      await _pumpBar(tester, title: _twoLineTitle);

      expect(_lineCount(tester, _twoLineTitle), 2);
      expect(_barRect(tester), const Rect.fromLTWH(0, 0, 360, 56));
      expect(
        _titleRect(tester, _twoLineTitle),
        const Rect.fromLTRB(20, 12, 296, 44),
      );
      expect(_closeButtonRect(tester), _referenceCloseButtonRect);
    });

    testWidgets('titre sur 3 lignes : barre de 56 px, titre et croix aux '
        'mêmes positions', (tester) async {
      await _pumpBar(tester, title: _threeLineTitle);

      expect(_lineCount(tester, _threeLineTitle), 3);
      expect(_barRect(tester), const Rect.fromLTWH(0, 0, 360, 56));
      expect(
        _titleRect(tester, _threeLineTitle),
        const Rect.fromLTRB(20, 4, 296, 52),
      );
      expect(_closeButtonRect(tester), _referenceCloseButtonRect);
    });
  });

  group('croissance avec le titre', () {
    for (final (description, title, textScale) in [
      ('titre de 2 lignes à l\'échelle 2', 'CHOISIR UN SET', 2.0),
      ('libellé réel à l\'échelle 2', _twoLineTitle, 2.0),
      ('titre très long à l\'échelle 2', _veryLongTitle, 2.0),
    ]) {
      testWidgets('$description : la barre grandit, le titre y tient avec '
          'ses marges, la croix reste en haut', (tester) async {
        await _pumpBar(tester, title: title, textScale: textScale);

        final bar = _barRect(tester);
        final titleRect = _titleRect(tester, title);
        final topMargin = titleRect.top - bar.top;
        final bottomMargin = bar.bottom - titleRect.bottom;

        expect(bar.height, greaterThan(56));
        expect(topMargin, greaterThanOrEqualTo(_titleVerticalMargin));
        expect(bottomMargin, greaterThanOrEqualTo(_titleVerticalMargin));
        // Centré verticalement.
        expect(topMargin, moreOrLessEquals(bottomMargin, epsilon: 0.5));
        // La croix ne se recentre pas : même position que dans 56 px.
        expect(_closeButtonRect(tester), _referenceCloseButtonRect);
      });
    }

    testWidgets('titre court à l\'échelle 2 : il tient dans 56 px, la barre '
        'ne grandit pas', (tester) async {
      await _pumpBar(tester, title: _shortTitle, textScale: 2);

      final bar = _barRect(tester);
      final titleRect = _titleRect(tester, _shortTitle);

      expect(bar.height, 56);
      expect(
        titleRect.top - bar.top,
        moreOrLessEquals(bar.bottom - titleRect.bottom, epsilon: 0.5),
      );
      expect(_closeButtonRect(tester), _referenceCloseButtonRect);
    });
  });

  group('alignement horizontal du titre', () {
    for (final textScale in [1.0, 2.0]) {
      testWidgets('à l\'échelle $textScale : chaque ligne du titre commence au '
          'bord gauche de la zone de titre', (tester) async {
        await _pumpBar(tester, title: _twoLineTitle, textScale: textScale);

        final paragraph = tester.renderObject<RenderParagraph>(
          find.text(_twoLineTitle),
        );
        final boxes = paragraph.getBoxesForSelection(
          const TextSelection(
            baseOffset: 0,
            extentOffset: _twoLineTitle.length,
          ),
        );
        final lineStarts = <int, double>{};
        for (final box in boxes) {
          final line = box.top.round();
          final start = lineStarts[line];
          if (start == null || box.left < start) lineStarts[line] = box.left;
        }

        expect(lineStarts.length, greaterThan(1));
        // Moins de 1 px : la moitié de l'interlettrage (0,25 px) précède le
        // premier caractère d'une ligne alignée à gauche.
        expect(lineStarts.values, everyElement(lessThan(1)));
      });
    }
  });

  group('plafond d\'agrandissement du texte', () {
    for (final title in [_shortTitle, _twoLineTitle, _veryLongTitle]) {
      testWidgets('"${title.substring(0, 7)}…" : même hauteur et même titre '
          'aux échelles 2 et 3', (tester) async {
        await _pumpBar(tester, title: title, textScale: 2);
        final barAtTwo = _barRect(tester);
        final titleAtTwo = _titleRect(tester, title);

        await _pumpBar(tester, title: title, textScale: 3);

        expect(_barRect(tester), barAtTwo);
        expect(_titleRect(tester, title), titleAtTwo);
      });
    }

    testWidgets('en dessous du plafond, le texte suit l\'échelle demandée', (
      tester,
    ) async {
      await _pumpBar(tester, title: _shortTitle);
      final heightAtOne = _titleRect(tester, _shortTitle).height;

      await _pumpBar(tester, title: _shortTitle, textScale: 2);

      expect(_titleRect(tester, _shortTitle).height, greaterThan(heightAtOne));
    });
  });

  group('trois lignes maximum', () {
    for (final textScale in [1.0, 2.0]) {
      testWidgets('titre très long à l\'échelle $textScale : 3 lignes, '
          'ellipse, même hauteur qu\'un titre de 3 lignes', (tester) async {
        await _pumpBar(tester, title: _threeLineTitle, textScale: textScale);
        final threeLineBarHeight = _barRect(tester).height;

        await _pumpBar(tester, title: _veryLongTitle, textScale: textScale);

        expect(_lineCount(tester, _veryLongTitle), 3);
        expect(
          tester.widget<Text>(find.text(_veryLongTitle)).overflow,
          TextOverflow.ellipsis,
        );
        expect(_barRect(tester).height, threeLineBarHeight);
      });
    }

    testWidgets('un titre tronqué reste annoncé en entier par un lecteur '
        'd\'écran', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpBar(tester, title: _veryLongTitle, textScale: 2);

      expect(
        tester.getSemantics(find.text(_veryLongTitle)).label,
        _veryLongTitle,
      );
      handle.dispose();
    });
  });

  group('sous un parent qui borne la hauteur (hors `Column`)', () {
    // La barre garde sa hauteur de contenu au lieu de remplir la hauteur
    // offerte. Bornes lâches uniquement : une hauteur imposée (`SizedBox`
    // parent direct) s'applique à n'importe quel widget.
    Future<void> pumpBoundedBar(
      WidgetTester tester, {
      required String title,
      required double textScale,
      required Widget Function(Widget bar) wrap,
    }) async {
      tester.view.physicalSize = _screenSize;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: Scaffold(
            body: wrap(
              SheetHeaderBar(key: ValueKey('$title@$textScale'), title: title),
            ),
          ),
        ),
      );
    }

    for (final (parent, wrap) in <(String, Widget Function(Widget))>[
      ('directement en `body` de `Scaffold`', (bar) => bar),
      (
        'sous une hauteur maximale de 300',
        (bar) => ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: bar,
        ),
      ),
      (
        'alignée en haut d\'une `SizedBox` de 300 de haut',
        (bar) => SizedBox(
          height: 300,
          child: Align(alignment: Alignment.topCenter, child: bar),
        ),
      ),
    ]) {
      testWidgets('$parent : 56 px pour un titre court à l\'échelle 1', (
        tester,
      ) async {
        await pumpBoundedBar(
          tester,
          title: _shortTitle,
          textScale: 1,
          wrap: wrap,
        );

        expect(_barRect(tester), const Rect.fromLTWH(0, 0, 360, 56));
        expect(
          _titleRect(tester, _shortTitle),
          const Rect.fromLTRB(20, 20, 296, 36),
        );
        expect(_closeButtonRect(tester), _referenceCloseButtonRect);
      });

      testWidgets('$parent : même géométrie que dans une `Column` pour un '
          'titre de 3 lignes à l\'échelle 2', (tester) async {
        await _pumpBar(tester, title: _veryLongTitle, textScale: 2);
        final barInColumn = _barRect(tester);
        final titleInColumn = _titleRect(tester, _veryLongTitle);
        expect(_lineCount(tester, _veryLongTitle), 3);
        // 3 lignes de 31 px + 2 marges de 4 px.
        expect(barInColumn.height, 101);

        await pumpBoundedBar(
          tester,
          title: _veryLongTitle,
          textScale: 2,
          wrap: wrap,
        );

        expect(_barRect(tester), barInColumn);
        expect(_titleRect(tester, _veryLongTitle), titleInColumn);
        expect(_closeButtonRect(tester), _referenceCloseButtonRect);
      });
    }
  });

  group('bouton de fermeture', () {
    Future<void> pumpPushedBar(
      WidgetTester tester, {
      required bool closeEnabled,
      double textScale = 1,
    }) async {
      tester.view.physicalSize = _screenSize;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      body: Column(
                        children: [
                          SheetHeaderBar(
                            title: _veryLongTitle,
                            closeEnabled: closeEnabled,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
    }

    for (final textScale in [1.0, 2.0]) {
      testWidgets('à l\'échelle $textScale : zone de 44×44, un tap ferme', (
        tester,
      ) async {
        await pumpPushedBar(tester, closeEnabled: true, textScale: textScale);

        expect(_closeButtonRect(tester).size, const Size(44, 44));

        // Tap dans le coin bas-droit de la zone : toute la zone réagit, pas
        // seulement l'icône.
        await tester.tapAt(
          _closeButtonRect(tester).bottomRight - const Offset(1, 1),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SheetHeaderBar), findsNothing);
      });
    }

    testWidgets('closeEnabled: false : le bouton est désactivé, un tap ne '
        'ferme rien', (tester) async {
      await pumpPushedBar(tester, closeEnabled: false, textScale: 2);

      expect(
        tester.widget<IconButton>(find.byType(IconButton)).onPressed,
        isNull,
      );

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(find.byType(SheetHeaderBar), findsOneWidget);
      expect(_closeButtonRect(tester).size, const Size(44, 44));
    });
  });
}
