// Carte des signes vitaux à grande police (×2,0 et ×3,0) sur 320 dp avec les
// VRAIES polices (D196) : la police de test (Ahem, 1 em par glyphe) fausse les
// largeurs, donc un débordement apparent ou masqué. Aucune exception de
// débordement, cibles tactiles >= 44 dp, valeurs entièrement visibles.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/theme/app_spacing.dart';
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
  Size size = const Size(320, 568),
}) async {
  tester.view.physicalSize = size;
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

  for (final locale in [const Locale('fr'), const Locale('en')]) {
    testWidgets(
      'x1,0 ${locale.languageCode} sur 360 dp : étiquette à gauche, valeur '
      'alignée à droite, jamais collées',
      (tester) async {
        await _pump(
          tester,
          1,
          _detail(currentHp: 12, maxHp: 12, temporaryHp: 0, xp: 0),
          locale: locale,
          size: const Size(360, 640),
        );
        expect(tester.takeException(), isNull);
        final fr = locale.languageCode == 'fr';
        final pairs = [
          (fr ? 'POINTS DE VIE' : 'HIT POINTS', '12 / 12'),
          (fr ? 'EXPÉRIENCE' : 'EXPERIENCE', '0 / 300'),
        ];
        final card = tester.getRect(find.byType(CharacterVitalsCard));
        for (final (label, value) in pairs) {
          final labelRect = tester.getRect(find.text(label));
          final valueRect = tester.getRect(find.text(value));
          expect(
            valueRect.left - labelRect.right,
            greaterThanOrEqualTo(AppSpacing.sm),
            reason: '$label / $value collés',
          );
          expect(valueRect.top, lessThan(labelRect.bottom));
          // Valeur alignée à droite (l'icône crayon des PV peut la suivre).
          expect(card.right - valueRect.right, lessThan(48), reason: value);
        }
      },
    );
  }
}
