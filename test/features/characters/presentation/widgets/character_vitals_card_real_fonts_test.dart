// Carte des signes vitaux à grande police (×2,0 et ×3,0) sur 320 dp avec les
// VRAIES polices (D196) : la police de test (Ahem, 1 em par glyphe) fausse les
// largeurs, donc un débordement apparent ou masqué. Aucune exception de
// débordement, cibles tactiles >= 44 dp, valeurs entièrement visibles.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/theme/app_theme.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/domain/condition_type.dart';
import 'package:personnages/features/characters/presentation/widgets/character_vitals_card.dart';
import 'package:personnages/l10n/app_localizations.dart';

Future<void> _loadFont(String family, String path) async {
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(File(path).readAsBytesSync())));
  await loader.load();
}

CharacterDetail _detail({
  int currentHp = 0,
  int maxHp = 128,
  int temporaryHp = 12,
  int xp = 355000,
}) => CharacterDetail(
  id: '1',
  name: 'Test',
  classes: const [],
  xp: xp,
  currentHp: currentHp,
  maxHp: maxHp,
  temporaryHp: temporaryHp,
  abilityScores: const {},
  conditions: const [
    ConditionType.blinded,
    ConditionType.poisoned,
    ConditionType.prone,
    ConditionType.stunned,
  ],
);

Future<void> _pump(
  WidgetTester tester,
  double scale,
  CharacterDetail detail, {
  Locale locale = const Locale('fr'),
}) async {
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: CharacterVitalsCard(
            detail: detail,
            onTapAdjustHp: () {},
            onTapAddXp: () {},
            onTapLevelUp: () {},
            onTapRest: () {},
            onTapConditions: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(() async {
    await _loadFont('WorkSans', 'assets/fonts/WorkSans-VariableFont_wght.ttf');
    await _loadFont('PressStart2P', 'assets/fonts/PressStart2P-Regular.ttf');
  });

  for (final locale in [const Locale('fr'), const Locale('en')]) {
    for (final scale in [2.0, 3.0]) {
      testWidgets(
        'x$scale ${locale.languageCode} : aucun débordement, valeurs visibles, '
        'cibles >= 44',
        (tester) async {
          await _pump(tester, scale, _detail(), locale: locale);
          expect(tester.takeException(), isNull);
          expect(find.text('0 / 128'), findsOneWidget);
          expect(find.textContaining('355000 /'), findsOneWidget);
          final card = tester.getSize(find.byType(CharacterVitalsCard));
          expect(card.width, lessThanOrEqualTo(320));
          for (final type in [InkWell, ElevatedButton, OutlinedButton]) {
            for (final e in find.byType(type).evaluate()) {
              final size = e.size!;
              expect(
                size.height,
                greaterThanOrEqualTo(44),
                reason: '$type ${size.width}x${size.height}',
              );
            }
          }
        },
      );
    }
  }
}
