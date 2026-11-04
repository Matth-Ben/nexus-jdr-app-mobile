// Tests de widget du panneau "Infos" d'un don
// (`presentation/widgets/feat_info_panel.dart`) — voir sa documentation de
// classe. Même patron que `class_feature_info_panel_test.dart` : ouverture
// directe via [showFeatInfoPanel].

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/characters/presentation/widgets/feat_info_panel.dart';
import 'package:personnages/l10n/app_localizations.dart';

Future<void> _pumpPanel(
  WidgetTester tester, {
  required String name,
  required String description,
  String? prerequisiteText,
  Locale locale = const Locale('fr'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      // `showFeatInfoPanel` lit `AppLocalizations.of(context)!` (chantier
      // "traduction de l'app" Phase B, lot "Characters — classe/race/
      // maîtrises") : sans ces delegates, l'appel renverrait `null` et le
      // `!` planterait. `fr` par défaut, `en` passé explicitement par le
      // groupe "locale anglaise" plus bas.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showFeatInfoPanel(
                context,
                name: name,
                description: description,
                prerequisiteText: prerequisiteText,
              ),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('affiche le nom, "Prérequis", "DESCRIPTION" et la description, '
      'sans bouton d\'action', (tester) async {
    await _pumpPanel(
      tester,
      name: 'Robuste',
      description: 'Vos points de vie maximum augmentent.',
      prerequisiteText: 'Aucun.',
    );

    expect(find.text('ROBUSTE'), findsOneWidget);
    expect(find.text('Prérequis : Aucun.'), findsOneWidget);
    expect(find.text('DESCRIPTION'), findsOneWidget);
    expect(find.text('Vos points de vie maximum augmentent.'), findsOneWidget);
    expect(find.byType(PrimaryButton), findsNothing);
  });

  testWidgets('sans prérequis renseigné : pas de ligne "Prérequis"', (
    tester,
  ) async {
    await _pumpPanel(
      tester,
      name: 'Chanceux',
      description: 'Vous avez des points de chance.',
    );

    expect(find.textContaining('Prérequis'), findsNothing);
  });

  group('locale anglaise', () {
    // Même rationale que les autres lots du chantier "traduction de l'app"
    // Phase B : vérifie qu'un texte anglais s'affiche réellement.
    testWidgets('"Prerequisite" et "DESCRIPTION" en anglais', (tester) async {
      await _pumpPanel(
        tester,
        name: 'Robuste',
        description: 'Vos points de vie maximum augmentent.',
        prerequisiteText: 'Aucun.',
        locale: const Locale('en'),
      );

      expect(find.text('Prerequisite: Aucun.'), findsOneWidget);
      expect(find.text('DESCRIPTION'), findsOneWidget);
    });
  });
}
