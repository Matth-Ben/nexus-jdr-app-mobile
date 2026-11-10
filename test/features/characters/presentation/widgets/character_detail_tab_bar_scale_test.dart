// Onglets du pied de fiche (décision du 10/11/2026) : à partir de 340 dp de
// largeur, police pixel au palier title (x1,3) ; en dessous, police de corps
// compacte (règle DA R1 : jamais de display sous 11 px). Aucun mot changé,
// aucun débordement.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/presentation/widgets/character_detail_tab_bar.dart';
import 'package:personnages/l10n/app_localizations.dart';

Future<void> _pump(
  WidgetTester tester, {
  required String locale,
  required double width,
  required double scale,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale(locale),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        bottomNavigationBar: CharacterDetailTabBar(
          current: CharacterDetailTab.character,
          onSelect: (_) {},
        ),
      ),
    ),
  );
}

void main() {
  test('le seuil de bascule est 340 dp', () {
    expect(CharacterDetailTabBar.compactWidth, 340);
  });

  for (final locale in ['fr', 'en']) {
    for (final width in [320.0, 339.0, 340.0, 360.0]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        final font = width < 340 ? 'de corps' : 'pixel';
        testWidgets('$locale, ${width}dp, x$scale : police $font, aucun '
            'débordement, mots entiers', (tester) async {
          await _pump(tester, locale: locale, width: width, scale: scale);
          expect(tester.takeException(), isNull);
          final l10n = AppLocalizations.of(
            tester.element(find.byType(CharacterDetailTabBar)),
          )!;
          final cell = width / 5;
          for (final tab in CharacterDetailTab.values) {
            final label = tab.label(l10n);
            final paragraph = tester.renderObject<RenderParagraph>(
              find.descendant(
                of: find.text(label),
                matching: find.byType(RichText),
              ),
            );
            final style = paragraph.text.style!;
            // Taille de base lue dans le style, jamais un 11 en dur.
            final base = style.fontSize!;
            final isPixel = style.fontFamily!.contains('PressStart2P');
            expect(isPixel, width >= 340, reason: '$label à ${width}dp');
            if (isPixel) {
              // Palier title : plafond x1,3.
              expect(
                paragraph.textScaler.scale(base),
                closeTo(base * (scale < 1.3 ? scale : 1.3), 0.01),
              );
            }
            final painter = TextPainter(
              text: TextSpan(text: label, style: style),
              textDirection: TextDirection.ltr,
              textScaler: paragraph.textScaler,
            )..layout();
            final fitted = find
                .ancestor(
                  of: find.text(label),
                  matching: find.byType(FittedBox),
                )
                .first;
            final rendered = tester.getSize(fitted).width;
            expect(rendered, lessThanOrEqualTo(cell), reason: '$label coupé');
            if (isPixel && width >= 360) {
              final effective =
                  paragraph.textScaler.scale(base) * rendered / painter.width;
              expect(
                effective,
                greaterThanOrEqualTo(11 - 0.01),
                reason: '$label sous 11 px',
              );
              expect(base, 11);
            }
          }
          // Hauteur constante, zone de tap complète.
          expect(tester.getSize(find.byType(CharacterDetailTabBar)).height, 62);
        });
      }
    }
  }
}
