// Tests de `SceneScaffold`/`WoodPlankPainter` — effet "planche en bois" du
// fond "scène" (recettage direction-artistique du 13/09 : le fond était un
// simple dégradé plat, sans les jointures horizontales visibles sur la
// maquette source, ex. `cran-de-connexion-style-sc-ne.jpg`).

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/scene_scaffold.dart';

void main() {
  testWidgets('affiche son body, avec un CustomPaint(WoodPlankPainter) '
      'derrière', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SceneScaffold(body: Center(child: Text('Contenu'))),
      ),
    );

    expect(find.text('Contenu'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is WoodPlankPainter,
      ),
      findsOneWidget,
    );
  });

  group('WoodPlankPainter', () {
    test('shouldRepaint renvoie toujours false — motif statique, jamais '
        'recalculé (les lignes ne dépendent que de `size`, déjà fourni à '
        'chaque paint)', () {
      const painter = WoodPlankPainter();
      expect(painter.shouldRepaint(const WoodPlankPainter()), isFalse);
    });

    test('paint ne lève jamais, y compris sur une taille nulle/très petite '
        '(garde-fou contre un layout pas encore résolu)', () {
      const painter = WoodPlankPainter();
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);

      expect(() => painter.paint(canvas, Size.zero), returnsNormally);
      expect(
        () => painter.paint(canvas, const Size(390, 844)),
        returnsNormally,
      );
      expect(() => painter.paint(canvas, const Size(10, 5)), returnsNormally);

      recorder.endRecording().dispose();
    });
  });
}
