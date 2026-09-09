// Tests de widget de la carte personnage (liste d'accueil) — variantes
// "archivé"/"mort", voir `docs/cahier-des-charges/`
// 11-fonctionnalites-a-ajouter.md section 2 et 10-design-system.md section 4
// ("Carte personnage", variantes "archivé"/"mort").

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/dashed_border_painter.dart';
import 'package:personnages/features/characters/domain/character_summary.dart';
import 'package:personnages/features/characters/presentation/widgets/character_card.dart';

const _baseSummary = CharacterSummary(
  id: '1',
  name: 'Halltesse Ambrelune',
  raceName: 'Elfe',
  className: 'Magicienne',
  level: 5,
  xp: 7000,
);

Future<void> _pump(WidgetTester tester, CharacterSummary character) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: CharacterCard(character: character)),
    ),
  );
}

void main() {
  testWidgets('personnage normal : ni badge, ni bordure pointillée', (
    tester,
  ) async {
    await _pump(tester, _baseSummary);

    expect(find.text('ARCHIVÉ'), findsNothing);
    expect(find.text('MORT'), findsNothing);
    expect(find.byIcon(Icons.mood_bad), findsNothing);
  });

  testWidgets('personnage archivé : badge "ARCHIVÉ" et bordure pointillée '
      '(DashedBorderPainter)', (tester) async {
    await _pump(
      tester,
      _baseSummary.copyWith(
        isArchived: true,
        // Portrait défini : sans lui, `PortraitFrame` peint elle-même un
        // second `DashedBorderPainter` pour son placeholder "sans portrait"
        // (`core/widgets/portrait_frame.dart`), ce qui ferait échouer le
        // `findsOneWidget` ci-dessous en comptant celui de la carte elle-même
        // ET celui du portrait vide.
        portraitUrl: 'https://example.com/halltesse.jpg',
      ),
    );

    expect(find.text('ARCHIVÉ'), findsOneWidget);
    expect(find.text('MORT'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint && widget.painter is DashedBorderPainter,
      ),
      findsOneWidget,
    );
  });

  testWidgets('personnage mort : badge "MORT", icône de substitution dédiée '
      'quand aucun portrait n\'est défini', (tester) async {
    await _pump(tester, _baseSummary.copyWith(isDead: true));

    expect(find.text('MORT'), findsOneWidget);
    expect(find.text('ARCHIVÉ'), findsNothing);
    expect(find.byIcon(Icons.mood_bad), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsNothing);
  });

  testWidgets(
    'personnage mort AVEC portrait : le portrait réel reste affiché, pas '
    'l\'icône de substitution',
    (tester) async {
      await _pump(
        tester,
        _baseSummary.copyWith(
          isDead: true,
          portraitUrl: 'https://example.com/halltesse.jpg',
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.mood_bad), findsNothing);
    },
  );

  testWidgets(
    'personnage à la fois archivé et mort : les deux badges sont affichés',
    (tester) async {
      await _pump(
        tester,
        _baseSummary.copyWith(isArchived: true, isDead: true),
      );

      expect(find.text('ARCHIVÉ'), findsOneWidget);
      expect(find.text('MORT'), findsOneWidget);
    },
  );

  testWidgets('le nom et le résumé restent toujours affichés, quelle que '
      'soit la variante', (tester) async {
    await _pump(
      tester,
      _baseSummary.copyWith(isArchived: true, isDead: true),
    );

    expect(find.text('Halltesse Ambrelune'), findsOneWidget);
    expect(find.text('Elfe · Magicienne · Niv. 5'), findsOneWidget);
  });
}
