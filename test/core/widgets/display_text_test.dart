import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/theme/app_typography.dart';
import 'package:personnages/core/widgets/display_text.dart';

import 'display_scale_helpers.dart';

void main() {
  Widget display({int? maxLines, TextOverflow? overflow, String? semantics}) =>
      DisplayText(
        'TITRE',
        style: AppTypography.display(fontSize: 11),
        maxLines: maxLines,
        overflow: overflow,
        semanticsLabel: semantics,
      );

  Widget body() => Text('corps', style: AppTypography.body(fontSize: 14));

  Widget scaled(double scale, Widget home) => MaterialApp(
    builder: (context, c) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: c!,
    ),
    home: home,
  );

  test('le plafond display est x1,3', () {
    expect(AppTypography.maxDisplayScaleFactor, 1.3);
  });

  testWidgets('x1,0 : taille inchangée', (tester) async {
    await pumpScaled(tester, display(), scale: 1);
    expect(effectiveFontSize(tester, 'TITRE', 11), closeTo(11, 0.01));
  });

  testWidgets('x1,3 : agrandi de 1,3', (tester) async {
    await pumpScaled(tester, display(), scale: 1.3);
    expect(effectiveFontSize(tester, 'TITRE', 11), closeTo(11 * 1.3, 0.01));
  });

  testWidgets('x2,0 : plafonné à x1,3 (largeur et taille)', (tester) async {
    await pumpScaled(tester, display(), scale: 1.3);
    final widthAt13 = tester.getSize(find.byType(DisplayText)).width;
    await pumpScaled(tester, display(), scale: 2);
    final widthAt20 = tester.getSize(find.byType(DisplayText)).width;
    expect(effectiveFontSize(tester, 'TITRE', 11), closeTo(11 * 1.3, 0.01));
    expect(widthAt20, closeTo(widthAt13, widthAt13 * 0.01));
  });

  testWidgets('le texte body à x2,0 continue de grandir', (tester) async {
    await pumpScaled(tester, body(), scale: 2);
    expect(effectiveFontSize(tester, 'corps', 14), closeTo(28, 0.01));
  });

  testWidgets('plafond local : un DisplayText ne plafonne pas son frère', (
    tester,
  ) async {
    await pumpScaled(tester, Column(children: [display(), body()]), scale: 2);
    expect(effectiveFontSize(tester, 'TITRE', 11), closeTo(14.3, 0.01));
    expect(effectiveFontSize(tester, 'corps', 14), closeTo(28, 0.01));
  });

  testWidgets('un plafond plus bas posé plus haut reste prioritaire', (
    tester,
  ) async {
    await tester.pumpWidget(
      scaled(
        2,
        MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.1,
          child: Scaffold(body: display()),
        ),
      ),
    );
    expect(effectiveFontSize(tester, 'TITRE', 11), closeTo(12.1, 0.01));
  });

  testWidgets('dans un sous-arbre plafonné à x2,0, le plafond x1,3 reste', (
    tester,
  ) async {
    await tester.pumpWidget(
      scaled(
        3,
        MediaQuery.withClampedTextScaling(
          maxScaleFactor: AppTypography.maxTextScaleFactor,
          child: Scaffold(body: Column(children: [display(), body()])),
        ),
      ),
    );
    expect(effectiveFontSize(tester, 'TITRE', 11), closeTo(14.3, 0.01));
    expect(effectiveFontSize(tester, 'corps', 14), closeTo(28, 0.01));
  });

  testWidgets('maxLines, overflow et semanticsLabel sont transmis', (
    tester,
  ) async {
    await pumpScaled(
      tester,
      display(maxLines: 1, overflow: TextOverflow.ellipsis, semantics: 'Titre'),
      scale: 1,
    );
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(text.semanticsLabel, 'Titre');
  });

  testWidgets('DisplayText.rich est plafonné aussi', (tester) async {
    await pumpScaled(
      tester,
      DisplayText.rich(
        TextSpan(text: 'RICHE', style: AppTypography.display(fontSize: 11)),
      ),
      scale: 2,
    );
    final paragraph = tester.renderObject<RenderParagraph>(
      find.byType(RichText),
    );
    expect(paragraph.textScaler.scale(11), closeTo(14.3, 0.01));
  });
}
