// Écran de repli de `lib/main.dart` : le bouton « Réessayer » reçoit bien le
// style display du thème (aucun `style` explicite sur le `DisplayText`) et le
// palier control (x1,5).

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/theme/app_colors.dart';
import 'package:personnages/core/theme/app_theme.dart';
import 'package:personnages/core/widgets/display_text.dart';
import 'package:personnages/main.dart';

Future<void> _pump(WidgetTester tester, double scale) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: SupabaseUnavailableScreen(onRetry: () {}),
    ),
  );
}

void main() {
  testWidgets('« Réessayer » : style display du thème, sans style explicite', (
    tester,
  ) async {
    await _pump(tester, 1);
    final display = tester.widget<DisplayText>(find.byType(DisplayText));
    expect(display.style, isNull, reason: 'le style vient du thème');
    expect(display.tier, DisplayTier.control);
    final style = tester
        .renderObject<RenderParagraph>(
          find.descendant(
            of: find.text('Réessayer'),
            matching: find.byType(RichText),
          ),
        )
        .text
        .style!;
    expect(style.fontFamily, contains('PressStart2P'));
    expect(style.fontSize, 11);
    expect(style.color, AppColors.woodDark);
  });

  testWidgets('« Réessayer » à x2,0 : plafonné à x1,5', (tester) async {
    await _pump(tester, 2);
    final paragraph = tester.renderObject<RenderParagraph>(
      find.descendant(
        of: find.text('Réessayer'),
        matching: find.byType(RichText),
      ),
    );
    expect(paragraph.textScaler.scale(11), closeTo(16.5, 0.01));
  });
}
