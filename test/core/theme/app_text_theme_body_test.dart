// Thème Material en police corps (D192, PR 3) : `labelLarge`, `headlineSmall` et
// `titleMedium` (hérités par `TextButton`, `PopupMenuItem`, `ChoiceChip`, titre
// d'`AlertDialog`) ne sont plus en police pixel, donc grandissent librement.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/theme/app_theme.dart';
import 'package:personnages/core/theme/app_typography.dart';

import '../widgets/display_scale_helpers.dart';

void main() {
  group('textTheme', () {
    final theme = AppTheme.light.textTheme;

    test('labelLarge, headlineSmall et titleMedium : corps, >= 11 px', () {
      for (final (name, style) in [
        ('labelLarge', theme.labelLarge),
        ('headlineSmall', theme.headlineSmall),
        ('titleMedium', theme.titleMedium),
      ]) {
        expect(style!.fontFamily, 'WorkSans', reason: name);
        expect(
          style.fontSize,
          greaterThanOrEqualTo(AppTypography.minDisplayFontSize),
          reason: name,
        );
        expect(style.fontWeight, FontWeight.w700, reason: name);
      }
    });

    test("titleLarge reste en police pixel (titre d'AppBar, sans usage)", () {
      expect(theme.titleLarge!.fontFamily, 'PressStart2P');
      expect(
        theme.titleLarge!.fontSize,
        greaterThanOrEqualTo(AppTypography.minDisplayFontSize),
      );
    });

    test('couleurs inchangées (texte principal)', () {
      expect(theme.labelLarge!.color, AppTypography.body().color);
      expect(theme.headlineSmall!.color, AppTypography.body().color);
    });
  });

  group('widgets Material sous le thème', () {
    for (final scale in [2.0, 3.0]) {
      for (final width in displayScaleWidths) {
        testWidgets('x$scale sur ${width.toInt()} dp', (tester) async {
          await useScaledView(tester, scale: scale, width: width);
          var selected = 0;
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              home: Scaffold(
                body: StatefulBuilder(
                  builder: (context, setState) => SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          children: [
                            TextButton(
                              onPressed: () {},
                              child: const Text('Réessayer maintenant'),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text('Annuler'),
                            ),
                          ],
                        ),
                        PopupMenuButton<int>(
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 1, child: Text('Modifier')),
                            PopupMenuItem(
                              value: 2,
                              child: Text('Exporter en XML'),
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (var i = 0; i < 4; i++)
                              ChoiceChip(
                                label: Text('Constitution $i'),
                                selected: selected == i,
                                onSelected: (_) => setState(() => selected = i),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.byType(PopupMenuButton<int>));
          await tester.pumpAndSettle();

          for (final label in [
            'Réessayer maintenant',
            'Annuler',
            'Modifier',
            'Exporter en XML',
            'Constitution 0',
          ]) {
            final paragraph = tester.renderObject<RenderParagraph>(
              find.descendant(
                of: find.text(label),
                matching: find.byType(RichText),
              ),
            );
            expect(paragraph.text.style?.fontFamily, 'WorkSans', reason: label);
            expect(paragraph.textScaler.scale(10), closeTo(10 * scale, 0.01));
          }
          expect(displayParagraphs(tester), isEmpty);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
