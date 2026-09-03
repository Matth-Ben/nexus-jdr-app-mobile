// Tests de widget de la sheet "Signaler un bug"
// (`presentation/widgets/report_bug_sheet.dart`) — pattern autoportant
// calqué sur `edit_display_name_sheet_test.dart`/
// `character_story_edit_sheet_test.dart` (voir ces fichiers pour le modèle
// de référence) : validation activant/désactivant "Envoyer", les 3 options
// de sévérité avec la bonne valeur technique envoyée, succès `synced` ET
// `failed` traités identiquement côté UI, hors-ligne, erreur générique,
// préservation de la saisie, verrouillage pendant l'envoi.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/network/connectivity_checker.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/core/widgets/selectable_option_tile.dart';
import 'package:personnages/core/widgets/sheet_header_bar.dart';
import 'package:personnages/features/bug_report/data/bug_report_repository.dart';
import 'package:personnages/features/bug_report/domain/bug_report_failure.dart';
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
  Object? errorToThrow;

  @override
  Future<void> submitReport({
    required String title,
    required String description,
    required String severity,
    String? characterId,
  }) async {
    submitReportCallCount++;
    lastTitle = title;
    lastDescription = description;
    lastSeverity = severity;
    lastCharacterId = characterId;
    if (gateSubmitReport) await gate.future;
    final error = errorToThrow;
    if (error != null) throw error;
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
}) async {
  final repository = _FakeBugReportRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        bugReportRepositoryProvider.overrideWithValue(repository),
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
    'affiche le titre de la sheet, les 2 champs texte et les 3 tuiles de '
    'sévérité, "Gênant" sélectionnée par défaut',
    (tester) async {
      await _pumpSheet(tester);

      expect(find.text('SIGNALER UN BUG'), findsOneWidget);
      expect(find.text('TITRE'), findsOneWidget);
      expect(find.text('DESCRIPTION'), findsOneWidget);
      expect(find.text('À QUEL POINT ÇA TE BLOQUE ?'), findsOneWidget);
      expect(find.text('Gênant'), findsOneWidget);
      expect(find.text('Problématique'), findsOneWidget);
      expect(find.text('Ça bloque tout'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));

      final tiles = tester
          .widgetList<SelectableOptionTile>(find.byType(SelectableOptionTile))
          .toList();
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
}
