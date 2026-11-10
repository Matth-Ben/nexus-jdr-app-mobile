import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Monte [child] dans une appli dont la taille de police système vaut
/// [scale] (comme le réglage d'accessibilité de l'OS).
Future<void> pumpScaled(
  WidgetTester tester,
  Widget child, {
  required double scale,
  Size surface = const Size(400, 800),
}) async {
  // `tester.view` (et non `binding.setSurfaceSize`, qui n'est pas pris en compte
  // par le premier `MediaQuery`) : la taille est appliquée avant le montage.
  tester.view.physicalSize = surface;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: c!,
      ),
      home: Scaffold(
        body: Align(alignment: Alignment.topLeft, child: child),
      ),
    ),
  );
}

/// Taille de police effective (en px logiques) du texte [text] pour une taille
/// déclarée de [fontSize] : ce que le moteur de rendu applique réellement.
double effectiveFontSize(WidgetTester tester, String text, double fontSize) {
  final paragraph = tester.renderObject<RenderParagraph>(
    find.descendant(of: find.text(text), matching: find.byType(RichText)),
  );
  return paragraph.textScaler.scale(fontSize);
}
