// Tests de widget de la feuille d'ajustement PV détaillée
// (`presentation/widgets/hp_adjustment_sheet.dart`, bouton crayon du bandeau
// PV) — feuille dans un `MaterialApp` minimal, aucun dépôt à injecter :
// `onApply` est un simple callback synchrone (comportement inchangé par le
// chantier "traduction de l'app" Phase B, lot "Characters — PV/XP/Repos/
// Montée de niveau", qui migre uniquement les textes affichés).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/characters/domain/hp_adjustment.dart';
import 'package:personnages/features/characters/presentation/widgets/hp_adjustment_sheet.dart';
import 'package:personnages/l10n/app_localizations.dart';

const _initialState = HpState(currentHp: 10, maxHp: 20, temporaryHp: 0);

Future<HpState?> _open(
  WidgetTester tester, {
  HpState state = _initialState,
  Locale locale = const Locale('fr'),
}) async {
  HpState? applied;
  await tester.pumpWidget(
    MaterialApp(
      // `hp_adjustment_sheet.dart` lit `AppLocalizations.of(context)!`
      // (chantier "traduction de l'app" Phase B, lot "Characters — PV/XP/
      // Repos/Montée de niveau") : sans ces delegates, l'appel renverrait
      // `null` et le `!` planterait.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showHpAdjustmentSheet(
              context,
              state: state,
              onApply: (value) => applied = value,
            ),
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
  return applied;
}

void main() {
  testWidgets(
    'affiche le titre et les 3 segments Dégâts/Soins/PV temp., "Appliquer" '
    'désactivé tant qu\'aucun montant n\'est saisi',
    (tester) async {
      await _open(tester);

      expect(find.text('Ajuster les PV'), findsOneWidget);
      expect(find.text('DÉGÂTS'), findsOneWidget);
      expect(find.text('SOINS'), findsOneWidget);
      expect(find.text('PV TEMP.'), findsOneWidget);

      final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(button.onPressed, isNull);
    },
  );

  testWidgets(
    'segment "Dégâts" (défaut) : augmenter le montant puis "Appliquer" '
    'transmet l\'état avec les PV retirés',
    (tester) async {
      HpState? applied;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showHpAdjustmentSheet(
                  context,
                  state: _initialState,
                  onApply: (value) => applied = value,
                ),
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.tap(find.text('APPLIQUER'));
      await tester.pumpAndSettle();

      expect(applied?.currentHp, 9);
      expect(find.text('Ajuster les PV'), findsNothing);
    },
  );

  testWidgets('"Annuler" ferme la feuille sans appeler onApply', (
    tester,
  ) async {
    HpState? applied;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showHpAdjustmentSheet(
                context,
                state: _initialState,
                onApply: (value) => applied = value,
              ),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ANNULER'));
    await tester.pumpAndSettle();

    expect(applied, isNull);
    expect(find.text('Ajuster les PV'), findsNothing);
  });

  group('locale anglaise', () {
    // Même rationale que les autres lots du chantier "traduction de l'app"
    // Phase B : vérifie qu'un texte anglais s'affiche réellement pour le
    // titre, les 3 segments et les 2 boutons.
    testWidgets('titre, segments et boutons en anglais', (tester) async {
      await _open(tester, locale: const Locale('en'));

      expect(find.text('Adjust HP'), findsOneWidget);
      expect(find.text('DAMAGE'), findsOneWidget);
      expect(find.text('HEALING'), findsOneWidget);
      expect(find.text('TEMP. HP'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);
      expect(find.text('APPLY'), findsOneWidget);
    });
  });
}
