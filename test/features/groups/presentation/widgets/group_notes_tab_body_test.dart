// Tests de widget de l'onglet « Notes » d'un groupe
// (`presentation/widgets/group_notes_tab_body.dart`) : carnet personnel,
// bouton "Enregistrer" actif seulement si le texte a changé, bouton micro
// (dictée vocale) — voir aussi `group_screen_test.dart` pour le comportement
// d'intégration (appels à `saveGroupNote`).

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/groups/presentation/widgets/group_notes_tab_body.dart';
import 'package:personnages/l10n/app_localizations.dart';

const _speechChannel = MethodChannel('plugin.csdcorp.com/speech_to_text');

/// Simule le moteur natif `speech_to_text` déclenchant son callback
/// `onError` pendant une écoute active, en rejouant exactement ce que fait
/// `MethodChannelSpeechToText._handleCallbacks` côté plugin : un appel de
/// méthode `notifyError` reçu *depuis* la plateforme (et non envoyé vers
/// elle, d'où `handlePlatformMessage` plutôt que `setMockMethodCallHandler`)
/// sur ce même canal, avec en argument le JSON d'un `SpeechRecognitionError`
/// (voir `speech_recognition_error.dart`).
Future<void> _simulateNativeDictationError(
  WidgetTester tester, {
  required String errorMsg,
}) async {
  final call = MethodCall(
    'notifyError',
    jsonEncode({'errorMsg': errorMsg, 'permanent': false}),
  );
  final data = _speechChannel.codec.encodeMethodCall(call);
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    _speechChannel.name,
    data,
    (_) {},
  );
}

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

  testWidgets(
    'une erreur native de reconnaissance en cours d\'écoute transmet le '
    'message localisé groupNotesTabBodyDictationErrorMessage (FR puis EN) '
    'à onDictationError',
    (tester) async {
      // `initialize` doit réussir ici (contrairement au test "micro
      // indisponible" ci-dessus) pour atteindre `_speech.listen(...)` et
      // donc le callback `onError`, voir `_DictationButtonState._toggle`.
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        _speechChannel,
        (call) async => call.method == 'initialize' ? true : null,
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          _speechChannel,
          null,
        ),
      );

      // `SpeechToText` (le plugin `speech_to_text`) est un singleton
      // interne : une fois `initialize()` réussi une première fois dans le
      // process de test, ses appels suivants renvoient `true` sans
      // ré-exécuter l'appel plateforme ni ré-enregistrer `errorListener`
      // (voir `speech_to_text.dart`, `if (_initWorked) return
      // Future.value(_initWorked);` avant l'affectation de
      // `errorListener`). Un second `pumpWidget` qui recréerait le
      // `_DictationButton` (et donc une nouvelle `_DictationButtonState`)
      // ne recevrait donc plus jamais les erreurs : seul CE widget, celui
      // dont l'init a réussi la première fois, reste le destinataire pour
      // le reste du fichier de test. D'où un seul test qui fait vivre le
      // même widget sur ses deux phases (FR puis EN) via un changement de
      // `Locale` sans reconstruire l'arbre (même position/type ⇒ même
      // `State` Flutter conservé), plutôt que deux tests indépendants.
      String? error;
      await tester.pumpWidget(
        buildWidget(onDictationError: (message) => error = message),
      );

      await tester.tap(find.byIcon(Icons.mic_none));
      await tester.pumpAndSettle();

      await _simulateNativeDictationError(tester, errorMsg: 'error_no_match');
      await tester.pumpAndSettle();

      expect(error, 'Erreur de reconnaissance vocale : error_no_match');

      String? secondError;
      await tester.pumpWidget(
        buildWidget(
          onDictationError: (message) => secondError = message,
          locale: const Locale('en'),
        ),
      );

      await tester.tap(find.byIcon(Icons.mic_none));
      await tester.pumpAndSettle();

      await _simulateNativeDictationError(tester, errorMsg: 'error_no_match');
      await tester.pumpAndSettle();

      expect(secondError, 'Voice recognition error: error_no_match');
    },
  );
}
