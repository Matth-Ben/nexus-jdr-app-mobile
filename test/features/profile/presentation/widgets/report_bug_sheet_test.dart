// Tests de widget de la sheet "Signaler un bug"
// (`presentation/widgets/report_bug_sheet.dart`) — pattern autoportant
// calqué sur `edit_display_name_sheet_test.dart`/
// `character_story_edit_sheet_test.dart` (voir ces fichiers pour le modèle
// de référence) : validation activant/désactivant "Envoyer", les 4 options
// de sévérité avec la bonne valeur technique envoyée, succès `synced` ET
// `failed` traités identiquement côté UI, hors-ligne, erreur générique,
// préservation de la saisie, verrouillage pendant l'envoi, et bloc
// « Capture d'écran » (états vide/préparation/avec image, erreurs de choix et
// d'envoi) avec un double du sélecteur — jamais le vrai sélecteur natif.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/network/connectivity_checker.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/core/widgets/alert_banner.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/core/widgets/selectable_option_tile.dart';
import 'package:personnages/core/widgets/sheet_header_bar.dart';
import 'package:personnages/core/widgets/dashed_add_tile.dart';
import 'package:personnages/features/bug_report/data/bug_report_repository.dart';
import 'package:personnages/features/bug_report/data/bug_report_screenshot_picker.dart';
import 'package:personnages/features/bug_report/domain/bug_report_failure.dart';
import 'package:personnages/features/bug_report/domain/bug_report_screenshot.dart';
import 'package:personnages/features/bug_report/presentation/providers/bug_report_providers.dart';
import 'package:personnages/features/profile/presentation/widgets/report_bug_sheet.dart';

class _FakeBugReportRepository implements BugReportRepository {
  final Completer<void> gate = Completer<void>();
  bool gateSubmitReport = false;

  int submitReportCallCount = 0;
  String? lastTitle;
  String? lastDescription;
  String? lastSeverity;
  String? lastCharacterId;
  Uint8List? lastScreenshot;
  Object? errorToThrow;

  @override
  Future<void> submitReport({
    required String title,
    required String description,
    required String severity,
    String? characterId,
    Uint8List? screenshotJpeg,
  }) async {
    submitReportCallCount++;
    lastTitle = title;
    lastDescription = description;
    lastSeverity = severity;
    lastCharacterId = characterId;
    lastScreenshot = screenshotJpeg;
    if (gateSubmitReport) await gate.future;
    final error = errorToThrow;
    if (error != null) throw error;
  }
}

/// Double du sélecteur de capture : [pickResult]/[pickError] pour l'étape
/// de choix, [prepareResult]/[prepareError] pour la préparation, et
/// [prepareGate] pour observer l'état « Préparation de l'image… ».
class _FakeScreenshotPicker implements BugReportScreenshotPicker {
  Uint8List? pickResult = Uint8List.fromList([1, 2, 3]);
  Object? pickError;
  Uint8List prepareResult = Uint8List(840 * 1024);
  Object? prepareError;
  Completer<void>? prepareGate;

  int pickCallCount = 0;
  BugReportScreenshotSource? lastSource;
  Uint8List? lastPreparedInput;

  @override
  Future<Uint8List?> pick(BugReportScreenshotSource source) async {
    pickCallCount++;
    lastSource = source;
    final error = pickError;
    if (error != null) throw error;
    return pickResult;
  }

  @override
  Future<Uint8List> prepare(Uint8List bytes) async {
    lastPreparedInput = bytes;
    final gate = prepareGate;
    if (gate != null) await gate.future;
    final error = prepareError;
    if (error != null) throw error;
    return prepareResult;
  }
}

class _FakeConnectivityChecker implements ConnectivityChecker {
  _FakeConnectivityChecker({required this.connected});

  final bool connected;

  @override
  Future<bool> hasConnection() async => connected;

  @override
  Stream<bool> get onConnectivityRestored => const Stream.empty();
}

