// Tests de widget de l'onglet « Notes » d'un groupe
// (`presentation/widgets/group_notes_tab_body.dart`) : carnet personnel,
// bouton "Enregistrer" actif seulement si le texte a changé, bouton micro
// (dictée vocale) — voir aussi `group_screen_test.dart` pour le comportement
// d'intégration (appels à `saveGroupNote`).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/groups/presentation/widgets/group_notes_tab_body.dart';
import 'package:personnages/l10n/app_localizations.dart';

const _speechChannel = MethodChannel('plugin.csdcorp.com/speech_to_text');

void main() {
  Widget buildWidget({
    String initialBody = '',
    bool isSaving = false,
    ValueChanged<String>? onSave,
    ValueChanged<String>? onDictationError,
    Locale locale = const Locale('fr'),
  }) {
    return MaterialApp(
      // Ce widget lit `AppLocalizations.of(context)!` (chantier "traduction
      // de l'app" Phase B, lot "Groups — onglets/butin") : sans ces
      // delegates, l'appel renverrait `null` et le `!` planterait.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(
        body: GroupNotesTabBody(
          initialBody: initialBody,
          isSaving: isSaving,
          onSave: onSave ?? (_) {},
          onDictationError: onDictationError ?? (_) {},
        ),
      ),
    );
  }

  testWidgets(
    'affiche le texte initial et le hint, bouton ENREGISTRER désactivé tant '
    "que rien n'a changé",
    (tester) async {
      await tester.pumpWidget(buildWidget(initialBody: 'Un indice trouvé.'));

      expect(find.text('Un indice trouvé.'), findsOneWidget);
      final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(button.onPressed, isNull);
      expect(button.label, 'Enregistrer');
    },
  );

  testWidgets(
    'modifier le texte active ENREGISTRER et appelle onSave avec le texte '
    'complet',
    (tester) async {
      String? saved;
      await tester.pumpWidget(buildWidget(onSave: (body) => saved = body));

      await tester.enterText(find.byType(TextField), 'Un piège.');
      await tester.pumpAndSettle();

      final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(button.onPressed, isNotNull);

      button.onPressed!();
      expect(saved, 'Un piège.');
    },
  );

  group('traduction anglaise', () {
    testWidgets('hint et bouton "Save" en anglais', (tester) async {
      await tester.pumpWidget(buildWidget(locale: const Locale('en')));

      expect(
        find.text('Take notes during the session: events, clues, twists…'),
        findsOneWidget,
      );
      final button = tester.widget<PrimaryButton>(find.byType(PrimaryButton));
      expect(button.label, 'Save');
    });

    testWidgets('micro indisponible : message dédié en anglais transmis à '
        'onDictationError', (tester) async {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        _speechChannel,
        (call) async => call.method == 'initialize' ? false : null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          _speechChannel,
          null,
        ),
      );

      String? error;
      await tester.pumpWidget(
        buildWidget(
          onDictationError: (message) => error = message,
          locale: const Locale('en'),
        ),
      );

      await tester.tap(find.byIcon(Icons.mic_none));
      await tester.pumpAndSettle();

      expect(
        error,
        'Voice recognition unavailable on this device, or microphone '
        'access refused.',
      );
    });
  });
}
