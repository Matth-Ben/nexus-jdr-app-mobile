// Tests de widget du signal "À 0 PV" de `CharacterVitalsCard` (décision du
// 09/11/2026, proposition P5) : présent à PV = 0 exactement, absent à 1,
// icône + libellé (jamais la couleur seule).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/domain/character_detail.dart';
import 'package:personnages/features/characters/presentation/widgets/character_vitals_card.dart';
import 'package:personnages/l10n/app_localizations.dart';

Future<void> _pump(
  WidgetTester tester,
  int currentHp, {
  Locale locale = const Locale('fr'),
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: CharacterVitalsCard(
            detail: CharacterDetail(
              id: '1',
              name: 'Test',
              classes: const [],
              xp: 0,
              currentHp: currentHp,
              maxHp: 8,
              temporaryHp: 0,
              abilityScores: const {},
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

void main() {
  testWidgets('à 0 PV : libellé "À 0 PV" et icône visibles, valeur 0 / 8 '
      'conservée', (tester) async {
    await _pump(tester, 0);

    expect(find.text('À 0 PV'), findsOneWidget);
    expect(find.byIcon(Icons.heart_broken_outlined), findsOneWidget);
    expect(find.text('0 / 8'), findsOneWidget);
  });

  testWidgets('à 1 PV : aucun signal', (tester) async {
    await _pump(tester, 1);

    expect(find.text('À 0 PV'), findsNothing);
    expect(find.byIcon(Icons.heart_broken_outlined), findsNothing);
  });

  testWidgets('locale anglaise : "At 0 HP"', (tester) async {
    await _pump(tester, 0, locale: const Locale('en'));

    expect(find.text('At 0 HP'), findsOneWidget);
  });

  testWidgets('largeur très étroite et texte x2 : le libellé passe à la ligne '
      'sans débordement (isolé, discrimine le Flexible)', (tester) async {
    // Le signal est testé isolé : dans la carte, le libellé court ne déborde
    // jamais et les autres rangées (hors périmètre) débordent déjà à x2.
    final reported = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) => reported.add(details.toString());
    addTearDown(() => FlutterError.onError = previous);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 90, child: ZeroHpIndicator()),
          ),
        ),
      ),
    );
    FlutterError.onError = previous;

    expect(find.text('À 0 PV'), findsOneWidget);
    expect(reported, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sémantique : libellé annoncé une seule fois, icône exclue', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, 0);

    expect(find.bySemanticsLabel(RegExp('À 0 PV')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ExcludeSemantics),
        matching: find.byIcon(Icons.heart_broken_outlined),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });
}
