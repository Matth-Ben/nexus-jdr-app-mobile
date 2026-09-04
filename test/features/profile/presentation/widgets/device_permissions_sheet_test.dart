// Tests de widget de la sheet "Gestion des autorisations appareil"
// (`presentation/widgets/device_permissions_sheet.dart`) — sheet 100%
// statique (aucun appel réseau/état de chargement) : affichage du texte
// explicatif, tap "Ouvrir les réglages" déclenche `AppSettings
// .openAppSettings()` (canal de méthode natif `com.spencerccf.app_settings/
// methods`, mocké ici — même principe que `export_data_sheet_test.dart` pour
// `share_plus`), et la sheet reste librement fermable (contrairement aux
// sheets réseau de ce dossier).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personnages/core/widgets/primary_button.dart';
import 'package:personnages/features/profile/presentation/widgets/device_permissions_sheet.dart';

Future<List<MethodCall>> _pumpSheet(WidgetTester tester) async {
  final calls = <MethodCall>[];
  const channel = MethodChannel('com.spencerccf.app_settings/methods');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return null;
      });

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showDevicePermissionsSheet(context),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Ouvrir'));
  await tester.pumpAndSettle();
  return calls;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('affiche le titre et le texte explicatif', (tester) async {
    await _pumpSheet(tester);

    expect(find.text('GESTION DES AUTORISATIONS APPAREIL'), findsOneWidget);
    expect(
      find.textContaining("l'appareil photo et la galerie"),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(PrimaryButton, 'OUVRIR LES RÉGLAGES'),
      findsOneWidget,
    );
  });

  testWidgets('"Ouvrir les réglages" appelle `AppSettings.openAppSettings`', (
    tester,
  ) async {
    final calls = await _pumpSheet(tester);

    await tester.tap(find.widgetWithText(PrimaryButton, 'OUVRIR LES RÉGLAGES'));
    await tester.pumpAndSettle();

    expect(calls, hasLength(1));
    expect(calls.single.method, 'openSettings');
  });

  testWidgets('librement fermable (X, sans état à protéger)', (tester) async {
    await _pumpSheet(tester);

    await tester.tapAt(const Offset(400, 10));
    await tester.pumpAndSettle();

    expect(find.text('GESTION DES AUTORISATIONS APPAREIL'), findsNothing);
  });
}
