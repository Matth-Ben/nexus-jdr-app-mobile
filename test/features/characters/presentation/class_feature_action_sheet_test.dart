// Tests de widget de la sheet "Actions d'aptitude"
// (`presentation/widgets/class_feature_action_sheet.dart`) — même patron que
// `spell_action_sheet_test.dart`/`rest_sheet_test.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/characters/domain/character_class_feature.dart';
import 'package:personnages/features/characters/presentation/widgets/class_feature_action_sheet.dart';
import 'package:personnages/l10n/app_localizations.dart';

const _rage = CharacterClassFeature(
  id: 1,
  name: 'Rage',
  level: 1,
  usesMax: 2,
  usesRemaining: 1,
  restType: 'repos_long',
  description: 'Entrez dans une rage destructrice.',
);

const _exhaustedFeature = CharacterClassFeature(
  id: 2,
  name: 'Conduit divin',
  level: 2,
  usesMax: 1,
  usesRemaining: 0,
  restType: 'repos_court',
  description: 'Canalisez une énergie divine.',
);

void main() {
  List<CharacterClassFeature> useCalls = [];

  Future<void> pumpSheet(
    WidgetTester tester, {
    required CharacterClassFeature feature,
    Locale locale = const Locale('fr'),
  }) async {
    useCalls = [];
    await tester.pumpWidget(
      MaterialApp(
        // `showClassFeatureActionSheet`/`showClassFeatureInfoPanel` lisent
        // `AppLocalizations.of(context)!` (chantier "traduction de l'app"
        // Phase B, lot "Characters — classe/race/maîtrises") : sans ces
        // delegates, l'appel renverrait `null` et le `!` planterait. `fr`
        // par défaut, `en` passé explicitement par le groupe "locale
        // anglaise" plus bas.
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showClassFeatureActionSheet(
                  context,
                  feature: feature,
                  onUseFeature: useCalls.add,
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

  testWidgets('affiche le nom, le compteur formaté littéralement, "Infos" et '
      '"Utiliser" activée', (tester) async {
    await pumpSheet(tester, feature: _rage);

    expect(find.text('Rage'), findsOneWidget);
    expect(find.text('1 / 2 · repos long'), findsOneWidget);
    expect(find.text('Infos'), findsOneWidget);
    expect(find.text('Utiliser'), findsOneWidget);
    expect(find.text('Épuisée'), findsNothing);
  });

  testWidgets('"Utiliser" appelle directement onUseFeature, sans sheet de '
      'choix intermédiaire', (tester) async {
    await pumpSheet(tester, feature: _rage);

    await tester.tap(find.text('Utiliser'));
    await tester.pumpAndSettle();

    expect(useCalls, [_rage]);
    expect(find.text('Rage'), findsNothing);
  });

  testWidgets(
    'aptitude épuisée : "Utiliser" est désactivée, libellé "Épuisée", tap '
    'sans effet',
    (tester) async {
      await pumpSheet(tester, feature: _exhaustedFeature);

      expect(find.text('Épuisée'), findsOneWidget);

      await tester.tap(find.text('Utiliser'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(useCalls, isEmpty);
      expect(find.text('Conduit divin'), findsOneWidget);
    },
  );

  testWidgets('"Infos" ouvre le panneau avec le niveau, le compteur et la '
      'description, et son bouton "Utiliser" délègue au même flux', (
    tester,
  ) async {
    await pumpSheet(tester, feature: _rage);

    await tester.tap(find.text('Infos'));
    await tester.pumpAndSettle();

    expect(find.text('RAGE'), findsOneWidget);
    expect(find.text('Obtenue au niveau 1.'), findsOneWidget);
    expect(find.text('Utilisations'), findsOneWidget);
    expect(find.text('1 / 2 · repos long'), findsOneWidget);
    expect(find.text('DESCRIPTION'), findsOneWidget);
    expect(find.text('Entrez dans une rage destructrice.'), findsOneWidget);

    await tester.tap(find.widgetWithText(PrimaryButton, 'UTILISER'));
    await tester.pumpAndSettle();

    expect(useCalls, [_rage]);
  });

  testWidgets(
    'panneau "Infos" d\'une aptitude épuisée : "Utiliser" désactivé',
    (tester) async {
      await pumpSheet(tester, feature: _exhaustedFeature);

      await tester.tap(find.text('Infos'));
      await tester.pumpAndSettle();

      final button = tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, 'UTILISER'),
      );
      expect(button.onPressed, isNull);
    },
  );

  group('locale anglaise', () {
    // Même rationale que les autres lots du chantier "traduction de l'app"
    // Phase B : vérifie qu'un texte anglais s'affiche réellement.
    testWidgets('actions "Info"/"Use", "Exhausted" et panneau "Infos" en '
        'anglais', (tester) async {
      await pumpSheet(
        tester,
        feature: _exhaustedFeature,
        locale: const Locale('en'),
      );

      expect(find.text('Info'), findsOneWidget);
      expect(find.text('Use'), findsOneWidget);
      expect(find.text('Exhausted'), findsOneWidget);

      await tester.tap(find.text('Info'));
      await tester.pumpAndSettle();

      expect(find.text('Obtained at level 2.'), findsOneWidget);
      expect(find.text('Uses'), findsOneWidget);
      expect(find.text('DESCRIPTION'), findsOneWidget);
    });
  });
}
