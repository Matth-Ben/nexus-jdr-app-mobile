// Valeurs `body` jumelées aux étiquettes display PV/XP de
// `CharacterVitalsCard` : plafonnées à x1,6 (décision du 10/11/2026), alors que
// le reste du corps de la carte reste libre et que les étiquettes display
// restent au palier title (x1,3).

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/presentation/widgets/character_vitals_card.dart';
import 'package:personnages/l10n/app_localizations.dart';

Future<void> _pump(WidgetTester tester, double textScale) async {
  // 400 dp et non 360 : la police de test (Ahem, 1 em par glyphe) est ~1,8 fois
  // plus large que WorkSans, la ligne PV tient sur 360 dp avec les vraies polices
  // mais pas avec Ahem.
  await tester.binding.setSurfaceSize(const Size(400, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: CharacterVitalsCard(
            detail: const CharacterDetail(
              id: '1',
              name: 'Test',
              classes: [],
              xp: 0,
              currentHp: 0,
              maxHp: 8,
              temporaryHp: 0,
              abilityScores: {},
            ),
            onTapAdjustHp: () {},
            onTapAddXp: () {},
            onTapLevelUp: () {},
            onTapRest: () {},
          ),
        ),
      ),
    ),
  );
}

double _size(WidgetTester tester, String text, double base) {
  final paragraph = tester.renderObject<RenderParagraph>(
    find.descendant(of: find.text(text), matching: find.byType(RichText)),
  );
  return paragraph.textScaler.scale(base);
}

void main() {
  testWidgets('x1,0 : valeurs PV et XP inchangées', (tester) async {
    await _pump(tester, 1);
    expect(_size(tester, '0 / 8', 15), closeTo(15, 0.01));
    expect(_size(tester, '0 / 300', 13), closeTo(13, 0.01));
  });

  for (final scale in [2.0, 3.0]) {
    testWidgets('x$scale : valeurs PV/XP plafonnées à x1,6, étiquettes à x1,3, '
        'corps voisin libre, aucun débordement', (tester) async {
      await _pump(tester, scale);
      expect(tester.takeException(), isNull);
      expect(_size(tester, '0 / 8', 15), closeTo(15 * 1.6, 0.01));
      expect(_size(tester, '0 / 300', 13), closeTo(13 * 1.6, 0.01));
      expect(_size(tester, 'POINTS DE VIE', 11), closeTo(11 * 1.3, 0.01));
      // Le reste du corps de la carte n'est pas concerné par le plafond.
      expect(_size(tester, 'À 0 PV', 13), closeTo(13 * scale, 0.01));
    });
  }

  testWidgets('x1,5 : sous le plafond x1,6, valeur agrandie librement', (
    tester,
  ) async {
    await _pump(tester, 1.5);
    expect(_size(tester, '0 / 8', 15), closeTo(22.5, 0.01));
  });
}
