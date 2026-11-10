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

  Widget control({int? maxLines}) => DisplayText(
    'BOUTON',
    tier: DisplayTier.control,
    style: AppTypography.display(fontSize: 11),
    maxLines: maxLines,
  );

  test('les plafonds des paliers : title x1,3, control x1,5', () {
    expect(AppTypography.maxDisplayScaleFactor, 1.3);
    expect(AppTypography.maxControlScaleFactor, 1.5);
    expect(DisplayTier.title.maxScaleFactor, 1.3);
    expect(DisplayTier.control.maxScaleFactor, 1.5);
  });

  testWidgets('le palier par défaut est title', (tester) async {
    await pumpScaled(tester, display(), scale: 2);
    expect(
      tester.widget<DisplayText>(find.byType(DisplayText)).tier,
      DisplayTier.title,
    );
    expect(effectiveFontSize(tester, 'TITRE', 11), closeTo(14.3, 0.01));
  });

  testWidgets(
    'control : x1,5 plafonné (x1,0 inchangé, x1,5 libre, x2,0 coupé)',
    (tester) async {
      await pumpScaled(tester, control(), scale: 1);
      expect(effectiveFontSize(tester, 'BOUTON', 11), closeTo(11, 0.01));
      await pumpScaled(tester, control(), scale: 1.4);
      expect(effectiveFontSize(tester, 'BOUTON', 11), closeTo(15.4, 0.01));
      await pumpScaled(tester, control(), scale: 2);
      expect(effectiveFontSize(tester, 'BOUTON', 11), closeTo(16.5, 0.01));
      await pumpScaled(tester, control(), scale: 3);
      expect(effectiveFontSize(tester, 'BOUTON', 11), closeTo(16.5, 0.01));
    },
  );

  testWidgets(
    'control : un plafond plus bas posé plus haut reste prioritaire',
    (tester) async {
      await tester.pumpWidget(
        scaled(
          2,
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.1,
            child: Scaffold(body: control()),
          ),
        ),
      );
      expect(effectiveFontSize(tester, 'BOUTON', 11), closeTo(12.1, 0.01));
    },
  );

  testWidgets('control : DisplayText.rich plafonné à x1,5', (tester) async {
    await pumpScaled(
      tester,
      DisplayText.rich(
        TextSpan(text: 'RICHE', style: AppTypography.display(fontSize: 11)),
        tier: DisplayTier.control,
      ),
      scale: 2,
    );
    final paragraph = tester.renderObject<RenderParagraph>(
      find.byType(RichText),
    );
    expect(paragraph.textScaler.scale(11), closeTo(16.5, 0.01));
  });

  testWidgets('control : maxLines 2 permet le retour à la ligne', (
    tester,
  ) async {
    await pumpScaled(
      tester,
      SizedBox(width: 120, child: control(maxLines: 2)),
      scale: 1.5,
    );
    final paragraph = tester.renderObject<RenderParagraph>(
      find.byType(RichText),
    );
    expect(
      paragraph.getFullHeightForCaret(const TextPosition(offset: 0)),
      isNotNull,
    );
    expect(paragraph.size.height, greaterThan(16.5 * 1.2));
  });

  testWidgets('scaler non linéaire : le plafond s applique à la taille réelle '
      'et un scaler plus bas reste prioritaire', (tester) async {
    // scale(11) = 11 * 1,0 + 4 = 15 (pas 11 * k) ; scale(22) = 26.
    Widget app(TextScaler scaler, Widget home) => MaterialApp(
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: scaler),
        child: c!,
      ),
      home: Scaffold(body: home),
    );
    // Au-dessus du plafond title (14,3) : plafonné.
    await tester.pumpWidget(app(const _OffsetScaler(4), display()));
    expect(effectiveFontSize(tester, 'TITRE', 11), closeTo(14.3, 0.01));
    // Control (16,5) : 15 < 16,5 donc la valeur non linéaire passe telle quelle.
    await tester.pumpWidget(app(const _OffsetScaler(4), control()));
    expect(effectiveFontSize(tester, 'BOUTON', 11), closeTo(15, 0.01));
    // Au-dessus du plafond control.
    await tester.pumpWidget(app(const _OffsetScaler(9), control()));
    expect(effectiveFontSize(tester, 'BOUTON', 11), closeTo(16.5, 0.01));
    // Sous le plafond title : intact.
    await tester.pumpWidget(app(const _OffsetScaler(2), display()));
    expect(effectiveFontSize(tester, 'TITRE', 11), closeTo(13, 0.01));
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

/// `TextScaler` non linéaire (comme celui d'Android 14 pour les grandes
/// tailles) : `scale(x) = x + offset`, donc `scale(11)` n'est pas `11 * k`.
class _OffsetScaler extends TextScaler {
  const _OffsetScaler(this.offset);

  final double offset;

  @override
  double scale(double fontSize) => fontSize + offset;

  @override
  double get textScaleFactor => scale(14) / 14;
}