Future<_FakeBugReportRepository> _pumpSheet(
  WidgetTester tester, {
  bool connected = true,
  String? characterId,
  _FakeScreenshotPicker? picker,
}) async {
  final repository = _FakeBugReportRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        bugReportRepositoryProvider.overrideWithValue(repository),
        bugReportScreenshotPickerProvider.overrideWithValue(
          picker ?? _FakeScreenshotPicker(),
        ),
        connectivityCheckerProvider.overrideWithValue(
          _FakeConnectivityChecker(connected: connected),
        ),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () =>
                    showReportBugSheet(context, characterId: characterId),
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets(
    'affiche le titre de la sheet, les 2 champs texte et les 4 tuiles de '
    'sévérité ("Contenu à corriger" en dernier, sous-titres non tronqués), '
    '"Gênant" sélectionnée par défaut',
    (tester) async {
      await _pumpSheet(tester);

      expect(find.text('SIGNALER UN BUG'), findsOneWidget);
      expect(find.text('TITRE'), findsOneWidget);
      expect(find.text('DESCRIPTION'), findsOneWidget);
      expect(find.text('QUEL GENRE DE SOUCI ?'), findsOneWidget);
      expect(find.text('À QUEL POINT ÇA TE BLOQUE ?'), findsNothing);
      expect(find.text('Gênant'), findsOneWidget);
      expect(find.text('Problématique'), findsOneWidget);
      expect(find.text('Ça bloque tout'), findsOneWidget);
      expect(find.text('Contenu à corriger'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));

      final tiles = tester
          .widgetList<SelectableOptionTile>(find.byType(SelectableOptionTile))
          .toList();
      expect(tiles.map((t) => t.title), [
        'Gênant',
        'Problématique',
        'Ça bloque tout',
        'Contenu à corriger',
      ]);
      expect(
        tiles.last.subtitle,
        'Erreur ou oubli dans un sort, un objet, une règle ou une traduction',
      );
      expect(tiles.every((t) => t.subtitleMaxLines == null), isTrue);
      expect(tiles.last.leading, isNull);
      expect(tiles.last.onInfo, isNull);
      expect(
        tiles.singleWhere((t) => t.title == 'Contenu à corriger').selected,
        isFalse,
      );
      expect(tiles.singleWhere((t) => t.title == 'Gênant').selected, isTrue);
      expect(
        tiles.singleWhere((t) => t.title == 'Problématique').selected,
        isFalse,
      );
      expect(
        tiles.singleWhere((t) => t.title == 'Ça bloque tout').selected,
        isFalse,
      );
    },
  );

  testWidgets(
    '"Envoyer" désactivé tant que titre ou description sont vides, activé '
    'une fois les deux renseignés',
    (tester) async {
      await _pumpSheet(tester);

      PrimaryButton sendButton() => tester.widget<PrimaryButton>(
        find.widgetWithText(PrimaryButton, 'ENVOYER'),
      );

      expect(sendButton().onPressed, isNull);

      await tester.enterText(find.byType(TextFormField).first, 'Titre');
      await tester.pump();
      expect(
        sendButton().onPressed,
        isNull,
        reason: 'la description est encore vide',
      );

      await tester.enterText(
        find.byType(TextFormField).last,
        'Description détaillée.',
      );
      await tester.pump();
      expect(sendButton().onPressed, isNotNull);

      await tester.enterText(find.byType(TextFormField).first, '   ');
      await tester.pump();
      expect(
        sendButton().onPressed,
        isNull,
        reason: 'un titre blanc après trim ne doit pas activer "Envoyer"',
      );
    },
  );

  testWidgets('sélectionner "Problématique" puis "Envoyer" transmet `severity: '
      '"majeur"` au repository', (tester) async {
    final repository = await _pumpSheet(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Titre');
    await tester.enterText(find.byType(TextFormField).last, 'Description.');
    await tester.pump();
    await tester.tap(find.text('Problématique'));
    await tester.pump();
    await tester.tap(find.widgetWithText(PrimaryButton, 'ENVOYER'));
    await tester.pumpAndSettle();

    expect(repository.lastSeverity, 'majeur');
  });

  testWidgets(
    'sélectionner "Ça bloque tout" puis "Envoyer" transmet `severity: '
    '"bloquant"` au repository',
    (tester) async {
      final repository = await _pumpSheet(tester);

      await tester.enterText(find.byType(TextFormField).first, 'Titre');
      await tester.enterText(find.byType(TextFormField).last, 'Description.');
      await tester.pump();
      await tester.ensureVisible(find.text('Ça bloque tout'));
      await tester.pump();
      await tester.tap(find.text('Ça bloque tout'));
      await tester.pump();
      await tester.ensureVisible(find.widgetWithText(PrimaryButton, 'ENVOYER'));
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENVOYER'));
      await tester.pumpAndSettle();

      expect(repository.lastSeverity, 'bloquant');
    },
  );

  testWidgets(
    '"Envoyer" sans changer la sévérité transmet `severity: "mineur"` par '
    'défaut, et le titre/la description trimés',
    (tester) async {
      final repository = await _pumpSheet(tester);

      await tester.enterText(find.byType(TextFormField).first, '  Résumé  ');
      await tester.enterText(
        find.byType(TextFormField).last,
        '  Ce qui se passe.  ',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENVOYER'));
      await tester.pumpAndSettle();

      expect(repository.lastSeverity, 'mineur');
      expect(repository.lastTitle, 'Résumé');
      expect(repository.lastDescription, 'Ce qui se passe.');
      expect(repository.lastCharacterId, isNull);
    },
  );

  testWidgets(
    'succès `status: "synced"` (ou `"failed"`, indifférencié côté UI) : '
    'ferme la sheet, le SnackBar de confirmation est affiché par '
    'l\'appelant',
    (tester) async {
      final repository = await _pumpSheet(tester);

      await tester.enterText(find.byType(TextFormField).first, 'Titre');
      await tester.enterText(find.byType(TextFormField).last, 'Description.');
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENVOYER'));
      await tester.pumpAndSettle();

      expect(repository.submitReportCallCount, 1);
      expect(find.byType(TextFormField), findsNothing);
      expect(
        find.text('Merci, ton signalement a bien été envoyé !'),
        findsOneWidget,
      );
    },
  );

  testWidgets('pendant l\'envoi : "Envoyer" en isLoading, "Annuler" et le X du '
      'SheetHeaderBar désactivés, champs/tuiles grisés-non-interactifs', (
    tester,
  ) async {
    final repository = await _pumpSheet(tester);
    repository.gateSubmitReport = true;

    await tester.enterText(find.byType(TextFormField).first, 'Titre');
    await tester.enterText(find.byType(TextFormField).last, 'Description.');
    await tester.pump();
    await tester.tap(find.widgetWithText(PrimaryButton, 'ENVOYER'));
    await tester.pump();

    // `isLoading: true` remplace le libellé "ENVOYER" par un indicateur
    // de chargement (voir `PrimaryButton`) : recherche par type, pas par
    // texte, une fois l'envoi démarré.
    final primaryButton = tester.widget<PrimaryButton>(
      find.byType(PrimaryButton),
    );
    expect(primaryButton.isLoading, isTrue);

    final secondaryButton = tester.widget<SecondaryButton>(
      find.widgetWithText(SecondaryButton, 'ANNULER'),
    );
    expect(secondaryButton.onPressed, isNull);

    final header = tester.widget<SheetHeaderBar>(find.byType(SheetHeaderBar));
    expect(header.closeEnabled, isFalse);

    final ignorePointer = tester.widget<IgnorePointer>(
      find.byKey(const Key('reportBugFieldsIgnorePointer')),
    );
    expect(ignorePointer.ignoring, isTrue);

    // Tenter de sélectionner une autre sévérité pendant l'envoi ne doit
    // rien changer : `IgnorePointer` bloque déjà le tap, mais on vérifie
    // aussi qu'aucun deuxième appel réseau n'est déclenché par un tap
    // "en dessous" par erreur.
    await tester.tap(find.text('Ça bloque tout'), warnIfMissed: false);
    await tester.pump();
    expect(repository.submitReportCallCount, 1);

    repository.gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets(
    'aucune connexion réseau : bandeau hors-ligne, sheet reste ouverte, '
    'saisie préservée, aucun appel réseau tenté',
    (tester) async {
      final repository = await _pumpSheet(tester, connected: false);

      await tester.enterText(
        find.byType(TextFormField).first,
        'Titre pas encore envoyé.',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'Description pas encore envoyée.',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENVOYER'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining("n'a pas pu être enregistrée"),
        findsOneWidget,
      );
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'Titre pas encore envoyé.',
      );
      expect(
        repository.submitReportCallCount,
        0,
        reason:
            'sans connectivité, aucune tentative réseau ne doit être '
            'faite (pas de file d\'attente hors-ligne pour cette écriture)',
      );
    },
  );

  testWidgets(
    'BugReportFailure levée par le repository : bandeau générique fixe '
    '(jamais `failure.message`), sheet reste ouverte, saisie préservée',
    (tester) async {
      final repository = await _pumpSheet(tester);
      repository.errorToThrow = const BugReportFailure(
        'Détail serveur jamais affiché.',
      );

      await tester.enterText(
        find.byType(TextFormField).first,
        'En cours de saisie.',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'Description en cours.',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENVOYER'));
      await tester.pumpAndSettle();

      expect(
        find.text("Impossible d'envoyer le signalement. Réessayez."),
        findsOneWidget,
      );
      expect(find.text('Détail serveur jamais affiché.'), findsNothing);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'En cours de saisie.',
      );
    },
  );

  testWidgets(
    'échec inattendu (pas une BugReportFailure) : même bandeau générique '
    'fixe',
    (tester) async {
      final repository = await _pumpSheet(tester);
      repository.errorToThrow = Exception('boom');

      await tester.enterText(find.byType(TextFormField).first, 'Titre');
      await tester.enterText(find.byType(TextFormField).last, 'Description.');
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENVOYER'));
      await tester.pumpAndSettle();

      expect(
        find.text("Impossible d'envoyer le signalement. Réessayez."),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'pendant l\'envoi : ni le geste retour Android, ni un tap sur le voile '
    'ne ferment la sheet',
    (tester) async {
      final repository = await _pumpSheet(tester);
      repository.gateSubmitReport = true;

      await tester.enterText(find.byType(TextFormField).first, 'Titre');
      await tester.enterText(find.byType(TextFormField).last, 'Description.');
      await tester.pump();
      await tester.tap(find.widgetWithText(PrimaryButton, 'ENVOYER'));
      await tester.pump();

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.byType(TextFormField),
        findsNWidgets(2),
        reason: 'le geste retour ne doit pas fermer la sheet pendant l\'envoi',
      );

      await tester.tapAt(const Offset(400, 10));
      await tester.pump();
      expect(find.byType(TextFormField), findsNWidgets(2));

      expect(repository.submitReportCallCount, 1);

      repository.gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNothing);
    },
  );

  testWidgets('`characterId` transmis à `showReportBugSheet` est propagé au '
      'repository', (tester) async {
    final repository = await _pumpSheet(tester, characterId: 'char-7');

    await tester.enterText(find.byType(TextFormField).first, 'Titre');
    await tester.enterText(find.byType(TextFormField).last, 'Description.');
    await tester.pump();
    await tester.tap(find.widgetWithText(PrimaryButton, 'ENVOYER'));
    await tester.pumpAndSettle();

    expect(repository.lastCharacterId, 'char-7');
  });

  testWidgets(
    'sélectionner "Contenu à corriger" puis "Envoyer" transmet `severity: '
    '"contenu"` au repository, sans capture par défaut',
    (tester) async {
      final repository = await _pumpSheet(tester);

      await _fillFields(tester);
      await tester.ensureVisible(find.text('Contenu à corriger'));
      await tester.pump();
      await tester.tap(find.text('Contenu à corriger'));
      await tester.pump();
      await _tapSend(tester);

      expect(repository.lastSeverity, 'contenu');
      expect(repository.lastScreenshot, isNull);
    },
  );

  group("bloc « Capture d'écran »", () {
    testWidgets('état vide : en-tête, mention de confidentialité exacte, tuile '
        '"Ajouter une capture" sous les sévérités, dans le bloc grisable', (
      tester,
    ) async {
      await _pumpSheet(tester);

      expect(find.text("CAPTURE D'ÉCRAN"), findsOneWidget);
      expect(
        find.text(
          "Facultatif, une seule image. Elle reste privée : seule l'équipe "
          "de développement la voit, elle n'est jamais publiée avec ton "
          'signalement et elle est supprimée avec ton compte. Évite quand '
          "même d'y laisser des infos personnelles.",
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.text('Ajouter une capture'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('reportBugFieldsIgnorePointer')),
          matching: find.byType(DashedAddTile),
        ),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(find.text("CAPTURE D'ÉCRAN")).dy,
        greaterThan(tester.getTopLeft(find.text('Contenu à corriger')).dy),
      );
      expect(
        find.bySemanticsLabel("Ajouter une capture d'écran (facultatif)"),
        findsOneWidget,
      );
    });

    testWidgets(
      'la sheet de source s\'empile (galerie en premier, puis photo) sans '
      'fermer le signalement ; annuler ne change rien',
      (tester) async {
        final picker = _FakeScreenshotPicker();
        await _pumpSheet(tester, picker: picker);
        await _fillFields(tester);

        await _openSourceSheet(tester);

        expect(find.text('Choisir dans la galerie'), findsOneWidget);
        expect(find.text('Prendre une photo'), findsOneWidget);
        expect(
          tester.getTopLeft(find.text('Choisir dans la galerie')).dy,
          lessThan(tester.getTopLeft(find.text('Prendre une photo')).dy),
        );
        expect(find.text('Utiliser une URL'), findsNothing);
        expect(find.text('SIGNALER UN BUG'), findsOneWidget);

        // Fermeture de la sheet de source sans choix (voile).
        await tester.tapAt(const Offset(400, 10));
        await tester.pumpAndSettle();

        expect(find.text('Choisir dans la galerie'), findsNothing);
        expect(find.text('SIGNALER UN BUG'), findsOneWidget);
        expect(picker.pickCallCount, 0);
        expect(find.text('Ajouter une capture'), findsOneWidget);
        expect(
          tester
              .widget<TextFormField>(find.byType(TextFormField).first)
              .controller!
              .text,
          'Titre',
        );
      },
    );

    testWidgets(
      'galerie -> préparation ("Envoyer" désactivé) -> capture jointe '
      '(poids, Remplacer/Retirer) -> envoyée au repository',
      (tester) async {
        final picker = _FakeScreenshotPicker()..prepareGate = Completer<void>();
        final repository = await _pumpSheet(tester, picker: picker);
        await _fillFields(tester);
        expect(_sendButton(tester).onPressed, isNotNull);

        await _openSourceSheet(tester);
        await tester.tap(find.text('Choisir dans la galerie'));
        // Pas de `pumpAndSettle` : l'indicateur de progression de l'état
        // « Préparation » tourne en continu tant que [prepareGate] est ouvert.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(picker.lastSource, BugReportScreenshotSource.gallery);
        expect(picker.lastPreparedInput, picker.pickResult);
        expect(
          find.byKey(const Key('reportBugCapturePreparing')),
          findsOneWidget,
        );
        expect(find.text("Préparation de l'image…"), findsOneWidget);
        expect(find.text('Ajouter une capture'), findsNothing);
        expect(
          find.bySemanticsLabel("Préparation de l'image en cours"),
          findsOneWidget,
        );
        expect(
          _sendButton(tester).onPressed,
          isNull,
          reason: '"Envoyer" désactivé pendant la préparation',
        );

        picker.prepareGate!.complete();
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('reportBugCaptureAttached')),
          findsOneWidget,
        );
        expect(find.text('Capture jointe'), findsOneWidget);
        expect(find.text('840 Ko'), findsOneWidget);
        expect(find.text('Remplacer'), findsOneWidget);
        expect(find.text('Retirer'), findsOneWidget);
        expect(
          tester.getTopLeft(find.text('Retirer')).dy,
          greaterThan(tester.getTopLeft(find.text('Remplacer')).dy),
          reason: 'boutons empilés verticalement',
        );
        expect(find.bySemanticsLabel("Capture d'écran jointe"), findsOneWidget);
        expect(
          find.bySemanticsLabel("Remplacer la capture d'écran"),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel("Retirer la capture d'écran"),
          findsOneWidget,
        );
        expect(_sendButton(tester).onPressed, isNotNull);

        await _tapSend(tester);

        expect(repository.submitReportCallCount, 1);
        expect(repository.lastScreenshot, same(picker.prepareResult));
      },
    );

    testWidgets('"Prendre une photo" transmet la source appareil photo', (
      tester,
    ) async {
      final picker = _FakeScreenshotPicker();
      await _pumpSheet(tester, picker: picker);

      await _openSourceSheet(tester);
      await tester.tap(find.text('Prendre une photo'));
      await tester.pumpAndSettle();

      expect(picker.lastSource, BugReportScreenshotSource.camera);
      expect(find.text('Capture jointe'), findsOneWidget);
    });

    testWidgets('sélecteur annulé (aucune image) : rien ne change', (
      tester,
    ) async {
      final picker = _FakeScreenshotPicker()..pickResult = null;
      await _pumpSheet(tester, picker: picker);

      await _openSourceSheet(tester);
      await tester.tap(find.text('Choisir dans la galerie'));
      await tester.pumpAndSettle();

      expect(picker.pickCallCount, 1);
      expect(picker.lastPreparedInput, isNull);
      expect(find.text('Ajouter une capture'), findsOneWidget);
      expect(find.byType(AlertBanner), findsNothing);
    });

    testWidgets('"Retirer" revient immédiatement à l\'état vide, et '
        'l\'envoi part alors sans capture', (tester) async {
      final repository = await _pumpSheet(tester);
      await _fillFields(tester);
      await _attachCapture(tester);

      await tester.ensureVisible(find.text('Retirer'));
      await tester.tap(find.text('Retirer'));
      await tester.pump();

      expect(find.text('Capture jointe'), findsNothing);
      expect(find.text('Ajouter une capture'), findsOneWidget);

      await _tapSend(tester);
      expect(repository.lastScreenshot, isNull);
    });

    final pickErrorCases = <String, (Object, bool)>{
      'Cette image est trop lourde (plus de 5 Mo), même compressée. '
          'Choisissez-en une autre.': (
        const BugReportScreenshotFailure(
          BugReportScreenshotFailureKind.tooLarge,
        ),
        false,
      ),
      "Ce format d'image n'est pas pris en charge. Choisissez une autre "
          'image.': (
        const BugReportScreenshotFailure(
          BugReportScreenshotFailureKind.unsupportedFormat,
        ),
        false,
      ),
      "L'accès à vos photos ou à l'appareil photo est refusé. Autorisez-le "
          'dans les réglages du téléphone.': (
        const BugReportScreenshotFailure(
          BugReportScreenshotFailureKind.accessDenied,
        ),
        true,
      ),
    };
    for (final MapEntry(key: message, value: (error, atPick))
        in pickErrorCases.entries) {
      testWidgets(
        'erreur de choix ($message) : bandeau sous la zone d\'ajout, image '
        'non jointe, effacé à la réouverture de la sheet de source',
        (tester) async {
          final picker = _FakeScreenshotPicker();
          if (atPick) {
            picker.pickError = error;
          } else {
            picker.prepareError = error;
          }
          await _pumpSheet(tester, picker: picker);
          await _fillFields(tester);

          await _openSourceSheet(tester);
          await tester.tap(find.text('Choisir dans la galerie'));
          await tester.pumpAndSettle();

          expect(find.text(message), findsOneWidget);
          expect(find.text('Capture jointe'), findsNothing);
          expect(find.text('Ajouter une capture'), findsOneWidget);
          expect(
            tester.getTopLeft(find.text(message)).dy,
            greaterThan(tester.getTopLeft(find.text('Ajouter une capture')).dy),
          );
          expect(
            find.ancestor(
              of: find.byType(AlertBanner),
              matching: find.byWidgetPredicate(
                (w) => w is Semantics && (w.properties.liveRegion ?? false),
              ),
            ),
            findsWidgets,
          );
          expect(_sendButton(tester).onPressed, isNotNull);

          await _openSourceSheet(tester);
          expect(find.text(message), findsNothing);
        },
      );
    }

    testWidgets('remplacement refusé : l\'image précédente reste jointe', (
      tester,
    ) async {
      final picker = _FakeScreenshotPicker();
      final repository = await _pumpSheet(tester, picker: picker);
      await _fillFields(tester);
      await _attachCapture(tester);
      final firstCapture = picker.prepareResult;

      picker
        ..prepareResult = Uint8List(2 * 1024 * 1024)
        ..prepareError = const BugReportScreenshotFailure(
          BugReportScreenshotFailureKind.tooLarge,
        );
      await tester.ensureVisible(find.text('Remplacer'));
      await tester.tap(find.text('Remplacer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choisir dans la galerie'));
      await tester.pumpAndSettle();

      expect(find.textContaining('trop lourde'), findsOneWidget);
      expect(find.text('Capture jointe'), findsOneWidget);
      expect(find.text('840 Ko'), findsOneWidget);

      await _tapSend(tester);
      expect(repository.lastScreenshot, same(firstCapture));
    });

    testWidgets(
      'remplacement réussi : la nouvelle image remplace l\'ancienne une fois '
      'prête',
      (tester) async {
        final picker = _FakeScreenshotPicker();
        final repository = await _pumpSheet(tester, picker: picker);
        await _fillFields(tester);
        await _attachCapture(tester);

        final replacement = Uint8List((1.2 * 1024 * 1024).round());
        picker.prepareResult = replacement;
        await tester.ensureVisible(find.text('Remplacer'));
        await tester.tap(find.text('Remplacer'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Choisir dans la galerie'));
        await tester.pumpAndSettle();

        expect(find.text('1,2 Mo'), findsOneWidget);
        await _tapSend(tester);
        expect(repository.lastScreenshot, same(replacement));
      },
    );

    testWidgets(
      "échec d'envoi de la capture : bandeau dédié en haut, sheet ouverte, "
      'saisie ET image conservées',
      (tester) async {
        final repository = await _pumpSheet(tester);
        repository.errorToThrow = const BugReportFailure(
          'Détail Storage jamais affiché.',
          kind: BugReportFailureKind.screenshotUpload,
        );
        await _fillFields(tester);
        await _attachCapture(tester);

        await _tapSend(tester);

        expect(
          find.text(
            "Impossible d'envoyer la capture. Réessayez, ou retirez-la pour "
            'envoyer le signalement sans.',
          ),
          findsOneWidget,
        );
        expect(find.text('Détail Storage jamais affiché.'), findsNothing);
        expect(find.text('SIGNALER UN BUG'), findsOneWidget);
        expect(find.text('Capture jointe'), findsOneWidget);
        expect(
          tester
              .widget<TextFormField>(find.byType(TextFormField).first)
              .controller!
              .text,
          'Titre',
        );

        // Réessayer renvoie la même image.
        repository.errorToThrow = null;
        await _tapSend(tester);
        expect(repository.submitReportCallCount, 2);
        expect(repository.lastScreenshot, isNotNull);
        expect(find.text('SIGNALER UN BUG'), findsNothing);
      },
    );

    testWidgets(
      '"Retirer" après un échec d\'envoi de la capture efface le bandeau '
      'dédié',
      (tester) async {
        final repository = await _pumpSheet(tester);
        repository.errorToThrow = const BugReportFailure(
          'x',
          kind: BugReportFailureKind.screenshotUpload,
        );
        await _fillFields(tester);
        await _attachCapture(tester);
        await _tapSend(tester);
        expect(
          find.textContaining("Impossible d'envoyer la capture"),
          findsOneWidget,
        );

        await tester.ensureVisible(find.text('Retirer'));
        await tester.tap(find.text('Retirer'));
        await tester.pump();

        expect(
          find.textContaining("Impossible d'envoyer la capture"),
          findsNothing,
        );
      },
    );

    testWidgets(
      'nouvelle capture jointe après un échec d\'envoi de la capture : le '
      'bandeau dédié disparaît',
      (tester) async {
        final repository = await _pumpSheet(tester);
        repository.errorToThrow = const BugReportFailure(
          'x',
          kind: BugReportFailureKind.screenshotUpload,
        );
        await _fillFields(tester);
        await _attachCapture(tester);
        await _tapSend(tester);
        expect(
          find.textContaining("Impossible d'envoyer la capture"),
          findsOneWidget,
        );

        await _openSourceSheet(tester);
        await tester.tap(find.text('Choisir dans la galerie'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining("Impossible d'envoyer la capture"),
          findsNothing,
        );
        expect(find.text('Capture jointe'), findsOneWidget);
      },
    );

    testWidgets('un autre bandeau d\'envoi (générique) n\'est pas effacé par '
        '"Retirer"', (tester) async {
      final repository = await _pumpSheet(tester);
      repository.errorToThrow = const BugReportFailure('internal_error');
      await _fillFields(tester);
      await _attachCapture(tester);
      await _tapSend(tester);

      await tester.ensureVisible(find.text('Retirer'));
      await tester.tap(find.text('Retirer'));
      await tester.pump();

      expect(
        find.text("Impossible d'envoyer le signalement. Réessayez."),
        findsOneWidget,
      );
    });

    testWidgets(
      'échec générique avec une capture jointe : bandeau générique, image '
      'conservée',
      (tester) async {
        final repository = await _pumpSheet(tester);
        repository.errorToThrow = const BugReportFailure('internal_error');
        await _fillFields(tester);
        await _attachCapture(tester);

        await _tapSend(tester);

        expect(
          find.text("Impossible d'envoyer le signalement. Réessayez."),
          findsOneWidget,
        );
        expect(find.text('Capture jointe'), findsOneWidget);
      },
    );

    testWidgets('hors ligne avec une capture : bandeau hors-ligne inchangé, '
        'image conservée, aucun envoi', (tester) async {
      final repository = await _pumpSheet(tester, connected: false);
      await _fillFields(tester);
      await _attachCapture(tester);

      await _tapSend(tester);

      expect(
        find.textContaining("n'a pas pu être enregistrée"),
        findsOneWidget,
      );
      expect(find.text('Capture jointe'), findsOneWidget);
      expect(repository.submitReportCallCount, 0);
    });

    testWidgets(
      'texte agrandi (x3) : la tuile d\'ajout reste sur une ligne, sans '
      'débordement',
      (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await _pumpSheet(tester);
        await tester.ensureVisible(find.text('Ajouter une capture'));
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(
          tester.widget<Text>(find.text('Ajouter une capture')).maxLines,
          1,
        );
      },
    );
  });

  group('bandeau d\'erreur d\'envoi', _scrollBackToBannerTests);
}

/// Envoi déclenché depuis le bas de la sheet (défilement non nul) : le
/// bandeau d'erreur, en tête, doit revenir dans le champ, annoncé en
/// `liveRegion`.
void _scrollBackToBannerTests() {
  for (final MapEntry(key: label, value: (connected, error))
      in <String, (bool, Object?)>{
        'hors ligne': (false, null),
        'BugReportFailure': (true, const BugReportFailure('x')),
        'erreur inattendue': (true, Exception('boom')),
      }.entries) {
    testWidgets(
      'échec d\'envoi ($label) depuis le bas : défilement ramené en haut, '
      'bandeau visible en liveRegion',
      (tester) async {
        final repository = await _pumpSheet(tester, connected: connected);
        repository.errorToThrow = error;
        await _fillFields(tester);
        await tester.ensureVisible(find.text('Ajouter une capture'));
        await tester.pumpAndSettle();

        final scrollable = tester.state<ScrollableState>(
          find
              .descendant(
                of: find.byType(SingleChildScrollView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(scrollable.position.pixels, greaterThan(0));

        await _tapSend(tester);

        expect(scrollable.position.pixels, 0);
        expect(find.byType(AlertBanner), findsOneWidget);
        expect(
          find.ancestor(
            of: find.byType(AlertBanner),
            matching: find.byWidgetPredicate(
              (w) => w is Semantics && (w.properties.liveRegion ?? false),
            ),
          ),
          findsWidgets,
        );
      },
    );
  }
}

Future<void> _fillFields(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).first, 'Titre');
  await tester.enterText(find.byType(TextFormField).last, 'Description.');
  await tester.pump();
}

PrimaryButton _sendButton(WidgetTester tester) =>
    tester.widget<PrimaryButton>(find.byType(PrimaryButton));

Future<void> _tapSend(WidgetTester tester) async {
  await tester.ensureVisible(find.byType(PrimaryButton));
  await tester.tap(find.byType(PrimaryButton));
  await tester.pumpAndSettle();
}

Future<void> _openSourceSheet(WidgetTester tester) async {
  final addTile = find.text('Ajouter une capture');
  final target = addTile.evaluate().isNotEmpty
      ? addTile
      : find.text('Remplacer');
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _attachCapture(WidgetTester tester) async {
  await _openSourceSheet(tester);
  await tester.tap(find.text('Choisir dans la galerie'));
  await tester.pumpAndSettle();
  expect(find.text('Capture jointe'), findsOneWidget);
}
