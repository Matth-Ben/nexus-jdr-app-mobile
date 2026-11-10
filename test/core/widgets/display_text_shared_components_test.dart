// Les composants partagés en police pixel (`AppTypography.display`) ne
// dépassent pas leur palier avec la taille de police du système (décision du
// 10/11/2026) : x1,3 pour title (titres), x1,5 pour control (boutons, onglets
// segmentés), inchangés à police normale. Les composants control grandissent
// en hauteur (aucun débordement, aucun mot coupé, cible tactile >= 44 dp à
// x1,5 et x2,0 sur 360 dp).

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/dashed_button.dart';
import 'package:personnages/core/widgets/destructive_button.dart';
import 'package:personnages/core/widgets/display_text.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/core/widgets/segmented_tab_bar.dart';
import 'package:personnages/core/widgets/segmented_toggle.dart';
import 'package:personnages/core/widgets/sheet_header_bar.dart';
import 'package:personnages/core/widgets/wood_back_header.dart';

import 'display_scale_helpers.dart';

void main() {
  // (composant, texte réellement affiché dans le `Text`).
  final cases = <String, (Widget, String, double)>{
    'PrimaryButton': (
      PrimaryButton(label: 'Valider', onPressed: () {}),
      'VALIDER',
      1.5,
    ),
    'SecondaryButton': (
      SecondaryButton(label: 'Annuler', onPressed: () {}),
      'ANNULER',
      1.5,
    ),
    'DestructiveButton (plein)': (
      DestructiveButton(label: 'Supprimer', filled: true, onPressed: () {}),
      'SUPPRIMER',
      1.5,
    ),
    'DashedButton': (
      DashedButton(icon: Icons.add, label: 'Ajouter', onPressed: () {}),
      'Ajouter',
      1.5,
    ),
    'SegmentedTabBar': (
      SegmentedTabBar<int>(
        options: const [
          SegmentedTabBarOption(value: 1, label: 'Un'),
          SegmentedTabBarOption(value: 2, label: 'Deux'),
        ],
        value: 1,
        onChanged: (_) {},
      ),
      'UN',
      1.5,
    ),
    'SegmentedToggle': (
      SegmentedToggle<int>(
        options: const [
          SegmentedToggleOption(value: 1, label: 'Un'),
          SegmentedToggleOption(value: 2, label: 'Deux'),
        ],
        value: 1,
        onChanged: (_) {},
      ),
      'UN',
      1.3,
    ),
    'SheetHeaderBar': (const SheetHeaderBar(title: 'Titre'), 'Titre', 1.3),
    'WoodBackHeader': (
      WoodBackHeader(title: 'Fiche', onBack: () {}),
      'Fiche',
      1.3,
    ),
  };

  for (final entry in cases.entries) {
    final (widget, label, factor) = entry.value;
    testWidgets('${entry.key} : x1,0 inchangé, x2,0 plafonné à x$factor', (
      tester,
    ) async {
      await pumpScaled(tester, widget, scale: 1);
      expect(find.text(label), findsOneWidget);
      expect(effectiveFontSize(tester, label, 11), closeTo(11, 0.01));

      await pumpScaled(tester, widget, scale: 2);
      expect(effectiveFontSize(tester, label, 11), closeTo(11 * factor, 0.01));
    });
  }

  testWidgets('DestructiveButton (contour, body) continue de grandir', (
    tester,
  ) async {
    await pumpScaled(
      tester,
      DestructiveButton(label: 'Supprimer', onPressed: () {}),
      scale: 2,
    );
    expect(effectiveFontSize(tester, 'Supprimer', 14), closeTo(28, 0.01));
  });

  // Palier control : aucune erreur de mise en page ni mot coupé, et zone de tap
  // >= 44 dp, à x1,5 et x2,0 sur 360 dp, libellé long forçant 2 lignes.
  const surface = Size(360, 800);
  final controlWidgets = <String, (Widget Function(), double)>{
    'PrimaryButton': (
      () => PrimaryButton(label: 'Ajouter au butin', onPressed: () {}),
      160,
    ),
    'SecondaryButton': (
      () => SecondaryButton(label: 'Ajouter au butin', onPressed: () {}),
      160,
    ),
    'DestructiveButton (plein)': (
      () => DestructiveButton(
        label: 'Ajouter au butin',
        filled: true,
        onPressed: () {},
      ),
      160,
    ),
    'DashedButton': (
      () => DashedButton(
        icon: Icons.add,
        label: 'Ajouter au butin',
        onPressed: () {},
      ),
      180,
    ),
    'SegmentedTabBar': (
      () => SegmentedTabBar<int>(
        options: const [
          SegmentedTabBarOption(value: 1, label: 'Membres actifs'),
          SegmentedTabBarOption(value: 2, label: 'Butin commun'),
        ],
        value: 1,
        onChanged: (_) {},
      ),
      328,
    ),
  };

  for (final entry in controlWidgets.entries) {
    for (final scale in [1.5, 2.0]) {
      testWidgets('${entry.key} : x$scale sur 360 dp, hauteur élastique, '
          'aucun débordement ni mot coupé, tap >= 44', (tester) async {
        final (build, width) = entry.value;
        await pumpScaled(
          tester,
          _inColumn(width, build()),
          scale: scale,
          surface: surface,
        );
        expect(tester.takeException(), isNull);
        final texts = find.descendant(
          of: find.byType(DisplayText),
          matching: find.byType(RichText),
        );
        for (final element in texts.evaluate()) {
          final paragraph = element.renderObject! as RenderParagraph;
          expect(paragraph.textScaler.scale(11), closeTo(16.5, 0.01));
          expect(paragraph.didExceedMaxLines, isFalse);
          final plain = paragraph.text.toPlainText();
          for (final word in plain.split(' ')) {
            final painter = TextPainter(
              text: TextSpan(text: word, style: paragraph.text.style),
              textDirection: TextDirection.ltr,
              textScaler: paragraph.textScaler,
            )..layout();
            expect(
              painter.width,
              lessThanOrEqualTo(paragraph.size.width + 0.5),
              reason: 'mot "$word" coupé',
            );
          }
        }
        final size = tester.getSize(find.byType(InkWell).first);
        expect(size.height, greaterThanOrEqualTo(44));
        expect(size.width, greaterThanOrEqualTo(44));
      });
    }
  }

  testWidgets('PrimaryButton à x1,5 : plus haut qu à x1,0 (élastique)', (
    tester,
  ) async {
    Widget button() => _inColumn(
      160,
      PrimaryButton(label: 'Ajouter au butin', onPressed: () {}),
    );
    await pumpScaled(tester, button(), scale: 1, surface: surface);
    final h1 = tester.getSize(find.byType(PrimaryButton)).height;
    await pumpScaled(tester, button(), scale: 1.5, surface: surface);
    final h15 = tester.getSize(find.byType(PrimaryButton)).height;
    expect(h1, 48);
    expect(h15, greaterThan(48));
  });
  // N1 : deux boutons demi-largeur (160 dp, paire `Expanded`) avec un mot long
  // de 11 lettres : à x1,5 il ne tient pas à pleine échelle (11 x 16,5 dp >
  // 144 dp utiles) ; le mot reste entier (échelle réduite, jamais sous x1,0
  // donc jamais sous 11 px), et le rendu à x1,0 est inchangé.
  final halfWidthButtons = <String, Widget Function(String)>{
    'PrimaryButton': (l) => PrimaryButton(label: l, onPressed: () {}),
    'SecondaryButton': (l) => SecondaryButton(label: l, onPressed: () {}),
    'DestructiveButton (plein)': (l) =>
        DestructiveButton(label: l, filled: true, onPressed: () {}),
    'DashedButton': (l) =>
        DashedButton(icon: Icons.add, label: l, onPressed: () {}),
  };
  for (final entry in halfWidthButtons.entries) {
    for (final word in ['Enregistrer', 'Personnages']) {
      testWidgets('${entry.key} demi-largeur, "$word" : mot entier à x1,5 et '
          'x2,0, taille >= 11, inchangé à x1,0', (tester) async {
        Widget pair() => SizedBox(
          width: 360,
          child: Row(
            children: [
              Expanded(child: entry.value(word)),
              const SizedBox(width: 8),
              Expanded(child: entry.value(word)),
            ],
          ),
        );
        double fontOf() {
          final p = tester.renderObject<RenderParagraph>(
            find.descendant(
              of: find.byType(DisplayText).first,
              matching: find.byType(RichText),
            ),
          );
          return p.textScaler.scale(11);
        }

        await pumpScaled(
          tester,
          _inColumn(360, pair()),
          scale: 1,
          surface: surface,
        );
        expect(fontOf(), closeTo(11, 0.01));
        for (final scale in [1.5, 2.0]) {
          await pumpScaled(
            tester,
            _inColumn(360, pair()),
            scale: scale,
            surface: surface,
          );
          expect(tester.takeException(), isNull);
          for (final element
              in find
                  .descendant(
                    of: find.byType(DisplayText),
                    matching: find.byType(RichText),
                  )
                  .evaluate()) {
            final paragraph = element.renderObject! as RenderParagraph;
            final plain = paragraph.text.toPlainText();
            final painter = TextPainter(
              text: TextSpan(text: plain, style: paragraph.text.style),
              textDirection: TextDirection.ltr,
              textScaler: paragraph.textScaler,
            )..layout();
            expect(
              painter.width,
              lessThanOrEqualTo(paragraph.size.width + 0.5),
              reason: '"$plain" coupé à x$scale',
            );
            expect(paragraph.textScaler.scale(11), greaterThanOrEqualTo(11));
          }
        }
      });
    }
  }
}

/// Hauteur non bornée, comme dans un `Column`/`ListView` réel : sans elle, le
/// `Center` interne des boutons occuperait tout l'écran.
Widget _inColumn(double width, Widget child) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [SizedBox(width: width, child: child)],
);
