// Onglets du pied de fiche : palier title (x1,3), conteneur fixe de 62 dp à
// 5 colonnes ne pouvant pas absorber x1,5 (voir le commentaire du composant).
// Aucun débordement Flutter à x1,5 et x2,0 sur 360 dp.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/presentation/widgets/character_detail_tab_bar.dart';
import 'package:personnages/l10n/app_localizations.dart';

void main() {
  for (final locale in ['fr', 'en']) {
    for (final scale in [1.5, 2.0]) {
      testWidgets('$locale, x$scale sur 360 dp : aucun débordement, libellés '
          'plafonnés à x1,3, mots entiers', (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
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
        expect(tester.takeException(), isNull);
        final l10n = AppLocalizations.of(
          tester.element(find.byType(CharacterDetailTabBar)),
        )!;
        for (final tab in CharacterDetailTab.values) {
          final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(
              of: find.text(tab.label(l10n)),
              matching: find.byType(RichText),
            ),
          );
          expect(paragraph.textScaler.scale(11), closeTo(11 * 1.3, 0.01));
          // Mot entier sur une ligne, dans sa colonne de 72 dp, et jamais
          // rendu sous 11 dp (rétrécissement `FittedBox`, pas de coupure).
          final painter = TextPainter(
            text: TextSpan(text: tab.label(l10n), style: paragraph.text.style),
            textDirection: TextDirection.ltr,
            textScaler: paragraph.textScaler,
          )..layout();
          final fitted = find
              .ancestor(
                of: find.text(tab.label(l10n)),
                matching: find.byType(FittedBox),
              )
              .first;
          final rendered = tester.getSize(fitted).width;
          expect(rendered, lessThanOrEqualTo(360 / 5));
          final effective = 11 * 1.3 * rendered / painter.width;
          expect(effective, greaterThanOrEqualTo(11 - 0.01));
        }
        expect(
          tester.getSize(find.byType(CharacterDetailTabBar)).height,
          greaterThanOrEqualTo(62),
        );
      });
    }
  }
}
