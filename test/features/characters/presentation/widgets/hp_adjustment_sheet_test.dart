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

  testWidgets('le bouton principal suit le mode actif (jamais la couleur '
      'seule) et la borne est affichée sous le champ', (tester) async {
    await _open(tester);

    expect(find.text('INFLIGER'), findsOneWidget);
    expect(find.text('Max 9999'), findsOneWidget);
    await tester.tap(find.text('SOINS'));
    await tester.pump();
    expect(find.text('SOIGNER'), findsOneWidget);
    expect(find.text('INFLIGER'), findsNothing);
    await tester.tap(find.text('PV TEMP.'));
    await tester.pump();
    expect(find.text('AJOUTER'), findsOneWidget);
    await tester.tap(find.text('DÉGÂTS'));
    await tester.pump();
    expect(find.text('INFLIGER'), findsOneWidget);
  });

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
      await tester.tap(find.text('INFLIGER'));
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

  group('saisie numérique', () {
    Future<List<HpState>> openSheet(
      WidgetTester tester, {
      HpState state = _initialState,
      Size? size,
      double textScale = 1,
    }) async {
      final applied = <HpState>[];
      if (size != null) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
      }
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
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showHpAdjustmentSheet(
                  context,
                  state: state,
                  onApply: applied.add,
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

    testWidgets('saisir 27 puis Appliquer = 27 dégâts en un seul geste', (
      tester,
    ) async {
      final applied = await openSheet(
        tester,
        state: const HpState(currentHp: 40, maxHp: 50, temporaryHp: 0),
      );

      await tester.enterText(find.byType(TextField), '27');
      await tester.pump();
      await tester.tap(find.text('INFLIGER'));
      await tester.pumpAndSettle();

      expect(applied, hasLength(1));
      expect(applied.single.currentHp, 13);
    });

    testWidgets('dégâts supérieurs aux PV : bornés à 0', (tester) async {
      final applied = await openSheet(tester);

      await tester.enterText(find.byType(TextField), '500');
      await tester.pump();
      await tester.tap(find.text('INFLIGER'));
      await tester.pumpAndSettle();

      expect(applied.single.currentHp, 0);
    });

    testWidgets('soins supérieurs au manque : bornés au maximum', (
      tester,
    ) async {
      final applied = await openSheet(tester);

      await tester.tap(find.text('SOINS'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '500');
      await tester.pump();
      await tester.tap(find.text('SOIGNER'));
      await tester.pumpAndSettle();

      expect(applied.single.currentHp, 20);
    });

    testWidgets('PV temporaires : maximum non cumulé', (tester) async {
      final applied = await openSheet(
        tester,
        state: const HpState(currentHp: 10, maxHp: 20, temporaryHp: 8),
      );

      await tester.tap(find.text('PV TEMP.'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '5');
      await tester.pump();
      await tester.tap(find.text('AJOUTER'));
      await tester.pumpAndSettle();

      expect(applied.single.temporaryHp, 8);
    });

    testWidgets('PV temporaires absorbent d\'abord les dégâts', (tester) async {
      final applied = await openSheet(
        tester,
        state: const HpState(currentHp: 10, maxHp: 20, temporaryHp: 8),
      );

      await tester.enterText(find.byType(TextField), '12');
      await tester.pump();
      await tester.tap(find.text('INFLIGER'));
      await tester.pumpAndSettle();

      expect(applied.single.temporaryHp, 0);
      expect(applied.single.currentHp, 6);
    });

    testWidgets('champ vide ou 0 : Appliquer reste désactivé', (tester) async {
      await openSheet(tester);

      await tester.enterText(find.byType(TextField), '0');
      await tester.pump();
      expect(
        tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed,
        isNull,
      );
    });

    testWidgets('tient à 320 px de large avec texte système agrandi', (
      tester,
    ) async {
      await openSheet(tester, size: const Size(320, 640), textScale: 1.6);
      expect(tester.takeException(), isNull);
      expect(find.text('INFLIGER'), findsOneWidget);
    });
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
      expect(find.text('INFLICT'), findsOneWidget);
      expect(find.text('Max 9999'), findsOneWidget);

      await tester.tap(find.text('HEALING'));
      await tester.pump();
      expect(find.text('HEAL'), findsOneWidget);
      await tester.tap(find.text('TEMP. HP'));
      await tester.pump();
      expect(find.text('ADD'), findsOneWidget);
    });
  });
}
