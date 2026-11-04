// Tests de widget de `CharacterSelectionActionBar` (barre d'action en pied
// de `CharacterListScreen` pendant le mode sélection multiple).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/features/characters/presentation/widgets/character_selection_action_bar.dart';
import 'package:personnages/l10n/app_localizations.dart';

Future<void> _pump(
  WidgetTester tester, {
  required int selectedCount,
  VoidCallback? onCancel,
  VoidCallback? onDelete,
  bool isDeleting = false,
  Locale locale = const Locale('fr'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      // `CharacterSelectionActionBar` lit `AppLocalizations.of(context)!`
      // (chantier "traduction de l'app" Phase B, lot "Characters — liste")
      // : sans ces delegates, l'appel renverrait `null` et le `!`
      // planterait. `fr` par défaut, `en` passé explicitement par le
      // groupe "locale anglaise" plus bas.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: CharacterSelectionActionBar(
            selectedCount: selectedCount,
            onCancel: onCancel ?? () {},
            onDelete: onDelete,
            isDeleting: isDeleting,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('libellé central (nombre de personnages sélectionnés)', () {
    testWidgets('0 sélection : "Aucun personnage sélectionné"', (tester) async {
      await _pump(tester, selectedCount: 0);

      expect(find.text('Aucun personnage sélectionné'), findsOneWidget);
    });

    testWidgets('1 sélection : singulier "1 personnage sélectionné"', (
      tester,
    ) async {
      await _pump(tester, selectedCount: 1);

      expect(find.text('1 personnage sélectionné'), findsOneWidget);
    });

    testWidgets('plusieurs sélections : pluriel "n personnages sélectionnés"', (
      tester,
    ) async {
      await _pump(tester, selectedCount: 3);

      expect(find.text('3 personnages sélectionnés'), findsOneWidget);
    });
  });

  testWidgets('"Annuler" appelle onCancel au tap', (tester) async {
    var cancelled = false;
    await _pump(tester, selectedCount: 2, onCancel: () => cancelled = true);

    await tester.tap(find.text('Annuler'));
    expect(cancelled, isTrue);
  });

  testWidgets(
    '"Annuler" désactivé pendant une suppression en cours (isDeleting)',
    (tester) async {
      var cancelled = false;
      await _pump(
        tester,
        selectedCount: 2,
        onCancel: () => cancelled = true,
        isDeleting: true,
      );

      await tester.tap(find.text('Annuler'), warnIfMissed: false);
      expect(cancelled, isFalse);
    },
  );

  testWidgets('"Supprimer" désactivé (onDelete null) : aucune sélection', (
    tester,
  ) async {
    await _pump(tester, selectedCount: 0);

    await tester.tap(find.text('SUPPRIMER'), warnIfMissed: false);
    // Pas d'assertion d'appel ici : onDelete est `null`, seul le fait que le
    // tap ne lève aucune exception compte.
    expect(tester.takeException(), isNull);
  });

  testWidgets('"Supprimer" appelle onDelete au tap', (tester) async {
    var deleted = false;
    await _pump(tester, selectedCount: 2, onDelete: () => deleted = true);

    await tester.tap(find.text('SUPPRIMER'));
    expect(deleted, isTrue);
  });

  testWidgets(
    'isDeleting: true affiche un indicateur de progression au lieu du '
    'libellé "Supprimer"',
    (tester) async {
      await _pump(tester, selectedCount: 2, onDelete: () {}, isDeleting: true);

      expect(find.text('SUPPRIMER'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    },
  );

  group('locale anglaise', () {
    // Même rationale que `login_screen_test.dart`/`profile_screen_test.dart`
    // (chantier "traduction de l'app" Phase B) : vérifie qu'un texte anglais
    // s'affiche réellement, pas seulement que le widget ne plante pas.
    testWidgets('libellé central et boutons "Cancel"/"DELETE" en anglais', (
      tester,
    ) async {
      await _pump(
        tester,
        selectedCount: 3,
        onDelete: () {},
        locale: const Locale('en'),
      );

      expect(find.text('3 characters selected'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('DELETE'), findsOneWidget);
    });

    testWidgets('0 sélection en anglais : "No character selected"', (
      tester,
    ) async {
      await _pump(tester, selectedCount: 0, locale: const Locale('en'));

      expect(find.text('No character selected'), findsOneWidget);
    });

    testWidgets('1 sélection en anglais : singulier "1 character selected"', (
      tester,
    ) async {
      await _pump(tester, selectedCount: 1, locale: const Locale('en'));

      expect(find.text('1 character selected'), findsOneWidget);
    });
  });
}
