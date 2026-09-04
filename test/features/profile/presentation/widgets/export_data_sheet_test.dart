// Tests de widget de la sheet "Export de mes données"
// (`presentation/widgets/export_data_sheet.dart`) — pattern autoportant
// calqué sur `report_bug_sheet_test.dart` : succès (retourne le chemin du
// fichier via `Navigator.pop`, ce qui déclenche `Share.shareXFiles` +
// `SnackBar` côté appelant), hors-ligne, erreur générique, verrouillage
// pendant la génération, fermeture non bloquée pendant l'appel.
//
// `Share.shareXFiles` (package `share_plus`) contacte en interne le canal de
// méthode natif `dev.fluttercommunity.plus/share` (`MethodChannelShare`,
// implémentation par défaut de `SharePlatform.instance` tant qu'aucun plugin
// spécifique à la plateforme ne s'est enregistré — jamais le cas dans
// `flutter test`, qui n'exécute jamais le "plugin registrant" généré) : mocké
// une fois pour toute cette suite (méthode `'share'`, réponse minimale), même
// principe que les autres plugins de ce dépôt (`image_picker`,
// `path_provider`...) jamais exercés via un vrai canal de plateforme en
// test.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/network/connectivity_checker.dart';
import 'package:personnages/core/network/connectivity_providers.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/core/widgets/secondary_button.dart';
import 'package:personnages/core/widgets/sheet_header_bar.dart';
import 'package:personnages/features/profile/data/data_export_repository.dart';
import 'package:personnages/features/profile/presentation/providers/data_export_providers.dart';
import 'package:personnages/features/profile/presentation/widgets/export_data_sheet.dart';

class _FakeDataExportRepository implements DataExportRepository {
  final Completer<void> gate = Completer<void>();
  bool gateExport = false;

  int exportCallCount = 0;
  Object? errorToThrow;
  String pathToReturn = '/tmp/export.json';

  @override
  Future<String> exportMyData() async {
    exportCallCount++;
    if (gateExport) await gate.future;
    final error = errorToThrow;
    if (error != null) throw error;
    return pathToReturn;
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

Future<_FakeDataExportRepository> _pumpSheet(
  WidgetTester tester, {
  bool connected = true,
}) async {
  final repository = _FakeDataExportRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dataExportRepositoryProvider.overrideWithValue(repository),
        connectivityCheckerProvider.overrideWithValue(
          _FakeConnectivityChecker(connected: connected),
        ),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showExportDataSheet(context),
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
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dev.fluttercommunity.plus/share');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'share') return '';
        return null;
      });

  testWidgets('affiche le titre et le texte explicatif', (tester) async {
    await _pumpSheet(tester);

    expect(find.text('EXPORT DE MES DONNÉES'), findsOneWidget);
    expect(
      find.textContaining('fichier JSON contenant tous tes personnages'),
      findsOneWidget,
    );
  });

  testWidgets('"Annuler" ferme la sheet sans générer d\'export', (
    tester,
  ) async {
    final repository = await _pumpSheet(tester);

    await tester.tap(find.widgetWithText(SecondaryButton, 'ANNULER'));
    await tester.pumpAndSettle();

    expect(find.text('EXPORT DE MES DONNÉES'), findsNothing);
    expect(repository.exportCallCount, 0);
  });

  testWidgets(
    '"Générer l\'export" réussi : ferme la sheet, propose le partage puis '
    'affiche le SnackBar de confirmation',
    (tester) async {
      final repository = await _pumpSheet(tester);
      repository.pathToReturn = '/tmp/nexus-jdr-export-123.json';

      await tester.tap(find.widgetWithText(PrimaryButton, "GÉNÉRER L'EXPORT"));
      await tester.pumpAndSettle();

      expect(repository.exportCallCount, 1);
      expect(find.text('EXPORT DE MES DONNÉES'), findsNothing);
      expect(find.text('Export généré.'), findsOneWidget);
    },
  );

  testWidgets(
    'pendant la génération : "Générer l\'export" en isLoading, "Annuler" et '
    'le X du SheetHeaderBar désactivés',
    (tester) async {
      final repository = await _pumpSheet(tester);
      repository.gateExport = true;

      await tester.tap(find.widgetWithText(PrimaryButton, "GÉNÉRER L'EXPORT"));
      await tester.pump();

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

      repository.gate.complete();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'aucune connexion réseau : bandeau hors-ligne, sheet reste ouverte, '
    'aucun appel réseau tenté',
    (tester) async {
      final repository = await _pumpSheet(tester, connected: false);

      await tester.tap(find.widgetWithText(PrimaryButton, "GÉNÉRER L'EXPORT"));
      await tester.pumpAndSettle();

      expect(
        find.textContaining("n'a pas pu être enregistrée"),
        findsOneWidget,
      );
      expect(repository.exportCallCount, 0);
      expect(find.text('EXPORT DE MES DONNÉES'), findsOneWidget);
    },
  );

  testWidgets(
    'échec de génération (ex. `CharacterFailure`) : bandeau générique fixe, '
    'sheet reste ouverte',
    (tester) async {
      final repository = await _pumpSheet(tester);
      repository.errorToThrow = Exception('Détail serveur jamais affiché.');

      await tester.tap(find.widgetWithText(PrimaryButton, "GÉNÉRER L'EXPORT"));
      await tester.pumpAndSettle();

      expect(
        find.text("Impossible de générer l'export. Réessayez."),
        findsOneWidget,
      );
      expect(find.text('Détail serveur jamais affiché.'), findsNothing);
      expect(find.text('EXPORT DE MES DONNÉES'), findsOneWidget);
    },
  );

  testWidgets(
    'pendant la génération : ni le geste retour Android, ni un tap sur le '
    'voile ne ferment la sheet',
    (tester) async {
      final repository = await _pumpSheet(tester);
      repository.gateExport = true;

      await tester.tap(find.widgetWithText(PrimaryButton, "GÉNÉRER L'EXPORT"));
      await tester.pump();

      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('EXPORT DE MES DONNÉES'), findsOneWidget);

      await tester.tapAt(const Offset(400, 10));
      await tester.pump();
      expect(find.text('EXPORT DE MES DONNÉES'), findsOneWidget);

      expect(repository.exportCallCount, 1);

      repository.gate.complete();
      await tester.pumpAndSettle();
    },
  );
}
